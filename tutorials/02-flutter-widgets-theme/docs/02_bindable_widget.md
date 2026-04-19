# 第2章 — StatefulWidget 与交互控件

> 上一章我们学习了 StatelessWidget——它适用于纯展示的控件。但真实应用中，用户会点击、输入、滑动，控件需要响应这些交互并更新 UI。本章我们将深入 StatefulWidget 的机制，理解 State 生命周期，并构建一个带动画的 CounterButton 交互控件。

---

## 2.1 StatefulWidget 与 State 的关系

### Widget 不可变，State 持有可变状态

Flutter 的核心设计理念是 **Widget 是不可变的配置描述**。那可变的状态放在哪里？答案是 `State` 对象。

```dart
class CounterButton extends StatefulWidget {
  final int initialValue;  // Widget 的配置参数，不可变
  const CounterButton({super.key, this.initialValue = 0});

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  late int _count;  // State 持有的可变状态

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
  }
}
```

这个分离设计有深刻的原因：
- **Widget** 描述"应该长什么样"，可以频繁重建（每帧都可能重建）
- **State** 持有"当前是什么状态"，生命周期更长，不会因为 Widget 重建而丢失

### createState() 的调用时机

`createState()` 在 Flutter 框架将 Widget 挂载到 Element 树时被调用——通常是 **第一次构建** 的时候。它只会被调用 **一次**（除非 Widget 被移出树又重新挂入）。

### Widget 重建时 State 是否重建？

**不会！** 这是 StatefulWidget 最核心的特性。当父 Widget 重建导致 `CounterButton` 被新实例替换时：

1. Flutter 比较新旧 Widget 的 `runtimeType` 和 `key`
2. 如果匹配，**复用已有的 State 对象**，只调用 `didUpdateWidget`
3. 如果不匹配，销毁旧 State，创建新 State

这就是为什么 `_count` 的值在父 Widget 重建后依然保留——State 被 Element 持有，不随 Widget 重建而销毁。

```
Widget 树重建:
  旧 CounterButton(initialValue: 0)  →  新 CounterButton(initialValue: 0)
  旧 _CounterButtonState(_count=5)   →  复用！_count 还是 5
```

---

## 2.2 State 生命周期

### 完整生命周期

```
createState()
     ↓
initState()           ← 初始化，只调一次
     ↓
didChangeDependencies() ← InheritedWidget 变化时也会调
     ↓
build()               ← 构建 UI，可能多次调用
     ↓
didUpdateWidget()     ← 父 Widget 重建，传入新 Widget
     ↓
build()               ← 重新构建
     ↓
  ... (多次 build/didUpdateWidget 循环)
     ↓
deactivate()          ← 从树中移除（可能稍后重新插入）
     ↓
dispose()             ← 永久销毁，释放资源
```

### 每个方法的用途

**`initState()`**
- 初始化 State 的字段
- 创建 AnimationController、ScrollController 等
- 订阅 Stream
- ⚠️ 不能在这里调用 `context` 相关方法（如 `Theme.of(context)`），因为此时 `didChangeDependencies` 还没被调用，依赖关系尚未建立

```dart
@override
void initState() {
  super.initState(); // 必须先调用 super
  _count = widget.initialValue;
  _controller = AnimationController(vsync: this);
}
```

**`didChangeDependencies()`**
- 当 State 依赖的 InheritedWidget 发生变化时调用
- 第一次 `initState()` 之后也会调用一次
- 适合做依赖 `context` 的初始化（如获取主题、MediaQuery 等）

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // 安全地使用 context
  _primaryColor = Theme.of(context).colorScheme.primary;
}
```

**`build()`**
- 构建 Widget 子树
- 可能被 **频繁调用**（每次 `setState`、每次父 Widget 重建）
- ⚠️ 不要在 build 中做耗时操作

**`didUpdateWidget(oldWidget)`**
- 父 Widget 重建后，如果 Flutter 复用了这个 State，就会调用此方法
- 可以比较新旧 Widget 的参数，决定是否需要更新状态
- 典型场景：外部传入的 `initialValue` 变了，需要重新初始化

```dart
@override
void didUpdateWidget(CounterButton oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.initialValue != oldWidget.initialValue) {
    _count = widget.initialValue; // 外部参数变了，更新内部状态
  }
}
```

**`dispose()`**
- 释放资源：取消 Timer、关闭 Stream 订阅、dispose AnimationController
- ⚠️ 忘记 dispose 会导致内存泄漏

```dart
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  super.dispose(); // 最后调用 super
}
```

### 常见错误

```dart
// ❌ 错误：在 initState 里调用 context 相关方法
@override
void initState() {
  super.initState();
  // 此时 InheritedWidget 还没建立依赖关系
  final theme = Theme.of(context); // 可能出错或得到错误结果
}

