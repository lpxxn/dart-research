# 第四章：ref 详解

> `ref` 是 Riverpod 中连接 Widget 和 Provider 的桥梁。本章深入学习 `ref` 的所有用法，掌握 `watch`、`read`、`listen`、`select` 的最佳使用场景。

## 目录

1. [ref 是什么](#1-ref-是什么)
2. [ref.watch — 响应式监听](#2-refwatch--响应式监听)
3. [ref.read — 一次性读取](#3-refread--一次性读取)
4. [ref.listen — 副作用监听](#4-reflisten--副作用监听)
5. [select — 精确监听](#5-select--精确监听)
6. [ConsumerWidget vs ConsumerStatefulWidget vs Consumer](#6-consumerwidget-vs-consumerstatefulwidget-vs-consumer)
7. [ref 使用规则总结](#7-ref-使用规则总结)
8. [实战示例](#8-实战示例)
9. [小结](#9-小结)

---

## 1. ref 是什么

`ref` 是一个对象，提供了读取/监听/操作 Provider 的能力。在不同的上下文中有两种类型的 ref：

| 类型 | 获取方式 | 使用场景 |
|------|----------|----------|
| `WidgetRef` | ConsumerWidget 的 `build(context, ref)` | Widget 中 |
| `Ref` | Provider/Notifier 的 `build()` 内 | Provider/Notifier 中 |

两者的 API 基本相同，都支持 `watch`、`read`、`listen`。

---

## 2. ref.watch — 响应式监听

### 2.1 基本用法

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当 counterProvider 的值变化时，build 方法会重新执行
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

### 2.2 特点

- **响应式**：值变化时自动触发 Widget 重建
- **只能在 build 中使用**：不要在回调（onPressed 等）中使用
- **可以多次调用**：一个 Widget 可以 watch 多个 Provider

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final name = ref.watch(nameProvider);           // 监听 1
  final age = ref.watch(ageProvider);             // 监听 2
  final theme = ref.watch(themeProvider);         // 监听 3
  // 任何一个变化都会触发重建
  return Text('$name, $age');
}
```

### 2.3 在 Notifier 中使用

```dart
class FilteredTodosNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // ✅ 在 Notifier 的 build() 中可以使用 ref.watch
    final todos = ref.watch(todosProvider);
    final filter = ref.watch(filterProvider);
    return _applyFilter(todos, filter);
  }
}
```

---

## 3. ref.read — 一次性读取

### 3.1 基本用法

```dart
ElevatedButton(
  onPressed: () {
    // 一次性读取当前值，不建立监听关系
    final count = ref.read(counterProvider);
    print('当前值：$count');

    // 读取 Notifier 并调用方法
    ref.read(counterProvider.notifier).increment();
  },
  child: Text('点击'),
)
```

### 3.2 使用场景

- **事件回调**：onPressed、onTap、onChanged
- **读取 .notifier 调用方法**：这是最常见的用法
- **一次性获取**：不需要响应式更新的场景

### 3.3 常见错误

```dart
// ❌ 错误：在 build 中使用 ref.read
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.read(counterProvider);  // 不会自动更新 UI！
  return Text('$count');
}

// ✅ 正确：在 build 中使用 ref.watch
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.watch(counterProvider);  // 自动更新 UI
  return Text('$count');
}
```

---

## 4. ref.listen — 副作用监听

### 4.1 基本用法

`ref.listen` 用于在值变化时执行**副作用**（如显示 SnackBar、导航、日志等），而不是重建 Widget。

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // 监听错误状态，显示 SnackBar
  ref.listen(errorProvider, (previous, next) {
    if (next != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next)),
      );
    }
  });

  return const Text('...');
}
```

### 4.2 参数说明

```dart
ref.listen<T>(
  provider,         // 要监听的 Provider
  (T? previous,     // 上一个值（首次为 null）
   T next) {        // 新值
    // 执行副作用
  },
);
```

### 4.3 与 ref.watch 的区别

| 对比 | ref.watch | ref.listen |
|------|-----------|------------|
| 作用 | 获取值并重建 Widget | 执行副作用 |
| 返回值 | 返回 Provider 的值 | 无返回值 |
| 触发时机 | 值变化时重建整个 Widget | 值变化时仅执行回调 |
| 典型用法 | 显示数据 | SnackBar、导航、日志 |

### 4.4 在 Notifier 中使用

```dart
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 在 Notifier 中监听其他 Provider 的变化
    ref.listen(tokenProvider, (prev, next) {
      if (next == null) {
        state = AuthState.loggedOut;
      }
    });
    return AuthState.initial;
  }
}
```

---

## 5. select — 精确监听

### 5.1 问题：过度重建

```dart
class User {
  final String name;
  final int age;
  User(this.name, this.age);
}

// 如果你只关心 name，但 age 变化也会触发重建
final user = ref.watch(userProvider);  // age 变了也重建 ❌
```

### 5.2 使用 select 精确监听

```dart
// ✅ 只有 name 变化时才重建
final name = ref.watch(userProvider.select((user) => user.name));

// ✅ 只有 age 变化时才重建
final age = ref.watch(userProvider.select((user) => user.age));

// ✅ 只关心列表长度
final count = ref.watch(todosProvider.select((todos) => todos.length));

// ✅ 复杂选择：只关心是否有未完成项
final hasActive = ref.watch(
  todosProvider.select((todos) => todos.any((t) => !t.isDone)),
);
```

### 5.3 select 工作原理

```
Provider 值变化
      │
      ▼
select 函数计算新的选择值
      │
      ├── 选择值没变 → 不重建 Widget ✅
      │
      └── 选择值变了 → 重建 Widget
```

### 5.4 select 可用于 listen

```dart
ref.listen(
  userProvider.select((user) => user.name),
  (previous, next) {
    print('name 从 $previous 变为 $next');
  },
);
```

---

## 6. ConsumerWidget vs ConsumerStatefulWidget vs Consumer

### 6.1 ConsumerWidget

替代 `StatelessWidget`，最常用：

```dart
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    return Text('$data');
  }
}
```

### 6.2 ConsumerStatefulWidget

替代 `StatefulWidget`，需要 `initState` / `dispose` 等生命周期时使用：

```dart
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // ✅ 在 initState 中可以使用 ref.read
    final initialValue = ref.read(myProvider);
    _controller.text = initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 在 build 中通过 ref 访问（不需要参数，使用 widget 的 ref）
    final data = ref.watch(myProvider);
    return TextField(controller: _controller);
  }
}
```

### 6.3 Consumer

当只需要在 Widget 树的**一小部分**使用 ref 时：

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('这部分不需要 ref'),

        // 只有这里需要 ref，使用 Consumer 限制重建范围
        Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(counterProvider);
            return Text('$count');
          },
        ),

        const Text('这部分也不需要 ref'),
      ],
    );
  }
}
```

### 6.4 选择指南

```
需要 ref？
│
├── 整个 Widget 需要 ref
│   ├── 不需要生命周期（initState 等）→ ConsumerWidget
│   └── 需要生命周期 → ConsumerStatefulWidget
│
└── 只有 Widget 树的一小部分需要 ref → Consumer
```

---

## 7. ref 使用规则总结

| 规则 | 说明 |
|------|------|
| build 中用 `ref.watch` | 响应式获取数据，值变时自动重建 |
| 回调中用 `ref.read` | 一次性读取或调用方法 |
| 副作用用 `ref.listen` | 值变时执行操作（SnackBar、导航等） |
| 精确监听用 `.select` | 只监听对象的某个字段，避免过度重建 |
| ❌ build 中别用 ref.read | 不会自动刷新 UI |
| ❌ 回调中别用 ref.watch | 多余的监听 |

---

## 8. 实战示例

本章代码演示：
- `ref.watch`：实时显示计数器、用户信息
- `ref.read`：按钮点击修改状态
- `ref.listen`：状态变化时显示 SnackBar
- `select`：精确监听用户名变化，避免 age 变化触发重建
- 三种 Consumer 组件的使用对比

---

## 9. 小结

| 知识点 | 要点 |
|--------|------|
| ref.watch | build 中使用，响应式重建 |
| ref.read | 回调中使用，一次性读取 |
| ref.listen | 副作用（SnackBar、导航） |
| .select | 精确监听某个字段，减少不必要的重建 |
| ConsumerWidget | 替代 StatelessWidget，最常用 |
| ConsumerStatefulWidget | 替代 StatefulWidget，需要生命周期 |
| Consumer | 只包裹需要 ref 的子树 |

> 📌 **下一章**将学习异步 Provider：FutureProvider、StreamProvider、AsyncNotifier。
