import 'package:flutter/material.dart';

/// 第四章：层叠布局（Stack Layout）综合示例
void main() => runApp(const StackLayoutApp());

class StackLayoutApp extends StatelessWidget {
  const StackLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '层叠布局演示',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const StackLayoutHomePage(),
    );
  }
}

/// 主页面：使用 ListView 组织各个示例区块
class StackLayoutHomePage extends StatelessWidget {
  const StackLayoutHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第四章：层叠布局'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // 第一节：Stack alignment 演示
          _SectionTitle(title: '1. Stack alignment 演示'),
          SizedBox(height: 8),
          _StackAlignmentDemo(),
          SizedBox(height: 24),

          // 第二节：Stack fit 演示
          _SectionTitle(title: '2. Stack fit 演示'),
          SizedBox(height: 8),
          _StackFitDemo(),
          SizedBox(height: 24),

          // 第三节：Positioned 定位演示
          _SectionTitle(title: '3. Positioned 定位演示'),
          SizedBox(height: 8),
          _PositionedDemo(),
          SizedBox(height: 24),

          // 第四节：clipBehavior 演示
          _SectionTitle(title: '4. clipBehavior 对比'),
          SizedBox(height: 8),
          _ClipBehaviorDemo(),
          SizedBox(height: 24),

          // 第五节：IndexedStack 演示
          _SectionTitle(title: '5. IndexedStack 切换'),
          SizedBox(height: 8),
          _IndexedStackDemo(),
          SizedBox(height: 24),

          // 第六节：角标 Badge 实战
          _SectionTitle(title: '6. 实战：角标 Badge'),
          SizedBox(height: 8),
          _BadgeDemo(),
          SizedBox(height: 24),

          // 第七节：图片叠加文字
          _SectionTitle(title: '7. 实战：图片叠加文字'),
          SizedBox(height: 8),
          _ImageOverlayDemo(),
          SizedBox(height: 24),

