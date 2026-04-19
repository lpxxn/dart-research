// 第8章：状态管理实战对比 —— 购物车应用
//
// 本示例用三种不同的状态管理方案实现同一个购物车需求：
// 1. Provider（ChangeNotifier）
// 2. Riverpod（StateNotifier）
// 3. BLoC（Event/State）
//
// 通过 Tab 页面切换查看不同实现的效果。
//
// 运行方式：flutter run -t lib/ch08_state_comparison.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as prov;
import 'package:flutter_riverpod/flutter_riverpod.dart' as rpod;
import 'package:flutter_bloc/flutter_bloc.dart';

// ============================================================
// 共享数据模型
// ============================================================

/// 商品
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

/// 购物车项
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// 示例商品数据
const sampleProducts = [
  Product(id: '1', name: '苹果', price: 5.0, emoji: '🍎'),
  Product(id: '2', name: '面包', price: 8.0, emoji: '🍞'),
  Product(id: '3', name: '牛奶', price: 12.0, emoji: '🥛'),
  Product(id: '4', name: '鸡蛋', price: 15.0, emoji: '🥚'),
  Product(id: '5', name: '咖啡', price: 25.0, emoji: '☕'),
  Product(id: '6', name: '蛋糕', price: 35.0, emoji: '🍰'),
];

// ============================================================
// Section 1：Provider 实现
// ============================================================

/// Provider 方案：使用 ChangeNotifier
class ProviderCart extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addProduct(Product product) {
    final index = _items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((e) => e.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final index = _items.indexWhere((e) => e.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// ============================================================
// Section 2：Riverpod 实现
// ============================================================

/// Riverpod 方案：使用 StateNotifier + 不可变状态
class RiverpodCartNotifier extends rpod.StateNotifier<List<CartItem>> {
  RiverpodCartNotifier() : super([]);

  void addProduct(Product product) {
    final index = state.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(quantity: state[i].quantity + 1)
          else state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((e) => e.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId) item.copyWith(quantity: quantity)
        else item,
    ];
  }

  void clearCart() {
    state = [];
  }
}

/// Riverpod Provider 定义
final riverpodCartProvider =
    rpod.StateNotifierProvider<RiverpodCartNotifier, List<CartItem>>(
  (ref) => RiverpodCartNotifier(),
);

/// 派生状态：总价
final riverpodTotalProvider = rpod.Provider<double>((ref) {
  final items = ref.watch(riverpodCartProvider);
  return items.fold(0, (sum, item) => sum + item.subtotal);
});

/// 派生状态：商品总数
final riverpodCountProvider = rpod.Provider<int>((ref) {
  final items = ref.watch(riverpodCartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

// ============================================================
// Section 3：BLoC 实现
// ============================================================

// --- 事件 ---
abstract class BlocCartEvent {}

class AddToCart extends BlocCartEvent {
  final Product product;
  AddToCart(this.product);
}

class RemoveFromCart extends BlocCartEvent {
  final String productId;
  RemoveFromCart(this.productId);
}

class UpdateCartQuantity extends BlocCartEvent {
  final String productId;
  final int quantity;
  UpdateCartQuantity(this.productId, this.quantity);
}

class ClearCart extends BlocCartEvent {}

// --- 状态 ---
class BlocCartState {
  final List<CartItem> items;

  const BlocCartState({this.items = const []});

  double get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

// --- BLoC ---
class CartBloc extends Bloc<BlocCartEvent, BlocCartState> {
  CartBloc() : super(const BlocCartState()) {
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateCartQuantity>(_onUpdate);
    on<ClearCart>(_onClear);
  }

  void _onAdd(AddToCart event, Emitter<BlocCartState> emit) {
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((e) => e.product.id == event.product.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItem(product: event.product));
    }
    emit(BlocCartState(items: items));
  }

  void _onRemove(RemoveFromCart event, Emitter<BlocCartState> emit) {
    final items = state.items.where((e) => e.product.id != event.productId).toList();
    emit(BlocCartState(items: items));
  }

  void _onUpdate(UpdateCartQuantity event, Emitter<BlocCartState> emit) {
    if (event.quantity <= 0) {
      _onRemove(RemoveFromCart(event.productId), emit);
      return;
    }
    final items = [
      for (final item in state.items)
        if (item.product.id == event.productId) item.copyWith(quantity: event.quantity)
        else item,
    ];
    emit(BlocCartState(items: items));
  }

  void _onClear(ClearCart event, Emitter<BlocCartState> emit) {
    emit(const BlocCartState());
  }
}

// ============================================================
// Section 4：主应用入口
// ============================================================

void main() {
  runApp(
    // Riverpod 需要 ProviderScope 包裹整个应用
    rpod.ProviderScope(
      child: const Ch08ComparisonApp(),
    ),
  );
}

class Ch08ComparisonApp extends StatelessWidget {
  const Ch08ComparisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider 需要 ChangeNotifierProvider
    return prov.ChangeNotifierProvider(
      create: (_) => ProviderCart(),
      child: BlocProvider(
        create: (_) => CartBloc(),
        child: MaterialApp(
          title: '状态管理对比',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
          ),
          home: const ComparisonHomePage(),
        ),
      ),
    );
  }
}

/// 主页面：Tab 切换三种实现
class ComparisonHomePage extends StatelessWidget {
  const ComparisonHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🛒 购物车对比'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Provider'),
              Tab(text: 'Riverpod'),
              Tab(text: 'BLoC'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProviderCartPage(),
            RiverpodCartPage(),
            BlocCartPage(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Section 5：Provider 购物车页面
// ============================================================

class ProviderCartPage extends StatelessWidget {
  const ProviderCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return prov.Consumer<ProviderCart>(
      builder: (context, cart, _) {
        return _CartPageLayout(
          label: 'Provider',
          color: Colors.blue,
          totalPrice: cart.totalPrice,
          itemCount: cart.itemCount,
          items: cart.items,
          onAddProduct: (product) => cart.addProduct(product),
          onRemoveProduct: (id) => cart.removeProduct(id),
          onUpdateQuantity: (id, qty) => cart.updateQuantity(id, qty),
          onClear: () => cart.clearCart(),
        );
      },
    );
  }
}

// ============================================================
// Section 6：Riverpod 购物车页面
// ============================================================

class RiverpodCartPage extends rpod.ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, rpod.WidgetRef ref) {
    final items = ref.watch(riverpodCartProvider);
    final totalPrice = ref.watch(riverpodTotalProvider);
    final itemCount = ref.watch(riverpodCountProvider);

    return _CartPageLayout(
      label: 'Riverpod',
      color: Colors.green,
      totalPrice: totalPrice,
      itemCount: itemCount,
      items: items,
      onAddProduct: (product) =>
          ref.read(riverpodCartProvider.notifier).addProduct(product),
      onRemoveProduct: (id) =>
          ref.read(riverpodCartProvider.notifier).removeProduct(id),
      onUpdateQuantity: (id, qty) =>
          ref.read(riverpodCartProvider.notifier).updateQuantity(id, qty),
      onClear: () => ref.read(riverpodCartProvider.notifier).clearCart(),
    );
  }
}

// ============================================================
// Section 7：BLoC 购物车页面
// ============================================================

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, BlocCartState>(
      builder: (context, state) {
        return _CartPageLayout(
          label: 'BLoC',
          color: Colors.orange,
          totalPrice: state.totalPrice,
          itemCount: state.itemCount,
          items: state.items,
          onAddProduct: (product) =>
              context.read<CartBloc>().add(AddToCart(product)),
          onRemoveProduct: (id) =>
              context.read<CartBloc>().add(RemoveFromCart(id)),
          onUpdateQuantity: (id, qty) =>
              context.read<CartBloc>().add(UpdateCartQuantity(id, qty)),
          onClear: () => context.read<CartBloc>().add(ClearCart()),
        );
      },
    );
  }
}

