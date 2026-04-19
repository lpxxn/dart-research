import 'package:flutter/material.dart';

/// 第二章：Flutter 原生状态管理方案
/// 本文件演示了 InheritedWidget 主题切换 和 ValueNotifier 计数器

void main() => runApp(const Ch02App());

// ============================================================================
// 应用入口
// ============================================================================

class Ch02App extends StatefulWidget {
  const Ch02App({super.key});

  @override
  State<Ch02App> createState() => _Ch02AppState();
}

class _Ch02AppState extends State<Ch02App> {
  // 主题配置状态
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  double _fontSize = 16.0;

  /// 切换亮色/暗色主题
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  /// 切换主题色
  void _changePrimaryColor(Color color) {
    setState(() {
      _primaryColor = color;
    });
  }

  /// 调整字体大小
  void _changeFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 用自定义 InheritedWidget 包裹整个应用，向下共享主题配置
    return ThemeSettingsWidget(
      isDarkMode: _isDarkMode,
      primaryColor: _primaryColor,
      fontSize: _fontSize,
      onToggleTheme: _toggleTheme,
      onChangePrimaryColor: _changePrimaryColor,
      onChangeFontSize: _changeFontSize,
      child: MaterialApp(
        title: '第二章：原生状态管理',
        debugShowCheckedModeBanner: false,
        theme: _isDarkMode
            ? ThemeData.dark(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: _primaryColor,
                  secondary: _primaryColor,
                ),
              )
            : ThemeData.light(useMaterial3: true).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _primaryColor,
                  secondary: _primaryColor,
                ),
              ),
        home: const MainScreen(),
      ),
    );
  }
}

// ============================================================================
// 自定义 InheritedWidget：主题配置共享
// ============================================================================

/// ThemeSettingsWidget 是一个 InheritedWidget，用于在组件树中共享主题配置。
///
/// 原理：
/// 1. InheritedWidget 是不可变的，数据存储在其字段中
/// 2. 子孙组件通过 [of] 方法获取最近的实例
/// 3. 调用 of 时会自动注册依赖关系
/// 4. 当 InheritedWidget 重建时，[updateShouldNotify] 决定是否通知依赖者
class ThemeSettingsWidget extends InheritedWidget {
  /// 是否为暗色模式
  final bool isDarkMode;

  /// 主题主色调
  final Color primaryColor;

  /// 全局字体大小
  final double fontSize;

  /// 切换主题的回调
  final VoidCallback onToggleTheme;

  /// 切换主题色的回调
  final ValueChanged<Color> onChangePrimaryColor;

  /// 调整字体大小的回调
  final ValueChanged<double> onChangeFontSize;

  const ThemeSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.primaryColor,
    required this.fontSize,
    required this.onToggleTheme,
    required this.onChangePrimaryColor,
    required this.onChangeFontSize,
    required super.child,
  });

  /// 从上下文中获取最近的 ThemeSettingsWidget 实例。
  /// 调用此方法会自动建立依赖关系，当主题变化时消费者会自动 rebuild。
  static ThemeSettingsWidget of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ThemeSettingsWidget>();
    assert(widget != null, '未找到 ThemeSettingsWidget，请确保在组件树上层提供');
    return widget!;
  }

  @override
  bool updateShouldNotify(ThemeSettingsWidget oldWidget) {
    // 任一属性变化都需要通知所有依赖者重建
    return isDarkMode != oldWidget.isDarkMode ||
        primaryColor != oldWidget.primaryColor ||
        fontSize != oldWidget.fontSize;
  }
}