          // 第八节：头像 + 在线状态
          _SectionTitle(title: '8. 实战：头像 + 在线状态'),
          SizedBox(height: 8),
          _AvatarStatusDemo(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 区块标题组件
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Stack alignment 演示
// ---------------------------------------------------------------------------

class _StackAlignmentDemo extends StatelessWidget {
  const _StackAlignmentDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        // 未定位子组件居中对齐
        alignment: Alignment.center,
        children: [
          // 最底层：蓝色大方块
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('底层 (180×180)', style: TextStyle(fontSize: 12)),
          ),
          // 中间层：绿色中方块（受 alignment 影响，居中）
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('中层 (120×120)', style: TextStyle(fontSize: 12)),
          ),
          // 最上层：红色小方块（受 alignment 影响，居中）
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('顶层', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Stack fit 演示
// ---------------------------------------------------------------------------

class _StackFitDemo extends StatelessWidget {
  const _StackFitDemo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // StackFit.loose：子组件保持自身大小
          Expanded(
            child: Column(
              children: [
                const Text('loose', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Stack(
                      fit: StackFit.loose,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          color: Colors.orange.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // StackFit.expand：子组件撑满 Stack
          Expanded(
            child: Column(
              children: [
                const Text('expand', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          // expand 模式下会忽略 width/height，撑满整个区域
                          color: Colors.purple.withValues(alpha: 0.4),
                          alignment: Alignment.center,
                          child: const Text(
                            '撑满',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // StackFit.passthrough：透传父约束
          Expanded(
            child: Column(
              children: [
                const Text('passthrough', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          color: Colors.teal.withValues(alpha: 0.4),
                          alignment: Alignment.center,
                          child: const Text(
                            '透传',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// 3. Positioned 定位演示
// ---------------------------------------------------------------------------

class _PositionedDemo extends StatelessWidget {
  const _PositionedDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      child: Stack(
        children: [
          // 左上角定位
          const Positioned(
            left: 8,
            top: 8,
            child: _PositionLabel(text: '左上', color: Colors.red),
          ),
          // 右上角定位
          const Positioned(
            right: 8,
            top: 8,
            child: _PositionLabel(text: '右上', color: Colors.blue),
          ),
          // 左下角定位
          const Positioned(
            left: 8,
            bottom: 8,
            child: _PositionLabel(text: '左下', color: Colors.green),
          ),
          // 右下角定位
          const Positioned(
            right: 8,
            bottom: 8,
            child: _PositionLabel(text: '右下', color: Colors.orange),
          ),
          // 使用 left + right 实现自适应宽度的横幅
          Positioned(
            left: 60,
            right: 60,
            top: 85,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Text(
                'left + right 自适应宽度',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 定位标签小组件
class _PositionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _PositionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. clipBehavior 对比演示
// ---------------------------------------------------------------------------

class _ClipBehaviorDemo extends StatelessWidget {
  const _ClipBehaviorDemo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Clip.hardEdge：裁剪溢出部分（默认）
          _buildClipExample('hardEdge (裁剪)', Clip.hardEdge),
          const SizedBox(width: 32),
          // Clip.none：不裁剪，允许溢出
          _buildClipExample('none (不裁剪)', Clip.none),
        ],
      ),
    );
  }

  Widget _buildClipExample(String label, Clip clip) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: Stack(
            clipBehavior: clip,
            children: [
              Container(
                width: 80,
                height: 60,
                color: Colors.blue.withValues(alpha: 0.4),
              ),
              // 这个红色方块会溢出 Stack 的右下角
              Positioned(
                right: -20,
                bottom: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '溢出',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. IndexedStack 演示（StatefulWidget，支持按钮切换）
// ---------------------------------------------------------------------------

class _IndexedStackDemo extends StatefulWidget {
  const _IndexedStackDemo();

  @override
  State<_IndexedStackDemo> createState() => _IndexedStackDemoState();
}

class _IndexedStackDemoState extends State<_IndexedStackDemo> {
  int _currentIndex = 0;

  // 三个页面的配置
  static const List<_PageConfig> _pages = [
    _PageConfig(icon: Icons.looks_one, label: '页面 A', color: Colors.blue),
    _PageConfig(icon: Icons.looks_two, label: '页面 B', color: Colors.green),
    _PageConfig(icon: Icons.looks_3, label: '页面 C', color: Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 切换按钮行
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_pages.length, (index) {
                final isActive = _currentIndex == index;
                return FilledButton.tonal(
                  onPressed: () => setState(() => _currentIndex = index),
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive
                        ? _pages[index].color.withValues(alpha: 0.2)
                        : null,
                  ),
                  child: Text(
                    _pages[index].label,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
          ),
          // IndexedStack 显示当前选中的页面
          SizedBox(
            height: 120,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages
                  .map((page) => _IndexedStackPage(config: page))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 页面配置数据
class _PageConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _PageConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// IndexedStack 的子页面
class _IndexedStackPage extends StatefulWidget {
  final _PageConfig config;

  const _IndexedStackPage({required this.config});

  @override
  State<_IndexedStackPage> createState() => _IndexedStackPageState();
}

class _IndexedStackPageState extends State<_IndexedStackPage> {
  // 用计数器来演示状态保持（切换后计数不会重置）
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _tapCount++),
      child: Container(
        color: widget.config.color.withValues(alpha: 0.1),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.config.icon, size: 36, color: widget.config.color),
              const SizedBox(height: 4),
              Text(
                widget.config.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.config.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击次数: $_tapCount（状态被保持）',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. 角标 Badge 演示
// ---------------------------------------------------------------------------

class _BadgeDemo extends StatelessWidget {
  const _BadgeDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 带数字角标的消息图标
          _buildBadgeIcon(Icons.mail_outline, 5),
          // 超过 99 显示 99+
          _buildBadgeIcon(Icons.notifications_none, 128),
          // 红点角标（数量为 0 时不显示数字）
          _buildRedDotBadge(Icons.shopping_cart_outlined),
          // 无角标
          _buildBadgeIcon(Icons.person_outline, 0),
        ],
      ),
    );
  }

  /// 带数字角标的图标
  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none, // 允许角标溢出
      children: [
        Icon(icon, size: 32, color: Colors.grey.shade700),
        if (count > 0)
          Positioned(
            right: -10,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 红点角标（无数字）
  Widget _buildRedDotBadge(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 32, color: Colors.grey.shade700),
        Positioned(
          right: -3,
          top: -3,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. 图片叠加文字演示
// ---------------------------------------------------------------------------

class _ImageOverlayDemo extends StatelessWidget {
  const _ImageOverlayDemo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 底层：使用渐变色模拟图片背景
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // 模拟图片上的装饰元素
              child: CustomPaint(painter: _CirclePatternPainter()),
            ),
            // 中层：底部渐变遮罩，让文字更清晰
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // 上层左上：分类标签
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '精选',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            // 上层右上：收藏按钮
            const Positioned(
              right: 12,
              top: 12,
              child: Icon(Icons.favorite_border, color: Colors.white, size: 24),
            ),
            // 上层底部：标题和描述文字
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Flutter 层叠布局实战',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '使用 Stack 和 Positioned 实现精美的卡片叠加效果',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 装饰性圆形图案画笔（模拟图片背景上的视觉元素）
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // 绘制几个装饰性圆形
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 8. 头像 + 在线状态演示
// ---------------------------------------------------------------------------

class _AvatarStatusDemo extends StatelessWidget {
  const _AvatarStatusDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 在线用户
          _AvatarWithStatus(
            name: '张三',
            color: Colors.blue,
            isOnline: true,
          ),
          // 离线用户
          _AvatarWithStatus(
            name: '李四',
            color: Colors.purple,
            isOnline: false,
          ),
          // 在线用户
          _AvatarWithStatus(
            name: '王五',
            color: Colors.teal,
            isOnline: true,
          ),
          // 离线用户
          _AvatarWithStatus(
            name: '赵六',
            color: Colors.deepOrange,
            isOnline: false,
          ),
        ],
      ),
    );
  }
}

/// 带在线状态指示器的头像组件
class _AvatarWithStatus extends StatelessWidget {
  final String name;
  final Color color;
  final bool isOnline;

  const _AvatarWithStatus({
    required this.name,
    required this.color,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头像 + 状态指示器的层叠
        Stack(
          children: [
            // 底层：头像
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Text(
                name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 上层：在线状态指示器（右下角）
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  // 白色边框让指示器在头像上更加突出
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 用户名
        Text(name, style: const TextStyle(fontSize: 12)),
        // 在线状态文字
        Text(
          isOnline ? '在线' : '离线',
          style: TextStyle(
            fontSize: 10,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}
