import 'package:flutter/material.dart';

/// 第6章示例：深色 / 浅色主题切换
///
/// 使用 [ValueNotifier] 管理 [ThemeMode]，
/// 通过 AnimatedTheme 在页面级别实现平滑的亮色/暗色切换。
/// 不嵌套 MaterialApp，而是用 Theme + AnimatedTheme 局部切换。
class DarkLightExample extends StatefulWidget {
  const DarkLightExample({super.key});

  @override
  State<DarkLightExample> createState() => _DarkLightExampleState();
}

class _DarkLightExampleState extends State<DarkLightExample> {
  /// 主题模式管理
  final ValueNotifier<ThemeMode> _themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// 种子色
  static const Color _seedColor = Colors.indigo;

  /// 底部导航栏当前索引
  int _navIndex = 0;

  /// 根据亮度生成对应的 ThemeData
  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  /// 根据 ThemeMode 和系统亮度计算实际 Brightness
  Brightness _resolveBrightness(
      ThemeMode mode, Brightness platformBrightness) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return platformBrightness;
    }
  }

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取系统亮度，用于 ThemeMode.system 时判断
    final platformBrightness = MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        final brightness = _resolveBrightness(mode, platformBrightness);
        final theme = _buildTheme(brightness);

        // AnimatedTheme 实现平滑的主题过渡动画
        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Builder(
            builder: (context) {
              // Builder 确保子树中 Theme.of(context) 取到 AnimatedTheme 的值
              final currentTheme = Theme.of(context);
              final colorScheme = currentTheme.colorScheme;
              final textTheme = currentTheme.textTheme;

              return Scaffold(
                appBar: AppBar(
                  title: const Text('第6章：深色/浅色切换'),
                  backgroundColor: colorScheme.inversePrimary,
                  actions: [
                    // ☀️ 亮色
                    IconButton(
                      tooltip: '亮色模式',
                      icon: const Text('☀️', style: TextStyle(fontSize: 20)),
                      onPressed: () => _themeMode.value = ThemeMode.light,
                    ),
                    // 🌙 暗色
                    IconButton(
                      tooltip: '暗色模式',
                      icon: const Text('🌙', style: TextStyle(fontSize: 20)),
                      onPressed: () => _themeMode.value = ThemeMode.dark,
                    ),
                    // 📱 跟随系统
                    IconButton(
                      tooltip: '跟随系统',
                      icon: const Text('📱', style: TextStyle(fontSize: 20)),
                      onPressed: () => _themeMode.value = ThemeMode.system,
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── 当前状态信息 ──
                    _buildModeIndicator(mode, brightness, textTheme),
                    const SizedBox(height: 24),

                    // ── 文字展示 ──
                    _buildTextSection(textTheme),
                    const SizedBox(height: 24),

                    // ── Card + ListTile ──
                    _buildCardSection(colorScheme),
                    const SizedBox(height: 24),

                    // ── 按钮展示 ──
                    _buildButtonSection(),
                    const SizedBox(height: 24),

                    // ── TextField ──
                    _buildTextFieldSection(),
                    const SizedBox(height: 24),

                    // ── 色彩对比展示 ──
                    _buildColorCompare(colorScheme, textTheme),
                    const SizedBox(height: 16),
                  ],
                ),
                // 底部导航栏
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _navIndex = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '首页',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore),
                      label: '发现',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: '我的',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 当前模式指示器
  Widget _buildModeIndicator(
      ThemeMode mode, Brightness brightness, TextTheme textTheme) {
    final modeLabels = {
      ThemeMode.light: '☀️ 亮色模式',
      ThemeMode.dark: '🌙 暗色模式',
      ThemeMode.system: '📱 跟随系统',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              brightness == Brightness.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modeLabels[mode] ?? '',
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    '实际亮度: ${brightness == Brightness.dark ? "暗色" : "亮色"}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 文字排版展示
  Widget _buildTextSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Headline Small', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '这是一段正文内容。深色模式下，文字颜色会自动调整以保持良好的对比度和可读性。'
          'Material 3 使用 ColorScheme 中的 onSurface 作为默认文字颜色，'
          '确保在任何亮度下都有最佳阅读体验。',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '这是一段辅助说明文字，使用 bodySmall 样式。',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Card + ListTile 展示
  Widget _buildCardSection(ColorScheme colorScheme) {
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.palette,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('主题配色演示'),
                subtitle: const Text('观察卡片在不同主题下的 surface 和阴影变化'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.brightness_6,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Surface Tint'),
                subtitle: const Text('Material 3 用色调叠加表示 elevation 层级'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 不同 elevation 的 Card 对比
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Elevation 0',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Elevation 2',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Elevation 6',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 按钮展示
  Widget _buildButtonSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.thumb_up),
          label: const Text('Elevated'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Filled'),
        ),
        FilledButton.tonal(
          onPressed: () {},
          child: const Text('Tonal'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Text'),
        ),
      ],
    );
  }

  /// TextField 展示
  Widget _buildTextFieldSection() {
    return const Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '输入框示例',
            hintText: '在深色和浅色下观察边框和填充色的变化',
            prefixIcon: Icon(Icons.edit),
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Filled 样式',
            hintText: '填充式输入框',
            filled: true,
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// 色彩对比展示——同时显示亮色和暗色的关键颜色
  Widget _buildColorCompare(ColorScheme colorScheme, TextTheme textTheme) {
    final entries = <_ColorEntry>[
      _ColorEntry('primary', colorScheme.primary),
      _ColorEntry('secondary', colorScheme.secondary),
      _ColorEntry('tertiary', colorScheme.tertiary),
      _ColorEntry('surface', colorScheme.surface),
      _ColorEntry('error', colorScheme.error),
      _ColorEntry('outline', colorScheme.outline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('当前 ColorScheme 关键色', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries.map((e) {
            final textColor =
                ThemeData.estimateBrightnessForColor(e.color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black;
            return Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: e.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  Text(
                    e.name,
                    style: TextStyle(fontSize: 10, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${e.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 8,
                      color: textColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 色板条目
class _ColorEntry {
  final String name;
  final Color color;
  const _ColorEntry(this.name, this.color);
}
