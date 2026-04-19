# 第二章：Flutter 原生状态管理方案

> 在引入第三方状态管理库之前，Flutter 框架自身已经提供了一套完整且强大的状态管理工具链。
> 理解这些原生方案是掌握 Flutter 响应式编程的基石。

📄 **示例代码**: [`lib/ch02_native_state.dart`](../lib/ch02_native_state.dart)

---

## 目录

1. [setState 的工作原理](#1-setstate-的工作原理)
2. [InheritedWidget 详解](#2-inheritedwidget-详解)
3. [InheritedNotifier 的用法和优势](#3-inheritednotifier-的用法和优势)
4. [ValueNotifier + ValueListenableBuilder](#4-valuenotifier--valuelistenablebuilder)
5. [ChangeNotifier + ListenableBuilder](#5-changenotifier--listenablebuilder)
6. [各方案的适用场景对比](#6-各方案的适用场景对比)
7. [最佳实践总结](#7-最佳实践总结)

---

## 1. setState 的工作原理

### 1.1 基本用法

`setState` 是 Flutter 中最基础的状态管理方式，它属于 `State<T>` 类的方法：

```dart
class _MyWidgetState extends State<MyWidget> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_counter');
  }
}
```

### 1.2 完整工作流程：标记 dirty → rebuild

当你调用 `setState()` 时，Flutter 内部执行以下步骤：

```
setState() 调用
    │
    ▼
执行传入的回调函数（修改状态变量）
    │
    ▼
调用 _element!.markNeedsBuild()
    │
    ▼
将当前 Element 标记为 "dirty"（脏元素）
    │
    ▼
将该 Element 加入 BuildOwner 的 _dirtyElements 列表
    │
    ▼
请求新的一帧（SchedulerBinding.instance.scheduleFrame()）
    │
    ▼
在下一帧的 build 阶段：
    - BuildOwner.buildScope() 遍历 _dirtyElements
    - 按深度排序，从上到下 rebuild
    - 调用 Element.rebuild() → performRebuild()
    - 最终调用 State.build(context) 生成新的 Widget 树
    │
    ▼
对比新旧 Widget 树（canUpdate 判断）
    - 类型相同 & key 相同 → 更新 Element
    - 否则 → 卸载旧 Element，创建新 Element
    │
    ▼
渲染阶段：将变化的部分提交到 RenderObject 树进行布局和绘制
```

### 1.3 源码分析

```dart
// framework.dart 中 State.setState 的简化实现
@protected
void setState(VoidCallback fn) {
  // 断言检查：不能在 dispose 之后调用
  assert(_debugLifecycleState != _StateLifecycle.defunct);
  // 执行回调
  final Object? result = fn() as dynamic;
  // 断言：回调不能返回 Future
  assert(() {
    if (result is Future) {
      throw FlutterError.fromParts(<DiagnosticsNode>[...]);
    }
    return true;
  }());
  // 核心：标记当前 Element 需要重建
  _element!.markNeedsBuild();
}
```

### 1.4 注意事项

| 要点 | 说明 |
|------|------|
| **回调同步执行** | `setState` 中的回调必须是同步的，不能是 `async` |
| **合并更新** | 同一帧内多次 `setState` 只会触发一次 rebuild |
| **作用范围** | 只会重建当前 `StatefulWidget`，不会影响父级 |
| **空回调也会触发** | `setState(() {})` 也会标记 dirty 并触发 rebuild |
| **生命周期限制** | 不能在 `dispose` 之后调用，不能在 `build` 中调用 |

### 1.5 setState 的局限性

- **状态无法跨组件共享**：只能管理当前 Widget 内部的状态
- **props drilling**：跨层级传递状态需要一层层向下传参
- **重建范围过大**：会重建整个 `build()` 方法返回的子树
- **逻辑与 UI 耦合**：业务逻辑和 UI 代码混在一起

---

## 2. InheritedWidget 详解

### 2.1 概述

`InheritedWidget` 是 Flutter 中**跨组件共享数据**的核心机制。`Theme.of(context)`、`MediaQuery.of(context)` 等框架 API 底层都依赖它。

### 2.2 核心原理

```
Widget 树结构：

InheritedWidget（持有共享数据）
    │
    ├── ChildA
    │       └── GrandChildA（通过 context 访问数据）
    │
    └── ChildB
            └── GrandChildB（通过 context 访问数据）
```

**关键机制**：

1. **数据存储**：`InheritedWidget` 本身是不可变的（immutable），数据存储在其字段中
2. **数据获取**：子孙 Widget 通过 `context.dependOnInheritedWidgetOfExactType<T>()` 获取
3. **依赖注册**：调用上述方法时，当前 Element 会自动注册为该 `InheritedWidget` 的依赖者
4. **更新通知**：当 `InheritedWidget` 重建时，通过 `updateShouldNotify` 判断是否需要通知依赖者
5. **精确重建**：只有注册过依赖关系的 Element 才会被标记为 dirty 并重建

### 2.3 生命周期

```
InheritedElement 生命周期：

1. mount() 
   - 创建 InheritedElement
   - 将自身注册到 _inheritedWidgets Map 中
   
2. update(newWidget)
   - 用新的 InheritedWidget 替换旧的
   - 调用 updateShouldNotify(oldWidget) 判断数据是否变化
   - 如果返回 true → 通知所有依赖者（调用 didChangeDependencies）
   
3. notifyClients()
   - 遍历 _dependents Map
   - 对每个依赖的 Element 调用 didChangeDependencies()
   - 被通知的 Element 会标记为 dirty，等待下一帧 rebuild

4. unmount()
   - 从 _inheritedWidgets 中移除自身
   - 清理依赖关系
```

### 2.4 updateShouldNotify 详解

```dart
class MyInheritedWidget extends InheritedWidget {
  final int value;

  const MyInheritedWidget({
    super.key,
    required this.value,
    required super.child,
  });

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) {
    // 返回 true：通知所有依赖者重建
    // 返回 false：即使 InheritedWidget 本身重建了，也不通知依赖者
    return value != oldWidget.value;
  }
}
```

**重要**：`updateShouldNotify` 控制的是**是否通知依赖者**，而不是 InheritedWidget 自身是否重建。

### 2.5 dependOnInheritedWidgetOfExactType vs getInheritedWidgetOfExactType

```dart
// ✅ 建立依赖关系，数据变化时会自动 rebuild
final widget = context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();

// ⚠️ 只读取数据，不建立依赖关系，数据变化时不会自动 rebuild
final widget = context.getInheritedWidgetOfExactType<MyInheritedWidget>();
```

### 2.6 手写主题切换示例

在示例代码 `lib/ch02_native_state.dart` 中，我们实现了一个完整的 `ThemeSettingsWidget`：

```dart
/// 自定义 InheritedWidget，用于在组件树中共享主题配置
class ThemeSettingsWidget extends InheritedWidget {
  final bool isDarkMode;
  final Color primaryColor;
  final double fontSize;

  const ThemeSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.primaryColor,
    required this.fontSize,
    required super.child,
  });

  /// 便捷方法：从上下文中获取最近的 ThemeSettingsWidget
  static ThemeSettingsWidget of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ThemeSettingsWidget>();
    assert(widget != null, '未找到 ThemeSettingsWidget，请确保在组件树上层提供');
    return widget!;
  }

  @override
  bool updateShouldNotify(ThemeSettingsWidget oldWidget) {
    // 任一属性变化都需要通知依赖者
    return isDarkMode != oldWidget.isDarkMode ||
        primaryColor != oldWidget.primaryColor ||
        fontSize != oldWidget.fontSize;
  }
}
```

**使用方式**：

```dart
// 在组件树顶部提供
ThemeSettingsWidget(
  isDarkMode: _isDarkMode,
  primaryColor: _primaryColor,
  fontSize: _fontSize,
  child: MaterialApp(...),
)

// 在任意子组件中消费
Widget build(BuildContext context) {
  final theme = ThemeSettingsWidget.of(context);
  return Container(
    color: theme.isDarkMode ? Colors.grey[900] : Colors.white,
    child: Text(
      'Hello',
      style: TextStyle(fontSize: theme.fontSize),
    ),
  );
}
```

---

## 3. InheritedNotifier 的用法和优势

### 3.1 概述

`InheritedNotifier` 是 `InheritedWidget` 的子类，它接受一个 `Listenable`（通常是 `ChangeNotifier` 或 `ValueNotifier`），并在该 `Listenable` 发出通知时**自动更新依赖者**。

### 3.2 与 InheritedWidget 的区别

| 特性 | InheritedWidget | InheritedNotifier |
|------|----------------|-------------------|
| 更新触发 | 需要父级 `setState` 重建 | `Listenable` 通知自动触发 |
| updateShouldNotify | 需要手动实现 | 自动处理（Listenable 通知即更新） |
| 数据源 | 存储在 Widget 字段中 | 存储在 Notifier 中 |
| 适用场景 | 静态或不频繁变化的数据 | 频繁变化的响应式数据 |

### 3.3 代码示例

```dart
class CounterNotifier extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}

/// InheritedNotifier 会在 notifier 发出通知时自动更新依赖者
class CounterProvider extends InheritedNotifier<CounterNotifier> {
  const CounterProvider({
    super.key,
    required CounterNotifier super.notifier,
    required super.child,
  });

  static CounterNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CounterProvider>()!
        .notifier!;
  }
}

// 使用
CounterProvider(
  notifier: counterNotifier,
  child: Builder(
    builder: (context) {
      final counter = CounterProvider.of(context);
      return Text('Count: ${counter.count}');
    },
  ),
)
```

### 3.4 优势

1. **无需手动 `setState`**：Notifier 变化自动触发 UI 更新
2. **关注点分离**：状态逻辑封装在 Notifier 中，与 UI 解耦
3. **自动清理**：`InheritedNotifier` 的 Element 会自动监听/取消监听 Listenable
4. **可测试性**：Notifier 可以独立于 Widget 进行单元测试

---

## 4. ValueNotifier + ValueListenableBuilder

### 4.1 概述

`ValueNotifier<T>` 是 `ChangeNotifier` 的特化版本，专门管理**单一值**。配合 `ValueListenableBuilder` 可以实现**精确的局部重建**。

### 4.2 ValueNotifier 原理

```dart
// ValueNotifier 的简化实现
class ValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  ValueNotifier(this._value);

  @override
  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return; // 值相同时不通知
    _value = newValue;
    notifyListeners(); // 值变化时通知所有监听者
  }
}
```

**特点**：
- 泛型支持，类型安全
- 自带相等性判断，避免不必要的通知
- 继承自 `ChangeNotifier`，拥有完整的监听器管理能力

### 4.3 ValueListenableBuilder 用法

```dart
final ValueNotifier<int> _counter = ValueNotifier<int>(0);

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // 只有 ValueListenableBuilder 内部会 rebuild，外部不受影响
      ValueListenableBuilder<int>(
        valueListenable: _counter,
        builder: (context, value, child) {
          return Text('计数: $value');
        },
        // child 参数：不依赖 value 的子 Widget，不会 rebuild
        child: const Icon(Icons.star),
      ),
      ElevatedButton(
        onPressed: () => _counter.value++,
        child: const Text('增加'),
      ),
    ],
  );
}
```

### 4.4 child 参数优化

`ValueListenableBuilder` 的 `child` 参数是一个重要的性能优化点：

```dart
ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (context, value, child) {
    return Row(
      children: [
        Text('$value'),
        child!, // 这个 child 不会随 value 变化而 rebuild
      ],
    );
  },
  // 复杂的子 Widget 放在这里，只构建一次
  child: const ExpensiveWidget(),
)
```

### 4.5 适用场景

- ✅ 管理单一值（计数器、开关、选中状态等）
- ✅ 需要精确局部重建的场景
- ✅ 简单的表单字段状态
- ❌ 不适合管理复杂的多字段状态
- ❌ 不适合需要业务逻辑的场景

---

## 5. ChangeNotifier + ListenableBuilder

### 5.1 概述

`ChangeNotifier` 是 Flutter 中通用的**可观察对象**基类，可管理多个字段和复杂逻辑。配合 `ListenableBuilder`（Flutter 3.10+）可以实现灵活的状态管理。

> ⚠️ 注意：`AnimatedBuilder` 已被标记为语义不明确的命名。在不涉及动画的场景中，
> 推荐使用 `ListenableBuilder`，它在功能上与 `AnimatedBuilder` 等价但语义更清晰。

### 5.2 ChangeNotifier 详解

```dart
/// 用户信息管理器
class UserProfileNotifier extends ChangeNotifier {
  String _name = '';
  String _email = '';
  bool _isLoading = false;

  String get name => _name;
  String get email => _email;
  bool get isLoading => _isLoading;

  /// 更新用户名
  void updateName(String name) {
    _name = name;
    notifyListeners(); // 通知所有监听者
  }

  /// 异步加载用户信息
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));
    _name = '张三';
    _email = 'zhangsan@example.com';

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
```

### 5.3 ListenableBuilder 用法

```dart
final _profileNotifier = UserProfileNotifier();

@override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: _profileNotifier,
    builder: (context, child) {
      if (_profileNotifier.isLoading) {
        return const CircularProgressIndicator();
      }
      return Column(
        children: [
          Text('姓名: ${_profileNotifier.name}'),
          Text('邮箱: ${_profileNotifier.email}'),
          child!, // 不变的子组件
        ],
      );
    },
    child: ElevatedButton(
      onPressed: _profileNotifier.loadProfile,
      child: const Text('加载'),
    ),
  );
}
```

### 5.4 监听多个 Listenable

使用 `Listenable.merge` 可以同时监听多个 Notifier：

```dart
ListenableBuilder(
  listenable: Listenable.merge([notifierA, notifierB, notifierC]),
  builder: (context, child) {
    // 任何一个 Notifier 变化都会触发 rebuild
    return Text('A: ${notifierA.value}, B: ${notifierB.value}');
  },
)
```

### 5.5 ChangeNotifier vs ValueNotifier

| 特性 | ValueNotifier | ChangeNotifier |
|------|--------------|----------------|
| 数据模型 | 单一值 | 多字段复杂模型 |
| 通知机制 | 值变化自动通知 | 手动调用 `notifyListeners()` |
| 相等性判断 | 内置（`==`） | 需自行实现 |
| 业务逻辑 | 不适合 | 可封装复杂逻辑 |
| 代码量 | 极少 | 适中 |

---

## 6. 各方案的适用场景对比

### 6.1 对比表

| 方案 | 复杂度 | 跨组件共享 | 精确重建 | 适用场景 |
|------|--------|-----------|---------|---------|
| `setState` | ⭐ | ❌ | ❌ | 组件内部简单状态 |
| `InheritedWidget` | ⭐⭐⭐ | ✅ | ✅ | 配置/主题等低频变化的全局数据 |
| `InheritedNotifier` | ⭐⭐⭐ | ✅ | ✅ | 需要响应式更新的共享数据 |
| `ValueNotifier` + `Builder` | ⭐⭐ | ❌* | ✅ | 单一值的局部状态 |
| `ChangeNotifier` + `Builder` | ⭐⭐ | ❌* | ✅ | 复杂模型的局部状态 |

> *可以结合 `InheritedNotifier` 或依赖注入实现跨组件共享

### 6.2 选择流程

```
状态是否只在一个 Widget 内部使用？
    │
    ├── 是 → 状态结构简单？
    │         ├── 是（单个值） → ValueNotifier + ValueListenableBuilder
    │         └── 否（多字段） → ChangeNotifier + ListenableBuilder
    │
    └── 否 → 需要跨组件共享
              │
              ├── 数据变化频率低（主题/语言/配置）
              │   └── InheritedWidget + setState
              │
              ├── 数据变化频率中等
              │   └── InheritedNotifier
              │
              └── 状态逻辑非常复杂
                  └── 考虑第三方方案（Provider / Riverpod / Bloc）
```

### 6.3 性能考量

1. **setState**：重建范围 = 整个 `build()` 返回的子树
2. **ValueListenableBuilder**：重建范围 = builder 函数返回的部分
3. **InheritedWidget**：重建范围 = 所有调用了 `dependOn...` 的子孙 Widget
4. **ListenableBuilder**：重建范围 = builder 函数返回的部分

**性能优化建议**：
- 将 `setState` 的范围缩小到最小的 StatefulWidget
- 善用 `const` 构造函数避免不必要的重建
- `ValueListenableBuilder` 和 `ListenableBuilder` 的 `child` 参数可以避免子树重建
- 拆分大 Widget 为多个小 Widget，每个只监听自己关心的数据

---

## 7. 最佳实践总结

### 7.1 通用原则

1. **从简单开始**：先用 `setState`，只在需要时升级到更复杂的方案
2. **状态就近管理**：状态应该放在需要它的最近的公共祖先
3. **不可变数据**：尽量使用不可变的数据模型
4. **及时释放**：在 `dispose` 中清理 Notifier 和监听器
5. **避免滥用全局状态**：只有真正需要全局共享的数据才放到顶层

### 7.2 常见错误

```dart
// ❌ 错误：在 build 中创建 Notifier
@override
Widget build(BuildContext context) {
  final notifier = ValueNotifier(0); // 每次 build 都创建新的！
  return ValueListenableBuilder(...);
}

// ✅ 正确：在 initState 或字段中创建
final _notifier = ValueNotifier(0);

// ❌ 错误：忘记 dispose
// ✅ 正确：
@override
void dispose() {
  _notifier.dispose();
  super.dispose();
}
```

### 7.3 调试技巧

- 使用 Flutter DevTools 的 **Widget Inspector** 查看 Widget rebuild 次数
- 在 `build` 方法中添加 `debugPrint` 追踪重建
- 使用 `debugRepaintRainbowEnabled = true` 可视化重绘区域
- 使用 `Profile` 模式运行来获取准确的性能数据

---

## 下一章预告

在第三章中，我们将学习 **Provider** —— Flutter 官方推荐的状态管理方案。
Provider 本质上是对 `InheritedWidget` 的封装，理解了本章内容，学习 Provider 将事半功倍。

---

📄 **完整示例代码**: [`lib/ch02_native_state.dart`](../lib/ch02_native_state.dart)

运行方式：
```bash
cd flutter-state
flutter run lib/ch02_native_state.dart
```
