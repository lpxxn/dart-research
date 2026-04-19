# Chapter 2：单子布局控件（Single-Child Layout Widgets）

> Flutter 布局系统中，**单子布局控件**是最基础也是最常用的一类控件。它们只接收一个 `child`，
> 通过对这个子控件施加约束（constraints）、变换（transform）、装饰（decoration）等操作来控制布局。
> 掌握它们是理解 Flutter 布局模型的第一步。

---

## 目录

1. [Container 的本质](#1-container-的本质)
2. [SizedBox vs Container 选型](#2-sizedbox-vs-container-选型)
3. [Padding 与 Margin 的区别](#3-padding-与-margin-的区别)
4. [Center 和 Align](#4-center-和-align)
5. [FractionallySizedBox](#5-fractionallysizedbox)
6. [ConstrainedBox 和 LimitedBox](#6-constrainedbox-和-limitedbox)
7. [AspectRatio 与 FittedBox](#7-aspectratio-与-fittedbox)
8. [IntrinsicWidth / IntrinsicHeight](#8-intrinsicwidth--intrinsicheight)
9. [最佳实践与选型指南](#9-最佳实践与选型指南)

---

## 1. Container 的本质

### 1.1 Container 不是一个原子控件

很多初学者把 `Container` 当作 HTML 中的 `<div>` 来用。但实际上，`Container` 是一个
**便利组合控件（convenience widget）**，它的 `build()` 方法内部会根据你传入的参数，
层层嵌套多个更基础的控件：

```
Container
  └─ Align               （当设置了 alignment）
      └─ Padding          （当设置了 padding）
          └─ DecoratedBox  （当设置了 decoration / foregroundDecoration）
              └─ ConstrainedBox  （当设置了 constraints / width / height）
                  └─ Transform   （当设置了 transform）
                      └─ child
```

### 1.2 源码拆解

打开 `Container` 的源码，你会看到类似这样的结构：

```dart
@override
Widget build(BuildContext context) {
  Widget current = child;

  // 第一层：如果有 alignment，用 Align 包裹
  if (alignment != null) {
    current = Align(alignment: alignment!, child: current);
  }

  // 第二层：如果有 padding，用 Padding 包裹
  if (padding != null) {
    current = Padding(padding: padding!, child: current);
  }

  // 第三层：如果有 decoration，用 DecoratedBox 包裹
  if (decoration != null) {
    current = DecoratedBox(decoration: decoration!, child: current);
  }

  // 第四层：如果有 constraints 或 width / height，用 ConstrainedBox 包裹
  if (constraints != null) {
    current = ConstrainedBox(constraints: constraints!, child: current);
  }

  // 第五层：如果有 transform，用 Transform 包裹
  if (transform != null) {
    current = Transform(transform: transform!, child: current);
  }

  return current;
}
```

### 1.3 关键要点

| 参数 | 内部使用的控件 | 说明 |
|------|--------------|------|
| `alignment` | `Align` | 控制子控件在 Container 内部的对齐方式 |
| `padding` | `Padding` | 内边距 |
| `margin` | `Padding`（外层） | 外边距，本质也是 Padding |
| `decoration` | `DecoratedBox` | 背景装饰（颜色、边框、圆角、阴影等） |
| `width` / `height` | `ConstrainedBox` | 固定尺寸约束 |
| `constraints` | `ConstrainedBox` | 更灵活的约束 |
| `transform` | `Transform` | 矩阵变换 |

> **注意**：`color` 参数和 `decoration` 参数不能同时使用。如果只需要设置背景色，用 `color`；
> 如果需要更复杂的装饰（圆角、边框等），用 `decoration: BoxDecoration(color: ...)`。

### 1.4 示例

```dart
Container(
  width: 200,
  height: 100,
  margin: const EdgeInsets.all(16),        // 外边距
  padding: const EdgeInsets.all(12),       // 内边距
  alignment: Alignment.center,             // 子控件居中
  decoration: BoxDecoration(
    color: Colors.blue,                    // 背景色
    borderRadius: BorderRadius.circular(8),// 圆角
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 4,
        offset: const Offset(2, 2),
      ),
    ],
  ),
  child: const Text('Hello', style: TextStyle(color: Colors.white)),
)
```

---

## 2. SizedBox vs Container 选型

### 2.1 SizedBox 的优势

`SizedBox` 是一个纯粹的尺寸约束控件，它内部直接使用 `RenderConstrainedBox`，
**没有任何额外的包装层**。

```dart
// ✅ 推荐：只需要设置大小时用 SizedBox
const SizedBox(width: 100, height: 50, child: Placeholder())

// ❌ 不推荐：仅为了设置大小就用 Container
Container(width: 100, height: 50, child: const Placeholder())
```

### 2.2 SizedBox 的常见用法

```dart
// 用作间距（比 Padding 更直观）
const SizedBox(height: 16)  // 垂直间距
const SizedBox(width: 8)    // 水平间距

// 强制子控件撑满父控件
const SizedBox.expand(child: Placeholder())

// 收缩为子控件大小
const SizedBox.shrink(child: Text('hi'))
```

### 2.3 选型规则

| 场景 | 推荐控件 | 原因 |
|------|---------|------|
| 只设置宽高 | `SizedBox` | 更轻量，支持 const |
| 需要背景色/边框/圆角 | `Container` | 需要 decoration |
| 需要 padding | `Padding` 或 `Container` | 视复杂度而定 |
| 空白间距 | `SizedBox` | 语义清晰 |
| 需要 transform | `Container` 或 `Transform` | 根据是否有其他属性 |

---

## 3. Padding 与 Margin 的区别

### 3.1 本质相同，位置不同

在 Flutter 中，`margin` 和 `padding` **都是通过 `Padding` 控件实现的**，
区别仅在于它们嵌套的层级不同：

```
// Container 的内部结构（简化版）
Padding(               ← margin（外层 Padding）
  padding: margin,
  child: DecoratedBox(  ← decoration 在中间
    decoration: ...,
    child: Padding(     ← padding（内层 Padding）
      padding: padding,
      child: child,
    ),
  ),
)
```

### 3.2 关键区别

- **margin**：在 `decoration`（背景/边框）**外面**，影响控件与外部的距离
- **padding**：在 `decoration`（背景/边框）**里面**，影响子控件与边框的距离

```dart
Container(
  margin: const EdgeInsets.all(20),   // 背景色外面的空白
  padding: const EdgeInsets.all(16),  // 背景色里面的空白
  decoration: BoxDecoration(
    color: Colors.amber,
    border: Border.all(color: Colors.red, width: 2),
  ),
  child: const Text('注意 margin 和 padding 的区别'),
)
```

### 3.3 建议

如果不需要 `decoration`，直接使用 `Padding` 控件而不是 `Container`：

```dart
// ✅ 推荐
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('内容'),
)

// ❌ 不推荐（多了不必要的 Container 层）
Container(
  padding: const EdgeInsets.all(16),
  child: const Text('内容'),
)
```

---

## 4. Center 和 Align

### 4.1 Center 就是 Align 的特例

`Center` 继承自 `Align`，等价于 `Align(alignment: Alignment.center)`。

```dart
// 以下两种写法完全等价
const Center(child: Text('居中'))
const Align(alignment: Alignment.center, child: Text('居中'))
```

### 4.2 Alignment 坐标系详解

`Alignment` 使用的坐标系以**控件中心为原点**，范围从 `(-1, -1)` 到 `(1, 1)`：

```
(-1, -1) -------- (0, -1) -------- (1, -1)
    |                 |                 |
    |          topCenter               |
    |                 |                 |
(-1, 0) --------- (0, 0) --------- (1, 0)
    |            center                |
    |                 |                 |
(-1, 1) --------- (0, 1) --------- (1, 1)
```

- `Alignment(-1, -1)` = `Alignment.topLeft`
- `Alignment(0, 0)` = `Alignment.center`
- `Alignment(1, 1)` = `Alignment.bottomRight`

### 4.3 自定义位置

```dart
// 把子控件放在水平方向 25% 的位置
const Align(
  alignment: Alignment(-0.5, 0.0), // x 从 -1 到 1，-0.5 即左侧 25%
  child: Text('自定义位置'),
)
```

### 4.4 Alignment 的计算公式

子控件在父控件中的实际偏移量计算公式：

```
偏移 x = (parentWidth - childWidth) / 2 * (1 + alignment.x)
偏移 y = (parentHeight - childHeight) / 2 * (1 + alignment.y)
```

### 4.5 widthFactor 和 heightFactor

`Align` 和 `Center` 都支持 `widthFactor` 和 `heightFactor`，用于控制自身大小：

```dart
// Align 的大小 = 子控件大小 × factor
Center(
  widthFactor: 2.0,   // Align 宽度 = child 宽度 × 2
  heightFactor: 1.5,  // Align 高度 = child 高度 × 1.5
  child: const Text('内容'),
)
```

如果不设置 factor，`Align`/`Center` 默认会尽可能撑满父控件。

---

## 5. FractionallySizedBox

### 5.1 用途

`FractionallySizedBox` 允许你**按父控件尺寸的比例**来设置子控件的大小。
这在响应式布局中非常有用。

### 5.2 基本用法

```dart
// 子控件宽度 = 父控件宽度的 80%，高度 = 父控件高度的 50%
FractionallySizedBox(
  widthFactor: 0.8,
  heightFactor: 0.5,
  child: Container(
    color: Colors.green,
    child: const Center(child: Text('80% 宽, 50% 高')),
  ),
)
```

### 5.3 配合 alignment

```dart
FractionallySizedBox(
  alignment: Alignment.topLeft,  // 按比例缩放后靠左上角对齐
  widthFactor: 0.6,
  child: Container(color: Colors.orange),
)
```

### 5.4 注意事项

- 如果父控件是无界约束（unbounded），比如在 `ListView` 中没有限制的方向，
  使用 `FractionallySizedBox` 对应的 factor 会导致异常
- 通常建议在有明确约束的父控件中使用

---

## 6. ConstrainedBox 和 LimitedBox

### 6.1 ConstrainedBox

`ConstrainedBox` 对子控件施加**额外的约束**：

```dart
ConstrainedBox(
  constraints: const BoxConstraints(
    minWidth: 100,
    maxWidth: 300,
    minHeight: 50,
    maxHeight: 200,
  ),
  child: Container(
    color: Colors.purple,
    child: const Text('我的大小被约束了'),
  ),
)
```

#### 约束合并规则

Flutter 的约束系统遵循一个核心原则：**子控件的约束 = 父控件的约束 ∩ 自己设置的约束**。

也就是说，`ConstrainedBox` 设置的约束会与父控件传下来的约束取交集：
- 最终的 `minWidth` = max(父的 minWidth, 自己的 minWidth)
- 最终的 `maxWidth` = min(父的 maxWidth, 自己的 maxWidth)

> **重要**：`ConstrainedBox` 只能**收紧**约束，不能放宽。如果父控件已经规定了 `maxWidth: 200`，
> 你在 `ConstrainedBox` 中设置 `maxWidth: 300` 是无效的。

#### 快捷构造函数

```dart
// 只设置最大尺寸
ConstrainedBox(
  constraints: BoxConstraints.loose(const Size(200, 100)),
  child: ...,
)

// 只设置精确尺寸（等价于 SizedBox）
ConstrainedBox(
  constraints: BoxConstraints.tight(const Size(200, 100)),
  child: ...,
)
```

### 6.2 LimitedBox

`LimitedBox` 只在**父控件没有给出约束**（unbounded）时才生效。
典型场景是在 `ListView`、`Column`（无约束方向）中使用：

```dart
ListView(
  children: [
    // 在 ListView 中，垂直方向是 unbounded
    // LimitedBox 给子控件一个默认的最大高度
    LimitedBox(
      maxHeight: 150,
      child: Container(color: Colors.red),
    ),
  ],
)
```

#### 何时用 LimitedBox 而不是 ConstrainedBox？

| 场景 | 推荐 |
|------|------|
| 父控件有明确约束 | `ConstrainedBox` |
| 父控件可能无约束（如 ListView 中） | `LimitedBox` |
| 需要设置 minWidth/minHeight | `ConstrainedBox` |
| 只需要设置最大值，且仅在无约束时生效 | `LimitedBox` |

---

## 7. AspectRatio 与 FittedBox

### 7.1 AspectRatio

`AspectRatio` 会尝试将子控件调整为指定的**宽高比**：

```dart
AspectRatio(
  aspectRatio: 16 / 9,  // 宽:高 = 16:9
  child: Container(
    color: Colors.teal,
    child: const Center(child: Text('16:9')),
  ),
)
```

#### 工作原理

1. 首先根据父控件的约束确定一个维度（通常是宽度）
2. 然后根据 `aspectRatio` 计算另一个维度
3. 如果计算结果超出父控件约束，会被裁剪到约束范围内

```dart
// 常见用途：视频播放器、图片预览
SizedBox(
  width: 320,
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: Container(color: Colors.black), // 高度自动计算为 180
  ),
)
```

### 7.2 FittedBox

`FittedBox` 会根据 `fit` 参数将子控件**缩放**到适合自身大小：

```dart
SizedBox(
  width: 200,
  height: 100,
  child: FittedBox(
    fit: BoxFit.contain,  // 等比缩放，完整显示
    child: const Text(
      '这段文字会自动缩放',
      style: TextStyle(fontSize: 50),
    ),
  ),
)
```

#### BoxFit 枚举值

| 值 | 说明 |
|----|------|
| `BoxFit.fill` | 拉伸填满，可能变形 |
| `BoxFit.contain` | 等比缩放，完整显示，可能有留白 |
| `BoxFit.cover` | 等比缩放，填满容器，可能裁剪 |
| `BoxFit.fitWidth` | 宽度适配，高度可能溢出 |
| `BoxFit.fitHeight` | 高度适配，宽度可能溢出 |
| `BoxFit.none` | 不缩放，居中显示 |
| `BoxFit.scaleDown` | 只缩小不放大（常用） |

#### 典型使用场景

```dart
// 文字自适应容器大小
FittedBox(
  fit: BoxFit.scaleDown,  // 文字太大时缩小，刚好时不放大
  child: Text(
    dynamicText,
    style: const TextStyle(fontSize: 24),
  ),
)
```

---

## 8. IntrinsicWidth / IntrinsicHeight

### 8.1 作用

`IntrinsicWidth` 和 `IntrinsicHeight` 会将子控件的宽度/高度调整为其
**固有尺寸（intrinsic dimension）**。

### 8.2 什么是固有尺寸？

每个 `RenderBox` 都有四个固有尺寸方法：
- `getMinIntrinsicWidth(height)` —— 给定高度下的最小固有宽度
- `getMaxIntrinsicWidth(height)` —— 给定高度下的最大固有宽度
- `getMinIntrinsicHeight(width)` —— 给定宽度下的最小固有高度
- `getMaxIntrinsicHeight(width)` —— 给定宽度下的最大固有高度

### 8.3 典型使用场景

```dart
// 让 Column 中的所有子控件宽度一致（等于最宽的那个）
IntrinsicWidth(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton(onPressed: () {}, child: const Text('短')),
      ElevatedButton(onPressed: () {}, child: const Text('这个按钮文字比较长')),
      ElevatedButton(onPressed: () {}, child: const Text('中等长度')),
    ],
  ),
)
```

### 8.4 ⚠️ 性能警告

> **慎用！** `IntrinsicWidth` / `IntrinsicHeight` 的时间复杂度是 **O(n²)**，
> 因为它需要两次布局：
> 1. 第一次：计算子控件的固有尺寸
> 2. 第二次：用计算出的尺寸作为约束，再布局一次
>
> 在复杂的布局树中，嵌套使用会导致指数级的性能下降。
> 只在确实需要时使用，并避免在深层嵌套中使用。

### 8.5 替代方案

| 场景 | 替代方案 |
|------|---------|
| 按钮等宽 | 用 `Row` + `Expanded` 或设置固定宽度 |
| 表格列等宽 | 用 `Table` 控件 |
| 内容自适应 | 用 `Wrap` 或 `Flow` |

---

## 9. 最佳实践与选型指南

### 9.1 控件选型速查表

| 需求 | 推荐控件 | 说明 |
|------|---------|------|
| 固定宽高 | `SizedBox` | 最轻量 |
| 空白间距 | `SizedBox` | 语义清晰 |
| 内边距 | `Padding` | 不需要装饰时 |
| 背景色 + 圆角 + 阴影 | `Container` | 需要 decoration |
| 居中 | `Center` | 语义清晰 |
| 自定义对齐 | `Align` | 比 Container 轻量 |
| 按比例大小 | `FractionallySizedBox` | 响应式布局 |
| 约束限制 | `ConstrainedBox` | 设置 min/max |
| ListView 中限制大小 | `LimitedBox` | 仅无约束时生效 |
| 宽高比 | `AspectRatio` | 视频/图片 |
| 内容缩放 | `FittedBox` | 文字自适应 |
| 子控件等宽/等高 | `IntrinsicWidth/Height` | 慎用，性能差 |

### 9.2 性能优先级

1. **优先使用 `const` 构造函数** —— 编译时常量，零开销
2. **优先使用专用控件** —— `SizedBox` 优于 `Container`，`Padding` 优于 `Container`
3. **避免不必要的嵌套** —— 一个 `Container` 能解决的不要拆成三层
4. **慎用 Intrinsic 系列** —— O(n²) 复杂度

### 9.3 常见陷阱

#### 陷阱 1：Container 的 color 和 decoration 冲突

```dart
// ❌ 报错！
Container(
  color: Colors.red,
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
)

// ✅ 正确
Container(
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(8),
  ),
)
```

#### 陷阱 2：ConstrainedBox 无法放宽约束

```dart
// 父控件约束 maxWidth: 100
// ❌ 以下设置无效，子控件最大仍然是 100
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 200),
  child: ...,
)

// ✅ 如果需要放宽，使用 UnconstrainedBox
UnconstrainedBox(
  child: SizedBox(width: 200, child: ...),
)
```

#### 陷阱 3：FractionallySizedBox 在无约束方向上异常

```dart
// ❌ 在 ListView 中使用 heightFactor 会报错
ListView(
  children: [
    FractionallySizedBox(
      heightFactor: 0.5,  // ListView 垂直方向无约束！
      child: Container(color: Colors.red),
    ),
  ],
)
```

---

## 完整示例代码

完整的可运行示例请参考：
[`lib/ch02_single_child_layout.dart`](../lib/ch02_single_child_layout.dart)

该示例包含了本章所有控件的演示，每个控件都有独立的展示区域和中文注释。

---

## 小结

单子布局控件是 Flutter 布局的基石。核心思想是：

1. **约束向下传递，尺寸向上报告** —— 父控件告诉子控件"你最大/最小可以多大"，
   子控件在约束范围内决定自己的实际尺寸，然后报告给父控件
2. **选择最合适的控件** —— 不要什么都用 Container，选择语义最匹配的专用控件
3. **理解组合模式** —— Container 本身就是多个基础控件的组合，理解这一点有助于调试布局问题

下一章我们将学习多子布局控件（Multi-Child Layout Widgets），包括 Row、Column、Stack 等。
