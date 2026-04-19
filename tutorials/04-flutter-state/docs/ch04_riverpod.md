# 第四章：Riverpod 状态管理

> Riverpod 是 Provider 的"进化版"，由同一作者开发，解决了 Provider 的多个根本性问题。
> 本章将深入学习 Riverpod 的核心概念与实战用法。

## 目录

1. [Riverpod vs Provider 的区别](#1-riverpod-vs-provider-的区别)
2. [安装与基本配置](#2-安装与基本配置)
3. [Provider 类型全解](#3-provider-类型全解)
4. [ref.watch vs ref.read vs ref.listen](#4-refwatch-vs-refread-vs-reflisten)
5. [autoDispose 和 family 修饰符](#5-autodispose-和-family-修饰符)
6. [ConsumerWidget 和 ConsumerStatefulWidget](#6-consumerwidget-和-consumerstatefulwidget)
7. [常见模式和最佳实践](#7-常见模式和最佳实践)
8. [实战示例：Todo List](#8-实战示例todo-list)

---

## 1. Riverpod vs Provider 的区别

### 1.1 为什么需要 Riverpod？

Provider 虽然简单易用，但存在以下根本性问题：

| 问题 | Provider | Riverpod |
|------|----------|----------|
| 编译时安全 | ❌ 运行时可能抛出 `ProviderNotFoundException` | ✅ 编译时就能发现错误 |
| 依赖 BuildContext | ❌ 必须有 `BuildContext` 才能读取状态 | ✅ 不依赖 `BuildContext`，任何地方都能读取 |
| 同类型多 Provider | ❌ 同类型的多个 Provider 会冲突 | ✅ 每个 Provider 都是独立的全局变量 |
| 可测试性 | ⚠️ 需要在 widget 树中 mock | ✅ 可以轻松 override 任何 Provider |
| Provider 组合 | ⚠️ 使用 `ProxyProvider`，较复杂 | ✅ 直接使用 `ref.watch` 组合 |

### 1.2 编译时安全

在 Provider 中，如果你忘记在 widget 树上方放置 Provider，只有在运行时才会报错：

```dart
// Provider - 运行时错误 💥
final counter = context.watch<CounterNotifier>(); // 如果上方没有 Provider，运行时崩溃
```

在 Riverpod 中，Provider 是全局声明的变量，不存在"找不到"的问题：

```dart
// Riverpod - 编译时安全 ✅
final counterProvider = NotifierProvider<CounterNotifier, int>(() {
  return CounterNotifier();
});

// 任何 ConsumerWidget 中都可以安全访问
final count = ref.watch(counterProvider);
```

### 1.3 不依赖 BuildContext

Provider 必须通过 `BuildContext` 才能读取状态，这意味着：
- 不能在 `initState` 中使用
- 不能在回调函数中方便地使用
- 不能在非 Widget 类中使用

Riverpod 通过 `ref` 对象解决了这个问题：

```dart
// Riverpod - 不需要 BuildContext
class MyRepository {
  final Ref ref;
  MyRepository(this.ref);

  Future<void> fetchData() async {
    final apiClient = ref.read(apiClientProvider);
    // ...
  }
}
```

### 1.4 可测试性

Riverpod 可以轻松 override 任何 Provider 进行测试：

```dart
testWidgets('counter test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        counterProvider.overrideWith(() => MockCounterNotifier()),
      ],
      child: MyApp(),
    ),
  );
});
```

---

## 2. 安装与基本配置

### 2.1 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
```

### 2.2 ProviderScope

每个 Riverpod 应用都必须在根节点包裹 `ProviderScope`：

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

`ProviderScope` 是所有 Provider 状态的容器，类似于 Provider 包中的 `MultiProvider`，
但你不需要列出所有的 Provider —— 它们会自动注册。

---

## 3. Provider 类型全解

Riverpod 提供了多种 Provider 类型，每种都有其特定的用途。

### 3.1 Provider（只读值）

`Provider` 用于暴露不可变的值或计算结果。最常见的用途是：
- 暴露常量或配置
- 暴露通过组合其他 Provider 计算出来的值（派生状态）

```dart
// 暴露一个常量配置
final apiUrlProvider = Provider<String>((ref) {
  return 'https://api.example.com';
});

// 派生状态：过滤后的列表
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoFilterProvider);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoFilter.all:
      return todos;
    case TodoFilter.active:
      return todos.where((t) => !t.isDone).toList();
    case TodoFilter.completed:
      return todos.where((t) => t.isDone).toList();
  }
});
```

**特点：**
- 值是只读的，外部不能直接修改
- 当依赖的其他 Provider 变化时，自动重新计算
- 非常适合做"计算属性"或"派生状态"

### 3.2 StateProvider（简单可变状态）

`StateProvider` 用于管理简单的可变状态，如 `int`、`String`、`enum` 等。

```dart
// 定义
final counterProvider = StateProvider<int>((ref) => 0);
final filterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

// 读取
final count = ref.watch(counterProvider);

// 修改
ref.read(counterProvider.notifier).state++;
// 或者
ref.read(counterProvider.notifier).update((state) => state + 1);
```

**适用场景：**
- 简单的计数器
- 开关切换（bool）
- 下拉选择
- 筛选条件

**注意：** 对于复杂的状态逻辑（需要多个方法修改状态），请使用 `NotifierProvider`。

### 3.3 FutureProvider（异步数据）

`FutureProvider` 用于处理异步操作，相当于 `Provider` 的异步版本。

```dart
final userProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.fetchUser();
});

// 在 widget 中使用
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('错误: $err'),
    );
  }
}
```

**特点：**
- 返回 `AsyncValue<T>`，包含 `data`、`loading`、`error` 三种状态
- 使用 `.when()` 方法可以优雅地处理这三种状态
- 自动处理加载和错误状态

### 3.4 StreamProvider（流数据）

`StreamProvider` 用于监听数据流，非常适合：
- WebSocket 连接
- Firebase Realtime Database / Firestore 监听
- 定时器

```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchMessages();
});

