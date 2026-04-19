# 第3章：交错动画 (Staggered Animations)

## 目录

1. [什么是交错动画](#什么是交错动画)
2. [Interval 详解](#interval-详解)
3. [一个 Controller 驱动多动画](#一个-controller-驱动多动画)
4. [列表项依次飞入](#列表项依次飞入)
5. [卡片展开动画](#卡片展开动画)
6. [最佳实践](#最佳实践)

---

## 什么是交错动画

交错动画（Staggered Animations）是指**多个动画按照特定的时间顺序依次执行或重叠执行**的动画模式。关键特征：

- 使用**单个 AnimationController** 驱动所有动画
- 每个子动画占据总时长的**不同时间片段**
- 通过 `Interval` 定义每个子动画的起止时间
- 子动画可以**顺序执行**、**部分重叠**或**完全并行**

### 生活中的类比

想象一个舞台表演：
- 0~2秒：灯光亮起
- 1~3秒：幕布拉开（与灯光有重叠）
- 2~4秒：演员入场（灯光已完成，幕布即将完成）
- 3~5秒：音乐响起

所有这些效果由**一个总调度员**（AnimationController）控制，但每个效果在不同时间段执行。

---

## Interval 详解

`Interval` 是实现交错动画的核心类。它将 AnimationController 的 0.0~1.0 时间线**截取一段**给特定动画使用。

```dart
// Interval(开始时间, 结束时间, curve: 可选曲线)
// 时间值范围是 0.0 ~ 1.0，代表总时长的百分比

// 假设总时长 2 秒
// 这个 Interval 表示在 0~1 秒（前半段）执行
const Interval(0.0, 0.5)

// 这个 Interval 表示在 0.5~1.5 秒（中间段）执行
const Interval(0.25, 0.75)

// 这个 Interval 表示在 1~2 秒（后半段）执行
const Interval(0.5, 1.0)
```

### Interval 的工作原理

```
Controller 时间线:  0.0 -------- 0.5 -------- 1.0
                    |                          |
Interval(0.0,0.5): [===动画执行===]             |  → 输出 0.0~1.0
Interval(0.25,0.75):    [===动画执行===]        |  → 输出 0.0~1.0
Interval(0.5,1.0):               [===动画执行===]  → 输出 0.0~1.0
```

关键理解：**每个 Interval 内部的动画值都是从 0.0 到 1.0**。Interval 只是决定了这个 0→1 的过程在总时间线上的哪个位置。

### 添加曲线

```dart
CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
)
```

---

## 一个 Controller 驱动多动画

### 基本模式

```dart
class _StaggerDemoState extends State<StaggerDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _width;
  late Animation<Color?> _color;
  late Animation<double> _borderRadius;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 0% ~ 30%：透明度从 0 变到 1
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 20% ~ 60%：宽度从 50 变到 200
    _width = Tween<double>(begin: 50.0, end: 200.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    // 40% ~ 80%：颜色从蓝变到红
    _color = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8),
      ),
    );

    // 70% ~ 100%：圆角从 0 变到 50
    _borderRadius = Tween<double>(begin: 0.0, end: 50.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 时间线示意

```
时间进度:     0%   20%   40%   60%   80%  100%
透明度:      [=====]
宽度:             [===========]
颜色:                   [===========]
圆角:                              [=========]
```

---

## 列表项依次飞入

一个经典的交错动画场景：列表中的每一项按顺序从右侧飞入。

### 核心思路

1. 将总时间线按列表项数量**均匀分割**
2. 每一项占据一个时间片段，可以有少许重叠
3. 每一项在自己的时间片段内完成**滑入 + 淡入**

```dart
// 假设有 5 个列表项，总时长 1.5 秒
// 每项占 0.4 的时间片段（有重叠）

List<Animation<Offset>> _slideAnimations = [];
List<Animation<double>> _fadeAnimations = [];

for (int i = 0; i < itemCount; i++) {
  final start = i * 0.15;  // 每项间隔 0.15
  final end = start + 0.4; // 每项持续 0.4

  _slideAnimations.add(
    Tween<Offset>(
      begin: const Offset(1.0, 0.0),  // 从右侧飞入
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
    )),
  );

  _fadeAnimations.add(
    Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end.clamp(0.0, 1.0)),
    )),
  );
}
```

### 使用动画

```dart
ListView.builder(
  itemCount: itemCount,
  itemBuilder: (context, index) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: ListTile(title: Text('项目 $index')),
      ),
    );
  },
)
```

---

## 卡片展开动画

一个更复杂的交错动画：点击卡片后，卡片依次展开多个属性。

### 动画序列

1. **阶段1 (0%~30%)**：卡片高度增加
2. **阶段2 (20%~50%)**：标题文字变大
3. **阶段3 (40%~70%)**：内容区域淡入
4. **阶段4 (60%~90%)**：操作按钮滑入
5. **阶段5 (80%~100%)**：分隔线绘制

```dart
// 高度动画
_heightAnimation = Tween<double>(begin: 80.0, end: 280.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
  ),
);

// 标题大小动画
_titleSizeAnimation = Tween<double>(begin: 16.0, end: 24.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
  ),
);

// 内容淡入
_contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 0.7),
  ),
);

// 按钮滑入
_buttonOffset = Tween<Offset>(
  begin: const Offset(0, 0.5),
  end: Offset.zero,
).animate(CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
));
```

---

## 最佳实践

### 1. 合理规划时间线

在编码前先在纸上画出时间线：

```
0%     25%     50%     75%    100%
|-------|-------|-------|-------|
[==fade in==]
    [====scale up====]
        [====slide in====]
            [====color change====]
```

### 2. 适度重叠让动画更自然

```dart
// ❌ 完全不重叠，感觉像幻灯片
Interval(0.0, 0.33)
Interval(0.33, 0.66)
Interval(0.66, 1.0)

// ✅ 适度重叠，更加流畅
Interval(0.0, 0.4)
Interval(0.2, 0.6)
Interval(0.4, 0.8)
Interval(0.6, 1.0)
```

### 3. 使用 clamp 防止越界

```dart
// 动态计算 Interval 时，确保不超过 1.0
final end = (start + 0.4).clamp(0.0, 1.0);
```

### 4. 性能考虑

- 使用 `AnimatedBuilder` 而不是 `addListener + setState`
- 传入 `child` 参数避免不必要的重建
- 列表项很多时考虑只动画可见区域

### 5. 为列表项动画提取公共组件

```dart
class StaggeredListItem extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
```

---

## 本章示例代码

查看 `lib/ch03_staggered_animations.dart`，该示例展示了：
- 交错动画的基本模式（多属性依次变化）
- 列表项依次飞入效果
- 卡片展开动画
- Interval 的各种使用方式

运行方式：
```bash
flutter run -t lib/ch03_staggered_animations.dart
```
