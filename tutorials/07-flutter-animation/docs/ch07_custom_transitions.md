# 第7章：自定义页面转场

## 概述

页面转场动画是提升应用体验的重要手段。Flutter 默认提供了 `MaterialPageRoute`（Android 风格）和 `CupertinoPageRoute`（iOS 风格）两种转场。本章将深入讲解如何使用 `PageRouteBuilder` 创建自定义转场效果，包括淡入、滑入、缩放、旋转和 3D 翻转等效果。

---

## 7.1 PageRouteBuilder 基础

### 为什么需要自定义转场

默认的 `MaterialPageRoute` 使用平台标准的转场动画。但在以下场景中，我们需要自定义转场：

- 品牌化体验：让转场风格符合应用的设计语言
- 上下文关联：从某个元素展开新页面
- 特殊效果：实现酷炫的 3D 翻转、粒子效果等

### PageRouteBuilder 构造

```dart
PageRouteBuilder(
  // 目标页面
  pageBuilder: (context, animation, secondaryAnimation) {
    return const TargetPage();
  },
  // 转场动画
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  // 动画持续时间
  transitionDuration: const Duration(milliseconds: 500),
  // 反向动画持续时间（返回时）
  reverseTransitionDuration: const Duration(milliseconds: 300),
)
```

### 两个动画参数

`transitionsBuilder` 接收两个 Animation 参数：

- **`animation`**：当前页面的进入动画（0.0 → 1.0 进入，1.0 → 0.0 退出）
- **`secondaryAnimation`**：当新页面压入时，当前页面的退出动画（用于实现"旧页面同时退出"的效果）

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  // animation: 新页面进场
  // secondaryAnimation: 当更新的页面覆盖当前页面时触发
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
},
```

---

## 7.2 淡入转场（Fade Transition）

最简单的转场效果，新页面逐渐变为不透明。

```dart
PageRouteBuilder(
  pageBuilder: (context, animation, secondaryAnimation) => const TargetPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  transitionDuration: const Duration(milliseconds: 600),
)
```

### 使用 CurvedAnimation 添加缓动

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOut,
  );
  return FadeTransition(
    opacity: curvedAnimation,
    child: child,
  );
},
```

---

## 7.3 滑入转场（Slide Transition）

页面从指定方向滑入。

### 从右向左滑入

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final offsetAnimation = Tween<Offset>(
    begin: const Offset(1.0, 0.0), // 从右侧开始
    end: Offset.zero,               // 滑到原位
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  ));

  return SlideTransition(
    position: offsetAnimation,
    child: child,
  );
},
```

### 从底部向上滑入

```dart
begin: const Offset(0.0, 1.0), // 从底部开始
end: Offset.zero,
```

### Offset 方向参考

| Offset | 方向 |
|--------|------|
| `Offset(1.0, 0.0)` | 右侧 |
| `Offset(-1.0, 0.0)` | 左侧 |
| `Offset(0.0, 1.0)` | 底部 |
| `Offset(0.0, -1.0)` | 顶部 |

---

## 7.4 缩放转场（Scale Transition）

页面从小变大或从大变小。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final scaleAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutBack, // 带回弹效果
  ));

  return ScaleTransition(
    scale: scaleAnimation,
    child: child,
  );
},
```

### 缩放 + 淡入组合

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );

  return FadeTransition(
    opacity: curvedAnimation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
      child: child,
    ),
  );
},
```

---

## 7.5 旋转转场（Rotation Transition）

页面旋转进入。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final rotationAnimation = Tween<double>(
    begin: 0.5, // 旋转半圈（turns 为单位）
    end: 0.0,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  ));

  return RotationTransition(
    turns: rotationAnimation,
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
},
```

> **提示**：单独的旋转效果可能看起来比较突兀，通常搭配淡入或缩放使用。

---

## 7.6 3D 翻转转场

使用 `Transform` 和 `Matrix4` 实现 3D 翻转效果。

```dart
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  final rotateAnimation = Tween<double>(
    begin: 1.0,
    end: 0.0,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutBack,
  ));

  return AnimatedBuilder(
    animation: rotateAnimation,
    child: child,
    builder: (context, child) {
      // 使用 Matrix4 创建 3D 透视效果
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.001)  // 透视效果
        ..rotateY(rotateAnimation.value * 3.14159); // 绕 Y 轴旋转

      return Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: child,
      );
    },
  );
},
```

### 透视效果说明

`Matrix4.setEntry(3, 2, value)` 设置透视变换：
- 值越大，透视效果越强（近大远小更明显）
- 推荐值在 `0.001` 到 `0.003` 之间
- 设为 0 则无透视效果（正交投影）

---

## 7.7 双向转场

双向转场意味着新页面进入时，旧页面同时有退出动画。

### 实现方式

利用 `secondaryAnimation` 参数控制旧页面的动画：

```dart
// 在旧页面的路由定义中，处理 secondaryAnimation
transitionsBuilder: (context, animation, secondaryAnimation, child) {
  // 新页面滑入
  final slideIn = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  ));

  // 旧页面缩小并淡出
  final scaleOut = Tween<double>(
    begin: 1.0,
    end: 0.9,
  ).animate(CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeInCubic,
  ));

  final fadeOut = Tween<double>(
    begin: 1.0,
    end: 0.5,
  ).animate(secondaryAnimation);

  return SlideTransition(
    position: slideIn,
    child: FadeTransition(
      opacity: fadeOut,
      child: ScaleTransition(
        scale: scaleOut,
        child: child,
      ),
    ),
  );
},
```

---

## 7.8 封装可复用的转场

### 自定义 PageRoute 类

```dart
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

// 使用
Navigator.push(context, FadePageRoute(page: const DetailPage()));
```

### 使用扩展方法简化调用

```dart
extension NavigatorExtension on BuildContext {
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// 使用
context.pushFade(const DetailPage());
```

---

## 7.9 最佳实践

### 1. 转场时间

- 快速切换（如 Tab）：150-250ms
- 普通页面转场：300-500ms
- 强调效果（如模态弹出）：400-600ms
- 避免超过 700ms，会让用户感觉迟钝

### 2. 选择合适的缓动曲线

```
进入动画 → Curves.easeOut / Curves.easeOutCubic（快入慢出）
退出动画 → Curves.easeIn / Curves.easeInCubic（慢入快出）
双向动画 → Curves.easeInOut（两端慢中间快）
弹性效果 → Curves.easeOutBack / Curves.elasticOut
```

### 3. 性能考虑

- 3D 变换比 2D 变换更消耗性能
- 转场动画中避免触发重新布局
- 使用 `child` 参数缓存不变的子 Widget

### 4. 平台一致性

- 考虑 Android 和 iOS 用户的期望
- iOS 用户习惯从右向左滑入
- 可以通过 `Platform.isIOS` 判断平台

---

## 7.10 本章示例代码

示例代码文件：`lib/ch07_custom_transitions.dart`

展示 5 种自定义转场效果：
1. 淡入转场（Fade）
2. 滑入转场（Slide）
3. 缩放转场（Scale）
4. 旋转转场（Rotation）
5. 3D 翻转转场（3D Flip）

运行方式：
```bash
flutter run -t lib/ch07_custom_transitions.dart
```
