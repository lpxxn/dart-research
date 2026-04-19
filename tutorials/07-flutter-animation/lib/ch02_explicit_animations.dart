import 'dart:math';
import 'package:flutter/material.dart';

/// 第2章：显式动画示例
/// 展示 AnimationController、Tween、CurvedAnimation、
/// AnimatedBuilder、AnimatedWidget 以及内置 Transition 组件的用法。

void main() => runApp(const Ch02App());

class Ch02App extends StatelessWidget {
  const Ch02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第2章：显式动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const ExplicitAnimationsDemo(),
    );
  }
}

class ExplicitAnimationsDemo extends StatefulWidget {
  const ExplicitAnimationsDemo({super.key});

  @override
  State<ExplicitAnimationsDemo> createState() =>
      _ExplicitAnimationsDemoState();
}

class _ExplicitAnimationsDemoState extends State<ExplicitAnimationsDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第2章：显式动画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('1. AnimatedBuilder + 旋转'),
          _RotationDemo(),
          Divider(height: 32),
          _SectionTitle('2. Tween + CurvedAnimation'),
          _TweenCurveDemo(),
          Divider(height: 32),
          _SectionTitle('3. AnimatedWidget 自定义封装'),
          _AnimatedWidgetDemo(),
          Divider(height: 32),
          _SectionTitle('4. 内置 Transition 组件'),
          _BuiltInTransitionsDemo(),
          Divider(height: 32),
          _SectionTitle('5. 动画状态控制'),
          _AnimationControlDemo(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ============================================================
// 1. AnimatedBuilder + 旋转动画
// 使用 AnimationController 驱动，AnimatedBuilder 构建 UI
// ============================================================
class _RotationDemo extends StatefulWidget {
  const _RotationDemo();

  @override
  State<_RotationDemo> createState() => _RotationDemoState();
}

class _RotationDemoState extends State<_RotationDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // AnimationController 是显式动画的核心
    // vsync: this 依赖 SingleTickerProviderStateMixin，确保与屏幕刷新同步
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // 必须释放 controller，否则会内存泄漏
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_isPlaying) {
        _controller.stop();
      } else {
        _controller.repeat(); // 无限循环
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedBuilder 监听 _controller，每帧重建 builder 部分
        // child 参数传入不变的子树，避免每帧重建，提升性能
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * pi, // 0~1 映射到 0~2π
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.settings, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _toggle,
          child: Text(_isPlaying ? '停止' : '开始旋转'),
        ),
      ],
    );
  }
}

// ============================================================
// 2. Tween + CurvedAnimation
// 展示如何将 controller 的 0~1 值映射到自定义范围，并应用曲线
// ============================================================
class _TweenCurveDemo extends StatefulWidget {
  const _TweenCurveDemo();

  @override
  State<_TweenCurveDemo> createState() => _TweenCurveDemoState();
}

class _TweenCurveDemoState extends State<_TweenCurveDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _borderRadiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Tween 将 0~1 映射到 60~200
    // CurvedAnimation 为动画添加缓动曲线
    _sizeAnimation = Tween<double>(begin: 60, end: 200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _colorAnimation = ColorTween(
      begin: Colors.amber,
      end: Colors.deepPurple,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _borderRadiusAnimation = Tween<double>(begin: 8, end: 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    // 根据状态决定正向或反向播放
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: _sizeAnimation.value,
              height: _sizeAnimation.value,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius:
                    BorderRadius.circular(_borderRadiusAnimation.value),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Tween',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _toggle, child: const Text('切换')),
      ],
    );
  }
}

// ============================================================
// 3. AnimatedWidget 自定义封装
// 将动画逻辑封装到独立的 Widget 类中，便于复用
// ============================================================

/// 自定义的 AnimatedWidget：脉冲缩放图标
class _PulsingIcon extends AnimatedWidget {
  final IconData icon;

