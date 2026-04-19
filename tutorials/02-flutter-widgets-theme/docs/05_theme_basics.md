# 第5章 — ThemeData 基础与全局主题

> 在 Flutter 中，主题（Theme）是让你的应用拥有统一视觉风格的核心机制。本章将深入讲解 `ThemeData`、`ColorScheme`、`TextTheme` 等基础概念，帮助你从零打造一套品牌主题。

---

## 5.1 Material Design 主题体系概述

Flutter 的 Material 组件库内建了一套完整的主题系统。你只需要在 `MaterialApp` 上配置一个 `ThemeData`，所有的 Material Widget——按钮、卡片、输入框、对话框等——都会自动读取并应用这套配置。

### MaterialApp 的 theme 和 darkTheme

`MaterialApp` 提供了三个与主题相关的关键属性：

```dart
MaterialApp(
  theme: ThemeData(...),        // 亮色主题
  darkTheme: ThemeData(...),    // 暗色主题
  themeMode: ThemeMode.system,  // 跟随系统 / 强制亮色 / 强制暗色
)
```

- **theme**：应用的默认（亮色）主题。
- **darkTheme**：暗色主题。如果设备处于深色模式且 `themeMode` 为 `ThemeMode.system`，Flutter 会自动使用这个主题。
- **themeMode**：控制使用哪个主题，可选 `system`、`light`、`dark`。

### ThemeData 是什么

`ThemeData` 是一个**巨大的配置对象**，它包含了所有 Material 组件的默认样式。你可以把它理解为一张「全局设计规格表」：颜色方案、文字排版、按钮样式、卡片外观、输入框装饰……全部集中在这一个对象里。

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
  ),
  cardTheme: const CardThemeData(elevation: 2),
  // ... 还有几十个属性
)
```

### Theme.of(context) 获取当前主题

在任意 Widget 的 `build` 方法中，都可以通过 `Theme.of(context)` 获取最近的 `ThemeData`：

```dart
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
final textTheme = theme.textTheme;

Text(
  '你好，世界',
  style: textTheme.headlineMedium?.copyWith(
    color: colorScheme.primary,
  ),
);
```

`Theme.of(context)` 会沿着 Widget 树向上查找最近的 `Theme` widget（`MaterialApp` 内部会自动插入一个）。如果你在局部用 `Theme` widget 覆盖了主题，子树中的 `Theme.of(context)` 会得到覆盖后的值。

---

## 5.2 ColorScheme — 色彩系统的核心

### Material 3 的 ColorScheme

在 Material 3 中，`ColorScheme` 是整个色彩系统的核心。它定义了一组**语义化的颜色角色**，每个角色在 UI 中有明确的用途：

| 颜色角色 | 含义 |
|---------|------|
| `primary` | 主要操作和高亮元素（按钮、链接、FAB） |
| `onPrimary` | 显示在 primary 颜色上的内容（文字、图标） |
| `primaryContainer` | primary 的容器色（更柔和） |
| `onPrimaryContainer` | 显示在 primaryContainer 上的内容 |
| `secondary` | 次要操作和辅助元素 |
| `onSecondary` | 显示在 secondary 上的内容 |
| `tertiary` | 第三级强调色，用于平衡 primary 和 secondary |
| `surface` | 卡片、底栏、对话框等表面的背景色 |
| `onSurface` | 显示在 surface 上的主要文字和图标 |
| `error` | 错误状态颜色 |
| `onError` | 显示在 error 上的内容 |
| `outline` | 边框和分隔线 |

### ColorScheme.fromSeed() — 从种子色自动生成完整配色

这是 Material 3 最强大的功能之一。只需提供一个「种子色」，算法就会基于 HCT 色彩空间自动生成**完整的、和谐的配色方案**：

```dart
// 只需一行代码，即可生成完整的配色方案
final colorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,         // 种子色
  brightness: Brightness.light,   // 亮色 or 暗色
);

