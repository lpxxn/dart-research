# 第8章：状态管理实战对比

## 目录

1. [统一需求定义](#1-统一需求定义)
2. [Provider 实现](#2-provider-实现)
3. [Riverpod 实现](#3-riverpod-实现)
4. [BLoC 实现](#4-bloc-实现)
5. [对比分析](#5-对比分析)
6. [选型建议](#6-选型建议)

---

## 1. 统一需求定义

为了公平比较不同状态管理方案，我们定义一个统一的购物车需求：

### 功能需求

| 功能 | 说明 |
|------|------|
| 商品列表 | 显示可选商品，带名称和价格 |
| 添加到购物车 | 点击商品旁的按钮添加 |
| 购物车页面 | 查看已添加的商品 |
| 删除商品 | 从购物车中移除某个商品 |
| 修改数量 | 增加/减少购物车中商品数量 |
| 总价计算 | 实时显示购物车总价 |

### 数据模型

所有实现共用同一个数据模型：

```dart
/// 商品数据模型
class Product {
  final String id;
  final String name;
  final double price;
  final String emoji;  // 用 emoji 代替图片

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
  });
}

/// 购物车项（商品 + 数量）
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}
```

### 示例商品数据

```dart
const products = [
  Product(id: '1', name: '苹果', price: 5.0, emoji: '🍎'),
  Product(id: '2', name: '面包', price: 8.0, emoji: '🍞'),
  Product(id: '3', name: '牛奶', price: 12.0, emoji: '🥛'),
  Product(id: '4', name: '鸡蛋', price: 15.0, emoji: '🥚'),
  Product(id: '5', name: '咖啡', price: 25.0, emoji: '☕'),
];
```

---

## 2. Provider 实现

### 核心思路

使用 `ChangeNotifier` + `Provider` / `Consumer`：

```dart
/// Provider 方案：使用 ChangeNotifier 管理购物车状态
class ProviderCart extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  /// 添加商品
  void addProduct(Product product) {
    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();  // 通知所有监听者
  }

  /// 删除商品
  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// 修改数量
  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }
}
```

### UI 层

```dart
// 提供状态
ChangeNotifierProvider(
  create: (_) => ProviderCart(),
  child: ProviderCartPage(),
)

// 消费状态
Consumer<ProviderCart>(
  builder: (context, cart, child) {
    return Text('总价: ¥${cart.totalPrice.toStringAsFixed(2)}');
  },
)

// 操作状态
context.read<ProviderCart>().addProduct(product);
```

### 优缺点

| 优点 | 缺点 |
|------|------|
| 官方推荐，生态好 | ChangeNotifier 通知粒度粗 |
| 概念简单 | 大量 Consumer 嵌套 |
| 文档丰富 | 不支持异步状态 |

---

## 3. Riverpod 实现

### 核心思路

使用 `StateNotifier` + `StateNotifierProvider`：

```dart
/// Riverpod 方案：使用 StateNotifier 管理不可变状态
class RiverpodCartNotifier extends StateNotifier<List<CartItem>> {
  RiverpodCartNotifier() : super([]);

  void addProduct(Product product) {
    final index = state.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index >= 0) {
      // 创建新列表（不可变状态）
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            CartItem(
              product: state[i].product,
              quantity: state[i].quantity + 1,
            )
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeProduct(String productId) {
    state = state.where(
      (item) => item.product.id != productId,
    ).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          CartItem(product: item.product, quantity: quantity)
        else
          item,
    ];
  }
}

// 定义 Provider
final riverpodCartProvider =
    StateNotifierProvider<RiverpodCartNotifier, List<CartItem>>(
  (ref) => RiverpodCartNotifier(),
);

// 计算总价（派生状态）
final totalPriceProvider = Provider<double>((ref) {
  final items = ref.watch(riverpodCartProvider);
  return items.fold(0, (sum, item) => sum + item.subtotal);
});
```

### UI 层

```dart
// 根组件
ProviderScope(child: RiverpodCartPage())

// 消费状态（使用 ConsumerWidget）
class RiverpodCartPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(riverpodCartProvider);
    final total = ref.watch(totalPriceProvider);

    return Column(
      children: [
        Text('总价: ¥${total.toStringAsFixed(2)}'),
        ...items.map((item) => Text(item.product.name)),
      ],
    );
  }
}

// 操作状态
ref.read(riverpodCartProvider.notifier).addProduct(product);
```

### 优缺点

| 优点 | 缺点 |
|------|------|
| 编译期安全 | 学习曲线较陡 |
| 不依赖 BuildContext | 概念多（Provider/Notifier/Ref） |
| 支持派生状态 | 声明式定义需要适应 |
| 可测试性极佳 | 相比 Provider 多写一些代码 |

---

## 4. BLoC 实现

### 核心思路

定义 Event → BLoC → State 完整流程：

```dart
// ===== 事件定义 =====
abstract class CartEvent {}

class AddToCart extends CartEvent {
  final Product product;
  AddToCart(this.product);
}

class RemoveFromCart extends CartEvent {
  final String productId;
  RemoveFromCart(this.productId);
}

class UpdateCartQuantity extends CartEvent {
  final String productId;
  final int quantity;
  UpdateCartQuantity(this.productId, this.quantity);
}

// ===== 状态定义 =====
class CartState {
  final List<CartItem> items;
  
  CartState({this.items = const []});

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + item.subtotal);
  
  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);
}

// ===== BLoC 实现 =====
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartQuantity>(_onUpdateQuantity);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere(
      (item) => item.product.id == event.product.id,
    );
    if (index >= 0) {
      items[index] = CartItem(
        product: items[index].product,
        quantity: items[index].quantity + 1,
      );
    } else {
      items.add(CartItem(product: event.product));
    }
    emit(CartState(items: items));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final items = state.items.where(
      (item) => item.product.id != event.productId,
    ).toList();
    emit(CartState(items: items));
  }

  void _onUpdateQuantity(
    UpdateCartQuantity event,
    Emitter<CartState> emit,
  ) {
    if (event.quantity <= 0) {
      _onRemoveFromCart(RemoveFromCart(event.productId), emit);
      return;
    }
    final items = [
      for (final item in state.items)
        if (item.product.id == event.productId)
          CartItem(product: item.product, quantity: event.quantity)
        else
          item,
    ];
    emit(CartState(items: items));
  }
}
```

### UI 层

```dart
// 提供 BLoC
BlocProvider(
  create: (_) => CartBloc(),
  child: BlocCartPage(),
)

// 消费状态
BlocBuilder<CartBloc, CartState>(
  builder: (context, state) {
    return Text('总价: ¥${state.totalPrice.toStringAsFixed(2)}');
  },
)

// 发送事件
context.read<CartBloc>().add(AddToCart(product));
```

### 优缺点

| 优点 | 缺点 |
|------|------|
| 结构清晰（Event/State） | 代码量最多 |
| 可追溯（事件日志） | 学习曲线陡峭 |
| 可测试性极佳 | 大量模板代码 |
| 适合复杂业务 | 简单功能过于繁琐 |

---

## 5. 对比分析

### 5.1 代码量对比

| 方案 | 状态管理代码 | UI 代码 | 模板代码 | 总体 |
|------|------------|---------|---------|------|
| **Provider** | ~40 行 | ~60 行 | 少 | ⭐ 最少 |
| **Riverpod** | ~50 行 | ~60 行 | 中等 | ⭐⭐ 适中 |
| **BLoC** | ~80 行 | ~60 行 | 多 | ⭐⭐⭐ 最多 |

### 5.2 学习曲线

| 方案 | 核心概念数量 | 上手时间 | 精通时间 |
|------|------------|---------|---------|
| **Provider** | 3 个 | 1-2 天 | 1 周 |
| **Riverpod** | 5 个 | 3-5 天 | 2 周 |
| **BLoC** | 6 个 | 5-7 天 | 3 周 |

### 5.3 可测试性

| 方案 | 单元测试 | 集成测试 | Mock 难度 |
|------|---------|---------|----------|
| **Provider** | 好 | 好 | 低 |
| **Riverpod** | 优秀 | 优秀 | 低 |
| **BLoC** | 优秀 | 优秀 | 低 |

### 5.4 适用场景

| 方案 | 小型项目 | 中型项目 | 大型项目 | 团队协作 |
|------|---------|---------|---------|---------|
| **Provider** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Riverpod** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **BLoC** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### 5.5 综合对比表

| 维度 | Provider | Riverpod | BLoC |
|------|----------|----------|------|
| **学习成本** | 🟢 低 | 🟡 中 | 🔴 高 |
| **代码量** | 🟢 少 | 🟡 适中 | 🔴 多 |
| **可测试性** | 🟡 好 | 🟢 优秀 | 🟢 优秀 |
| **可扩展性** | 🟡 中 | 🟢 强 | 🟢 强 |
| **类型安全** | 🟡 运行时 | 🟢 编译期 | 🟡 运行时 |
| **DevTools** | 🟢 有 | 🟢 有 | 🟢 有 |
| **官方支持** | 🟢 官方推荐 | 🟡 社区 | 🟡 社区 |
| **异步支持** | 🟡 手动 | 🟢 内置 | 🟢 内置 |

---

## 6. 选型建议

### 6.1 决策流程图

```
你的项目规模？
├── 小型 / 个人项目 ──→ Provider ✅
│   └── 需要路由+DI ──→ GetX
│
├── 中型项目 ──→ Riverpod ✅
│   └── 团队熟悉 BLoC ──→ BLoC
│
└── 大型 / 企业项目
    ├── 需要事件追溯 ──→ BLoC ✅
    ├── 需要编译期安全 ──→ Riverpod ✅
    └── 快速迭代优先 ──→ Provider / Riverpod
```

### 6.2 具体建议

#### 选 Provider 如果...
- 你是 Flutter 初学者
- 项目简单，状态不复杂
- 你想用官方推荐的方案
- 团队成员水平参差不齐

#### 选 Riverpod 如果...
- 你想要编译期安全
- 需要复杂的状态依赖关系
- 需要好的可测试性
- 想要 Provider 的升级版

#### 选 BLoC 如果...
- 项目复杂，业务逻辑重
- 需要事件追溯和日志
- 团队有严格的架构规范
- 需要和后端团队统一架构思想

#### 选 GetX 如果...
- 快速原型开发
- 个人项目或小团队
- 需要全功能框架（状态+路由+DI）
- 追求最少代码量

### 6.3 最终忠告

> **没有最好的状态管理方案，只有最适合的。**
> 
> 选择时考虑：团队经验、项目规模、长期维护成本。
> 
> 不要因为"大家都说 X 好"就选 X，也不要因为"Y 代码少"就选 Y。
> 实际写一个小 Demo 用每种方案试试，你自然会知道哪个最适合你的项目。

---

## 参考资源

- [Flutter 官方状态管理指南](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Provider vs Riverpod vs BLoC 对比](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
- [BLoC Library](https://bloclibrary.dev)
- [Riverpod 官方文档](https://riverpod.dev)
