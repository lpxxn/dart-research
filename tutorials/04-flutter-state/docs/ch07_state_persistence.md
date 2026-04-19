# 第7章：状态持久化

## 目录

1. [为什么需要状态持久化](#1-为什么需要状态持久化)
2. [SharedPreferences 基础](#2-sharedpreferences-基础)
3. [RestorableProperty 系统级恢复](#3-restorableproperty-系统级恢复)
4. [状态序列化策略](#4-状态序列化策略)
5. [实战：用户设置页面](#5-实战用户设置页面)
6. [最佳实践](#6-最佳实践)

---

## 1. 为什么需要状态持久化

### 问题场景

在 Flutter 应用中，所有内存中的状态在以下情况会丢失：

| 场景 | 说明 |
|------|------|
| App 重启 | 用户手动关闭再打开应用 |
| 系统回收 | 系统内存不足时回收后台 App |
| 热重载/重新构建 | 开发过程中的重新编译 |

### 需要持久化的典型数据

- **用户设置**：主题偏好、语言设置、字体大小
- **登录状态**：Token、用户信息
- **应用状态**：上次浏览位置、搜索历史
- **缓存数据**：离线数据、临时表单数据

### Flutter 持久化方案概览

| 方案 | 适用数据 | 特点 |
|------|---------|------|
| **SharedPreferences** | 简单键值对 | 轻量、同步读异步写 |
| **RestorableProperty** | 系统级状态恢复 | 处理系统杀死进程的场景 |
| **文件存储** | 大量文本/JSON | 灵活但需自己管理 |
| **SQLite (sqflite)** | 结构化数据 | 关系型数据库，适合复杂查询 |
| **Hive** | NoSQL 数据 | 快速、纯 Dart 实现 |

---

## 2. SharedPreferences 基础

### 什么是 SharedPreferences？

SharedPreferences 是一个键值对存储方案，底层实现：
- **Android**：SharedPreferences XML 文件
- **iOS**：NSUserDefaults
- **Web**：localStorage

### 安装

```yaml
dependencies:
  shared_preferences: ^2.0.0
```

### 基本操作

```dart
import 'package:shared_preferences/shared_preferences.dart';

// 获取实例（异步操作）
final prefs = await SharedPreferences.getInstance();

// ===== 写入数据 =====
await prefs.setString('username', '张三');
await prefs.setInt('age', 25);
await prefs.setDouble('height', 175.5);
await prefs.setBool('isDarkMode', true);
await prefs.setStringList('favorites', ['苹果', '香蕉', '橙子']);

// ===== 读取数据 =====
String? username = prefs.getString('username');  // 返回 null 如果不存在
int age = prefs.getInt('age') ?? 0;              // 使用 ?? 提供默认值
double height = prefs.getDouble('height') ?? 0.0;
bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
List<String>? favorites = prefs.getStringList('favorites');

// ===== 删除数据 =====
await prefs.remove('username');  // 删除单个键
await prefs.clear();             // 清除所有数据

// ===== 检查键是否存在 =====
bool exists = prefs.containsKey('username');
```

### 支持的数据类型

| 类型 | 读方法 | 写方法 |
|------|--------|--------|
| `String` | `getString()` | `setString()` |
| `int` | `getInt()` | `setInt()` |
| `double` | `getDouble()` | `setDouble()` |
| `bool` | `getBool()` | `setBool()` |
| `List<String>` | `getStringList()` | `setStringList()` |

> **注意**：SharedPreferences **不支持**直接存储对象。需要先序列化为 JSON 字符串。

### 封装一个设置管理类

```dart
/// 用户设置管理器
class SettingsManager {
  static const _keyTheme = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyFontSize = 'font_size';

  final SharedPreferences _prefs;

  // 通过工厂方法创建（因为 getInstance 是异步的）
  static Future<SettingsManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsManager._(prefs);
  }

  SettingsManager._(this._prefs);

  // 主题模式
  String get themeMode => _prefs.getString(_keyTheme) ?? 'system';
  Future<bool> setThemeMode(String mode) => _prefs.setString(_keyTheme, mode);

  // 语言
  String get language => _prefs.getString(_keyLanguage) ?? 'zh';
  Future<bool> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  // 字体大小
  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 16.0;
  Future<bool> setFontSize(double size) => _prefs.setDouble(_keyFontSize, size);
}
```

---

## 3. RestorableProperty 系统级恢复

### 什么是 RestorableProperty？

当 Android/iOS 系统因内存不足杀死后台 App 时，Flutter 的 Restoration Framework 可以保存和恢复 Widget 的状态。

### 与 SharedPreferences 的区别

| 特性 | SharedPreferences | RestorableProperty |
|------|------------------|-------------------|
| 存储位置 | 磁盘文件 | 系统提供的临时存储 |
| 生命周期 | 持久（直到删除） | 临时（App 被杀死到恢复） |
| 使用场景 | 用户设置 | 表单输入、滚动位置 |
| 数据大小 | 较大 | 应尽量小 |

### 使用方式

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RestorationMixin {
  // 定义可恢复的属性
  final RestorableInt _counter = RestorableInt(0);
  final RestorableString _name = RestorableString('');
  final RestorableBool _isChecked = RestorableBool(false);

  // 必须提供唯一的 restoration ID
  @override
  String? get restorationId => 'my_home_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // 注册需要恢复的属性
    registerForRestoration(_counter, 'counter');
    registerForRestoration(_name, 'name');
    registerForRestoration(_isChecked, 'is_checked');
  }

  @override
  void dispose() {
    _counter.dispose();
    _name.dispose();
    _isChecked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('计数: ${_counter.value}'),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _counter.value++;
            });
          },
          child: Text('增加'),
        ),
      ],
    );
  }
}
```

### 常用 RestorableProperty 类型

```dart
RestorableInt(0)              // int
RestorableDouble(0.0)         // double
RestorableString('')          // String
RestorableBool(false)         // bool
RestorableDateTime(DateTime.now())  // DateTime
RestorableTextEditingController()   // TextEditingController
```

---

## 4. 状态序列化策略

### 4.1 JSON 序列化

最常用的序列化方式，适合存储复杂对象到 SharedPreferences：

```dart
import 'dart:convert';