// ============================================================
// Section 8：通用购物车页面布局（三种实现共享）
// ============================================================

/// 通用购物车页面布局
class _CartPageLayout extends StatelessWidget {
  final String label;
  final Color color;
  final double totalPrice;
  final int itemCount;
  final List<CartItem> items;
  final void Function(Product) onAddProduct;
  final void Function(String) onRemoveProduct;
  final void Function(String, int) onUpdateQuantity;
  final VoidCallback onClear;

  const _CartPageLayout({
    required this.label,
    required this.color,
    required this.totalPrice,
    required this.itemCount,
    required this.items,
    required this.onAddProduct,
    required this.onRemoveProduct,
    required this.onUpdateQuantity,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 方案标识栏
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: color.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$itemCount 件商品'),
                ],
              ),
              Text(
                '¥${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),

        // 商品列表 + 购物车
        Expanded(
          child: ListView(
            children: [
              // 商品列表区域
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '📦 商品列表',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...sampleProducts.map((product) {
                final inCart = items.any((e) => e.product.id == product.id);
                return ListTile(
                  leading: Text(product.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(product.name),
                  subtitle: Text('¥${product.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(
                      inCart ? Icons.check_circle : Icons.add_shopping_cart,
                      color: inCart ? Colors.green : null,
                    ),
                    onPressed: () => onAddProduct(product),
                  ),
                );
              }),

              const Divider(height: 24),

              // 购物车区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🛒 购物车',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (items.isNotEmpty)
                      TextButton(
                        onPressed: onClear,
                        child: const Text('清空'),
                      ),
                  ],
                ),
              ),

              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Text('🛒', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('购物车是空的', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ...items.map((item) => _buildCartItem(item)),

              // 总价栏
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: color.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '合计',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '¥${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建购物车项
  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(item.product.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '¥${item.product.price.toStringAsFixed(2)} × ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // 数量控制
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => onUpdateQuantity(item.product.id, item.quantity - 1),
            ),
            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => onUpdateQuantity(item.product.id, item.quantity + 1),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
              onPressed: () => onRemoveProduct(item.product.id),
            ),
          ],
        ),
      ),
    );
  }
}
