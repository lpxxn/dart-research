# 第3章 — 控件美化：装饰、阴影与渐变

Flutter 的 UI 表现力远超传统原生框架，原因之一就是它提供了极其灵活的装饰（Decoration）系统。在前面的章节中，我们学会了如何用 Theme 统一管理颜色与字体；本章我们将深入到单个控件的视觉层面，系统讲解 `BoxDecoration`、渐变、阴影、异形裁剪与毛玻璃等核心技术，并通过一个"多风格卡片"综合实战项目把所有知识串联起来。

---

## 3.1 BoxDecoration 全面解析

`Container`（或 `DecoratedBox`）的 `decoration` 参数接受一个 `Decoration` 对象，最常用的实现就是 `BoxDecoration`。它可以同时控制背景、边框、圆角、阴影和形状，几乎可以实现所有常见的视觉效果。

### 3.1.1 背景：color / gradient / image 三选一

`BoxDecoration` 的背景有三种互斥的设置方式——`color`、`gradient` 和 `image`，它们不能同时使用（`gradient` 会覆盖 `color`，`image` 会覆盖 `gradient`）：

```dart
// 纯色背景
BoxDecoration(color: Colors.blue)

// 渐变背景（后续 3.2 节详细讲解）
BoxDecoration(
  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
)

// 图片背景
BoxDecoration(
  image: DecorationImage(
    image: AssetImage('assets/bg.jpg'),
    fit: BoxFit.cover,
  ),
)
```

### 3.1.2 borderRadius：圆角的多种写法

圆角通过 `borderRadius` 设置，它的类型是 `BorderRadiusGeometry`，常见写法如下：

```dart
// 四角统一圆角
borderRadius: BorderRadius.circular(12)

// 四角统一（另一种写法）
borderRadius: BorderRadius.all(Radius.circular(12))

// 只设置部分角
borderRadius: BorderRadius.only(
  topLeft: Radius.circular(16),
  topRight: Radius.circular(16),
  bottomLeft: Radius.zero,
  bottomRight: Radius.zero,
)

// 垂直/水平对称
borderRadius: BorderRadius.vertical(
  top: Radius.circular(16),
  bottom: Radius.circular(8),
)
```

> **注意：** 当 `shape` 设为 `BoxShape.circle` 时，不能同时设置 `borderRadius`，否则会抛出异常。

### 3.1.3 border：边框

边框有几种构造方式：

```dart
// 四边统一
border: Border.all(color: Colors.grey, width: 1)

// 各边独立
border: Border(
  top: BorderSide(color: Colors.red, width: 2),
  bottom: BorderSide(color: Colors.blue, width: 2),
  left: BorderSide.none,
  right: BorderSide.none,
)

// 支持 RTL 的方向性边框
border: BorderDirectional(
  start: BorderSide(color: Colors.green, width: 2),
  end: BorderSide(color: Colors.orange, width: 2),
)
```

### 3.1.4 boxShadow：多层阴影叠加

`boxShadow` 接受一个 `List<BoxShadow>`，允许叠加多层阴影，每层阴影有以下关键参数：

| 参数 | 说明 |
|------|------|
| `color` | 阴影颜色，通常带透明度 |
| `offset` | 阴影偏移量，`Offset(dx, dy)` |
| `blurRadius` | 模糊半径，值越大越模糊扩散 |
| `spreadRadius` | 扩散半径，正值让阴影比控件更大，负值更小 |

```dart
boxShadow: [
  // 主阴影
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.1),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  ),
  // 辅助阴影（更近、更轻）
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    offset: Offset(0, 1),
    blurRadius: 4,
    spreadRadius: 0,
  ),
]
```

多层阴影叠加可以模拟出非常真实的 Material Design 效果，比单层阴影细腻得多。

### 3.1.5 shape：BoxShape.circle vs rectangle

`shape` 只有两个值：

- `BoxShape.rectangle`（默认）：矩形，可配合 `borderRadius` 使用
- `BoxShape.circle`：圆形，控件的宽高取较小值作为直径，**不能** 再设置 `borderRadius`

```dart
Container(
  width: 100,
  height: 100,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.blue,
    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
  ),
)
```

---

## 3.2 渐变 (Gradient) 详解

Flutter 提供三种渐变类型，都继承自 `Gradient` 抽象类。

### 3.2.1 LinearGradient 线性渐变

最常用的渐变类型，沿一条直线方向过渡颜色：

```dart
LinearGradient(
  begin: Alignment.topLeft,     // 起点
  end: Alignment.bottomRight,   // 终点
  colors: [Colors.blue, Colors.purple, Colors.pink],
  stops: [0.0, 0.5, 1.0],      // 每种颜色的位置（可选）
)
```

