import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 第4章：Deep Linking
/// 演示 Deep Link 路由解析 — 用 GoRouter 配置多个路径，模拟外部链接跳转
void main() => runApp(const Ch04App());

// =============================================================================
// GoRouter 路由配置 — 支持多种 Deep Link 路径
// =============================================================================

final GoRouter _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,

  // 错误页面（相当于 404）
  errorBuilder: (context, state) {
    return NotFoundPage(path: state.uri.toString());
  },

  routes: [
    // 首页 — Deep Link 测试入口
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    // 商品详情页 — 路径参数
    // Deep Link 示例: myapp://product/42
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '0';
        return ProductPage(productId: id);
      },
    ),

    // 用户相关页面 — 嵌套路由
    // Deep Link 示例: myapp://user/100, myapp://user/100/orders
    GoRoute(
      path: '/user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '0';
        return UserPage(userId: userId);
      },
      routes: [
        // 嵌套路由：用户订单页
        // 完整路径: /user/:userId/orders
        GoRoute(
          path: 'orders',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '0';
            return UserOrdersPage(userId: userId);
          },
        ),
      ],
    ),

    // 搜索页 — 查询参数
    // Deep Link 示例: myapp://search?q=flutter&category=book
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        final category = state.uri.queryParameters['category'] ?? '全部';
        return SearchPage(query: query, category: category);
      },
    ),

    // 活动推广页 — 路径参数
    // Deep Link 示例: myapp://promo/SUMMER2024
    GoRoute(
      path: '/promo/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return PromoPage(promoCode: code);
      },
    ),

    // 关于页面 — 简单静态路径
    // Deep Link 示例: myapp://about
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),
  ],
);

// =============================================================================
// App 入口
// =============================================================================

class Ch04App extends StatelessWidget {
  const Ch04App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '第4章：Deep Linking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// =============================================================================
// 首页 — Deep Link 模拟测试入口
// =============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第4章：Deep Linking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 16),

          _SectionTitle('路径参数 Deep Link'),

          // 模拟 Deep Link: /product/42
          _DeepLinkButton(
            label: '/product/42',
            description: '商品详情（路径参数）',
            onTap: () => context.go('/product/42'),
          ),

          // 模拟 Deep Link: /user/100
          _DeepLinkButton(
            label: '/user/100',
            description: '用户主页（路径参数）',
            onTap: () => context.go('/user/100'),
          ),

          const SizedBox(height: 8),
          _SectionTitle('嵌套路由 Deep Link'),

          // 模拟 Deep Link: /user/100/orders
          _DeepLinkButton(
            label: '/user/100/orders',
            description: '用户订单（嵌套路由，可返回用户主页）',
            onTap: () => context.go('/user/100/orders'),
          ),

          const SizedBox(height: 8),
          _SectionTitle('查询参数 Deep Link'),

          // 模拟 Deep Link: /search?q=flutter&category=book
          _DeepLinkButton(
            label: '/search?q=flutter&category=book',
            description: '搜索页（查询参数）',
            onTap: () => context.go('/search?q=flutter&category=book'),
          ),

          const SizedBox(height: 8),
          _SectionTitle('活动推广 Deep Link'),

          // 模拟 Deep Link: /promo/SUMMER2024
          _DeepLinkButton(
            label: '/promo/SUMMER2024',
            description: '活动推广页',
            onTap: () => context.go('/promo/SUMMER2024'),
          ),

          const SizedBox(height: 8),
          _SectionTitle('其他'),

          _DeepLinkButton(
            label: '/about',
            description: '关于页面（静态路径）',
            onTap: () => context.go('/about'),
          ),

          // 测试 404
          _DeepLinkButton(
            label: '/this/does/not/exist',
            description: '不存在的页面（测试 404）',
            onTap: () => context.go('/this/does/not/exist'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 20),
                SizedBox(width: 8),
                Text('Deep Link 模拟测试',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '点击下方按钮模拟不同的 Deep Link 跳转。\n'
              '每个按钮对应一个 URL 路径，GoRouter 会自动解析并导航到对应页面。\n\n'
              '在真实场景中，这些 URL 来自系统（如通知点击、浏览器链接）。',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 商品详情页 — /product/:id
// =============================================================================

class ProductPage extends StatelessWidget {
  final String productId;
  const ProductPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商品 #$productId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _PageContent(
          icon: Icons.shopping_bag,
          title: '商品详情',
          details: [
            '商品 ID: $productId',
            '',
            'Deep Link 路径: /product/$productId',
            '路由定义: /product/:id',
            'state.pathParameters["id"] = $productId',
          ],
          onBack: () => context.go('/'),
        ),
      ),
    );
  }
}