// Firebase 示例
final usersProvider = StreamProvider<List<User>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => User.fromJson(doc.data())).toList());
});

// 在 widget 中使用
class MessageList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider);

    return messagesAsync.when(
      data: (messages) => ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) => Text(messages[index].text),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('错误: $err'),
    );
  }
}
```

### 3.5 NotifierProvider（推荐的状态管理方式）⭐

`NotifierProvider` 是 Riverpod 2.x 推荐的状态管理方式，适用于复杂的状态逻辑。

```dart
// 1. 定义 Notifier 类
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // 返回初始状态
    return [];
  }

  void addTodo(String title) {
    state = [
      ...state,
      Todo(id: DateTime.now().toString(), title: title),
    ];
  }

  void toggleTodo(String id) {
    state = state.map((todo) {
      if (todo.id == id) {
        return Todo(id: todo.id, title: todo.title, isDone: !todo.isDone);
      }
      return todo;
    }).toList();
  }

  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

// 2. 创建 Provider
final todoListProvider = NotifierProvider<TodoListNotifier, List<Todo>>(() {
  return TodoListNotifier();
});

// 3. 在 widget 中使用
class TodoScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return ListTile(
          title: Text(todo.title),
          leading: Checkbox(
            value: todo.isDone,
            onChanged: (_) {
              ref.read(todoListProvider.notifier).toggleTodo(todo.id);
            },
          ),
        );
      },
    );
  }
}
```

**NotifierProvider vs StateProvider：**
- `StateProvider`：适合简单状态（bool、int、String、enum）
- `NotifierProvider`：适合复杂状态（有多个修改方法、需要业务逻辑）

### 3.6 AsyncNotifierProvider（异步状态管理）

`AsyncNotifierProvider` 是 `NotifierProvider` 的异步版本，适合需要异步初始化或异步操作的状态。

```dart
class UserListNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    // 异步初始化
    return await ref.watch(userRepositoryProvider).fetchUsers();
  }

  Future<void> addUser(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).createUser(name);
      return ref.read(userRepositoryProvider).fetchUsers();
    });
  }
}

final userListProvider =
    AsyncNotifierProvider<UserListNotifier, List<User>>(() {
  return UserListNotifier();
});
```

---

## 4. ref.watch vs ref.read vs ref.listen

这是 Riverpod 中最重要的三个方法，理解它们的区别至关重要。

### 4.1 ref.watch（响应式监听）

- **用途：** 监听 Provider 的值，当值变化时自动重建 widget
- **使用场景：** 在 `build` 方法中使用
- **特点：** 响应式，值变化时 widget 自动刷新

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ 在 build 中使用 watch
  final count = ref.watch(counterProvider);
  return Text('$count');
}
```

### 4.2 ref.read（一次性读取）