// ============================================================================
// 主界面：使用 BottomNavigationBar 在不同示例间切换
// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 页面列表
  static const List<Widget> _pages = [
    InheritedWidgetDemo(),
    ValueNotifierDemo(),
    ChangeNotifierDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: 'InheritedWidget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'ValueNotifier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'ChangeNotifier',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 示例 1：InheritedWidget 实现主题切换
// ============================================================================

class InheritedWidgetDemo extends StatelessWidget {
  const InheritedWidgetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // 通过 ThemeSettingsWidget.of(context) 获取主题配置
    final themeSettings = ThemeSettingsWidget.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('InheritedWidget 主题切换'),
        actions: [
          // 主题切换按钮
          IconButton(
            icon: Icon(
              themeSettings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeSettings.onToggleTheme,
            tooltip: '切换亮色/暗色主题',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前主题状态显示
            _buildThemeInfoCard(context, themeSettings),
            const SizedBox(height: 16),

            // 主题色选择器
            _buildColorPicker(themeSettings),
            const SizedBox(height: 16),

            // 字体大小调节
            _buildFontSizeSlider(themeSettings),
            const SizedBox(height: 16),

            // 预览区域 —— 此组件也通过 InheritedWidget 获取主题
            const ThemePreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeInfoCard(
    BuildContext context,
    ThemeSettingsWidget themeSettings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前主题信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('模式: ${themeSettings.isDarkMode ? "暗色" : "亮色"}'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('主题色: '),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: themeSettings.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('字体大小: ${themeSettings.fontSize.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(ThemeSettingsWidget themeSettings) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择主题色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: colors.map((color) {
                final isSelected = themeSettings.primaryColor == color;
                return GestureDetector(
                  onTap: () => themeSettings.onChangePrimaryColor(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(ThemeSettingsWidget themeSettings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('字体大小: ${themeSettings.fontSize.toStringAsFixed(1)}'),
            Slider(
              value: themeSettings.fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              label: themeSettings.fontSize.toStringAsFixed(1),
              onChanged: themeSettings.onChangeFontSize,
            ),
          ],
        ),
      ),
    );
  }
}

/// 主题预览卡片 —— 演示子组件如何通过 InheritedWidget 获取主题配置
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 这里再次通过 of 获取主题，验证跨组件数据共享
    final themeSettings = ThemeSettingsWidget.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预览效果',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '这段文字的大小由 InheritedWidget 控制',
              style: TextStyle(fontSize: themeSettings.fontSize),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeSettings.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeSettings.primaryColor.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '主题色背景区域\n'
                '当前模式: ${themeSettings.isDarkMode ? "暗色" : "亮色"}',
                style: TextStyle(
                  fontSize: themeSettings.fontSize,
                  color: themeSettings.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 示例 2：ValueNotifier + ValueListenableBuilder 实现计数器
// ============================================================================

class ValueNotifierDemo extends StatefulWidget {
  const ValueNotifierDemo({super.key});

  @override
  State<ValueNotifierDemo> createState() => _ValueNotifierDemoState();
}

class _ValueNotifierDemoState extends State<ValueNotifierDemo> {
  /// 计数器，使用 ValueNotifier 管理单一 int 值
  final ValueNotifier<int> _counter = ValueNotifier<int>(0);

  /// 步进值，演示多个 ValueNotifier 独立管理不同状态
  final ValueNotifier<int> _stepSize = ValueNotifier<int>(1);

  @override
  void dispose() {
    // 释放资源，避免内存泄漏
    _counter.dispose();
    _stepSize.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ValueNotifier 计数器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _counter.value = 0,
            tooltip: '重置计数器',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 计数器显示 —— 只有这个区域会在计数变化时 rebuild
              ValueListenableBuilder<int>(
                valueListenable: _counter,
                builder: (context, count, child) {
                  return Column(
                    children: [
                      Text(
                        '当前计数',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$count',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      // child 参数演示：这个 Text 不会随 count 变化而 rebuild
                      child!,
                    ],
                  );
                },
                // 不依赖 count 的子组件放在 child 中优化性能
                child: Text(
                  '(使用 ValueListenableBuilder 实现精确重建)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 32),

              // 步进值选择 —— 独立的 ValueListenableBuilder
              ValueListenableBuilder<int>(
                valueListenable: _stepSize,
                builder: (context, step, child) {
                  return Column(
                    children: [
                      Text('步进值: $step'),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 10, label: Text('10')),
                        ],
                        selected: {step},
                        onSelectionChanged: (values) {
                          _stepSize.value = values.first;
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'decrement',
                    onPressed: () => _counter.value -= _stepSize.value,
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'increment',
                    onPressed: () => _counter.value += _stepSize.value,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 示例 3：ChangeNotifier + ListenableBuilder 实现用户资料管理
// ============================================================================

/// 用户资料 ChangeNotifier —— 管理多字段的复杂状态
class UserProfileNotifier extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _bio = '';
  bool _isEditing = false;

  String get name => _name;
  String get email => _email;
  String get bio => _bio;
  bool get isEditing => _isEditing;
  bool get hasData => _name.isNotEmpty;

  /// 加载用户资料（模拟异步请求）
  Future<void> loadProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _name = '张三';
    _email = 'zhangsan@example.com';
    _bio = 'Flutter 开发者，热爱开源';
    notifyListeners();
  }

  /// 切换编辑模式
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  /// 更新字段
  void updateName(String name) {
    _name = name;
    notifyListeners();
  }

  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void updateBio(String bio) {
    _bio = bio;
    notifyListeners();
  }

  /// 重置所有数据
  void reset() {
    _name = '';
    _email = '';
    _bio = '';
    _isEditing = false;
    notifyListeners();
  }
}

class ChangeNotifierDemo extends StatefulWidget {
  const ChangeNotifierDemo({super.key});

  @override
  State<ChangeNotifierDemo> createState() => _ChangeNotifierDemoState();
}

class _ChangeNotifierDemoState extends State<ChangeNotifierDemo> {
  final UserProfileNotifier _profileNotifier = UserProfileNotifier();

  @override
  void dispose() {
    _profileNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChangeNotifier 用户资料'),
        actions: [
          // 使用 ListenableBuilder 让按钮根据状态变化
          ListenableBuilder(
            listenable: _profileNotifier,
            builder: (context, child) {
              if (!_profileNotifier.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  _profileNotifier.isEditing ? Icons.check : Icons.edit,
                ),
                onPressed: _profileNotifier.toggleEditing,
                tooltip: _profileNotifier.isEditing ? '完成编辑' : '编辑资料',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _profileNotifier,
        builder: (context, child) {
          if (!_profileNotifier.hasData) {
            // 未加载数据时显示加载按钮
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('点击按钮加载用户资料'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _profileNotifier.loadProfile,
                    icon: const Icon(Icons.download),
                    label: const Text('加载资料'),
                  ),
                ],
              ),
            );
          }

          // 已加载数据时显示资料卡片
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildInfoSection(context),
                const SizedBox(height: 16),
                // 重置按钮
                OutlinedButton.icon(
                  onPressed: _profileNotifier.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置数据'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _profileNotifier.name.isNotEmpty
                    ? _profileNotifier.name[0]
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profileNotifier.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileNotifier.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('详细信息', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: '姓名',
              value: _profileNotifier.name,
              onChanged: _profileNotifier.isEditing
                  ? _profileNotifier.updateName
                  : null,
            ),
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: '邮箱',
              value: _profileNotifier.email,
              onChanged: _profileNotifier.isEditing
                  ? _profileNotifier.updateEmail
                  : null,
            ),
            _buildInfoRow(
              context,
              icon: Icons.info_outline,
              label: '简介',
              value: _profileNotifier.bio,
              onChanged: _profileNotifier.isEditing
                  ? _profileNotifier.updateBio
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: onChanged != null
                ? TextFormField(
                    initialValue: value,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
}