- `begin` 和 `end` 使用 `Alignment` 坐标系（-1 到 1）
- `stops` 数组长度必须与 `colors` 一致，定义每种颜色出现的位置
- 省略 `stops` 时颜色均匀分布

### 3.2.2 RadialGradient 径向渐变

从一个中心点向外扩散：

```dart
RadialGradient(
  center: Alignment.center,   // 中心点
  radius: 0.8,                // 半径（相对于控件短边的比例）
  colors: [Colors.yellow, Colors.orange, Colors.red],
  stops: [0.0, 0.5, 1.0],
)
```

`radius` 是一个 0-1 的相对值，1.0 表示渐变圆的半径等于控件短边的一半。

### 3.2.3 SweepGradient 扫描渐变

像雷达扫描一样绕中心点旋转：

```dart
SweepGradient(
  center: Alignment.center,
  startAngle: 0.0,            // 起始角度（弧度）
  endAngle: 2 * pi,           // 结束角度
  colors: [Colors.red, Colors.blue, Colors.green, Colors.red],
)
```

`SweepGradient` 特别适合制作色轮选择器或环形进度条的渐变效果。

### 3.2.4 渐变的应用场景

渐变不仅可以用在 `BoxDecoration` 中，还可以用在以下场景：

**ShaderMask — 给任意控件添加渐变蒙版：**

```dart
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ).createShader(bounds),
  child: Text('渐变文字', style: TextStyle(fontSize: 32, color: Colors.white)),
)
```

**CustomPainter — 在 Canvas 上使用渐变填充：**

```dart
final paint = Paint()
  ..shader = LinearGradient(
    colors: [Colors.blue, Colors.red],
  ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
```

---

## 3.3 阴影与发光效果

### 3.3.1 boxShadow vs elevation

Flutter 中有两种添加阴影的方式：

- **boxShadow**（`BoxDecoration`）：完全手动控制，灵活但需要自己调参
- **elevation**（`Material`、`Card`、`ElevatedButton` 等）：Material Design 规范的阴影，由系统自动计算

```dart
// Material Design 风格阴影
Material(
  elevation: 8,
  shadowColor: Colors.black54,
  borderRadius: BorderRadius.circular(12),
  child: Container(/* ... */),
)
```

`elevation` 的优势是遵循 Material Design 规范，阴影会随高度自动调整；`boxShadow` 的优势是可以做出非标准的创意效果（比如彩色阴影、多层阴影、发光效果）。

### 3.3.2 内阴影模拟技巧

CSS 有 `inset` 内阴影，Flutter 原生不支持，但可以用渐变叠加层模拟：

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.15),  // 顶部暗
        Colors.transparent,                     // 底部透明
      ],
    ),
  ),
)
```

将这个带渐变的 `Container` 叠加在目标控件上方（用 `Stack`），就能模拟顶部内阴影效果。

### 3.3.3 发光/霓虹效果

霓虹发光效果的核心是**多层亮色模糊阴影**：

```dart
boxShadow: [
  // 外层大范围柔光
  BoxShadow(
    color: Colors.cyanAccent.withValues(alpha: 0.3),
    blurRadius: 24,
    spreadRadius: 2,
  ),
  // 中层光晕
  BoxShadow(
    color: Colors.cyanAccent.withValues(alpha: 0.5),
    blurRadius: 12,
    spreadRadius: 0,
  ),
  // 内层强光
  BoxShadow(
    color: Colors.cyanAccent.withValues(alpha: 0.8),
    blurRadius: 4,
    spreadRadius: -2,
  ),
]
```

配合深色背景和亮色边框，就能做出非常酷的霓虹灯效果。

---

## 3.4 异形裁剪

当矩形和圆形不够用时，Flutter 提供了强大的裁剪机制。

### 3.4.1 ClipRRect / ClipOval / ClipPath

```dart
// 圆角裁剪
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset('assets/photo.jpg'),
)

// 椭圆/圆形裁剪
ClipOval(child: Image.asset('assets/avatar.jpg'))