// 生成暗色版本也很简单
final darkScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.dark,
);
```

`fromSeed` 内部使用 Google 的 Material Color Utilities 库，基于色相、色度、色调（HCT）色彩空间进行计算，保证生成的颜色在不同亮度下都有良好的对比度和可读性。

### ColorScheme.fromSwatch() — 从色板生成

如果你有一个 `MaterialColor`（即一个包含多个深浅的色板），也可以用 `fromSwatch` 生成 ColorScheme：

```dart
final colorScheme = ColorScheme.fromSwatch(
  primarySwatch: Colors.purple,
  accentColor: Colors.amber,
  brightness: Brightness.light,
);
```

但在 Material 3 时代，**推荐使用 `fromSeed`**，因为它能生成更完整、更和谐的配色。

### 各颜色角色详解

理解每个颜色角色的用途至关重要：

- **primary / onPrimary**：用于最重要的 UI 元素，如 `ElevatedButton` 的背景色、`FloatingActionButton` 的颜色。`onPrimary` 是显示在 primary 上的文字颜色。
- **secondary / onSecondary**：用于次重要的元素，如 `FilterChip` 被选中时的颜色。
- **tertiary / onTertiary**：提供额外的色彩层次，用于在 primary 和 secondary 之间创造视觉平衡。
- **surface / onSurface**：卡片、对话框、底部导航栏等的背景色。大部分 UI 表面都使用这个颜色。`onSurface` 是最主要的文字颜色。
- **error / onError**：表单验证错误、网络请求失败等错误状态使用的颜色。
- **outline / outlineVariant**：输入框边框、分隔线等使用的颜色。

---

## 5.3 TextTheme — 文字排版系统

### Material 3 的 TextTheme

Material 3 定义了一套层次分明的文字样式体系，按用途分为 5 大类，每类有 Large / Medium / Small 三个级别：

| 类别 | 用途 |
|------|------|
| `displayLarge/Medium/Small` | 最大的标题，通常用于英雄区域（Hero Section） |
| `headlineLarge/Medium/Small` | 章节标题 |
| `titleLarge/Medium/Small` | 卡片标题、对话框标题、AppBar 标题 |
| `bodyLarge/Medium/Small` | 正文文字 |
| `labelLarge/Medium/Small` | 按钮文字、标签、Caption |

```dart
// 在 Widget 中使用
Text(
  '大标题',
  style: Theme.of(context).textTheme.displayLarge,
);

Text(
  '正文内容',
  style: Theme.of(context).textTheme.bodyMedium,
);
```

### 自定义 TextTheme

你可以完全自定义 `TextTheme`，比如使用自定义字体：

```dart
ThemeData(
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'NotoSansSC',
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'NotoSansSC',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    // ... 其他级别
  ),
)
```

如果你使用 `google_fonts` 包，可以更方便地设置：

```dart
import 'package:google_fonts/google_fonts.dart';

