import 'dart:ui';

import 'package:flutter/material.dart';

// ============================================================================
// 品牌颜色扩展
// ============================================================================

/// 品牌颜色扩展
///
/// 定义品牌专属的颜色令牌，支持亮色/暗色主题切换和 lerp 动画插值。
///
/// 使用方式：
/// ```dart
/// final brand = Theme.of(context).extension<BrandColors>()!;
/// Container(color: brand.brandPrimary);
/// ```
class BrandColors extends ThemeExtension<BrandColors> {
  /// 品牌主色
  final Color brandPrimary;

  /// 品牌强调色
  final Color brandAccent;

  /// 卡片背景色
  final Color cardBackground;

  /// 成功状态色
  final Color successColor;

  /// 警告状态色
  final Color warningColor;

  /// 信息提示色
  final Color infoColor;

  const BrandColors({
    required this.brandPrimary,
    required this.brandAccent,
    required this.cardBackground,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
  });

  // ---------- 预置亮色方案 ----------

  static const light = BrandColors(
    brandPrimary: Color(0xFF6750A4),
    brandAccent: Color(0xFFFF6B35),
    cardBackground: Color(0xFFF5F5F5),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFFC107),
    infoColor: Color(0xFF2196F3),
  );

  // ---------- 预置暗色方案 ----------

  static const dark = BrandColors(
    brandPrimary: Color(0xFFD0BCFF),
    brandAccent: Color(0xFFFFB088),
    cardBackground: Color(0xFF1E1E1E),
    successColor: Color(0xFF81C784),
    warningColor: Color(0xFFFFD54F),
    infoColor: Color(0xFF64B5F6),
  );

  @override
  BrandColors copyWith({
    Color? brandPrimary,
    Color? brandAccent,
    Color? cardBackground,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
  }) {
    return BrandColors(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandAccent: brandAccent ?? this.brandAccent,
      cardBackground: cardBackground ?? this.cardBackground,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
    );
  }

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
    );
  }
}

// ============================================================================
// 品牌间距扩展
// ============================================================================

/// 品牌间距扩展
///
/// 定义品牌专属的间距和圆角令牌，支持 compact（紧凑）和 comfortable（舒适）两套预置。
///
/// 使用方式：
/// ```dart
/// final spacing = Theme.of(context).extension<BrandSpacing>()!;
/// Padding(padding: EdgeInsets.all(spacing.medium));
/// ```
class BrandSpacing extends ThemeExtension<BrandSpacing> {
  /// 小间距
  final double small;

  /// 中间距
  final double medium;

  /// 大间距
  final double large;

  /// 卡片内边距
  final double cardPadding;

  /// 卡片圆角
  final double cardRadius;

  const BrandSpacing({
    required this.small,
    required this.medium,
    required this.large,
    required this.cardPadding,
    required this.cardRadius,
  });

  // ---------- 紧凑方案：适合信息密集型界面 ----------

  static const compact = BrandSpacing(
    small: 4.0,
    medium: 8.0,
    large: 12.0,
    cardPadding: 12.0,
    cardRadius: 8.0,
  );

  // ---------- 舒适方案：适合内容展示型界面 ----------

  static const comfortable = BrandSpacing(
    small: 8.0,
    medium: 16.0,
    large: 24.0,
    cardPadding: 20.0,
    cardRadius: 16.0,
  );

  @override
  BrandSpacing copyWith({
    double? small,
    double? medium,
    double? large,
    double? cardPadding,
    double? cardRadius,
  }) {
    return BrandSpacing(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      cardPadding: cardPadding ?? this.cardPadding,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  BrandSpacing lerp(BrandSpacing? other, double t) {
    if (other is! BrandSpacing) return this;
    return BrandSpacing(
      small: lerpDouble(small, other.small, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
