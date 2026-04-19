import 'package:flutter/material.dart';

/// 第8章：导航实战 —— 简易电商 App 导航架构
/// 功能：
/// - 底部 Tab：首页、分类、购物车、我的
/// - 首页 → 商品详情（Hero 动画）
/// - "我的" → 未登录跳转登录页（自定义从底部滑入过渡）
/// - 双击返回退出提示
void main() => runApp(const Ch08App());

class Ch08App extends StatelessWidget {
  const Ch08App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch08 导航实战',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================
// 全局登录状态管理（简单的单例 + ValueNotifier）
// ============================================================
class AuthManager {
  // 私有构造 + 单例
  AuthManager._();
  static final AuthManager _instance = AuthManager._();
  factory AuthManager() => _instance;

  /// 登录状态通知
  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  /// 当前用户名
  String? username;

  void login(String name) {
    username = name;
    isLoggedIn.value = true;
  }

  void logout() {
    username = null;
    isLoggedIn.value = false;
  }
}

// ============================================================
// 商品数据模型
// ============================================================
class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final IconData icon;
  final Color color;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// 模拟商品数据
const List<Product> _mockProducts = [
  Product(
    id: 1, name: '智能手表', price: 1299,
    description: '支持心率监测、GPS定位、NFC支付等功能。续航7天，50米防水。',
    icon: Icons.watch, color: Colors.blue,
  ),
  Product(
    id: 2, name: '无线耳机', price: 699,
    description: '主动降噪，蓝牙5.3，30小时续航。支持空间音频。',
    icon: Icons.headphones, color: Colors.purple,
  ),
  Product(
    id: 3, name: '便携音箱', price: 399,
    description: '360度环绕立体声，IP67防尘防水，续航12小时。',
    icon: Icons.speaker, color: Colors.orange,
  ),
  Product(
    id: 4, name: '平板电脑', price: 3999,
    description: '11英寸全面屏，M系列芯片，支持手写笔和键盘。',
    icon: Icons.tablet_mac, color: Colors.teal,
  ),
  Product(
    id: 5, name: '机械键盘', price: 599,
    description: '热插拔轴体，RGB背光，支持有线/蓝牙/2.4G三模连接。',
    icon: Icons.keyboard, color: Colors.indigo,
  ),
  Product(
    id: 6, name: '移动电源', price: 199,
    description: '20000mAh大容量，65W快充，同时充3台设备。',
    icon: Icons.battery_charging_full, color: Colors.green,
  ),
];

// ============================================================
// 主屏幕：底部 4 Tab 导航
// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  // 4 个 Tab 页面（使用 const 减少重建）
  final List<Widget> _pages = const [
    HomePage(),
    CategoryPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 使用 PopScope 实现双击退出
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('再按一次退出应用'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        // 使用 IndexedStack 保持 Tab 页状态
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: '分类',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: '购物车',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 0：首页 - 商品列表（带 Hero 动画跳转详情）
// ============================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商城首页'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('搜索功能示例'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        key: const PageStorageKey<String>('home-grid'),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _mockProducts.length,
        itemBuilder: (context, index) {
          final product = _mockProducts[index];
          return _ProductCard(product: product);
        },
      ),
    );
  }
}

/// 商品卡片组件
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 使用自定义 Fade 过渡 + Hero 动画跳转商品详情
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailPage(product: product),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero 包裹商品图标区域
            Expanded(
              child: Hero(
                tag: 'product-${product.id}',
                child: Container(
                  color: product.color.withValues(alpha: 0.1),
                  child: Icon(product.icon, size: 64, color: product.color),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 商品详情页（Hero 动画目标）
// ============================================================
class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero 目标：与列表中的 tag 匹配
            Hero(
              tag: 'product-${product.id}',
              child: Container(
                height: 280,
                color: product.color.withValues(alpha: 0.1),
                child: Icon(product.icon, size: 120, color: product.color),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '商品详情',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已加入购物车'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('加入购物车'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('立即购买（示例）'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.flash_on),
                          label: const Text('立即购买'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 1：分类页
// ============================================================
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('手机数码', Icons.phone_android),
      ('电脑办公', Icons.computer),
      ('家用电器', Icons.tv),
      ('运动户外', Icons.sports_basketball),
      ('服饰鞋帽', Icons.checkroom),
      ('美妆个护', Icons.face),
      ('食品饮料', Icons.local_cafe),
      ('图书影音', Icons.menu_book),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('商品分类')),
      body: ListView.separated(
        key: const PageStorageKey<String>('category-list'),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (name, icon) = categories[index];
          return ListTile(
            leading: Icon(icon),
            title: Text(name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('进入 $name 分类（示例）'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// Tab 2：购物车页
// ============================================================
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '购物车是空的',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // 提示用户去首页逛逛
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('去首页添加商品吧'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('去逛逛'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 3：我的页面（登录状态判断）
// ============================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ValueListenableBuilder<bool>(
        valueListenable: AuthManager().isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return isLoggedIn
              ? _LoggedInView()
              : const _NotLoggedInView();
        },
      ),
    );
  }
}

/// 未登录视图
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '未登录',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // 自定义从底部滑入的过渡动画跳转登录页
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    // 从底部滑入
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('登录 / 注册'),
          ),
        ],
      ),
    );
  }
}

/// 已登录视图
class _LoggedInView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = AuthManager();
    return ListView(
      children: [
        // 用户头像和信息
        Container(
          padding: const EdgeInsets.all(24),
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (auth.username ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.username ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('欢迎回来！', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        // 功能菜单
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('我的订单'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('我的收藏'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('收货地址'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('设置'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        const Divider(),
        // 退出登录
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('退出登录', style: TextStyle(color: Colors.red)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认退出'),
                content: const Text('确定要退出登录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              auth.logout();
            }
          },
        ),
      ],
    );
  }
}

// ============================================================
// 登录页
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入用户名'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // 模拟登录成功
    AuthManager().login(username);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Icon(
              Icons.storefront,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              '欢迎登录',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // 用户名
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // 密码
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 24),
            // 登录按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _handleLogin,
                child: const Text('登录', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            // 提示
            Text(
              '输入任意用户名即可登录（演示用）',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
