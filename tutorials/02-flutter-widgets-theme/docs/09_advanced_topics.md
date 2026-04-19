# 第9章 — 高级话题：动画主题与动态换肤

> 从 AnimatedTheme 平滑过渡到动态 JSON 主题加载，再到多品牌白标方案——本章探讨主题系统的高级应用。

---

## 9.1 AnimatedTheme 平滑过渡

### AnimatedTheme vs Theme 的区别

在前面的章节中，我们一直使用 `Theme` widget 来设置主题。当 `ThemeData` 发生变化时，`Theme` 会立即切换——没有过渡动画，视觉上是"跳变"的。

`AnimatedTheme` 是 `Theme` 的动画版本。当 `ThemeData` 发生变化时，它会对新旧主题的颜色值进行**线性插值（lerp）**，在指定的 `duration` 内平滑过渡。

```dart
// 普通 Theme：立即切换
Theme(
  data: currentTheme,
  child: child,
)

// AnimatedTheme：平滑过渡
AnimatedTheme(
  data: currentTheme,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeInOut,
  child: child,
)
```

### duration 和 curve 控制过渡动画

- **`duration`**：过渡动画的总时长。通常 300-800 毫秒比较合适
- **`curve`**：动画曲线。常用的有：
  - `Curves.easeInOut`：缓入缓出，最自然
  - `Curves.easeOut`：快速开始，缓慢结束
  - `Curves.fastOutSlowIn`：Material Design 推荐曲线

### 原理：对 ThemeData 中的颜色值做 lerp 插值

`AnimatedTheme` 内部使用 `ThemeDataTween`，它会对 `ThemeData` 中所有支持插值的属性进行 `lerp` 运算：

1. `ColorScheme` 中的每个颜色属性会调用 `Color.lerp()`
2. `TextTheme` 中的字体颜色也会做插值
3. 组件主题中的颜色属性同样参与插值
4. 注册的 `ThemeExtension` 会调用它们自己的 `lerp()` 方法

这就是为什么在第7章中我们强调 `ThemeExtension.lerp()` 的重要性——它让自定义属性也能参与动画过渡。

```dart
// ThemeDataTween 的核心逻辑（简化）
class ThemeDataTween extends Tween<ThemeData> {
  @override
  ThemeData lerp(double t) {
    return ThemeData.lerp(begin!, end!, t);
  }
}
```

---

## 9.2 动态主题：从 JSON 加载

### 思路

在某些场景下，主题配色不是在编译时确定的，而是从服务端动态下发的——比如运营活动页面、节日特别版、A/B 测试等。这时我们需要将 `ColorScheme` 序列化为 JSON，在运行时解析并构建 `ThemeData`。

### 定义 JSON 格式

```json
{
  "name": "春节特别版",
  "brightness": "light",
  "primary": "#D32F2F",
  "secondary": "#FFC107",
  "surface": "#FFFDE7",
  "error": "#B71C1C",
  "onPrimary": "#FFFFFF",
  "onSecondary": "#000000",
  "onSurface": "#212121",
  "onError": "#FFFFFF"
}
```

### 解析并构建 ThemeData

```dart
/// 从 JSON Map 构建 ThemeData
ThemeData buildThemeFromJson(Map<String, dynamic> json) {
  // 辅助方法：解析颜色字符串
  Color parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  final brightness = json['brightness'] == 'dark'
      ? Brightness.dark
      : Brightness.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: parseColor(json['primary']),
    secondary: parseColor(json['secondary']),
    surface: parseColor(json['surface']),
    error: parseColor(json['error']),
    onPrimary: parseColor(json['onPrimary']),
    onSecondary: parseColor(json['onSecondary']),
    onSurface: parseColor(json['onSurface']),
    onError: parseColor(json['onError']),
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
  );
}
```

### 完整流程

```dart
// 1. 从服务端获取 JSON
final response = await http.get(Uri.parse('https://api.example.com/theme'));
final jsonData = jsonDecode(response.body);

// 2. 构建 ThemeData
final dynamicTheme = buildThemeFromJson(jsonData);

// 3. 应用到 MaterialApp
setState(() {
  _currentTheme = dynamicTheme;
});
```

---

## 9.3 主题持久化

### SharedPreferences 存储用户选择

当用户手动选择了某个主题后，我们需要将这个选择持久化，以便下次启动时自动应用。

```dart
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _key = 'selected_theme';

  /// 保存用户选择的主题名称
  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeName);
  }

  /// 读取用户之前选择的主题名称
  static Future<String?> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
```

