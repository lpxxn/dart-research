import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 第四章：本地存储示例
/// 使用 SharedPreferences 演示本地数据的持久化存储

void main() => runApp(const Ch04App());

// ============================================================
// 存储服务：封装 SharedPreferences 的读写操作
// ============================================================

class StorageService {
  static const String keyUsername = 'username';
  static const String keyThemeMode = 'theme_mode'; // 'light', 'dark', 'system'
  static const String keyFontSize = 'font_size';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyLoginCount = 'login_count';
  static const String keyTags = 'tags';

  /// 获取 SharedPreferences 实例
  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  // ---------- 用户名 ----------

  Future<String> getUsername() async {
    final prefs = await _getPrefs();
    return prefs.getString(keyUsername) ?? '';
  }

  Future<void> setUsername(String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(keyUsername, value);
  }

  // ---------- 主题模式 ----------

  Future<String> getThemeMode() async {
    final prefs = await _getPrefs();
    return prefs.getString(keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(keyThemeMode, value);
  }

  // ---------- 字体大小 ----------

  Future<double> getFontSize() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(keyFontSize) ?? 16.0;
  }

  Future<void> setFontSize(double value) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(keyFontSize, value);
  }

  // ---------- 通知开关 ----------

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(keyNotificationsEnabled, value);
  }

  // ---------- 登录次数 ----------

  Future<int> getLoginCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(keyLoginCount) ?? 0;
  }

  Future<void> setLoginCount(int value) async {
    final prefs = await _getPrefs();
    await prefs.setInt(keyLoginCount, value);
  }

  // ---------- 标签列表 ----------

  Future<List<String>> getTags() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(keyTags) ?? <String>[];
  }

  Future<void> setTags(List<String> value) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(keyTags, value);
  }

  // ---------- 清除所有数据 ----------

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}

// ============================================================
// 根组件：根据主题模式切换亮/暗主题
// ============================================================

class Ch04App extends StatefulWidget {
  const Ch04App({super.key});

  @override
  State<Ch04App> createState() => _Ch04AppState();
}

class _Ch04AppState extends State<Ch04App> {
  ThemeMode _themeMode = ThemeMode.system;

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '本地存储示例',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: SettingsPage(onThemeModeChanged: _onThemeModeChanged),
    );
  }
}

