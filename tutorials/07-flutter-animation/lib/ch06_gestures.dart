import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 第6章：手势系统
/// 演示内容：
/// 1. 可拖拽排序列表（LongPressDraggable + DragTarget）
/// 2. 双指缩放图片（InteractiveViewer）
/// 3. Dismissible 滑动删除

void main() => runApp(const Ch06GesturesApp());

class Ch06GesturesApp extends StatelessWidget {
  const Ch06GesturesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第6章：手势系统',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const GestureHomePage(),
    );
  }
}

// ==================== 手势系统首页 ====================

class GestureHomePage extends StatelessWidget {
  const GestureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第6章：手势系统')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoCard(
            title: '可拖拽排序列表',
            subtitle: 'LongPressDraggable + DragTarget',
            icon: Icons.drag_indicator,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DraggableSortListPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            title: '双指缩放图片',
            subtitle: 'InteractiveViewer 缩放与平移',
            icon: Icons.zoom_in,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PinchZoomPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DemoCard(
            title: '滑动删除列表',
            subtitle: 'Dismissible 组件',
            icon: Icons.swipe,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DismissibleListPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ==================== 可拖拽排序列表 ====================

class DraggableSortListPage extends StatefulWidget {
  const DraggableSortListPage({super.key});

  @override
  State<DraggableSortListPage> createState() => _DraggableSortListPageState();
}

class _DraggableSortListPageState extends State<DraggableSortListPage> {
  // 待排序的数据列表
  final List<_FruitItem> _items = [
    _FruitItem('🍎', '苹果', Colors.red),
    _FruitItem('🍊', '橙子', Colors.orange),
    _FruitItem('🍋', '柠檬', Colors.yellow),
    _FruitItem('🍇', '葡萄', Colors.purple),
    _FruitItem('🍉', '西瓜', Colors.green),
    _FruitItem('🍓', '草莓', Colors.pinkAccent),
    _FruitItem('🫐', '蓝莓', Colors.blueAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('可拖拽排序列表')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '长按项目即可拖拽排序',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildDraggableItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(int index) {
    final item = _items[index];

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        setState(() {
          // 将拖拽项从原位置移除并插入到目标位置
          final draggedItem = _items.removeAt(details.data);
          _items.insert(index, draggedItem);
        });
        HapticFeedback.lightImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;

        return LongPressDraggable<int>(
          data: index,
          // 拖拽时跟随手指的外观
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: _FruitTile(
                item: item,
                isHighlighted: true,
              ),
            ),
          ),
          // 拖拽时原位置变为半透明占位
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _FruitTile(item: item),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(vertical: isTargeted ? 8 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isTargeted
                  ? Border.all(color: Colors.indigo, width: 2)
                  : null,
            ),
            child: _FruitTile(item: item),
          ),
        );
      },
    );
  }
}

class _FruitItem {
  final String emoji;
  final String name;
  final Color color;

  _FruitItem(this.emoji, this.name, this.color);
}

class _FruitTile extends StatelessWidget {
  final _FruitItem item;
  final bool isHighlighted;

  const _FruitTile({required this.item, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHighlighted ? 8 : 1,
      color: isHighlighted
          ? item.color.withValues(alpha: 0.2)
          : null,
      child: ListTile(
        leading: Text(item.emoji, style: const TextStyle(fontSize: 32)),
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
      ),
    );
  }
}

// ==================== 双指缩放图片 ====================

class PinchZoomPage extends StatefulWidget {
  const PinchZoomPage({super.key});

  @override
  State<PinchZoomPage> createState() => _PinchZoomPageState();
}

class _PinchZoomPageState extends State<PinchZoomPage> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// 重置缩放状态
  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('双指缩放图片'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置缩放',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '使用双指缩放和平移下方图片',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(60),
              child: Center(
                child: _SampleImage(),
              ),
            ),
          ),
          // 显示当前缩放信息
          ListenableBuilder(
            listenable: _transformController,
            builder: (context, child) {
              final scale =
                  _transformController.value.getMaxScaleOnAxis();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '当前缩放: ${scale.toStringAsFixed(2)}x',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 用 CustomPaint 绘制一张示例图片（不依赖外部资源）
class _SampleImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 300),
      painter: _SampleImagePainter(),
    );
  }
}

class _SampleImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ),
      bgPaint,
    );

    // 绘制装饰圆形
    final circlePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      60,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.6),
      80,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      40,
      circlePaint,
    );

    // 绘制文字
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🏔️ 双指缩放',
        style: TextStyle(fontSize: 28, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== 滑动删除列表 ====================

class DismissibleListPage extends StatefulWidget {
  const DismissibleListPage({super.key});

  @override
  State<DismissibleListPage> createState() => _DismissibleListPageState();
}

class _DismissibleListPageState extends State<DismissibleListPage> {
  final List<String> _items = List.generate(
    15,
    (index) => '列表项 ${index + 1}',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('滑动删除列表')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '向左滑动删除，向右滑动归档',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      '所有项目已清空 🎉',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: ValueKey(item),
                        // 向右滑 → 归档（绿色背景）
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child:
                              const Icon(Icons.archive, color: Colors.white),
                        ),
                        // 向左滑 → 删除（红色背景）
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // 向左滑：弹出确认对话框
                            return await _showDeleteConfirmDialog(
                                context, item);
                          }
                          // 向右滑：直接归档
                          return true;
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _items.removeAt(index);
                          });
                          final action = direction ==
                                  DismissDirection.endToStart
                              ? '删除'
                              : '归档';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$item 已$action'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(item),
                            subtitle: const Text('左滑删除 · 右滑归档'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(
      BuildContext context, String item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "$item" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
