import 'package:flutter/material.dart';

/// 第三章：多子布局控件示例
/// 演示 Row、Column、Flexible、Expanded、Spacer、Wrap、Flow 的用法
void main() => runApp(const MultiChildLayoutApp());

class MultiChildLayoutApp extends StatelessWidget {
  const MultiChildLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第三章：多子布局控件',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MultiChildLayoutDemo(),
    );
  }
}

class MultiChildLayoutDemo extends StatelessWidget {
  const MultiChildLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('多子布局控件')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === 第一节：Row 和 MainAxisAlignment ===
          const _SectionTitle('1. Row - MainAxisAlignment 对齐方式'),
          const _SubTitle('MainAxisAlignment.start'),
          _buildRowDemo(MainAxisAlignment.start),
          const SizedBox(height: 8),
          const _SubTitle('MainAxisAlignment.center'),
          _buildRowDemo(MainAxisAlignment.center),
          const SizedBox(height: 8),
          const _SubTitle('MainAxisAlignment.end'),
          _buildRowDemo(MainAxisAlignment.end),
          const SizedBox(height: 8),
          const _SubTitle('MainAxisAlignment.spaceBetween'),
          _buildRowDemo(MainAxisAlignment.spaceBetween),
          const SizedBox(height: 8),
          const _SubTitle('MainAxisAlignment.spaceAround'),
          _buildRowDemo(MainAxisAlignment.spaceAround),
          const SizedBox(height: 8),
          const _SubTitle('MainAxisAlignment.spaceEvenly'),
          _buildRowDemo(MainAxisAlignment.spaceEvenly),
          const SizedBox(height: 24),

          // === 第二节：Column 和 CrossAxisAlignment ===
          const _SectionTitle('2. Column - CrossAxisAlignment 交叉轴对齐'),
          _buildCrossAxisDemo(),
          const SizedBox(height: 24),

          // === 第三节：MainAxisSize ===
          const _SectionTitle('3. MainAxisSize 主轴尺寸'),
          _buildMainAxisSizeDemo(),
          const SizedBox(height: 24),

          // === 第四节：Flexible 和 Expanded ===
          const _SectionTitle('4. Flexible 和 Expanded'),
          _buildFlexibleExpandedDemo(),
          const SizedBox(height: 24),

          // === 第五节：Spacer ===
          const _SectionTitle('5. Spacer 弹性间距'),
          _buildSpacerDemo(),
          const SizedBox(height: 24),

          // === 第六节：Wrap 标签云 ===
          const _SectionTitle('6. Wrap - 标签云示例'),
          _buildTagCloudDemo(),
          const SizedBox(height: 24),

          // === 第七节：Flow 自定义布局 ===
          const _SectionTitle('7. Flow - 自定义布局'),
          _buildFlowDemo(),
          const SizedBox(height: 24),

          // === 第八节：响应式卡片布局 ===
          const _SectionTitle('8. 响应式卡片布局'),
          _buildResponsiveCardLayout(),
          const SizedBox(height: 24),

