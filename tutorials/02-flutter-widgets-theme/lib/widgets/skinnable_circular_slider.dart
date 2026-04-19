import 'dart:math';
import 'package:flutter/material.dart';

/// 滑块皮肤配置
///
/// 封装了环形滑块的所有视觉参数，遵循"配置对象模式"。
/// 提供三种预置皮肤：[techBlue]、[warmOrange]、[darkPurple]。
class SliderSkin {
  /// 进度条渐变色（至少两个颜色）
  final List<Color> progressGradientColors;

  /// 背景轨道颜色
  final Color trackColor;

  /// 拖拽把手填充色
  final Color handlerColor;

  /// 拖拽把手边框色
  final Color handlerBorderColor;

  /// 阴影颜色
  final Color shadowColor;

  /// 中心百分比文字颜色
  final Color textColor;

  /// 背景轨道宽度
  final double trackWidth;

  /// 进度条宽度
  final double progressWidth;

  /// 拖拽把手半径
  final double handlerRadius;

  const SliderSkin({
    this.progressGradientColors = const [Color(0xFF00B4DB), Color(0xFF0083B0)],
    this.trackColor = const Color(0xFFE0E0E0),
    this.handlerColor = Colors.white,
    this.handlerBorderColor = const Color(0xFF0083B0),
    this.shadowColor = const Color(0xFF00B4DB),
    this.textColor = const Color(0xFF0083B0),
    this.trackWidth = 12,
    this.progressWidth = 12,
    this.handlerRadius = 16,
  });

  /// 预置皮肤：科技蓝
  static const techBlue = SliderSkin(
    progressGradientColors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    trackColor: Color(0xFFE0E0E0),
    handlerColor: Colors.white,
    handlerBorderColor: Color(0xFF0083B0),
    shadowColor: Color(0xFF00B4DB),
    textColor: Color(0xFF0083B0),
    trackWidth: 12,
    progressWidth: 12,
    handlerRadius: 16,
  );

  /// 预置皮肤：暖橙
  static const warmOrange = SliderSkin(
    progressGradientColors: [Color(0xFFFF8008), Color(0xFFFFC837)],
    trackColor: Color(0xFFFFF3E0),
    handlerColor: Colors.white,
    handlerBorderColor: Color(0xFFFF8008),
    shadowColor: Color(0xFFFF8008),
    textColor: Color(0xFFE65100),
    trackWidth: 14,
    progressWidth: 14,
    handlerRadius: 18,
  );

  /// 预置皮肤：暗夜紫
  static const darkPurple = SliderSkin(
    progressGradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    trackColor: Color(0xFF2D2D2D),
    handlerColor: Color(0xFF1A1A2E),
    handlerBorderColor: Color(0xFF8E2DE2),
    shadowColor: Color(0xFF8E2DE2),
    textColor: Color(0xFFD0BCFF),
    trackWidth: 10,
    progressWidth: 14,
    handlerRadius: 14,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SliderSkin &&
          runtimeType == other.runtimeType &&
          progressGradientColors.length ==
              other.progressGradientColors.length &&
          trackColor == other.trackColor &&
          handlerColor == other.handlerColor &&
          handlerBorderColor == other.handlerBorderColor &&
          shadowColor == other.shadowColor &&
          textColor == other.textColor &&
          trackWidth == other.trackWidth &&
          progressWidth == other.progressWidth &&
          handlerRadius == other.handlerRadius;

  @override
  int get hashCode => Object.hash(
        trackColor,
        handlerColor,
        handlerBorderColor,
        shadowColor,
        textColor,
        trackWidth,
        progressWidth,
        handlerRadius,
      );
}

/// 可换肤环形滑块
///
/// 用法示例：
/// ```dart
/// SkinnableCircularSlider(
///   value: 0.6,
///   skin: SliderSkin.techBlue,
///   onChanged: (v) => print('进度: $v'),
/// )
/// ```
class SkinnableCircularSlider extends StatefulWidget {
  /// 当前进度值，范围 0.0 ~ 1.0
  final double value;

  /// 进度变化回调；为 null 时滑块不可交互
  final ValueChanged<double>? onChanged;

  /// 控件尺寸（宽高相等的正方形）
  final double size;

  /// 皮肤配置
  final SliderSkin skin;

  /// 是否在中心显示百分比文字
  final bool showPercentText;

  const SkinnableCircularSlider({
    super.key,
    this.value = 0.0,
    this.onChanged,
    this.size = 200,
    this.skin = const SliderSkin(),
    this.showPercentText = true,
  });

  @override
  State<SkinnableCircularSlider> createState() =>
      _SkinnableCircularSliderState();
}

class _SkinnableCircularSliderState extends State<SkinnableCircularSlider> {
  /// 起始角度（12 点钟方向 = -π/2）
  static const double _startAngle = -pi / 2;

  /// 总角度范围（完整一圈 = 2π）
  static const double _sweepRange = 2 * pi;

