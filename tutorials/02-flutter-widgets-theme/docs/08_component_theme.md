# 第8章 — 组件级主题定制

> Material Design 的每个组件都有对应的主题类，通过 ThemeData 中的 xxxTheme 属性，可以全局统一组件的视觉风格。

---

## 8.1 什么是组件级主题

### ThemeData 中的 xxxTheme 属性

Flutter 的 `ThemeData` 不仅包含颜色和字体这些基础属性，还提供了几十个**组件主题**属性，用于控制每一种 Material 组件的默认外观：

```dart
ThemeData(
  elevatedButtonTheme: ElevatedButtonThemeData(...),
  outlinedButtonTheme: OutlinedButtonThemeData(...),
  inputDecorationTheme: InputDecorationTheme(...),
  cardTheme: CardTheme(...),
  chipTheme: ChipThemeData(...),
  navigationBarTheme: NavigationBarThemeData(...),
  tabBarTheme: TabBarTheme(...),
  // ... 还有很多
)
```

### 每个 Material 组件都有对应的主题类

这是 Flutter Material 3 设计系统的核心理念之一：组件的默认样式可以通过主题系统全局配置，而不需要在每个组件实例上重复设置。

例如：
- `ElevatedButton` → `ElevatedButtonThemeData`
- `TextField` → `InputDecorationTheme`
- `Card` → `CardTheme`
- `Chip` → `ChipThemeData`
- `AppBar` → `AppBarTheme`
- `NavigationBar` → `NavigationBarThemeData`

### 全局定义 vs 局部覆盖

组件主题有两种使用方式：

1. **全局定义**：在 `MaterialApp` 的 `theme` 中设置，影响整个应用
2. **局部覆盖**：用 `Theme` widget 包裹子树，只影响子树中的组件

```dart
// 全局：所有 ElevatedButton 都是胶囊形
MaterialApp(
  theme: ThemeData(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: StadiumBorder(),
      ),
    ),
  ),
);

// 局部：只有这个子树中的 ElevatedButton 是方形
Theme(
  data: Theme.of(context).copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(),
      ),
    ),
  ),
  child: MySpecialPage(),
);
```

---

## 8.2 按钮主题定制

### ElevatedButtonThemeData

`ElevatedButtonThemeData` 只有一个 `style` 属性，接收 `ButtonStyle` 对象。`ButtonStyle` 是按钮主题中最核心的类，几乎控制了按钮外观的方方面面。

### ButtonStyle 详解

```dart
ButtonStyle(
  // 文字/图标颜色
  foregroundColor: WidgetStateProperty.all(Colors.white),
  // 背景颜色
  backgroundColor: WidgetStateProperty.all(Color(0xFF6750A4)),
  // 按下/悬停时的覆盖层颜色
  overlayColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return Colors.white.withAlpha(30);
    }
    if (states.contains(WidgetState.hovered)) {
      return Colors.white.withAlpha(20);
    }
    return null;
  }),
  // 形状
  shape: WidgetStateProperty.all(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  // 内边距
  padding: WidgetStateProperty.all(
    EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  ),
  // 阴影高度
  elevation: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) return 0.0;
    if (states.contains(WidgetState.hovered)) return 4.0;
    return 2.0;
  }),
  // 文字样式
  textStyle: WidgetStateProperty.all(
    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
)
```

### WidgetStateProperty 条件样式

`WidgetStateProperty` 是按钮主题的灵魂。它允许你根据按钮的不同交互状态返回不同的样式值：

| 状态 | 说明 |
|------|------|
| `WidgetState.hovered` | 鼠标悬停（桌面/Web 端） |
| `WidgetState.pressed` | 按下 |
| `WidgetState.focused` | 获得焦点 |
| `WidgetState.disabled` | 禁用 |
| `WidgetState.selected` | 选中（如 ToggleButton） |
| `WidgetState.dragged` | 拖拽中 |

```dart
// 示例：禁用时半透明，正常时品牌色
WidgetStateProperty.resolveWith<Color>((states) {
  if (states.contains(WidgetState.disabled)) {
    return Color(0xFF6750A4).withAlpha(100);
  }
  return Color(0xFF6750A4);
})
```

### 其他按钮主题

除了 `ElevatedButtonThemeData`，还有：

- **`OutlinedButtonThemeData`**：轮廓按钮，通常只有边框没有填充
- **`TextButtonThemeData`**：文字按钮，没有边框和填充
- **`IconButtonThemeData`**：图标按钮

它们的结构都是一样的——只有一个 `style` 属性，接收 `ButtonStyle`。

### 代码示例：统一品牌按钮样式

```dart
ThemeData(
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF6750A4),
      foregroundColor: Colors.white,
      shape: StadiumBorder(),           // 胶囊形
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Color(0xFF6750A4),
      side: BorderSide(color: Color(0xFF6750A4), width: 1.5),
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Color(0xFF6750A4),
    ),
  ),
)
```

---

## 8.3 输入框主题

### InputDecorationTheme

`InputDecorationTheme` 控制 `TextField`、`TextFormField` 等输入组件的装饰样式。它的属性非常丰富：

```dart
InputDecorationTheme(
  // 是否填充背景
  filled: true,
  fillColor: Color(0xFFF0F0F0),
  
  // 默认边框
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  // 聚焦时边框
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Color(0xFF6750A4), width: 2),
  ),
  // 错误时边框
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red, width: 1.5),
  ),
  // 聚焦+错误时边框
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),
  
  // 标签样式
  labelStyle: TextStyle(color: Colors.grey[600]),
  // 提示文字样式
  hintStyle: TextStyle(color: Colors.grey[400]),
  
  // 内边距
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
)
```

