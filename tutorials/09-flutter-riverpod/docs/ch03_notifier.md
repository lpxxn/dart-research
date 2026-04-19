# 第三章：Notifier 与 NotifierProvider

> 当状态逻辑变得复杂时，`StateProvider` 就力不从心了。`Notifier` + `NotifierProvider` 是 Riverpod 2.x 推荐的状态管理模式，让你在类中封装状态和修改逻辑。

## 目录

1. [为什么需要 Notifier](#1-为什么需要-notifier)
2. [Notifier 基础](#2-notifier-基础)
3. [不可变状态与 copyWith](#3-不可变状态与-copywith)
4. [NotifierProvider 的声明方式](#4-notifierprovider-的声明方式)
5. [实战示例：购物车](#5-实战示例购物车)
6. [Notifier vs StateProvider 选择指南](#6-notifier-vs-stateprovider-选择指南)
7. [小结](#7-小结)

---

## 1. 为什么需要 Notifier

StateProvider 虽然简单，但存在以下限制：

```dart
// ❌ 问题一：无法封装业务逻辑
ref.read(cartProvider.notifier).state = [...state, item]; // 逻辑散落在 UI 中

// ❌ 问题二：无法做状态验证
ref.read(quantityProvider.notifier).state = -1; // 没人阻止非法值

// ❌ 问题三：复杂对象难以管理
ref.read(userProvider.notifier).state = User(
  name: ref.read(userProvider).name,
  age: newAge,  // 每次都要手动重建整个对象
);
```

**Notifier** 让你在一个类中集中管理状态和逻辑：

```dart
// ✅ 逻辑封装在 Notifier 中
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) { /* 封装添加逻辑 */ }
  void removeItem(String id) { /* 封装删除逻辑 */ }
  void updateQuantity(String id, int qty) { /* 封装数量验证 */ }
}
```

---

## 2. Notifier 基础

### 2.1 定义一个 Notifier

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() {
    // build() 返回初始状态，类似 StateProvider 的 (ref) => 0
    return 0;
  }

  void increment() {
    state = state + 1;  // 通过 state 属性读写状态
  }

  void decrement() {
    if (state > 0) state = state - 1;  // 可以加入业务逻辑
  }

  void reset() {
    state = 0;
  }
}
```

### 2.2 注册为 Provider

```dart
final counterProvider = NotifierProvider<CounterNotifier, int>(() {
  return CounterNotifier();
});
// 泛型参数：<Notifier类型, 状态类型>
```

### 2.3 在 Widget 中使用

```dart
class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听状态值
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          // 调用 Notifier 的方法
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: Text('+1'),
        ),
      ],
    );
  }
}
```

### 2.4 build() 方法详解

`build()` 是 Notifier 的核心方法：

| 特性 | 说明 |
|------|------|
| 返回值 | 初始状态 |
| 调用时机 | Provider 首次被读取时 |
| 可以用 ref | 在 build() 中可以使用 `ref.watch` / `ref.read` 依赖其他 Provider |
| 重新执行 | 当 build() 中 `ref.watch` 的依赖变化时，会重新执行 |

```dart
class UserGreetingNotifier extends Notifier<String> {
  @override
  String build() {
    // ✅ 可以在 build() 中依赖其他 Provider
    final userName = ref.watch(userNameProvider);
    return '你好, $userName！';
  }

  void updateGreeting(String greeting) {
    state = greeting;
  }
}
```

---

## 3. 不可变状态与 copyWith

### 3.1 为什么要不可变？

Riverpod 通过比较新旧 state 引用来判断是否通知监听者。如果你直接修改对象的属性（可变操作），引用不变，UI 不会更新：

```dart
// ❌ 错误：直接修改属性，引用不变，UI 不更新
state.name = 'Alice';

// ✅ 正确：创建新对象，引用改变，UI 更新
state = User(name: 'Alice', age: state.age);
```

### 3.2 copyWith 模式

给你的 Model 添加 `copyWith` 方法：

```dart
class User {
  final String name;
  final int age;
  final String email;

  const User({required this.name, required this.age, required this.email});

  // copyWith：只修改指定字段，其余保持不变
  User copyWith({String? name, int? age, String? email}) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }
}
```

在 Notifier 中使用：

```dart
class UserNotifier extends Notifier<User> {
  @override
  User build() => const User(name: '', age: 0, email: '');

  void updateName(String name) {
    state = state.copyWith(name: name);  // 只改 name，其余不变
  }

  void updateAge(int age) {
    if (age < 0 || age > 150) return;  // 业务验证
    state = state.copyWith(age: age);
  }
}
```

---

## 4. NotifierProvider 的声明方式

```dart
// 完整声明
final myProvider = NotifierProvider<MyNotifier, MyState>(() {
  return MyNotifier();
});

// 简写（tear-off）
final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);
```

### 声明模板

```dart
// 1. 定义状态类
class TodoState { ... }

// 2. 定义 Notifier
class TodoNotifier extends Notifier<TodoState> {
  @override
  TodoState build() => TodoState(...);  // 初始状态

  void doSomething() {
    state = state.copyWith(...);        // 修改状态
  }
}

// 3. 声明 Provider
final todoProvider = NotifierProvider<TodoNotifier, TodoState>(TodoNotifier.new);

// 4. Widget 中使用
// 读状态：ref.watch(todoProvider)
// 调方法：ref.read(todoProvider.notifier).doSomething()
```

---

## 5. 实战示例：购物车

本章代码演示一个完整的购物车功能：

- `Product` 产品数据模型
- `CartItem` 购物车项（包含产品和数量）
- `CartNotifier` 管理购物车状态（添加、删除、增减数量）
- 使用派生 Provider 计算总价和总数

---

## 6. Notifier vs StateProvider 选择指南

| 场景 | 推荐 |
|------|------|
| 简单开关（bool） | StateProvider |
| 搜索关键词（String） | StateProvider |
| 排序方式（enum） | StateProvider |
| 包含业务逻辑的状态 | **Notifier** |
| 复杂对象（多字段） | **Notifier** |
| 需要验证的状态变更 | **Notifier** |
| 需要组合多个操作 | **Notifier** |
| 涉及异步操作 | **AsyncNotifier**（第五章） |

---

## 7. 小结

| 知识点 | 要点 |
|--------|------|
| Notifier | 在类中封装状态和修改逻辑 |
| build() | 返回初始状态，可依赖其他 Provider |
| state | 读写状态的属性 |
| 不可变状态 | 每次修改创建新对象，不要直接改属性 |
| copyWith | 只修改指定字段，其余保持不变 |
| NotifierProvider | 注册 Notifier，声明泛型 `<Notifier类型, 状态类型>` |

> 📌 **下一章**将深入学习 `ref` 的各种用法：`watch`、`read`、`listen`、`select`。
