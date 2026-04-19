// 第7章：状态持久化 —— 用户设置页面
//
// 本示例演示了：
// - SharedPreferences 存储简单数据
// - 主题切换（亮色/暗色/跟随系统）
// - 语言选择
// - 字体大小调节
// - 设置持久化与恢复
// - RestorableProperty 系统级状态恢复
//
// 运行方式：flutter run -t lib/ch07_state_persistence.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// 第一部分：常量与键名管理
// ============================================================

/// 集中管理 SharedPreferences 的键名，避免硬编码字符串
class PrefsKeys {
  static const String themeMode = 'pref_theme_mode';
  static const String language = 'pref_language';
  static const String fontSize = 'pref_font_size';
}

/// 支持的语言选项
class LanguageOption {
  final String code;
  final String name;
  const LanguageOption(this.code, this.name);
}

const supportedLanguages = [
  LanguageOption('zh', '中文'),
  LanguageOption('en', 'English'),
  LanguageOption('ja', '日本語'),
];

// ============================================================
// 第二部分：设置管理器
// ============================================================

/// 用户设置管理器：封装 SharedPreferences 操作
class SettingsManager {
  final SharedPreferences _prefs;

  SettingsManager(this._prefs);

  // --- 主题模式 ---
  /// 获取主题模式：'light' / 'dark' / 'system'
  String get themeMode => _prefs.getString(PrefsKeys.themeMode) ?? 'system';

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(PrefsKeys.themeMode, mode);
  }

  /// 将字符串转为 ThemeMode 枚举
  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // --- 语言 ---
  /// 获取语言代码
  String get language => _prefs.getString(PrefsKeys.language) ?? 'zh';

  /// 设置语言
  Future<void> setLanguage(String lang) async {
    await _prefs.setString(PrefsKeys.language, lang);
  }

  // --- 字体大小 ---
  /// 获取字体大小（12.0 - 24.0）
  double get fontSize => _prefs.getDouble(PrefsKeys.fontSize) ?? 16.0;

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(PrefsKeys.fontSize, size);
  }

  // --- 重置所有设置 ---
  Future<void> resetAll() async {
    await _prefs.remove(PrefsKeys.themeMode);
    await _prefs.remove(PrefsKeys.language);
    await _prefs.remove(PrefsKeys.fontSize);
  }
}

// ============================================================
// 第三部分：应用入口
// ============================================================

void main() async {
  // 确保 Flutter 绑定初始化（使用异步操作前必须调用）
  WidgetsFlutterBinding.ensureInitialized();

  // 预加载 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsManager(prefs);

  runApp(Ch07PersistenceApp(settings: settings));
}

/// 应用根组件：需要是 StatefulWidget 以响应主题变化
class Ch07PersistenceApp extends StatefulWidget {
  final SettingsManager settings;
  const Ch07PersistenceApp({super.key, required this.settings});

  @override
  State<Ch07PersistenceApp> createState() => _Ch07PersistenceAppState();
}

class _Ch07PersistenceAppState extends State<Ch07PersistenceApp> {
  late ThemeMode _themeMode;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    // 从持久化存储恢复设置
    _themeMode = widget.settings.themeModeEnum;
    _fontSize = widget.settings.fontSize;
  }

  /// 更新主题模式（从设置页面回调）
  void _updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  /// 更新字体大小（从设置页面回调）
  void _updateFontSize(double size) {
    setState(() => _fontSize = size);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '状态持久化示例',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: _fontSize),
          bodyLarge: TextStyle(fontSize: _fontSize + 2),
        ),
      ),
      // 使用 restorationScopeId 启用系统级状态恢复
      restorationScopeId: 'ch07_app',
      home: SettingsPage(
        settings: widget.settings,
        onThemeModeChanged: _updateThemeMode,
        onFontSizeChanged: _updateFontSize,
      ),
    );
  }
}

// ============================================================
// 第四部分：设置页面
// ============================================================

class SettingsPage extends StatefulWidget {
  final SettingsManager settings;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<double> onFontSizeChanged;

