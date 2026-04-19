import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/theme_extensions.dart';

/// 第7章示例：ThemeExtension 品牌色主题扩展
///
/// 演示如何使用自定义 ThemeExtension 实现品牌级别的颜色和间距定制，
/// 并支持亮色/暗色品牌方案的一键切换。
class ThemeExtensionExample extends StatefulWidget {
  const ThemeExtensionExample({super.key});

  @override
  State<ThemeExtensionExample> createState() => _ThemeExtensionExampleState();
}

class _ThemeExtensionExampleState extends State<ThemeExtensionExample> {
  /// 是否使用暗色品牌方案
  bool _isDarkBrand = false;

  /// 是否使用舒适间距
  bool _isComfortable = true;

  @override
  Widget build(BuildContext context) {
    // 根据当前选择，决定使用哪套品牌颜色和间距
    final brandColors = _isDarkBrand ? BrandColors.dark : BrandColors.light;
    final brandSpacing =
        _isComfortable ? BrandSpacing.comfortable : BrandSpacing.compact;

    // 用 Theme widget 包裹整个页面，注册自定义扩展
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[brandColors, brandSpacing],
      ),
      // 用 Builder 确保子树能获取到更新后的 Theme
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('第7章：ThemeExtension')),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(brandSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- 切换按钮区域 ----
                  _buildSwitchBar(context),
                  SizedBox(height: brandSpacing.large),

                  // ---- 品牌色色板 ----
                  _buildColorPalette(context),
                  SizedBox(height: brandSpacing.large),

                  // ---- 品牌色标题 ----
                  _buildBrandTitle(context),
                  SizedBox(height: brandSpacing.large),

                  // ---- 状态标签 ----
                  _buildStatusChips(context),
                  SizedBox(height: brandSpacing.large),

                  // ---- 品牌卡片 ----
                  _buildBrandCard(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 顶部切换按钮：亮色品牌 / 暗色品牌 + 间距方案
  Widget _buildSwitchBar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('主题切换', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                // 亮色品牌按钮
                Expanded(
                  child: _BrandToggleButton(
                    label: '☀️ 亮色品牌',
                    isSelected: !_isDarkBrand,
                    onTap: () => setState(() => _isDarkBrand = false),
                  ),
                ),
                const SizedBox(width: 8),
                // 暗色品牌按钮
                Expanded(
                  child: _BrandToggleButton(
                    label: '🌙 暗色品牌',
                    isSelected: _isDarkBrand,
                    onTap: () => setState(() => _isDarkBrand = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BrandToggleButton(
                    label: '📐 紧凑间距',
                    isSelected: !_isComfortable,
                    onTap: () => setState(() => _isComfortable = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BrandToggleButton(
                    label: '🛋️ 舒适间距',
                    isSelected: _isComfortable,
                    onTap: () => setState(() => _isComfortable = true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 品牌色圆形色板展示
  Widget _buildColorPalette(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    // 每种品牌色对应一个名称和颜色值
    final palette = <MapEntry<String, Color>>[
      MapEntry('主色', brand.brandPrimary),
      MapEntry('强调', brand.brandAccent),
      MapEntry('卡片背景', brand.cardBackground),
      MapEntry('成功', brand.successColor),
      MapEntry('警告', brand.warningColor),
      MapEntry('信息', brand.infoColor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('品牌色板', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: palette.map((entry) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 圆形色块
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: entry.value.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 用 brandPrimary 着色的标题
  Widget _buildBrandTitle(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '品牌色标题',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: brand.brandPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '这段文字使用品牌强调色',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: brand.brandAccent,
          ),
        ),
      ],
    );
  }

  /// 状态标签区域：success / warning / info
  Widget _buildStatusChips(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('状态标签', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(label: '✅ 成功', color: brand.successColor),
            _StatusChip(label: '⚠️ 警告', color: brand.warningColor),
            _StatusChip(label: 'ℹ️ 信息', color: brand.infoColor),
            _StatusChip(label: '🎨 主色', color: brand.brandPrimary),
            _StatusChip(label: '🔥 强调', color: brand.brandAccent),
          ],
        ),
      ],
    );
  }

  /// 使用 cardBackground + cardPadding + cardRadius 制作的品牌卡片
  Widget _buildBrandCard(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final spacing = Theme.of(context).extension<BrandSpacing>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('品牌卡片', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: spacing.medium),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacing.cardPadding),
          decoration: BoxDecoration(
            color: brand.cardBackground,
            borderRadius: BorderRadius.circular(spacing.cardRadius),
            border: Border.all(
              color: brand.brandPrimary.withAlpha(50),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: brand.brandPrimary),
                  SizedBox(width: spacing.small),
                  Text(
                    '品牌定制卡片',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: brand.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.medium),
              Text(
                '这张卡片的背景色、内边距和圆角都来自 ThemeExtension。\n'
                '当切换品牌方案时，所有属性自动更新。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: spacing.medium),
              // 底部操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '了解更多',
                      style: TextStyle(color: brand.brandAccent),
                    ),
                  ),
                  SizedBox(width: spacing.small),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('开始使用'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 内部组件
// ============================================================================

/// 品牌方案切换按钮
class _BrandToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态标签组件
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withAlpha(25),
      side: BorderSide(color: color.withAlpha(80)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
