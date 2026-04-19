# 第1章：隐式动画 (Implicit Animations)

## 目录

1. [什么是隐式动画](#什么是隐式动画)
2. [核心概念：duration 与 curve](#核心概念duration-与-curve)
3. [常用隐式动画组件](#常用隐式动画组件)
4. [AnimatedContainer](#animatedcontainer)
5. [AnimatedOpacity](#animatedopacity)
6. [AnimatedPositioned](#animatedpositioned)
7. [AnimatedPadding](#animatedpadding)
8. [AnimatedDefaultTextStyle](#animateddefaulttextstyle)
9. [AnimatedCrossFade](#animatedcrossfade)
10. [AnimatedSwitcher](#animatedswitcher)
11. [TweenAnimationBuilder](#tweenanimationbuilder)
12. [最佳实践](#最佳实践)

---

## 什么是隐式动画

隐式动画（Implicit Animations）是 Flutter 中最简单的动画方式。你只需要：

1. **设置目标值**：告诉 Widget 你想要的最终状态
2. **Flutter 自动补间**：框架会自动在旧值和新值之间创建平滑过渡

之所以叫"隐式"，是因为你**不需要手动管理 AnimationController**，不需要关心动画的每一帧，Flutter 帮你处理了所有细节。

### 隐式动画 vs 显式动画

| 特性 | 隐式动画 | 显式动画 |
|------|---------|---------|
| 复杂度 | 低 | 高 |
| 控制力 | 有限 | 完全控制 |
| 需要 Controller | 否 | 是 |
| 适用场景 | 简单的属性变化 | 复杂的、连续的动画 |
| 典型用法 | 改变颜色、大小、位置 | 旋转、路径动画、交错动画 |

---

## 核心概念：duration 与 curve

几乎所有隐式动画组件都有两个关键参数：

### Duration（持续时间）

`Duration` 定义了动画从开始到结束所需的时间：

```dart
// 常见的 duration 设置
const Duration(milliseconds: 300)  // 0.3 秒，适合微交互
const Duration(milliseconds: 500)  // 0.5 秒，适合中等变化
const Duration(seconds: 1)         // 1 秒，适合大幅变化
```

**经验法则**：
- 微交互（按钮状态变化）：200-300ms
- 中等变化（展开/折叠）：300-500ms
- 大幅变化（页面转场）：500-800ms

### Curve（动画曲线）

`Curve` 定义了动画的速度变化规律。Flutter 内置了丰富的曲线：

```dart
Curves.linear       // 匀速运动
Curves.easeIn       // 先慢后快
Curves.easeOut      // 先快后慢
Curves.easeInOut    // 先慢后快再慢（最常用）
Curves.bounceOut    // 弹跳效果
Curves.elasticOut   // 弹性效果
Curves.fastOutSlowIn // Material Design 标准曲线
```

**曲线的数学本质**：曲线本质上是一个 `f(t) → t'` 的映射函数，其中 t 是时间进度（0.0~1.0），t' 是动画进度。例如 `easeIn` 的效果是前半段时间走过不到一半的动画进度。

---

## 常用隐式动画组件

Flutter 提供了大量以 `Animated` 开头的隐式动画组件，它们都是对应普通组件的动画版本：

| 隐式动画组件 | 对应普通组件 | 可动画化的属性 |
|-------------|------------|--------------|
| AnimatedContainer | Container | 几乎所有属性 |
| AnimatedOpacity | Opacity | opacity |
| AnimatedPositioned | Positioned | left/top/right/bottom/width/height |
| AnimatedPadding | Padding | padding |
| AnimatedDefaultTextStyle | DefaultTextStyle | style |
| AnimatedCrossFade | — | 两个子组件之间切换 |
| AnimatedSwitcher | — | 子组件替换时的过渡 |

---

## AnimatedContainer

`AnimatedContainer` 是最强大的隐式动画组件，几乎可以动画化 `Container` 的所有属性。

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
  width: _expanded ? 200 : 100,
  height: _expanded ? 200 : 100,
  decoration: BoxDecoration(
    color: _expanded ? Colors.blue : Colors.red,
    borderRadius: BorderRadius.circular(_expanded ? 30 : 10),
  ),
  child: const Center(child: Text('点我')),
)
```

### 可动画化的属性

- `width` / `height`
- `color`（通过 decoration）
- `padding` / `margin`
- `alignment`
- `borderRadius`
- `transform`（矩阵变换）
- `constraints`

### 工作原理

当你在 `setState` 中改变 `_expanded` 的值时：
1. Flutter 检测到 AnimatedContainer 的属性发生了变化
2. 自动创建从旧值到新值的补间动画（Tween）
3. 在指定的 duration 内，按照 curve 的节奏，逐帧更新属性值

---

## AnimatedOpacity

用于平滑地改变子组件的透明度：

```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: _visible ? 1.0 : 0.0,
  child: const Text('淡入淡出'),
)
```

> **注意**：`AnimatedOpacity` 只改变透明度，组件仍然占据布局空间。如果你需要在隐藏时不占据空间，考虑结合 `AnimatedCrossFade` 或 `Visibility`。

---

## AnimatedPositioned

在 `Stack` 中动画化子组件的位置：

```dart
Stack(
  children: [
    AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      left: _moved ? 200 : 0,
      top: _moved ? 100 : 0,
      child: Container(width: 50, height: 50, color: Colors.green),
    ),
  ],
)
```

---

## AnimatedPadding

平滑地改变内边距：

```dart
AnimatedPadding(
  duration: const Duration(milliseconds: 300),
  padding: EdgeInsets.all(_expanded ? 32.0 : 8.0),
  child: Container(color: Colors.orange),
)
```

---

## AnimatedDefaultTextStyle

动画化文本样式变化（字体大小、颜色、字重等）：

```dart
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 400),
  style: _highlighted
      ? const TextStyle(fontSize: 28, color: Colors.red, fontWeight: FontWeight.bold)
      : const TextStyle(fontSize: 16, color: Colors.black),
  child: const Text('动态文字样式'),
)
```

---

## AnimatedCrossFade

在两个子组件之间做交叉淡入淡出切换：

```dart
AnimatedCrossFade(
  duration: const Duration(milliseconds: 300),
  // 根据条件决定显示哪个子组件
  crossFadeState: _showFirst
      ? CrossFadeState.showFirst
      : CrossFadeState.showSecond,
  // 第一个子组件
  firstChild: const Icon(Icons.play_arrow, size: 80),
  // 第二个子组件
  secondChild: const Icon(Icons.pause, size: 80),
)
```

### 特点

- 同时处理**淡入淡出**和**大小变化**
- 自动处理两个子组件大小不同的情况
- 可以通过 `sizeCurve` 自定义大小变化的曲线

---

## AnimatedSwitcher

当子组件被替换时自动执行过渡动画：

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  // 自定义过渡效果
  transitionBuilder: (child, animation) {
    return ScaleTransition(scale: animation, child: child);
  },
  // 关键：必须给子组件设置不同的 key
  child: Text(
    '$_count',
    key: ValueKey<int>(_count),
    style: const TextStyle(fontSize: 40),
  ),
)
```

### 重要：Key 的作用

`AnimatedSwitcher` 通过比较子组件的 **key** 来判断是否需要执行过渡动画。如果不设置 key，Flutter 会认为是同一个组件，不会触发动画。

---

## TweenAnimationBuilder

`TweenAnimationBuilder` 是隐式动画的"瑞士军刀"——当内置的 Animated* 组件无法满足需求时，用它可以动画化**任意值**：

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: _targetAngle),
  duration: const Duration(milliseconds: 600),
  builder: (context, value, child) {
    return Transform.rotate(
      angle: value,
      child: child,
    );
  },
  child: const Icon(Icons.refresh, size: 50),  // child 优化：不会每帧重建
)
```

### 关键特性

1. **泛型支持**：可以补间 `double`、`Color`、`Offset`、`Size` 等任意可插值类型
2. **child 优化**：`builder` 的第三个参数 `child` 不会在动画过程中重建，适合传入不变的子树
3. **自动处理 tween 变化**：当 `tween.end` 改变时，自动从当前值过渡到新的目标值

### 何时使用 TweenAnimationBuilder

- 需要动画化某个自定义属性（如旋转角度、缩放比例）
- 内置 Animated* 组件不支持的属性组合
- 需要在动画过程中做自定义的 UI 变换

---

## 最佳实践

### 1. 选择合适的 Duration

```dart
// ❌ 太快，用户感知不到
const Duration(milliseconds: 50)

// ❌ 太慢，让用户等待
const Duration(seconds: 3)

// ✅ 适中，流畅自然
const Duration(milliseconds: 300)
```

### 2. 使用语义化的 Curve

```dart
// 元素进入屏幕：先快后慢
Curves.easeOut

// 元素离开屏幕：先慢后快
Curves.easeIn

// 元素在屏幕内移动：先慢后快再慢
Curves.easeInOut
```

### 3. 避免过度动画

不要给每个属性都加动画。只对**用户关注的**、**有意义的**变化添加动画。

### 4. 利用 child 参数优化性能

```dart
// ✅ child 不会在动画过程中重建
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: const Duration(seconds: 1),
  builder: (context, value, child) {
    return Opacity(opacity: value, child: child);
  },
  child: const ExpensiveWidget(),  // 只构建一次
)
```

### 5. 当隐式动画不够用时

如果你需要以下功能，请考虑使用显式动画（第2章）：
- 无限循环的动画
- 精确控制动画的播放/暂停/倒放
- 多个动画的同步协调
- 基于手势的动画

---

## 本章示例代码

查看 `lib/ch01_implicit_animations.dart`，该示例展示了：
- AnimatedContainer 的多属性动画
- AnimatedOpacity 的淡入淡出
- AnimatedCrossFade 的组件切换
- AnimatedSwitcher 的计数器过渡
- TweenAnimationBuilder 的自定义动画

运行方式：
```bash
flutter run -t lib/ch01_implicit_animations.dart
```
