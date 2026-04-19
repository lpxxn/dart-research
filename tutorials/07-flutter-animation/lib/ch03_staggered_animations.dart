import 'package:flutter/material.dart';

/// 第3章：交错动画示例
/// 展示 Interval 的用法、一个 Controller 驱动多个动画、
/// 列表项依次飞入、卡片展开动画。

void main() => runApp(const Ch03App());

class Ch03App extends StatelessWidget {
  const Ch03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第3章：交错动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const StaggeredAnimationsDemo(),
    );
  }
}

class StaggeredAnimationsDemo extends StatefulWidget {
  const StaggeredAnimationsDemo({super.key});

  @override
  State<StaggeredAnimationsDemo> createState() =>
      _StaggeredAnimationsDemoState();
}

class _StaggeredAnimationsDemoState extends State<StaggeredAnimationsDemo> {
  int _selectedIndex = 0;

  final _pages = const <Widget>[
    _StaggeredPropertyDemo(),
    _StaggeredListDemo(),
    _CardExpandDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第3章：交错动画')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.animation), label: '多属性'),
          NavigationDestination(icon: Icon(Icons.list), label: '列表飞入'),
          NavigationDestination(icon: Icon(Icons.credit_card), label: '卡片展开'),
        ],
      ),
    );
  }
}

// ============================================================
// 页面1：交错多属性动画
// 一个 Controller 驱动透明度、宽度、颜色、圆角四个动画
// 每个动画占据不同的时间片段（Interval）
// ============================================================
class _StaggeredPropertyDemo extends StatefulWidget {
  const _StaggeredPropertyDemo();

  @override
  State<_StaggeredPropertyDemo> createState() =>
      _StaggeredPropertyDemoState();
}

class _StaggeredPropertyDemoState extends State<_StaggeredPropertyDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 四个独立的动画，分别在不同时间段执行
  late Animation<double> _opacity;
  late Animation<double> _width;
  late Animation<Color?> _color;
  late Animation<double> _borderRadius;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 0%~30%：透明度从 0 → 1
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 20%~60%：宽度从 60 → 300
    _width = Tween<double>(begin: 60, end: 300).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // 50%~80%：颜色从蓝 → 橙
    _color = ColorTween(begin: Colors.blue, end: Colors.deepOrange).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8),
      ),
    );

    // 70%~100%：圆角从 4 → 60（带弹跳效果）
    _borderRadius = Tween<double>(begin: 4, end: 60).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 时间线示意
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('时间线:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('0%~30%  → 透明度'),
                Text('20%~60% → 宽度'),
                Text('50%~80% → 颜色'),
                Text('70%~100% → 圆角'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 用 AnimatedBuilder 监听 controller，统一重建
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: _width.value,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _color.value,
                    borderRadius:
                        BorderRadius.circular(_borderRadius.value),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '交错动画',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _play,
            icon: const Icon(Icons.play_arrow),
            label: const Text('播放'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 页面2：列表项依次飞入
// 每个列表项占据不同的 Interval，产生依次飞入效果
// ============================================================
class _StaggeredListDemo extends StatefulWidget {
  const _StaggeredListDemo();

  @override
  State<_StaggeredListDemo> createState() => _StaggeredListDemoState();
}

class _StaggeredListDemoState extends State<_StaggeredListDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const _itemCount = 8;

  // 每个列表项有自己的滑入和淡入动画
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // 为每个列表项创建错开的动画
    for (int i = 0; i < _itemCount; i++) {
      // 每项间隔 0.1，持续 0.4
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);

      // 从右侧飞入
      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0), // 右侧偏移一个自身宽度
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        )),
      );

      // 同时淡入
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end),
        )),
      );
    }

    // 页面打开时自动播放
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _itemCount,
            itemBuilder: (context, index) {
              return SlideTransition(
                position: _slideAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.primaries[index % Colors.primaries.length],
                        child: Text('${index + 1}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('列表项 ${index + 1}'),
                      subtitle: Text('依次从右侧飞入，间隔 ${(index * 100)}ms'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _replay,
            icon: const Icon(Icons.replay),
            label: const Text('重新播放'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 页面3：卡片展开动画
// 点击卡片后，高度、标题、内容、按钮依次动画
// ============================================================
class _CardExpandDemo extends StatefulWidget {
  const _CardExpandDemo();

  @override
  State<_CardExpandDemo> createState() => _CardExpandDemoState();
}

class _CardExpandDemoState extends State<_CardExpandDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _heightAnimation;
  late Animation<double> _titleSizeAnimation;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonOpacity;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 阶段1 (0%~35%)：卡片高度增加
    _heightAnimation = Tween<double>(begin: 80, end: 260).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 阶段2 (20%~50%)：标题变大
    _titleSizeAnimation = Tween<double>(begin: 16, end: 24).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // 阶段3 (40%~70%)：内容淡入
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7),
      ),
    );

    // 阶段4 (65%~100%)：按钮滑入并淡入
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    ));

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.9),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                width: double.infinity,
                height: _heightAnimation.value,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题：大小随动画变化
                    Row(
                      children: [
                        const Icon(Icons.article, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Text(
                          '交错动画卡片',
                          style: TextStyle(
                            fontSize: _titleSizeAnimation.value,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                    // 内容：淡入
                    if (_contentOpacity.value > 0) ...[
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _contentOpacity.value,
                        child: const Text(
                          '这是卡片的详细内容。通过交错动画，高度、标题、'
                          '内容和按钮依次出现，营造了流畅的展开效果。\n\n'
                          '每个阶段使用不同的 Interval，'
                          '但都由同一个 AnimationController 驱动。',
                          style: TextStyle(
                              color: Colors.black54, height: 1.5),
                        ),
                      ),
                    ],
                    // 按钮：滑入
                    if (_buttonOpacity.value > 0) ...[
                      const Spacer(),
                      SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('了解更多'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () {},
                                child: const Text('开始'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
