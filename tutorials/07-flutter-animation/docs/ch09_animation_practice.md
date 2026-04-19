# 第9章：动画实战 — 天气动效页面

## 概述

本章是一个综合实战项目，将前面学到的动画知识融会贯通，构建一个完整的**天气动效展示页面**。这个页面包含四个核心动画模块：

1. **视差滚动背景** — 多层背景以不同速度滚动，创造纵深感
2. **天气图标动画切换** — 不同天气状态之间平滑过渡
3. **温度数字滚动** — 数字变化时的滚动动画效果
4. **入场交错动画** — 页面元素依次进入的编排动画

---

## 9.1 视差滚动背景（Parallax Background）

### 原理

视差滚动（Parallax Scrolling）是一种经典的视觉效果：距离"摄像机"越近的层移动越快，越远的层移动越慢，从而创造出纵深感。

### 实现思路

```
远景层（天空）    → 移动最慢（偏移系数 0.1）
中景层（云朵）    → 中等速度（偏移系数 0.3）
近景层（建筑/山） → 移动最快（偏移系数 0.6）
```

### 关键代码

```dart
// 使用 AnimationController 驱动周期性的视差偏移
class ParallaxBackground extends StatefulWidget {
  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(); // 无限循环
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 远景层 — 移动最慢
            _buildLayer(
              offset: _controller.value * 50,
              color: Colors.indigo,
              height: 0.3,
            ),
            // 中景层
            _buildLayer(
              offset: _controller.value * 150,
              color: Colors.blueGrey,
              height: 0.5,
            ),
            // 近景层 — 移动最快
            _buildLayer(
              offset: _controller.value * 300,
              color: Colors.grey,
              height: 0.7,
            ),
          ],
        );
      },
    );
  }
}
```

### 使用 CustomPainter 绘制

对于更精细的视差效果，使用 `CustomPainter`：

```dart
class ParallaxPainter extends CustomPainter {
  final double animationValue;

  ParallaxPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制远景（天空渐变）
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1a237e),
        const Color(0xFF283593),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = skyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      ),
    );

    // 绘制山脉（近景层），使用正弦函数创建起伏
    final mountainPath = Path();
    mountainPath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.6 +
          sin((x / size.width * 2 * pi) + animationValue * 2 * pi * 0.1) * 30;
      mountainPath.lineTo(x, y);
    }
    mountainPath.lineTo(size.width, size.height);
    mountainPath.close();
    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF37474f));
  }

  @override
  bool shouldRepaint(covariant ParallaxPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
```

---

## 9.2 天气图标动画切换

### 设计思路

天气图标切换包含两个动画：
1. **旧图标退出**：缩小 + 淡出 + 向上移动
2. **新图标进入**：放大 + 淡入 + 从下方移入

### 使用 AnimatedSwitcher

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 600),
  switchInCurve: Curves.easeOutBack,
  switchOutCurve: Curves.easeIn,
  transitionBuilder: (child, animation) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation,
          child: child,
        ),
      ),
    );
  },
  child: Icon(
    _weatherIcon,
    key: ValueKey(_weatherType), // key 变化触发切换
    size: 80,
    color: Colors.white,
  ),
)
```

### 天气状态映射

```dart
// 天气类型枚举
enum WeatherType { sunny, cloudy, rainy, snowy, stormy }

// 图标映射
IconData getWeatherIcon(WeatherType type) {
  switch (type) {
    case WeatherType.sunny: return Icons.wb_sunny;
    case WeatherType.cloudy: return Icons.cloud;
    case WeatherType.rainy: return Icons.grain;
    case WeatherType.snowy: return Icons.ac_unit;
    case WeatherType.stormy: return Icons.flash_on;
  }
}

// 颜色映射
Color getWeatherColor(WeatherType type) {
  switch (type) {
    case WeatherType.sunny: return const Color(0xFFFF8F00);
    case WeatherType.cloudy: return const Color(0xFF78909C);
    case WeatherType.rainy: return const Color(0xFF42A5F5);
    case WeatherType.snowy: return const Color(0xFFE0E0E0);
    case WeatherType.stormy: return const Color(0xFFFFD600);
  }
}
```

---

## 9.3 温度数字滚动

### 原理

温度变化时，数字像老虎机一样滚动到新的值。核心思想是将每个数字放在一个竖直列表中，通过动画控制列表的偏移来实现滚动效果。

### 实现方案

```dart
class RollingNumber extends StatelessWidget {
  final int value;
  final Duration duration;