// 定义数据模型
class UserSettings {
  final String theme;
  final String language;
  final double fontSize;
  final List<String> recentSearches;

  UserSettings({
    required this.theme,
    required this.language,
    required this.fontSize,
    required this.recentSearches,
  });

  // 序列化：对象 → Map → JSON 字符串
  Map<String, dynamic> toJson() => {
    'theme': theme,
    'language': language,
    'fontSize': fontSize,
    'recentSearches': recentSearches,
  };

  // 反序列化：JSON 字符串 → Map → 对象
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] as String,
      language: json['language'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      recentSearches: List<String>.from(json['recentSearches']),
    );
  }

  // 默认设置
  factory UserSettings.defaults() {
    return UserSettings(
      theme: 'system',
      language: 'zh',
      fontSize: 16.0,
      recentSearches: [],
    );
  }
}

// 存储
Future<void> saveSettings(UserSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(settings.toJson());
  await prefs.setString('user_settings', jsonString);
}

// 读取
Future<UserSettings> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('user_settings');
  if (jsonString == null) {
    return UserSettings.defaults();
  }
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return UserSettings.fromJson(json);
}
```

### 4.2 版本迁移策略

当数据结构变化时，需要处理旧版本数据：

```dart
class UserSettings {
  static const int currentVersion = 2;

  // 序列化时带上版本号
  Map<String, dynamic> toJson() => {
    '_version': currentVersion,
    'theme': theme,
    'language': language,
    'fontSize': fontSize,
  };

  // 反序列化时检查版本
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final version = json['_version'] as int? ?? 1;

