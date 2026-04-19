import 'dart:math';

import 'package:flutter/material.dart';

/// 环形渐变进度条控件
///
/// 使用 [CustomPainter] 绘制背景圆环、渐变进度弧和中心百分比文字。
class CircleProgress extends StatelessWidget {
  /// 进度值，范围 0.0 ~ 1.0
  final double progress;

  /// 控件尺寸（宽高相等的正方形）
  final double size;

  /// 圆环线宽
  final double strokeWidth;

  /// 背景圆环颜色
  final Color backgroundColor;

  /// 进度弧颜色（单色模式，优先级低于 [gradientColors]）
  final Color progressColor;

  /// 进度弧渐变颜色列表（设置后覆盖 [progressColor]）
  final List<Color>? gradientColors;

  /// 是否显示中心百分比文字
  final bool showPercentText;

  /// 百分比文字样式
  final TextStyle? textStyle;

  /// 进度弧端点样式
  final StrokeCap strokeCap;

  const CircleProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.progressColor = Colors.blue,
    this.gradientColors,
    this.showPercentText = true,
    this.textStyle,
    this.strokeCap = StrokeCap.round,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircleProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          progressColor: progressColor,
          gradientColors: gradientColors,
          showPercentText: showPercentText,
          textStyle: textStyle ??
              TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: gradientColors?.first ?? progressColor,
              ),
          strokeCap: strokeCap,
        ),
      ),
    );
  }
}

/// 环形进度条画家
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final List<Color>? gradientColors;
  final bool showPercentText;
  final TextStyle textStyle;
  final StrokeCap strokeCap;

  _CircleProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    this.gradientColors,
    required this.showPercentText,
    required this.textStyle,
    required this.strokeCap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 半径 = 控件半宽 - 线宽的一半（让圆环完全在控件内）
    final radius = (size.width - strokeWidth) / 2;

    _drawBackgroundCircle(canvas, center, radius);

    if (progress > 0) {
      _drawProgressArc(canvas, center, radius, size);
    }

    if (showPercentText) {
      _drawPercentText(canvas, size);
    }
  }

  /// 绘制背景圆环
  void _drawBackgroundCircle(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, bgPaint);
  }

  /// 绘制渐变进度弧
  void _drawProgressArc(
      Canvas canvas, Offset center, double radius, Size size) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * pi * progress;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap
      ..isAntiAlias = true;

    // 设置渐变或单色
    final colors = gradientColors ?? [progressColor, progressColor];
    if (colors.length >= 2) {
      // 使用 SweepGradient 实现弧线渐变效果
      // 需要旋转渐变起点到 12 点钟方向（-90°）
      progressPaint.shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: colors,
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);
    } else {
      progressPaint.color = colors.first;
    }

    // 从 12 点钟方向（-π/2）开始，顺时针绘制
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
  }

  /// 绘制中心百分比文字
  void _drawPercentText(Canvas canvas, Size size) {
    final percent = (progress * 100).round();
    final textPainter = TextPainter(
      text: TextSpan(text: '$percent%', style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 居中绘制
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.showPercentText != showPercentText ||
        oldDelegate.strokeCap != strokeCap;
  }
}
