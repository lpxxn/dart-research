import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/skinnable_circular_slider.dart';

/// 第10章示例：可换肤环形滑块
///
/// 展示 [SkinnableCircularSlider] 的三种预置皮肤以及运行时换肤能力。
class SkinnableSliderExample extends StatefulWidget {
  const SkinnableSliderExample({super.key});

  @override
  State<SkinnableSliderExample> createState() => _SkinnableSliderExampleState();
}

class _SkinnableSliderExampleState extends State<SkinnableSliderExample> {
  /// 当前选中的皮肤索引
  int _selectedIndex = 0;

  /// 大滑块的进度值
  double _progress = 0.65;

  /// 皮肤列表
  static const _skins = [
    SliderSkin.techBlue,
    SliderSkin.warmOrange,
    SliderSkin.darkPurple,
  ];

  /// 皮肤名称
  static const _skinNames = ['科技蓝', '暖橙', '暗夜紫'];

  /// 根据当前选中皮肤决定背景色（暗夜紫用暗色背景）
  Color get _backgroundColor =>
      _selectedIndex == 2 ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

  /// 根据背景色决定文字颜色
  Color get _foregroundColor =>
      _selectedIndex == 2 ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: _backgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('第10章：可换肤环形滑块'),
          backgroundColor: Colors.transparent,
          foregroundColor: _foregroundColor,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ── 大型可交互滑块 ──
                _buildMainSlider(),

                const SizedBox(height: 32),

                // ── 皮肤选择卡片 ──
                _buildSkinSelector(),

                const SizedBox(height: 32),

                // ── 三个小型预览滑块 ──
                _buildPreviewSliders(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 中央大滑块
  Widget _buildMainSlider() {
    return Center(
      child: SkinnableCircularSlider(
        value: _progress,
        size: 250,
        skin: _skins[_selectedIndex],
        onChanged: (v) => setState(() => _progress = v),
      ),
    );
  }

  /// 皮肤选择卡片（横向排列）
  Widget _buildSkinSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择皮肤',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _foregroundColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_skins.length, (index) {
            final skin = _skins[index];
            final isSelected = _selectedIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == _skins.length - 1 ? 0 : 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? skin.progressGradientColors.first
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  skin.progressGradientColors.first.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      // 渐变色预览圆
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: skin.progressGradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _skinNames[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? skin.progressGradientColors.first
                              : _foregroundColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 底部三个小型预览滑块
  Widget _buildPreviewSliders() {
    const previewValues = [0.3, 0.6, 0.85];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '皮肤预览',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _foregroundColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_skins.length, (index) {
            return Column(
              children: [
                SkinnableCircularSlider(
                  value: previewValues[index],
                  size: 100,
                  skin: _skins[index],
                  showPercentText: true,
                  // 不传 onChanged，预览滑块不可交互
                ),
                const SizedBox(height: 8),
                Text(
                  _skinNames[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: _foregroundColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
