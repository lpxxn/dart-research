# 第8章：国际化（Internationalization / i18n）

## 目录

1. [国际化基础概念](#1-国际化基础概念)
2. [Flutter 国际化体系](#2-flutter-国际化体系)
3. [手动实现 Localizations](#3-手动实现-localizations)
4. [使用 intl 包](#4-使用-intl-包)
5. [ARB 文件格式](#5-arb-文件格式)
6. [Locale 切换](#6-locale-切换)
7. [日期和数字格式化](#7-日期和数字格式化)
8. [最佳实践](#8-最佳实践)

---

## 1. 国际化基础概念

### 1.1 术语解释

- **i18n**（Internationalization）：国际化，让应用支持多语言的架构设计
- **l10n**（Localization）：本地化，为特定语言/地区翻译内容
- **Locale**：区域设置，如 `zh_CN`（中国大陆中文）、`en_US`（美国英语）
- **ARB**（Application Resource Bundle）：Flutter 推荐的翻译文件格式

### 1.2 为什么要做国际化

- 应用面向全球用户
- 日期、数字、货币格式因地区而异
- 文本方向（LTR/RTL）不同
- 复数形式在不同语言中规则不同

## 2. Flutter 国际化体系

### 2.1 核心组件

```
MaterialApp
├── localizationsDelegates   ← 提供翻译数据的代理
├── supportedLocales         ← 支持的语言列表
└── locale                   ← 当前使用的语言（可选，不设则跟随系统）
```

### 2.2 依赖配置

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:     # Flutter 内置组件的翻译
    sdk: flutter
  intl: any                  # 日期、数字格式化 + 消息翻译
```

### 2.3 MaterialApp 配置

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  // 本地化代理 —— 告诉 Flutter 如何获取翻译
  localizationsDelegates: const [
    AppLocalizations.delegate,              // 你自己的翻译
    GlobalMaterialLocalizations.delegate,   // Material 组件翻译
    GlobalWidgetsLocalizations.delegate,    // 基础 Widget 翻译
    GlobalCupertinoLocalizations.delegate,  // Cupertino 组件翻译
  ],
  // 支持的语言
  supportedLocales: const [
    Locale('zh', 'CN'),  // 简体中文
    Locale('en', 'US'),  // 英语
    Locale('ja'),        // 日语
  ],
)
```

## 3. 手动实现 Localizations

手动实现有助于理解 Flutter 国际化的底层机制。

### 3.1 定义翻译类

```dart
/// 应用翻译类 —— 包含所有需要翻译的字符串
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// 通过 BuildContext 获取当前翻译实例
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 翻译数据 —— 每种语言一个 Map
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Flutter Architecture',
      'hello': 'Hello',
      'counter': 'Counter',
      'increment': 'Increment',
      'decrement': 'Decrement',
      'settings': 'Settings',
      'language': 'Language',
      'switchLang': 'Switch Language',
    },
    'zh': {
      'title': 'Flutter 架构教程',
      'hello': '你好',
      'counter': '计数器',
      'increment': '增加',
      'decrement': '减少',
      'settings': '设置',
      'language': '语言',
      'switchLang': '切换语言',
    },
  };

  /// 获取翻译文本
  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get hello => _localizedValues[locale.languageCode]!['hello']!;
  String get counter => _localizedValues[locale.languageCode]!['counter']!;
  // ... 其他 getter
}
```

### 3.2 实现 LocalizationsDelegate

```dart
/// 本地化代理 —— 告诉 Flutter 如何加载翻译
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {

  const AppLocalizationsDelegate();

  /// 是否支持该语言
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  /// 加载翻译数据
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  /// 是否需要重新加载
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
```

### 3.3 使用翻译

```dart
// 在 Widget 中使用
Text(AppLocalizations.of(context).title)
```

## 4. 使用 intl 包

### 4.1 intl 的优势

- **复数处理**：`Intl.plural()` 自动处理不同语言的复数规则
- **性别处理**：`Intl.gender()` 处理性别相关文本
- **消息提取**：可从代码中自动提取翻译字符串
- **格式化**：日期、数字、货币格式化

### 4.2 消息定义

```dart
import 'package:intl/intl.dart';

class Messages {
  // 简单消息
  String get title => Intl.message(
    'Flutter Architecture Tutorial',
    name: 'title',
    desc: 'The application title',
  );

  // 带参数的消息
  String greeting(String name) => Intl.message(
    'Hello, $name!',
    name: 'greeting',
    args: [name],
    desc: 'Greeting with user name',
  );

  // 复数处理
  String itemCount(int count) => Intl.plural(
    count,
    zero: 'No items',
    one: '1 item',
    other: '$count items',
    name: 'itemCount',
    args: [count],
    desc: 'Number of items',
  );

  // 性别处理
  String welcomeMessage(String gender, String name) => Intl.gender(
    gender,
    male: 'Welcome, Mr. $name',
    female: 'Welcome, Ms. $name',
    other: 'Welcome, $name',
    name: 'welcomeMessage',
    args: [gender, name],
    desc: 'Welcome message based on gender',
  );
}
```

### 4.3 gen-l10n 方式（官方推荐）

Flutter 3.x 推荐使用 `flutter gen-l10n` 命令：

在 `pubspec.yaml` 中启用：

```yaml
flutter:
  generate: true
```

创建 `l10n.yaml`：

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

## 5. ARB 文件格式

### 5.1 什么是 ARB

ARB（Application Resource Bundle）是一种基于 JSON 的翻译文件格式，被 Flutter 官方推荐使用。

### 5.2 文件示例

`lib/l10n/app_en.arb`：

```json
{
  "@@locale": "en",
  "appTitle": "Flutter Architecture",
  "@appTitle": {
    "description": "The title of the application"
  },
  "hello": "Hello, {name}!",
  "@hello": {
    "description": "A greeting",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "World"
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "lastLogin": "Last login: {date}",
  "@lastLogin": {
    "description": "Last login date",
    "placeholders": {
      "date": {
        "type": "DateTime",
        "format": "yMMMd"
      }
    }
  }
}
```

`lib/l10n/app_zh.arb`：

```json
{
  "@@locale": "zh",
  "appTitle": "Flutter 架构教程",
  "hello": "你好，{name}！",
  "itemCount": "{count, plural, =0{没有项目} =1{1 个项目} other{{count} 个项目}}",
  "lastLogin": "上次登录：{date}"
}
```

### 5.3 生成代码

```bash
flutter gen-l10n
```

使用生成的代码：

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 在 Widget 中
Text(AppLocalizations.of(context)!.hello('Flutter'))
```

## 6. Locale 切换

### 6.1 跟随系统语言

```dart
MaterialApp(
  // 不设置 locale，自动跟随系统
  localeResolutionCallback: (deviceLocale, supportedLocales) {
    // 自定义语言匹配逻辑
    for (var locale in supportedLocales) {
      if (locale.languageCode == deviceLocale?.languageCode) {
        return locale;
      }
    }
    return supportedLocales.first;  // 回退到第一个支持的语言
  },
)
```

### 6.2 手动切换语言

使用 `ValueNotifier` 或状态管理方案控制语言：

```dart
class LocaleNotifier extends ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');

  Locale get locale => _locale;

  void switchLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}
```

在 MaterialApp 中使用：

```dart
ValueListenableBuilder<Locale>(
  valueListenable: localeNotifier,
  builder: (context, locale, child) {
    return MaterialApp(
      locale: locale,
      // ... 其他配置
    );
  },
)
```

### 6.3 持久化语言设置

```dart
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _key = 'app_locale';

  /// 保存语言设置
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  /// 读取语言设置
  static Future<Locale?> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) return Locale(code);
    return null;
  }
}
```

## 7. 日期和数字格式化

### 7.1 日期格式化

```dart
import 'package:intl/intl.dart';

// 需要先初始化日期格式化数据
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('zh_CN', null);

  final now = DateTime.now();

  // 中文格式
  print(DateFormat.yMMMMd('zh_CN').format(now));  // 2024年1月15日
  print(DateFormat.yMd('zh_CN').format(now));      // 2024/1/15
  print(DateFormat.Hm('zh_CN').format(now));       // 14:30
  print(DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(now));  // 2024年01月15日 星期一

  // 英文格式
  print(DateFormat.yMMMMd('en_US').format(now));  // January 15, 2024
  print(DateFormat.yMd('en_US').format(now));      // 1/15/2024
}
```

### 7.2 数字格式化

```dart
import 'package:intl/intl.dart';

// 千分位分隔
print(NumberFormat('#,###').format(1234567));     // 1,234,567
print(NumberFormat('#,###', 'zh_CN').format(1234567));  // 1,234,567

// 货币格式
print(NumberFormat.currency(locale: 'zh_CN', symbol: '¥').format(1234.5));
// ¥1,234.50

print(NumberFormat.currency(locale: 'en_US', symbol: '\$').format(1234.5));
// $1,234.50

print(NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(1234));
// ¥1,234

// 百分比
print(NumberFormat.percentPattern('zh_CN').format(0.85));  // 85%

// 紧凑格式
print(NumberFormat.compact(locale: 'en_US').format(1234567));  // 1.2M
print(NumberFormat.compact(locale: 'zh_CN').format(1234567));  // 123万
```

### 7.3 相对时间

```dart
/// 计算相对时间（如"3分钟前"）
String timeAgo(DateTime dateTime, String locale) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (locale.startsWith('zh')) {
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return DateFormat.yMd('zh_CN').format(dateTime);
  } else {
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat.yMd('en_US').format(dateTime);
  }
}
```

## 8. 最佳实践

### 8.1 翻译键命名

```dart
// ❌ 不好的命名
'btn1': '提交'
'text_abc': '欢迎'

// ✅ 好的命名 —— 语义化 + 上下文
'loginButton': '登录'
'homeWelcomeMessage': '欢迎回来'
'settingsLanguageTitle': '语言设置'
'errorNetworkTimeout': '网络超时，请重试'
```

### 8.2 避免拼接字符串

```dart
// ❌ 错误：字符串拼接 —— 不同语言语序不同
final text = '你好' + name + '，欢迎';

// ✅ 正确：使用占位符
// 中文: "你好，{name}，欢迎"
// 英文: "Hello {name}, welcome"
final text = AppLocalizations.of(context).greeting(name);
```

### 8.3 处理文本方向

```dart
// 支持 RTL（阿拉伯语、希伯来语等）
Directionality(
  textDirection: TextDirection.rtl,
  child: Text('مرحبا'),
)

// 自动检测
Widget build(BuildContext context) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return Padding(
    padding: EdgeInsetsDirectional.only(start: 16),  // 自动适应方向
    child: Text('...'),
  );
}
```

### 8.4 测试国际化

```dart
testWidgets('中文翻译测试', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: const MyHomePage(),
    ),
  );

  expect(find.text('Flutter 架构教程'), findsOneWidget);
});
```

---

## 总结

| 概念 | 说明 |
|------|------|
| `Locale` | 语言 + 地区标识 (如 zh_CN) |
| `LocalizationsDelegate` | 加载翻译数据的代理 |
| `flutter_localizations` | Material/Cupertino 组件的内置翻译 |
| `intl` | 日期、数字格式化 + 消息翻译 |
| `ARB` | 翻译资源文件格式 |
| `flutter gen-l10n` | 从 ARB 生成 Dart 代码 |

国际化不仅仅是文本翻译，还包括日期格式、数字格式、货币、文本方向等方面。良好的国际化架构应该从项目初期就开始规划。

**下一章**：[第9章：性能优化](ch09_performance.md)
