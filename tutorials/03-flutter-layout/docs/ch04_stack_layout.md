# 第四章：层叠布局（Stack Layout）

## 目录

1. [概述](#概述)
2. [Stack 组件详解](#stack-组件详解)
3. [Positioned 组件详解](#positioned-组件详解)
4. [IndexedStack 组件详解](#indexedstack-组件详解)
5. [实际应用场景](#实际应用场景)
6. [综合示例代码](#综合示例代码)
7. [最佳实践](#最佳实践)
8. [常见问题与陷阱](#常见问题与陷阱)

---

## 概述

在 Flutter 中，层叠布局（Stack Layout）允许子组件按照**绘制顺序**堆叠在一起，后添加的子组件会覆盖在先添加的子组件之上。这与 CSS 中的 `position: absolute` 配合 `z-index` 的概念类似。

层叠布局的核心组件：

| 组件 | 作用 |
|------|------|
| `Stack` | 层叠容器，管理子组件的堆叠方式 |
| `Positioned` | 定位子组件在 Stack 中的精确位置 |
| `IndexedStack` | 只显示指定索引的子组件（继承自 Stack） |

### 什么时候使用层叠布局？

- 需要将多个组件叠放在一起时（如图片上叠加文字）
- 需要在某个组件的特定位置放置另一个组件时（如角标）
- 需要实现浮动按钮、弹出菜单等覆盖效果时
- 需要在多个页面/视图之间切换但保持状态时

---

## Stack 组件详解

### 基本构造函数

```dart
Stack({
  Key? key,
  AlignmentGeometry alignment = AlignmentDirectional.topStart,
  TextDirection? textDirection,
  StackFit fit = StackFit.loose,
  Clip clipBehavior = Clip.hardEdge,
  List<Widget> children = const <Widget>[],
})
```

### alignment 属性

`alignment` 控制**未定位子组件**（即没有被 `Positioned` 包裹的子组件）在 Stack 中的对齐方式。

```dart
// 所有未定位的子组件居中对齐
Stack(
  alignment: Alignment.center,
  children: [
    Container(width: 200, height: 200, color: Colors.blue),   // 未定位：受 alignment 影响
    Container(width: 100, height: 100, color: Colors.red),     // 未定位：受 alignment 影响
    Positioned(left: 0, top: 0, child: Icon(Icons.star)),      // 已定位：不受 alignment 影响
  ],
)
```

常用的 `Alignment` 值：

| 值 | 说明 |
|----|------|
| `Alignment.topLeft` | 左上角 |
| `Alignment.topCenter` | 顶部居中 |
| `Alignment.topRight` | 右上角 |
| `Alignment.centerLeft` | 左侧居中 |
| `Alignment.center` | 完全居中 |
| `Alignment.centerRight` | 右侧居中 |
| `Alignment.bottomLeft` | 左下角 |
| `Alignment.bottomCenter` | 底部居中 |
| `Alignment.bottomRight` | 右下角 |

> **注意**：`Alignment(x, y)` 中 x 和 y 的范围是 -1.0 到 1.0，其中 `(-1, -1)` 是左上角，`(1, 1)` 是右下角。

### fit 属性

`fit` 决定 Stack 如何约束**未定位子组件**的大小：

#### StackFit.loose（默认值）

子组件可以从 0 到 Stack 的最大约束之间自由选择大小：

```dart
// loose 模式：子组件保持自身的大小
Stack(
  fit: StackFit.loose,
  children: [
    Container(width: 100, height: 100, color: Colors.blue), // 实际为 100x100
    Container(width: 50, height: 50, color: Colors.red),    // 实际为 50x50
  ],
)
```

#### StackFit.expand

强制未定位子组件扩展到 Stack 的最大约束：

```dart
// expand 模式：未定位的子组件会填满整个 Stack
Stack(
  fit: StackFit.expand,
  children: [
    // 即使设置了 width/height，未定位子组件也会被强制撑满
    Container(color: Colors.blue),  // 填满整个 Stack
    Positioned(          // Positioned 子组件不受 fit 影响
      left: 10,
      top: 10,
      child: Text('我不受 fit 影响'),
    ),
  ],
)
```

#### StackFit.passthrough

将父组件传递给 Stack 的约束原样传递给子组件：

```dart
// passthrough 模式：不修改约束，直接透传
Stack(
  fit: StackFit.passthrough,
  children: [
    Container(color: Colors.blue),
  ],
)
```

#### 三种 fit 模式对比

| 模式 | 子组件最小约束 | 子组件最大约束 | 典型场景 |
|------|--------------|--------------|---------|
| `loose` | 0 | Stack 最大约束 | 子组件需要自定义大小 |
| `expand` | Stack 最大约束 | Stack 最大约束 | 需要子组件填满 Stack |
| `passthrough` | 父组件最小约束 | 父组件最大约束 | 需要透传父约束 |

### clipBehavior 属性

`clipBehavior` 控制子组件超出 Stack 边界时的裁剪行为：

```dart
// 允许子组件溢出显示
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(width: 100, height: 100, color: Colors.blue),
    Positioned(
      right: -20,  // 超出右边界 20 像素
      top: 10,
      child: Container(width: 50, height: 50, color: Colors.red),
    ),
  ],
)
```

| 值 | 说明 | 性能 |
|----|------|------|
| `Clip.none` | 不裁剪，允许溢出 | 最好 |
| `Clip.hardEdge` | 硬边裁剪（默认值） | 较好 |
| `Clip.antiAlias` | 抗锯齿裁剪 | 一般 |
| `Clip.antiAliasWithSaveLayer` | 抗锯齿 + SaveLayer | 最差 |

> **性能建议**：如果不需要裁剪效果，使用 `Clip.none` 可以获得最佳性能。如果需要裁剪，大多数情况下 `Clip.hardEdge` 就足够了。

### Stack 的大小计算规则

Stack 的大小取决于其中**最大的未定位子组件**：

```dart
// Stack 的大小由第一个 Container（200x200）决定
Stack(
  children: [
    Container(width: 200, height: 200, color: Colors.blue),  // 决定 Stack 大小
    Container(width: 100, height: 100, color: Colors.red),    // 不影响 Stack 大小
    Positioned(                                                // Positioned 不影响 Stack 大小
      left: 0, top: 0,
      width: 300, height: 300,
      child: Container(color: Colors.green),
    ),
  ],
)
```

---

## Positioned 组件详解

### 基本构造函数

```dart
const Positioned({
  Key? key,
  double? left,    // 距 Stack 左边的距离
  double? top,     // 距 Stack 顶部的距离
  double? right,   // 距 Stack 右边的距离
  double? bottom,  // 距 Stack 底部的距离
  double? width,   // 子组件宽度
  double? height,  // 子组件高度
  required Widget child,
})
```

### 定位规则

#### 水平方向（left、right、width）

这三个属性中，**最多只能指定两个**：

```dart
// 方式1：指定 left 和 width
Positioned(left: 10, width: 100, child: ...)  // 左边距 10，宽度 100

// 方式2：指定 right 和 width
Positioned(right: 10, width: 100, child: ...)  // 右边距 10，宽度 100

// 方式3：指定 left 和 right（宽度由两者决定）
Positioned(left: 10, right: 10, child: ...)  // 左右各留 10，宽度 = Stack宽 - 20

// 错误：不能同时指定三个
// Positioned(left: 10, right: 10, width: 100, child: ...)  // ❌ 会报错
```

#### 垂直方向（top、bottom、height）

同样，这三个属性中最多只能指定两个：

```dart
// 固定在底部，高度为 50
Positioned(bottom: 0, height: 50, child: ...)

// 固定在顶部和底部（高度自适应）
Positioned(top: 10, bottom: 10, child: ...)
```

### Positioned.fill 命名构造函数

快速创建一个填满 Stack 的 Positioned：

```dart
// 等价于 Positioned(left: 0, top: 0, right: 0, bottom: 0, ...)
Positioned.fill(
  child: Container(color: Colors.blue),
)

// 也可以加偏移
Positioned.fill(
  left: 10,
  top: 10,
  right: 10,
  bottom: 10,
  child: Container(color: Colors.blue),
)
```

### Positioned.directional

支持 RTL（从右到左）布局方向：

```dart
Positioned.directional(
  textDirection: TextDirection.rtl,
  start: 10,   // RTL 时相当于 right: 10
  top: 10,
  child: Text('支持 RTL 布局'),
)
```

---

## IndexedStack 组件详解

`IndexedStack` 继承自 `Stack`，但**只显示指定索引位置的子组件**，其余子组件虽然不可见但仍然存在于 Widget 树中。

### 基本用法

```dart
IndexedStack(
  index: _currentIndex,  // 当前显示的子组件索引
  children: [
    PageOne(),    // index == 0 时显示
    PageTwo(),    // index == 1 时显示
    PageThree(),  // index == 2 时显示
  ],
)
```

### 预加载 vs 懒加载对比

#### IndexedStack 的特点（预加载）

| 特性 | 说明 |
|------|------|
| 子组件创建时机 | 全部子组件在初始化时**同时创建** |
| 状态保持 | ✅ 切换时保持所有子组件的状态 |
| 内存占用 | 较高（所有子组件都在内存中） |
| 切换性能 | 极快（无需重建组件） |
| 适用场景 | 底部导航栏、标签页等需要保持状态的场景 |

```dart
// IndexedStack：所有页面同时创建，切换时保持状态
class TabExample extends StatefulWidget {
  const TabExample({super.key});

  @override
  State<TabExample> createState() => _TabExampleState();
}

class _TabExampleState extends State<TabExample> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              HomeTab(),     // 一开始就创建，即使不显示
              SearchTab(),   // 一开始就创建，即使不显示
              ProfileTab(),  // 一开始就创建，即使不显示
            ],
          ),
        ),
        BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ],
    );
  }
}
```

#### 懒加载替代方案

如果子组件初始化开销大，可以使用条件渲染或 `PageView` 实现懒加载：

```dart
// 方案1：条件渲染（不保持状态，每次切换重建）
Widget build(BuildContext context) {
  switch (_currentIndex) {
    case 0: return const HomeTab();
    case 1: return const SearchTab();
    case 2: return const ProfileTab();
    default: return const HomeTab();
  }
}

// 方案2：使用 Offstage（与 IndexedStack 类似，但更灵活）
Stack(
  children: [
    Offstage(offstage: _currentIndex != 0, child: const HomeTab()),
    Offstage(offstage: _currentIndex != 1, child: const SearchTab()),
    Offstage(offstage: _currentIndex != 2, child: const ProfileTab()),
  ],
)
```

#### 对比总结

| 方案 | 预加载 | 保持状态 | 内存 | 初始性能 | 切换性能 |
|------|--------|---------|------|---------|---------|
| IndexedStack | ✅ 是 | ✅ 是 | 高 | 慢 | 快 |
| 条件渲染 | ❌ 否 | ❌ 否 | 低 | 快 | 慢 |
| Offstage | ✅ 是 | ✅ 是 | 高 | 慢 | 快 |
| PageView + keepAlive | 按需加载 | ✅ 是 | 中 | 快 | 中 |

---

## 实际应用场景

### 场景一：角标 Badge

在图标或头像右上角添加红点或数字角标：

```dart
/// 角标组件
Widget buildBadge(Widget child, int count) {
  return Stack(
    clipBehavior: Clip.none,  // 允许角标溢出
    children: [
      child,
      if (count > 0)
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
    ],
  );
}
```

**要点**：
- 使用 `Clip.none` 让角标可以溢出 Stack 边界
- 使用 `Positioned` 的 `right` 和 `top` 负值实现溢出效果
- 条件渲染：`count > 0` 时才显示角标

### 场景二：图片叠加文字

在图片上显示标题、描述或渐变遮罩：

```dart
/// 图片叠加文字的卡片
Widget buildImageCard(String imageUrl, String title) {
  return Stack(
    children: [
      // 底层：图片
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      ),
      // 中层：渐变遮罩（让文字更清晰）
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ),
      // 上层：文字
      Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
```

**要点**：
- 使用三层结构：底层图片 → 渐变遮罩 → 文字
- `Positioned.fill` 让遮罩覆盖整个图片
- 使用 `withValues(alpha: 0.7)` 代替 `withOpacity(0.7)`

### 场景三：用户头像 + 在线状态

```dart
/// 带在线状态指示器的头像
Widget buildAvatar(String avatarUrl, bool isOnline) {
  return Stack(
    children: [
      // 头像
      CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(avatarUrl),
      ),
      // 在线状态指示器
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    ],
  );
}
```

**要点**：
- 头像和状态指示器的层叠关系
- 使用白色边框让指示器在头像上更加突出
- 根据在线状态动态改变颜色

---

## 综合示例代码

完整的可运行示例请参考 `lib/ch04_stack_layout.dart`，该文件包含了本章所有知识点的综合演示：

1. **Stack 基本用法**：不同 alignment 和 fit 效果
2. **Positioned 定位**：四角定位和自适应宽度
3. **clipBehavior 演示**：溢出裁剪与不裁剪的对比
4. **IndexedStack 切换**：带按钮的页面切换演示
5. **角标 Badge**：消息图标角标
6. **图片叠加文字**：渐变遮罩 + 文字
7. **头像在线状态**：圆形头像 + 状态指示器

---

## 最佳实践

### 1. 合理选择 clipBehavior

```dart
// ✅ 不需要裁剪时，显式设置 Clip.none 提升性能
Stack(
  clipBehavior: Clip.none,
  children: [...],
)

// ❌ 避免使用 antiAliasWithSaveLayer，除非确实需要
Stack(
  clipBehavior: Clip.antiAliasWithSaveLayer,  // 性能最差
  children: [...],
)
```

### 2. 使用 const 构造函数

```dart
// ✅ 尽量使用 const
const Positioned(
  left: 0,
  top: 0,
  child: Icon(Icons.star),
)
```

### 3. 避免不必要的嵌套

```dart
// ❌ 不必要的嵌套
Stack(
  children: [
    Stack(
      children: [
        widget1,
        widget2,
      ],
    ),
    widget3,
  ],
)

// ✅ 扁平化结构
Stack(
  children: [
    widget1,
    widget2,
    widget3,
  ],
)
```

### 4. IndexedStack 的使用建议

```dart
// ✅ 页面数量少（3-5个）且需要保持状态时使用 IndexedStack
IndexedStack(
  index: _currentIndex,
  children: const [PageA(), PageB(), PageC()],
)

// ❌ 页面数量多或初始化开销大时，考虑懒加载方案
// IndexedStack 会同时创建所有子组件，页面太多会占用大量内存
```

### 5. 使用 withValues 替代 withOpacity

```dart
// ✅ 推荐：使用 withValues
Colors.black.withValues(alpha: 0.5)

// ❌ 不推荐：withOpacity 在某些场景下可能导致问题
// Colors.black.withOpacity(0.5)
```

---

## 常见问题与陷阱

### 问题 1：Stack 大小为零

```dart
// ❌ 如果所有子组件都是 Positioned，Stack 大小为 0
Stack(
  children: [
    Positioned(left: 0, top: 0, child: Text('A')),
    Positioned(right: 0, bottom: 0, child: Text('B')),
  ],
)

// ✅ 解决：添加一个非 Positioned 的子组件，或给 Stack 一个明确的大小
SizedBox(
  width: 200,
  height: 200,
  child: Stack(
    children: [
      Positioned(left: 0, top: 0, child: Text('A')),
      Positioned(right: 0, bottom: 0, child: Text('B')),
    ],
  ),
)
```

### 问题 2：Positioned 不生效

```dart
// ❌ Positioned 必须是 Stack 的直接子组件
Stack(
  children: [
    Padding(
      padding: EdgeInsets.all(8),
      child: Positioned(  // 无效！Positioned 不是 Stack 的直接子组件
        left: 0, top: 0,
        child: Text('无效'),
      ),
    ),
  ],
)

// ✅ Positioned 直接放在 Stack 下
Stack(
  children: [
    Positioned(
      left: 8, top: 8,
      child: Text('有效'),
    ),
  ],
)
```

### 问题 3：IndexedStack 内存占用过大

如果 IndexedStack 的子组件数量较多或初始化代价大，应考虑以下优化策略：

- **延迟创建**：首次切换到某个 Tab 时才创建对应的组件
- **分页加载**：结合 `PageView` 和 `AutomaticKeepAliveClientMixin`
- **手动管理**：使用 `Visibility` 或 `Offstage` 替代，按需控制

---

> **小结**：层叠布局是 Flutter 中非常强大的布局方式，合理使用 Stack、Positioned 和 IndexedStack 可以实现各种复杂的 UI 效果。关键是理解每个属性的作用和子组件的约束传递规则，避免常见的陷阱。