  const SettingsPage({
    super.key,
    required this.settings,
    required this.onThemeModeChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _themeMode;
  late String _language;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    // 从 SettingsManager 加载当前设置
    _themeMode = widget.settings.themeMode;
    _language = widget.settings.language;
    _fontSize = widget.settings.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
        actions: [
          // 重置按钮
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复默认设置',
            onPressed: _resetSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题设置
          _buildSectionHeader('🎨 主题模式'),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // 语言设置
          _buildSectionHeader('🌐 语言'),
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          // 字体大小设置
          _buildSectionHeader('🔤 字体大小'),
          _buildFontSizeSlider(),
          const SizedBox(height: 24),

          // 预览区域
          _buildSectionHeader('👁️ 效果预览'),
          _buildPreviewCard(),
          const SizedBox(height: 24),

          // 当前设置信息
          _buildSectionHeader('ℹ️ 当前设置'),
          _buildSettingsInfo(),
        ],
      ),
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// 主题选择器
  Widget _buildThemeSelector() {
    return Card(
      child: RadioGroup<String>(
        groupValue: _themeMode,
        onChanged: (newValue) async {
          if (newValue == null) return;
          setState(() => _themeMode = newValue);
          await widget.settings.setThemeMode(newValue);
          switch (newValue) {
            case 'light':
              widget.onThemeModeChanged(ThemeMode.light);
            case 'dark':
              widget.onThemeModeChanged(ThemeMode.dark);
            default:
              widget.onThemeModeChanged(ThemeMode.system);
          }
        },
        child: Column(
          children: [
            RadioListTile<String>(
              value: 'system',
              title: const Text('跟随系统'),
              secondary: const Icon(Icons.settings_suggest),
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              value: 'light',
              title: const Text('亮色模式'),
              secondary: const Icon(Icons.light_mode),
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              value: 'dark',
              title: const Text('暗色模式'),
              secondary: const Icon(Icons.dark_mode),
            ),
          ],
        ),
      ),
    );
  }

  /// 语言选择器
  Widget _buildLanguageSelector() {
    return Card(
      child: RadioGroup<String>(
        groupValue: _language,
        onChanged: (newValue) async {
          if (newValue == null) return;
          setState(() => _language = newValue);
          await widget.settings.setLanguage(newValue);
          final langName = supportedLanguages
              .firstWhere((l) => l.code == newValue,
                  orElse: () => const LanguageOption('zh', '中文'))
              .name;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('语言已切换为 $langName'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Column(
          children: supportedLanguages.asMap().entries.map((entry) {
            final lang = entry.value;
            final isLast = entry.key == supportedLanguages.length - 1;
            return Column(
              children: [
                RadioListTile<String>(
                  value: lang.code,
                  title: Text(lang.name),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 字体大小滑块
  Widget _buildFontSizeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Text(
                  '${_fontSize.toInt()}px',
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
            Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              label: '${_fontSize.toInt()}px',
              onChanged: (value) {
                setState(() => _fontSize = value);
              },
              onChangeEnd: (value) async {
                // 滑块松手后才持久化（防抖策略）
                await widget.settings.setFontSize(value);
                widget.onFontSizeChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 效果预览卡片
  Widget _buildPreviewCard() {
    final languageName = supportedLanguages
        .firstWhere(
          (lang) => lang.code == _language,
          orElse: () => const LanguageOption('zh', '中文'),
        )
        .name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '这是预览文本',
              style: TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '当前字体大小为 ${_fontSize.toInt()}px，语言为$languageName。'
              '此文本用于预览设置效果。修改设置后，此处会实时更新。',
              style: TextStyle(fontSize: _fontSize),
            ),
            const SizedBox(height: 8),
            Text(
              'The quick brown fox jumps over the lazy dog.',
              style: TextStyle(
                fontSize: _fontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 当前设置信息
  Widget _buildSettingsInfo() {
    final themeName = switch (_themeMode) {
      'light' => '亮色模式',
      'dark' => '暗色模式',
      _ => '跟随系统',
    };

    final languageName = supportedLanguages
        .firstWhere(
          (lang) => lang.code == _language,
          orElse: () => const LanguageOption('zh', '中文'),
        )
        .name;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('主题', themeName),
            const Divider(),
            _buildInfoRow('语言', languageName),
            const Divider(),
            _buildInfoRow('字体大小', '${_fontSize.toInt()}px'),
            const Divider(),
            _buildInfoRow('存储方式', 'SharedPreferences'),
          ],
        ),
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// 重置所有设置
  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认设置'),
        content: const Text('确定要恢复所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.settings.resetAll();
      setState(() {
        _themeMode = 'system';
        _language = 'zh';
        _fontSize = 16.0;
      });
      widget.onThemeModeChanged(ThemeMode.system);
      widget.onFontSizeChanged(16.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已恢复为默认值')),
        );
      }
    }
  }
}

// ============================================================
// 第五部分：使用 RestorableProperty 的示例页面
// ============================================================

/// 演示 RestorableProperty：系统级状态恢复
/// 当系统回收 App 内存后再恢复时，状态会自动保存和恢复
class RestorableCounterPage extends StatefulWidget {
  const RestorableCounterPage({super.key});

  @override
  State<RestorableCounterPage> createState() => _RestorableCounterPageState();
}

class _RestorableCounterPageState extends State<RestorableCounterPage>
    with RestorationMixin {
  // 可恢复的属性
  final RestorableInt _counter = RestorableInt(0);
  final RestorableString _note = RestorableString('');
  final RestorableBool _isImportant = RestorableBool(false);

  @override
  String? get restorationId => 'restorable_counter_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // 注册需要恢复的属性
    registerForRestoration(_counter, 'counter');
    registerForRestoration(_note, 'note');
    registerForRestoration(_isImportant, 'is_important');
  }

  @override
  void dispose() {
    _counter.dispose();
    _note.dispose();
    _isImportant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restorable 示例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_counter.value}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('重要标记'),
              value: _isImportant.value,
              onChanged: (value) {
                setState(() => _isImportant.value = value ?? false);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _counter.value++);
              },
              child: const Text('增加'),
            ),
          ],
        ),
      ),
    );
  }
}
