# 第三章：Provider 状态管理

## 目录

1. [Provider 的设计理念](#1-provider-的设计理念)
2. [ChangeNotifierProvider 详解](#2-changenotifierprovider-详解)
3. [MultiProvider 用法](#3-multiprovider-用法)
4. [Consumer 和 Selector](#4-consumer-和-selector)
5. [ProxyProvider](#5-proxyprovider)
6. [context.watch vs context.read vs context.select](#6-contextwatch-vs-contextread-vs-contextselect)
7. [常见错误和最佳实践](#7-常见错误和最佳实践)
8. [示例代码](#8-示例代码)

---

## 1. Provider 的设计理念

### 1.1 从 InheritedWidget 说起

在 Flutter 中，跨组件共享状态的原生方式是使用 `InheritedWidget`。它允许子组件访问祖先组件中的数据，而不需要层层传递参数。但直接使用 `InheritedWidget` 有以下痛点：

- **模板代码繁多**：每次都需要创建一个继承自 `InheritedWidget` 的类，重写 `updateShouldNotify`，并提供一个静态的 `of` 方法。
- **生命周期管理复杂**：需要手动管理状态对象的创建和销毁。
- **不支持响应式更新**：`InheritedWidget` 本身不监听变化，需要配合 `StatefulWidget` 使用。
- **类型安全性差**：获取数据时需要手动处理类型转换和空值情况。

```dart
// 原始 InheritedWidget 的写法（繁琐）
class MyData extends InheritedWidget {
  final int count;
  
  const MyData({
    required this.count,
    required Widget child,
  }) : super(child: child);

  static MyData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyData>();
  }

  @override
  bool updateShouldNotify(MyData oldWidget) {
    return count != oldWidget.count;
  }
}
```

### 1.2 Provider 是 InheritedWidget 的语法糖

Provider 包由 Remi Rousselet 开发，是 Flutter 官方推荐的状态管理方案之一。它本质上是对 `InheritedWidget` 的封装，提供了：

- **简洁的 API**：用几行代码就能完成状态的注入和读取。
- **自动生命周期管理**：Provider 会在不需要时自动调用 `dispose`。
- **类型安全**：通过泛型确保类型正确，编译期即可发现错误。
- **多种 Provider 类型**：针对不同场景提供了 `Provider`、`ChangeNotifierProvider`、`FutureProvider`、`StreamProvider` 等。
- **DevTools 支持**：可以在 Flutter DevTools 中查看 Provider 的状态。

### 1.3 为什么需要 Provider

| 场景 | setState | InheritedWidget | Provider |
|------|----------|-----------------|----------|
| 单组件内状态 | ✅ 简单直接 | ❌ 过度设计 | ❌ 过度设计 |
| 父子组件共享 | ⚠️ 回调层层传递 | ✅ 可以但繁琐 | ✅ 简洁 |
| 跨层级共享 | ❌ 不可行 | ⚠️ 模板代码多 | ✅ 简洁 |
| 多状态组合 | ❌ 混乱 | ❌ 极其复杂 | ✅ MultiProvider |
| 精准重建控制 | ❌ 无法控制 | ⚠️ 需手动优化 | ✅ Selector/Consumer |

### 1.4 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
```

然后执行：

```bash
flutter pub get
```

---

## 2. ChangeNotifierProvider 详解

### 2.1 ChangeNotifier 基础

`ChangeNotifier` 是 Flutter 框架中的一个类，实现了观察者模式。当数据变化时，调用 `notifyListeners()` 通知所有监听者。

```dart
class CounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // 通知所有监听者数据已改变
  }
}
```

**关键点**：
- 继承 `ChangeNotifier` 而不是混入（mixin），因为需要 `dispose` 的生命周期。
- 每次状态改变后必须调用 `notifyListeners()`，否则 UI 不会更新。
- 不要在 `notifyListeners()` 中传递数据，它只是一个信号。

### 2.2 创建 ChangeNotifierProvider

`ChangeNotifierProvider` 负责创建 `ChangeNotifier` 实例并将其提供给子树：

```dart
ChangeNotifierProvider(
  create: (context) => CounterModel(),
  child: MyApp(),
)
```

**`create` 参数**：
- 接收一个 `BuildContext`，返回一个 `ChangeNotifier` 实例。
- 该实例只会被创建一次（懒加载，首次被读取时创建）。
- Provider 会在自身被移除时自动调用 `dispose()`。

**在 `main` 中使用**：

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CounterModel(),
      child: const MyApp(),
    ),
  );
}
```

### 2.3 读取 Provider 中的数据

在子组件中读取数据有多种方式：

```dart
// 方式1：context.watch — 监听变化并重建
final counter = context.watch<CounterModel>();
Text('${counter.count}');

// 方式2：context.read — 只读取一次，不监听
final counter = context.read<CounterModel>();
counter.increment(); // 常用于事件回调中

// 方式3：Consumer — 限制重建范围
Consumer<CounterModel>(
  builder: (context, counter, child) {
    return Text('${counter.count}');
  },
)
```

### 2.4 生命周期

Provider 管理的对象有清晰的生命周期：

1. **创建**：当 Provider widget 首次插入 widget 树时（懒加载模式下是首次被访问时）。
2. **更新通知**：当 `notifyListeners()` 被调用时，所有依赖该 Provider 的 widget 会重建。
3. **销毁**：当 Provider widget 从 widget 树中移除时，会自动调用 `ChangeNotifier.dispose()`。

```dart
class TodoListNotifier extends ChangeNotifier {
  final List<TodoModel> _todos = [];

  // 不要忘记在 dispose 中清理资源
  @override
  void dispose() {
    // 清理订阅、定时器等
    super.dispose();
  }
}
```

> ⚠️ **注意**：不要在 Provider 的 `create` 回调之外创建 `ChangeNotifier`，否则 Provider 无法管理其生命周期。

```dart
// ❌ 错误：在外部创建
final model = CounterModel();
ChangeNotifierProvider.value(value: model, child: MyApp());
// model 不会被 Provider 自动 dispose

// ✅ 正确：在 create 中创建
ChangeNotifierProvider(create: (_) => CounterModel(), child: MyApp());
```

---

## 3. MultiProvider 用法

### 3.1 为什么需要 MultiProvider

实际应用中通常需要多个状态对象。如果嵌套使用 Provider，代码会变得很深：

```dart
// ❌ 嵌套地狱
ChangeNotifierProvider(
  create: (_) => AuthModel(),
  child: ChangeNotifierProvider(
    create: (_) => TodoModel(),
    child: ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: MyApp(),
    ),
  ),
)
```

### 3.2 使用 MultiProvider 简化

`MultiProvider` 将多个 Provider 扁平化：

```dart
// ✅ 使用 MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthModel()),
    ChangeNotifierProvider(create: (_) => TodoModel()),
    ChangeNotifierProvider(create: (_) => ThemeModel()),
  ],
  child: MyApp(),
)
```

**注意事项**：
- `providers` 列表中的顺序很重要：排在前面的 Provider 可以被后面的 Provider 访问。
- 如果后面的 Provider 依赖前面的，应使用 `ProxyProvider`（见第5节）。
- 每个 Provider 管理的类型应该唯一，同一类型的多个 Provider 会导致后者覆盖前者。

### 3.3 实际项目结构建议

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // 基础服务层
        Provider(create: (_) => ApiService()),
        
        // 状态管理层
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => TodoListNotifier()),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 4. Consumer 和 Selector

### 4.1 Consumer：限制重建范围

`Consumer` 是一个 widget，它监听指定的 Provider 并在数据变化时仅重建自身包裹的部分。

```dart
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('TodoPage build'); // 不会因 todo 变化而重新执行
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TodoListNotifier>(
          builder: (context, todoList, child) {
            // 只有这里会重建
            return Text('待办事项 (${todoList.todos.length})');
          },
        ),
      ),
      body: Consumer<TodoListNotifier>(
        builder: (context, todoList, child) {
          return ListView.builder(
            itemCount: todoList.todos.length,
            itemBuilder: (_, index) => TodoTile(todo: todoList.todos[index]),
          );
        },
      ),
    );
  }
}
```

**Consumer 的 `child` 参数**：

`child` 用于缓存不需要重建的子组件：

```dart
Consumer<CounterModel>(
  builder: (context, counter, child) {
    return Column(
      children: [
        Text('Count: ${counter.count}'), // 会重建
        child!, // 不会重建（被缓存了）
      ],
    );
  },
  child: const HeavyWidget(), // 传入不变的子组件
)
```

### 4.2 Selector：精准选择

`Selector` 比 `Consumer` 更精确——它只在选择的特定值发生变化时才触发重建。

```dart
// 只在 doneCount 变化时重建，添加新的未完成 todo 不会触发
Selector<TodoListNotifier, int>(
  selector: (_, notifier) => notifier.doneCount,
  builder: (context, doneCount, child) {
    return Text('已完成: $doneCount');
  },
)
```

**Selector 的工作原理**：
1. `selector` 函数从 Provider 的数据中提取一个值。
2. 每次 Provider 通知变化时，Selector 会重新调用 `selector` 获取新值。
3. 将新值与旧值比较（默认使用 `==`）。
4. 只有当值不同时，才调用 `builder` 重建。

**使用场景**：
- Provider 中有很多字段，但当前 widget 只依赖其中一个。
- 列表长度变化时更新计数器，但不需要因为单个 item 的变化而重建。
- 性能敏感的 widget，需要尽量减少重建次数。

### 4.3 Consumer2, Consumer3...

当一个 widget 需要依赖多个 Provider 时：

```dart
Consumer2<AuthNotifier, TodoListNotifier>(
  builder: (context, auth, todoList, child) {
    if (!auth.isLoggedIn) return LoginPrompt();
    return TodoList(todos: todoList.todos);
  },
)
```

Provider 包提供了 `Consumer` 到 `Consumer6`，满足不同数量的依赖需求。

---

## 5. ProxyProvider

### 5.1 什么是 ProxyProvider

`ProxyProvider` 用于创建一个依赖于其他 Provider 的 Provider。当被依赖的 Provider 变化时，`ProxyProvider` 会自动更新。

### 5.2 基本用法

```dart
MultiProvider(
  providers: [
    // 先提供 AuthNotifier
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
    
    // ApiService 依赖 AuthNotifier 提供的 token
    ProxyProvider<AuthNotifier, ApiService>(
      update: (_, auth, previousApi) {
        return ApiService(token: auth.token);
      },
    ),
  ],
  child: MyApp(),
)
```

### 5.3 ChangeNotifierProxyProvider

如果依赖其他 Provider 的对象本身也是 `ChangeNotifier`：

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
    
    ChangeNotifierProxyProvider<AuthNotifier, TodoListNotifier>(
      create: (_) => TodoListNotifier(),
      update: (_, auth, previous) {
        // previous 是上一次的 TodoListNotifier 实例
        previous!.updateAuth(auth.token);
        return previous;
      },
    ),
  ],
  child: MyApp(),
)
```

### 5.4 ProxyProvider2, ProxyProvider3...

依赖多个 Provider 时：

```dart
ProxyProvider2<AuthNotifier, SettingsNotifier, ApiService>(
  update: (_, auth, settings, previous) {
    return ApiService(
      token: auth.token,
      baseUrl: settings.apiUrl,
    );
  },
)
```

> ⚠️ **注意**：`ProxyProvider` 的 `update` 会在任何一个依赖变化时调用，确保 `update` 方法是幂等的。

---

## 6. context.watch vs context.read vs context.select

### 6.1 三者对比

| 方法 | 监听变化 | 触发重建 | 适用场景 |
|------|---------|---------|---------|
| `context.watch<T>()` | ✅ | ✅ 整个 build 方法 | 在 `build` 方法中读取并监听 |
| `context.read<T>()` | ❌ | ❌ | 在事件回调中读取（一次性） |
| `context.select<T, R>()` | ✅ | ✅ 仅选定值变化时 | 在 `build` 中选择性监听 |

### 6.2 context.watch

```dart
@override
Widget build(BuildContext context) {
  // 监听 TodoListNotifier 的所有变化
  final todoList = context.watch<TodoListNotifier>();
  return Text('共 ${todoList.todos.length} 个待办');
}
```

**使用场景**：
- 在 `build` 方法中需要监听变化的数据。
- 当 Provider 数据的任何变化都需要触发当前 widget 重建时。

### 6.3 context.read

```dart
@override
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      // 在事件回调中使用 read，不需要监听
      context.read<TodoListNotifier>().add('新待办');
    },
    child: const Text('添加'),
  );
}
```

**使用场景**：
- 在 `onPressed`、`onTap` 等事件回调中调用方法。
- 在 `initState` 中获取 Provider（但不能监听）。
- 任何不需要响应数据变化的场景。

> ⚠️ **绝对不要在 `build` 方法中使用 `context.read` 来获取显示数据**，否则数据变化时 UI 不会更新。

### 6.4 context.select

```dart
@override
Widget build(BuildContext context) {
  // 只监听 doneCount 的变化
  final doneCount = context.select<TodoListNotifier, int>(
    (notifier) => notifier.doneCount,
  );
  return Text('已完成: $doneCount');
}
```

**使用场景**：
- 只关心 Provider 中的某个特定字段。
- 需要避免因不相关的字段变化而导致的不必要重建。
- 性能优化的关键手段。

### 6.5 实际使用示例

```dart
class TodoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ 用 select 只监听计数变化
    final totalCount = context.select<TodoListNotifier, int>(
      (n) => n.todos.length,
    );
    final doneCount = context.select<TodoListNotifier, int>(
      (n) => n.doneCount,
    );

    return Row(
      children: [
        Text('总计: $totalCount'),
        Text('已完成: $doneCount'),
        ElevatedButton(
          onPressed: () {
            // ✅ 用 read 触发操作
            context.read<TodoListNotifier>().clearDone();
          },
          child: const Text('清除已完成'),
        ),
      ],
    );
  }
}
```

---

## 7. 常见错误和最佳实践

### 7.1 常见错误

#### 错误 1：在 build 中使用 read

```dart
// ❌ 错误：数据变化时 UI 不更新
@override
Widget build(BuildContext context) {
  final count = context.read<CounterModel>().count;
  return Text('$count');
}

