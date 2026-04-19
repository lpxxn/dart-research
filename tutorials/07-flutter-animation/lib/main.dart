import 'package:flutter/material.dart';

void main() {
  runApp(const AnimationTutorialApp());
}

class AnimationTutorialApp extends StatelessWidget {
  const AnimationTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 动画与手势',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AnimationHomePage(),
    );
  }
}

class _ChapterInfo {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String file;

  const _ChapterInfo({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
  });
}

const _chapters = <_ChapterInfo>[
  _ChapterInfo(number: '01', title: '隐式动画', subtitle: 'AnimatedContainer 等', icon: Icons.animation, file: 'ch01_implicit_animations.dart'),
  _ChapterInfo(number: '02', title: '显式动画', subtitle: 'AnimationController', icon: Icons.motion_photos_on, file: 'ch02_explicit_animations.dart'),
  _ChapterInfo(number: '03', title: '交错动画', subtitle: 'Staggered Animations', icon: Icons.waterfall_chart, file: 'ch03_staggered_animations.dart'),
  _ChapterInfo(number: '04', title: 'Hero 动画', subtitle: '共享元素转场', icon: Icons.swap_calls, file: 'ch04_hero_animations.dart'),
  _ChapterInfo(number: '05', title: '物理动画', subtitle: '弹簧与摩擦力', icon: Icons.speed, file: 'ch05_physics_animations.dart'),
  _ChapterInfo(number: '06', title: '手势识别', subtitle: 'GestureDetector', icon: Icons.touch_app, file: 'ch06_gestures.dart'),
  _ChapterInfo(number: '07', title: '自定义转场', subtitle: 'PageRouteBuilder', icon: Icons.swap_horiz, file: 'ch07_custom_transitions.dart'),
  _ChapterInfo(number: '08', title: 'Lottie / Rive', subtitle: '第三方动画集成', icon: Icons.movie_creation, file: 'ch08_lottie_rive.dart'),
  _ChapterInfo(number: '09', title: '动画综合实战', subtitle: '综合练习项目', icon: Icons.rocket_launch, file: 'ch09_animation_practice.dart'),
];

class AnimationHomePage extends StatelessWidget {
  const AnimationHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 动画与手势'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final ch = _chapters[index];
                return Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('请运行: flutter run -t lib/${ch.file}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(ch.icon, size: 32, color: colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            '第 ${ch.number} 章',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              '请使用 flutter run -t lib/chXX_xxx.dart 运行各章节示例',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
