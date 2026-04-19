import 'package:flutter/material.dart';

import 'examples/ex00_philosophy_demo.dart';
import 'examples/ex01_greeting_card.dart';
import 'examples/ex02_counter_button.dart';
import 'examples/ex03_styled_card.dart';
import 'examples/ex04_circle_progress.dart';
import 'examples/ex05_theme_basic.dart';
import 'examples/ex06_dark_light.dart';
import 'examples/ex07_theme_extension.dart';
import 'examples/ex08_component_theme.dart';
import 'examples/ex09_animated_theme.dart';
import 'examples/ex10_skinnable_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 自定义控件 & 主题教程',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TutorialHomePage(),
    );
  }
}

/// 教程章节数据
class _Chapter {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _Chapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class TutorialHomePage extends StatelessWidget {
  const TutorialHomePage({super.key});

  static final List<_Chapter> _chapters = [
    _Chapter(
      number: '第0章',
      title: '设计哲学与理念',
      subtitle: '组合优于继承 · 声明式UI · Key的意义',
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      builder: (_) => const PhilosophyDemoPage(),
    ),
    _Chapter(
      number: '第1章',
      title: '基础自定义控件',
      subtitle: 'StatelessWidget 组合 · GreetingCard',
      icon: Icons.widgets_outlined,
      color: Colors.blue,
      builder: (_) => const GreetingCardExample(),
    ),
    _Chapter(
      number: '第2章',
      title: 'StatefulWidget 交互',
      subtitle: 'State 生命周期 · CounterButton',
      icon: Icons.touch_app_outlined,
      color: Colors.green,
      builder: (_) => const CounterButtonExample(),
    ),
    _Chapter(
      number: '第3章',
      title: '控件美化',
      subtitle: '装饰 · 阴影 · 渐变 · 毛玻璃',
      icon: Icons.brush_outlined,
      color: Colors.pink,
      builder: (_) => const StyledCardExample(),
    ),
    _Chapter(
      number: '第4章',
      title: 'CustomPainter 自绘',
      subtitle: 'Canvas API · 环形进度条',
      icon: Icons.palette_outlined,
      color: Colors.teal,
      builder: (_) => const CircleProgressExample(),
    ),
    _Chapter(
      number: '第5章',
      title: 'ThemeData 全局主题',
      subtitle: 'ColorScheme · TextTheme · Material 3',
      icon: Icons.color_lens_outlined,
      color: Colors.deepPurple,
      builder: (_) => const ThemeBasicExample(),
    ),
    _Chapter(
      number: '第6章',
      title: '深色/浅色切换',
      subtitle: 'ThemeMode · 跟随系统 · 平滑过渡',
      icon: Icons.dark_mode_outlined,
      color: Colors.indigo,
      builder: (_) => const DarkLightExample(),
    ),
    _Chapter(
      number: '第7章',
      title: 'ThemeExtension',
      subtitle: '自定义品牌色 · lerp 动画插值',
      icon: Icons.extension_outlined,
      color: Colors.orange,
      builder: (_) => const ThemeExtensionExample(),
    ),
    _Chapter(
      number: '第8章',
      title: '组件级主题定制',
      subtitle: 'ButtonTheme · InputTheme · CardTheme',
      icon: Icons.tune_outlined,
      color: Colors.cyan,
      builder: (_) => const ComponentThemeExample(),
    ),
    _Chapter(
      number: '第9章',
      title: '动画主题切换',
      subtitle: 'AnimatedTheme · 动态换肤 · 持久化',
      icon: Icons.animation_outlined,
      color: Colors.red,
      builder: (_) => const AnimatedThemeExample(),
    ),
    _Chapter(
      number: '第10章',
      title: '开源控件皮肤剖析',
      subtitle: 'sleek_circular_slider · 可换肤滑块',
      icon: Icons.code_outlined,
      color: Colors.purple,
      builder: (_) => const SkinnableSliderExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 大标题 AppBar
          SliverAppBar.large(
            title: const Text('Flutter 控件 & 主题教程'),
            centerTitle: true,
          ),
          // 副标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                '由浅入深，从设计哲学到动态换肤的完整学习路径',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          // 章节列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: _chapters.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ch = _chapters[index];
                return _ChapterCard(chapter: ch);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final _Chapter chapter;
  const _ChapterCard({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: chapter.builder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 章节图标
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: chapter.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(chapter.icon, color: chapter.color, size: 28),
              ),
              const SizedBox(width: 16),
              // 章节信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${chapter.number}  ${chapter.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