// ✅ 正确：使用 watch 或 select
@override
Widget build(BuildContext context) {
  final count = context.watch<CounterModel>().count;
  return Text('$count');
}
```

#### 错误 2：在回调中使用 watch

```dart
// ❌ 错误：watch 不应该在回调中使用
onPressed: () {
  context.watch<CounterModel>().increment();
}

// ✅ 正确：在回调中使用 read
onPressed: () {
  context.read<CounterModel>().increment();
}
```

#### 错误 3：Provider 找不到（ProviderNotFoundException）

```dart
// ❌ 错误：在 Provider 的同一层级访问
ChangeNotifierProvider(
  create: (_) => MyModel(),
  // 这里的 context 还没有 MyModel
  child: Text(context.watch<MyModel>().value), // 报错！
)

// ✅ 正确：在子 widget 中访问
ChangeNotifierProvider(
  create: (_) => MyModel(),
  child: const MyWidget(), // MyWidget 的 build 中可以访问 MyModel
)
```

#### 错误 4：在 create 中使用 context 访问其他 Provider

```dart
// ❌ 可能报错：create 只在首次调用，之后不会更新
ChangeNotifierProvider(
  create: (context) {
    final auth = context.read<AuthNotifier>();
    return TodoNotifier(auth.token);
  },
  child: MyApp(),
)

