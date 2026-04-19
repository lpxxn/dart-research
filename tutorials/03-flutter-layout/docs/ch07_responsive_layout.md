# 第七章：响应式布局（Responsive Layout）

## 概述

在移动端、平板和桌面端多平台并存的时代，一个优秀的 Flutter 应用必须能够优雅地适配不同屏幕尺寸。
响应式布局的核心思想是：**根据可用空间动态调整 UI 结构和样式**，而不是为每种设备写一套独立的界面。

Flutter 提供了丰富的工具来实现响应式布局：
- **MediaQuery**：获取屏幕级别的全局信息（尺寸、方向、像素密度、安全区域等）
- **LayoutBuilder**：获取父级组件提供的约束信息，按约束动态构建子组件
- **OrientationBuilder**：专门响应屏幕方向变化
- **SafeArea**：处理刘海屏、底部指示器等系统 UI 遮挡区域

本章将深入讲解这些工具的原理和用法，并介绍断点系统设计和自适应布局的实现策略。

---

## 1. MediaQuery 详解

### 1.1 什么是 MediaQuery

`MediaQuery` 是 Flutter 中获取屏幕和设备信息的核心工具。它以 `InheritedWidget` 的形式存在于
Widget 树中，任何子组件都可以通过 `MediaQuery.of(context)` 获取当前的 `MediaQueryData`。

```dart
final mediaQuery = MediaQuery.of(context);
```

### 1.2 核心属性

#### size — 屏幕逻辑尺寸

```dart
final size = MediaQuery.of(context).size;
print('宽度: ${size.width}, 高度: ${size.height}');
```

`size` 返回的是**逻辑像素**（logical pixels），不是物理像素。逻辑像素是与设备无关的单位，
Flutter 会根据 `devicePixelRatio` 将逻辑像素映射到物理像素。

- iPhone 14: 逻辑宽度约 390，物理宽度 1170（devicePixelRatio = 3.0）
- iPad Pro 12.9": 逻辑宽度约 1024
- 普通桌面浏览器窗口: 宽度通常 > 1200

#### orientation — 屏幕方向

```dart
final orientation = MediaQuery.of(context).orientation;
if (orientation == Orientation.portrait) {
  // 竖屏布局
} else {
  // 横屏布局
}
```

`Orientation` 只有两个值：`portrait`（竖屏）和 `landscape`（横屏）。
判断依据是 `size.width < size.height` 为竖屏，反之为横屏。

#### devicePixelRatio — 设备像素比

```dart
final dpr = MediaQuery.of(context).devicePixelRatio;
print('设备像素比: $dpr');
```

设备像素比表示每个逻辑像素对应多少物理像素：
- `1.0`：低密度屏幕（如早期 Android 设备）
- `2.0`：Retina 屏幕（如 iPhone 8）
- `3.0`：超高密度屏幕（如 iPhone 14 Pro）

**使用场景**：加载不同分辨率的图片资源、精确控制线条粗细等。

#### padding — 安全区域内边距

```dart
final padding = MediaQuery.of(context).padding;
print('顶部安全区: ${padding.top}');    // 刘海屏状态栏高度
print('底部安全区: ${padding.bottom}'); // Home Indicator 高度
```

`padding` 包含了系统 UI 占用的区域：
- `top`：状态栏高度（刘海屏会更大）
- `bottom`：底部指示器高度（如 iPhone X 及以后的机型）
- `left` / `right`：通常为 0，但在某些横屏模式下可能非零

#### viewInsets — 软键盘等系统 UI 遮挡区域

```dart
final viewInsets = MediaQuery.of(context).viewInsets;
print('底部遮挡: ${viewInsets.bottom}'); // 键盘高度
```

`viewInsets` 和 `padding` 的区别：
- `padding`：**始终存在**的系统 UI 区域（状态栏、底部指示器）
- `viewInsets`：**临时出现**的系统 UI 区域（软键盘、系统弹窗）

**典型用法**：当键盘弹出时，自动调整布局避免内容被遮挡。

```dart
// 判断键盘是否弹出
final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
```

#### textScaleFactor — 文字缩放因子

```dart
final textScaler = MediaQuery.of(context).textScaler;
```

用户可以在系统设置中调整文字大小，`textScaler` 反映了这个设置。
良好的响应式布局应该尊重用户的无障碍设置。

### 1.3 MediaQuery.of vs 细粒度查询方法

#### 问题：MediaQuery.of 的性能陷阱

`MediaQuery.of(context)` 会监听**整个** `MediaQueryData` 的变化。这意味着即使你只用了
`size`，当 `viewInsets`（键盘弹出/收起）变化时，你的 Widget 也会重建。