### 统一圆角输入框 + 聚焦高亮

上面的配置实现了一种常见的现代输入框设计：
- 默认状态：浅灰填充、无边框、圆角
- 聚焦状态：品牌色边框突出显示
- 错误状态：红色边框警示

这比在每个 `TextField` 上单独设置 `decoration` 要高效得多。

---

## 8.4 卡片主题

### CardTheme

`CardTheme` 控制所有 `Card` 组件的默认样式：

```dart
CardTheme(
  // 卡片背景色
  color: Colors.white,
  // 阴影高度
  elevation: 2,
  // 形状（圆角）
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  // 外边距
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  // 裁剪行为
  clipBehavior: Clip.antiAlias,
)
```

### 统一卡片圆角 + 阴影

通过 `CardTheme` 统一设置，可以确保整个应用中的卡片视觉一致：

```dart
ThemeData(
  cardTheme: CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: Colors.black.withAlpha(40),
  ),
)
```

一旦全局设置后，所有 `Card()` 组件自动继承这些样式，无需逐一配置。

---

## 8.5 导航组件主题

### NavigationBarThemeData

Material 3 的底部导航栏组件 `NavigationBar` 可以通过 `NavigationBarThemeData` 定制：

```dart
NavigationBarThemeData(
  // 背景色
  backgroundColor: Colors.white,
  // 指示器颜色（选中项的背景）
  indicatorColor: Color(0xFF6750A4).withAlpha(30),
  // 选中图标颜色
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return IconThemeData(color: Color(0xFF6750A4));
    }
    return IconThemeData(color: Colors.grey);
  }),
  // 标签样式
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return TextStyle(
        color: Color(0xFF6750A4),
        fontWeight: FontWeight.w600,
      );
    }
    return TextStyle(color: Colors.grey);
  }),
)
```

### TabBarTheme

`TabBarTheme` 控制 `TabBar` 的样式：

```dart
TabBarTheme(
  // 选中标签颜色
  labelColor: Color(0xFF6750A4),
  // 未选中标签颜色
  unselectedLabelColor: Colors.grey,
  // 指示器装饰
  indicator: UnderlineTabIndicator(
    borderSide: BorderSide(color: Color(0xFF6750A4), width: 3),
  ),
  // 标签内边距
  labelPadding: EdgeInsets.symmetric(horizontal: 16),
)
```

### DrawerThemeData

`DrawerThemeData` 控制抽屉导航的样式：

```dart
DrawerThemeData(
  backgroundColor: Colors.white,
  elevation: 8,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
  ),
)
```

---

## 8.6 局部覆盖 Theme

### 使用 Theme widget 局部覆盖

有时候，某个页面或组件树需要不同于全局的主题。这时可以用 `Theme` widget 包裹子树，通过 `copyWith` 只覆盖需要修改的部分：

```dart
Theme(
  data: Theme.of(context).copyWith(
    // 只在这个子树中修改按钮和卡片样式
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.red[50],
      elevation: 0,
    ),
  ),
  child: SpecialPromotionPage(),
)
```

### 使用场景

- **促销页面**：需要特殊的红色配色方案
- **设置页面**：需要更紧凑的间距和更低的阴影
- **深色区域**：页面中某个区域需要深色背景配浅色文字
- **嵌入式主题**：在亮色页面中嵌入一个暗色卡片

**关键原则：** `Theme.of(context)` 会向上查找最近的 `Theme` widget。所以局部覆盖只影响子树，不影响其他部分。

---

## 8.7 示例：统一组件样式

下面是一个完整的示例，展示如何通过组件主题统一整个应用的视觉风格：

```dart
Theme(
  data: Theme.of(context).copyWith(
    // 统一按钮为胶囊形
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    // 统一输入框为圆角填充式
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF6750A4), width: 2),
      ),
    ),
    // 统一卡片为圆角微阴影
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // 统一 Chip 样式
    chipTheme: ChipThemeData(
      shape: StadiumBorder(),
    ),
  ),
  child: Scaffold(
    body: Column(
      children: [
        ElevatedButton(onPressed: () {}, child: Text('胶囊按钮')),
        OutlinedButton(onPressed: () {}, child: Text('轮廓按钮')),
        TextField(decoration: InputDecoration(labelText: '圆角输入框')),
        Card(child: ListTile(title: Text('统一圆角卡片'))),
        Chip(label: Text('标签')),
      ],
    ),
  ),
);
```

所有这些组件都没有单独设置样式，它们的外观完全由主题控制。当需要修改整体风格时，只需修改主题配置，所有组件自动更新。

> 📖 完整代码示例见 `lib/examples/ex08_component_theme.dart`

---

## 8.8 小结

本章我们学习了如何通过组件级主题统一应用的视觉风格：

| 知识点 | 要点 |
|--------|------|
| **组件主题概念** | ThemeData 中的 xxxTheme 属性控制对应组件的默认外观 |
| **ButtonStyle** | 按钮的核心样式类，支持 WidgetStateProperty 条件样式 |
| **WidgetStateProperty** | 根据交互状态（hover/press/disabled）返回不同样式值 |
| **InputDecorationTheme** | 统一输入框的边框、填充、标签样式 |
| **CardTheme** | 统一卡片的圆角、阴影、背景色 |
| **导航组件主题** | NavigationBarThemeData、TabBarTheme、DrawerThemeData |
| **局部覆盖** | 用 Theme widget 的 copyWith 在子树中覆盖特定组件主题 |

在下一章中，我们将探讨**高级话题**——AnimatedTheme 动画主题切换、从 JSON 加载动态主题、主题持久化等进阶内容。
