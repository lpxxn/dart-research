import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// 第5章：物理动画示例
/// 展示 SpringSimulation/SpringDescription、animateWith、
/// 拖拽释放弹回效果、不同弹簧参数的对比。

void main() => runApp(const Ch05App());

class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第5章：物理动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const PhysicsAnimationsDemo(),
    );
  }
}

class PhysicsAnimationsDemo extends StatefulWidget {
  const PhysicsAnimationsDemo({super.key});

  @override
  State<PhysicsAnimationsDemo> createState() => _PhysicsAnimationsDemoState();
}

class _PhysicsAnimationsDemoState extends State<PhysicsAnimationsDemo> {
  int _selectedIndex = 0;

  final _pages = const <Widget>[
    _DragSpringDemo(),
    _SpringComparisonDemo(),
    _SpringTunerDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第5章：物理动画')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.touch_app), label: '拖拽弹回'),
          NavigationDestination(icon: Icon(Icons.compare), label: '参数对比'),
          NavigationDestination(icon: Icon(Icons.tune), label: '参数调节'),
        ],
      ),
    );
  }
}

// ============================================================
// 页面1：拖拽释放弹回
// 用户拖拽圆球，松手后弹簧动画将其弹回原位
// ============================================================
class _DragSpringDemo extends StatefulWidget {
  const _DragSpringDemo();

  @override
  State<_DragSpringDemo> createState() => _DragSpringDemoState();
}

