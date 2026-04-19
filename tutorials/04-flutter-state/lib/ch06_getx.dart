// 第6章：GetX 状态管理 —— 计数器 + 购物车
//
// 本示例演示了 GetX 的核心功能：
// - 响应式状态管理（.obs + Obx）
// - GetBuilder（简单状态管理）
// - GetxController 生命周期
// - 依赖注入（Get.put / Get.find）
// - Tab 切换展示两个功能模块
//
// 运行方式：flutter run -t lib/ch06_getx.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ============================================================
// 第一部分：数据模型
// ============================================================

/// 商品数据模型
class GxProduct {
  final String id;
  final String name;
  final double price;
  final String emoji;

  const GxProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
  });
}

/// 购物车项
class GxCartItem {
  final GxProduct product;
  int quantity;

  GxCartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

/// 示例商品列表
const gxProducts = [
  GxProduct(id: '1', name: '苹果', price: 5.0, emoji: '🍎'),
  GxProduct(id: '2', name: '面包', price: 8.0, emoji: '🍞'),
  GxProduct(id: '3', name: '牛奶', price: 12.0, emoji: '🥛'),
  GxProduct(id: '4', name: '鸡蛋', price: 15.0, emoji: '🥚'),
  GxProduct(id: '5', name: '咖啡', price: 25.0, emoji: '☕'),
  GxProduct(id: '6', name: '蛋糕', price: 35.0, emoji: '🍰'),
];

// ============================================================
// 第二部分：计数器控制器（响应式 .obs）
// ============================================================

/// 计数器控制器：演示 .obs 响应式状态管理
class CounterController extends GetxController {
  // 使用 .obs 创建响应式变量
  var count = 0.obs;
  var message = '点击按钮开始计数'.obs;

  @override
  void onInit() {
    super.onInit();
    // ever: 每次 count 变化时触发
    ever(count, (value) {
      if (value % 10 == 0 && value > 0) {
        message.value = '🎉 恭喜！达到 $value 次！';
      } else if (value > 0) {
        message.value = '当前计数: $value';
      }
    });

    // once: 只在第一次变化时触发
    once(count, (value) {
      message.value = '开始计数了！第一次点击 👆';
    });
  }

  void increment() => count.value++;
  void decrement() {
    if (count.value > 0) count.value--;
  }

  void reset() {
    count.value = 0;
    message.value = '已重置，点击按钮开始计数';
  }
}

// ============================================================
// 第三部分：购物车控制器（GetBuilder 简单状态管理）
// ============================================================

/// 购物车控制器：演示 GetBuilder + update() 手动更新
class CartController extends GetxController {
  final List<GxCartItem> _items = [];

  /// 获取购物车项列表（不可变副本）
  List<GxCartItem> get items => List.unmodifiable(_items);

  /// 购物车商品总数
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// 购物车总价
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  /// 检查商品是否在购物车中
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  /// 获取商品在购物车中的数量
  int getQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// 添加商品到购物车
  void addProduct(GxProduct product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(GxCartItem(product: product));
    }
    update(); // 手动通知 UI 更新
  }

  /// 从购物车中移除商品
  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    update();
  }

  /// 修改商品数量
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      update();
    }
  }

  /// 清空购物车
  void clearCart() {
    _items.clear();
    update();
  }

  @override
  void onClose() {
    // 控制器销毁时清理资源
    _items.clear();
    super.onClose();
  }
}

// ============================================================
// 第四部分：主应用入口
// ============================================================

void main() {
  runApp(const Ch06GetXApp());
}

class Ch06GetXApp extends StatelessWidget {
  const Ch06GetXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GetX 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.purple,
        useMaterial3: true,
      ),
      home: const MainTabPage(),
    );
  }
}

/// 主页面：使用 Tab 切换计数器和购物车
class MainTabPage extends StatelessWidget {
  const MainTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.put 注入控制器
    Get.put(CounterController());
    Get.put(CartController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎯 GetX 示例'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_circle), text: '计数器'),
              Tab(icon: Icon(Icons.shopping_cart), text: '购物车'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CounterPage(),
            ShoppingPage(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 第五部分：计数器页面（Obx 响应式）
// ============================================================

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Get.find 获取已注入的控制器
    final controller = Get.find<CounterController>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Obx 自动监听 .obs 变量的变化
            Obx(() => Text(
                  '${controller.count}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                )),
            const SizedBox(height: 16),
            // 消息也是响应式的
            Obx(() => Text(
                  controller.message.value,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'dec',
                  onPressed: controller.decrement,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'reset',
                  onPressed: controller.reset,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'inc',
                  onPressed: controller.increment,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 演示 Obx 的条件渲染
            Obx(() {
              if (controller.count.value >= 10) {
                return Card(
                  color: Colors.amber.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('计数已超过 10！'),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 第六部分：购物车页面（GetBuilder 简单状态管理）
// ============================================================

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部购物车摘要
        GetBuilder<CartController>(
          builder: (controller) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🛒 购物车 (${controller.itemCount} 件)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '¥${controller.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            );
          },
        ),

        // 商品列表
        Expanded(
          child: ListView(
            children: [
              // 商品区域
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '📦 商品列表',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...gxProducts.map((product) => _ProductTile(product: product)),

              const Divider(height: 32),

              // 购物车区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🛒 已选商品',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.find<CartController>().clearCart();
                      },
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ),
              // 使用 GetBuilder 显示购物车内容
              GetBuilder<CartController>(
                builder: (controller) {
                  if (controller.items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '购物车是空的',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: controller.items
                        .map((item) => _CartItemTile(item: item))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 商品列表项
class _ProductTile extends StatelessWidget {
  final GxProduct product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (controller) {
        final quantity = controller.getQuantity(product.id);
        return ListTile(
          leading: Text(product.emoji, style: const TextStyle(fontSize: 32)),
          title: Text(product.name),
          subtitle: Text('¥${product.price.toStringAsFixed(2)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quantity > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('x$quantity'),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => controller.addProduct(product),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 购物车项
class _CartItemTile extends StatelessWidget {
  final GxCartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(item.product.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '¥${item.product.price.toStringAsFixed(2)} × ${item.quantity} = ¥${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // 数量调节按钮
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => controller.updateQuantity(
                item.product.id,
                item.quantity - 1,
              ),
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => controller.updateQuantity(
                item.product.id,
                item.quantity + 1,
              ),
            ),
            // 删除按钮
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => controller.removeProduct(item.product.id),
            ),
          ],
        ),
      ),
    );
  }
}
