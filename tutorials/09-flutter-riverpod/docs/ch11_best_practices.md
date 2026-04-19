# 第十一章：最佳实践与常见陷阱

> 本章总结 Riverpod 开发中的最佳实践、推荐架构模式以及需要避免的常见错误。

## 目录

1. [架构分层](#1-架构分层)
2. [命名约定](#2-命名约定)
3. [Provider 组织](#3-provider-组织)
4. [性能优化](#4-性能优化)
5. [常见陷阱](#5-常见陷阱)
6. [代码示例](#6-代码示例)
7. [小结](#7-小结)

---

## 1. 架构分层

### 1.1 推荐分层

```
┌──────────────────────────────┐
│           UI 层               │  ConsumerWidget / ConsumerStatefulWidget
│     ref.watch / ref.read      │
├──────────────────────────────┤
│        ViewModel 层           │  Notifier / AsyncNotifier
│     业务逻辑、状态管理          │
├──────────────────────────────┤
│        Repository 层          │  Provider<XxxRepository>
│     数据访问抽象               │
├──────────────────────────────┤
│        DataSource 层          │  API Client、本地数据库
│     具体数据实现               │
└──────────────────────────────┘
```

### 1.2 层间通信规则

| 规则 | 说明 |
|------|------|
| UI → ViewModel | `ref.watch` 读取状态，`ref.read(notifier).method()` 触发操作 |
| ViewModel → Repository | `ref.watch(repoProvider)` 获取 Repository |
| Repository → DataSource | 构造函数注入 |
| **不允许反向依赖** | DataSource 不能依赖 Repository，Repository 不能依赖 ViewModel |

### 1.3 文件组织（Feature-First）

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_api.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── auth_notifier.dart
│   │       ├── login_page.dart
│   │       └── register_page.dart
│   └── todo/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── providers/
│   │   └── dio_provider.dart
│   └── widgets/
└── main.dart
```

---

## 2. 命名约定

### 2.1 Provider 命名

```dart
// ✅ 推荐：描述性名称 + Provider 后缀
final userListProvider = ...;
final authStateProvider = ...;
final todoFilterProvider = ...;

// ❌ 避免：不清晰的名称
final provider1 = ...;
final data = ...;
final p = ...;
```

### 2.2 Notifier 命名

```dart
// ✅ 推荐：对应 Provider 名称 + Notifier 后缀
final userListProvider = NotifierProvider<UserListNotifier, List<User>>(...);
class UserListNotifier extends Notifier<List<User>> { ... }

// ✅ 推荐：简洁但描述性
final cartProvider = NotifierProvider<CartNotifier, CartState>(...);
class CartNotifier extends Notifier<CartState> { ... }
```

---

## 3. Provider 组织

### 3.1 单一职责

```dart
// ❌ 一个 Provider 做太多事
class AppNotifier extends Notifier<AppState> {
  void login() { ... }
  void addTodo() { ... }
  void changeTheme() { ... }
  void updateProfile() { ... }
}

// ✅ 拆分为多个 Provider
class AuthNotifier extends Notifier<AuthState> { ... }
class TodoNotifier extends Notifier<List<Todo>> { ... }
class ThemeNotifier extends Notifier<ThemeMode> { ... }
class ProfileNotifier extends Notifier<UserProfile> { ... }
```

### 3.2 合理使用派生 Provider

```dart
// ✅ 用 Provider 派生计算值，而不是在 Notifier 中维护冗余状态
final todosProvider = NotifierProvider<TodoNotifier, List<Todo>>(...);

final activeTodosProvider = Provider<List<Todo>>((ref) {
  return ref.watch(todosProvider).where((t) => !t.done).toList();
});

final activeCountProvider = Provider<int>((ref) {
  return ref.watch(activeTodosProvider).length;
});
```

---

## 4. 性能优化

### 4.1 使用 select 减少重建

```dart
// ❌ user 的任何字段变化都触发重建
final user = ref.watch(userProvider);
Text(user.name);

// ✅ 只有 name 变化才重建
final name = ref.watch(userProvider.select((u) => u.name));
Text(name);
```

### 4.2 使用 Consumer 限制重建范围

```dart
// ❌ 整个页面因 counter 变化而重建
class MyPage extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    final count = ref.watch(counterProvider);
    return Scaffold(
      body: ExpensiveWidget(),  // 这个也会重建！
      floatingActionButton: Text('$count'),
    );
  }
}

// ✅ 只有 Consumer 内部重建
class MyPage extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      body: ExpensiveWidget(),  // 不会重建
      floatingActionButton: Consumer(
        builder: (_, ref, __) {
          final count = ref.watch(counterProvider);
          return Text('$count');
        },
      ),
    );
  }
}
```

### 4.3 合理使用 autoDispose

```dart
// ✅ 页面级数据用 autoDispose
final searchResultProvider = FutureProvider.autoDispose.family<List<Item>, String>(...);

// ✅ 全局数据不用 autoDispose
final authProvider = NotifierProvider<AuthNotifier, AuthState>(...);
```

---

## 5. 常见陷阱

### 5.1 在 build 中使用 ref.read

```dart
// ❌ 陷阱：build 中用 ref.read，UI 不会更新
@override
Widget build(context, ref) {
  final count = ref.read(counterProvider);  // 不会响应变化！
  return Text('$count');
}

// ✅ 正确：build 中用 ref.watch
@override
Widget build(context, ref) {
  final count = ref.watch(counterProvider);  // 自动更新
  return Text('$count');
}
```

### 5.2 在回调中使用 ref.watch

```dart
// ❌ 陷阱：回调中用 ref.watch
onPressed: () {
  final count = ref.watch(counterProvider);  // 多余的监听
}

// ✅ 正确：回调中用 ref.read
onPressed: () {
  ref.read(counterProvider.notifier).state++;
}
```

### 5.3 直接修改状态对象

```dart
// ❌ 陷阱：直接修改列表，UI 不更新
state.add(newItem);  // 引用没变，Riverpod 不知道你改了

// ✅ 正确：创建新列表
state = [...state, newItem];
```

### 5.4 忘记 ProviderScope

```dart
// ❌ 陷阱：忘了 ProviderScope，运行时崩溃
void main() {
  runApp(const MyApp());
}

// ✅ 正确
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

### 5.5 在 Notifier 方法中使用 ref.watch

```dart
// ❌ 陷阱：方法中用 ref.watch（应该只在 build 中用）
class MyNotifier extends Notifier<String> {
  @override
  String build() => '';

  void doSomething() {
    final data = ref.watch(otherProvider);  // 错误！
  }
}

// ✅ 正确：方法中用 ref.read
void doSomething() {
  final data = ref.read(otherProvider);
}
```

---

## 6. 代码示例

本章代码通过一个"正确 vs 错误"对比面板，展示各种最佳实践和陷阱。

---

## 7. 小结

| 类别 | 要点 |
|------|------|
| 架构 | UI → ViewModel(Notifier) → Repository → DataSource |
| 命名 | xxxProvider, XxxNotifier, 描述性命名 |
| 组织 | 单一职责，用派生 Provider 计算值 |
| 性能 | select、Consumer、autoDispose |
| 陷阱 | build 用 watch、回调用 read、不要直接修改状态 |

> 📌 **下一章**是实战项目：天气查询 App。
