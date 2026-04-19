import 'dart:math';

import 'package:flutter/material.dart';

/// 第8章：Lottie 与 Rive
/// 演示内容：使用纯 Flutter 的 AnimationController 模拟动画控制逻辑
/// 1. 模拟 Lottie 播放器：播放/暂停/进度/速度控制
/// 2. 模拟 Rive 状态机：状态切换和交互控制
/// 不依赖任何第三方包和外部资源文件

void main() => runApp(const Ch08LottieRiveApp());

class Ch08LottieRiveApp extends StatelessWidget {
  const Ch08LottieRiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第8章：Lottie 与 Rive 模拟',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const LottieRiveHomePage(),
    );
  }
}

// ==================== 首页 ====================

class LottieRiveHomePage extends StatelessWidget {
  const LottieRiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第8章：Lottie 与 Rive 模拟')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            title: '模拟 Lottie 播放器',
            subtitle: '播放 / 暂停 / 进度拖拽 / 速度调节',
            icon: Icons.animation,
            color: Colors.orange,
            page: const MockLottiePlayerPage(),
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: '模拟 Rive 状态机',
            subtitle: '状态切换 / 输入控制 / 交互动画',
            icon: Icons.account_tree,
            color: Colors.teal,
            page: const MockRiveStateMachinePage(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}

// ==================== 模拟 Lottie 播放器 ====================

class MockLottiePlayerPage extends StatefulWidget {
  const MockLottiePlayerPage({super.key});

  @override
  State<MockLottiePlayerPage> createState() => _MockLottiePlayerPageState();
}

class _MockLottiePlayerPageState extends State<MockLottiePlayerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;
  bool _isLooping = false;
  double _speed = 1.0;

