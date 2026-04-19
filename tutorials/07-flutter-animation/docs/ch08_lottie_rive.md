# 第8章：Lottie 与 Rive

## 概述

在实际开发中，复杂的动画效果往往由设计师使用专业工具制作，然后在应用中播放。**Lottie** 和 **Rive** 是目前 Flutter 生态中最流行的两种外部动画方案。本章将详细讲解这两个工具的原理、用法和最佳实践，并通过纯 Flutter 代码模拟动画控制逻辑。

---

## 8.1 Lottie 简介

### 什么是 Lottie

Lottie 是 Airbnb 开源的动画库，可以在移动端和 Web 端渲染 **Adobe After Effects** 导出的动画。设计师使用 After Effects 制作动画，通过 **Bodymovin** 插件导出为 JSON 格式，然后在各平台上原生渲染。

### 工作流程

```
After Effects 动画 → Bodymovin 插件 → JSON 文件 → Lottie 库渲染
```

### 优势

- **体积小**：JSON 格式比 GIF/视频小很多
- **无损缩放**：基于矢量的动画，任意缩放不失真
- **跨平台**：iOS、Android、Web、Flutter 都支持
- **设计师友好**：设计师使用熟悉的 AE 工作流

### Flutter 中使用 Lottie

#### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.3.1
```

#### 2. 添加动画文件

将 `.json` 动画文件放在 `assets/` 目录下，并在 `pubspec.yaml` 中声明：

```yaml
flutter:
  assets:
    - assets/animations/
```

#### 3. 基本用法

```dart
import 'package:lottie/lottie.dart';

// 最简单的用法：自动播放
Lottie.asset('assets/animations/loading.json')

// 从网络加载
Lottie.network('https://example.com/animation.json')

// 设置尺寸和循环
Lottie.asset(
  'assets/animations/loading.json',
  width: 200,
  height: 200,
  repeat: true,
  animate: true,
)
```

#### 4. 使用 AnimationController 控制播放

```dart
class _LottieExampleState extends State<LottieExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/star.json',
          controller: _controller,
          // 动画加载完成后获取实际时长
          onLoaded: (composition) {
            _controller.duration = composition.duration;
          },
        ),
        Row(
          children: [
            // 播放
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _controller.forward(),
            ),
            // 暂停
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _controller.stop(),
            ),
            // 循环
            IconButton(
              icon: const Icon(Icons.repeat),
              onPressed: () => _controller.repeat(),
            ),
            // 反向播放
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => _controller.reverse(),
            ),
          ],
        ),
      ],
    );
  }
}
```

#### 5. 控制播放范围

```dart
// 只播放前半段
_controller.forward(from: 0.0);
_controller.animateTo(0.5);

// 播放指定帧范围
Lottie.asset(
  'assets/animations/progress.json',
  controller: _controller,
  // 使用 delegates 可以动态修改动画属性
)
```

#### 6. Lottie Delegates（动态修改动画属性）

```dart
Lottie.asset(
  'assets/animations/icon.json',
  delegates: LottieDelegates(
    values: [
      // 动态修改颜色
      ValueDelegate.color(
        const ['Layer 1', '**'],
        value: Colors.red,
      ),
      // 动态修改透明度
      ValueDelegate.opacity(
        const ['Layer 2', '**'],
        value: 50,
      ),
    ],
  ),
)
```

### Lottie 资源获取

- **LottieFiles**：https://lottiefiles.com — 最大的 Lottie 动画社区
- **IconScout**：https://iconscout.com/lottie-animations
- **自制**：使用 Adobe After Effects + Bodymovin 插件

---

## 8.2 Rive 简介

### 什么是 Rive

Rive（原名 Flare）是一个实时交互式动画工具。与 Lottie 不同，Rive 有自己的在线编辑器，并且原生支持**状态机（State Machine）**，可以根据用户输入实时改变动画状态。

### Rive vs Lottie

| 特性 | Lottie | Rive |
|------|--------|------|
| 制作工具 | Adobe After Effects | Rive Editor（在线） |
| 文件格式 | JSON | .riv（二进制） |
| 交互性 | 有限，需代码控制 | 原生状态机支持 |
| 文件体积 | 较小 | 极小 |
| 学习曲线 | 需要 AE 经验 | 独立工具，入门简单 |
| 实时交互 | 需手动实现 | 内置状态机 |
| 渲染性能 | 好 | 极好（自定义渲染引擎）|

### Flutter 中使用 Rive

#### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  rive: ^0.13.22
```

