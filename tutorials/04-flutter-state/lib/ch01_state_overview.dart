import 'package:flutter/material.dart';

/// 第一章：状态管理概论 - 示例代码
///
/// 本文件演示了两种状态类型：
/// 1. 短暂状态（Ephemeral State）—— 计数器，用 setState 管理
/// 2. 应用状态（App State）—— 购物车，用状态提升管理
///
/// 配套文档：docs/ch01_state_overview.md

void main() => runApp(const Ch01App());

/// 应用根组件
class Ch01App extends StatelessWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第一章：状态管理概论',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// =============================================================================
// 主屏幕 —— 管理页面切换（短暂状态）和购物车数据（应用状态）
// =============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 当前选中的底部导航栏索引 —— 这是短暂状态
  int _currentIndex = 0;

  /// 购物车中的商品列表 —— 这是应用状态（需要在多个子组件间共享）
  /// 通过"状态提升"，将购物车状态放在父组件中管理
  final List<String> _cartItems = [];

  /// 添加商品到购物车
  void _addToCart(String product) {
    setState(() {
      _cartItems.add(product);
    });
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加「$product」到购物车'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 从购物车移除商品
  void _removeFromCart(String product) {
    setState(() {
      _cartItems.remove(product);
    });
  }

  /// 清空购物车
  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 根据当前索引构建对应的页面
    final pages = <Widget>[
      // 页面 1：计数器（短暂状态演示）
      const CounterPage(),
      // 页面 2：购物车（应用状态演示）
      // 通过构造函数将状态和回调传递给子组件 —— 这就是状态提升
      ShoppingPage(
        cartItems: _cartItems,
        onAddToCart: _addToCart,
        onRemoveFromCart: _removeFromCart,
        onClearCart: _clearCart,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? '短暂状态：计数器' : '应用状态：购物车',
        ),
        // 在 AppBar 中显示购物车角标 —— 这也是应用状态的体现
        actions: [
          if (_cartItems.isNotEmpty)
            Badge(
              label: Text('${_cartItems.length}'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // 切换到购物车页面
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // 切换页面 —— _currentIndex 是短暂状态，用 setState 管理
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '计数器',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: '购物车',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 页面 1：计数器页面 —— 短暂状态（Ephemeral State）演示
// =============================================================================

/// 计数器页面
/// 计数值 _count 是短暂状态：只有这个 Widget 内部使用，不需要跨组件共享
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  /// 计数值 —— 短暂状态，用 setState 管理
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 说明区域
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  '短暂状态（Ephemeral State）',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '计数值只在这个 Widget 内部使用，\n使用 setState 管理即可。\n切换到购物车页面再切回来，计数会重置。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // 计数显示
          Text(
            '$_count',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前计数',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 减少按钮
              FilledButton.tonalIcon(
                onPressed: _count > 0
                    ? () {
                        setState(() {
                          _count--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
                label: const Text('减少'),
              ),
              const SizedBox(width: 16),
              // 重置按钮
              OutlinedButton.icon(
                onPressed: _count != 0
                    ? () {
                        setState(() {
                          _count = 0;
                        });
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
              ),
              const SizedBox(width: 16),
              // 增加按钮
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _count++;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('增加'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 页面 2：购物车页面 —— 应用状态（App State）+ 状态提升 演示
// =============================================================================

/// 购物车页面
/// 这个组件本身是 StatelessWidget —— 它不管理状态，只接收父组件传下来的数据
class ShoppingPage extends StatelessWidget {
  /// 购物车中的商品 —— 从父组件接收（状态提升）
  final List<String> cartItems;

  /// 添加商品的回调 —— 从父组件接收
  final ValueChanged<String> onAddToCart;

  /// 移除商品的回调 —— 从父组件接收
  final ValueChanged<String> onRemoveFromCart;

  /// 清空购物车的回调 —— 从父组件接收
  final VoidCallback onClearCart;

  const ShoppingPage({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 说明区域
        _buildInfoBanner(context),
        // 主要内容区
        Expanded(
          child: Row(
            children: [
              // 左侧：商品列表
              Expanded(
                flex: 3,
                child: ProductListSection(
                  cartItems: cartItems,
                  onAddToCart: onAddToCart,
                ),
              ),
              // 分隔线
              const VerticalDivider(width: 1),
              // 右侧：购物车
              Expanded(
                flex: 2,
                child: CartSection(
                  cartItems: cartItems,
                  onRemoveFromCart: onRemoveFromCart,
                  onClearCart: onClearCart,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '应用状态（App State）：购物车数据在父组件中管理，通过状态提升传递给商品列表和购物车展示组件。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 商品列表组件 —— 子组件，通过回调通知父组件添加商品
// =============================================================================

/// 可购买的商品数据
const _availableProducts = <_Product>[
  _Product('🍎', '苹果', 5.0),
  _Product('🍌', '香蕉', 3.5),
  _Product('🍊', '橙子', 4.0),
  _Product('🥝', '猕猴桃', 8.0),
  _Product('🍇', '葡萄', 12.0),
  _Product('🍓', '草莓', 15.0),
  _Product('🫐', '蓝莓', 20.0),
  _Product('🥑', '牛油果', 10.0),
];

/// 商品数据类
class _Product {
  final String emoji;
  final String name;
  final double price;

  const _Product(this.emoji, this.name, this.price);
}

/// 商品列表区域
class ProductListSection extends StatelessWidget {
  final List<String> cartItems;
  final ValueChanged<String> onAddToCart;

  const ProductListSection({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '商品列表',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _availableProducts.length,
            itemBuilder: (context, index) {
              final product = _availableProducts[index];
              // 计算该商品在购物车中的数量
              final countInCart =
                  cartItems.where((item) => item == product.name).length;

              return ListTile(
                leading: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(product.name),
                subtitle: Text('¥${product.price.toStringAsFixed(1)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (countInCart > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x$countInCart',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // 点击添加 —— 通过回调通知父组件
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => onAddToCart(product.name),
                      tooltip: '添加到购物车',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 购物车展示组件 —— 子组件，展示父组件传下来的购物车数据
// =============================================================================

/// 购物车区域
class CartSection extends StatelessWidget {
  final List<String> cartItems;
  final ValueChanged<String> onRemoveFromCart;
  final VoidCallback onClearCart;

  const CartSection({
    super.key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 统计每种商品的数量
    final itemCounts = <String, int>{};
    for (final item in cartItems) {
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    // 计算总价
    double totalPrice = 0;
    for (final item in cartItems) {
      final product = _availableProducts.firstWhere(
        (p) => p.name == item,
        orElse: () => const _Product('', '', 0),
      );
      totalPrice += product.price;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '购物车',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: onClearCart,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('清空'),
                ),
            ],
          ),
        ),
        // 购物车内容
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '购物车是空的',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击左侧商品的 + 按钮添加',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: itemCounts.entries.map((entry) {
                    final product = _availableProducts.firstWhere(
                      (p) => p.name == entry.key,
                      orElse: () => const _Product('?', '未知', 0),
                    );
                    return ListTile(
                      dense: true,
                      leading: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(entry.key),
                      subtitle: Text(
                        '¥${product.price.toStringAsFixed(1)} × ${entry.value}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 20,
                        // 点击移除 —— 通过回调通知父组件
                        onPressed: () => onRemoveFromCart(entry.key),
                        tooltip: '移除一个',
                      ),
                    );
                  }).toList(),
                ),
        ),
        // 底部总价
        if (cartItems.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '共 ${cartItems.length} 件',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '¥${totalPrice.toStringAsFixed(1)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
