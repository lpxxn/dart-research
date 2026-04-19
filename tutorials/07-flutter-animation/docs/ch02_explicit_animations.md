# 第2章：显式动画 (Explicit Animations)

## 目录

1. [什么是显式动画](#什么是显式动画)
2. [AnimationController](#animationcontroller)
3. [SingleTickerProviderStateMixin](#singletickerproviderstateMixin)
4. [Tween](#tween)
5. [CurvedAnimation](#curvedanimation)
6. [AnimatedBuilder](#animatedbuilder)
7. [AnimatedWidget](#animatedwidget)
8. [动画状态监听](#动画状态监听)
9. [最佳实践](#最佳实践)

---

## 什么是显式动画

显式动画（Explicit Animations）给予你**完全的控制权**。与隐式动画不同，你需要手动：

1. **创建 AnimationController**：驱动动画的核心引擎
2. **定义 Tween**：指定值的变化范围
3. **控制播放**：手动调用 forward()、reverse()、repeat() 等
4. **管理生命周期**：在 dispose() 中释放资源

### 为什么需要显式动画？

- **循环动画**：如 loading 指示器、旋转图标
- **精确控制**：暂停、倒放、跳转到特定位置
- **复杂编排**：多个动画协调执行（交错动画，见第3章）
- **手势驱动**：拖拽进度与动画值绑定

---

## AnimationController

`AnimationController` 是显式动画的核心。它本质上是一个**随时间变化的 double 值生成器**，默认在 0.0 到 1.0 之间。

```dart
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),  // 动画总时长
      vsync: this,  // 垂直同步，防止屏幕外动画浪费资源
    );
  }

  @override
  void dispose() {
    _controller.dispose();  // 必须释放！否则内存泄漏
    super.dispose();
  }
}
```

### 常用控制方法

```dart
_controller.forward();              // 正向播放（0.0 → 1.0）
_controller.reverse();              // 反向播放（1.0 → 0.0）
_controller.repeat();               // 循环播放
_controller.repeat(reverse: true);  // 来回循环播放
_controller.stop();                 // 停止
_controller.reset();                // 重置到起点
_controller.animateTo(0.5);         // 动画到指定值
```

### 常用属性

```dart
_controller.value;      // 当前值（0.0~1.0）
_controller.status;     // 动画状态（forward, reverse, completed, dismissed）
_controller.isAnimating // 是否正在运行
```

### 自定义值范围

```dart
AnimationController(
  duration: const Duration(seconds: 1),
  lowerBound: 0.0,   // 最小值（默认 0.0）
  upperBound: 1.0,    // 最大值（默认 1.0）
  vsync: this,
);
```

---

## SingleTickerProviderStateMixin

`vsync` 参数需要一个 `TickerProvider`。它的作用是：

1. **同步屏幕刷新**：确保动画每帧只更新一次（通常 60fps 或 120fps）
2. **节省资源**：当 Widget 不可见时自动暂停动画

```dart
// 只有一个 AnimationController 时使用
class _MyState extends State<MyWidget>
    with SingleTickerProviderStateMixin { ... }

// 有多个 AnimationController 时使用
class _MyState extends State<MyWidget>
    with TickerProviderStateMixin { ... }
```

### 为什么不能用 `SingleTickerProviderStateMixin` 管理多个 Controller？

因为 `SingleTickerProviderStateMixin` 内部只允许创建一个 Ticker。如果你尝试创建第二个 AnimationController 并传入 `vsync: this`，会抛出异常。

---

## Tween

`Tween`（补间）定义了动画值的**映射关系**——将 Controller 的 0.0~1.0 映射到你需要的值范围：

```dart
// 数值补间
final sizeTween = Tween<double>(begin: 50.0, end: 200.0);

// 颜色补间
final colorTween = ColorTween(begin: Colors.red, end: Colors.blue);

// Offset 补间
final offsetTween = Tween<Offset>(begin: Offset.zero, end: const Offset(1.0, 0.0));
```

### 使用 Tween

```dart
// 方式1：通过 animate() 创建 Animation 对象
final Animation<double> sizeAnimation = sizeTween.animate(_controller);

// 方式2：通过 evaluate() 获取某一时刻的值
double currentSize = sizeTween.evaluate(_controller);

// 方式3：配合 CurvedAnimation 使用
final Animation<double> curvedSizeAnimation = sizeTween.animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeOut),
);
```

### 常用 Tween 类型

| Tween 类型 | 说明 | 示例 |
|-----------|------|------|
| `Tween<double>` | 数值补间 | 大小、透明度、角度 |
| `ColorTween` | 颜色补间 | 背景色渐变 |
| `IntTween` | 整数补间 | 计数器 |
| `AlignmentTween` | 对齐补间 | 位置移动 |
| `BorderRadiusTween` | 圆角补间 | 形状变化 |
| `DecorationTween` | 装饰补间 | 复合样式变化 |

---

## CurvedAnimation

`CurvedAnimation` 将非线性曲线应用到 AnimationController 上：

```dart
final curvedAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.easeInOut,      // 正向播放的曲线
  reverseCurve: Curves.easeIn,  // 反向播放的曲线（可选）
);

// 然后用 curvedAnimation 替代 _controller 来驱动 Tween
final animation = Tween<double>(begin: 0, end: 300).animate(curvedAnimation);
```

### 组合链

一个完整的动画链条是这样的：

```
AnimationController (0.0 ~ 1.0, 线性)
    ↓
CurvedAnimation (应用曲线)
    ↓
Tween.animate() (映射到目标值范围)
    ↓
Animation<T> (最终可用的动画值)
```

---

## AnimatedBuilder

`AnimatedBuilder`（即 `AnimatedBuilder`）是将动画值应用到 Widget 树的推荐方式：

```dart
AnimatedBuilder(
  animation: _controller,  // 监听的动画对象
  builder: (context, child) {
    return Transform.rotate(
      angle: _controller.value * 2 * pi,
      child: child,  // 不变的子树，不会每帧重建
    );
  },
  child: const Icon(Icons.refresh, size: 60),  // 性能优化
)
```

### 为什么用 AnimatedBuilder 而不是 setState？

```dart
// ❌ 不推荐：整个 build 方法都会重新执行
_controller.addListener(() {
  setState(() {});
});

// ✅ 推荐：只有 AnimatedBuilder 的 builder 部分重建
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child,
    );
  },
  child: const HeavyWidget(),  // 不会重建
)
```

使用 `AnimatedBuilder` 的好处：
1. **精确的重建范围**：只重建 builder 内的 Widget
2. **child 优化**：不变的子树只构建一次
3. **代码清晰**：动画逻辑集中在 builder 中

---

## AnimatedWidget

`AnimatedWidget` 是另一种封装动画逻辑的方式——通过创建自定义 Widget 类：

```dart
class SpinningIcon extends AnimatedWidget {
  const SpinningIcon({super.key, required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.rotate(
      angle: animation.value * 2 * pi,
      child: const Icon(Icons.settings, size: 60),
    );
  }
}

// 使用时
SpinningIcon(animation: _controller)
```

### AnimatedBuilder vs AnimatedWidget

| 特性 | AnimatedBuilder | AnimatedWidget |
|------|----------------|----------------|
| 使用方式 | 在 build 中内联使用 | 创建独立的 Widget 类 |
| 复用性 | 较低 | 高（可在多处使用） |
| child 优化 | 内置 child 参数 | 需自行处理 |
| 适用场景 | 一次性使用的动画 | 可复用的动画组件 |

---

## 动画状态监听

### 监听动画值变化

```dart
_controller.addListener(() {
  print('当前值：${_controller.value}');
});
```

### 监听动画状态变化

```dart
_controller.addStatusListener((status) {
  switch (status) {
    case AnimationStatus.dismissed:
      print('动画在起点（0.0）');
      break;
    case AnimationStatus.forward:
      print('正在正向播放');
      break;
    case AnimationStatus.reverse:
      print('正在反向播放');
      break;
    case AnimationStatus.completed:
      print('动画在终点（1.0）');
      break;
  }
});
```

### 实现来回循环动画

```dart
_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    _controller.reverse();
  } else if (status == AnimationStatus.dismissed) {
    _controller.forward();
  }
});
```

> **更简洁的方式**：`_controller.repeat(reverse: true);`

---

## 最佳实践

### 1. 始终在 dispose 中释放 Controller

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

不释放会导致内存泄漏和 `setState() called after dispose()` 错误。

### 2. 根据 Controller 数量选择 Mixin

```dart
// 一个 Controller
with SingleTickerProviderStateMixin

// 多个 Controller
with TickerProviderStateMixin
```

### 3. 使用 AnimatedBuilder 的 child 参数

```dart
// ✅ 
AnimatedBuilder(
  animation: _controller,
  builder: (_, child) => Transform.scale(
    scale: _animation.value,
    child: child,
  ),
  child: const MyComplexWidget(),  // 只构建一次
)
```

### 4. 考虑使用内置的 Transition 组件

Flutter 提供了许多基于显式动画的 Transition 组件：

```dart
FadeTransition(opacity: _animation, child: ...)
ScaleTransition(scale: _animation, child: ...)
RotationTransition(turns: _animation, child: ...)
SlideTransition(position: _offsetAnimation, child: ...)
SizeTransition(sizeFactor: _animation, child: ...)
```

这些组件内部已经优化了 child 的重建，直接使用即可。

### 5. 合理使用 Interval

当一个 Controller 驱动多个动画时（详见第3章），使用 `Interval` 让不同动画在不同时间段执行。

---

## 本章示例代码

查看 `lib/ch02_explicit_animations.dart`，该示例展示了：
- AnimationController 的基本用法
- Tween + CurvedAnimation 的组合
- AnimatedBuilder 构建动画 UI
- AnimatedWidget 的自定义封装
- FadeTransition / RotationTransition / ScaleTransition 的使用
- 动画状态监听与控制

运行方式：
```bash
flutter run -t lib/ch02_explicit_animations.dart
```