  const RollingNumber({
    required this.value,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: digits.map((digit) {
        return _RollingDigit(
          digit: int.parse(digit),
          duration: duration,
        );
      }).toList(),
    );
  }
}
```

### 单个数字的滚动动画

```dart
class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  int _previousDigit = 0;

  @override
  void didUpdateWidget(covariant _RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = oldWidget.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          child: Stack(
            children: [
              // 旧数字向上滚出
              Transform.translate(
                offset: Offset(0, -_animation.value * 40),
                child: Opacity(
                  opacity: 1 - _animation.value,
                  child: Text('$_previousDigit',
                    style: const TextStyle(fontSize: 32)),
                ),
              ),
              // 新数字从下方滚入
              Transform.translate(
                offset: Offset(0, (1 - _animation.value) * 40),
                child: Opacity(
                  opacity: _animation.value,
                  child: Text('${widget.digit}',
                    style: const TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 使用 TweenAnimationBuilder 的简化版

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: oldTemp, end: newTemp),
  duration: const Duration(milliseconds: 1000),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) {
    return Text(
      '${value.toStringAsFixed(0)}°',
      style: const TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  },
)
```

---

## 9.4 入场交错动画（Staggered Animation）

### 原理

交错动画是指多个动画按照一定的时间间隔依次开始播放，形成元素逐个登场的视觉效果。

### 使用 Interval 实现

```dart
class StaggeredEntrance extends StatefulWidget {
  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 为每个元素创建交错的动画
    _fadeAnimations = List.generate(5, (index) {
      final start = index * 0.15;       // 每个间隔 15%
      final end = start + 0.4;          // 持续 40% 的总时长
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0),
            curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(5, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
        ),
      );
    });

    // 启动动画
    _controller.forward();
  }
}
```

### Interval 工作原理

`Interval` 将动画的 0.0-1.0 范围映射到一个子区间：

```
总动画时长：1500ms

元素0: Interval(0.0, 0.4)  → 0ms ~ 600ms
元素1: Interval(0.15, 0.55) → 225ms ~ 825ms
元素2: Interval(0.3, 0.7)  → 450ms ~ 1050ms
元素3: Interval(0.45, 0.85) → 675ms ~ 1275ms
元素4: Interval(0.6, 1.0)  → 900ms ~ 1500ms

结果：每个元素间隔 225ms 依次开始动画
```

### 构建交错列表项

```dart
Widget _buildStaggeredItem(int index) {
  return FadeTransition(
    opacity: _fadeAnimations[index],
    child: SlideTransition(
      position: _slideAnimations[index],
      child: _buildInfoCard(index),
    ),
  );
}
```

---

## 9.5 综合整合

### 页面结构

```
WeatherAnimationPage
├── ParallaxBackground (视差背景)
│   ├── SkyLayer (天空渐变层)
│   ├── CloudLayer (云朵层)
│   └── MountainLayer (山脉层)
├── ContentOverlay (内容叠加层)
│   ├── WeatherIcon (天气图标切换)
│   ├── TemperatureDisplay (温度数字滚动)
│   ├── WeatherInfo (天气信息)
│   └── InfoCards (信息卡片 - 交错入场)
└── WeatherSelector (天气类型选择器)
```

### 动画协调

各动画的触发时机：

```
页面加载:
  0ms     → 视差背景开始循环
  200ms   → 天气图标淡入
  400ms   → 温度数字出现
  600ms+  → 信息卡片交错入场

切换天气:
  0ms     → 背景色开始渐变
  0ms     → 旧天气图标退出
  200ms   → 新天气图标进入
  200ms   → 温度数字滚动
  400ms   → 信息卡片刷新（交错动画）
```

### 状态管理

```dart
class WeatherState {
  final WeatherType type;
  final int temperature;
  final String description;
  final List<WeatherDetail> details;
}

// 切换天气时触发所有动画
void _switchWeather(WeatherType newType) {
  setState(() {
    _currentWeather = _getWeatherData(newType);
  });
  // 重置交错动画
  _staggerController.reset();
  _staggerController.forward();
}
```

---

## 9.6 性能优化

### 1. RepaintBoundary

```dart
// 将频繁重绘的层隔离
RepaintBoundary(
  child: CustomPaint(
    painter: ParallaxPainter(animationValue: _controller.value),
    size: Size.infinite,
  ),
)
```

### 2. 避免不必要的重建

```dart
// 使用 AnimatedBuilder 而非 setState
AnimatedBuilder(
  animation: _controller,
  // child 不会随动画变化而重建
  child: const ExpensiveWidget(),
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(0, _controller.value * 100),
      child: child, // 复用 child
    );
  },
)
```

### 3. 合理使用 shouldRepaint

```dart
@override
bool shouldRepaint(covariant ParallaxPainter oldDelegate) {
  // 只在动画值变化时重绘
  return oldDelegate.animationValue != animationValue;
}
```

### 4. 页面不可见时暂停

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _parallaxController.stop();
  } else if (state == AppLifecycleState.resumed) {
    _parallaxController.repeat();
  }
}
```

---

## 9.7 最佳实践总结

### 动画编排原则

1. **有节奏**：不要所有动画同时开始，使用交错为页面注入节奏感
2. **有重点**：核心元素的动画应该最突出
3. **有关联**：相关元素的动画应该有视觉上的联系
4. **可打断**：用户操作时，动画应该能平滑地过渡到新状态

### 代码组织

```
lib/
├── ch09_animation_practice.dart   # 主文件入口
```

将所有组件组织在一个文件中，清晰分层：
- 数据模型和枚举
- 各个动画组件（视差背景、天气图标、温度滚动、交错动画）
- 主页面整合

### 调试技巧

- 使用 `timeDilation` 放慢动画便于调试
- Flutter DevTools 的 Timeline 查看动画性能
- 使用 `debugPrint` 在动画回调中输出状态

```dart
import 'package:flutter/scheduler.dart';
// 放慢动画 5 倍
timeDilation = 5.0;
```

---

## 9.8 本章示例代码

示例代码文件：`lib/ch09_animation_practice.dart`

实现完整的天气动效页面，包含：
- 视差滚动背景（CustomPainter + AnimationController）
- 天气图标动画切换（AnimatedSwitcher + 组合动画）
- 温度数字滚动（TweenAnimationBuilder）
- 入场交错动画（Interval + 多动画编排）
- 天气类型切换（底部选择器）

运行方式：
```bash
flutter run -t lib/ch09_animation_practice.dart
```