// 自定义路径裁剪
ClipPath(
  clipper: MyCustomClipper(),
  child: Container(color: Colors.blue),
)
```

### 3.4.2 自定义 CustomClipper\<Path\>

通过继承 `CustomClipper<Path>` 可以实现任意形状的裁剪：

```dart
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);

    // 用二次贝塞尔曲线画波浪
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(
      firstControlPoint.dx, firstControlPoint.dy,
      firstEndPoint.dx, firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.5);
    final secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(
      secondControlPoint.dx, secondControlPoint.dy,
      secondEndPoint.dx, secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
```

### 3.4.3 ShapeBorder 家族

除了裁剪，Flutter 还提供了多种 `ShapeBorder`，可用于 `Material`、`Card` 等控件的 `shape` 属性：

| ShapeBorder | 效果 |
|-------------|------|
| `RoundedRectangleBorder` | 圆角矩形（最常用） |
| `StadiumBorder` | 胶囊形（两端半圆） |
| `BeveledRectangleBorder` | 切角矩形 |
| `ContinuousRectangleBorder` | 超椭圆圆角（iOS 风格，过渡更平滑） |
| `CircleBorder` | 圆形 |

```dart
Card(
  shape: ContinuousRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  ),
  child: /* ... */,
)
```

---

## 3.5 BackdropFilter 毛玻璃效果

毛玻璃（Glassmorphism）是近年非常流行的 UI 风格，Flutter 通过 `BackdropFilter` 实现。

### 3.5.1 ImageFilter.blur

`BackdropFilter` 会对其**后方**的内容应用滤镜效果：

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    color: Colors.white.withValues(alpha: 0.2),
    child: Text('毛玻璃效果'),
  ),
)
```

> **关键点：** `BackdropFilter` 模糊的是它**下方/后方**的内容，而不是它自身的 `child`。它必须放在一个 `Stack` 或类似布局中，并且后方要有可见内容（图片、渐变等），效果才明显。

### 3.5.2 结合 ClipRRect 实现卡片毛玻璃

完整的毛玻璃卡片通常需要 `ClipRRect` + `BackdropFilter` + 半透明叠加层：

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Text('Glassmorphism Card',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
  ),
)
```

`ClipRRect` 的作用是限制模糊效果的范围，防止模糊溢出到圆角之外。

---

## 3.6 示例：StyledCard 美化卡片

现在我们把上面学到的技术综合起来，做一个支持多种风格的 `StyledCard` 控件。

### 需求

创建一个 `StyledCard`，支持以下四种视觉风格：

1. **flat（扁平）**：纯色背景 + 细边框，无阴影，适合简洁风
2. **elevated（浮起）**：白色背景 + 多层柔和阴影，经典 Material Design 风格
3. **glassmorphism（毛玻璃）**：半透明背景 + 模糊滤镜 + 白色细边框，现代潮流风
4. **neon（霓虹）**：深色背景 + 亮色边框 + 发光阴影，赛博朋克风

### 用法

```dart
StyledCard(
  style: CardStyle.glassmorphism,
  primaryColor: Colors.blue,
  borderRadius: 16,
  onTap: () => print('点击了卡片'),
  child: Column(
    children: [
      Icon(Icons.blur_on, size: 48, color: Colors.white),
      SizedBox(height: 8),
      Text('毛玻璃', style: TextStyle(color: Colors.white)),
    ],
  ),
)
```

### 关键实现

- 使用 `enum CardStyle { flat, elevated, glassmorphism, neon }` 区分风格
- 每种风格返回不同的 `BoxDecoration`
- glassmorphism 风格额外包裹 `ClipRRect` + `BackdropFilter`
- neon 风格使用多层 `boxShadow` 实现发光效果

完整代码请参看 `lib/widgets/styled_card.dart` 和示例页面 `lib/examples/ex03_styled_card.dart`。

---

## 3.7 小结

本章覆盖了 Flutter 控件美化的核心技术栈：

| 技术 | 适用场景 |
|------|----------|
| `BoxDecoration` | 背景、边框、圆角、阴影的一站式方案 |
| `LinearGradient` / `RadialGradient` / `SweepGradient` | 丰富的渐变效果 |
| `boxShadow` 多层叠加 | 真实感阴影、发光/霓虹效果 |
| `ClipRRect` / `ClipPath` | 圆角裁剪、异形裁剪 |
| `CustomClipper<Path>` | 波浪、曲线等自定义裁剪形状 |
| `BackdropFilter` | 毛玻璃/磨砂效果 |
| `ShapeBorder` 家族 | 胶囊形、切角、超椭圆等特殊形状 |

**设计心得：**

- 阴影宁可多层轻柔，也不要单层粗暴——多层阴影更接近真实光照
- 毛玻璃效果一定要有丰富的背景内容衬托，纯白底上看不出效果
- 霓虹效果在深色主题中最出彩，浅色主题下效果会大打折扣
- 圆角尽量使用 `ContinuousRectangleBorder`（超椭圆），它比普通圆角更自然，这也是苹果 iOS 图标的圆角方式

下一章我们将进入 `CustomPainter` 的世界，学习如何在 Canvas 上自由绘制，实现完全自定义的图形控件。