// ✅ 正确：在 didChangeDependencies 或 build 中调用
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final theme = Theme.of(context); // 安全
}
```

---

## 2.3 状态管理入门

### setState 的工作原理

`setState` 并不是"立即重建 UI"。它的工作流程是：

1. 执行传入的回调函数，修改状态变量
2. 将当前 Element 标记为 **dirty**（脏）
3. 在 **下一帧** 的构建阶段，Flutter 重新调用 `build` 方法

```dart
void _increment() {
  setState(() {
    _count++;  // 1. 修改状态
  });
  // 2. Element 被标记为 dirty
  // 3. 下一帧才会重新 build
  print(_count); // 值已经变了，但 UI 还没更新
}
```

这意味着 `setState` 是同步的（回调立即执行），但 UI 更新是异步的（下一帧才发生）。

### 异步操作与 mounted 检查

在异步操作（如网络请求）完成后调用 `setState` 时，State 可能已经被 dispose 了。这会导致错误：

```dart
// ❌ 危险：异步操作完成时 Widget 可能已经不在树中
void _loadData() async {
  final data = await fetchFromServer();
  setState(() {
    _data = data;  // 如果此时 State 已被 dispose，会报错
  });
}

// ✅ 安全：先检查 mounted
void _loadData() async {
  final data = await fetchFromServer();
  if (!mounted) return;  // State 已被销毁，直接返回
  setState(() {
    _data = data;
  });
}
```

### ValueNotifier + ValueListenableBuilder

对于简单的状态管理场景，`ValueNotifier` 是一个轻量级的替代方案，不需要引入第三方包：

```dart
class _MyPageState extends State<MyPage> {
  // ValueNotifier 持有一个值，值变化时通知监听者
  final _counter = ValueNotifier<int>(0);

