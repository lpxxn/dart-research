# 第5章：物理动画 (Physics-based Animations)

## 目录

1. [什么是物理动画](#什么是物理动画)
2. [物理动画 vs 补间动画](#物理动画-vs-补间动画)
3. [SpringSimulation 与 SpringDescription](#springsimulation-与-springdescription)
4. [animateWith 方法](#animatewith-方法)
5. [拖拽释放弹回效果](#拖拽释放弹回效果)
6. [弹簧参数调优](#弹簧参数调优)
7. [其他物理模拟](#其他物理模拟)
8. [最佳实践](#最佳实践)

---

## 什么是物理动画

物理动画（Physics-based Animations）模拟**真实世界的物理行为**，让动画看起来更加自然和真实。与补间动画（从 A 到 B 的线性插值）不同，物理动画考虑的是：

- **速度**：物体的初始速度会影响运动轨迹
- **力**：弹力、摩擦力、重力等作用于物体
- **质量**：物体的质量影响运动响应
- **阻尼**：能量随时间的衰减

### 常见的物理动画

| 效果 | 物理模型 | 典型应用 |
|------|---------|---------|
| 弹回 | 弹簧（Spring） | 拖拽释放、下拉刷新 |
| 抛掷 | 摩擦力（Friction） | 列表惯性滚动 |
| 落下 | 重力（Gravity） | 下落效果 |
| 弹跳 | 弹簧 + 碰撞 | 球体弹跳 |

---

## 物理动画 vs 补间动画

| 特性 | 补间动画 (Tween) | 物理动画 (Physics) |
|------|-----------------|-------------------|
| 时长 | 固定（你指定 duration） | 自然结束（取决于物理参数） |
| 终点 | 确定（你指定 end） | 可能确定（弹簧目标点）或自然停止 |
| 初始速度 | 不考虑 | 核心参数 |
| 真实感 | 一般 | 高 |
| 控制精度 | 高（精确到时间和值） | 低（结果取决于物理参数） |
| 适用场景 | UI 属性变化 | 手势响应、自然运动 |

### 何时选择物理动画？

- 动画需要**响应手势的速度**（如抛掷 fling）
- 需要**弹性/弹跳效果**
- 需要让用户感觉到**真实的物理反馈**
- **不确定动画时长**，让物理自然决定

---

## SpringSimulation 与 SpringDescription

### SpringDescription（弹簧描述）

`SpringDescription` 定义了弹簧的物理属性：

```dart
const spring = SpringDescription(
  mass: 1.0,       // 质量：越大惯性越大，运动越慢
  stiffness: 100.0, // 刚度：越大弹力越强，弹回越快
  damping: 10.0,    // 阻尼：越大能量衰减越快，振荡越少
);
```

### 三个参数的直觉理解

**mass（质量）**：
- 想象一个挂在弹簧上的球
- 质量大 → 球重 → 弹簧拉得更长、弹回更慢
- 质量小 → 球轻 → 弹簧响应更灵敏

**stiffness（刚度）**：
- 想象弹簧的硬度
- 刚度大 → 弹簧很硬 → 弹回力大、频率高
- 刚度小 → 弹簧很软 → 弹回力小、频率低

**damping（阻尼）**：
- 想象空气阻力或弹簧内部摩擦
- 阻尼大 → 很快停下来（过阻尼）
- 阻尼小 → 来回振荡很久（欠阻尼）
- 阻尼适中 → 弹几下后停下（临界阻尼附近）

### 临界阻尼

临界阻尼 = `2 × sqrt(mass × stiffness)`，此时弹簧不会振荡，以最快速度回到平衡位置。

```dart
// 计算临界阻尼
import 'dart:math';
final criticalDamping = 2.0 * sqrt(mass * stiffness);
```

### SpringSimulation

```dart
final simulation = SpringSimulation(
  spring,        // SpringDescription
  0.0,           // 起始位置
  1.0,           // 目标位置
  0.0,           // 初始速度（每秒移动的距离）
);

// simulation 提供的方法
simulation.x(time);      // 在 time 时刻的位置
simulation.dx(time);     // 在 time 时刻的速度
simulation.isDone(time);  // 在 time 时刻是否已结束
```

---

## animateWith 方法

`AnimationController` 的 `animateWith` 方法用于将物理模拟应用到控制器上：

```dart
void _startSpringAnimation() {
  final spring = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 15.0,
  );

  final simulation = SpringSimulation(
    spring,
    _controller.value,  // 当前位置作为起点
    1.0,                // 目标位置
    _velocity,          // 初始速度（可以从手势中获取）
  );

  _controller.animateWith(simulation);
}
```

### 重要特性

1. **`animateWith` 会覆盖 controller 的 duration 设置**——动画时长由物理模拟决定
2. **controller 的值范围不受 lowerBound/upperBound 限制**——物理模拟可以"越界"
3. **返回 TickerFuture**——可以 await 等待动画完成

---

## 拖拽释放弹回效果

这是物理动画最经典的应用：用户拖拽一个元素，松手后元素弹回原位。

### 实现思路

1. 使用 `GestureDetector` 捕获拖拽和释放
2. 拖拽时直接更新位置（跟随手指）
3. 释放时获取手指速度，启动弹簧动画弹回

### 核心代码

```dart
class _DragSpringDemoState extends State<DragSpringDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {
          // 动画过程中更新位置
          _dragOffset = Offset(
            _dragOffset.dx * (1 - _controller.value),
            _dragOffset.dy * (1 - _controller.value),
          );
        });
      });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // 获取手指释放时的速度
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;

    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 300.0,
      damping: 20.0,
    );

    final simulation = SpringSimulation(spring, 0.0, 1.0, -speed / 1000);
    _controller.animateWith(simulation);
  }
}
```

### 使用 Alignment 的简化方案

```dart
// 将拖拽偏移转换为 Alignment，利用弹簧弹回
void _onPanEnd(DragEndDetails details) {
  final spring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 15,
  );

  // 从当前位置弹回原点
  final simulation = SpringSimulation(spring, _controller.value, 0, 0);
  _controller.animateWith(simulation);
}
```

---

## 弹簧参数调优

### 预设参数参考

```dart
// 柔和弹簧（类似果冻）
SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)

// 快速弹簧（类似按钮点击反馈）
SpringDescription(mass: 1.0, stiffness: 500.0, damping: 25.0)

// 重物弹簧（类似大物体）
SpringDescription(mass: 3.0, stiffness: 200.0, damping: 20.0)

// 临界阻尼（无振荡，最快归位）
SpringDescription(mass: 1.0, stiffness: 200.0, damping: 28.3) // 2*sqrt(200)

// Material Design 风格
SpringDescription(mass: 1.0, stiffness: 300.0, damping: 22.0)
```

### 调参技巧

1. **先固定 mass = 1.0**，调整 stiffness 和 damping
2. **增大 stiffness** 让动画更快、更有力
3. **增大 damping** 减少振荡次数
4. **如果需要慢动作感觉**，增大 mass

### 可视化理解

```
欠阻尼（damping 小）:
位置 |  ╭─╮    ╭╮
     | ╱  ╰─╮╱╰─── 目标位置
     |╱     ╰
     └──────────── 时间

临界阻尼:
位置 |
     |  ╭──────── 目标位置
     | ╱
     |╱
     └──────────── 时间

过阻尼（damping 大）:
位置 |
     |       ╭──── 目标位置
     |    ╱
     |  ╱
     |╱
     └──────────── 时间
```

---

## 其他物理模拟

### FrictionSimulation（摩擦模拟）

模拟一个减速停下的物体，如惯性滚动：

```dart
import 'package:flutter/physics.dart';

final simulation = FrictionSimulation(
  0.135,   // 摩擦系数（drag），越大减速越快
  100.0,   // 起始位置
  500.0,   // 初始速度
);
```

### GravitySimulation（重力模拟）

模拟自由落体或抛射运动：

```dart
final simulation = GravitySimulation(
  200.0,  // 重力加速度
  0.0,    // 起始位置
  300.0,  // 终止位置
  0.0,    // 初始速度
);
```

### BouncingScrollSimulation

Flutter 的 ScrollPhysics 内部就使用了物理模拟。`BouncingScrollPhysics`（iOS 风格）就是基于弹簧模拟实现的。

---

## 最佳实践

### 1. 使用 unbounded 的 AnimationController

物理模拟的值可能超出 0.0~1.0 的范围（如弹簧的过冲）：

```dart
_controller = AnimationController.unbounded(vsync: this);
```

或者设置足够大的范围：

```dart
_controller = AnimationController(
  vsync: this,
  lowerBound: double.negativeInfinity,
  upperBound: double.infinity,
);
```

### 2. 从手势速度中获取初始速度

```dart
void _onPanEnd(DragEndDetails details) {
  // 像素/秒 → 归一化速度
  final pixelsPerSecond = details.velocity.pixelsPerSecond;
  final screenSize = MediaQuery.of(context).size;

  // 将速度归一化到 -1 ~ 1 范围
  final normalizedVelocity = pixelsPerSecond.dy / screenSize.height;

  // 传入弹簧模拟
  final simulation = SpringSimulation(spring, currentPos, targetPos, normalizedVelocity);
  _controller.animateWith(simulation);
}
```

### 3. 组合多个物理动画

可以同时在 x 轴和 y 轴分别运行弹簧模拟：

```dart
// x 方向弹簧
final xSim = SpringSimulation(spring, offsetX, 0, velocityX);
_xController.animateWith(xSim);

// y 方向弹簧
final ySim = SpringSimulation(spring, offsetY, 0, velocityY);
_yController.animateWith(ySim);
```

### 4. 处理动画中断

如果用户在弹簧动画进行中再次拖拽，需要停止当前动画：

```dart
void _onPanStart(DragStartDetails details) {
  _controller.stop();  // 停止正在进行的物理动画
}
```

### 5. 避免无限振荡

确保阻尼足够大，否则弹簧动画理论上永远不会完全停止。Flutter 在振幅足够小时会自动判定结束，但过低的阻尼仍然会导致长时间的微小振荡。

---

## 本章示例代码

查看 `lib/ch05_physics_animations.dart`，该示例展示了：
- SpringSimulation 基本使用
- 拖拽释放弹回效果
- 不同弹簧参数的对比
- 弹簧参数的实时调整

运行方式：
```bash
flutter run -t lib/ch05_physics_animations.dart
```
