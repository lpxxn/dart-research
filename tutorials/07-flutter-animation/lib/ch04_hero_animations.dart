import 'package:flutter/material.dart';

/// 第4章：Hero 动画示例
/// 展示 Hero 基本用法、tag 匹配、flightShuttleBuilder、
/// 图片画廊→放大效果。

void main() => runApp(const Ch04App());

class Ch04App extends StatelessWidget {
  const Ch04App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第4章：Hero 动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.purple,
        useMaterial3: true,
      ),
      home: const HeroGalleryPage(),
    );
  }
}

/// 预定义的颜色和标签，模拟图片数据
class PhotoItem {
  final Color color;
  final String title;
  final IconData icon;
  final String description;

  const PhotoItem({
    required this.color,
    required this.title,
    required this.icon,
    required this.description,
  });
}

const _photos = [
  PhotoItem(
    color: Colors.red,
    title: '热情红',
    icon: Icons.local_fire_department,
    description: '红色代表热情与活力，是最能吸引注意力的颜色。',
  ),
  PhotoItem(
    color: Colors.blue,
    title: '宁静蓝',
    icon: Icons.water_drop,
    description: '蓝色代表宁静与信任，是最受欢迎的颜色之一。',
  ),
  PhotoItem(
    color: Colors.green,
    title: '自然绿',
    icon: Icons.eco,
    description: '绿色代表自然与生机，令人感到放松和舒适。',
  ),
  PhotoItem(
    color: Colors.orange,
    title: '活力橙',
    icon: Icons.wb_sunny,
    description: '橙色代表温暖与快乐，充满阳光般的活力。',
  ),
  PhotoItem(
    color: Colors.purple,
    title: '神秘紫',
    icon: Icons.auto_awesome,
    description: '紫色代表神秘与优雅，是皇室的象征色。',
  ),
  PhotoItem(
    color: Colors.teal,
    title: '清新青',
    icon: Icons.spa,
    description: '青色代表清新与平衡，介于蓝色和绿色之间。',
  ),
  PhotoItem(
    color: Colors.pink,
    title: '浪漫粉',
    icon: Icons.favorite,
    description: '粉色代表浪漫与温柔，是最具女性魅力的颜色。',
  ),
  PhotoItem(
    color: Colors.amber,
    title: '琥珀金',
    icon: Icons.diamond,
    description: '琥珀色代表珍贵与温暖，如同凝固的阳光。',
  ),
  PhotoItem(
    color: Colors.indigo,
    title: '深邃靛',
    icon: Icons.nightlight,
    description: '靛色代表深邃与智慧，如同深夜的天空。',
  ),
];

// ============================================================
// 画廊页面 —— Grid 布局，每个方块包裹在 Hero 中
// ============================================================
class HeroGalleryPage extends StatelessWidget {
  const HeroGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第4章：Hero 动画 - 色彩画廊')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
            return GestureDetector(
              onTap: () {
                // 导航到详情页，Hero 动画自动触发
                Navigator.push(
                  context,
                  // 使用 PageRouteBuilder 自定义过渡时间
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    reverseTransitionDuration:
                        const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondAnimation) =>
                        PhotoDetailPage(index: index, photo: photo),
                    transitionsBuilder: (context, animation, secondAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              // Hero：用 tag 标识，在两个页面间建立关联
              child: Hero(
                tag: 'photo-$index',
                // flightShuttleBuilder：自定义飞行过程中的外观
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      // 飞行过程中圆角从 16 过渡到 24
                      final borderRadius = BorderRadius.circular(
                        16 + animation.value * 8,
                      );
                      return ClipRRect(
                        borderRadius: borderRadius,
                        child: Material(
                          color: photo.color,
                          child: Center(
                            child: Icon(
                              photo.icon,
                              color: Colors.white.withValues(
                                alpha: 0.6 + animation.value * 0.4,
                              ),
                              size: 32 + animation.value * 32,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Material(
                  color: photo.color,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(photo.icon, color: Colors.white, size: 32),
                      const SizedBox(height: 4),
                      Text(
                        photo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// 详情页 —— 展示放大后的内容
// ============================================================
class PhotoDetailPage extends StatelessWidget {
  final int index;
  final PhotoItem photo;

  const PhotoDetailPage({
    super.key,
    required this.index,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用透明 AppBar 覆盖在 Hero 上方
      appBar: AppBar(
        title: Text(photo.title),
        backgroundColor: photo.color.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero：tag 与画廊页一致，Flutter 自动产生飞行动画
          Hero(
            tag: 'photo-$index',
            child: Material(
              color: photo.color,
              child: SizedBox(
                height: 280,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(photo.icon, color: Colors.white, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        photo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 详情信息（Hero 动画之外的部分）
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  photo.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 24),
                // 提示信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: photo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: photo.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '点击返回按钮查看反向 Hero 飞行效果',
                          style: TextStyle(color: photo.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
