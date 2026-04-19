import 'package:flutter/material.dart';

/// 第5章：页面过渡动画
/// 展示 4 种过渡动画 + Hero 动画效果
void main() => runApp(const Ch05App());

class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch05 页面过渡动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TransitionDemoHome(),
    );
  }
}

// ============================================================
// 首页：展示各种过渡动画入口
// ============================================================
class TransitionDemoHome extends StatelessWidget {
  const TransitionDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面过渡动画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 4 种基础过渡动画
          _buildTransitionTile(
            context,
            title: '淡入淡出 (Fade)',
            subtitle: 'FadeTransition',
            icon: Icons.opacity,
            onTap: () => _pushWithTransition(
              context,
              const DemoPage(title: '淡入淡出效果', color: Colors.blue),
              TransitionType.fade,
            ),
          ),
          _buildTransitionTile(
            context,
            title: '滑动 (Slide)',
            subtitle: 'SlideTransition - 从右侧滑入',
            icon: Icons.swap_horiz,
            onTap: () => _pushWithTransition(
              context,
              const DemoPage(title: '滑动效果', color: Colors.green),
              TransitionType.slide,
            ),
          ),
          _buildTransitionTile(
            context,
            title: '缩放 (Scale)',
            subtitle: 'ScaleTransition',
            icon: Icons.zoom_in,
            onTap: () => _pushWithTransition(
              context,
              const DemoPage(title: '缩放效果', color: Colors.orange),
              TransitionType.scale,
            ),
          ),
          _buildTransitionTile(
            context,
            title: '旋转 (Rotation)',
            subtitle: 'RotationTransition',
            icon: Icons.rotate_right,
            onTap: () => _pushWithTransition(
              context,
              const DemoPage(title: '旋转效果', color: Colors.purple),
              TransitionType.rotation,
            ),
          ),
          _buildTransitionTile(
            context,
            title: '组合过渡 (Fade + Scale)',
            subtitle: '淡入 + 缩放组合',
            icon: Icons.animation,
            onTap: () => _pushWithTransition(
              context,
              const DemoPage(title: '组合过渡效果', color: Colors.teal),
              TransitionType.fadeScale,
            ),
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Hero 动画',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Hero 动画展示
          _buildHeroGrid(context),
        ],
      ),
    );
  }

  Widget _buildTransitionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Hero 动画网格：点击图标卡片跳转到详情页
  Widget _buildHeroGrid(BuildContext context) {
    final items = [
      const HeroItem(id: 1, icon: Icons.star, label: '收藏', color: Colors.amber),
      const HeroItem(id: 2, icon: Icons.favorite, label: '喜欢', color: Colors.red),
      const HeroItem(
          id: 3, icon: Icons.bookmark, label: '书签', color: Colors.blue),
      const HeroItem(
          id: 4, icon: Icons.music_note, label: '音乐', color: Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                reverseTransitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    HeroDetailPage(item: item),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  // Hero 动画 + 淡入效果
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hero 包裹共享元素，tag 必须唯一
                Hero(
                  tag: 'hero-icon-${item.id}',
                  child: Icon(item.icon, size: 48, color: item.color),
                ),
                const SizedBox(height: 8),
                Text(item.label),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 过渡类型枚举
// ============================================================
enum TransitionType { fade, slide, scale, rotation, fadeScale }

/// 根据过渡类型推入页面
void _pushWithTransition(
    BuildContext context, Widget page, TransitionType type) {
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case TransitionType.fade:
            // 淡入淡出
            return FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );

          case TransitionType.slide:
            // 从右侧滑入
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child,
            );

          case TransitionType.scale:
            // 从中心缩放
            return ScaleTransition(
              scale: CurvedAnimation(
                  parent: animation, curve: Curves.fastOutSlowIn),
              child: child,
            );

          case TransitionType.rotation:
            // 旋转进入（从半圈旋转到正常位置）+ 淡入
            return FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: Tween(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: child,
              ),
            );

          case TransitionType.fadeScale:
            // 淡入 + 缩放组合
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
        }
      },
    ),
  );
}

// ============================================================
// 过渡效果目标页面
// ============================================================
class DemoPage extends StatelessWidget {
  final String title;
  final Color color;

  const DemoPage({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color.withValues(alpha: 0.2),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 24, color: color),
            ),
            const SizedBox(height: 8),
            const Text('点击返回按钮查看反向动画'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Hero 动画相关
// ============================================================

/// Hero 动画的数据项
class HeroItem {
  final int id;
  final IconData icon;
  final String label;
  final Color color;

  const HeroItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// Hero 详情页
class HeroDetailPage extends StatelessWidget {
  final HeroItem item;

  const HeroDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.label)),
      body: Column(
        children: [
          const SizedBox(height: 40),
          // Hero 目标：使用相同的 tag
          Hero(
            tag: 'hero-icon-${item.id}',
            // 自定义 flightShuttleBuilder：飞行过程中添加旋转效果
            flightShuttleBuilder: (
              BuildContext flightContext,
              Animation<double> animation,
              HeroFlightDirection flightDirection,
              BuildContext fromHeroContext,
              BuildContext toHeroContext,
            ) {
              return RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
                child: Icon(item.icon, size: 120, color: item.color),
              );
            },
            child: Icon(item.icon, size: 120, color: item.color),
          ),
          const SizedBox(height: 24),
          Text(
            item.label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '这是「${item.label}」的详情页。\n'
              'Hero 动画会自动在两个页面之间创建共享元素过渡效果。\n\n'
              '本示例使用了自定义 flightShuttleBuilder，'
              '在飞行过程中添加了旋转效果。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