// ✅ 正确：使用 ProxyProvider 处理依赖关系
ChangeNotifierProxyProvider<AuthNotifier, TodoNotifier>(
  create: (_) => TodoNotifier(),
  update: (_, auth, previous) => previous!..updateToken(auth.token),
)
```

#### 错误 5：在 notifyListeners 之前没有实际改变数据

```dart
// ❌ 无意义的通知
void doNothing() {
  notifyListeners(); // 没有改变任何数据就通知
}

// ✅ 只在数据真正变化时通知
void toggle(String id) {
  final todo = _todos.firstWhere((t) => t.id == id);
  todo.isDone = !todo.isDone;
  notifyListeners();
}
```

### 7.2 最佳实践

#### 实践 1：保持 Notifier 职责单一

```dart
// ✅ 好的：每个 Notifier 管理一类状态
class AuthNotifier extends ChangeNotifier { ... }
class TodoListNotifier extends ChangeNotifier { ... }
class ThemeNotifier extends ChangeNotifier { ... }

// ❌ 不好的：一个 Notifier 管理所有状态
class AppState extends ChangeNotifier {
  User? user;
  List<Todo> todos;
  ThemeMode theme;
  // ... 所有东西都在这里
}
```

#### 实践 2：使用 Selector 优化性能

```dart
// ✅ 只在需要的数据变化时重建
Selector<TodoListNotifier, int>(
  selector: (_, n) => n.doneCount,
  builder: (_, count, __) => Text('完成: $count'),
)
```

#### 实践 3：不要暴露 ChangeNotifier 的内部状态

```dart
// ❌ 不好：外部可以直接修改列表
class TodoListNotifier extends ChangeNotifier {
  List<Todo> todos = [];
}

