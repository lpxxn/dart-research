# 第4章 — CustomPainter 自绘控件

Flutter 的 Widget 系统已经足够强大，但总有一些场景是现有控件组合无法覆盖的——自定义图表、仪表盘、复杂动画、游戏画面等。这时候就需要 `CustomPainter`，它让你直接操作 Canvas，像画家一样在画布上自由创作。本章将系统讲解 `CustomPainter` 的使用方法，从基础 API 到性能优化，并通过一个"环形渐变进度条"实战项目巩固所学。

---

## 4.1 什么时候需要 CustomPainter

在决定使用 `CustomPainter` 之前，先问自己一个问题：**现有 Widget 的组合能否满足需求？**

Widget 组合是 Flutter 的首选方案，因为它自带布局、命中测试、无障碍支持等能力。只有在以下场景中，才值得考虑 `CustomPainter`：

- **自定义图表**：折线图、柱状图、饼图、雷达图等数据可视化
- **仪表盘/进度条**：环形进度条、速度表盘、自定义加载动画
- **自由绘制**：签名板、绘图工具、手写输入
- **游戏画面**：简单 2D 游戏的渲染层
- **特殊视觉效果**：粒子效果、波浪动画、自定义过渡效果

如果你的需求仅仅是"给一个矩形加圆角加阴影"，那用 `BoxDecoration` 就够了，不必动用 `CustomPainter`。

---

## 4.2 CustomPaint 与 CustomPainter

### 4.2.1 CustomPaint Widget

`CustomPaint` 是 Flutter 提供的用于承载自绘内容的 Widget：

```dart
CustomPaint(
  size: Size(200, 200),        // 当没有 child 时的尺寸
  painter: MyPainter(),        // 在 child 下方绘制
  foregroundPainter: MyFgPainter(), // 在 child 上方绘制
  child: Center(child: Text('Hello')),  // 可选的子控件
)
```

关键参数说明：

| 参数 | 说明 |
|------|------|
| `size` | 当没有 `child` 时使用此尺寸；有 `child` 时以 `child` 的尺寸为准 |
| `painter` | 在 `child` **下方**绘制的画家 |
| `foregroundPainter` | 在 `child` **上方**绘制的画家 |
| `child` | 可选子控件，决定了 `CustomPaint` 的大小 |

> **提示：** 如果只有自绘内容没有 `child`，一定要设置 `size`，否则 `CustomPaint` 的大小为零，你什么也看不到。

### 4.2.2 CustomPainter 的核心方法

自定义画家需要继承 `CustomPainter` 并实现两个方法：

```dart
class MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 在这里绘制内容
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    // 返回 true 表示需要重绘
    return false;
  }
}
```

- **`paint(Canvas canvas, Size size)`**：核心绘制方法。`canvas` 是画布，`size` 是可用的绘制区域大小。
- **`shouldRepaint(oldDelegate)`**：当 `CustomPaint` 收到新的 `painter` 实例时调用。如果返回 `true`，Flutter 会重新调用 `paint`；返回 `false` 则跳过重绘。

### 4.2.3 shouldRepaint 的优化策略

`shouldRepaint` 是性能优化的关键。错误的实现会导致不必要的重绘：

```dart
// ❌ 错误：每次都返回 true，浪费性能
@override
bool shouldRepaint(covariant MyPainter oldDelegate) => true;

// ❌ 错误：每次都返回 false，数据变了也不更新
@override
bool shouldRepaint(covariant MyPainter oldDelegate) => false;

// ✅ 正确：只在相关数据变化时重绘
@override
bool shouldRepaint(covariant MyPainter oldDelegate) {
  return oldDelegate.progress != progress ||
         oldDelegate.color != color;
}
```

**黄金法则：** 把会变化的数据作为 `CustomPainter` 的构造参数，在 `shouldRepaint` 中逐一比较。

---

## 4.3 Canvas API 速查

`Canvas` 类提供了丰富的绘制 API，以下是最常用的方法分类。

### 4.3.1 基础图形

```dart
// 线段
canvas.drawLine(Offset(0, 0), Offset(100, 100), paint);

// 矩形
canvas.drawRect(Rect.fromLTWH(10, 10, 80, 60), paint);

// 圆角矩形
canvas.drawRRect(
  RRect.fromRectAndRadius(
    Rect.fromLTWH(10, 10, 80, 60),
    Radius.circular(12),
  ),
  paint,
);

// 圆形
canvas.drawCircle(Offset(50, 50), 40, paint);

// 椭圆
canvas.drawOval(Rect.fromLTWH(10, 10, 100, 60), paint);

// 弧形
canvas.drawArc(
  Rect.fromCircle(center: Offset(50, 50), radius: 40),
  -pi / 2,  // 起始角度（从3点钟方向逆时针）
  pi,        // 扫过的角度
  false,     // 是否连接到中心（扇形 vs 弧线）
  paint,
);
```

### 4.3.2 路径 (Path)

路径是最灵活的绘制方式，可以创建任意形状：

