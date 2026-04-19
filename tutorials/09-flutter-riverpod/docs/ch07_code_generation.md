# 第七章：Riverpod Generator（代码生成）

> Riverpod Generator 让你通过 `@riverpod` 注解自动生成 Provider 声明，减少样板代码，提高可读性。本章讲解代码生成的配置和用法。

## 目录

1. [为什么需要代码生成](#1-为什么需要代码生成)
2. [环境配置](#2-环境配置)
3. [函数式 Provider](#3-函数式-provider)
4. [类式 Provider（Notifier）](#4-类式-providernotifier)
5. [异步 Provider 生成](#5-异步-provider-生成)
6. [family 参数](#6-family-参数)
7. [autoDispose 行为](#7-autodispose-行为)
8. [手写 vs 生成 对比](#8-手写-vs-生成-对比)
9. [build_runner 工作流](#9-build_runner-工作流)
10. [小结](#10-小结)

---

## 1. 为什么需要代码生成

手写 Provider 虽然灵活，但有以下痛点：

```dart
// 手写：泛型参数多、容易写错
final userProvider = AsyncNotifierProvider.autoDispose.family<
    UserNotifier, User, String>(UserNotifier.new);

// 生成：简洁直观
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String userId) async { ... }
}
```

| 手写 | 生成 |
|------|------|
| 需要记忆各种 Provider 类型 | 自动推断 Provider 类型 |
| 泛型参数容易写错 | 不需要写泛型 |
| autoDispose/family 需要手动声明 | 自动处理 |
| 类型和 Provider 声明分离 | 代码更集中 |

---

## 2. 环境配置

### 2.1 添加依赖

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

### 2.2 创建文件

生成的代码会创建 `.g.dart` 文件，你需要在源文件中引入：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_file.g.dart';  // 生成的代码

@riverpod
String hello(HelloRef ref) {
  return 'Hello, Riverpod!';
}
```

### 2.3 运行 build_runner

```bash
# 一次性生成
dart run build_runner build

# 监听模式（文件变化时自动生成）
dart run build_runner watch
```

---

## 3. 函数式 Provider

### 3.1 同步 Provider

```dart
// 等价于：final helloProvider = Provider<String>((ref) => 'Hello!');
@riverpod
String hello(HelloRef ref) {
  return 'Hello, Riverpod!';
}

// 使用：ref.watch(helloProvider)
```

### 3.2 带依赖的 Provider

```dart
@riverpod
String greeting(GreetingRef ref) {
  final name = ref.watch(nameProvider);
  return '你好，$name！';
}
```

### 3.3 异步函数式 Provider

```dart
// 等价于：FutureProvider.autoDispose<User>
@riverpod
Future<User> currentUser(CurrentUserRef ref) async {
  final response = await http.get('/user');
  return User.fromJson(response.body);
}

// Stream
@riverpod
Stream<int> counter(CounterRef ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
}
```

---

## 4. 类式 Provider（Notifier）

### 4.1 同步 Notifier

```dart
// 等价于：NotifierProvider.autoDispose<CounterNotifier, int>
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// 使用：
// ref.watch(counterProvider)
// ref.read(counterProvider.notifier).increment()
```

### 4.2 类名与 Provider 名的映射

```
类名: Counter      → counterProvider
类名: UserProfile  → userProfileProvider
类名: TodoList     → todoListProvider
```

规则：**类名首字母小写 + "Provider"**。

---

## 5. 异步 Provider 生成

### 5.1 AsyncNotifier

```dart
@riverpod
class UserList extends _$UserList {
  @override
  Future<List<User>> build() async {
    return await api.getUsers();
  }

  Future<void> addUser(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await api.addUser(name);
      return await api.getUsers();
    });
  }
}
```

---

## 6. family 参数

使用代码生成时，family 参数就是 `build()` 方法的参数：

### 6.1 函数式

```dart
// 等价于：FutureProvider.autoDispose.family<User, String>
@riverpod
Future<User> userDetail(UserDetailRef ref, String userId) async {
  return await api.getUser(userId);
}

// 使用：ref.watch(userDetailProvider('user_123'))
```

### 6.2 类式

```dart
@riverpod
class UserDetail extends _$UserDetail {
  @override
  Future<User> build(String userId) async {
    return await api.getUser(userId);
  }

  Future<void> update(String name) async {
    // 可以通过 arg 访问 family 参数（Riverpod Generator 自动提供）
    state = await AsyncValue.guard(() => api.updateUser(userId, name));
  }
}
```

### 6.3 多参数

```dart
@riverpod
Future<List<Product>> searchProducts(
  SearchProductsRef ref,
  String query,
  {int page = 1, String? category}
) async {
  return await api.search(query, page: page, category: category);
}

// 使用：ref.watch(searchProductsProvider('flutter', page: 2))
```

---

## 7. autoDispose 行为

代码生成默认**启用 autoDispose**。如果需要关闭：

```dart
// 默认 autoDispose（推荐）
@riverpod
String hello(HelloRef ref) => 'hello';

// 关闭 autoDispose
@Riverpod(keepAlive: true)
String hello(HelloRef ref) => 'hello';
```

---

## 8. 手写 vs 生成 对比

| 场景 | 手写 | 生成 |
|------|------|------|
| 简单同步 | `Provider<String>((ref) => 'hi')` | `@riverpod String hello(ref) => 'hi';` |
| StateProvider | `StateProvider<int>((ref) => 0)` | ❌ 不支持，用类式替代 |
| Notifier | `NotifierProvider<N,S>(N.new)` | `@riverpod class N extends _$N {}` |
| AsyncNotifier | `AsyncNotifierProvider<N,S>(N.new)` | `@riverpod class N extends _$N {}` |
| family | `.family<T, P>((ref, p) => ...)` | 直接加参数 |
| autoDispose | `.autoDispose` | 默认开启 |

---

## 9. build_runner 工作流

```bash
# 首次生成
dart run build_runner build --delete-conflicting-outputs

# 监听模式开发
dart run build_runner watch --delete-conflicting-outputs

# 清理生成文件
dart run build_runner clean
```

---

## 10. 小结

| 知识点 | 要点 |
|--------|------|
| @riverpod | 函数式 Provider，自动推断类型 |
| 类式 @riverpod | 继承 _$ClassName，定义 Notifier |
| family | build() 的参数就是 family 参数 |
| autoDispose | 默认开启，用 keepAlive: true 关闭 |
| build_runner | `build` 一次性 / `watch` 监听模式 |
| 命名规则 | 类名 Counter → counterProvider |

> 📌 **下一章**将学习 Provider 的组合与依赖注入模式。
