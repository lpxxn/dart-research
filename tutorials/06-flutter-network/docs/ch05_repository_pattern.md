# 第五章：Repository 模式

## 概述

Repository 模式是一种常见的软件架构模式，在 Flutter 应用中被广泛使用。它的核心思想是**将数据访问逻辑从业务逻辑中抽离出来**，通过统一的接口管理多种数据源（远程 API、本地缓存、数据库等），让上层代码无需关心数据的具体来源。

## 为什么需要 Repository 模式？

在没有 Repository 的情况下，UI 层可能直接调用网络请求：

```dart
// ❌ 不推荐：UI 直接依赖网络层
class UserPage extends StatefulWidget { ... }
class _UserPageState extends State<UserPage> {
  Future<void> loadUsers() async {
    final response = await http.get(Uri.parse('https://api.example.com/users'));
    final users = jsonDecode(response.body);
    // ...
  }
}
```

这样做的问题：
- **耦合度高**：UI 直接依赖网络库，换库成本大
- **无法缓存**：每次都发网络请求，用户体验差
- **难以测试**：测试 UI 需要真实网络
- **无离线支持**：没网就无法使用

Repository 模式的解决方案：

```
UI 层  →  Repository  →  远程数据源 (API)
                      →  本地数据源 (缓存/数据库)
```

## 核心设计

### 1. 抽象数据源接口

定义统一的数据访问接口，所有数据源都实现它：

```dart
/// 用户数据源接口 —— Repository 模式的核心抽象
abstract class UserDataSource {
  Future<List<User>> getUsers();
  Future<User?> getUserById(int id);
  Future<void> saveUsers(List<User> users);
}
```

**好处**：
- 面向接口编程，便于替换实现
- 本地数据源和远程数据源遵循同一契约
- 方便写 Mock 进行单元测试

### 2. 远程数据源

封装网络请求，负责从服务器获取数据：

```dart
class RemoteUserDataSource implements UserDataSource {
  @override
  Future<List<User>> getUsers() async {
    // 发起网络请求
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('请求失败: ${response.statusCode}');
  }

  // ...其他方法
}
```

### 3. 本地数据源（内存缓存）

管理数据的本地存储，提供快速访问和离线支持：

```dart
class LocalUserDataSource implements UserDataSource {
  final List<User> _cache = [];
  DateTime? _lastUpdated;

  /// 缓存是否有效（设置过期时间）
  bool get isCacheValid {
    if (_lastUpdated == null || _cache.isEmpty) return false;
    return DateTime.now().difference(_lastUpdated!).inMinutes < 5;
  }

  @override
  Future<List<User>> getUsers() async => List.from(_cache);

  @override
  Future<void> saveUsers(List<User> users) async {
    _cache
      ..clear()
      ..addAll(users);
    _lastUpdated = DateTime.now();
  }
}
```

### 4. Repository 层 —— 协调者

Repository 是数据源的协调者，实现缓存策略：

```dart
class UserRepository {
  final RemoteUserDataSource _remoteSource;
  final LocalUserDataSource _localSource;

  /// 缓存优先策略
  Future<DataResult<List<User>>> getUsers({bool forceRefresh = false}) async {
    // 步骤1：缓存有效且非强制刷新，直接返回缓存
    if (!forceRefresh && _localSource.isCacheValid) {
      final cached = await _localSource.getUsers();
      return DataResult(data: cached, source: DataSource.cache);
    }

    // 步骤2：尝试从远程获取
    try {
      final remote = await _remoteSource.getUsers();
      await _localSource.saveUsers(remote); // 更新缓存
      return DataResult(data: remote, source: DataSource.remote);
    } catch (e) {
      // 步骤3：远程失败，降级使用过期缓存
      final cached = await _localSource.getUsers();
      if (cached.isNotEmpty) {
        return DataResult(
          data: cached,
          source: DataSource.cacheFallback,
          errorMessage: e.toString(),
        );
      }
      rethrow; // 无任何数据可用
    }
  }
}
```

## 缓存策略详解

### 缓存优先（Cache-First）

这是示例代码中采用的策略：

```
请求数据 → 缓存有效？ → 是 → 返回缓存
                     → 否 → 请求远程 → 成功 → 更新缓存 → 返回
                                     → 失败 → 有过期缓存？ → 降级返回
                                                          → 抛出异常
```

适用场景：数据更新频率低，用户体验优先

### 网络优先（Network-First）

```dart
Future<List<User>> getUsers() async {
  try {
    final remote = await _remoteSource.getUsers();
    await _localSource.saveUsers(remote);
    return remote;
  } catch (e) {
    return _localSource.getUsers(); // 降级到缓存
  }
}
```

适用场景：数据实时性要求高

### 仅缓存 / 仅网络

- **仅缓存**：配置、静态资源等
- **仅网络**：实时性要求极高、不可缓存的数据

## 离线优先设计

离线优先（Offline-First）是更高级的策略：

1. **读操作**：优先从本地读取，后台静默刷新
2. **写操作**：先写入本地，网络恢复后同步到服务器
3. **冲突解决**：需要时间戳或版本号来处理冲突

```dart
/// 离线优先的写操作思路
Future<void> updateUser(User user) async {
  // 1. 先更新本地
  await _localSource.updateUser(user);

  // 2. 尝试同步到远程
  try {
    await _remoteSource.updateUser(user);
  } catch (e) {
    // 3. 网络失败，标记为待同步
    await _localSource.markPendingSync(user.id);
  }
}
```

## 数据结果包装

用 `DataResult` 告知 UI 数据来源，让用户知道当前看到的数据状态：

```dart
class DataResult<T> {
  final T data;
  final DataSource source;       // cache / remote / cacheFallback
  final String? errorMessage;    // 降级时的错误信息
}
```

UI 层可以根据 `source` 显示不同提示：
- `cache` → 绿色标签 "来自缓存"
- `remote` → 蓝色标签 "已从服务器更新"
- `cacheFallback` → 黄色警告 "网络失败，显示的是过期数据"

## 示例代码说明

`lib/ch05_repository_pattern.dart` 实现了完整的 Repository 模式演示：

- **User 模型**：包含 `fromJson` / `toJson`
- **RemoteUserDataSource**：模拟 800-2000ms 网络延迟，20% 概率失败
- **LocalUserDataSource**：内存缓存，5 分钟过期
- **UserRepository**：缓存优先策略 + 降级处理
- **UI**：展示数据来源状态，支持加载/强制刷新/清除缓存

运行方式：
```bash
# 修改 lib/main.dart 的 import，或直接运行
flutter run -t lib/ch05_repository_pattern.dart
```

## 最佳实践

1. **接口优先**：先定义抽象接口，再实现具体数据源
2. **依赖注入**：Repository 通过构造函数注入数据源，方便测试
3. **单一职责**：每个数据源只负责一种数据获取方式
4. **缓存过期**：一定要设置缓存过期时间，避免数据过时
5. **错误传播**：让上层知道数据来源，便于做出 UI 决策
6. **结合状态管理**：实际项目中配合 Provider / Riverpod / Bloc 使用效果更好

## 扩展阅读

- 在真实项目中，本地数据源通常使用 `sqflite`（SQLite）或 `hive` 而非内存缓存
- `shared_preferences` 适合存储简单键值对，不适合存储列表数据
- 考虑使用 `connectivity_plus` 包检测网络状态，实现更智能的离线策略
