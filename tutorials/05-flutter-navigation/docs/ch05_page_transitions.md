# 第5章：页面过渡动画

## 概述

页面过渡动画（Page Transition）是指在路由切换时播放的动画效果。好的过渡动画能让用户感知到页面之间的空间关系，提升用户体验。Flutter 提供了灵活的 API 来自定义这些动画。

本章将涵盖：
1. `PageRouteBuilder` 自定义过渡
2. 常见过渡效果：Fade、Slide、Scale、Rotation
3. 组合多种过渡
4. Hero 动画

---

## 1. PageRouteBuilder 自定义过渡

### 1.1 默认过渡行为

在 Material 风格中，`MaterialPageRoute` 使用平台默认的过渡动画：
- Android：从底部向上滑入
- iOS：从右侧滑入

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SecondPage()),
);
```

### 1.2 PageRouteBuilder 原理

当默认动画不满足需求时，可以使用 `PageRouteBuilder` 来完全自定义过渡效果。

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    // 构建目标页面
    pageBuilder: (context, animation, secondaryAnimation) => TargetPage(),
    // 构建过渡效果
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    // 动画持续时间
    transitionDuration: const Duration(milliseconds: 300),
    // 反向动画持续时间（返回时）
    reverseTransitionDuration: const Duration(milliseconds: 300),
  ),
);
```

**参数详解：**

| 参数 | 说明 |
|------|------|
| `pageBuilder` | 返回目标页面的 Widget |
| `transitionsBuilder` | 定义过渡动画效果，`animation` 是进入动画（0.0 → 1.0），`secondaryAnimation` 是当有新页面推入时的退出动画 |
| `transitionDuration` | 前进时的动画时长 |
| `reverseTransitionDuration` | 返回时的动画时长 |
| `opaque` | 页面是否不透明，影响底层页面是否绘制 |
| `barrierColor` | 遮罩颜色 |
| `barrierDismissible` | 点击遮罩是否关闭页面 |

### 1.3 animation 和 secondaryAnimation

理解这两个参数是掌握页面过渡的关键：

- **`animation`**：当前页面的进入/退出动画。从 A 页面 push 到 B 页面时，B 页面的 `animation` 从 0.0 → 1.0；pop 回 A 时，B 页面的 `animation` 从 1.0 → 0.0。

- **`secondaryAnimation`**：当有新页面覆盖当前页面时触发。从 A push 到 B，A 页面的 `secondaryAnimation` 从 0.0 → 1.0；从 B pop 回 A 时，A 页面的 `secondaryAnimation` 从 1.0 → 0.0。

```
push B:    A.secondary: 0→1, B.animation: 0→1
pop  B:    A.secondary: 1→0, B.animation: 1→0
```

---

## 2. 常见过渡效果

### 2.1 淡入淡出（Fade Transition）

最简单的过渡效果，适合内容变化不大的场景。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: animation,
    child: child,
  );
},
```

**使用 CurvedAnimation 添加缓动曲线：**

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ),
    child: child,
  );
},
```

### 2.2 滑动（Slide Transition）

模拟页面从某个方向滑入。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  // Offset(1.0, 0.0) 表示从右侧滑入
  // Offset(-1.0, 0.0) 表示从左侧滑入
  // Offset(0.0, 1.0) 表示从底部滑入
  // Offset(0.0, -1.0) 表示从顶部滑入
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  final tween = Tween(begin: begin, end: end)
      .chain(CurveTween(curve: Curves.easeInOut));

  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
},
```

**Tween 链式调用原理：**

```dart
// 方式一：使用 chain
Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease))

// 方式二：使用 CurvedAnimation
Tween(begin: begin, end: end).animate(
  CurvedAnimation(parent: animation, curve: Curves.ease)
)

// 方式三：使用 drive
animation.drive(Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.ease)))
```

### 2.3 缩放（Scale Transition）

页面从小到大放大出现。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return ScaleTransition(
    scale: CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
    ),
    child: child,
  );
},
```

**设置缩放中心：**

```dart
ScaleTransition(
  scale: animation,
  alignment: Alignment.bottomRight, // 从右下角缩放
  child: child,
)
```

### 2.4 旋转（Rotation Transition）

页面旋转进入，通常用于特殊场景。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return RotationTransition(
    turns: Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    ),
    child: child,
  );
},
```

> **注意：** `turns` 表示旋转圈数。`0.5` 表示半圈（180°），`1.0` 表示一圈（360°）。上面的代码表示从 180° 旋转到 360°（即正常位置）。

---

## 3. 组合多种过渡

可以嵌套多个 Transition Widget 来组合效果。

### 3.1 Fade + Slide 组合

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      )),
      child: child,
    ),
  );
},
```

