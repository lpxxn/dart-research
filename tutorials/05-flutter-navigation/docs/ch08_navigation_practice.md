# 第8章：导航实战 —— 简易电商 App 导航架构

## 概述

本章将综合运用前面章节学到的知识，构建一个简易电商 App 的导航架构。这个项目涵盖：
- 底部 Tab 导航（首页、分类、购物车、我的）
- Hero 动画（商品列表 → 商品详情）
- 登录拦截（未登录状态下访问"我的"页面跳转登录）
- 自定义页面过渡动画
- 纯 Flutter 实现，不依赖第三方路由库

---

## 1. 项目导航架构设计

### 1.1 页面结构

```
App
├── MainScreen（底部 Tab 容器）
│   ├── Tab 0: HomePage（首页 - 商品列表）
│   │   └── → ProductDetailPage（商品详情，带 Hero 动画）
│   ├── Tab 1: CategoryPage（分类）
│   ├── Tab 2: CartPage（购物车）
│   └── Tab 3: ProfilePage（我的）
│       └── → 未登录时跳转 LoginPage
└── LoginPage（登录页，全屏覆盖）
```

### 1.2 导航策略

| 场景 | 策略 |
|------|------|
| Tab 切换 | `IndexedStack` 保持状态 |
| 商品详情 | 全局 `Navigator.push`，带 Hero 动画 |
| 登录页 | 全局 `Navigator.push`，自定义过渡 |
| 返回处理 | 使用 `PopScope` 拦截 |

---

## 2. 状态管理

### 2.1 简单的登录状态

本示例使用简单的 `ValueNotifier` 管理登录状态，真实项目中建议使用 Provider、Riverpod 等状态管理方案。

```dart
/// 全局登录状态管理
class AuthManager {
  static final AuthManager _instance = AuthManager._();
  factory AuthManager() => _instance;
  AuthManager._();

  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
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
```

---

## 3. 底部 Tab 导航

### 3.1 MainScreen 实现

```dart
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CategoryPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category), label: '分类'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart), label: '购物车'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

### 3.2 为什么使用 IndexedStack

`IndexedStack` 的优势：
1. **保持所有 Tab 页的状态**：切换 Tab 时不会销毁页面
2. **简单直接**：不需要手动管理 PageController
3. **性能适中**：所有 Tab 只初始化一次

缺点是所有 Tab 页会同时加载。如果 Tab 页初始化开销大，可以使用懒加载优化。

---

## 4. 商品列表与 Hero 动画

### 4.1 商品数据模型

```dart
class Product {
  final int id;
  final String name;
  final String image; // 这里用 Icon 代替
  final double price;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
  });
}
```

### 4.2 商品列表页

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => _navigateToDetail(context, product),
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image, size: 64)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(product.name),
                  ),
                  Text('¥${product.price}',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailPage(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
```

### 4.3 商品详情页

```dart
class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'product-${product.id}',
            child: Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.image, size: 120)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 24)),
                Text('¥${product.price}',
                    style: const TextStyle(fontSize: 20, color: Colors.red)),
                const SizedBox(height: 16),
                Text(product.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. 登录拦截

### 5.1 "我的" 页面

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ValueListenableBuilder<bool>(
        valueListenable: AuthManager().isLoggedIn,
        builder: (context, isLoggedIn, child) {
          if (isLoggedIn) {
            return _buildLoggedInView(context);
          } else {
            return _buildNotLoggedInView(context);
          }
        },
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('未登录'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 跳转登录页，使用自定义过渡
              Navigator.push(context, _loginRoute());
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _loginRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    );
  }
}
```

### 5.2 登录页

```dart
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  AuthManager().login(_controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 6. 自定义页面过渡

### 6.1 过渡策略

| 场景 | 过渡效果 |
|------|---------|
| 商品列表 → 详情 | Fade + Hero |
| 我的 → 登录 | 从底部滑入 |
| 其他页面切换 | 默认 Material 过渡 |

### 6.2 封装通用过渡

```dart
/// 底部滑入过渡路由
Route slideUpRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  );
}

/// 淡入过渡路由
Route fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
```

---

## 7. 返回处理

### 7.1 双击退出应用

```dart
class MainScreen extends StatefulWidget {
  // ...
}

class _MainScreenState extends State<MainScreen> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
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
              content: Text('再按一次退出'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(/* ... */),
    );
  }
}
```

---

## 8. 完整架构图

```
┌──────────────────────────────────────────────┐
│                   MaterialApp                 │
│  ┌──────────────────────────────────────────┐│
│  │            Root Navigator                ││
│  │  ┌──────────────────────────────────────┐││
│  │  │         MainScreen (PopScope)        │││
│  │  │  ┌──────────────────────────────────┐│││
│  │  │  │       IndexedStack               ││││
│  │  │  │  ┌────┬────┬────┬────┐           ││││
│  │  │  │  │首页│分类│购物车│我的│          ││││
│  │  │  │  └────┴────┴────┴────┘           ││││
│  │  │  └──────────────────────────────────┘│││
│  │  │  ┌──────────────────────────────────┐│││
│  │  │  │     NavigationBar (4 Tabs)       ││││
│  │  │  └──────────────────────────────────┘│││
│  │  └──────────────────────────────────────┘││
│  │                                          ││
│  │  Push: ProductDetailPage (Hero + Fade)   ││
│  │  Push: LoginPage (SlideUp)               ││
│  └──────────────────────────────────────────┘│
└──────────────────────────────────────────────┘
```

---

## 9. 最佳实践总结

### 9.1 导航架构选择

| 项目规模 | 推荐方案 |
|---------|---------|
| 小型 App（< 10 页面） | `Navigator` + `MaterialPageRoute` |
| 中型 App（10-30 页面） | 命名路由 + `onGenerateRoute` |
| 大型 App（> 30 页面） | `go_router` 或 `auto_route` |
| 需要深层链接 | `go_router` |

### 9.2 状态保持策略

1. `IndexedStack` 保持 Tab 页状态
2. `PageStorageKey` 保持滚动位置
3. `AutomaticKeepAliveClientMixin` 配合 `PageView` 使用

### 9.3 动画一致性

- 同类页面使用相同的过渡效果
- 商品列表 → 详情：Fade + Hero
- 模态页面（登录、设置）：从底部滑入
- 保持动画时长一致（300-500ms）

### 9.4 PopScope 使用

```dart
// ✅ 推荐：使用 PopScope（替代已弃用的 WillPopScope）
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    // 处理返回逻辑
  },
  child: /* ... */,
)
```

---

## 10. 小结

本章通过一个简易电商 App 的导航架构，综合运用了：
- `NavigationBar` 底部导航
- `IndexedStack` 状态保持
- `Hero` 共享元素动画
- `PageRouteBuilder` 自定义过渡
- `PopScope` 返回拦截
- `ValueNotifier` 简单状态管理

这些知识足以应对大多数中小型 Flutter App 的导航需求。对于更复杂的项目，建议引入 `go_router` 等路由库来管理声明式路由。
