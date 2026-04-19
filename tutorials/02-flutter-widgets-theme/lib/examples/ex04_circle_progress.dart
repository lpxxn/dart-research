import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/circle_progress.dart';

/// 第4章示例页面：环形进度条演示
class CircleProgressExample extends StatefulWidget {
  const CircleProgressExample({super.key});

  @override
  State<CircleProgressExample> createState() => _CircleProgressExampleState();
}

class _CircleProgressExampleState extends State<CircleProgressExample>
    with SingleTickerProviderStateMixin {
  /// Slider 控制的进度值（0-100）
  double _sliderValue = 65;

  /// 动画控制器
  AnimationController? _animationController;

  /// 动画对象
  Animation<double>? _animation;

  /// 当前动画驱动的进度值（0.0-1.0），为 null 时使用 Slider 值
  double? _animatedProgress;

  /// 底部展示的四个小进度条配置
  static const List<_ProgressConfig> _smallConfigs = [
    _ProgressConfig(
      progress: 0.25,
      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
      label: '25%',
    ),
    _ProgressConfig(
      progress: 0.50,
      colors: [Color(0xFF4ECDC4), Color(0xFF44BD32)],
      label: '50%',
    ),
    _ProgressConfig(
      progress: 0.75,
      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
      label: '75%',
    ),
    _ProgressConfig(
      progress: 1.0,
      colors: [Color(0xFFFFA502), Color(0xFFFF6348)],
      label: '100%',
    ),
  ];

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  /// 启动动画：从 0 平滑过渡到当前 Slider 值
  void _startAnimation() {
    // 释放旧的控制器
    _animationController?.dispose();

    final targetProgress = _sliderValue / 100;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: targetProgress).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {
          _animatedProgress = _animation!.value;
        });
      });

    // 动画结束后清除动画进度，回到 Slider 控制
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animatedProgress = null;
        });
      }
    });

    setState(() {
      _animatedProgress = 0;
    });
    _animationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 主进度值：动画进行时用动画值，否则用 Slider 值
    final mainProgress = _animatedProgress ?? (_sliderValue / 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第4章：CustomPainter 环形进度条'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ===== 大进度条 =====
            const SizedBox(height: 16),
            CircleProgress(
              progress: mainProgress,
              size: 200,
              strokeWidth: 14,
              gradientColors: const [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
              textStyle: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667EEA),
              ),
            ),

            // ===== Slider 控制区域 =====
            const SizedBox(height: 32),
            Text(
              '拖动调节进度: ${_sliderValue.round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _sliderValue,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_sliderValue.round()}%',
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                  // 手动拖动时取消动画
                  _animatedProgress = null;
                  _animationController?.stop();
                });
              },
            ),

            // ===== 动画演示按钮 =====
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startAnimation,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('动画演示'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击后进度从 0 动画到当前值',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            // ===== 四个小进度条 =====
            const SizedBox(height: 40),
            Text(
              '多种配色示例',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _smallConfigs.map((config) {
                return Column(
                  children: [
                    CircleProgress(
                      progress: config.progress,
                      size: 72,
                      strokeWidth: 7,
                      gradientColors: config.colors,
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: config.colors.first,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      config.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: config.colors.first,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// 小进度条配置
class _ProgressConfig {
  final double progress;
  final List<Color> colors;
  final String label;

  const _ProgressConfig({
    required this.progress,
    required this.colors,
    required this.label,
  });
}