// =============================================================================
// 用户主页 — /user/:userId
// =============================================================================

class UserPage extends StatelessWidget {
  final String userId;
  const UserPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户 #$userId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageContent(
              icon: Icons.person,
              title: '用户主页',
              details: [
                '用户 ID: $userId',
                '',
                'Deep Link 路径: /user/$userId',
                '路由定义: /user/:userId',
              ],
              onBack: () => context.go('/'),
            ),
            const SizedBox(height: 16),
            // 跳转到嵌套路由
            FilledButton.icon(
              onPressed: () => context.go('/user/$userId/orders'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('查看我的订单（嵌套路由）'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 用户订单页 — /user/:userId/orders（嵌套路由）
// =============================================================================

class UserOrdersPage extends StatelessWidget {
  final String userId;
  const UserOrdersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户 #$userId 的订单'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('嵌套路由说明',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Deep Link 路径: /user/$userId/orders\n'
                      '路由定义: /user/:userId/orders\n\n'
                      '这是 /user/:userId 的嵌套路由。\n'
                      '通过 Deep Link 直接打开此页面时，\n'
                      'GoRouter 自动构建导航栈：\n'
                      '[UserPage($userId), UserOrdersPage($userId)]',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 模拟订单列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt),
                    title: Text('订单 #${1000 + index}'),
                    subtitle: Text('用户 $userId 的第 ${index + 1} 个订单'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 搜索页 — /search?q=xxx&category=yyy
// =============================================================================

class SearchPage extends StatelessWidget {
  final String query;
  final String category;

  const SearchPage({super.key, required this.query, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索结果'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _PageContent(
          icon: Icons.search,
          title: '搜索页',
          details: [
            '关键词: $query',
            '分类: $category',
            '',
            'Deep Link 路径: /search?q=$query&category=$category',
            '路由定义: /search',
            'state.uri.queryParameters["q"] = $query',
            'state.uri.queryParameters["category"] = $category',
          ],
          onBack: () => context.go('/'),
        ),
      ),
    );
  }
}

// =============================================================================
// 活动推广页 — /promo/:code
// =============================================================================

class PromoPage extends StatelessWidget {
  final String promoCode;
  const PromoPage({super.key, required this.promoCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活动推广'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _PageContent(
          icon: Icons.celebration,
          title: '🎉 活动推广',
          details: [
            '推广码: $promoCode',
            '',
            'Deep Link 路径: /promo/$promoCode',
            '路由定义: /promo/:code',
            '',
            '此类页面常用于营销活动：',
            '• 短信/邮件中的推广链接',
            '• 社交媒体分享链接',
            '• 广告投放链接',
          ],
          onBack: () => context.go('/'),
        ),
      ),
    );
  }
}

// =============================================================================
// 关于页面 — /about
// =============================================================================

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _PageContent(
          icon: Icons.info_outline,
          title: '关于',
          details: const [
            'Flutter Navigation 教程',
            '第4章：Deep Linking',
            '',
            '本示例演示了如何使用 GoRouter',
            '配置多个路径以支持 Deep Link。',
          ],
          onBack: () => context.go('/'),
        ),
      ),
    );
  }
}

// =============================================================================
// 404 页面 — GoRouter errorBuilder
// =============================================================================

class NotFoundPage extends StatelessWidget {
  final String path;
  const NotFoundPage({super.key, required this.path});

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
              const Icon(Icons.link_off, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text('404',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(color: Colors.red)),
              const SizedBox(height: 8),
              Text('路径 "$path" 不存在',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Deep Link 指向了未配置的路径。\n'
                '在生产环境中应提供友好的 404 页面\n'
                '并引导用户回到主页。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
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
      padding: const EdgeInsets.only(top: 8, bottom: 4),
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

class _DeepLinkButton extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onTap;

  const _DeepLinkButton({
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link, size: 20),
        title: Text(label,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
        subtitle: Text(description),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> details;
  final VoidCallback onBack;

  const _PageContent({
    required this.icon,
    required this.title,
    required this.details,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...details.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(line,
                    textAlign: TextAlign.center,
                    style: line.isEmpty
                        ? null
                        : Theme.of(context).textTheme.bodyMedium),
              )),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.home),
            label: const Text('回到首页'),
          ),
        ],
      ),
    );
  }
}