```dart
// ❌ 不推荐：监听了整个 MediaQueryData
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return Text('宽度: ${size.width}');
}
```

#### 解决方案：使用细粒度查询方法

Flutter 3.10+ 引入了一系列静态方法，只监听特定属性的变化：

```dart
// ✅ 推荐：只在 size 变化时重建
final size = MediaQuery.sizeOf(context);

// ✅ 推荐：只在方向变化时重建
final orientation = MediaQuery.orientationOf(context);

// ✅ 推荐：只在 padding 变化时重建
final padding = MediaQuery.paddingOf(context);

// ✅ 推荐：只在 viewInsets 变化时重建
final viewInsets = MediaQuery.viewInsetsOf(context);

// ✅ 推荐：只在像素密度变化时重建
final dpr = MediaQuery.devicePixelRatioOf(context);

// ✅ 推荐：只在文字缩放变化时重建
final textScaler = MediaQuery.textScalerOf(context);

// ✅ 推荐：只在平台亮度变化时重建
final brightness = MediaQuery.platformBrightnessOf(context);
```

#### 性能对比

| 方法 | 触发重建的条件 | 适用场景 |
|------|---------------|---------|
| `MediaQuery.of(context)` | 任何 MediaQueryData 变化 | 需要多个属性时 |
| `MediaQuery.sizeOf(context)` | 仅 size 变化 | 只需要屏幕尺寸 |
| `MediaQuery.orientationOf(context)` | 仅方向变化 | 只需要屏幕方向 |
| `MediaQuery.paddingOf(context)` | 仅 padding 变化 | 只需要安全区域 |
| `MediaQuery.viewInsetsOf(context)` | 仅 viewInsets 变化 | 只需要键盘状态 |

**最佳实践**：始终使用最具体的查询方法，减少不必要的 Widget 重建。

---

## 2. LayoutBuilder 详解

### 2.1 什么是 LayoutBuilder

`LayoutBuilder` 是一个根据**父级约束**（`BoxConstraints`）来构建子组件的 Widget。
与 `MediaQuery` 获取全局屏幕信息不同，`LayoutBuilder` 获取的是**当前组件实际可用的空间**。

```dart
LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) {
    print('最大宽度: ${constraints.maxWidth}');
    print('最大高度: ${constraints.maxHeight}');
    print('最小宽度: ${constraints.minWidth}');
    print('最小高度: ${constraints.minHeight}');

    if (constraints.maxWidth > 600) {
      return const WideLayout();
    } else {
      return const NarrowLayout();
    }
  },
)
```

### 2.2 MediaQuery vs LayoutBuilder

这是一个非常重要的区别：

| 特性 | MediaQuery | LayoutBuilder |
|------|-----------|--------------|
| 信息来源 | 屏幕/窗口级别 | 父组件约束 |
| 获取的尺寸 | 整个屏幕的尺寸 | 当前组件可用的空间 |
| 适用场景 | 全局布局决策 | 局部布局适配 |
| 嵌套使用 | 值不随嵌套变化 | 值随父组件约束变化 |

**关键区别示例**：

```dart
// 假设屏幕宽度 1200px，左侧导航栏占 300px

// MediaQuery 返回的始终是 1200（屏幕宽度）
final screenWidth = MediaQuery.sizeOf(context).width; // 1200

// LayoutBuilder 返回的是实际可用空间 900（减去导航栏）
LayoutBuilder(
  builder: (context, constraints) {
    // constraints.maxWidth = 900
    return buildContent(constraints.maxWidth);
  },
)
```

**最佳实践**：
- 用 `MediaQuery` 做**顶层布局决策**（选择哪种布局模式）
- 用 `LayoutBuilder` 做**组件级别的自适应**（网格列数、卡片大小等）

### 2.3 BoxConstraints 详解

`BoxConstraints` 包含四个属性：

```dart
BoxConstraints(
  minWidth: 0,        // 最小宽度
  maxWidth: 400,      // 最大宽度
  minHeight: 0,       // 最小高度
  maxHeight: double.infinity, // 最大高度（无限制 = 在可滚动容器内）
)
```