ThemeData(
  textTheme: GoogleFonts.notoSansScTextTheme(),
)
```

### copyWith 局部覆盖

`copyWith` 是 Flutter 中非常常用的模式——它创建一个副本，只修改你指定的属性：

```dart
// 基于默认 TextTheme，只修改 bodyLarge 的颜色
final customTextTheme = Theme.of(context).textTheme.copyWith(
  bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: Colors.indigo,
    fontWeight: FontWeight.bold,
  ),
);
```

这个模式在整个 Flutter 主题系统中随处可见：`ThemeData.copyWith`、`ColorScheme.copyWith`、`TextStyle.copyWith`……

---

## 5.4 AppBarTheme / CardTheme / IconThemeData...

### 常用组件主题概述

`ThemeData` 中包含了大量组件级别的主题配置。以下是最常用的几个：

| 属性 | 控制对象 |
|------|---------|
| `appBarTheme` | AppBar 的背景色、前景色、阴影、标题样式 |
| `cardTheme` | Card 的阴影、形状、颜色 |
| `elevatedButtonTheme` | ElevatedButton 的样式 |
| `outlinedButtonTheme` | OutlinedButton 的样式 |
| `textButtonTheme` | TextButton 的样式 |
| `floatingActionButtonTheme` | FAB 的颜色、形状、大小 |
| `inputDecorationTheme` | TextField 的装饰样式 |
| `iconTheme` | 默认的图标颜色和大小 |
| `chipTheme` | Chip 的样式 |
| `dialogTheme` | Dialog 的形状和背景 |
| `bottomNavigationBarTheme` | 底部导航栏的样式 |
| `navigationBarTheme` | Material 3 导航栏的样式 |
| `switchTheme` | Switch 的颜色和样式 |
| `checkboxTheme` | Checkbox 的颜色和样式 |

```dart
ThemeData(
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
)
```

### 如何查看某个 Widget 读取了哪些主题属性

当你想知道某个 Widget 使用了哪些主题属性时，有几种方法：

1. **查看源码**：在 IDE 中按住 Cmd/Ctrl 点击 Widget 名称，跳转到源码。搜索 `Theme.of` 或 `xxxTheme.of` 即可看到它读取了哪些主题属性。

2. **查看文档**：Flutter 官方文档中，每个 Widget 的页面都会说明它如何使用主题。

3. **实验法**：修改 `ThemeData` 中的某个属性，观察 Widget 的变化。

例如，`ElevatedButton` 的样式解析优先级为：
```
Widget 参数 style > ElevatedButtonTheme > ThemeData.elevatedButtonTheme > 默认值（基于 ColorScheme）
```

---

## 5.5 useMaterial3

### Material 2 vs Material 3 的视觉差异

Material 3（也称 Material You）是 Google 在 2021 年发布的最新设计语言。与 Material 2 相比，主要差异包括：

| 特性 | Material 2 | Material 3 |
|------|-----------|-----------|
| 按钮形状 | 圆角较小 | 更大的圆角（stadium 形状） |
| 颜色系统 | primarySwatch + accent | ColorScheme + 种子色 |
| 阴影 | 传统阴影 | 阴影 + surface tint（色调叠加） |
| FAB | 圆形为主 | 支持大号 FAB、扩展 FAB |
| NavigationBar | BottomNavigationBar | NavigationBar（带指示器动画） |
| Card | 简单阴影 | 支持 filled / outlined / elevated 三种变体 |
| 字体系统 | 6 级 | 15 级（5 类 × 3 大小） |

### useMaterial3: true 的影响范围

```dart
ThemeData(
  useMaterial3: true,  // 启用 Material 3
)
```

设置 `useMaterial3: true` 后，以下方面会受到影响：

- **所有 Material Widget 的默认外观**都会切换为 Material 3 风格。
- **ColorScheme** 成为颜色系统的核心（而非旧的 primarySwatch）。
- **Typography** 使用 Material 3 的 15 级文字系统。
- **组件形状**普遍变为更大的圆角。
- **Surface tint** 取代纯阴影来表示层级。

> ⚠️ 从 Flutter 3.16 开始，`useMaterial3` 默认为 `true`。如果你的项目是新创建的，已经默认使用 Material 3。

---

## 5.6 示例：打造品牌主题

让我们从一个品牌色出发，打造一套完整的主题。假设我们的品牌色是「薰衣草紫」`Color(0xFF6750A4)`。

### 第一步：用 ColorScheme.fromSeed 生成配色

```dart
// 从品牌色生成完整的亮色和暗色配色方案
final lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),  // 薰衣草紫
  brightness: Brightness.light,
);

final darkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),
  brightness: Brightness.dark,
);
```

### 第二步：自定义 TextTheme

```dart
const brandTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ),
);
```

### 第三步：组合成完整的 ThemeData

```dart
ThemeData buildBrandTheme(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: brandTextTheme,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    ),
  );
}
```

### 第四步：在 MaterialApp 中使用

```dart
MaterialApp(
  theme: buildBrandTheme(lightScheme),
  darkTheme: buildBrandTheme(darkScheme),
  themeMode: ThemeMode.system,
  home: const HomePage(),
)
```

这样，整个应用的所有 Material 组件都会自动使用你的品牌主题，而且亮色和暗色切换也一并搞定。

---

## 5.7 小结

本章我们学习了 Flutter 主题系统的基础知识：

1. **ThemeData** 是一个集中管理所有 Material 组件样式的配置对象，通过 `MaterialApp` 的 `theme` 属性设置。
2. **ColorScheme** 是 Material 3 色彩系统的核心，`fromSeed` 方法可以从一个种子色自动生成和谐的完整配色。
3. **TextTheme** 提供了 15 级（5 类 × 3 大小）的文字排版系统，支持自定义字体和 `copyWith` 局部覆盖。
4. **组件主题**（如 `AppBarTheme`、`CardTheme` 等）允许你精细控制各个组件的默认外观。
5. **useMaterial3** 开关控制是否使用 Material 3 的新设计语言，新项目默认启用。
6. 从品牌色出发，利用 `ColorScheme.fromSeed` + 自定义 `TextTheme` + 组件主题，可以快速打造统一的品牌视觉。

> **下一章**我们将学习如何实现深色 / 浅色主题的动态切换。
