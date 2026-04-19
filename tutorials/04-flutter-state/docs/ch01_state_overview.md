# 第一章：状态管理概论

> 📖 本章配套示例代码：[`lib/ch01_state_overview.dart`](../lib/ch01_state_overview.dart)

---

## 目录

1. [什么是状态？](#1-什么是状态)
2. [UI = f(state) 概念详解](#2-ui--fstate-概念详解)
3. [短暂状态 vs 应用状态](#3-短暂状态-vs-应用状态)
4. [状态提升（Lifting State Up）](#4-状态提升lifting-state-up)
5. [主流方案概览与选型指南](#5-主流方案概览与选型指南)
6. [何时使用哪种方案——决策树](#6-何时使用哪种方案决策树)
7. [最佳实践总结](#7-最佳实践总结)

---

## 1. 什么是状态？

在 Flutter 中，**状态（State）** 是指在应用运行期间可能发生变化的任何数据。它决定了 UI 在某一时刻的呈现方式。

简单来说：

- 一个复选框是否被选中 → 状态
- 一个文本输入框中的文字 → 状态
- 用户是否已登录 → 状态
- 购物车里有哪些商品 → 状态
- 从网络请求拿到的数据 → 状态

> 💡 **核心思想**：Flutter 的 UI 是状态的函数。状态改变时，框架会重新构建（rebuild）受影响的 Widget 树，从而反映最新的状态。

---

## 2. UI = f(state) 概念详解

Flutter 采用**声明式 UI** 范式。与传统命令式框架（如 Android XML + Java/Kotlin、iOS Storyboard + Swift）不同，Flutter 不需要你手动操作 UI 元素来更新界面。

### 2.1 命令式 vs 声明式

**命令式（Imperative）**——传统方式：

```java
// Android 伪代码
TextView tvCount = findViewById(R.id.tv_count);
tvCount.setText("当前计数: " + count);
button.setOnClickListener(v -> {
    count++;
    tvCount.setText("当前计数: " + count); // 手动更新 UI
});
```

**声明式（Declarative）**——Flutter 方式：

```dart
// Flutter 声明式
@override
Widget build(BuildContext context) {
  return Text('当前计数: $count'); // UI 是状态的函数
}
```

### 2.2 公式拆解

```
UI = f(state)
```

| 符号 | 含义 |
|------|------|
| `UI` | 当前屏幕上显示的界面 |
| `f` | `build()` 方法——将状态映射为 Widget 树的函数 |
| `state` | 应用当前的数据/状态 |

当 `state` 发生变化时：

1. 调用 `setState()`（或其他状态管理机制通知框架）
2. Flutter 框架标记该 Widget 为 "dirty"
3. 框架在下一帧调用 `build()` 方法
4. 新的 Widget 树与旧树进行 diff（Element 树对比）
5. 只更新发生变化的部分到 RenderObject 树
6. 屏幕刷新，用户看到最新 UI

```dart
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0; // 这就是状态

  @override
  Widget build(BuildContext context) {
    // build() 就是 f()，_count 就是 state
    // 返回的 Widget 树就是 UI
    return Column(
      children: [
        Text('计数: $_count'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _count++; // 修改状态
            });
            // setState 通知框架重新调用 build()
          },
          child: const Text('增加'),
        ),
      ],
    );
  }
}
```

> 🔑 **关键理解**：你不需要告诉 Flutter "把文字从 5 改成 6"，你只需要说 "状态现在是 6"，Flutter 会自动算出需要更新什么。

---

## 3. 短暂状态 vs 应用状态

Flutter 官方将状态分为两类：**短暂状态（Ephemeral State）** 和 **应用状态（App State）**。

### 3.1 短暂状态（Ephemeral State）

短暂状态也叫 **局部状态（Local State）** 或 **UI 状态**。它只在单个 Widget 内部使用，不需要被其他 Widget 访问。

**典型例子：**

| 场景 | 状态数据 | 为什么是短暂状态 |
|------|---------|----------------|
| `BottomNavigationBar` 当前选中的 tab | `int _currentIndex` | 只有导航栏自己需要知道 |
| `PageView` 当前页面 | `int _currentPage` | 只影响页面滑动 |
| 一个动画的进度 | `double _animationValue` | 只在动画 Widget 内部使用 |
| `TextField` 中正在输入的文字 | `TextEditingController` | 通常只有输入框自己需要 |
| `ExpansionTile` 是否展开 | `bool _isExpanded` | 只影响这一个折叠面板 |

**管理方式：** 使用 `StatefulWidget` + `setState()`

```dart
class AnimatedLike extends StatefulWidget {
  const AnimatedLike({super.key});

  @override
  State<AnimatedLike> createState() => _AnimatedLikeState();
}

class _AnimatedLikeState extends State<AnimatedLike> {
  bool _isLiked = false; // 短暂状态：只有这个 Widget 关心

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isLiked ? Icons.favorite : Icons.favorite_border,
        color: _isLiked ? Colors.red : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _isLiked = !_isLiked; // 用 setState 管理
        });
      },
    );
  }
}
```

### 3.2 应用状态（App State）

应用状态是需要在多个 Widget、多个页面甚至整个应用中共享的状态。

**典型例子：**

| 场景 | 状态数据 | 为什么是应用状态 |
|------|---------|----------------|
| 用户登录信息 | `User currentUser` | 整个应用都需要知道用户是否登录 |
| 购物车 | `List<CartItem> items` | 商品列表页、购物车页、结算页都需要 |
| 消息通知 | `int unreadCount` | 多个页面的角标都要显示 |
| 主题设置 | `ThemeMode mode` | 影响整个应用的外观 |
| 多语言设置 | `Locale locale` | 影响整个应用的文字 |

**管理方式：** 需要更强大的状态管理方案（InheritedWidget、Provider、Riverpod、BLoC 等）

### 3.3 如何判断？

问自己这几个问题：

```
这个状态，是否只有一个 Widget 需要？
  ├── 是 → 短暂状态，用 setState
  └── 否 → 继续判断
        这个状态，是否需要跨页面/跨组件共享？
          ├── 是 → 应用状态，用状态管理方案
          └── 不确定 → 先用 setState，等需要共享时再提升
```

> 💡 **实用建议**：不要过度设计。如果你不确定一个状态是短暂状态还是应用状态，先用 `setState`。当你发现需要在多个地方访问这个状态时，再将其提升为应用状态。

---

## 4. 状态提升（Lifting State Up）

### 4.1 什么是状态提升？

当两个或多个子组件需要共享同一份状态时，将状态**提升到它们最近的共同父组件**中管理。父组件持有状态，并通过构造函数参数将状态和修改状态的回调传递给子组件。

### 4.2 问题场景

假设我们有一个购物应用：

```
App
├── ProductList（商品列表，需要"添加到购物车"功能）
└── CartBadge（购物车角标，需要显示购物车商品数量）
```

如果购物车数据放在 `ProductList` 中，`CartBadge` 就访问不到。如果放在 `CartBadge` 中，`ProductList` 又无法添加商品。

**解决方案：** 将购物车状态提升到它们的共同父组件 `App`。

### 4.3 实现步骤

**第一步：在父组件中定义状态和操作方法**

```dart
class ShoppingApp extends StatefulWidget {
  const ShoppingApp({super.key});

  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  // 状态提升到父组件
  final List<String> _cartItems = [];

  // 添加商品的方法
  void _addToCart(String product) {
    setState(() {
      _cartItems.add(product);
    });
  }

  // 移除商品的方法
  void _removeFromCart(String product) {
    setState(() {
      _cartItems.remove(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 把状态和回调传递给子组件
        CartBadge(itemCount: _cartItems.length),
        ProductList(
          cartItems: _cartItems,
          onAddToCart: _addToCart,
        ),
      ],
    );
  }
}
```

**第二步：子组件通过参数接收状态和回调**

```dart
class CartBadge extends StatelessWidget {
  final int itemCount; // 从父组件接收状态

  const CartBadge({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text('$itemCount'),
      child: const Icon(Icons.shopping_cart),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<String> cartItems; // 从父组件接收状态
  final ValueChanged<String> onAddToCart; // 从父组件接收回调

  const ProductList({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final products = ['苹果', '香蕉', '橙子'];
    return Column(
      children: products.map((product) {
        final isInCart = cartItems.contains(product);
        return ListTile(
          title: Text(product),
          trailing: isInCart
              ? const Icon(Icons.check, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () => onAddToCart(product),
                ),
        );
      }).toList(),
    );
  }
}
```

### 4.4 状态提升的数据流

```
        ┌──────────────────┐
        │   父组件 (State)  │
        │   _cartItems = [] │
        │   _addToCart()     │
        │   _removeFromCart()│
        └──────┬───────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
  ┌──────────┐  ┌───────────┐
  │ CartBadge │  │ ProductList│
  │ itemCount │  │ cartItems  │
  │ (只读)    │  │ onAddToCart │
  └──────────┘  └───────────┘
```

数据流向：**自上而下（单向数据流）**
- 状态从父组件流向子组件（通过构造函数参数）
- 事件从子组件流向父组件（通过回调函数）

### 4.5 状态提升的局限性

| 问题 | 说明 |
|------|------|
| **Props Drilling** | 当 Widget 树很深时，状态需要层层传递，中间组件被迫接收并转发它们不关心的参数 |
| **不必要的重建** | 父组件 setState 会导致所有子组件重建，即使某些子组件的数据没有变化 |
| **扩展性差** | 随着应用复杂度增加，共同父组件可能变得非常臃肿 |

这些局限性正是更高级的状态管理方案（Provider、Riverpod、BLoC 等）要解决的问题。

> ✅ 完整的状态提升示例请参考配套代码文件：[`lib/ch01_state_overview.dart`](../lib/ch01_state_overview.dart)

---

## 5. 主流方案概览与选型指南

### 5.1 方案一览

#### setState

最基础的状态管理方式，适用于单个 Widget 内部的短暂状态。

```dart
setState(() {
  _count++;
});
```

**优点：**
- 零学习成本，Flutter 内置
- 代码简单直观
- 不需要额外依赖

**缺点：**
- 无法跨组件共享状态
- 容易导致状态逻辑和 UI 逻辑混在一起
- Widget 树深时 Props Drilling 严重

---

#### InheritedWidget

Flutter 框架内置的跨组件状态共享机制。Provider 等方案的底层基础。

```dart
class CartInherited extends InheritedWidget {
  final List<String> items;
  final ValueChanged<String> onAdd;

  const CartInherited({
    super.key,
    required this.items,
    required this.onAdd,
    required super.child,
  });

  static CartInherited of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartInherited>()!;
  }

  @override
  bool updateShouldNotify(CartInherited oldWidget) {
    return items != oldWidget.items;
  }
}
```

**优点：**
- Flutter 内置，无额外依赖
- 避免了 Props Drilling
- 性能较好（可以精确控制通知范围）

**缺点：**
- 样板代码多（boilerplate）
- 使用起来不够方便
- 不支持多个同类型的 InheritedWidget 嵌套（会被覆盖）

---

#### Provider

对 InheritedWidget 的封装，是 Flutter 官方推荐的状态管理方案之一。

```dart
// 定义状态
class CartModel extends ChangeNotifier {
  final List<String> _items = [];
  List<String> get items => _items;

  void add(String item) {
    _items.add(item);
    notifyListeners(); // 通知监听者
  }
}

// 提供状态
ChangeNotifierProvider(
  create: (_) => CartModel(),
  child: const MyApp(),
);

// 消费状态
final cart = context.watch<CartModel>();
Text('购物车: ${cart.items.length} 件');
```

**优点：**
- 官方推荐，社区广泛使用
- 大幅减少样板代码
- 易于测试
- 学习成本适中

**缺点：**
- 依赖 `BuildContext`
- 复杂场景下仍有局限（如组合多个 Provider）
- `ChangeNotifier` 模式对大型应用可能不够优雅

---

#### Riverpod

Provider 作者的下一代作品，解决了 Provider 的诸多限制。

```dart
// 定义 provider（全局声明，编译时安全）
final cartProvider = StateNotifierProvider<CartNotifier, List<String>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<String>> {
  CartNotifier() : super([]);

  void add(String item) {
    state = [...state, item];
  }
}

// 消费（不依赖 BuildContext）
class CartPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    return Text('购物车: ${items.length} 件');
  }
}
```

**优点：**
- 编译时安全，不依赖 BuildContext
- 支持 Provider 之间的组合和依赖
- 自动销毁不再使用的状态
- 易于测试，可覆盖 Provider
- 支持异步状态（AsyncValue）

**缺点：**
- 学习曲线比 Provider 更陡
- 全局 Provider 声明对于习惯 OOP 的开发者可能不适应
- API 经历过较大变动（从 v1 到 v2）

---

#### BLoC（Business Logic Component）

基于流（Stream）的状态管理模式，强调业务逻辑与 UI 分离。

```dart
// 定义事件
abstract class CartEvent {}
class AddItem extends CartEvent {
  final String item;
  AddItem(this.item);
}

// 定义状态
class CartState {
  final List<String> items;
  const CartState({this.items = const []});
}

// BLoC 处理事件 → 产生新状态
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItem>((event, emit) {
      emit(CartState(items: [...state.items, event.item]));
    });
  }
}

// UI 中使用
BlocBuilder<CartBloc, CartState>(
  builder: (context, state) {
    return Text('购物车: ${state.items.length} 件');
  },
);
```

**优点：**
- 严格分离业务逻辑和 UI
- 事件驱动，状态变化可追踪
- 非常适合复杂业务流程
- 强大的测试支持（bloc_test）

**缺点：**
- 样板代码最多（Event、State、Bloc 三个类）
- 简单场景下过于复杂
- 学习曲线较陡（需理解 Stream 概念）

---

#### GetX

一体化框架，提供状态管理、路由、依赖注入等功能。

```dart
// 定义控制器
class CartController extends GetxController {
  final items = <String>[].obs; // .obs 使其变为响应式

  void add(String item) {
    items.add(item);
  }
}

// 使用
final controller = Get.put(CartController());

Obx(() => Text('购物车: ${controller.items.length} 件'));
```

**优点：**
- 极简 API，上手快
- 不需要 BuildContext
- 一体化方案（路由、国际化等）
- 响应式编程简洁

**缺点：**
- 全局单例模式，可能导致内存问题
- 测试困难
- 不遵循 Flutter 惯用模式
- 社区争议较大，维护活跃度波动

---

### 5.2 方案对比表

| 特性 | setState | InheritedWidget | Provider | Riverpod | BLoC | GetX |
|------|----------|-----------------|----------|----------|------|------|
| **学习难度** | ⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐ |
| **样板代码** | 极少 | 多 | 少 | 少 | 最多 | 极少 |
| **适用规模** | 小 | 中 | 中大 | 大 | 大 | 中 |
| **额外依赖** | 无 | 无 | 需要 | 需要 | 需要 | 需要 |
| **测试友好** | 一般 | 一般 | 好 | 很好 | 很好 | 差 |
| **官方推荐** | ✅ | ✅ | ✅ | — | — | — |
| **类型安全** | ✅ | ✅ | ✅ | ✅✅ | ✅ | ⚠️ |
| **DevTools** | — | — | ✅ | ✅ | ✅ | ✅ |

### 5.3 社区使用趋势

根据 pub.dev 下载量和 GitHub Stars（截至 2024 年），大致排名：

1. **Provider** — 最广泛使用，官方推荐
2. **BLoC** — 企业项目首选
3. **Riverpod** — 增长最快，新项目首选趋势
4. **GetX** — 有忠实用户群但争议大
5. **setState / InheritedWidget** — 简单场景首选

---

## 6. 何时使用哪种方案——决策树

以下是一个帮助你选择状态管理方案的决策流程：

### 步骤一：判断状态类型

> **这个状态是否只在一个 Widget 内部使用？**

- **是** → 使用 `setState`，不需要任何状态管理库。结束。
- **否** → 进入步骤二。

### 步骤二：判断共享范围

> **这个状态需要跨几个组件共享？**

- **2-3 个相邻组件** → 考虑使用**状态提升**（父组件管理，通过参数传递）。如果传递层级不超过 2-3 层，这是最简单的方式。结束。
- **多个不相邻组件或跨页面** → 进入步骤三。

### 步骤三：评估项目规模和团队经验

> **项目是什么规模？团队对 Flutter 的经验如何？**

- **小型项目 / 个人项目 / Flutter 新手** → 使用 **Provider**。它是官方推荐的，学习资料丰富，社区支持好。结束。
- **中大型项目 / 团队开发** → 进入步骤四。

### 步骤四：选择架构风格

> **团队偏好什么样的架构风格？**

- **偏好响应式 / 函数式编程** → 使用 **Riverpod**。它提供了编译时安全、不依赖 BuildContext、支持 Provider 组合等高级特性。结束。
- **偏好事件驱动 / 严格分层架构** → 使用 **BLoC**。它强制分离业务逻辑和 UI，适合复杂业务流程和大型团队协作。结束。
- **追求开发速度，愿意牺牲一些规范性** → 可以考虑 **GetX**，但请注意其测试困难和社区争议。结束。

### 决策流程图（文字版）

```
状态只在一个 Widget 内？
│
├── 是 ──→ 🟢 setState
│
└── 否
    │
    状态只在 2-3 个相邻组件间共享？
    │
    ├── 是 ──→ 🟢 状态提升（Lifting State Up）
    │
    └── 否
        │
        项目规模？
        │
        ├── 小型/学习 ──→ 🟢 Provider
        │
        └── 中大型
            │
            架构偏好？
            │
            ├── 响应式/函数式 ──→ 🟢 Riverpod
            ├── 事件驱动/分层 ──→ 🟢 BLoC
            └── 快速开发 ──────→ 🟡 GetX（谨慎选择）
```

> ⚠️ **注意**：这个决策树是一个参考指南，不是绝对规则。实际项目中可以混合使用多种方案——例如，用 `setState` 管理 UI 状态，用 Provider/Riverpod/BLoC 管理业务状态。

---

## 7. 最佳实践总结

### 7.1 通用原则

1. **从简单开始**：不要一开始就引入复杂的状态管理库。先用 `setState`，当你感到痛点时再升级。

2. **单向数据流**：状态永远从上往下流动，事件从下往上传递。不要让子组件直接修改父组件的状态。

3. **最小化状态**：只存储必要的状态。能从已有状态计算得出的值（派生状态），不要单独存储。

   ```dart
   // ❌ 不好：冗余状态
   int _itemCount = 0;
   List<String> _items = [];

   // ✅ 好：从 _items 派生出 count
   List<String> _items = [];
   int get itemCount => _items.length; // 派生状态
   ```

4. **不可变状态**：尽量使用不可变数据。修改状态时创建新对象而不是修改现有对象。

   ```dart
   // ❌ 不好：直接修改列表
   _items.add(newItem);

   // ✅ 好：创建新列表
   _items = [..._items, newItem];
   ```

5. **状态尽可能局部化**：状态应该放在需要它的最低层级。不是所有状态都需要放在全局。

### 7.2 setState 使用建议

```dart
// ✅ 好：setState 中只包含状态变更
setState(() {
  _count++;
});

// ❌ 不好：在 setState 中执行耗时操作
setState(() {
  _data = await fetchData(); // 不要这样做！
  _count++;
});

// ✅ 好：异步操作在 setState 之前完成
final data = await fetchData();
if (mounted) {  // 检查组件是否还在树中
  setState(() {
    _data = data;
  });
}
```

### 7.3 状态管理的常见错误

| 错误 | 说明 | 正确做法 |
|------|------|---------|
| 过度使用全局状态 | 把所有状态都放在全局 | 区分短暂状态和应用状态 |
| 忽略 `mounted` 检查 | 异步操作后直接 setState | 先检查 `mounted` |
| 在 `build` 中修改状态 | build 方法中调用 setState | 将状态修改放在事件处理中 |
| 状态和 UI 耦合 | 状态逻辑写在 Widget 中 | 将业务逻辑抽取到单独的类 |
| 不处理加载和错误状态 | 只考虑正常情况 | 始终考虑 loading、error、empty 状态 |

### 7.4 本章代码示例说明

配套代码 [`lib/ch01_state_overview.dart`](../lib/ch01_state_overview.dart) 展示了：

1. **短暂状态示例**——计数器页面
   - 使用 `StatefulWidget` + `setState`
   - 状态 `_count` 只在计数器 Widget 内部使用
   - 演示了最基本的状态管理方式

2. **应用状态示例**——购物车页面
   - 使用状态提升模式
   - 购物车数据 `_cartItems` 在父组件中管理
   - 商品列表组件和购物车展示组件共享同一份数据
   - 通过回调函数实现子组件到父组件的事件传递

3. **页面切换**
   - 使用 `BottomNavigationBar` 在两个页面间切换
   - 导航栏的 `_currentIndex` 是短暂状态
   - 购物车数据在切换页面时保持不变（因为状态在父组件中）

运行示例：

```bash
cd flutter-state
flutter run lib/ch01_state_overview.dart
```

---

## 延伸阅读

- [Flutter 官方文档 - 状态管理](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Flutter 官方文档 - 短暂状态 vs 应用状态](https://docs.flutter.dev/data-and-backend/state-mgmt/ephemeral-vs-app)
- [Provider 包文档](https://pub.dev/packages/provider)
- [Riverpod 官方文档](https://riverpod.dev/)
- [BLoC 官方文档](https://bloclibrary.dev/)

---

> 📝 **下一章预告**：第二章将深入学习 `Provider`，从 `ChangeNotifier` 到 `Consumer`，从单个 Provider 到多 Provider 组合，通过实战项目掌握 Flutter 官方推荐的状态管理方案。