```dart
final path = Path()
  ..moveTo(0, 50)               // 移动到起点
  ..lineTo(50, 0)               // 直线
  ..quadraticBezierTo(          // 二次贝塞尔曲线
    75, 0,                      //   控制点
    100, 50,                    //   终点
  )
  ..cubicTo(                    // 三次贝塞尔曲线
    120, 80,                    //   控制点1
    80, 120,                    //   控制点2
    50, 100,                    //   终点
  )
  ..arcTo(                      // 弧线
    Rect.fromCircle(center: Offset(25, 75), radius: 25),
    0, pi,                      //   起始角度、扫过角度
    false,                      //   是否强制移动到弧线起点
  )
  ..close();                    // 封闭路径

canvas.drawPath(path, paint);
```

### 4.3.3 文字 (TextPainter)

Canvas 上绘制文字需要使用 `TextPainter`：

```dart
final textPainter = TextPainter(
  text: TextSpan(
    text: '75%',
    style: TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  textDirection: TextDirection.ltr,
);

textPainter.layout();  // 必须先布局

// 居中绘制
final offset = Offset(
  (size.width - textPainter.width) / 2,
  (size.height - textPainter.height) / 2,
);
textPainter.paint(canvas, offset);
```

### 4.3.4 图片

```dart
// 绘制整张图片
canvas.drawImage(image, Offset(0, 0), paint);

// 绘制图片的一部分到指定区域
canvas.drawImageRect(
  image,
  Rect.fromLTWH(0, 0, 100, 100),   // 源区域
  Rect.fromLTWH(10, 10, 80, 80),   // 目标区域
  paint,
);
```

### 4.3.5 变换

Canvas 支持变换操作，需要配合 `save` / `restore` 使用以避免影响后续绘制：

```dart
canvas.save();              // 保存当前状态
canvas.translate(100, 100); // 平移
canvas.rotate(pi / 4);     // 旋转（弧度）
canvas.scale(2.0, 2.0);    // 缩放
canvas.clipRect(rect);     // 裁剪区域

// 在这里绘制（受上面变换影响）
canvas.drawCircle(Offset.zero, 20, paint);

canvas.restore();           // 恢复到 save 时的状态
```

---

## 4.4 Paint 对象详解

`Paint` 是绘制时使用的"画笔"，控制颜色、线宽、填充方式等。

### 4.4.1 基础属性

```dart
final paint = Paint()
  ..color = Colors.blue             // 颜色
  ..strokeWidth = 3.0               // 线宽（仅 stroke 模式）
  ..style = PaintingStyle.stroke    // fill（填充）或 stroke（描边）
  ..strokeCap = StrokeCap.round     // 线段端点样式：butt / round / square
  ..strokeJoin = StrokeJoin.round   // 线段连接处样式：miter / round / bevel
  ..isAntiAlias = true;             // 抗锯齿（默认 true）
```

### 4.4.2 shader（渐变填充）

`Paint` 的 `shader` 属性可以设置渐变填充，这在自定义绘制中非常常用：

```dart
paint.shader = SweepGradient(
  center: Alignment.center,
  colors: [Colors.blue, Colors.purple, Colors.red],
  startAngle: 0,
  endAngle: 2 * pi,
  // transform 可以旋转渐变起始方向
).createShader(Rect.fromCircle(center: center, radius: radius));
```

### 4.4.3 maskFilter（模糊效果）

```dart
paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
```

`BlurStyle` 有四种：`normal`（内外均模糊）、`solid`（只模糊外部）、`outer`（只绘制模糊部分）、`inner`（只模糊内部）。

---

## 4.5 示例：环形进度条 CircleProgress

现在我们综合运用上面的知识，实现一个美观的环形渐变进度条。

### 需求

- 灰色背景圆环
- 渐变色的前景进度弧，从顶部 12 点钟方向开始，顺时针绘制
- 圆角端点 (`StrokeCap.round`)
- 中心显示百分比文字
- `shouldRepaint` 精确控制重绘

### 实现思路

1. **背景圆环：** 以控件中心为圆心，用 `canvas.drawCircle` 或 `canvas.drawArc` 画一个完整的灰色圆环（`PaintingStyle.stroke`）。

2. **前景进度弧：** 用 `canvas.drawArc` 画一段弧线。起始角度为 `-π/2`（12 点钟方向），扫过角度为 `2π × progress`。给 `Paint` 设置 `SweepGradient` 的 `shader`，让弧线呈渐变色。

3. **百分比文字：** 用 `TextPainter` 在中心绘制 `"75%"` 这样的文字。

4. **shouldRepaint：** 比较 `progress` 值，只有进度变化时才重绘。

### 关键代码片段