          // === 第九节：综合底部操作栏 ===
          const _SectionTitle('9. 综合示例：底部操作栏'),
          _buildBottomActionBar(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== Row 主轴对齐演示 ====================

  /// 构建一个展示 MainAxisAlignment 效果的 Row
  static Widget _buildRowDemo(MainAxisAlignment alignment) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: alignment,
        children: const [
          _ColorBox(color: Colors.red, label: 'A'),
          _ColorBox(color: Colors.green, label: 'B'),
          _ColorBox(color: Colors.blue, label: 'C'),
        ],
      ),
    );
  }

  // ==================== CrossAxisAlignment 演示 ====================

  /// 展示不同高度子组件在交叉轴上的对齐效果
  static Widget _buildCrossAxisDemo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 三个不同高度的容器，演示交叉轴居中对齐
          Container(
            width: 50,
            height: 40,
            color: Colors.red.withValues(alpha: 0.7),
            alignment: Alignment.center,
            child: const Text('矮', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 80,
            color: Colors.green.withValues(alpha: 0.7),
            alignment: Alignment.center,
            child: const Text('中', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 120,
            color: Colors.blue.withValues(alpha: 0.7),
            alignment: Alignment.center,
            child: const Text('高', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'CrossAxisAlignment.center\n三个不同高度的容器在垂直方向居中对齐',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MainAxisSize 演示 ====================

  /// 对比 MainAxisSize.max 和 MainAxisSize.min 的效果
  static Widget _buildMainAxisSizeDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // max：Row 占据所有可用宽度
        const _SubTitle('MainAxisSize.max（默认）'),
        Container(
          color: Colors.amber.withValues(alpha: 0.2),
          child: Row(
            children: const [
              _ColorBox(color: Colors.orange, label: '1'),
              _ColorBox(color: Colors.deepOrange, label: '2'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // min：Row 仅包裹子组件
        const _SubTitle('MainAxisSize.min'),
        Container(
          color: Colors.amber.withValues(alpha: 0.2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ColorBox(color: Colors.orange, label: '1'),
              _ColorBox(color: Colors.deepOrange, label: '2'),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Flexible & Expanded 演示 ====================

  /// 展示 Flexible 和 Expanded 的区别
  static Widget _buildFlexibleExpandedDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expanded 示例：按比例分配空间
        const _SubTitle('Expanded: flex=1 : flex=2 : flex=1'),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                color: Colors.red.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('flex:1', style: TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                height: 50,
                color: Colors.green.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('flex:2', style: TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: Container(
                height: 50,
                color: Colors.blue.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('flex:1', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Flexible（loose）vs Expanded（tight）对比
        const _SubTitle('Flexible(loose) vs Expanded(tight)'),
        Row(
          children: [
            // Flexible：子组件可以小于分配空间
            Flexible(
              child: Container(
                height: 50,
                width: 80, // 实际宽度小于分配空间
                color: Colors.purple.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('Flexible', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 4),
            // Expanded：子组件强制填满分配空间
            Expanded(
              child: Container(
                height: 50,
                color: Colors.teal.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('Expanded（填满）', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 固定 + 弹性混合布局
        const _SubTitle('固定宽度 + Expanded 混合布局'),
        Row(
          children: [
            Container(
              width: 80,
              height: 50,
              color: Colors.indigo.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: const Text('固定80', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.cyan.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: const Text('自动填充', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
            Container(
              width: 80,
              height: 50,
              color: Colors.indigo.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: const Text('固定80', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== Spacer 演示 ====================

  /// 展示 Spacer 的使用场景
  static Widget _buildSpacerDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 场景1：将元素推到两端
        const _SubTitle('Spacer 将元素推到两端'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu),
              const SizedBox(width: 8),
              const Text('标题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(), // 占据中间所有剩余空间
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 场景2：按比例分配间距
        const _SubTitle('Spacer(flex) 按比例分配间距'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.3),
                child: const Text('A'),
              ),
              const Spacer(flex: 2), // 2 份间距
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.green.withValues(alpha: 0.3),
                child: const Text('B'),
              ),
              const Spacer(), // 1 份间距
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.withValues(alpha: 0.3),
                child: const Text('C'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Wrap 标签云演示 ====================

  /// 使用 Wrap 构建标签云
  static Widget _buildTagCloudDemo() {
    // 模拟标签数据
    const tags = [
      'Flutter',
      'Dart',
      '布局系统',
      '响应式设计',
      'Widget',
      '状态管理',
      'Material Design',
      'Cupertino',
      '动画效果',
      '路由导航',
      '网络请求',
      '数据持久化',
      'Provider',
      'Riverpod',
      'Bloc',
      '单元测试',
      '集成测试',
    ];

    // 为标签分配不同颜色
    const tagColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 8.0, // 标签之间的水平间距
        runSpacing: 8.0, // 行与行之间的垂直间距
        alignment: WrapAlignment.start,
        children: List.generate(tags.length, (index) {
          final color = tagColors[index % tagColors.length];
          return Chip(
            label: Text(
              tags[index],
              style: TextStyle(color: color, fontSize: 13),
            ),
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        }),
      ),
    );
  }

  // ==================== Flow 自定义布局演示 ====================

  /// 使用 Flow + FlowDelegate 实现自定义排列布局
  static Widget _buildFlowDemo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Flow(
        delegate: const _TagFlowDelegate(spacing: 8),
        children: List.generate(12, (index) {
          // 生成不同宽度的标签来演示 Flow 的自动换行效果
          final labels = [
            'Flutter',
            'Dart 语言',
            '自定义布局',
            'Flow',
            'Widget',
            '高性能',
            'FlowDelegate',
            '动画',
            'Material',
            '变换矩阵',
            'GPU 加速',
            '响应式',
          ];
          final colors = [
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.teal,
            Colors.pink,
            Colors.indigo,
            Colors.cyan,
            Colors.amber,
            Colors.deepOrange,
            Colors.lightBlue,
          ];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors[index].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[index].withValues(alpha: 0.4)),
            ),
            child: Text(
              labels[index],
              style: TextStyle(color: colors[index], fontSize: 13),
            ),
          );
        }),
      ),
    );
  }

  // ==================== 响应式卡片布局 ====================

  /// 使用 LayoutBuilder + Wrap 实现响应式卡片布局
  static Widget _buildResponsiveCardLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度动态计算列数
        final availableWidth = constraints.maxWidth;
        int crossAxisCount;
        if (availableWidth >= 600) {
          crossAxisCount = 4;
        } else if (availableWidth >= 400) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // 计算每张卡片的宽度（考虑间距）
        const spacingValue = 10.0;
        final cardWidth =
            (availableWidth - (crossAxisCount - 1) * spacingValue) /
            crossAxisCount;

        // 模拟卡片数据
        final cardData = [
          _CardInfo(Icons.photo, '照片', Colors.blue),
          _CardInfo(Icons.music_note, '音乐', Colors.green),
          _CardInfo(Icons.video_library, '视频', Colors.red),
          _CardInfo(Icons.article, '文档', Colors.orange),
          _CardInfo(Icons.folder, '文件夹', Colors.purple),
          _CardInfo(Icons.cloud, '云存储', Colors.cyan),
          _CardInfo(Icons.settings, '设置', Colors.grey),
          _CardInfo(Icons.favorite, '收藏', Colors.pink),
        ];

        return Wrap(
          spacing: spacingValue,
          runSpacing: spacingValue,
          children: cardData.map((data) {
            return SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.icon, size: 36, color: data.color),
                      const SizedBox(height: 8),
                      Text(
                        data.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== 底部操作栏 ====================

  /// 综合示例：仿电商底部操作栏
  static Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：价格信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '合计',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withValues(alpha: 0.8),
                ),
              ),
              const Text(
                '¥ 299.00',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const Spacer(), // 弹性空间将左侧和右侧分开
          // 右侧：操作按钮
          OutlinedButton(
            onPressed: () {},
            child: const Text('加入购物车'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {},
            child: const Text('立即购买'),
          ),
        ],
      ),
    );
  }
}

// ==================== 辅助组件 ====================

/// 章节标题
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// 子标题
class _SubTitle extends StatelessWidget {
  final String title;
  const _SubTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// 彩色方块（用于演示布局效果）
class _ColorBox extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 卡片信息数据类
class _CardInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _CardInfo(this.icon, this.label, this.color);
}

// ==================== Flow 自定义委托 ====================

/// 自定义 FlowDelegate，实现自动换行的标签布局
/// Flow 的优势在于只需要重新绘制（paint），跳过测量和布局阶段，性能更高
class _TagFlowDelegate extends FlowDelegate {
  final double spacing;

  const _TagFlowDelegate({required this.spacing});

  @override
  void paintChildren(FlowPaintingContext context) {
    double dx = 0; // 当前绘制的 x 坐标
    double dy = 0; // 当前绘制的 y 坐标
    double rowHeight = 0; // 当前行的最大高度

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i);
      if (childSize == null) continue;

      // 如果当前行剩余空间不足以放下该子组件，则换行
      if (dx + childSize.width > context.size.width && dx > 0) {
        dx = 0;
        dy += rowHeight + spacing;
        rowHeight = 0;
      }

      // 使用变换矩阵将子组件绘制到指定位置
      context.paintChild(
        i,
        transform: Matrix4.translationValues(dx, dy, 0),
      );

      // 更新坐标
      dx += childSize.width + spacing;
      if (childSize.height > rowHeight) {
        rowHeight = childSize.height;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TagFlowDelegate oldDelegate) => false;
}