### 3.2 Scale + Fade 组合

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
},
```

### 3.3 封装为可复用的 Route

```dart
/// 自定义淡入滑动路由
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
        );
}

// 使用
Navigator.push(context, FadeSlideRoute(page: DetailPage()));
```

---

## 4. Hero 动画

### 4.1 基本概念

Hero 动画用于在两个页面之间共享一个 Widget 的过渡效果。典型场景：列表中的缩略图 → 详情页的大图。

**工作原理：**
1. 在源页面和目标页面中，用 `Hero` Widget 包裹需要共享的元素
2. 两个 `Hero` 使用相同的 `tag`
3. 路由切换时，Flutter 会自动在 Overlay 层创建一个飞行动画

```dart
// 源页面
Hero(
  tag: 'avatar-123',
  child: CircleAvatar(
    radius: 30,
    backgroundImage: NetworkImage(imageUrl),
  ),
)

// 目标页面
Hero(
  tag: 'avatar-123', // 相同的 tag
  child: CircleAvatar(
    radius: 100,
    backgroundImage: NetworkImage(imageUrl),
  ),
)
```

### 4.2 Hero 的关键属性

| 属性 | 说明 |
|------|------|
| `tag` | 唯一标识，源和目标页面必须匹配 |
| `child` | 被包裹的 Widget |
| `flightShuttleBuilder` | 自定义飞行过程中显示的 Widget |
| `placeholderBuilder` | 飞行时源位置显示的占位 Widget |
| `createRectTween` | 自定义飞行路径 |
| `transitionOnUserGestures` | 是否在手势返回时也执行动画 |

### 4.3 自定义 flightShuttleBuilder

默认情况下，Hero 在飞行过程中显示目标页面的 child。通过 `flightShuttleBuilder` 可以自定义飞行中的外观。

```dart
Hero(
  tag: 'item-$id',
  // 自定义飞行过程中的 Widget
  flightShuttleBuilder: (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // 飞行过程中使用圆角矩形裁切
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            // 从圆形过渡到方形
            (1 - animation.value) * 50,
          ),
          child: toHeroContext.widget,
        );
      },
    );
  },
  child: ClipOval(child: Image.network(imageUrl)),
)
```

### 4.4 自定义飞行路径

默认的 Hero 飞行路径是直线。通过 `createRectTween` 可以自定义路径。

```dart
Hero(
  tag: 'avatar',
  createRectTween: (begin, end) {
    // 使用 MaterialRectArcTween 实现弧线路径
    return MaterialRectArcTween(begin: begin, end: end);
  },
  child: myWidget,
)
```

---

## 5. 最佳实践

### 5.1 动画时长

- 简单过渡（Fade）：200-300ms
- 中等复杂度（Slide）：300-400ms
- 复杂组合动画：400-600ms
- 不要超过 600ms，用户会觉得缓慢

### 5.2 缓动曲线选择

```
Curves.easeInOut    → 通用，适合大多数场景
Curves.easeOut      → 元素进入时（快速出现，慢慢停下）
Curves.easeIn       → 元素退出时（慢慢加速离开）
Curves.fastOutSlowIn → Material Design 推荐曲线
Curves.elasticOut   → 弹性效果，适合趣味性场景
```

### 5.3 性能注意事项

1. 避免在过渡动画中使用 `Opacity` Widget，改用 `FadeTransition`（后者使用 RenderObject 层的 opacity，性能更好）
2. 使用 `const` 构造函数减少重建
3. Hero 动画的 `tag` 确保全局唯一，否则会报错
4. 在 `transitionsBuilder` 中不要创建新的 Widget 树结构，尽量只包裹 Transition Widget

### 5.4 使用 `withValues` 替代已弃用的 `withOpacity`

```dart
// ❌ 已弃用
color.withOpacity(0.5)

// ✅ 推荐
color.withValues(alpha: 0.5)
```

---

## 6. 小结

| 知识点 | 关键 API |
|--------|---------|
| 自定义过渡 | `PageRouteBuilder`, `transitionsBuilder` |
| 淡入淡出 | `FadeTransition` |
| 滑动过渡 | `SlideTransition`, `Tween<Offset>` |
| 缩放过渡 | `ScaleTransition` |
| 旋转过渡 | `RotationTransition` |
| 缓动曲线 | `CurvedAnimation`, `Curves` |
| Hero 动画 | `Hero`, `tag`, `flightShuttleBuilder` |

下一章我们将学习 Tab 导航与抽屉导航，构建更复杂的应用导航框架。