#### 2. 基本用法

```dart
import 'package:rive/rive.dart';

// 简单播放
const RiveAnimation.asset('assets/animations/truck.riv')

// 指定 artboard 和动画
RiveAnimation.asset(
  'assets/animations/truck.riv',
  artboard: 'Main',           // 指定画板
  animations: ['idle'],        // 指定播放的动画
  fit: BoxFit.contain,
)
```

#### 3. 使用状态机控制

Rive 的核心特色是状态机。状态机由以下部分组成：

- **State Machine**：一组状态和转换规则
- **Input**：触发状态转换的输入（布尔、数字、触发器）
- **State**：动画状态（如 idle、hover、pressed）

```dart
class _RiveStateMachineState extends State<RiveStateMachine> {
  // 状态机控制器
  StateMachineController? _controller;
  // 输入
  SMIBool? _isHovered;
  SMITrigger? _pressed;
  SMINumber? _level;

  void _onRiveInit(Artboard artboard) {
    // 获取状态机
    _controller = StateMachineController.fromArtboard(
      artboard,
      'ButtonStateMachine', // 状态机名称
    );
    if (_controller != null) {
      artboard.addController(_controller!);
      // 获取输入
      _isHovered = _controller!.findInput<bool>('isHovered') as SMIBool?;
      _pressed = _controller!.findInput<bool>('pressed') as SMITrigger?;
      _level = _controller!.findInput<double>('level') as SMINumber?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered?.value = true,
      onExit: (_) => _isHovered?.value = false,
      child: GestureDetector(
        onTap: () => _pressed?.fire(),
        child: RiveAnimation.asset(
          'assets/button.riv',
          onInit: _onRiveInit,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
```

#### 4. 动态控制动画

```dart
// SimpleAnimation 控制器
class _RiveControllerState extends State<RiveController> {
  late RiveAnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation('idle');
  }

  void _toggleAnimation() {
    setState(() {
      _controller.isActive = !_controller.isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      'assets/truck.riv',
      controllers: [_controller],
    );
  }
}
```

#### 5. OneShotAnimation（一次性动画）

```dart
// 播放一次后停止的动画
final _controller = OneShotAnimation(
  'bounce',
  autoplay: false,
  onStop: () => print('动画播放完毕'),
);

// 触发播放
_controller.isActive = true;
```

---

## 8.3 动画控制模式详解

无论使用 Lottie 还是 Rive，动画控制都遵循类似的模式。以下是使用 Flutter 原生 AnimationController 模拟的控制逻辑。

### 播放/暂停/停止

```dart
class AnimationControlDemo extends StatefulWidget {
  @override
  State<AnimationControlDemo> createState() => _AnimationControlDemoState();
}

class _AnimationControlDemoState extends State<AnimationControlDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // 监听动画状态
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlaying = false);
      }
    });
  }

  // 播放
  void _play() {
    _controller.forward();
    setState(() => _isPlaying = true);
  }

  // 暂停
  void _pause() {
    _controller.stop();
    setState(() => _isPlaying = false);
  }

  // 重置
  void _reset() {
    _controller.reset();
    setState(() => _isPlaying = false);
  }

  // 循环播放
  void _loop() {
    _controller.repeat();
    setState(() => _isPlaying = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 进度控制（Scrubbing）

```dart
// 使用 Slider 手动控制动画进度
Slider(
  value: _controller.value,
  onChanged: (value) {
    _controller.value = value; // 直接设置进度
  },
)
```

### 速度控制

```dart
// 调整动画速度
void _setSpeed(double speed) {
  final currentValue = _controller.value;
  _controller.duration = Duration(
    milliseconds: (3000 / speed).round(),
  );
  // 如果正在播放，从当前位置继续
  if (_isPlaying) {
    _controller.forward(from: currentValue);
  }
}
```

---

## 8.4 Lottie 进阶技巧

### 1. 预加载动画

```dart
// 在应用启动时预加载，避免首次播放卡顿
late final Future<LottieComposition> _composition;