- **用途：** 只读取一次 Provider 的当前值，不监听变化
- **使用场景：** 在事件处理器（onPressed 等）中使用
- **特点：** 不会触发重建

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return ElevatedButton(
    // ✅ 在事件回调中使用 read
    onPressed: () {
      ref.read(counterProvider.notifier).state++;
    },
    child: const Text('增加'),
  );
}
```

### 4.3 ref.listen（监听并执行副作用）

- **用途：** 监听 Provider 变化并执行副作用（如弹窗、导航、打印日志）
- **使用场景：** 需要在值变化时做一些非 UI 操作
- **特点：** 不触发 widget 重建，而是执行回调

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(counterProvider, (previous, next) {
    if (next >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('计数达到 10 了！')),
      );
    }
  });

  return const SizedBox();
}
```

### 4.4 三者对比总结

| 方法 | 触发重建 | 使用位置 | 典型场景 |
|------|---------|---------|---------|
| `ref.watch` | ✅ 是 | `build` 方法内 | 显示数据 |
| `ref.read` | ❌ 否 | 事件回调中 | 触发操作 |
| `ref.listen` | ❌ 否 | `build` 方法内 | 副作用（弹窗、导航） |

### 4.5 常见错误

```dart
// ❌ 错误：不要在 build 中使用 read
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.read(counterProvider); // 不会自动更新！
  return Text('$count');
}

// ❌ 错误：不要在回调中使用 watch
onPressed: () {
  final count = ref.watch(counterProvider); // 不必要的监听
}
```

---

## 5. autoDispose 和 family 修饰符

### 5.1 autoDispose

默认情况下，Provider 的状态会一直保存在内存中，即使没有 widget 在监听它。
使用 `autoDispose` 修饰符可以在没有监听者时自动释放状态。

```dart
// 当没有 widget 监听时，自动释放
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  final id = ref.watch(userIdProvider);
  return fetchUser(id);
});

// Notifier 版本
final counterProvider =
    NotifierProvider.autoDispose<CounterNotifier, int>(() {
  return CounterNotifier();
});

class CounterNotifier extends AutoDisposeNotifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}
```

**适用场景：**
- 页面级别的状态（页面离开后不再需要）
- 搜索结果（离开搜索页后释放）
- 表单状态

**注意：** 使用 `autoDispose` 时，Notifier 需要继承 `AutoDisposeNotifier` 而非 `Notifier`。

### 5.2 family

`family` 修饰符允许你根据参数创建不同的 Provider 实例。

```dart
// 根据 userId 获取不同的用户
final userProvider = FutureProvider.autoDispose.family<User, String>((ref, userId) async {
  return fetchUser(userId);
});

// 使用
final user = ref.watch(userProvider('user_123'));
```

**适用场景：**
- 根据 ID 获取不同的数据
- 根据参数筛选列表
- 分页加载

### 5.3 组合使用

```dart
// autoDispose + family
final todoDetailProvider =
    FutureProvider.autoDispose.family<Todo, String>((ref, todoId) async {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.getTodo(todoId);
});

// 在 widget 中使用
class TodoDetailPage extends ConsumerWidget {
  final String todoId;
  const TodoDetailPage({required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoDetailProvider(todoId));
    return todoAsync.when(
      data: (todo) => Text(todo.title),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('错误: $err'),
    );
  }
}
```

---

## 6. ConsumerWidget 和 ConsumerStatefulWidget

### 6.1 ConsumerWidget

`ConsumerWidget` 是 Riverpod 版本的 `StatelessWidget`，自动提供 `WidgetRef`。

```dart
class CounterDisplay extends ConsumerWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('计数: $count');
  }
}
```

### 6.2 ConsumerStatefulWidget

`ConsumerStatefulWidget` 是 Riverpod 版本的 `StatefulWidget`，在 State 中提供 `ref`。

```dart
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ 可以在 initState 中使用 ref
    ref.listenManual(searchResultsProvider, (previous, next) {
      // 处理搜索结果变化
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    return Column(
      children: [
        TextField(controller: _controller),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) => Text(results[index]),
          ),
        ),
      ],
    );
  }
}
```

### 6.3 Consumer

如果你只需要在 widget 树的某一部分使用 Provider，可以使用 `Consumer` widget：

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('这部分不需要 Provider'),
          // 只有这部分需要 Provider
          Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(counterProvider);
              return Text('$count');
            },
          ),
        ],
      ),
    );
  }
}
```

**使用 `Consumer` 的好处：** 缩小重建范围，提高性能。

---

## 7. 常见模式和最佳实践

### 7.1 Provider 组合

Riverpod 最强大的特性之一是 Provider 之间可以轻松组合：

```dart
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient);
});