常见的约束类型：
- **紧约束（tight）**：`minWidth == maxWidth && minHeight == maxHeight`，子组件必须是这个精确尺寸
- **松约束（loose）**：`min` 为 0，`max` 为正数，子组件可以在 0 到 max 之间选择尺寸
- **无界约束（unbounded）**：`max` 为 `double.infinity`，常见于可滚动容器中

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // 判断约束类型
    if (constraints.isTight) {
      print('紧约束：尺寸已确定');
    }
    if (constraints.maxHeight == double.infinity) {
      print('垂直方向无界：可能在 ListView 内');
    }
    return Container();
  },
)
```

---

## 3. OrientationBuilder

### 3.1 基本用法

`OrientationBuilder` 是专门用来响应屏幕方向变化的 Widget：

```dart
OrientationBuilder(
  builder: (BuildContext context, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return const PortraitLayout();
    } else {
      return const LandscapeLayout();
    }
  },
)
```

### 3.2 与 MediaQuery.orientationOf 的区别

`OrientationBuilder` 和 `MediaQuery.orientationOf` 有一个微妙的区别：

- `MediaQuery.orientationOf(context)`：基于**屏幕**的宽高比
- `OrientationBuilder`：基于**父组件约束**的宽高比

```dart
// 在一个宽度固定为 300、高度为 800 的容器中：
// MediaQuery.orientationOf 可能返回 landscape（如果屏幕是横屏的）
// OrientationBuilder 会返回 portrait（因为 300 < 800）
```

**使用建议**：
- 需要响应设备旋转 → `MediaQuery.orientationOf`
- 需要响应可用空间的比例 → `OrientationBuilder`

---

## 4. 断点系统设计

### 4.1 为什么需要断点系统

断点系统借鉴了 Web 开发中响应式设计的概念。通过定义一组宽度阈值，将屏幕分为不同的类别，
然后为每个类别设计对应的布局。

### 4.2 推荐断点方案

Material Design 3 推荐的断点：

| 断点名称 | 宽度范围 | 典型设备 |
|---------|---------|---------|
| Compact (Mobile) | < 600px | 手机 |
| Medium (Tablet) | 600 - 1024px | 平板 |
| Expanded (Desktop) | > 1024px | 桌面 |

### 4.3 实现断点工具类

```dart
/// 断点类型枚举
enum DeviceType { mobile, tablet, desktop }

/// 断点工具类
class Breakpoints {
  // 断点阈值
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  /// 根据宽度判断设备类型
  static DeviceType getDeviceType(double width) {
    if (width < mobileMaxWidth) return DeviceType.mobile;
    if (width < tabletMaxWidth) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 便捷判断方法
  static bool isMobile(double width) => width < mobileMaxWidth;
  static bool isTablet(double width) =>
      width >= mobileMaxWidth && width < tabletMaxWidth;
  static bool isDesktop(double width) => width >= tabletMaxWidth;
}
```

### 4.4 响应式数值工具

```dart
/// 根据设备类型返回不同的值
T responsiveValue<T>({
  required double width,
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  final deviceType = Breakpoints.getDeviceType(width);
  switch (deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? mobile;
    case DeviceType.desktop:
      return desktop ?? tablet ?? mobile;
  }
}
```

使用示例：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = responsiveValue<int>(
      width: constraints.maxWidth,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    final padding = responsiveValue<double>(
      width: constraints.maxWidth,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    return GridView.count(
      crossAxisCount: columns,
      padding: EdgeInsets.all(padding),
      children: items,
    );
  },
)
```

---

## 5. 自适应布局实现策略

### 5.1 条件渲染

根据屏幕尺寸，选择性地显示或隐藏特定组件：

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final isMobile = Breakpoints.isMobile(width);

  return Scaffold(
    // 移动端显示 AppBar，桌面端不显示
    appBar: isMobile ? AppBar(title: const Text('首页')) : null,
    // 移动端显示底部导航，桌面端不显示
    bottomNavigationBar: isMobile
        ? NavigationBar(
            destinations: const [...],
            selectedIndex: _currentIndex,
          )
        : null,
    body: Row(
      children: [
        // 桌面端显示侧边导航
        if (!isMobile)
          NavigationRail(
            destinations: const [...],
            selectedIndex: _currentIndex,
          ),
        // 主内容区域
        Expanded(child: _buildContent()),
      ],
    ),
  );
}
```

### 5.2 自适应间距

使用断点系统动态调整间距和内边距：

```dart
class ResponsiveSpacing {
  static EdgeInsets pagePadding(double width) {
    if (Breakpoints.isMobile(width)) {
      return const EdgeInsets.all(16);
    } else if (Breakpoints.isTablet(width)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }
  }

