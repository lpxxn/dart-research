import 'package:flutter/material.dart';

/// 第9章示例：动画主题切换
///
/// 演示如何使用 AnimatedTheme 在多套主题之间平滑过渡。
/// 预定义 3 套主题（科技蓝、暖阳橙、森林绿），切换时所有颜色平滑动画。
class AnimatedThemeExample extends StatefulWidget {
  const AnimatedThemeExample({super.key});

  @override
  State<AnimatedThemeExample> createState() => _AnimatedThemeExampleState();
}

class _AnimatedThemeExampleState extends State<AnimatedThemeExample> {
  /// 当前选中的主题索引
  int _selectedIndex = 0;

  /// 3 套预定义主题
  static final List<_ThemeOption> _themeOptions = [
    _ThemeOption(
      name: '科技蓝',
      icon: Icons.computer,
      description: '冷色调 · 专业可靠',
      seedColor: Colors.blue,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    ),
    _ThemeOption(
      name: '暖阳橙',
      icon: Icons.wb_sunny,
      description: '暖色调 · 活力友好',
      seedColor: Colors.orange,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    ),
    _ThemeOption(
      name: '森林绿',
      icon: Icons.park,
      description: '自然色调 · 清新环保',
      seedColor: Colors.green,
      themeData: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
    ),
  ];

  /// 当前主题
  ThemeData get _currentTheme => _themeOptions[_selectedIndex].themeData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第9章：动画主题切换')),
      body: AnimatedTheme(
        data: _currentTheme,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        child: Builder(
          builder: (context) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- 主题选择卡片（横向滑动） ----
                    _buildThemeSelector(context),
                    const SizedBox(height: 24),

                    // ---- 组件展示区 ----
                    _buildComponentShowcase(context),
                    const SizedBox(height: 24),

                    // ---- 颜色对比块 ----
                    _buildColorBlocks(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 顶部主题选择卡片（横向滑动）
  Widget _buildThemeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择主题',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _themeOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final option = _themeOptions[index];
              final isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: option.seedColor.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option.icon,
                        size: 28,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer.withAlpha(180)
                              : colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 组件展示区：Card、Button、TextField、Switch
  Widget _buildComponentShowcase(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '组件预览',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // 示例卡片
        Card(
          color: colorScheme.surfaceContainerLow,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        _themeOptions[_selectedIndex].icon,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _themeOptions[_selectedIndex].name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _themeOptions[_selectedIndex].description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 输入框
                TextField(
                  decoration: InputDecoration(
                    labelText: '搜索内容',
                    hintText: '输入关键词...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 16),

                // 按钮行
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('收藏'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send),
                        label: const Text('发送'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Switch 行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '开启通知',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    Switch(
                      value: true,
                      onChanged: (_) {},
                    ),
                  ],
                ),

                // 进度条
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 底部颜色对比块
  Widget _buildColorBlocks(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 展示的颜色列表
    final colorEntries = <_ColorEntry>[
      _ColorEntry('primary', colorScheme.primary, colorScheme.onPrimary),
      _ColorEntry(
        'secondary',
        colorScheme.secondary,
        colorScheme.onSecondary,
      ),
      _ColorEntry(
        'tertiary',
        colorScheme.tertiary,
        colorScheme.onTertiary,
      ),
      _ColorEntry(
        'surface',
        colorScheme.surface,
        colorScheme.onSurface,
      ),
      _ColorEntry(
        'primaryContainer',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      _ColorEntry(
        'secondaryContainer',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      _ColorEntry(
        'tertiaryContainer',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      _ColorEntry(
        'error',
        colorScheme.error,
        colorScheme.onError,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '颜色对比',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '切换主题时观察颜色的平滑过渡效果',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        // 使用 Wrap 排列颜色块，自动换行
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorEntries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: (MediaQuery.of(context).size.width - 56) / 4,
              height: 70,
              decoration: BoxDecoration(
                color: entry.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: entry.color.withAlpha(60),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  entry.name,
                  style: TextStyle(
                    color: entry.onColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// 内部数据类
// ============================================================================

/// 主题选项
class _ThemeOption {
  final String name;
  final IconData icon;
  final String description;
  final Color seedColor;
  final ThemeData themeData;

  const _ThemeOption({
    required this.name,
    required this.icon,
    required this.description,
    required this.seedColor,
    required this.themeData,
  });
}

/// 颜色展示条目
class _ColorEntry {
  final String name;
  final Color color;
  final Color onColor;

  const _ColorEntry(this.name, this.color, this.onColor);
}