    // 版本迁移
    if (version == 1) {
      // v1 没有 fontSize，使用默认值
      return UserSettings(
        theme: json['theme'] ?? 'system',
        language: json['language'] ?? 'zh',
        fontSize: 16.0,
        recentSearches: [],
      );
    }

    // 当前版本
    return UserSettings(
      theme: json['theme'] as String,
      language: json['language'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      recentSearches: List<String>.from(json['recentSearches'] ?? []),
    );
  }
}
```

### 4.3 错误处理

```dart
Future<UserSettings> loadSettingsSafe() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_settings');
    if (jsonString == null) return UserSettings.defaults();

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserSettings.fromJson(json);
  } catch (e) {
    // JSON 解析失败时返回默认值
    print('加载设置失败: $e，使用默认设置');
    return UserSettings.defaults();
  }
}
```

---

## 5. 实战：用户设置页面

完整代码见 `lib/ch07_state_persistence.dart`，实现功能：

### 功能列表

1. **主题切换**：亮色 / 暗色 / 跟随系统
2. **语言选择**：中文 / English
3. **字体大小调节**：滑块调节 12-24px
4. **设置持久化**：关闭再打开 App 后设置依然生效
5. **重置功能**：一键恢复默认设置

### 架构设计

```
┌─────────────────┐
│   设置页面 UI     │
│ (SettingsPage)   │
└────────┬────────┘
         │ 读写设置
         ▼
┌─────────────────┐
│  设置管理器       │
│ (SettingsManager)│
└────────┬────────┘
         │ 键值存储
         ▼
┌─────────────────┐
│SharedPreferences│
└─────────────────┘
```

### 关键实现细节

- 使用 `FutureBuilder` 处理异步初始化
- 设置变更时同时更新内存状态和持久化存储
- 主题模式的改变会立即反映到整个 App

---

## 6. 最佳实践

### 6.1 键名管理

```dart
// ✅ 使用常量集中管理键名
class PrefsKeys {
  static const String theme = 'pref_theme';
  static const String language = 'pref_language';
  static const String fontSize = 'pref_font_size';
  static const String isFirstLaunch = 'pref_is_first_launch';
}

// ❌ 避免硬编码字符串
prefs.getString('theme');  // 容易拼写错误
```

### 6.2 异步初始化处理

```dart
// ✅ 在 App 启动时预加载
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 预加载 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

// ✅ 或使用 FutureBuilder
Widget build(BuildContext context) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return CircularProgressIndicator();
      }
      return SettingsPage(prefs: snapshot.data!);
    },
  );
}
```

### 6.3 数据安全

```dart
// ⚠️ SharedPreferences 存储的数据是明文的！
// 不要用它存储敏感信息：
// - 密码
// - 信用卡号
// - 加密密钥

// 对于敏感数据，使用 flutter_secure_storage
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// final storage = FlutterSecureStorage();
// await storage.write(key: 'token', value: 'secret_token');
```

### 6.4 性能注意事项

```dart
// ✅ 缓存 SharedPreferences 实例
class AppPrefs {
  static SharedPreferences? _instance;
  
  static Future<SharedPreferences> get instance async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }
}

// ✅ 批量操作时考虑防抖
// 例如滑块调节字体大小时，不要每次滑动都写入
Timer? _debounceTimer;
void onFontSizeChanged(double size) {
  setState(() => _fontSize = size);
  
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    prefs.setDouble('font_size', size);
  });
}
```

### 6.5 测试策略

```dart
// SharedPreferences 支持设置初始值用于测试
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme': 'dark',
      'font_size': 18.0,
    });
  });

  test('读取主题设置', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme'), 'dark');
  });
}
```

---

## 参考资源

- [shared_preferences 官方文档](https://pub.dev/packages/shared_preferences)
- [Flutter 状态恢复](https://api.flutter.dev/flutter/widgets/RestorationMixin-mixin.html)
- [Flutter 数据持久化指南](https://docs.flutter.dev/cookbook/persistence)
