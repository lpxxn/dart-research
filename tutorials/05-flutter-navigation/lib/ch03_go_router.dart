import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 第3章：GoRouter
/// 演示声明式路由、路径参数、ShellRoute、路由重定向（登录守卫）
void main() => runApp(const Ch03App());

// =============================================================================
// 模拟认证服务 — 用于演示登录守卫
// =============================================================================

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void login() {
    _isLoggedIn = true;
    notifyListeners(); // 通知 GoRouter 重新评估 redirect
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

// =============================================================================
// 路由配置
// =============================================================================

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  debugLogDiagnostics: true, // 开启调试日志

  // 监听认证状态变化，自动刷新路由
  refreshListenable: AuthService.instance,

  // 全局重定向 — 登录守卫
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';

    // 未登录且不是去登录页 → 重定向到登录页
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // 已登录且要去登录页 → 重定向到首页
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // 不需要重定向
    return null;
  },

  routes: [
    // 登录页（ShellRoute 之外，不显示底部导航栏）
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    // ShellRoute — 共享底部导航栏布局
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        // 首页 Tab
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeTab(),
          routes: [
            // 嵌套路由：商品详情页（在 ShellRoute 内显示）
            GoRoute(
              path: 'detail/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '0';
                return ProductDetailPage(productId: id);
              },
            ),
          ],
        ),

        // 发现 Tab
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreTab(),
        ),

        // 个人中心 Tab
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileTab(),
        ),
      ],
    ),
  ],
);

// =============================================================================
// App 入口
// =============================================================================

class Ch03App extends StatelessWidget {
  const Ch03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '第3章：GoRouter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// =============================================================================
// 主布局 — 带底部导航栏的 Scaffold（ShellRoute 的 builder）
// =============================================================================

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // ShellRoute 的子路由页面内容
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.explore), label: '发现'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  /// 根据当前路径计算选中的 Tab 索引
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // /home 及其子路由
  }

  /// Tab 切换导航
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/explore');
      case 2:
        context.go('/profile');
    }
  }
}

// =============================================================================
// 登录页
// =============================================================================

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('欢迎使用 GoRouter 示例',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('请登录以继续', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // 登录后 GoRouter 自动重定向到首页（通过 refreshListenable）
                    AuthService.instance.login();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('登录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 首页 Tab — 商品列表，点击跳转到详情页（路径参数）
// =============================================================================

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 10,
        itemBuilder: (context, index) {
          final id = index + 1;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('$id')),
              title: Text('商品 #$id'),
              subtitle: Text('点击查看详情（路径参数 /home/detail/$id）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 使用 context.go 导航到嵌套路由
                // 路径：/home/detail/:id
                context.go('/home/detail/$id');
              },
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 商品详情页 — 接收路径参数
// =============================================================================

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商品详情 #$productId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // 返回首页
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('商品 ID: $productId',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                '本页通过路径参数接收数据：\n'
                'path: /home/detail/:id\n'
                'state.pathParameters["id"] = $productId',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // 演示查询参数（GoRouter 的 state.uri.queryParameters）
              Text(
                '当前完整路径: /home/detail/$productId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 发现 Tab
// =============================================================================

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text('发现页', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                '这是 ShellRoute 的第二个 Tab。\n'
                '底部导航栏在所有 Tab 中保持可见。\n'
                '切换 Tab 时 Scaffold 不会重建。',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 个人中心 Tab — 包含退出登录按钮
// =============================================================================

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              Text('已登录用户',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),

              // 退出登录 — GoRouter 的 redirect 会自动跳转到登录页
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AuthService.instance.logout();
                    // 不需要手动导航，refreshListenable 会触发 redirect
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '退出后 GoRouter 的 redirect 会自动跳转到登录页',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