final currentUserProvider = FutureProvider<User>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.fetchCurrentUser();
});
```

### 7.2 状态刷新

```dart
// 手动刷新 FutureProvider
ref.invalidate(userProvider);

// 或者使用 refresh 获取新值
final newValue = ref.refresh(userProvider);
```

### 7.3 调试技巧

使用 `ProviderObserver` 来观察所有 Provider 的变化：

```dart
class MyObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('Provider ${provider.name ?? provider.runtimeType}: $newValue');
  }
}

void main() {
  runApp(
    ProviderScope(
      observers: [MyObserver()],
      child: const MyApp(),
    ),
  );
}
```

### 7.4 代码组织建议

```
lib/
├── main.dart
├── providers/
│   ├── auth_provider.dart      // 认证相关 Provider
│   ├── todo_provider.dart      // Todo 相关 Provider
│   └── theme_provider.dart     // 主题相关 Provider
├── models/
│   ├── user.dart
│   └── todo.dart
├── screens/
│   ├── home_screen.dart
│   └── todo_screen.dart
└── widgets/
    ├── todo_item.dart
    └── filter_bar.dart
```

### 7.5 选择合适的 Provider 类型

```
需要暴露什么？
│
├── 只读值或计算值 → Provider
│
├── 简单可变状态（bool/int/enum）→ StateProvider
│
├── 异步一次性数据 → FutureProvider
│
├── 流数据 → StreamProvider
│
├── 复杂同步状态（带多个方法）→ NotifierProvider ⭐
│
└── 复杂异步状态（带异步方法）→ AsyncNotifierProvider ⭐
```

### 7.6 避免常见错误

1. **不要在 build 中使用 ref.read**
2. **不要在回调中使用 ref.watch**
3. **NotifierProvider 中不要直接修改 state 的属性，要创建新对象**
4. **不要忘记 ProviderScope**

```dart
// ❌ 错误：直接修改 state
void addTodo(Todo todo) {
  state.add(todo); // 不会触发更新！
}

// ✅ 正确：创建新列表
void addTodo(Todo todo) {
  state = [...state, todo];
}
```

---

## 8. 实战示例：Todo List

完整的示例代码请参考 [`lib/ch04_riverpod.dart`](../lib/ch04_riverpod.dart)。

该示例实现了一个带过滤功能的 Todo List 应用，包含：

- **数据模型：** `Todo` 类（id、title、isDone）
- **状态管理：** 使用 `NotifierProvider` 管理 todo 列表
- **过滤状态：** 使用 `StateProvider` 管理过滤条件
- **派生状态：** 使用 `Provider` 计算过滤后的列表
- **UI 交互：** 添加、切换完成状态、删除、过滤

### 关键代码结构

```dart
// Provider 定义
final todoListProvider = NotifierProvider<TodoListNotifier, List<Todo>>(...);
final todoFilterProvider = StateProvider<TodoFilter>(...);
final filteredTodosProvider = Provider<List<Todo>>(...);

// Widget 结构
ProviderScope
  └── MaterialApp
      └── TodoApp (ConsumerWidget)
          ├── AddTodoField
          ├── FilterButtons
          └── TodoList
              └── TodoItem (带 Checkbox 和删除按钮)
```

### 运行示例

```bash
cd flutter-state
flutter run lib/ch04_riverpod.dart
```

---

## 总结

| 特性 | Provider | Riverpod |
|------|----------|----------|
| 编译时安全 | ❌ | ✅ |
| 依赖 BuildContext | ✅ 需要 | ❌ 不需要 |
| 同类型多实例 | ❌ 冲突 | ✅ 支持 |
| Provider 组合 | ⚠️ ProxyProvider | ✅ ref.watch |
| 可测试性 | ⚠️ 一般 | ✅ 优秀 |
| 自动销毁 | ❌ | ✅ autoDispose |
| 参数化 Provider | ❌ | ✅ family |
| 异步支持 | ⚠️ 一般 | ✅ 内置 AsyncValue |

**推荐：** 新项目优先使用 Riverpod，它在各方面都优于 Provider。

---

## 参考资料

- [Riverpod 官方文档](https://riverpod.dev/)
- [Riverpod GitHub 仓库](https://github.com/rrousselGit/riverpod)
- [Flutter 状态管理对比](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
