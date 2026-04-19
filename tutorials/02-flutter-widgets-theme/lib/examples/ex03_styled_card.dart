import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/styled_card.dart';

/// 第3章示例页面：展示四种风格卡片，并支持切换主色调
class StyledCardExample extends StatefulWidget {
  const StyledCardExample({super.key});

  @override
  State<StyledCardExample> createState() => _StyledCardExampleState();
}

class _StyledCardExampleState extends State<StyledCardExample> {
  /// 当前选中的主色调
  Color _primaryColor = Colors.cyanAccent;

  /// 可选的颜色列表
  static const List<Color> _colorOptions = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.amber,
    Colors.greenAccent,
    Colors.deepPurpleAccent,
    Colors.orangeAccent,
  ];

  /// 四种卡片风格的配置信息
  static const List<_CardInfo> _cardInfoList = [
    _CardInfo(
      style: CardStyle.flat,
      title: 'Flat',
      subtitle: '扁平风格',
      icon: Icons.crop_square_rounded,
    ),
    _CardInfo(
      style: CardStyle.elevated,
      title: 'Elevated',
      subtitle: 'Material 阴影',
      icon: Icons.layers_rounded,
    ),
    _CardInfo(
      style: CardStyle.glassmorphism,
      title: 'Glass',
      subtitle: '毛玻璃效果',
      icon: Icons.blur_on_rounded,
    ),
    _CardInfo(
      style: CardStyle.neon,
      title: 'Neon',
      subtitle: '霓虹发光',
      icon: Icons.flash_on_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('第3章：控件美化'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // 渐变背景，让毛玻璃效果更明显
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 卡片网格区域
              Expanded(child: _buildCardGrid()),
              // 底部颜色选择器
              _buildColorPicker(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建卡片网格
  Widget _buildCardGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _cardInfoList.length,
        itemBuilder: (context, index) {
          final info = _cardInfoList[index];
          return StyledCard(
            style: info.style,
            primaryColor: _primaryColor,
            borderRadius: 16,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('点击了 ${info.title} 卡片'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  info.icon,
                  size: 48,
                  color: info.style == CardStyle.elevated
                      ? _primaryColor
                      : Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: info.style == CardStyle.elevated
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: info.style == CardStyle.elevated
                        ? Colors.black54
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建底部颜色选择器
  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '切换主色调',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colorOptions.map((color) {
              final isSelected = color == _primaryColor;
              return GestureDetector(
                onTap: () => setState(() => _primaryColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 卡片信息数据类
class _CardInfo {
  final CardStyle style;
  final String title;
  final String subtitle;
  final IconData icon;

  const _CardInfo({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