  @override
  void dispose() {
    _counter.dispose(); // 别忘了释放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ValueListenableBuilder 只在 _counter 值变化时重建
        // 其他部分的 Widget 不会被影响
        ValueListenableBuilder<int>(
          valueListenable: _counter,
          builder: (context, value, child) {
            return Text('计数: $value');
          },
        ),
        ElevatedButton(
          onPressed: () => _counter.value++, // 不需要 setState
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

`ValueListenableBuilder` 的好处是 **精确重建**——只有监听对应 `ValueNotifier` 的部分会重建，而不是整个 `build` 方法重新执行。在大型页面中，这可以显著提升性能。

---

## 2.4 控件通信模式

在 Flutter 中，控件之间的通信有几种典型模式：

### 回调函数（子 → 父）

最基本的通信方式。子控件通过构造函数接收回调，在事件发生时调用：

```dart
// 子控件
class CounterButton extends StatefulWidget {
  final ValueChanged<int>? onChanged;  // 回调
  // ...
}

// 父控件
CounterButton(
  onChanged: (newValue) {
    setState(() {
      _totalCount = newValue;
    });
  },
)
```

这种模式简单直接，适合直接父子关系的通信。

### InheritedWidget（祖先 → 后代）

当数据需要从祖先传递给深层嵌套的后代时，一层层传回调会很痛苦（"prop drilling"）。`InheritedWidget` 允许后代直接从祖先获取数据：

```dart
// 定义一个 InheritedWidget
class AppConfig extends InheritedWidget {
  final String apiBaseUrl;

  const AppConfig({
    super.key,
    required this.apiBaseUrl,
    required super.child,
  });

  // 便捷方法：后代通过它获取数据
  static AppConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>()!;
  }

  @override
  bool updateShouldNotify(AppConfig oldWidget) {
    return apiBaseUrl != oldWidget.apiBaseUrl;
  }
}

// 后代直接获取，不需要一层层传递
final apiUrl = AppConfig.of(context).apiBaseUrl;
```

`Theme.of(context)`、`MediaQuery.of(context)` 都是 InheritedWidget 的应用。

### Provider / Riverpod

对于更复杂的状态管理需求，社区有成熟的方案：

- **Provider**：基于 InheritedWidget 的封装，使用简单，官方推荐
- **Riverpod**：Provider 的进化版，编译期安全，不依赖 BuildContext

这些方案超出了本章范围，我们将在后续章节详细介绍。

---

## 2.5 示例：CounterButton 交互控件

### 需求描述

构建一个圆形计数按钮：
- 显示当前数值
- **点击** +1
- **长按** 重置为 0
- 数字变化时有 **滑入动画**（AnimatedSwitcher + SlideTransition）
- 带涟漪效果
- 支持自定义颜色和大小

### 完整代码

```dart
import 'package:flutter/material.dart';

/// 计数器按钮控件
///
/// 圆形按钮，中间显示数字。
/// 点击 +1，长按重置为 0，数字切换有动画效果。
class CounterButton extends StatefulWidget {
  /// 初始计数值
  final int initialValue;

  /// 计数值变化时的回调
  final ValueChanged<int>? onChanged;

  /// 按钮主色调
  final Color? color;

  /// 按钮直径
  final double size;

  const CounterButton({
    super.key,
    this.initialValue = 0,
    this.onChanged,
    this.color,
    this.size = 72,
  });

  @override
  State<CounterButton> createState() => CounterButtonState();
}

class CounterButtonState extends State<CounterButton> {
  late int _count;

  /// 外部可读取当前计数值
  int get count => _count;

  /// 外部可调用重置方法
  void reset() {
    setState(() {
      _count = 0;
    });
    widget.onChanged?.call(_count);
  }

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;  // 用 Widget 的参数初始化 State
  }

  void _increment() {
    setState(() {
      _count++;
    });
    widget.onChanged?.call(_count);
  }

  void _resetToZero() {
    setState(() {
      _count = 0;
    });
    widget.onChanged?.call(_count);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    return GestureDetector(
      onLongPress: _resetToZero,  // 长按重置
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _increment,  // 点击 +1
          borderRadius: BorderRadius.circular(widget.size / 2),
          splashColor: effectiveColor.withValues(alpha: 0.3),  // 涟漪颜色
          child: Ink(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveColor,
                  effectiveColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // AnimatedSwitcher：当 child 的 key 变化时，
              // 自动对旧 child 执行退出动画，对新 child 执行进入动画
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5), // 从下方滑入
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$_count',
                  // ValueKey 让 AnimatedSwitcher 知道"这是不同的内容"
                  key: ValueKey<int>(_count),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 逐行解析

| 关键点 | 说明 |
|-------|------|
| `State` 类公开为 `CounterButtonState` | 允许外部通过 GlobalKey 调用 `reset()` |
| `widget.initialValue` | 在 State 中通过 `widget` 属性访问 Widget 的参数 |
| `widget.onChanged?.call(_count)` | 安全调用可空回调，通知父组件 |
| `GestureDetector + InkWell` | 双层手势：GestureDetector 处理长按，InkWell 处理点击并提供涟漪 |
| `AnimatedSwitcher` | 核心动画组件，检测 child 的 key 变化时触发过渡动画 |
| `ValueKey<int>(_count)` | 告诉 AnimatedSwitcher "当 _count 变化时，这是一个新的 child" |
| `SlideTransition + FadeTransition` | 组合两种动画：滑动 + 淡入淡出 |
| `Curves.easeOutCubic` | 缓动曲线，让动画更自然 |

### AnimatedSwitcher 原理

`AnimatedSwitcher` 的工作方式非常巧妙：

1. 它检测 `child` 的 **Key** 是否变化
2. 如果变化了，用 `transitionBuilder` 中定义的动画对旧 child 执行 **反向动画**（淡出/滑出）
3. 同时对新 child 执行 **正向动画**（淡入/滑入）
4. 旧 child 动画结束后被移除

这就是为什么 `ValueKey<int>(_count)` 如此重要——没有它，AnimatedSwitcher 无法区分新旧 child。

---

## 2.6 小结

本章我们深入了解了 StatefulWidget 的工作机制：

1. **Widget 与 State 的分离**：Widget 是不可变配置，State 持有可变状态。Widget 可以频繁重建，State 被 Element 持有，生命周期更长。

2. **State 生命周期**：`initState` → `didChangeDependencies` → `build` → `didUpdateWidget` → `dispose`。每个方法有明确用途和注意事项。

3. **setState 机制**：标记 dirty → 下一帧重建。异步操作后记得检查 `mounted`。`ValueNotifier` + `ValueListenableBuilder` 提供精确重建能力。

4. **控件通信**：回调函数（子→父）、InheritedWidget（祖先→后代），以及社区方案 Provider/Riverpod。

5. **实战技巧**：通过 CounterButton 学习了 AnimatedSwitcher 动画、GestureDetector 手势处理、GlobalKey 跨组件调用等实用技术。

下一章，我们将学习如何使用 Flutter 的主题系统来统一管理应用的视觉风格。

> 📌 **练习**：为 CounterButton 添加"步长"参数 `step`，支持每次点击 +N。思考：`step` 变化时，是否需要在 `didUpdateWidget` 中做处理？（提示：不需要，因为 `step` 只在点击时读取，不影响当前状态。）