  static double itemSpacing(double width) {
    if (Breakpoints.isMobile(width)) return 8;
    if (Breakpoints.isTablet(width)) return 16;
    return 24;
  }
}
```

### 5.3 弹性网格

使用 `LayoutBuilder` + `GridView` 实现自适应网格：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // 每个卡片最小宽度 200px
    const minCardWidth = 200.0;
    final columns = (constraints.maxWidth / minCardWidth).floor().clamp(1, 6);
    final spacing = Breakpoints.isMobile(constraints.maxWidth) ? 8.0 : 16.0;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(item: items[index]),
    );
  },
)
```

---

## 6. SafeArea 详解

### 6.1 什么是 SafeArea

`SafeArea` 是一个自动避开系统 UI 遮挡区域的 Widget。它会在刘海屏的顶部、
底部 Home Indicator、以及可能的左右圆角区域添加相应的内边距。

```dart
SafeArea(
  child: Scaffold(
    body: YourContent(),
  ),
)
```

### 6.2 SafeArea 的参数

```dart
SafeArea(
  top: true,       // 是否避开顶部（状态栏/刘海）
  bottom: true,    // 是否避开底部（Home Indicator）
  left: true,      // 是否避开左侧
  right: true,     // 是否避开右侧
  minimum: EdgeInsets.all(16), // 最小内边距
  child: YourContent(),
)
```

### 6.3 何时使用 SafeArea

| 场景 | 是否需要 SafeArea |
|------|------------------|
| 使用 Scaffold + AppBar | 不需要（AppBar 自动处理） |
| 自定义全屏页面 | 需要 |
| 底部有固定按钮 | 需要处理 bottom |
| 横屏模式 | 需要处理 left/right |
| Scaffold 的 body 内容 | 通常不需要（Scaffold 已处理） |

### 6.4 手动处理安全区域

有时你需要更精细的控制：

```dart
Widget build(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);

  return Padding(
    padding: EdgeInsets.only(
      top: padding.top,
      bottom: padding.bottom + 16, // 安全区域 + 额外间距
    ),
    child: YourContent(),
  );
}
```

---

## 7. 综合实战：多端自适应布局

### 7.1 整体架构

一个典型的响应式应用架构如下：

```
App
├── Mobile Layout (< 600px)
│   ├── AppBar
│   ├── Body (单列)
│   └── BottomNavigationBar
├── Tablet Layout (600 - 1024px)
│   ├── NavigationRail（左侧）
│   └── Body (两列)
└── Desktop Layout (> 1024px)
    ├── NavigationDrawer（左侧永久展示）
    ├── Content (主内容)
    └── Detail Panel（右侧详情面板）
```

### 7.2 实现要点

1. **顶层使用 MediaQuery 选择布局模式**
2. **内部组件使用 LayoutBuilder 做细粒度适配**
3. **使用断点工具类统一管理阈值**
4. **SafeArea 处理安全区域**
5. **字体大小和间距跟随屏幕缩放**

### 7.3 响应式字体

```dart
double responsiveFontSize(BuildContext context, {double base = 14}) {
  final width = MediaQuery.sizeOf(context).width;
  if (Breakpoints.isMobile(width)) return base;
  if (Breakpoints.isTablet(width)) return base * 1.1;
  return base * 1.2;
}
```

---

## 8. 最佳实践总结

### 8.1 性能优化

1. **使用细粒度 MediaQuery 方法**（`sizeOf`、`orientationOf` 等）减少不必要的重建
2. **避免在 build 方法中做复杂计算**，将断点判断结果缓存为局部变量
3. **使用 const 构造函数**，让 Flutter 跳过不变的子树重建
4. **将响应式逻辑提升到最近的必要层级**，不要在每个叶子节点都查询 MediaQuery

### 8.2 代码组织

1. **统一的断点定义**：在一个地方定义所有断点，全局引用
2. **布局与内容分离**：将响应式布局逻辑和业务内容分开
3. **使用工具函数/类**：封装 `responsiveValue`、`ResponsiveSpacing` 等工具
4. **测试不同尺寸**：使用 Flutter 的 `MediaQuery` override 在测试中模拟不同屏幕

### 8.3 设计原则

1. **移动优先**（Mobile First）：先设计移动端布局，再逐步扩展到大屏
2. **内容优先**：布局变化应该服务于内容的可读性和可用性
3. **渐进增强**：大屏增加更多信息密度，而不是简单地放大
4. **保持一致性**：不同尺寸下的导航和交互模式应该保持逻辑一致

### 8.4 常见陷阱

1. **不要硬编码像素值**：使用相对值和断点系统
2. **不要忽略横屏模式**：很多用户会旋转设备
3. **不要忽略键盘弹出**：键盘会改变可用空间，尤其是表单页面
4. **不要忘记 SafeArea**：刘海屏和底部指示器需要额外处理
5. **不要过度响应**：不是每个组件都需要响应式，只在需要的地方使用

---

## 9. 参考资料

- [Flutter 官方文档 - Adaptive and responsive design](https://docs.flutter.dev/ui/adaptive-responsive)
- [Material Design 3 - Layout](https://m3.material.io/foundations/layout/overview)
- [MediaQuery API 文档](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- [LayoutBuilder API 文档](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html)
