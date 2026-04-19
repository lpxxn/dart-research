# 第三章：依赖注入（Dependency Injection）

## 目录

1. [什么是依赖注入](#什么是依赖注入)
2. [为什么需要依赖注入](#为什么需要依赖注入)
3. [依赖注入的三种方式](#依赖注入的三种方式)
4. [get_it 包介绍](#get_it-包介绍)
5. [注册方式对比](#注册方式对比)
6. [实际使用示例](#实际使用示例)
7. [Flutter 项目中的最佳实践](#flutter-项目中的最佳实践)
8. [与其他 DI 方案的对比](#与其他-di-方案的对比)

---

## 什么是依赖注入

### 依赖注入（DI）

依赖注入（Dependency Injection，简称 DI）是一种软件设计模式，其核心思想是：**对象不应该自己创建它所依赖的对象，而是由外部将依赖传递进来**。

举个简单的例子：

```dart
// ❌ 不好的做法：直接在内部创建依赖
class UserRepository {
  final ApiService _apiService = ApiServiceImpl(); // 硬编码依赖

  Future<User> getUser(String id) {
    return _apiService.fetchUser(id);
  }
}

// ✅ 好的做法：通过构造函数注入依赖
class UserRepository {
  final ApiService _apiService; // 依赖抽象而非实现

  UserRepository(this._apiService); // 由外部传入

  Future<User> getUser(String id) {
    return _apiService.fetchUser(id);
  }
}
```

### 控制反转（IoC）

控制反转（Inversion of Control，简称 IoC）是 DI 的理论基础。传统编程中，组件自己控制依赖的创建和查找；在 IoC 模式下，这个控制权被"反转"给了外部容器或框架。

DI 是实现 IoC 的一种具体方式。它们的关系可以简单理解为：

- **IoC** 是一种设计原则（告诉你"应该怎么想"）
- **DI** 是一种实现方式（告诉你"具体怎么做"）

IoC 的核心思想来源于 SOLID 原则中的**依赖倒置原则（Dependency Inversion Principle）**：

> 高层模块不应该依赖低层模块，两者都应该依赖抽象。
> 抽象不应该依赖细节，细节应该依赖抽象。

---

## 为什么需要依赖注入

### 1. 解决耦合问题

没有 DI 时，类之间的耦合非常紧密：

```dart
// 紧耦合：UserRepository 直接依赖 HttpApiService 的具体实现
class UserRepository {
  final httpService = HttpApiService(); // 无法轻松替换

  Future<List<User>> getUsers() {
    return httpService.get('/users');
  }
}
```

使用 DI 后，类之间通过抽象接口交互，耦合度大大降低：

```dart
// 松耦合：UserRepository 依赖抽象的 ApiService
class UserRepository {
  final ApiService _apiService;
  UserRepository(this._apiService);

  Future<List<User>> getUsers() {
    return _apiService.fetchData('/users');
  }
}
```

### 2. 提高可测试性

DI 使得单元测试变得简单，因为你可以轻松注入模拟（Mock）对象：

```dart
// 测试时注入 Mock 对象
class MockApiService implements ApiService {
  @override
  Future<String> fetchData(String endpoint) async {
    return '模拟数据';
  }
}

void main() {
  test('应该正确获取用户列表', () async {
    // 注入 Mock 服务
    final repo = UserRepository(MockApiService());
    final users = await repo.getUsers();
    expect(users, isNotEmpty);
  });
}
```

### 3. 便于维护和扩展

当需要替换某个服务的实现时（例如从 REST API 切换到 GraphQL），只需要修改注入的实现类，不需要修改依赖该服务的所有类。

### 4. 关注点分离

每个类只关注自己的业务逻辑，不需要关心依赖是如何创建的。这符合**单一职责原则**。

---

## 依赖注入的三种方式

### 1. 构造函数注入（Constructor Injection）

最常用也是最推荐的方式。通过构造函数参数传入依赖：

```dart
class UserRepository {
  final ApiService _apiService;
  final DatabaseService _dbService;

  // 通过构造函数注入所有依赖
  UserRepository(this._apiService, this._dbService);

  Future<User> getUser(String id) async {
    // 先查缓存
    final cached = await _dbService.query('users', id);
    if (cached != null) return cached;
    // 缓存未命中，调用 API
    return _apiService.fetchData('/users/$id');
  }
}
```

**优点：**
- 依赖关系清晰明确
- 对象创建后即处于完整可用状态
- 依赖不可变（使用 `final`），线程安全

**缺点：**
- 依赖过多时构造函数参数列表会很长（但这本身说明类承担了太多职责）

### 2. Setter 注入（Setter Injection）

通过 setter 方法或公开属性设置依赖：

```dart
class UserRepository {
  late ApiService apiService;    // 通过 setter 注入
  late DatabaseService dbService;

  void setApiService(ApiService service) {
    apiService = service;
  }

  void setDatabaseService(DatabaseService service) {
    dbService = service;
  }
}

// 使用
final repo = UserRepository();
repo.setApiService(ApiServiceImpl());
repo.setDatabaseService(DatabaseServiceImpl());
```

**优点：**
- 灵活，可以在运行时更换依赖
- 可选依赖的处理更方便

**缺点：**
- 对象可能处于不完整状态（依赖未设置就被使用）
- 依赖关系不够明确

### 3. 接口注入（Interface Injection）

通过实现特定接口来接收依赖：

```dart
// 定义注入接口
abstract class ApiServiceAware {
  void injectApiService(ApiService service);
}

// 实现注入接口
class UserRepository implements ApiServiceAware {
  late ApiService _apiService;

  @override
  void injectApiService(ApiService service) {
    _apiService = service;
  }
}
```

**优点：**
- 明确标识哪些类需要哪些依赖

**缺点：**
- 增加了接口数量，代码更复杂
- 在 Dart/Flutter 中较少使用

> 💡 **最佳实践**：在 Flutter 开发中，推荐优先使用**构造函数注入**，它最简洁、最安全。

---

## get_it 包介绍

### 什么是 get_it

[get_it](https://pub.dev/packages/get_it) 是 Flutter/Dart 生态中最流行的服务定位器（Service Locator）库。它提供了一个全局的容器来注册和获取依赖，简单易用且性能优秀。

### 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  get_it: ^8.0.0
```

### 基本使用

```dart
import 'package:get_it/get_it.dart';

// 创建全局实例
final getIt = GetIt.instance;

// 注册依赖
void setupDependencies() {
  // 注册单例
  getIt.registerSingleton<DatabaseService>(DatabaseServiceImpl());

  // 注册懒加载单例
  getIt.registerLazySingleton<ApiService>(() => ApiServiceImpl());

  // 注册工厂
  getIt.registerFactory<UserRepository>(
    () => UserRepository(getIt<ApiService>(), getIt<DatabaseService>()),
  );
}

// 获取依赖
void someFunction() {
  final apiService = getIt<ApiService>();       // 获取 ApiService 实例
  final userRepo = getIt<UserRepository>();     // 获取 UserRepository 实例
}

// 在 main 中初始化
void main() {
  setupDependencies();
  runApp(const MyApp());
}
```

### 重置和注销

```dart
// 注销某个依赖
getIt.unregister<ApiService>();

// 重置所有注册（常用于测试）
await getIt.reset();

// 检查是否已注册
bool isRegistered = getIt.isRegistered<ApiService>();
```

---

## 注册方式对比

get_it 提供了三种主要的注册方式，适用于不同的场景：

| 特性 | `registerSingleton` | `registerLazySingleton` | `registerFactory` |
|------|-------------------|----------------------|-------------------|
| **创建时机** | 注册时立即创建 | 首次获取时创建 | 每次获取时创建 |
| **实例数量** | 全局唯一（单例） | 全局唯一（单例） | 每次获取新实例 |
| **hashCode** | 始终相同 | 始终相同 | 每次不同 |
| **适用场景** | 应用启动时必须初始化的服务 | 可能用到也可能用不到的服务 | 需要每次获取全新实例的场景 |
| **内存占用** | 启动时即占用 | 按需占用 | 用完即释放（取决于引用） |
| **典型用途** | 数据库连接、配置服务 | 网络服务、日志服务 | ViewModel、临时数据处理器 |

### 代码对比

```dart
// 1. registerSingleton - 立即创建，全局唯一
getIt.registerSingleton<DatabaseService>(DatabaseServiceImpl());
// DatabaseServiceImpl() 在注册时就被调用

// 2. registerLazySingleton - 延迟创建，全局唯一
getIt.registerLazySingleton<ApiService>(() => ApiServiceImpl());
// ApiServiceImpl() 在第一次 getIt<ApiService>() 时才被调用

// 3. registerFactory - 每次创建新实例
getIt.registerFactory<UserRepository>(
  () => UserRepository(getIt<ApiService>(), getIt<DatabaseService>()),
);
// 每次调用 getIt<UserRepository>() 都会创建新的 UserRepository

// 验证区别
final db1 = getIt<DatabaseService>();
final db2 = getIt<DatabaseService>();
print(db1.hashCode == db2.hashCode); // true - 单例，同一个实例

final repo1 = getIt<UserRepository>();
final repo2 = getIt<UserRepository>();
print(repo1.hashCode == repo2.hashCode); // false - 工厂，不同实例
```

---

## 实际使用示例

### Service Locator 模式

Service Locator（服务定位器）模式是 get_it 的核心使用方式。它提供一个集中的注册表，任何地方都可以从中获取所需的服务。

```dart
import 'package:get_it/get_it.dart';

// 全局服务定位器
final GetIt getIt = GetIt.instance;

// ===== 抽象定义 =====

abstract class ApiService {
  Future<String> fetchData(String endpoint);
}

abstract class DatabaseService {
  Future<void> save(String key, String value);
  Future<String?> get(String key);
}

abstract class AuthService {
  Future<bool> login(String username, String password);
  Future<void> logout();
  bool get isLoggedIn;
}

// ===== 具体实现 =====

class ApiServiceImpl implements ApiService {
  @override
  Future<String> fetchData(String endpoint) async {
    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));
    return '来自 $endpoint 的数据';
  }
}

class DatabaseServiceImpl implements DatabaseService {
  final Map<String, String> _store = {};

  @override
  Future<void> save(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> get(String key) async {
    return _store[key];
  }
}

class AuthServiceImpl implements AuthService {
  bool _isLoggedIn = false;

  @override
  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = true;
    return true;
  }

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
  }

  @override
  bool get isLoggedIn => _isLoggedIn;
}

// ===== 依赖注册 =====

void setupDependencies() {
  // 数据库服务 - 单例，立即创建（应用核心服务）
  getIt.registerSingleton<DatabaseService>(DatabaseServiceImpl());

  // API 服务 - 懒加载单例（按需创建）
  getIt.registerLazySingleton<ApiService>(() => ApiServiceImpl());

  // 认证服务 - 懒加载单例
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl());
}

// ===== 使用依赖 =====

class UserRepository {
  final ApiService _apiService;
  final DatabaseService _dbService;

  UserRepository()
      : _apiService = getIt<ApiService>(),
        _dbService = getIt<DatabaseService>();

  Future<String> getUserData(String userId) async {
    // 先检查本地缓存
    final cached = await _dbService.get('user_$userId');
    if (cached != null) return cached;

    // 缓存未命中，从 API 获取
    final data = await _apiService.fetchData('/users/$userId');
    await _dbService.save('user_$userId', data);
    return data;
  }
}
```

---

## Flutter 项目中的最佳实践

### 1. 在 main.dart 中初始化

```dart
void main() {
  setupDependencies();
  runApp(const MyApp());
}
```

### 2. 按功能模块组织注册

```dart
// di/injection.dart - 主入口
void setupDependencies() {
  _registerCoreServices();
  _registerRepositories();
  _registerViewModels();
}

// 核心服务
void _registerCoreServices() {
  getIt.registerSingleton<DatabaseService>(DatabaseServiceImpl());
  getIt.registerLazySingleton<ApiService>(() => ApiServiceImpl());
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl());
}

// 数据仓库
void _registerRepositories() {
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<ApiService>(), getIt<DatabaseService>()),
  );
}

// ViewModel（每次获取新实例）
void _registerViewModels() {
  getIt.registerFactory<HomeViewModel>(
    () => HomeViewModel(getIt<UserRepository>()),
  );
}
```

### 3. 环境隔离（开发/生产）

```dart
enum Environment { dev, staging, prod }

void setupDependencies(Environment env) {
  switch (env) {
    case Environment.dev:
      // 开发环境使用模拟服务
      getIt.registerSingleton<ApiService>(MockApiService());
      break;
    case Environment.prod:
      // 生产环境使用真实服务
      getIt.registerSingleton<ApiService>(ApiServiceImpl());
      break;
    case Environment.staging:
      getIt.registerSingleton<ApiService>(StagingApiService());
      break;
  }
}
```

### 4. 测试中重置依赖

```dart
void main() {
  setUp(() {
    // 每个测试前重置并重新注册
    getIt.reset();
    getIt.registerSingleton<ApiService>(MockApiService());
    getIt.registerSingleton<DatabaseService>(MockDatabaseService());
  });

  test('用户仓库测试', () async {
    final repo = UserRepository();
    final result = await repo.getUserData('123');
    expect(result, isNotNull);
  });
}
```

### 5. 异步初始化

某些服务需要异步初始化（如数据库连接）：

```dart
Future<void> setupDependencies() async {
  // 先注册需要异步初始化的服务
  final db = DatabaseServiceImpl();
  await db.initialize(); // 等待初始化完成
  getIt.registerSingleton<DatabaseService>(db);

  // 或者使用 registerSingletonAsync
  getIt.registerSingletonAsync<DatabaseService>(() async {
    final db = DatabaseServiceImpl();
    await db.initialize();
    return db;
  });

  // 等待所有异步注册完成
  await getIt.allReady();
}
```

---

## 与其他 DI 方案的对比

Flutter 生态中有多种依赖注入/状态管理方案，各有特点：

| 特性 | get_it | Provider | Riverpod | injectable |
|------|--------|----------|----------|------------|
| **类型** | 服务定位器 | DI + 状态管理 | DI + 状态管理 | get_it 代码生成 |
| **是否依赖 BuildContext** | ❌ 不需要 | ✅ 需要 | ❌ 不需要 | ❌ 不需要 |
| **学习曲线** | 低 | 中 | 中高 | 中 |
| **代码生成** | 不需要 | 不需要 | 可选 | 需要 |
| **适用层** | Service/Repository | Widget/State | 全层 | Service/Repository |
| **编译时安全** | 运行时检查 | 运行时检查 | 编译时检查 | 编译时检查 |
| **可测试性** | 高 | 高 | 非常高 | 高 |
| **社区活跃度** | 高 | 非常高 | 高 | 中 |

### 选择建议

- **小型项目**：直接使用 `get_it` 即可满足需求，简单高效
- **中型项目**：`get_it` + `Provider` 或 `get_it` + `BLoC` 组合使用
- **大型项目**：考虑 `injectable`（get_it 的代码生成版本）或 `Riverpod`
- **需要 Widget 层响应式更新**：配合 `Provider` 或 `Riverpod` 使用

### get_it vs Provider

```dart
// get_it：任何地方都能获取，不需要 BuildContext
class MyService {
  void doSomething() {
    final api = getIt<ApiService>(); // ✅ 不需要 context
  }
}

// Provider：必须通过 BuildContext 获取
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context); // 必须有 context
    // 或者 context.read<ApiService>();
  }
}
```

> 💡 **总结**：`get_it` 最适合在非 Widget 层（Service、Repository、ViewModel）使用，
> 而 `Provider`/`Riverpod` 更适合在 Widget 层进行状态管理和响应式更新。
> 两者并不冲突，可以组合使用来发挥各自的优势。

---

## 小结

本章介绍了依赖注入的核心概念和在 Flutter 中的实践：

1. **DI 的本质**：将依赖的创建和管理从使用者中分离出来
2. **三种注入方式**：构造函数注入（推荐）、Setter 注入、接口注入
3. **get_it 的使用**：注册（Singleton/LazySingleton/Factory）和获取依赖
4. **最佳实践**：模块化注册、环境隔离、测试友好

在下一章中，我们将学习如何结合状态管理方案，构建完整的应用架构。
