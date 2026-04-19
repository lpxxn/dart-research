import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第三章：Notifier 与 NotifierProvider
// 演示：Notifier 类、build() 初始化、copyWith 不可变模式、购物车示例
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class Product {
  final String id;
  final String name;
  final double price;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
  });
}

/// 购物车项：包含产品和数量
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  /// copyWith 模式：创建新对象，只修改指定字段
  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  double get totalPrice => product.price * quantity;
}

// -----------------------------------------------------------------------------
// 2. 产品数据（只读 Provider）
// -----------------------------------------------------------------------------

final productsProvider = Provider<List<Product>>((ref) {
  return const [
    Product(id: '1', name: 'Flutter 实战', price: 79.0, emoji: '📘'),
    Product(id: '2', name: '机械键盘', price: 299.0, emoji: '⌨️'),
    Product(id: '3', name: '显示器', price: 1899.0, emoji: '🖥️'),
    Product(id: '4', name: '鼠标', price: 129.0, emoji: '🖱️'),
    Product(id: '5', name: '耳机', price: 599.0, emoji: '🎧'),
    Product(id: '6', name: '鼠标垫', price: 39.0, emoji: '🟫'),
  ];
});

// -----------------------------------------------------------------------------
// 3. 购物车 Notifier — 核心状态管理逻辑
// -----------------------------------------------------------------------------

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // 初始状态：空购物车
    return [];
  }

  /// 添加商品到购物车
  void addProduct(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // 已存在：数量 +1（使用 copyWith 创建新对象）
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      // 不存在：添加新项
      state = [...state, CartItem(product: product)];
    }
  }

  /// 从购物车移除商品
  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// 更新商品数量
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  /// 清空购物车
  void clear() {
    state = [];
  }
}

/// 注册购物车 Provider
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

// -----------------------------------------------------------------------------
// 4. 派生 Provider：总价、总数
// -----------------------------------------------------------------------------

/// 购物车总价
final cartTotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// 购物车商品总数
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

// -----------------------------------------------------------------------------
// 5. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch03App()));
}

class Ch03App extends StatelessWidget {
  const Ch03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch03 - Notifier 购物车',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const ShoppingPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. 商品列表 + 购物车页面
// -----------------------------------------------------------------------------

class ShoppingPage extends ConsumerWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第三章：Notifier 购物车'),
        actions: [
          // 购物车按钮，显示数量徽章
          Badge(
            label: Text('$cartCount'),
            isLabelVisible: cartCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartPage()));
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: ListTile(
              leading: Text(product.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(product.name),
              subtitle: Text('¥${product.price.toStringAsFixed(0)}'),
              trailing: FilledButton.icon(
                onPressed: () {
                  // 调用 Notifier 的方法
                  ref.read(cartProvider.notifier).addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已添加 ${product.name}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('加入'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. 购物车详情页
// -----------------------------------------------------------------------------

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalPrice = ref.watch(cartTotalPriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('清空'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_shopping_cart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('购物车是空的', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        child: ListTile(
                          leading: Text(item.product.emoji,
                              style: const TextStyle(fontSize: 28)),
                          title: Text(item.product.name),
                          subtitle: Text(
                            '¥${item.product.price.toStringAsFixed(0)} × ${item.quantity} = ¥${item.totalPrice.toStringAsFixed(0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 减少数量
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(
                                        item.product.id,
                                        item.quantity - 1,
                                      );
                                },
                              ),
                              Text('${item.quantity}',
                                  style: const TextStyle(fontSize: 16)),
                              // 增加数量
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(
                                        item.product.id,
                                        item.quantity + 1,
                                      );
                                },
                              ),
                              // 删除
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeProduct(item.product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 底部结算栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '合计：¥${totalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('结算成功！（示例）')),
                          );
                          ref.read(cartProvider.notifier).clear();
                          Navigator.pop(context);
                        },
                        child: const Text('结算'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. Notifier<T>：在类中封装状态（T）和修改逻辑
// 2. build()：返回初始状态，首次读取时调用
// 3. state：读写状态的属性，赋新值时自动通知监听者
// 4. copyWith：不可变状态模式，每次修改创建新对象
// 5. NotifierProvider<N, T>(N.new)：注册 Notifier
// 6. ref.read(provider.notifier).method()：调用 Notifier 方法
// 7. 派生 Provider：组合 cart 数据计算总价/总数
// =============================================================================
