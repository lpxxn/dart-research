import 'dart:ui';

import 'package:flutter/material.dart';

/// 卡片风格枚举
enum CardStyle {
  /// 扁平风格：纯色背景 + 细边框，无阴影
  flat,

  /// 浮起风格：白色背景 + 多层柔和阴影（Material 风格）
  elevated,

  /// 毛玻璃风格：半透明背景 + BackdropFilter 模糊 + 白色细边框
  glassmorphism,

  /// 霓虹风格：深色背景 + 亮色边框 + 发光阴影
  neon,
}

/// 多风格美化卡片控件
///
/// 支持 [CardStyle.flat]、[CardStyle.elevated]、[CardStyle.glassmorphism]、
/// [CardStyle.neon] 四种视觉风格。
class StyledCard extends StatelessWidget {
  /// 卡片风格
  final CardStyle style;

  /// 卡片内容
  final Widget child;

  /// 主色调，不同风格中的用途不同：
  /// - flat: 背景色
  /// - elevated: 不使用（白色背景）
  /// - glassmorphism: 半透明叠加色
  /// - neon: 边框及发光颜色
  final Color? primaryColor;

  /// 圆角半径
  final double borderRadius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const StyledCard({
    super.key,
    required this.style,
    required this.child,
    this.primaryColor,
    this.borderRadius = 16,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  /// 获取实际使用的主色调
  Color _resolvedColor(BuildContext context) {
    return primaryColor ?? Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolvedColor(context);
    final radius = BorderRadius.circular(borderRadius);

    Widget card;

    switch (style) {
      case CardStyle.flat:
        card = _buildFlat(color, radius);
      case CardStyle.elevated:
        card = _buildElevated(radius);
      case CardStyle.glassmorphism:
        card = _buildGlassmorphism(color, radius);
      case CardStyle.neon:
        card = _buildNeon(color, radius);
    }

    // 包裹点击效果
    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  /// 扁平风格：纯色背景 + 细边框，无阴影
  Widget _buildFlat(Color color, BorderRadius radius) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: child,
    );
  }

  /// 浮起风格：白色背景 + 多层柔和阴影
  Widget _buildElevated(BorderRadius radius) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          // 主阴影：较大偏移，模拟远光源
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -4,
          ),
          // 中间层：中等模糊
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -2,
          ),
          // 近层：紧贴边缘的细微阴影
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  /// 毛玻璃风格：半透明背景 + BackdropFilter + 白色细边框
  Widget _buildGlassmorphism(Color color, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // 半透明白色叠加，带一点主色调
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// 霓虹风格：深色背景 + 亮色边框 + 多层发光阴影
  Widget _buildNeon(Color color, BorderRadius radius) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // 深色背景让霓虹效果更明显
        color: const Color(0xFF1A1A2E),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          // 外层大范围柔光
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          // 中层光晕
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 0,
          ),
          // 内层强光
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: -3,
          ),
        ],
      ),
      child: child,
    );
  }
}