### 启动时读取 + 应用

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _theme = _defaultTheme;

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final themeName = await ThemePreferences.loadTheme();
    if (themeName != null) {
      setState(() {
        _theme = _getThemeByName(themeName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme,
      home: HomePage(),
    );
  }
}
```

### 伪代码流程

```
应用启动
  → 读取 SharedPreferences 中的 theme_name
  → 如果存在：根据名称查找对应 ThemeData，应用之
  → 如果不存在：使用默认主题
  
用户切换主题
  → 更新 UI（setState / Provider / Riverpod）
  → 写入 SharedPreferences
  → 下次启动自动应用
```

---

## 9.4 多品牌 / 白标方案

### 思路

"白标"（White-label）是 SaaS 产品的常见需求：同一个应用代码，为不同客户呈现不同的品牌外观——Logo、颜色、字体、甚至文案。

我们可以定义一个 `BrandConfig` 类来封装品牌的所有定制信息：

```dart
class BrandConfig {
  final String brandName;
  final String logoAsset;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;
  final String? fontFamily;
  final BrandColors lightBrandColors;
  final BrandColors darkBrandColors;

  const BrandConfig({
    required this.brandName,
    required this.logoAsset,
    required this.lightColorScheme,
    required this.darkColorScheme,
    this.fontFamily,
    required this.lightBrandColors,
    required this.darkBrandColors,
  });

  ThemeData get lightTheme => ThemeData(
    colorScheme: lightColorScheme,
    fontFamily: fontFamily,
    useMaterial3: true,
    extensions: [lightBrandColors],
  );

  ThemeData get darkTheme => ThemeData(
    colorScheme: darkColorScheme,
    fontFamily: fontFamily,
    useMaterial3: true,
    extensions: [darkBrandColors],
  );
}
```

### 运行时切换品牌

```dart
// 定义多个品牌配置
final Map<String, BrandConfig> brands = {
  'techBlue': BrandConfig(
    brandName: '科技蓝',
    logoAsset: 'assets/logo_blue.png',
    lightColorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    // ...
  ),
  'warmOrange': BrandConfig(
    brandName: '暖阳橙',
    logoAsset: 'assets/logo_orange.png',
    lightColorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    // ...
  ),
};

// 切换品牌
void switchBrand(String brandKey) {
  final config = brands[brandKey]!;
  setState(() {
    _currentTheme = config.lightTheme;
    _currentDarkTheme = config.darkTheme;
    _currentLogo = config.logoAsset;
  });
}
```

### 适用场景

| 场景 | 说明 |
|------|------|
| SaaS 白标 | 同一应用为不同企业客户定制品牌外观 |
| 多子品牌 | 一个集团下多个子品牌共用一套代码 |
| 节日主题 | 春节红、圣诞绿等运营活动主题 |
| 用户个性化 | 允许用户自定义应用配色 |

---

## 9.5 示例：动画换肤

本节实现一个完整的动画换肤示例，预定义 3 套主题，点击切换时使用 `AnimatedTheme` 平滑过渡。

### 预定义 3 套主题

```dart
// 1. 科技蓝：冷色调，专业、可靠
final techBlueTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

// 2. 暖阳橙：暖色调，活力、友好
final warmOrangeTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

// 3. 森林绿：自然色调，清新、环保
final forestGreenTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);
```

### 使用 AnimatedTheme

```dart
AnimatedTheme(
  data: _currentTheme,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeInOut,
  child: Builder(
    builder: (context) {
      // 这里的 Theme.of(context) 会获取到动画中间值
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        // 所有使用 colorScheme 的组件都会平滑过渡
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: Text('动画主题切换'),
        ),
        body: _buildContent(context),
      );
    },
  ),
)
```

### 效果展示

切换主题时，你会看到：
- AppBar 的背景色平滑变化
- 按钮的颜色渐变过渡
- 卡片的背景色柔和切换
- 文字颜色同步变化
- 整个页面的色调在 600 毫秒内完成转换

这种丝滑的过渡效果远比"一闪而切"的体验要好得多。

> 📖 完整代码示例见 `lib/examples/ex09_animated_theme.dart`

---

## 9.6 小结与全系列回顾

### 本章小结

| 知识点 | 要点 |
|--------|------|
| **AnimatedTheme** | Theme 的动画版本，对颜色值做 lerp 插值实现平滑过渡 |
| **动态 JSON 主题** | 将 ColorScheme 序列化为 JSON，运行时解析并构建 ThemeData |
| **主题持久化** | 用 SharedPreferences 存储用户选择，启动时自动应用 |
| **多品牌白标** | 定义 BrandConfig 封装品牌定制信息，运行时切换 |
| **动画时长** | 300-800ms 比较合适，推荐 600ms + easeInOut 曲线 |

### 全系列回顾

回顾整个主题系列教程，我们从基础到进阶，覆盖了 Flutter 主题系统的方方面面：

| 章节 | 主题 | 核心知识 |
|------|------|----------|
| 第7章 | ThemeExtension | 自定义品牌颜色/间距扩展 |
| 第8章 | 组件级主题 | ButtonStyle、InputDecorationTheme、CardTheme 等 |
| 第9章 | 高级话题 | AnimatedTheme、JSON 主题、持久化、白标方案 |

### 最佳实践总结

1. **始终使用 `Theme.of(context)`**——不要硬编码颜色值
2. **优先使用 `ColorScheme`**——Material 3 的核心，语义化颜色
3. **活用 `ThemeExtension`**——品牌定制的首选方案
4. **组件主题统一风格**——在 ThemeData 中配置，而不是在每个组件上重复
5. **AnimatedTheme 提升体验**——主题切换加上平滑动画
6. **主题配置集中管理**——建立 `theme/` 目录，按职责拆分文件

Flutter 的主题系统是构建高质量、可维护 UI 的基石。掌握了这些知识，你就能轻松应对各种品牌定制、主题切换、动态换肤的需求。

> 🎉 恭喜你完成了主题系列教程的学习！