  const _PulsingIcon({
    required Animation<double> animation,
    required this.icon,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    // 在 0.8~1.2 之间缩放，产生脉冲效果
    final scale = 0.8 + animation.value * 0.4;
    return Transform.scale(
      scale: scale,
      child: Icon(icon, size: 60, color: Colors.red),
    );
  }
}

class _AnimatedWidgetDemo extends StatefulWidget {
  const _AnimatedWidgetDemo();

  @override
  State<_AnimatedWidgetDemo> createState() => _AnimatedWidgetDemoState();
}

class _AnimatedWidgetDemoState extends State<_AnimatedWidgetDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true); // 来回循环
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 使用自定义 AnimatedWidget
        _PulsingIcon(animation: _controller, icon: Icons.favorite),
        const SizedBox(height: 8),
        const Text('AnimatedWidget 封装的脉冲心跳效果'),
      ],
    );
  }
}

// ============================================================
// 4. 内置 Transition 组件
// Flutter 提供了 FadeTransition、ScaleTransition、RotationTransition 等
// ============================================================
class _BuiltInTransitionsDemo extends StatefulWidget {
  const _BuiltInTransitionsDemo();

  @override
  State<_BuiltInTransitionsDemo> createState() =>
      _BuiltInTransitionsDemoState();
}

class _BuiltInTransitionsDemoState extends State<_BuiltInTransitionsDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // SlideTransition 需要 Animation<Offset>
    // Offset(1, 0) 表示向右偏移一个自身宽度
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
    return Column(
      children: [
        // FadeTransition：淡入淡出
        FadeTransition(
          opacity: _controller,
          child: const Chip(label: Text('FadeTransition')),
        ),
        const SizedBox(height: 8),
        // ScaleTransition：缩放
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
          child: const Chip(label: Text('ScaleTransition')),
        ),
        const SizedBox(height: 8),
        // RotationTransition：旋转（turns 参数，1.0 = 一圈）
        RotationTransition(
          turns: _controller,
          child: const Chip(label: Text('RotationTransition')),
        ),
        const SizedBox(height: 8),
        // SlideTransition：滑动
        SlideTransition(
          position: _slideAnimation,
          child: const Chip(label: Text('SlideTransition')),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _play, child: const Text('播放全部')),
      ],
    );
  }
}

// ============================================================
// 5. 动画状态控制
// 展示 forward、reverse、repeat、stop 等控制方法
// ============================================================
class _AnimationControlDemo extends StatefulWidget {
  const _AnimationControlDemo();

  @override
  State<_AnimationControlDemo> createState() => _AnimationControlDemoState();
}

class _AnimationControlDemoState extends State<_AnimationControlDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _statusText = '初始';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 300).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 监听动画状态变化
    _controller.addStatusListener((status) {
      setState(() {
        switch (status) {
          case AnimationStatus.dismissed:
            _statusText = '起点 (dismissed)';
          case AnimationStatus.forward:
            _statusText = '正向播放中 (forward)';
          case AnimationStatus.reverse:
            _statusText = '反向播放中 (reverse)';
          case AnimationStatus.completed:
            _statusText = '终点 (completed)';
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 用动画值控制水平偏移
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 60,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(_animation.value, 0),
                child: child,
              ),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('状态: $_statusText'),
        Text('进度: ${(_controller.value * 100).toStringAsFixed(0)}%'),
        const SizedBox(height: 12),
        // 控制按钮
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => _controller.forward(),
              child: const Text('正向'),
            ),
            FilledButton(
              onPressed: () => _controller.reverse(),
              child: const Text('反向'),
            ),
            FilledButton(
              onPressed: () => _controller.repeat(reverse: true),
              child: const Text('循环'),
            ),
            FilledButton(
              onPressed: () => _controller.stop(),
              child: const Text('停止'),
            ),
            FilledButton(
              onPressed: () => _controller.reset(),
              child: const Text('重置'),
            ),
          ],
        ),
      ],
    );
  }
}