```dart
// 画背景圆环
final bgPaint = Paint()
  ..color = backgroundColor
  ..style = PaintingStyle.stroke
  ..strokeWidth = strokeWidth;
canvas.drawCircle(center, radius, bgPaint);

// 画进度弧（带渐变）
final progressPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..shader = SweepGradient(
    startAngle: -pi / 2,
    endAngle: 3 * pi / 2,
    colors: gradientColors,
  ).createShader(Rect.fromCircle(center: center, radius: radius));

canvas.drawArc(
  Rect.fromCircle(center: center, radius: radius),
  -pi / 2,                  // 从 12 点钟方向开始
  2 * pi * progress,        // 扫过的角度
  false,
  progressPaint,
);
```

完整代码请参看 `lib/widgets/circle_progress.dart` 和示例页面 `lib/examples/ex04_circle_progress.dart`。

---

## 4.6 交互：手势 + CustomPainter

自绘控件默认没有交互能力，需要配合手势识别来实现。

### 4.6.1 GestureDetector 包裹

最简单的方式是用 `GestureDetector` 包裹 `CustomPaint`：

```dart
GestureDetector(
  onPanUpdate: (details) {
    // details.localPosition 获取触摸点相对于控件的坐标
    setState(() {
      _touchPoint = details.localPosition;
    });
  },
  child: CustomPaint(
    size: Size(300, 300),
    painter: MyInteractivePainter(touchPoint: _touchPoint),
  ),
)
```

### 4.6.2 hitTest 自定义命中区域

默认情况下 `CustomPaint` 的命中测试区域是整个矩形。如果你只想让某些绘制区域响应点击，可以重写 `CustomPainter` 的 `hitTest` 方法：

```dart
@override
bool? hitTest(Offset position) {
  // 只有点击到圆形区域内才响应
  final center = Offset(size.width / 2, size.height / 2);
  return (position - center).distance <= radius;
}
```

返回 `true` 表示命中，`false` 表示未命中，`null` 表示使用默认行为（矩形区域）。

---

## 4.7 性能优化

`CustomPainter` 直接操作渲染层，性能优化尤为重要。

### 4.7.1 RepaintBoundary 隔离重绘区域

当 `CustomPaint` 频繁重绘时（比如动画），默认会导致父控件一起重绘。用 `RepaintBoundary` 包裹可以隔离重绘区域：

```dart
RepaintBoundary(
  child: CustomPaint(
    painter: AnimatedPainter(animation: _controller),
  ),
)
```

`RepaintBoundary` 会创建一个独立的渲染层（Layer），自绘内容的重绘不会影响其他控件。

### 4.7.2 shouldRepaint 精确控制

前面已经强调过，`shouldRepaint` 要精确比较变化的数据：

```dart
@override
bool shouldRepaint(covariant CircleProgressPainter oldDelegate) {
  return oldDelegate.progress != progress ||
         oldDelegate.strokeWidth != strokeWidth ||
         oldDelegate.backgroundColor != backgroundColor;
  // 不要比较不会变的属性，减少比较开销
}
```

### 4.7.3 避免在 paint 中创建对象

`paint` 方法可能被频繁调用（每帧 60 次），应尽量避免在其中创建大量临时对象：

```dart
// ❌ 每次 paint 都创建新的 TextPainter
@override
void paint(Canvas canvas, Size size) {
  final textPainter = TextPainter(/* ... */);
  textPainter.layout();
  textPainter.paint(canvas, offset);
}

// ✅ 如果文字不变，在构造函数中创建并缓存
class MyPainter extends CustomPainter {
  final TextPainter _textPainter;

  MyPainter({required String text, required TextStyle style})
    : _textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      ) {
    _textPainter.layout();
  }
  // ...
}
```

对于每帧都要更新的文字（比如进度百分比），在 `paint` 中创建是可以接受的，但要注意不要在循环中创建。

---

## 4.8 小结

本章我们深入学习了 Flutter 的自绘系统：

| 知识点 | 要点 |
|--------|------|
| `CustomPaint` | 承载自绘内容的 Widget，区分 `painter` 和 `foregroundPainter` |
| `CustomPainter` | 实现 `paint` 和 `shouldRepaint`，在 Canvas 上自由绘制 |
| Canvas 基础图形 | `drawLine`、`drawRect`、`drawCircle`、`drawArc`、`drawPath` |
| Path | 支持直线、贝塞尔曲线、弧线，可创建任意形状 |
| TextPainter | 在 Canvas 上绘制文字，需要先 `layout()` 再 `paint()` |
| Paint | 控制颜色、线宽、填充模式、渐变 shader、模糊效果 |
| 手势交互 | `GestureDetector` + `hitTest` 自定义命中区域 |
| 性能优化 | `RepaintBoundary` 隔离、`shouldRepaint` 精确比较、减少 `paint` 中的对象创建 |

**实践建议：**

- 先用 Widget 组合尝试，实在不行再用 `CustomPainter`
- 动画场景一定要用 `RepaintBoundary` 包裹
- `shouldRepaint` 永远不要简单返回 `true`
- 可以把 `CustomPainter` 配合 `AnimationController` 使用，实现丝滑的自绘动画
- 复杂图形建议先在纸上画草图，标注坐标和角度，再转化为代码

下一章我们将学习动画系统（Animation），了解如何让这些自绘图形"动起来"。
