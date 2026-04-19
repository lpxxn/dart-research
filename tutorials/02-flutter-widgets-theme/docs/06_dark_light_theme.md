# 第6章 — 深色 / 浅色主题切换

> 深色模式已经成为现代应用的标配。本章将讲解深色主题的设计要点，并通过代码演示如何实现亮色与暗色主题的动态切换。

---

## 6.1 为什么需要深色模式

### 护眼与视觉舒适

在低光环境下（如夜晚在床上刷手机），亮色界面会让屏幕成为一个刺眼的光源，导致眼部疲劳。深色模式大幅降低了屏幕的整体亮度，减轻了对眼睛的刺激。虽然学术研究对「深色模式是否真正护眼」仍有争议，但不可否认的是，**大量用户主观上偏好深色模式**，尤其在夜间使用时。

### 省电（OLED 屏幕）

OLED 屏幕的每个像素都是独立发光的。当像素显示纯黑色时，它实际上是关闭状态，不消耗电量。因此，深色界面在 OLED 设备上可以显著延长电池续航。Google 曾在 Android Dev Summit 上展示，YouTube 在深色模式下 OLED 屏幕的功耗降低了约 60%。

### 用户偏好

根据多项调查，超过 80% 的智能手机用户会在至少部分时间使用深色模式。iOS 和 Android 都在系统级别提供了深色模式开关，用户期望应用能够尊重这个偏好。

### Material Design 深色主题指南

Google 的 Material Design 深色主题指南强调了几个关键原则：

1. **降低亮度而非简单反转**：深色主题不是简单地把黑变白、白变黑。
2. **保持可读性**：文字和背景之间需要足够的对比度（WCAG 建议至少 4.5:1）。
3. **减少大面积纯白**：在深色主题中，大面积高亮度的元素会非常刺眼。
4. **使用 surface 层级**：通过微妙的明度差异表示元素层级，而非依赖阴影。

---

## 6.2 MaterialApp 的 themeMode

### ThemeMode 三种模式

Flutter 通过 `ThemeMode` 枚举来控制应用使用哪个主题：

```dart
enum ThemeMode {
  system,  // 跟随系统设置
  light,   // 强制亮色
  dark,    // 强制暗色
}
```

### theme + darkTheme 的配置

在 `MaterialApp` 中，你可以同时提供亮色和暗色两套主题：

```dart
MaterialApp(
  // 亮色主题
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  ),
  // 暗色主题
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  ),
  // 主题模式
  themeMode: ThemeMode.system,
)
```

当 `themeMode` 为 `ThemeMode.system` 时，Flutter 会自动根据系统设置选择使用 `theme` 还是 `darkTheme`。

### 检测系统亮度

如果你需要在代码中手动判断当前系统是亮色还是暗色模式，可以使用：

```dart
// 方法1：通过 MediaQuery
final brightness = MediaQuery.platformBrightnessOf(context);
final isDark = brightness == Brightness.dark;

// 方法2：通过 Theme
final isDark = Theme.of(context).brightness == Brightness.dark;
```

---

## 6.3 实现主题切换

要让用户手动切换主题，我们需要一个**状态管理**机制来保存当前的 `ThemeMode` 并在变更时通知 UI 重建。

### 方案1：ValueNotifier + ValueListenableBuilder

这是最简单、不依赖任何第三方包的方案：

```dart
// 定义一个全局的 ValueNotifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}
```

在任何子 Widget 中，切换主题只需一行：

```dart
// 切换到暗色
themeNotifier.value = ThemeMode.dark;

// 切换到亮色
themeNotifier.value = ThemeMode.light;

// 跟随系统
themeNotifier.value = ThemeMode.system;
```

### 方案2：InheritedWidget 封装

如果你不想用全局变量，可以用 `InheritedWidget` 把 `ThemeMode` 的管理封装起来：

```dart
class ThemeController extends InheritedWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ThemeController({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeController>()!;
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}
```

这样在子 Widget 中就可以通过 `ThemeController.of(context)` 来获取和切换主题。

### 方案3：使用 Provider（推荐）

如果项目已经使用了 `provider` 包，这是最优雅的方案。但因为本教程聚焦在主题本身，我们不额外引入第三方依赖，因此选择 **方案1** 进行详细演示。

---

## 6.4 深色主题设计要点

### 不是简单反转颜色

深色主题绝对不是简单地把所有亮色变成暗色、暗色变成亮色。如果这样做，会出现很多问题：

- **对比度失控**：某些颜色组合在反转后可能变得难以阅读。
- **语义混乱**：错误色、警告色等语义颜色反转后可能失去原来的含义。
- **品牌色变形**：品牌色在简单反转后可能变得面目全非。

