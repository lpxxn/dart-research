import 'package:flutter/material.dart';

/// 第5章示例：ThemeData 全局主题
///
/// 演示如何使用 ColorScheme.fromSeed 从种子色生成完整主题，
/// 并展示各种 Material 组件在该主题下的效果。
class ThemeBasicExample extends StatefulWidget {
  const ThemeBasicExample({super.key});

  @override
  State<ThemeBasicExample> createState() => _ThemeBasicExampleState();
}

class _ThemeBasicExampleState extends State<ThemeBasicExample> {
  /// 可选的种子颜色列表
  static const List<_SeedColorOption> _seedOptions = [
    _SeedColorOption('蓝', Colors.blue),
    _SeedColorOption('紫', Colors.purple),
    _SeedColorOption('绿', Colors.green),
    _SeedColorOption('橙', Colors.orange),
    _SeedColorOption('红', Colors.red),
  ];

  /// 当前选中的种子色索引
  int _selectedIndex = 0;

  /// 根据当前种子色生成 ColorScheme
  ColorScheme get _currentScheme => ColorScheme.fromSeed(
        seedColor: _seedOptions[_selectedIndex].color,
        brightness: Brightness.light,
      );

  // 用于 Radio 演示的分组值
  int _radioValue = 0;

  // 用于 Switch / Checkbox 演示
  bool _switchValue = true;
  bool _checkboxValue = true;

  @override
  Widget build(BuildContext context) {
    final scheme = _currentScheme;

    // 用局部 Theme 包裹，不影响全局主题
    return Theme(
      data: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
      ),
      // Builder 确保子树中 Theme.of(context) 拿到的是上面的 Theme
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('第5章：ThemeData 全局主题'),
              backgroundColor: theme.colorScheme.inversePrimary,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 种子色选择器 ──
                _buildSeedColorSelector(),
                const SizedBox(height: 24),

                // ── 按钮展示 ──
                _buildSectionTitle(context, '按钮'),
                const SizedBox(height: 8),
                _buildButtons(),
                const SizedBox(height: 24),

                // ── Card + ListTile ──
                _buildSectionTitle(context, 'Card + ListTile'),
                const SizedBox(height: 8),
                _buildCard(),
                const SizedBox(height: 24),

                // ── TextField ──
                _buildSectionTitle(context, 'TextField'),
                const SizedBox(height: 8),
                _buildTextField(),
                const SizedBox(height: 24),

                // ── Chip / Badge ──
                _buildSectionTitle(context, 'Chip / Badge'),
                const SizedBox(height: 8),
                _buildChips(),
                const SizedBox(height: 24),

                // ── Switch / Checkbox / Radio ──
                _buildSectionTitle(context, 'Switch / Checkbox / Radio'),
                const SizedBox(height: 8),
                _buildToggles(),
                const SizedBox(height: 24),

                // ── 色板展示 ──
                _buildSectionTitle(context, 'ColorScheme 色板'),
                const SizedBox(height: 8),
                _buildColorPalette(scheme),
                const SizedBox(height: 80), // 为 FAB 留出空间
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  /// 构建种子色选择器——一排可点击的圆形色块
  Widget _buildSeedColorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_seedOptions.length, (index) {
        final option = _seedOptions[index];
        final isSelected = index == _selectedIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: option.color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  option.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 区域标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// 一排按钮：ElevatedButton, OutlinedButton, TextButton
  Widget _buildButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Text'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Filled'),
        ),
        FilledButton.tonal(
          onPressed: () {},
          child: const Text('Tonal'),
        ),
      ],
    );
  }

  /// Card + ListTile 示例
  Widget _buildCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题演示卡片'),
            subtitle: const Text('当前种子色：${''}'
                '观察颜色如何影响各个组件'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(
                '种子色: ${_seedOptions[_selectedIndex].label}'),
            subtitle: Text(
              '#${_seedOptions[_selectedIndex].color.toARGB32().toRadixString(16).toUpperCase()}',
            ),
          ),
        ],
      ),
    );
  }

  /// TextField 示例
  Widget _buildTextField() {
    return const Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '标签文字',
            hintText: '请输入内容...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Filled 样式',
            hintText: '请输入内容...',
            filled: true,
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Chip / Badge 示例
  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const Chip(label: Text('普通 Chip')),
        ActionChip(
          label: const Text('Action Chip'),
          avatar: const Icon(Icons.star, size: 18),
          onPressed: () {},
        ),
        FilterChip(
          label: const Text('Filter Chip'),
          selected: true,
          onSelected: (_) {},
        ),
        InputChip(
          label: const Text('Input Chip'),
          onDeleted: () {},
        ),
        // Badge 展示：包裹在图标上
        Badge(
          label: const Text('3'),
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  /// Switch / Checkbox / Radio 示例
  Widget _buildToggles() {
    return Row(
      children: [
        // Switch
        Switch(
          value: _switchValue,
          onChanged: (v) => setState(() => _switchValue = v),
        ),
        const SizedBox(width: 16),

        // Checkbox
        Checkbox(
          value: _checkboxValue,
          onChanged: (v) => setState(() => _checkboxValue = v ?? false),
        ),
        const SizedBox(width: 16),

        // Radio 组
        RadioGroup<int>(
          groupValue: _radioValue,
          onChanged: (v) => setState(() => _radioValue = v ?? 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<int>(value: 0),
              Radio<int>(value: 1),
              Radio<int>(value: 2),
            ],
          ),
        ),
      ],
    );
  }

  /// 展示当前 ColorScheme 的所有颜色角色
  Widget _buildColorPalette(ColorScheme scheme) {
    // 要展示的颜色角色列表
    final entries = <_ColorEntry>[
      _ColorEntry('primary', scheme.primary),
      _ColorEntry('onPrimary', scheme.onPrimary),
      _ColorEntry('primaryContainer', scheme.primaryContainer),
      _ColorEntry('secondary', scheme.secondary),
      _ColorEntry('onSecondary', scheme.onSecondary),
      _ColorEntry('secondaryContainer', scheme.secondaryContainer),
      _ColorEntry('tertiary', scheme.tertiary),
      _ColorEntry('surface', scheme.surface),
      _ColorEntry('onSurface', scheme.onSurface),
      _ColorEntry('error', scheme.error),
      _ColorEntry('onError', scheme.onError),
      _ColorEntry('outline', scheme.outline),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: entries.map((entry) {
        // 判断色块上的文字应该用白色还是黑色
        final textColor =
            ThemeData.estimateBrightnessForColor(entry.color) == Brightness.dark
                ? Colors.white
                : Colors.black;
        return Column(
          children: [
            Container(
              width: 64,
              height: 40,
              decoration: BoxDecoration(
                color: entry.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${entry.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(fontSize: 8, color: textColor),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 64,
              child: Text(
                entry.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// 种子色选项
class _SeedColorOption {
  final String label;
  final Color color;
  const _SeedColorOption(this.label, this.color);
}

/// 色板条目
class _ColorEntry {
  final String name;
  final Color color;
  const _ColorEntry(this.name, this.color);
}