@override
void initState() {
  super.initState();
  _composition = AssetLottie('assets/heavy_animation.json').load();
}

@override
Widget build(BuildContext context) {
  return FutureBuilder<LottieComposition>(
    future: _composition,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Lottie(composition: snapshot.data!);
      }
      return const CircularProgressIndicator();
    },
  );
}
```

### 2. 缓存策略

```dart
// Lottie 默认会缓存已加载的动画
// 可以通过 LottieCache 管理
Lottie.asset(
  'assets/anim.json',
  // 每次创建新的解码器（不使用缓存）
  addRepaintBoundary: true,
)
```

### 3. 帧对齐

```dart
// 确保动画帧与帧率对齐
Lottie.asset(
  'assets/anim.json',
  frameRate: FrameRate.max, // 使用设备最大帧率
  // 或者指定帧率
  // frameRate: const FrameRate(30),
)
```

---

## 8.5 Rive 进阶技巧

### 1. 多个动画混合

```dart
RiveAnimation.asset(
  'assets/character.riv',
  animations: ['idle', 'blink'], // 同时播放多个动画
)
```

### 2. 嵌套 Artboard

Rive 支持在一个 `.riv` 文件中包含多个 Artboard，可以根据需要切换：

```dart
RiveAnimation.asset(
  'assets/icons.riv',
  artboard: 'HomeIcon',  // 切换不同的画板
)
```

### 3. 文本运行时修改

```dart
void _onRiveInit(Artboard artboard) {
  final controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
  artboard.addController(controller!);
  // Rive 支持运行时修改文本
  final textRun = artboard.component<TextValueRun>('username');
  textRun?.text = 'Hello, World!';
}
```

---

## 8.6 选择 Lottie 还是 Rive

### 推荐使用 Lottie 的场景

- 团队已有 After Effects 工作流
- 需要大量免费动画资源（LottieFiles 社区）
- 简单的装饰性动画（加载、成功/失败提示等）
- 需要跨多个平台（Web、React Native 等）

### 推荐使用 Rive 的场景

- 需要交互式动画（按钮状态、表情响应等）
- 追求极致性能和极小文件体积
- 设计师愿意学习新工具
- 需要复杂的状态机逻辑（游戏角色、交互组件等）

### 实际建议

```
简单装饰动画 → Lottie（资源丰富，上手快）
交互式动画 → Rive（状态机强大，性能好）
性能敏感场景 → Rive（自定义渲染引擎）
团队已有 AE 流程 → Lottie（无需改变工作流）
```

---

## 8.7 最佳实践

### 1. 资源管理

- 压缩 Lottie JSON 文件（移除不必要的空格和注释）
- Rive 文件已经是二进制格式，天然紧凑
- 考虑延迟加载不常用的动画资源

### 2. 性能优化

- 使用 `addRepaintBoundary: true` 隔离重绘区域
- 避免在列表中大量使用复杂动画
- 页面不可见时暂停动画（配合 `WidgetsBindingObserver`）

### 3. 错误处理

```dart
// Lottie 错误处理
Lottie.asset(
  'assets/anim.json',
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
)
```

### 4. 无障碍

- 为动画添加语义描述
- 尊重系统的"减少动画"设置

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
if (reduceMotion) {
  return const StaticWidget(); // 显示静态替代内容
} else {
  return Lottie.asset('assets/fancy_animation.json');
}
```

---

## 8.8 本章示例代码

示例代码文件：`lib/ch08_lottie_rive.dart`

由于示例代码不依赖实际的 Lottie/Rive 资源文件，我们使用纯 Flutter 的 `AnimationController` 来模拟动画控制逻辑，演示：

1. **模拟 Lottie 播放器**：使用 AnimationController 驱动自定义绘制，模拟 Lottie 动画的播放/暂停/进度控制
2. **模拟 Rive 状态机**：使用状态管理模拟 Rive 的状态机输入和状态切换
3. **速度控制**：演示如何调整动画播放速度

运行方式：
```bash
flutter run -t lib/ch08_lottie_rive.dart
```
