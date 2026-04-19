# 第五章：异步 Provider

> 真实应用中，大部分数据来自网络请求或数据库查询。本章学习 Riverpod 处理异步数据的三大工具：`FutureProvider`、`StreamProvider` 和 `AsyncNotifier`。

## 目录

1. [FutureProvider — 一次性异步数据](#1-futureprovider--一次性异步数据)
2. [StreamProvider — 实时数据流](#2-streamprovider--实时数据流)
3. [AsyncValue 详解](#3-asyncvalue-详解)
4. [AsyncNotifier — 可变异步状态](#4-asyncnotifier--可变异步状态)
5. [错误处理与重试](#5-错误处理与重试)
6. [加载/成功/错误 UI 模式](#6-加载成功错误-ui-模式)
7. [实战示例：用户列表](#7-实战示例用户列表)
8. [小结](#8-小结)

---

## 1. FutureProvider — 一次性异步数据

`FutureProvider` 用于提供一个 **Future** 的结果，适合一次性的异步数据获取。

### 1.1 基本用法

```dart
// 模拟 API 请求
final userProvider = FutureProvider<User>((ref) async {
  final response = await http.get(Uri.parse('https://api.example.com/user'));
  return User.fromJson(jsonDecode(response.body));
});
```

### 1.2 在 Widget 中使用

`FutureProvider` 返回的是 `AsyncValue<T>`，不是直接的 `T`：

```dart
class UserPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncValue<User> 而不是 User
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('错误：$error'),
      data: (user) => Text('你好，${user.name}'),
    );
  }
}
```

### 1.3 适用场景

| ✅ 适合 | ❌ 不适合 |
|---------|----------|
| 页面初始化加载数据 | 需要手动触发刷新 |
| 获取配置信息 | 需要修改异步数据 |
| 只读的远程数据 | 表单提交等操作 |

> 如果需要手动刷新或修改异步数据，请使用 `AsyncNotifier`（本章第4节）。

---

## 2. StreamProvider — 实时数据流

`StreamProvider` 用于提供一个 **Stream** 的值，适合实时数据（WebSocket、数据库监听等）。

### 2.1 基本用法

```dart
// 实时时钟
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

// Firebase 实时数据
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return FirebaseFirestore.instance
      .collection('messages')
      .snapshots()
      .map((snap) => snap.docs.map(Message.fromDoc).toList());
});
```

### 2.2 在 Widget 中使用

和 `FutureProvider` 一样，返回 `AsyncValue<T>`：

```dart
final clockAsync = ref.watch(clockProvider);
clockAsync.when(
  loading: () => const Text('加载中...'),
  error: (e, s) => Text('错误：$e'),
  data: (time) => Text('${time.hour}:${time.minute}:${time.second}'),
);
```

---

## 3. AsyncValue 详解

`AsyncValue<T>` 是 Riverpod 处理异步状态的核心类型，有三种状态：

### 3.1 三种状态

```dart
sealed class AsyncValue<T> {
  AsyncData<T>    → 有数据
  AsyncLoading<T> → 加载中
  AsyncError<T>   → 出错
}
```

### 3.2 when 方法

```dart
final asyncValue = ref.watch(myFutureProvider);

asyncValue.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('出错了：$error'),
  data: (value) => Text('数据：$value'),
);
```

### 3.3 其他常用属性和方法

```dart
// 获取数据（可空）
final T? value = asyncValue.value;
final T? valueOrNull = asyncValue.valueOrNull;

// 判断状态
final bool isLoading = asyncValue.isLoading;
final bool hasValue = asyncValue.hasValue;
final bool hasError = asyncValue.hasError;

// 获取错误
final Object? error = asyncValue.error;

// maybeWhen：不需要处理所有状态
asyncValue.maybeWhen(
  data: (value) => Text('$value'),
  orElse: () => const CircularProgressIndicator(),
);

// 映射数据
final AsyncValue<String> mapped = asyncValue.whenData((value) => value.toString());
```

### 3.4 刷新时保留旧数据

`AsyncValue` 有一个很好的特性：刷新时，如果之前有数据，`isLoading` 为 true 但 `value` 仍然可用：

```dart
asyncValue.when(
  // skipLoadingOnRefresh: false 时，刷新也显示 loading
  // skipLoadingOnRefresh: true（默认），刷新时继续显示旧数据
  loading: () => const CircularProgressIndicator(),
  error: (e, s) => Text('$e'),
  data: (value) {
    // 刷新时 isLoading 为 true，可以显示一个小指示器
    return Stack(
      children: [
        Text('$value'),
        if (asyncValue.isLoading)
          const Positioned(top: 0, right: 0, child: CircularProgressIndicator()),
      ],
    );
  },
);
```

---

## 4. AsyncNotifier — 可变异步状态

`AsyncNotifier` 是 `Notifier` 的异步版本，`build()` 返回 `Future<T>`。适合需要**手动修改**的异步数据。

### 4.1 定义

```dart
class UsersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    // 初始加载
    return await _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
    return [User('Alice'), User('Bob')];
  }

  /// 添加用户
  Future<void> addUser(String name) async {
    state = const AsyncLoading();  // 显示加载状态
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟 API 调用
      return [...state.value ?? [], User(name)];
    });
  }

  /// 刷新数据
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }
}
```

### 4.2 注册

```dart
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(
  UsersNotifier.new,
);
```

### 4.3 AsyncValue.guard

`AsyncValue.guard` 是一个便捷方法，自动处理 try/catch：

```dart
// 等价于：
state = await AsyncValue.guard(() async {
  return await someAsyncWork();
});

// 手动版本：
try {
  final result = await someAsyncWork();
  state = AsyncData(result);
} catch (e, s) {
  state = AsyncError(e, s);
}
```

---

## 5. 错误处理与重试

### 5.1 在 AsyncNotifier 中处理错误

```dart
Future<void> addUser(String name) async {
  // 保存当前状态，失败时恢复
  final previousState = state;

  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    try {
      return await api.addUser(name);
    } catch (e) {
      // 恢复到之前的状态
      state = previousState;
      rethrow; // 让外层知道出错了
    }
  });
}
```

### 5.2 重试模式

```dart
// 使用 ref.invalidate 重新触发 build()
onPressed: () => ref.invalidate(usersProvider);

// 调用 Notifier 的刷新方法
onPressed: () => ref.read(usersProvider.notifier).refresh();
```

---

## 6. 加载/成功/错误 UI 模式

### 推荐的通用异步 Widget

```dart
Widget buildAsyncContent<T>(
  AsyncValue<T> asyncValue, {
  required Widget Function(T data) data,
  Widget Function()? loading,
  Widget Function(Object error, StackTrace stack)? error,
}) {
  return asyncValue.when(
    loading: loading ?? () => const Center(child: CircularProgressIndicator()),
    error: error ?? (e, s) => Center(child: Text('出错了：$e')),
    data: data,
  );
}
```

---

## 7. 实战示例：用户列表

本章代码演示：
- `FutureProvider`：一次性加载配置
- `StreamProvider`：实时时钟
- `AsyncNotifier`：可增删的用户列表
- `AsyncValue.when`：三态 UI 切换
- `ref.invalidate`：重新加载

---

## 8. 小结

| 知识点 | 要点 |
|--------|------|
| FutureProvider | 一次性异步数据，返回 AsyncValue |
| StreamProvider | 实时数据流，返回 AsyncValue |
| AsyncValue | when/maybeWhen 处理三种状态 |
| AsyncNotifier | 可修改的异步状态，build() 返回 Future |
| AsyncValue.guard | 自动处理 try/catch |
| ref.invalidate | 重新触发 Provider 的 build() |

> 📌 **下一章**将学习修饰符：`autoDispose` 和 `family`。