// ============================================================
// 设置页面：展示并编辑各项偏好设置
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onThemeModeChanged});

  /// 主题模式变更回调，通知根组件切换主题
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();

  bool _isLoading = true;

  // 各设置项的当前值
  late TextEditingController _usernameController;
  String _themeMode = 'system';
  double _fontSize = 16.0;
  bool _notificationsEnabled = true;
  int _loginCount = 0;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadPreferences();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// 启动时从本地存储加载所有偏好
  Future<void> _loadPreferences() async {
    final username = await _storage.getUsername();
    final themeMode = await _storage.getThemeMode();
    final fontSize = await _storage.getFontSize();
    final notificationsEnabled = await _storage.getNotificationsEnabled();
    final loginCount = await _storage.getLoginCount();
    final tags = await _storage.getTags();

    if (!mounted) return;

    setState(() {
      _usernameController.text = username;
      _themeMode = themeMode;
      _fontSize = fontSize;
      _notificationsEnabled = notificationsEnabled;
      _loginCount = loginCount;
      _tags = tags;
      _isLoading = false;
    });

    // 同步主题模式到根组件
    widget.onThemeModeChanged(_toThemeMode(themeMode));
  }

  /// 字符串转 ThemeMode 枚举
  ThemeMode _toThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// 显示保存成功的提示
  void _showSavedSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------- 各设置项的保存方法 --------------------

  Future<void> _saveUsername(String value) async {
    await _storage.setUsername(value);
    _showSavedSnackBar('用户名已保存');
  }

  Future<void> _saveThemeMode(String value) async {
    setState(() => _themeMode = value);
    await _storage.setThemeMode(value);
    widget.onThemeModeChanged(_toThemeMode(value));
    _showSavedSnackBar('主题已切换');
  }

  Future<void> _saveFontSize(double value) async {
    setState(() => _fontSize = value);
    await _storage.setFontSize(value);
    _showSavedSnackBar('字体大小已保存：${value.toStringAsFixed(1)}');
  }

  Future<void> _saveNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _storage.setNotificationsEnabled(value);
    _showSavedSnackBar(value ? '通知已开启' : '通知已关闭');
  }

  Future<void> _incrementLoginCount() async {
    final newCount = _loginCount + 1;
    setState(() => _loginCount = newCount);
    await _storage.setLoginCount(newCount);
    _showSavedSnackBar('模拟登录成功，当前第 $newCount 次');
  }

  Future<void> _addTag(String tag) async {
    if (tag.isEmpty || _tags.contains(tag)) return;
    final updated = [..._tags, tag];
    setState(() => _tags = updated);
    await _storage.setTags(updated);
    _showSavedSnackBar('标签「$tag」已添加');
  }

  Future<void> _removeTag(String tag) async {
    final updated = _tags.where((t) => t != tag).toList();
    setState(() => _tags = updated);
    await _storage.setTags(updated);
    _showSavedSnackBar('标签「$tag」已移除');
  }

  Future<void> _clearAll() async {
    await _storage.clearAll();
    if (!mounted) return;
    setState(() {
      _usernameController.clear();
      _themeMode = 'system';
      _fontSize = 16.0;
      _notificationsEnabled = true;
      _loginCount = 0;
      _tags = [];
    });
    widget.onThemeModeChanged(ThemeMode.system);
    _showSavedSnackBar('所有数据已清除');
  }

  // -------------------- 构建界面 --------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionHeader('用户信息', Icons.person),
                _buildUsernameSection(),
                const SizedBox(height: 20),
                _buildSectionHeader('主题设置', Icons.palette),
                _buildThemeSection(colorScheme),
                const SizedBox(height: 20),
                _buildSectionHeader('字体大小', Icons.format_size),
                _buildFontSizeSection(colorScheme),
                const SizedBox(height: 20),
                _buildSectionHeader('通知设置', Icons.notifications),
                _buildNotificationSection(),
                const SizedBox(height: 20),
                _buildSectionHeader('登录次数', Icons.login),
                _buildLoginCountSection(colorScheme),
                const SizedBox(height: 20),
                _buildSectionHeader('标签管理', Icons.label),
                _buildTagsSection(colorScheme),
                const SizedBox(height: 32),
                _buildClearButton(colorScheme),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  /// 分区标题
  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 用户名输入框
  Widget _buildUsernameSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            hintText: '请输入用户名',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_circle),
          ),
          onChanged: _saveUsername,
        ),
      ),
    );
  }

  /// 主题切换（SegmentedButton）
  Widget _buildThemeSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'light', label: Text('浅色'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: 'system', label: Text('跟随系统'), icon: Icon(Icons.settings_suggest)),
                ButtonSegment(value: 'dark', label: Text('深色'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {_themeMode},
              onSelectionChanged: (selected) => _saveThemeMode(selected.first),
            ),
            const SizedBox(height: 12),
            Text(
              '当前主题：${_themeModeLabel(_themeMode)}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      default:
        return '跟随系统';
    }
  }

  /// 字体大小滑块及预览
  Widget _buildFontSizeSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 24,
                    label: _fontSize.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _fontSize = value),
                    onChangeEnd: _saveFontSize,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '预览文字：字体大小 ${_fontSize.toStringAsFixed(1)}',
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 通知开关
  Widget _buildNotificationSection() {
    return Card(
      child: SwitchListTile(
        title: const Text('启用通知'),
        subtitle: Text(_notificationsEnabled ? '通知已开启' : '通知已关闭'),
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
        ),
        value: _notificationsEnabled,
        onChanged: _saveNotificationsEnabled,
      ),
    );
  }

  /// 登录次数展示与模拟登录按钮
  Widget _buildLoginCountSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 登录次数圆形徽章
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Text(
                '$_loginCount',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('累计登录次数', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '每次点击按钮模拟一次登录',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _incrementLoginCount,
              icon: const Icon(Icons.login),
              label: const Text('模拟登录'),
            ),
          ],
        ),
      ),
    );
  }

  /// 标签管理：Chip 展示 + 添加 / 删除
  Widget _buildTagsSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 已有标签
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _tags)
                  Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                // 添加按钮
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('添加标签'),
                  onPressed: () => _showAddTagDialog(),
                ),
              ],
            ),
            if (_tags.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '暂无标签，点击上方按钮添加',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 弹出添加标签对话框
  Future<void> _showAddTagDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加标签'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入标签名称',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _addTag(result);
    }
  }

  /// 清除所有数据按钮
  Widget _buildClearButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          // 二次确认
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认清除'),
              content: const Text('确定要清除所有已保存的数据吗？此操作不可撤销。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('清除'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await _clearAll();
          }
        },
        icon: const Icon(Icons.delete_forever),
        label: const Text('清除所有数据'),
      ),
    );
  }
}