  /// 将触摸坐标转换为 0.0 ~ 1.0 的进度值
  double _touchToProgress(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // atan2 返回 -π ~ π，3 点钟方向为 0
    double angle = atan2(dy, dx);

    // 转换为以 12 点钟方向为起点的角度（0 ~ 2π）
    angle = angle - _startAngle;
    if (angle < 0) angle += 2 * pi;

    // 映射到 0.0 ~ 1.0
    final progress = (angle / _sweepRange).clamp(0.0, 1.0);
    return progress;
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.onChanged == null) return;
    final progress = _touchToProgress(details.localPosition);
    widget.onChanged!(progress);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.onChanged == null) return;
    final progress = _touchToProgress(details.localPosition);
    widget.onChanged!(progress);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SliderPainter(
          value: widget.value.clamp(0.0, 1.0),
          skin: widget.skin,
          showPercentText: widget.showPercentText,
        ),
      ),
    );
  }
}

/// 环形滑块绘制器
///
/// 绘制顺序：阴影层 → 背景轨道 → 渐变进度弧 → 拖拽把手 → 中心文字
class _SliderPainter extends CustomPainter {
  final double value;
  final SliderSkin skin;
  final bool showPercentText;

  /// 起始角度（12 点钟方向）
  static const double _startAngle = -pi / 2;

  _SliderPainter({
    required this.value,
    required this.skin,
    required this.showPercentText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 留出足够的边距给把手和阴影
    final maxEdge = max(skin.handlerRadius, skin.progressWidth / 2) + 4;
    final radius = size.width / 2 - maxEdge;
    final sweepAngle = 2 * pi * value;

    // 1. 画阴影层
    _drawShadow(canvas, center, radius, sweepAngle);

    // 2. 画背景轨道
    _drawTrack(canvas, center, radius);

    // 3. 画渐变进度弧
    _drawProgress(canvas, center, radius, sweepAngle);

    // 4. 画拖拽把手
    _drawHandler(canvas, center, radius, sweepAngle);

    // 5. 画中心百分比文字
    if (showPercentText) {
      _drawCenterText(canvas, center);
    }
  }

  /// 画阴影层：3 层同心弧，opacity 从内到外递减
  void _drawShadow(
      Canvas canvas, Offset center, double radius, double sweepAngle) {
    if (value <= 0) return;

    const int layers = 3;
    const double baseOpacity = 0.3;
    const double widthStep = 4.0;

    for (int i = 0; i < layers; i++) {
      final opacity = baseOpacity * (1 - i / layers);
      final extraWidth = widthStep * (i + 1);

      final paint = Paint()
        ..color = skin.shadowColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = skin.progressWidth + extraWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + i * 2.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  /// 画背景轨道：完整圆弧
  void _drawTrack(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = skin.trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = skin.trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      2 * pi,
      false,
      paint,
    );
  }

  /// 画渐变进度弧：使用 SweepGradient
  void _drawProgress(
      Canvas canvas, Offset center, double radius, double sweepAngle) {
    if (value <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = skin.progressWidth
      ..strokeCap = StrokeCap.round;

    // 创建 SweepGradient 着色器
    if (skin.progressGradientColors.length >= 2) {
      final gradient = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + 2 * pi,
        colors: skin.progressGradientColors,
        // 渐变在整个圆上分布，进度弧只"揭露"其中一部分
      );
      paint.shader = gradient.createShader(rect);
    } else {
      paint.color = skin.progressGradientColors.isNotEmpty
          ? skin.progressGradientColors.first
          : skin.handlerBorderColor;
    }

    canvas.drawArc(rect, _startAngle, sweepAngle, false, paint);
  }

  /// 画拖拽把手：位于进度弧末端，带边框的圆形
  void _drawHandler(
      Canvas canvas, Offset center, double radius, double sweepAngle) {
    // 计算把手中心坐标
    final handlerAngle = _startAngle + sweepAngle;
    final handlerCenter = Offset(
      center.dx + radius * cos(handlerAngle),
      center.dy + radius * sin(handlerAngle),
    );

    // 画把手阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(handlerCenter, skin.handlerRadius, shadowPaint);

    // 画把手边框（稍大的圆）
    final borderPaint = Paint()
      ..color = skin.handlerBorderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handlerCenter, skin.handlerRadius, borderPaint);

    // 画把手内部填充（稍小的圆）
    final fillPaint = Paint()
      ..color = skin.handlerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handlerCenter, skin.handlerRadius * 0.7, fillPaint);
  }

  /// 画中心百分比文字
  void _drawCenterText(Canvas canvas, Offset center) {
    final percent = (value * 100).round();
    final textSpan = TextSpan(
      text: '$percent%',
      style: TextStyle(
        color: skin.textColor,
        fontSize: center.dx * 0.35, // 字号随控件尺寸自适应
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    // 居中绘制
    final offset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.skin != skin ||
        oldDelegate.showPercentText != showPercentText;
  }
}