### Surface 不应该是纯黑

Material Design 建议深色主题的 surface 颜色使用 **深灰色**（如 `#1C1B1F`）而非纯黑色 `#000000`。原因是：

1. 纯黑背景上的白色文字对比度太高（21:1），长时间阅读会造成「光晕效应」（halation），导致文字边缘看起来模糊。
2. 纯黑色无法通过明度差异表示层级——所有 surface 看起来都一样。
3. `ColorScheme.fromSeed` 会自动生成合适的深灰色 surface，你不需要手动调整。

### 文字对比度要求

WCAG 2.1 规定了最低对比度要求：

- **普通文字**：至少 4.5:1
- **大文字**（18sp+ 或 14sp+ 加粗）：至少 3:1

在深色主题中，不要使用纯白色 `#FFFFFF` 作为主要文字颜色。Material Design 推荐使用带有微妙透明度的白色（如 `Colors.white.withValues(alpha: 0.87)`），或者直接使用 `ColorScheme` 的 `onSurface` 颜色。

### Elevation 在深色下的表现

在亮色主题中，elevation（高度）通过阴影来表示——elevation 越高，阴影越深。但在深色主题中，阴影在深色背景上几乎不可见。

Material 3 的解决方案是 **Surface Tint**：elevation 越高，表面颜色越亮（混入更多 primary 色调）。这样即使在深色背景上，也能清晰地区分不同层级的元素。

```
elevation 0:  surface 原色（最暗）
elevation 1:  surface + 少量 primary tint
elevation 2:  surface + 更多 primary tint
elevation 3:  surface + 更多 primary tint（更亮）
```

### 图片和插画在深色下的处理

深色模式下处理图片和插画需要注意：

- **降低图片亮度**：可以在 `Image` 上叠加半透明的暗色遮罩，避免高亮图片在深色界面上过于刺眼。
- **使用不同版本的插画**：如果条件允许，为深色模式提供专门的插画版本。
- **图标颜色适配**：确保图标颜色使用了 `ColorScheme` 中的语义色（如 `onSurface`），这样切换主题时会自动适配。

---

## 6.5 示例：一键切换深色/浅色

以下是一个完整的示例，演示如何在页面级别实现深色/浅色主题的动态切换。我们使用 `ValueNotifier<ThemeMode>` 管理状态，用 `AnimatedTheme` 实现平滑过渡。

```dart
import 'package:flutter/material.dart';

class DarkLightExample extends StatefulWidget {
  const DarkLightExample({super.key});

  @override
  State<DarkLightExample> createState() => _DarkLightExampleState();
}

class _DarkLightExampleState extends State<DarkLightExample> {
  // 使用 ValueNotifier 管理主题模式
  final _themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  final _seedColor = Colors.indigo;

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        // 根据当前模式决定使用亮色还是暗色
        final brightness = mode == ThemeMode.dark
            ? Brightness.dark
            : mode == ThemeMode.light
                ? Brightness.light
                : MediaQuery.platformBrightnessOf(context);
        final theme = _buildTheme(brightness);

        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 300),
          child: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('第6章：深色/浅色切换'),
                actions: [
                  IconButton(
                    icon: const Text('☀️'),
                    onPressed: () => _themeMode.value = ThemeMode.light,
                  ),
                  IconButton(
                    icon: const Text('🌙'),
                    onPressed: () => _themeMode.value = ThemeMode.dark,
                  ),
                  IconButton(
                    icon: const Text('📱'),
                    onPressed: () => _themeMode.value = ThemeMode.system,
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 各种 Material 组件展示...
                  Text('当前模式: ${mode.name}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('主题示例'),
                      subtitle: const Text('观察组件在不同主题下的表现'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('ElevatedButton'),
                  ),
                  // ... 更多组件
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

完整的可运行代码请参见 `lib/examples/ex06_dark_light.dart`。

---

## 6.6 小结

本章我们学习了深色/浅色主题切换的完整知识：

1. **深色模式的意义**：护眼、省电、尊重用户偏好，是现代应用的标配。
2. **MaterialApp 的 themeMode**：通过 `theme` + `darkTheme` + `themeMode` 三个属性即可实现主题切换。
3. **状态管理方案**：可以用 `ValueNotifier`、`InheritedWidget` 或 `Provider` 管理 `ThemeMode`。
4. **深色主题设计要点**：不要简单反转颜色，surface 避免纯黑，注意对比度，理解 surface tint。
5. **AnimatedTheme**：可以让主题切换有平滑的过渡动画。

> **下一章**我们将学习如何在 Widget 树中局部覆盖主题，以及动态主题的高级技巧。