class _DragSpringDemoState extends State<_DragSpringDemo>
    with TickerProviderStateMixin {
  // 两个 Controller 分别控制 x 和 y 方向的弹回动画
  late AnimationController _xController;
  late AnimationController _yController;

  // 当前拖拽偏移量
  double _dx = 0;
  double _dy = 0;

  @override
  void initState() {
    super.initState();
    // unbounded：物理模拟的值可能超出 0~1 范围（弹簧过冲）
    _xController = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dx = _xController.value));
    _yController = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _dy = _yController.value));
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  /// 拖拽开始时停止正在进行的弹簧动画
  void _onPanStart(DragStartDetails details) {
    _xController.stop();
    _yController.stop();
  }

  /// 拖拽过程中直接更新偏移量（跟随手指）
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dx += details.delta.dx;
      _dy += details.delta.dy;
    });
  }

  /// 松手时启动弹簧动画弹回原位
  void _onPanEnd(DragEndDetails details) {
    // 获取手指释放时的速度
    final velocity = details.velocity.pixelsPerSecond;

    // 定义弹簧参数
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 300.0,
      damping: 18.0, // 适度阻尼，会有几次振荡
    );

    // x 方向弹簧：从当前位置弹回 0，初始速度为手指速度
    final xSim = SpringSimulation(spring, _dx, 0, velocity.dx);
    _xController.animateWith(xSim);

    // y 方向弹簧
    final ySim = SpringSimulation(spring, _dy, 0, velocity.dy);
    _yController.animateWith(ySim);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '拖拽下方圆球，松手后弹回',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '偏移: (${_dx.toStringAsFixed(0)}, ${_dy.toStringAsFixed(0)})',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          // 可拖拽的圆球
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: Offset(_dx, _dy),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: Offset(_dx * 0.05, _dy * 0.05 + 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.open_with, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 60),
          // 原位标记
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          const Text('原位', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================================
// 页面2：不同弹簧参数对比
// 同时展示三种弹簧效果，帮助理解参数含义
// ============================================================
class _SpringComparisonDemo extends StatefulWidget {
  const _SpringComparisonDemo();

  @override
  State<_SpringComparisonDemo> createState() => _SpringComparisonDemoState();
}

class _SpringComparisonDemoState extends State<_SpringComparisonDemo>
    with TickerProviderStateMixin {
  late AnimationController _softController;
  late AnimationController _normalController;
  late AnimationController _stiffController;

  @override
  void initState() {
    super.initState();
    _softController = AnimationController.unbounded(vsync: this);
    _normalController = AnimationController.unbounded(vsync: this);
    _stiffController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _softController.dispose();
    _normalController.dispose();
    _stiffController.dispose();
    super.dispose();
  }

  void _play() {
    // 柔软弹簧：低刚度、低阻尼 → 慢速、多振荡
    const softSpring = SpringDescription(
      mass: 1.0,
      stiffness: 80.0,
      damping: 5.0,
    );
    _softController.animateWith(
      SpringSimulation(softSpring, 0.0, 1.0, 0.0),
    );

    // 普通弹簧：中等参数
    const normalSpring = SpringDescription(
      mass: 1.0,
      stiffness: 200.0,
      damping: 15.0,
    );
    _normalController.animateWith(
      SpringSimulation(normalSpring, 0.0, 1.0, 0.0),
    );

    // 硬弹簧：高刚度、高阻尼 → 快速、少振荡
    const stiffSpring = SpringDescription(
      mass: 1.0,
      stiffness: 500.0,
      damping: 30.0,
    );
    _stiffController.animateWith(
      SpringSimulation(stiffSpring, 0.0, 1.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '三种弹簧参数对比',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击按钮观察不同弹簧参数的效果差异',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // 柔软弹簧
          _SpringBar(
            controller: _softController,
            label: '柔软 (s:80, d:5)',
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          // 普通弹簧
          _SpringBar(
            controller: _normalController,
            label: '普通 (s:200, d:15)',
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          // 硬弹簧
          _SpringBar(
            controller: _stiffController,
            label: '硬质 (s:500, d:30)',
            color: Colors.red,
          ),
          const SizedBox(height: 32),
          // 参数说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('参数说明:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('s = stiffness (刚度)：越大弹回越快'),
                Text('d = damping (阻尼)：越大振荡越少'),
                Text('柔软弹簧会来回振荡多次'),
                Text('硬质弹簧几乎不振荡，快速到位'),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: FilledButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放对比'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 弹簧进度条组件
class _SpringBar extends StatelessWidget {
  final AnimationController controller;
  final String label;
  final Color color;

  const _SpringBar({
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // 将 controller 值 (0~1) 映射到进度条宽度
            final progress = controller.value.clamp(0.0, 1.5);
            return Stack(
              children: [
                // 背景
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                // 进度
                FractionallySizedBox(
                  widthFactor: (progress / 1.5).clamp(0.0, 1.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      progress.toStringAsFixed(2),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// 页面3：弹簧参数实时调节
// 通过 Slider 实时调整 stiffness 和 damping
// ============================================================
class _SpringTunerDemo extends StatefulWidget {
  const _SpringTunerDemo();

  @override
  State<_SpringTunerDemo> createState() => _SpringTunerDemoState();
}

class _SpringTunerDemoState extends State<_SpringTunerDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _stiffness = 200;
  double _damping = 15;
  double _mass = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    final spring = SpringDescription(
      mass: _mass,
      stiffness: _stiffness,
      damping: _damping,
    );
    // 从位置 0 弹到位置 1，初始速度 0
    _controller.animateWith(
      SpringSimulation(spring, 0.0, 1.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '实时调节弹簧参数',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 弹簧动画展示区域
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value.clamp(-0.2, 1.3);
              return SizedBox(
                height: 100,
                child: Stack(
                  children: [
                    // 目标位置标记
                    Positioned(
                      right: 24,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 2,
                          height: 60,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // 弹簧小球
                    Positioned(
                      left: 24 + value * (MediaQuery.of(context).size.width - 120),
                      top: 25,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 参数控制：刚度
          _SliderControl(
            label: '刚度 (stiffness)',
            value: _stiffness,
            min: 20,
            max: 800,
            onChanged: (v) => setState(() => _stiffness = v),
          ),
          const SizedBox(height: 16),
          // 参数控制：阻尼
          _SliderControl(
            label: '阻尼 (damping)',
            value: _damping,
            min: 1,
            max: 60,
            onChanged: (v) => setState(() => _damping = v),
          ),
          const SizedBox(height: 16),
          // 参数控制：质量
          _SliderControl(
            label: '质量 (mass)',
            value: _mass,
            min: 0.1,
            max: 5.0,
            onChanged: (v) => setState(() => _mass = v),
          ),
          const SizedBox(height: 24),
          // 当前参数摘要
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'SpringDescription(\n'
              '  mass: ${_mass.toStringAsFixed(1)},\n'
              '  stiffness: ${_stiffness.toStringAsFixed(0)},\n'
              '  damping: ${_damping.toStringAsFixed(1)},\n'
              ')',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider 控件封装
class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