// ✅ 好的：通过 getter 返回不可变视图
class TodoListNotifier extends ChangeNotifier {
  final List<Todo> _todos = [];
  List<Todo> get todos => List.unmodifiable(_todos);
}
```

#### 实践 4：合理使用 Consumer 的 child 参数

```dart
// ✅ 将不变的部分作为 child 传入
Consumer<ThemeNotifier>(
  builder: (_, theme, child) {
    return Container(
      color: theme.backgroundColor,
      child: child, // 不会重建
    );
  },
  child: const ExpensiveWidget(), // 缓存
)
```

#### 实践 5：避免使用 withOpacity

```dart
// ❌ 不推荐：withOpacity 性能较差
color: Colors.blue.withOpacity(0.5),

// ✅ 推荐：使用 withValues
color: Colors.blue.withValues(alpha: 0.5),
```

---

## 8. 示例代码

完整的 Todo List 示例请参考：

📄 **[lib/ch03_provider.dart](../lib/ch03_provider.dart)**

该示例实现了一个完整的 Todo 应用，包含：
- `TodoModel` 数据类
- `TodoListNotifier` 状态管理类（增删改查）
- 使用 `ChangeNotifierProvider` 提供状态
- 使用 `Consumer` 和 `Selector` 优化重建
- 使用 `context.watch` 和 `context.read` 读取状态
- 展示已完成数量的精准更新

### 运行示例

```bash
cd flutter-state
flutter pub get
flutter run lib/ch03_provider.dart
```

### 示例架构

```
lib/ch03_provider.dart
├── TodoModel          — 数据模型
├── TodoListNotifier   — 状态管理（ChangeNotifier）
├── main()             — 入口，创建 ChangeNotifierProvider
├── TodoApp            — MaterialApp
├── TodoHomePage       — 主页面
├── AddTodoWidget      — 添加 Todo 输入框
├── TodoStatsWidget    — 统计信息（使用 Selector）
└── TodoListWidget     — Todo 列表（使用 Consumer）
```

---

## 扩展阅读

- [Provider 官方文档](https://pub.dev/packages/provider)
- [Flutter 官方状态管理指南](https://docs.flutter.dev/data-and-backend/state-mgmt/simple)
- [Provider 源码分析](https://github.com/rrousselGit/provider)

---

> **下一章预告**：第四章将介绍 Riverpod——Provider 作者推出的下一代状态管理方案，解决了 Provider 的一些固有限制。
