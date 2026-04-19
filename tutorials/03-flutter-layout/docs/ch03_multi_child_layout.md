# 第三章：多子布局控件（Multi-Child Layout Widgets）

> 本章深入讲解 Flutter 中可以包含**多个子组件**的布局控件，包括 Row、Column、Flexible、Expanded、Spacer、Wrap 和 Flow，并通过实际示例掌握响应式卡片布局和标签云布局。

---

## 目录

1. [Row 和 Column 深入](#1-row-和-column-深入)
2. [Flexible 和 Expanded](#2-flexible-和-expanded)
3. [Spacer](#3-spacer)
4. [Wrap](#4-wrap)
5. [Flow](#5-flow)
6. [实战示例](#6-实战示例)
7. [最佳实践总结](#7-最佳实践总结)

---

## 1. Row 和 Column 深入

### 1.1 基本概念

`Row` 和 `Column` 是 Flutter 中最常用的多子布局控件，它们都继承自 `Flex`：

- **Row**：沿**水平方向**排列子组件（主轴为水平方向）
- **Column**：沿**垂直方向**排列子组件（主轴为垂直方向）

```
Row（水平排列）:
┌──────────────────────────────────┐
│  [A]   [B]   [C]   [D]          │
└──────────────────────────────────┘
  ← ─ ─ ─ 主轴 (horizontal) ─ ─ ─ →
  ↑ 交叉轴 (vertical)

Column（垂直排列）:
┌──────────┐
│   [A]    │  ↑
│   [B]    │  │ 主轴 (vertical)
│   [C]    │  │
│   [D]    │  ↓
└──────────┘
  ← 交叉轴 (horizontal) →
```

### 1.2 MainAxisAlignment（主轴对齐方式）

`MainAxisAlignment` 控制子组件在**主轴方向**上的排列方式。

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [Widget1(), Widget2(), Widget3()],
)
```

各枚举值的排列效果（以 Row 为例）：

```
start（默认值）:
┌──────────────────────────────────┐
│ [A][B][C]                        │
└──────────────────────────────────┘

end:
┌──────────────────────────────────┐
│                        [A][B][C] │
└──────────────────────────────────┘

center:
┌──────────────────────────────────┐
│           [A][B][C]              │
└──────────────────────────────────┘

spaceBetween（首尾贴边，中间均分）:
┌──────────────────────────────────┐
│ [A]         [B]            [C]   │
└──────────────────────────────────┘

spaceAround（每个子组件两侧有相等间距）:
┌──────────────────────────────────┐
│   [A]       [B]        [C]       │
└──────────────────────────────────┘
  ↑ 半份 ↑  一份  ↑  一份  ↑ 半份 ↑

spaceEvenly（所有间距完全相等）:
┌──────────────────────────────────┐
│     [A]      [B]       [C]       │
└──────────────────────────────────┘
  ↑ 等份 ↑  等份  ↑  等份  ↑ 等份 ↑
```

### 1.3 CrossAxisAlignment（交叉轴对齐方式）

`CrossAxisAlignment` 控制子组件在**交叉轴方向**上的对齐方式。

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Container(height: 50),  // 较矮
    Container(height: 100), // 较高
  ],
)
```

各枚举值的效果（以 Row 为例，交叉轴为垂直方向）：

```
start（顶部对齐）:
┌──────────────────┐
│ [A]  ┌──┐        │
│      │B │        │
│      │  │        │
│      └──┘        │
└──────────────────┘

center（居中对齐，默认值）:
┌──────────────────┐
│      ┌──┐        │
│ [A]  │B │        │
│      │  │        │
│      └──┘        │
└──────────────────┘

end（底部对齐）:
┌──────────────────┐
│      ┌──┐        │
│      │B │        │
│      │  │        │
│ [A]  └──┘        │
└──────────────────┘

stretch（拉伸填满交叉轴）:
┌──────────────────┐
│ ┌──┐ ┌──┐        │
│ │A │ │B │        │
│ │  │ │  │        │
│ └──┘ └──┘        │
└──────────────────┘

baseline（基线对齐，仅对文本有效）:
需要设置 textBaseline 参数
```

> **注意**：使用 `CrossAxisAlignment.baseline` 时，必须同时设置 `textBaseline` 参数，否则会报错。

### 1.4 MainAxisSize（主轴尺寸策略）

`MainAxisSize` 决定 Row/Column 在主轴方向上占用多少空间：

- **`MainAxisSize.max`**（默认）：占据主轴方向上所有可用空间
- **`MainAxisSize.min`**：仅占据子组件所需的最小空间

```
MainAxisSize.max（默认）:
┌──────────────────────────────────┐
│ [A][B][C]                        │  ← Row 占满整行
└──────────────────────────────────┘

MainAxisSize.min:
┌──────────┐
│ [A][B][C]│  ← Row 仅包裹子组件
└──────────┘
```

```dart
// 示例：Row 仅占据必要宽度
Row(
  mainAxisSize: MainAxisSize.min, // 收缩到最小
  children: const [
    Icon(Icons.star),
    Text('收藏'),
  ],
)
```

---

## 2. Flexible 和 Expanded

### 2.1 Flexible

`Flexible` 允许子组件在主轴方向上**弹性**占据剩余空间。

```dart
Flexible({
  int flex = 1,            // 弹性系数
  FlexFit fit = FlexFit.loose,  // 填充方式
  required Widget child,
})
```

#### flex 系数

`flex` 决定了子组件分配剩余空间的**比例**：

```
总可用宽度: 300px
固定子组件: [A] = 60px
剩余空间: 240px

Flexible(flex: 1, child: [B])  → 240 * 1/3 = 80px
Flexible(flex: 2, child: [C])  → 240 * 2/3 = 160px

┌──────────────────────────────────┐
│ [A:60]  [B:80]     [C:160]       │
└──────────────────────────────────┘
```

#### fit 参数

`FlexFit` 有两个值：

- **`FlexFit.loose`**（Flexible 默认值）：子组件的大小可以**小于等于**分配到的空间
- **`FlexFit.tight`**（Expanded 使用）：子组件的大小必须**等于**分配到的空间

```
FlexFit.loose（宽松模式）:
分配空间: 160px，子组件实际宽度: 80px
┌─────────────────┐
│ [C:80]          │  ← 右侧有空余
└─────────────────┘

FlexFit.tight（紧凑模式 = Expanded）:
分配空间: 160px，子组件强制填满: 160px
┌─────────────────┐
│ [C:  160px     ]│  ← 完全填满
└─────────────────┘
```

### 2.2 Expanded

`Expanded` 是 `Flexible` 的快捷写法，等价于 `Flexible(fit: FlexFit.tight)`：

```dart
// 这两种写法完全等价
Expanded(flex: 2, child: widget)
Flexible(flex: 2, fit: FlexFit.tight, child: widget)
```

#### 常用布局模式

```dart
// 经典的三栏布局：左固定 + 中间弹性 + 右固定
Row(
  children: [
    const SizedBox(width: 80, child: Text('左侧')),
    Expanded(child: Text('中间内容，自动填充剩余空间')),
    const SizedBox(width: 80, child: Text('右侧')),
  ],
)

// 等分布局
Row(
  children: [
    Expanded(flex: 1, child: CardA()),
    Expanded(flex: 1, child: CardB()),
    Expanded(flex: 1, child: CardC()),
  ],
)
```

---

## 3. Spacer

`Spacer` 是一个利用 `Expanded` 实现的空白间距控件，用于在 Row/Column 中创建可弹性伸缩的空白区域。

```dart
// Spacer 的源码非常简单
class Spacer extends StatelessWidget {
  const Spacer({super.key, this.flex = 1});
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: const SizedBox.shrink());
  }
}
```

### 使用场景

```dart
// 将按钮推到右侧
Row(
  children: [
    const Text('标题'),
    const Spacer(), // 占据所有剩余空间
    ElevatedButton(onPressed: () {}, child: const Text('操作')),
  ],
)
```

```
效果:
┌──────────────────────────────────┐
│ [标题]              [操作按钮]    │
└──────────────────────────────────┘
        ↑ Spacer 占据中间空间
```

```dart
// 使用 flex 控制比例间距
Row(
  children: [
    const Text('A'),
    const Spacer(flex: 2), // 2 份空间
    const Text('B'),
    const Spacer(flex: 1), // 1 份空间
    const Text('C'),
  ],
)
```

---

## 4. Wrap

### 4.1 基本概念

`Wrap` 类似于 Row/Column，但当子组件在主轴方向上超出可用空间时，会自动**换行/换列**。

```dart
Wrap({
  Axis direction = Axis.horizontal,     // 排列方向
  WrapAlignment alignment = WrapAlignment.start,  // 主轴对齐
  double spacing = 0.0,                 // 子组件之间的主轴间距
  WrapAlignment runAlignment = WrapAlignment.start, // 行/列之间的交叉轴对齐
  double runSpacing = 0.0,              // 行/列之间的交叉轴间距
  WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
})
```

### 4.2 关键参数详解

#### direction（排列方向）

```
Axis.horizontal（默认，类似 Row 但会换行）:
┌──────────────────┐
│ [A] [B] [C] [D]  │
│ [E] [F]          │  ← 第二行
└──────────────────┘

Axis.vertical（类似 Column 但会换列）:
┌──────────────────┐
│ [A]  [D]         │
│ [B]  [E]         │
│ [C]  [F]         │
│      ↑ 第二列    │
└──────────────────┘
```

#### spacing 和 runSpacing

```
spacing = 8（同一行子组件间水平间距）
runSpacing = 12（行与行之间的垂直间距）

┌──────────────────────────┐
│ [A]←8→[B]←8→[C]←8→[D]  │
│       ↕ 12               │
│ [E]←8→[F]               │
└──────────────────────────┘
```

#### alignment（主轴对齐方式）

`WrapAlignment` 的值与 `MainAxisAlignment` 类似：

- `start`、`end`、`center`
- `spaceBetween`、`spaceAround`、`spaceEvenly`

```dart
// 标签云常用配置
Wrap(
  spacing: 8.0,        // 标签水平间距
  runSpacing: 4.0,     // 行间距
  alignment: WrapAlignment.start,
  children: tags.map((tag) => Chip(label: Text(tag))).toList(),
)
```

### 4.3 标签云示例

```dart
/// 标签云 - Wrap 的经典使用场景
Widget buildTagCloud() {
  final tags = ['Flutter', 'Dart', '布局', '响应式', 'Widget', '状态管理',
                 'Material', 'Cupertino', '动画', '路由', '网络请求'];

  return Wrap(
    spacing: 8.0,
    runSpacing: 6.0,
    children: tags.map((tag) {
      return Chip(
        label: Text(tag),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
      );
    }).toList(),
  );
}
```

---

## 5. Flow

### 5.1 基本概念

`Flow` 是一个高性能的自定义布局控件。它通过 `FlowDelegate` 来控制子组件的定位，特别适合需要**频繁重新定位**子组件（如动画）的场景。

**与其他布局的区别：**

| 特性 | Row/Column | Wrap | Flow |
|------|-----------|------|------|
| 自动排列 | ✅ | ✅ | ❌ |
| 自动换行 | ❌ | ✅ | ❌ |
| 自定义定位 | ❌ | ❌ | ✅ |
| 性能 | 一般 | 一般 | **最优** |
| 使用难度 | 简单 | 简单 | 较复杂 |

### 5.2 FlowDelegate

使用 Flow 需要实现一个 `FlowDelegate` 子类：

```dart
class MyFlowDelegate extends FlowDelegate {
  @override
  void paintChildren(FlowPaintingContext context) {
    // 在这里控制每个子组件的位置
    double dx = 0;
    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i)!;
      // 如果当前行放不下，换行
      if (dx + childSize.width > context.size.width) {
        dx = 0;
        // ... 更新 dy
      }
      // 绘制子组件到指定位置
      context.paintChild(i, transform: Matrix4.translationValues(dx, dy, 0));
      dx += childSize.width + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) => false;
}
```

### 5.3 FlowDelegate 的核心方法

```dart
abstract class FlowDelegate {
  /// 控制子组件的绘制位置
  /// context.childCount - 子组件数量
  /// context.getChildSize(i) - 获取第 i 个子组件的尺寸
  /// context.paintChild(i, transform: ...) - 在指定位置绘制子组件
  void paintChildren(FlowPaintingContext context);

  /// 是否需要重新布局
  bool shouldRelayout(FlowDelegate oldDelegate) => false;

  /// 是否需要重新绘制（通常用于动画）
  bool shouldRepaint(FlowDelegate oldDelegate);

  /// 可选：自定义约束
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return constraints;  // 默认传递父约束
  }

  /// 可选：自定义 Flow 的尺寸
  Size getSize(BoxConstraints constraints) {
    return constraints.biggest;  // 默认尽可能大
  }
}
```

### 5.4 Flow 的性能优势

Flow 的高性能来源于：

1. **子组件只测量一次**：尺寸在布局阶段确定后不再变化
2. **仅通过变换矩阵重新定位**：`paintChild` 使用 `Matrix4` 进行 transform，这是 GPU 级别的操作
3. **选择性重绘**：通过 `shouldRepaint` 可以精确控制何时需要重绘

```
传统布局重排流程:
  测量(measure) → 布局(layout) → 绘制(paint)
  ↑ 每次变化都要经历完整流程

Flow 重排流程:
  绘制(paint only)  ← 只需要重新绘制，跳过测量和布局！
```

---

## 6. 实战示例

### 6.1 响应式卡片布局

使用 `LayoutBuilder` + `Wrap` 实现根据屏幕宽度自动调整列数的卡片布局：

```dart
Widget buildResponsiveCards() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // 根据可用宽度计算卡片宽度
      final availableWidth = constraints.maxWidth;
      int crossAxisCount;
      if (availableWidth >= 900) {
        crossAxisCount = 4; // 大屏：4 列
      } else if (availableWidth >= 600) {
        crossAxisCount = 3; // 中屏：3 列
      } else {
        crossAxisCount = 2; // 小屏：2 列
      }

      final cardWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(8, (index) {
          return SizedBox(
            width: cardWidth,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.folder, size: 48,
                         color: Colors.blue.withValues(alpha: 0.8)),
                    const SizedBox(height: 8),
                    Text('卡片 ${index + 1}'),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    },
  );
}
```

### 6.2 Flow 实现自定义标签云

```dart
class TagFlowDelegate extends FlowDelegate {
  final double spacing;

  TagFlowDelegate({required this.spacing});

  @override
  void paintChildren(FlowPaintingContext context) {
    double dx = 0;
    double dy = 0;
    double rowHeight = 0;

    for (int i = 0; i < context.childCount; i++) {
      final childSize = context.getChildSize(i)!;

      // 换行判断
      if (dx + childSize.width > context.size.width && dx > 0) {
        dx = 0;
        dy += rowHeight + spacing;
        rowHeight = 0;
      }

      context.paintChild(i,
        transform: Matrix4.translationValues(dx, dy, 0),
      );

      dx += childSize.width + spacing;
      rowHeight = rowHeight > childSize.height ? rowHeight : childSize.height;
    }
  }

  @override
  bool shouldRepaint(TagFlowDelegate oldDelegate) => false;
}
```

### 6.3 底部操作栏

```dart
/// 常见的底部操作栏布局
Widget buildBottomBar() {
  return Row(
    children: [
      // 左侧信息
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('合计', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('¥ 299.00', style: TextStyle(fontSize: 18, color: Colors.red)),
        ],
      ),
      const Spacer(), // 弹性空间
      // 右侧操作按钮
      OutlinedButton(onPressed: () {}, child: const Text('加入购物车')),
      const SizedBox(width: 12),
      ElevatedButton(onPressed: () {}, child: const Text('立即购买')),
    ],
  );
}
```

---

## 7. 最佳实践总结

### 7.1 选择正确的布局控件

```
需求分析：
├─ 子组件在一行/一列？
│   ├─ 不会溢出 → Row / Column
│   └─ 可能溢出 → Wrap
├─ 需要弹性分配空间？ → Expanded / Flexible
├─ 需要自定义高性能布局？ → Flow
└─ 只需要空白间距？ → Spacer / SizedBox
```

### 7.2 常见问题和解决方案

#### 问题 1：Row/Column 溢出（黄黑条纹警告）

```dart
// ❌ 错误：内容过长导致溢出
Row(children: [Text('非常长的文本内容...')])

// ✅ 解决方案 1：用 Expanded 包裹可伸缩子组件
Row(children: [Expanded(child: Text('非常长的文本内容...', overflow: TextOverflow.ellipsis))])

// ✅ 解决方案 2：使用 Wrap 自动换行
Wrap(children: [Text('非常长的文本内容...')])
```

#### 问题 2：Column 内嵌 ListView

```dart
// ❌ 错误：Column 内直接放 ListView 会报错
Column(children: [ListView(...)])

// ✅ 解决方案：用 Expanded 包裹 ListView
Column(children: [Expanded(child: ListView(...))])
```

#### 问题 3：Flexible/Expanded 只能用在 Row/Column/Flex 中

```dart
// ❌ 错误：在非 Flex 父组件中使用 Expanded
Container(child: Expanded(child: Text('hello')))  // 报错！

// ✅ 正确：只在 Row/Column/Flex 中使用
Row(children: [Expanded(child: Text('hello'))])
```

### 7.3 性能建议

1. **优先使用 `const` 构造函数**：减少不必要的重建
2. **避免深度嵌套**：多层 Row/Column 嵌套会增加布局计算复杂度
3. **大量子组件用 Flow**：Flow 的重绘性能远优于 Wrap
4. **合理使用 MainAxisSize.min**：避免不必要的空间占用
5. **避免使用 `withOpacity()`**：使用 `withValues(alpha: x)` 替代，性能更好

### 7.4 调试技巧

```dart
// 使用 debugPaintSizeEnabled 查看布局边界
import 'package:flutter/rendering.dart';
void main() {
  debugPaintSizeEnabled = true; // 显示所有组件的边界
  runApp(MyApp());
}
```

---

## 小结

| 控件 | 用途 | 是否换行 | 性能 |
|------|------|---------|------|
| Row | 水平排列 | ❌ | ⭐⭐⭐ |
| Column | 垂直排列 | ❌ | ⭐⭐⭐ |
| Flexible | 弹性空间（宽松） | ❌ | ⭐⭐⭐ |
| Expanded | 弹性空间（填满） | ❌ | ⭐⭐⭐ |
| Spacer | 弹性空白 | ❌ | ⭐⭐⭐ |
| Wrap | 自动换行排列 | ✅ | ⭐⭐ |
| Flow | 自定义高性能布局 | 自定义 | ⭐⭐⭐⭐⭐ |

> **下一章预告**：第四章将学习层叠布局控件 Stack 和 Positioned，以及如何实现复杂的重叠效果。