  // 动画的基准时长
  static const _baseDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _baseDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isLooping) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _play() {
    if (_isLooping) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
    setState(() => _isPlaying = true);
  }

  void _pause() {
    _controller.stop();
    setState(() => _isPlaying = false);
  }

  void _reset() {
    _controller.reset();
    setState(() => _isPlaying = false);
  }

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    if (_isPlaying) {
      if (_isLooping) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  void _setSpeed(double speed) {
    final currentValue = _controller.value;
    setState(() => _speed = speed);
    _controller.duration = Duration(
      milliseconds: (_baseDuration.inMilliseconds / speed).round(),
    );
    if (_isPlaying) {
      if (_isLooping) {
        _controller.repeat();
      } else {
        _controller.forward(from: currentValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模拟 Lottie 播放器')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 动画展示区域
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(250, 250),
                      painter: _LottieSimulationPainter(
                        progress: _controller.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 进度条
            _buildProgressSection(),
            const SizedBox(height: 16),

            // 播放控制按钮
            _buildControlButtons(),
            const SizedBox(height: 16),

            // 速度控制
            _buildSpeedControl(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            // 进度百分比
            Text(
              '进度: ${(_controller.value * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            // 进度滑块（可拖拽控制进度）
            Slider(
              value: _controller.value,
              onChanged: (value) {
                _controller.value = value;
              },
              onChangeStart: (_) {
                if (_isPlaying) _controller.stop();
              },
              onChangeEnd: (_) {
                if (_isPlaying) _play();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置
        IconButton.filled(
          onPressed: _reset,
          icon: const Icon(Icons.stop),
          tooltip: '重置',
        ),
        const SizedBox(width: 12),
        // 播放/暂停
        IconButton.filled(
          onPressed: _isPlaying ? _pause : _play,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          tooltip: _isPlaying ? '暂停' : '播放',
          style: IconButton.styleFrom(
            minimumSize: const Size(64, 64),
          ),
        ),
        const SizedBox(width: 12),
        // 循环切换
        IconButton.filled(
          onPressed: _toggleLoop,
          icon: Icon(_isLooping ? Icons.repeat_one : Icons.repeat),
          tooltip: _isLooping ? '单次播放' : '循环播放',
          style: IconButton.styleFrom(
            backgroundColor: _isLooping ? Colors.deepPurple : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControl() {
    return Column(
      children: [
        Text(
          '播放速度: ${_speed.toStringAsFixed(1)}x',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [0.5, 1.0, 1.5, 2.0, 3.0].map((speed) {
            final isSelected = _speed == speed;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${speed}x'),
                selected: isSelected,
                onSelected: (_) => _setSpeed(speed),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 模拟 Lottie 动画的自定义绘制
/// 绘制一个由多个旋转图形组成的动画
class _LottieSimulationPainter extends CustomPainter {
  final double progress;

  _LottieSimulationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 20;

    // 背景圆
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()..color = const Color(0x1A7C4DFF),
    );

    // 绘制旋转的装饰元素
    final elementCount = 8;
    for (int i = 0; i < elementCount; i++) {
      final angle = (i / elementCount) * 2 * pi + progress * 2 * pi;
      final radius = maxRadius * 0.7;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      // 每个元素的大小随进度变化
      final elementProgress = (progress * 3 + i / elementCount) % 1.0;
      final elementSize = 8.0 + 8.0 * sin(elementProgress * pi);

      // 颜色渐变
      final hue = (i / elementCount * 360 + progress * 360) % 360;
      final color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();

      canvas.drawCircle(
        Offset(x, y),
        elementSize,
        Paint()..color = color,
      );
    }

    // 中心旋转的星形
    _drawStar(canvas, center, 30 + 10 * sin(progress * 2 * pi),
        progress * 2 * pi);

    // 外围脉冲圆环
    final pulseRadius = maxRadius * (0.8 + 0.2 * sin(progress * 4 * pi));
    canvas.drawCircle(
      center,
      pulseRadius,
      Paint()
        ..color = Colors.deepPurple.withValues(
            alpha: 0.3 * (1 - (progress * 2 % 1.0)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, double rotation) {
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.4;
      final angle = (i * pi / points) + rotation - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.deepPurple
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LottieSimulationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ==================== 模拟 Rive 状态机 ====================

/// 模拟 Rive 的状态机系统
/// 通过布尔输入、数值输入和触发器控制动画状态
class MockRiveStateMachinePage extends StatefulWidget {
  const MockRiveStateMachinePage({super.key});

  @override
  State<MockRiveStateMachinePage> createState() =>
      _MockRiveStateMachinePageState();
}

enum CharacterState { idle, happy, sad, excited }

class _MockRiveStateMachinePageState extends State<MockRiveStateMachinePage>
    with TickerProviderStateMixin {
  // 模拟 Rive 的状态机输入
  CharacterState _currentState = CharacterState.idle;
  double _energyLevel = 0.5; // 数值输入
  bool _isWaving = false; // 布尔输入

  // 主动画控制器（持续循环）
  late final AnimationController _idleController;
  // 状态切换动画控制器
  late final AnimationController _transitionController;
  // 挥手动画控制器
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _transitionController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _setState(CharacterState state) {
    if (_currentState == state) return;
    setState(() => _currentState = state);
    _transitionController.forward(from: 0);
  }

  void _toggleWave() {
    setState(() => _isWaving = !_isWaving);
    if (_isWaving) {
      _waveController.repeat(reverse: true);
    } else {
      _waveController.forward().then((_) => _waveController.reset());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模拟 Rive 状态机')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 角色动画展示
            SizedBox(
              height: 280,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _idleController,
                  _transitionController,
                  _waveController,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(250, 250),
                    painter: _CharacterPainter(
                      state: _currentState,
                      idleValue: _idleController.value,
                      transitionValue: _transitionController.value,
                      waveValue: _waveController.value,
                      energyLevel: _energyLevel,
                      isWaving: _isWaving,
                    ),
                  );
                },
              ),
            ),

            // 当前状态显示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '当前状态: ${_currentState.name.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStateDescription(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 状态切换按钮（模拟 Rive 的 Trigger 输入）
            const Text(
              '触发器输入 (Trigger)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CharacterState.values.map((state) {
                final isActive = _currentState == state;
                return FilterChip(
                  label: Text(_getStateLabel(state)),
                  selected: isActive,
                  onSelected: (_) => _setState(state),
                  avatar: Text(_getStateEmoji(state)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 布尔输入
            const Text(
              '布尔输入 (Boolean)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SwitchListTile(
              title: const Text('挥手 (isWaving)'),
              subtitle: Text(_isWaving ? '正在挥手' : '未挥手'),
              value: _isWaving,
              onChanged: (_) => _toggleWave(),
            ),
            const SizedBox(height: 12),

            // 数值输入
            const Text(
              '数值输入 (Number)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('能量等级:'),
                Expanded(
                  child: Slider(
                    value: _energyLevel,
                    onChanged: (value) {
                      setState(() => _energyLevel = value);
                    },
                  ),
                ),
                Text('${(_energyLevel * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStateDescription() {
    switch (_currentState) {
      case CharacterState.idle:
        return '角色处于待机状态，轻微呼吸动画';
      case CharacterState.happy:
        return '角色开心，嘴角上扬，身体微微跳动';
      case CharacterState.sad:
        return '角色悲伤，嘴角下垂，身体缩小';
      case CharacterState.excited:
        return '角色兴奋，大幅跳动，颜色更亮';
    }
  }

  String _getStateLabel(CharacterState state) {
    switch (state) {
      case CharacterState.idle:
        return '待机';
      case CharacterState.happy:
        return '开心';
      case CharacterState.sad:
        return '悲伤';
      case CharacterState.excited:
        return '兴奋';
    }
  }

  String _getStateEmoji(CharacterState state) {
    switch (state) {
      case CharacterState.idle:
        return '😐';
      case CharacterState.happy:
        return '😊';
      case CharacterState.sad:
        return '😢';
      case CharacterState.excited:
        return '🤩';
    }
  }
}

/// 绘制角色动画
class _CharacterPainter extends CustomPainter {
  final CharacterState state;
  final double idleValue;
  final double transitionValue;
  final double waveValue;
  final double energyLevel;
  final bool isWaving;

  _CharacterPainter({
    required this.state,
    required this.idleValue,
    required this.transitionValue,
    required this.waveValue,
    required this.energyLevel,
    required this.isWaving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 根据状态决定颜色
    final Color bodyColor;
    switch (state) {
      case CharacterState.idle:
        bodyColor = const Color(0xFF7C4DFF);
      case CharacterState.happy:
        bodyColor = const Color(0xFFFFB300);
      case CharacterState.sad:
        bodyColor = const Color(0xFF42A5F5);
      case CharacterState.excited:
        bodyColor = const Color(0xFFFF5252);
    }

    // 根据能量等级计算大小倍率
    final energyScale = 0.8 + energyLevel * 0.4;

    // 呼吸/跳动效果
    double bounceOffset;
    switch (state) {
      case CharacterState.idle:
        bounceOffset = sin(idleValue * pi) * 5;
      case CharacterState.happy:
        bounceOffset = sin(idleValue * pi * 2) * 8;
      case CharacterState.sad:
        bounceOffset = sin(idleValue * pi) * 2;
      case CharacterState.excited:
        bounceOffset = sin(idleValue * pi * 3) * 15;
    }

    final bodyCenter = Offset(centerX, centerY + bounceOffset);
    final bodyRadius = 50.0 * energyScale;

    // 身体（圆形）
    canvas.drawCircle(
      bodyCenter,
      bodyRadius,
      Paint()..color = bodyColor,
    );

    // 身体高光
    canvas.drawCircle(
      Offset(bodyCenter.dx - bodyRadius * 0.25,
          bodyCenter.dy - bodyRadius * 0.25),
      bodyRadius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // 眼睛
    final eyeY = bodyCenter.dy - bodyRadius * 0.15;
    final eyeSpacing = bodyRadius * 0.35;
    final eyeRadius = bodyRadius * 0.12;

    // 左眼
    canvas.drawCircle(
      Offset(bodyCenter.dx - eyeSpacing, eyeY),
      eyeRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(bodyCenter.dx - eyeSpacing, eyeY),
      eyeRadius * 0.5,
      Paint()..color = const Color(0xFF333333),
    );

    // 右眼
    canvas.drawCircle(
      Offset(bodyCenter.dx + eyeSpacing, eyeY),
      eyeRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(bodyCenter.dx + eyeSpacing, eyeY),
      eyeRadius * 0.5,
      Paint()..color = const Color(0xFF333333),
    );

    // 嘴巴（根据状态改变）
    final mouthY = bodyCenter.dy + bodyRadius * 0.25;
    final mouthPath = Path();
    switch (state) {
      case CharacterState.idle:
        // 水平线
        mouthPath.moveTo(bodyCenter.dx - bodyRadius * 0.2, mouthY);
        mouthPath.lineTo(bodyCenter.dx + bodyRadius * 0.2, mouthY);
      case CharacterState.happy:
      case CharacterState.excited:
        // 微笑弧线
        mouthPath.moveTo(bodyCenter.dx - bodyRadius * 0.25, mouthY);
        mouthPath.quadraticBezierTo(
          bodyCenter.dx,
          mouthY + bodyRadius * 0.25,
          bodyCenter.dx + bodyRadius * 0.25,
          mouthY,
        );
      case CharacterState.sad:
        // 悲伤弧线
        mouthPath.moveTo(
            bodyCenter.dx - bodyRadius * 0.2, mouthY + bodyRadius * 0.1);
        mouthPath.quadraticBezierTo(
          bodyCenter.dx,
          mouthY - bodyRadius * 0.15,
          bodyCenter.dx + bodyRadius * 0.2,
          mouthY + bodyRadius * 0.1,
        );
    }
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 挥手动画
    if (isWaving) {
      final handAngle = -pi / 4 + sin(waveValue * pi) * pi / 4;
      final handStart = Offset(
        bodyCenter.dx + bodyRadius * 0.9,
        bodyCenter.dy - bodyRadius * 0.2,
      );
      final handEnd = Offset(
        handStart.dx + cos(handAngle) * bodyRadius * 0.6,
        handStart.dy + sin(handAngle) * bodyRadius * 0.6,
      );

      canvas.drawLine(
        handStart,
        handEnd,
        Paint()
          ..color = bodyColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      // 手掌
      canvas.drawCircle(
        handEnd,
        8,
        Paint()..color = bodyColor,
      );
    }

    // 兴奋状态下的粒子效果
    if (state == CharacterState.excited) {
      final random = Random(42);
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * pi + idleValue * pi;
        final dist =
            bodyRadius * 1.5 + random.nextDouble() * 20 * sin(idleValue * pi);
        final px = bodyCenter.dx + cos(angle) * dist;
        final py = bodyCenter.dy + sin(angle) * dist;
        canvas.drawCircle(
          Offset(px, py),
          3,
          Paint()
            ..color = Colors.amber.withValues(
                alpha: 0.5 + 0.5 * sin(idleValue * pi + i)),
        );
      }
    }

    // 悲伤状态下的眼泪
    if (state == CharacterState.sad) {
      final tearProgress = (idleValue * 2) % 1.0;
      final tearY = eyeY + eyeRadius + tearProgress * bodyRadius * 0.5;
      canvas.drawCircle(
        Offset(bodyCenter.dx - eyeSpacing, tearY),
        3,
        Paint()
          ..color = Colors.lightBlue.withValues(alpha: 1.0 - tearProgress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.idleValue != idleValue ||
        oldDelegate.state != state ||
        oldDelegate.transitionValue != transitionValue ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.energyLevel != energyLevel ||
        oldDelegate.isWaving != isWaving;
  }
}
