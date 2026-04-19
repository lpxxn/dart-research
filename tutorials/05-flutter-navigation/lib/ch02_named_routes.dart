import 'package:flutter/material.dart';

/// 第2章：命名路由
/// 演示 routes 表、pushNamed、onGenerateRoute、onUnknownRoute、参数传递
void main() => runApp(const Ch02App());

// =============================================================================
// 路由名称常量 — 避免拼写错误
// =============================================================================

class AppRoutes {
  static const home = '/';
  static const detail = '/detail';
  static const settings = '/settings';
  static const login = '/login';
  // 动态路由由 onGenerateRoute 处理：/user/:id
}

// =============================================================================
// App 入口 — 配置 routes、onGenerateRoute、onUnknownRoute
// =============================================================================

class Ch02App extends StatelessWidget {
  const Ch02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第2章：命名路由',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      // 初始路由（不要同时设置 home 参数）
      initialRoute: AppRoutes.home,

      // 静态路由映射表
      routes: {
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.login: (context) => const LoginPage(),
      },

      // 动态路由生成 — 处理 routes 表中没有的路由
      onGenerateRoute: (RouteSettings settings) {
        final uri = Uri.parse(settings.name ?? '');

        // 匹配 /detail（带 arguments 参数）
        if (settings.name == AppRoutes.detail) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DetailPage(
              itemId: args?['id'] as int? ?? 0,
              itemTitle: args?['title'] as String? ?? '未知商品',
            ),
            settings: settings,
          );
        }

        // 匹配 /user/:id — 路径参数解析
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'user') {
          final userId = int.tryParse(uri.pathSegments[1]);
          if (userId != null) {
            return MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: userId),
              settings: settings,
            );
          }
        }

        // 匹配 /search?q=xxx — 查询参数解析
        if (uri.path == '/search') {
          final query = uri.queryParameters['q'] ?? '';
          return MaterialPageRoute(
            builder: (context) => SearchResultPage(query: query),
            settings: settings,
          );
        }

        // 未匹配返回 null，会调用 onUnknownRoute
        return null;
      },

      // 未知路由 — 404 页面
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: (context) => NotFoundPage(routeName: settings.name ?? ''),
        );
      },
    );
  }
}

// =============================================================================
// 首页 — 提供多种导航方式的入口按钮
// =============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第2章：命名路由'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('pushNamed + arguments 传参'),

          // 1. pushNamed 带 arguments
          _NavButton(
            title: '查看商品详情（arguments 传参）',
            subtitle: "pushNamed('/detail', arguments: {...})",
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.detail,
                arguments: {'id': 42, 'title': 'Flutter 实战指南'},
              );
            },
          ),

          const Divider(height: 32),
          _SectionTitle('onGenerateRoute 动态路由'),

          // 2. 动态路由 — 路径参数
          _NavButton(
            title: '查看用户主页（路径参数 /user/100）',
            subtitle: "pushNamed('/user/100')",
            onTap: () {
              Navigator.pushNamed(context, '/user/100');
            },
          ),

          // 3. 动态路由 — 查询参数
          _NavButton(
            title: '搜索 Flutter（查询参数）',
            subtitle: "pushNamed('/search?q=Flutter')",
            onTap: () {
              Navigator.pushNamed(context, '/search?q=Flutter');
            },
          ),

          const Divider(height: 32),
          _SectionTitle('路由栈操作'),

          // 4. pushReplacementNamed
          _NavButton(
            title: '进入设置页（pushReplacementNamed）',
            subtitle: '替换当前路由，无法返回首页',
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.settings);
            },
          ),

          const Divider(height: 32),
          _SectionTitle('404 未知路由'),

          // 5. 访问不存在的路由
          _NavButton(
            title: '访问不存在的页面',
            subtitle: "pushNamed('/this-page-does-not-exist')",
            onTap: () {
              Navigator.pushNamed(context, '/this-page-does-not-exist');
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 详情页 — 通过 onGenerateRoute 解析 arguments 后传入构造函数
// =============================================================================

class DetailPage extends StatelessWidget {
  final int itemId;
  final String itemTitle;

  const DetailPage({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(itemTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('商品 ID: $itemId',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              const Text(
                '本页通过 pushNamed + arguments 传参，\n'
                '在 onGenerateRoute 中解析后传入构造函数。',
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
// 用户主页 — 通过 onGenerateRoute 解析路径参数 /user/:id
// =============================================================================

class UserProfilePage extends StatelessWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户 #$userId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                child: Text('U$userId', style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 24),
              Text('用户 ID: $userId',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                '本页通过 onGenerateRoute 解析路径参数：\n'
                "Navigator.pushNamed(context, '/user/100')\n"
                '→ 匹配 /user/:id → userId = 100',
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
// 搜索结果页 — 通过 onGenerateRoute 解析查询参数
// =============================================================================

class SearchResultPage extends StatelessWidget {
  final String query;

  const SearchResultPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('搜索: $query'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text('搜索关键词: "$query"',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                '本页通过 onGenerateRoute 解析查询参数：\n'
                "Navigator.pushNamed(context, '/search?q=Flutter')\n"
                '→ 匹配 /search → q = Flutter',
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
// 设置页 — 演示 pushNamedAndRemoveUntil
// =============================================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                '本页通过 pushReplacementNamed 进入，\n首页已被替换，无法返回。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // pushNamedAndRemoveUntil 清空路由栈后跳转到登录页
              ElevatedButton.icon(
                onPressed: () {
                  // 跳转到登录页，清除所有之前的路由
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false, // 移除所有路由
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('退出登录（清空路由栈）'),
              ),
              const SizedBox(height: 16),

              // 回到首页
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('回到首页（重置路由栈）'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 登录页 — 演示登录后跳转
// =============================================================================

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false, // 隐藏返回按钮
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                '你已退出登录。\n路由栈已清空，无法返回之前的页面。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // 登录后替换为首页
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                icon: const Icon(Icons.login),
                label: const Text('重新登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 404 页面 — onUnknownRoute 处理未知路由
// =============================================================================

class NotFoundPage extends StatelessWidget {
  final String routeName;

  const NotFoundPage({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面未找到'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                '404',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                '页面 "$routeName" 不存在',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('回到首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 辅助 Widget
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
