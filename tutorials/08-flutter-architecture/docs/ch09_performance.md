# 第9章：性能优化

## 目录

1. [Flutter 渲染流程](#1-flutter-渲染流程)
2. [const Widget 优化](#2-const-widget-优化)
3. [RepaintBoundary](#3-repaintboundary)
4. [ListView 优化](#4-listview-优化)
5. [图片优化](#5-图片优化)
6. [Isolate 并发](#6-isolate-并发)
7. [构建优化](#7-构建优化)
8. [DevTools 性能分析](#8-devtools-性能分析)
9. [最佳实践清单](#9-最佳实践清单)

---

## 1. Flutter 渲染流程

### 1.1 三棵树

Flutter 使用三棵树来管理 UI：

```
Widget 树                Element 树              RenderObject 树
(配置描述)               (生命周期管理)           (布局 + 绘制)
┌──────────┐           ┌──────────┐           ┌──────────┐
│ MyApp    │  ──────►  │ Element  │  ──────►  │ Render   │
├──────────┤           ├──────────┤           ├──────────┤
│ Scaffold │  ──────►  │ Element  │  ──────►  │ Render   │
├──────────┤           ├──────────┤           ├──────────┤
│ Column   │  ──────►  │ Element  │  ──────►  │ Render   │
├──────────┤           ├──────────┤           ├──────────┤
│ Text     │  ──────►  │ Element  │  ──────►  │ Render   │
└──────────┘           └──────────┘           └──────────┘
```

- **Widget 树**：不可变的配置描述，创建成本低
- **Element 树**：Widget 的实例化，管理生命周期，尽量复用
- **RenderObject 树**：实际执行布局和绘制，成本最高

### 1.2 渲染管线

```
用户输入 / setState
    ↓
Build 阶段  ← Widget 树对比，更新 Element 树
    ↓
Layout 阶段 ← 计算大小和位置（RenderObject）
    ↓
Paint 阶段  ← 生成绘制指令（Layer 树）
    ↓
Composite   ← 合成图层，发送到 GPU
    ↓
Rasterize   ← GPU 渲染到屏幕
```

**目标**：每帧在 16ms 内完成（60fps）或 8ms（120fps）

### 1.3 性能瓶颈在哪

- **Build 阶段**：不必要的 Widget 重建
- **Layout 阶段**：复杂的嵌套布局
- **Paint 阶段**：过大的重绘区域
- **Rasterize 阶段**：复杂的阴影、裁剪、透明度

## 2. const Widget 优化

### 2.1 为什么 const 重要

`const` Widget 在编译期创建，运行时不需要重新分配内存：

```dart
// ❌ 每次 build 都创建新的 Text 对象
Widget build(BuildContext context) {
  return Text('Hello');  // 每次 build 都创建新实例
}

// ✅ 编译期创建，build 时复用同一实例
Widget build(BuildContext context) {
  return const Text('Hello');  // 始终是同一个实例
}
```

### 2.2 const 的连锁效应

当 Widget 是 `const` 时，Flutter 可以直接跳过该子树的重建：

```dart
// 整个子树都不会重建
const Column(
  children: [
    Text('Title'),         // const
    Icon(Icons.star),      // const
    SizedBox(height: 16),  // const
  ],
)
```

### 2.3 何时不能使用 const

```dart
// 以下情况不能使用 const：

// 1. 使用变量
Text(userName)                    // 变量值运行时才知道

// 2. 使用非 const 构造的对象
Container(color: myColor)         // myColor 不是 const

// 3. 调用非 const 方法
Text(DateTime.now().toString())   // 方法返回值不是 const
```

### 2.4 自定义 const Widget

```dart
class MyCard extends StatelessWidget {
  final String title;
  final IconData icon;

  // 添加 const 构造函数
  const MyCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
      ),
    );
  }
}

// 可以用 const 创建
const MyCard(title: 'Settings', icon: Icons.settings)
```

## 3. RepaintBoundary

### 3.1 什么是重绘边界

`RepaintBoundary` 创建一个新的绘制图层，将其子树的绘制与父级隔离：

```dart
// 没有 RepaintBoundary —— 动画导致整个页面重绘
Column(
  children: [
    const HeavyWidget(),       // 被迫重绘 😩
    AnimatedProgressBar(),     // 动画在这里
    const AnotherHeavyWidget(), // 被迫重绘 😩
  ],
)

// 有 RepaintBoundary —— 只重绘动画部分
Column(
  children: [
    const HeavyWidget(),       // 不受影响 ✅
    RepaintBoundary(
      child: AnimatedProgressBar(),  // 只有这里重绘
    ),
    const AnotherHeavyWidget(), // 不受影响 ✅
  ],
)
```

### 3.2 使用场景

```dart
// ✅ 适合使用 RepaintBoundary 的场景：
// 1. 频繁动画的 Widget
RepaintBoundary(child: MyAnimation())

// 2. 列表中的复杂项
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ComplexListItem(data: items[index]),
    );
  },
)

// 3. 静态不变的复杂 Widget
RepaintBoundary(child: ComplexChart())
```

### 3.3 注意事项

- RepaintBoundary 会增加一个图层，有内存开销
- 不要过度使用，只在确实需要隔离重绘时使用
- Flutter 内部已经在很多地方自动添加了 RepaintBoundary

## 4. ListView 优化

### 4.1 懒加载 vs 一次性构建

```dart
// ❌ 一次性构建所有子项 —— 1000 个 Widget 全部创建
ListView(
  children: List.generate(1000, (i) => ListTile(title: Text('Item $i'))),
)

// ✅ 按需构建 —— 只创建可见区域的 Widget
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return ListTile(title: Text('Item $index'));
  },
)
```

### 4.2 itemExtent 固定高度

```dart
// ❌ 不指定高度 —— Flutter 需要逐个测量
ListView.builder(
  itemCount: 10000,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)

// ✅ 指定固定高度 —— 跳过测量，直接计算位置
ListView.builder(
  itemCount: 10000,
  itemExtent: 56.0,  // 每项固定 56 像素
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)

// ✅ 或使用 prototypeItem（Flutter 3.x）
ListView.builder(
  itemCount: 10000,
  prototypeItem: const ListTile(title: Text('Prototype')),
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)
```

### 4.3 避免在 itemBuilder 中做重计算

```dart
// ❌ 每次构建都重新计算
ListView.builder(
  itemBuilder: (context, index) {
    final processed = expensiveProcessing(rawData[index]);  // 慢！
    return ListTile(title: Text(processed));
  },
)

// ✅ 预处理数据
final processedData = rawData.map(expensiveProcessing).toList();

ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(title: Text(processedData[index]));
  },
)
```

### 4.4 addAutomaticKeepAlives

```dart
// 对于需要保持状态的列表项（如包含输入框）
ListView.builder(
  addAutomaticKeepAlives: true,   // 默认 true
  addRepaintBoundaries: true,     // 默认 true
  itemBuilder: (context, index) {
    return MyStatefulListItem(key: ValueKey(index));
  },
)
```

## 5. 图片优化

### 5.1 适当的图片尺寸

```dart
// ❌ 加载原始大图（4000x3000），显示在 100x100 区域
Image.network('https://example.com/huge_image.jpg', width: 100, height: 100)

// ✅ 请求合适尺寸的图片（如果 CDN 支持）
Image.network('https://example.com/image.jpg?w=200&h=200', width: 100, height: 100)

// ✅ 使用 cacheWidth/cacheHeight 限制解码尺寸
Image.asset(
  'assets/big_image.png',
  cacheWidth: 200,   // 解码时缩小到 200 像素宽
  cacheHeight: 200,
)
```

### 5.2 图片缓存

```dart
// Flutter 默认有图片缓存（ImageCache）
// 可以调整缓存大小
PaintingBinding.instance.imageCache.maximumSize = 200;       // 最多缓存 200 张
PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20;  // 100MB
```

### 5.3 预加载图片

```dart
// 在需要显示前预加载
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(const AssetImage('assets/hero_image.png'), context);
}
```

## 6. Isolate 并发

### 6.1 为什么需要 Isolate

Flutter 的 UI 运行在主 Isolate 上。耗时计算会阻塞 UI，导致卡顿：

```dart
// ❌ 在主 Isolate 上执行耗时操作 —— UI 卡住
void onButtonPressed() {
  final result = heavyComputation(data);  // 阻塞 UI！
  setState(() => _result = result);
}
```

### 6.2 使用 Isolate.run（Dart 3.x 推荐）

```dart
import 'dart:isolate';

// ✅ 在后台 Isolate 中执行
void onButtonPressed() async {
  final result = await Isolate.run(() {
    return heavyComputation(data);
  });
  setState(() => _result = result);
}
```

### 6.3 使用 compute（Flutter 便捷方法）

```dart
import 'package:flutter/foundation.dart';

// 注意：传递的函数必须是顶层函数或静态方法
Future<List<Item>> parseItems(String jsonString) async {
  return await compute(_parseItemsInBackground, jsonString);
}

// 必须是顶层函数
List<Item> _parseItemsInBackground(String jsonString) {
  final jsonList = json.decode(jsonString) as List;
  return jsonList.map((e) => Item.fromJson(e)).toList();
}
```

### 6.4 何时使用 Isolate

| 操作 | 是否需要 Isolate |
|------|-----------------|
| JSON 解析（少量数据） | 不需要 |
| JSON 解析（大量数据 >1MB） | 需要 |
| 图片处理 | 需要 |
| 加密/解密 | 需要 |
| 数据库查询 | 通常不需要（已在 native 线程） |
| 网络请求 | 不需要（已异步） |
| 复杂算法计算 | 需要 |
| 文件 I/O | 通常不需要（已异步） |

### 6.5 Isolate 的限制

```dart
// ❌ Isolate 不能直接访问主 Isolate 的对象
await Isolate.run(() {
  // 不能访问 BuildContext、Widget、setState 等
  // 不能调用平台通道（MethodChannel）
  // 只能操作传入的数据
});

// ✅ 正确做法：传入纯数据，返回纯数据
final inputData = myList.toList();  // 创建副本
final result = await Isolate.run(() => processData(inputData));
```

## 7. 构建优化

### 7.1 减少不必要的 rebuild

```dart
// ❌ 整个页面因一个值变化而重建
class MyPage extends StatefulWidget { /* ... */ }

class _MyPageState extends State<MyPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeavyHeader(),         // 不需要重建但被迫重建
        Text('Count: $_counter'),    // 只有这里需要更新
        const HeavyFooter(),         // 不需要重建但被迫重建
      ],
    );
  }
}

// ✅ 将变化部分提取为独立 Widget
class CounterDisplay extends StatefulWidget {
  const CounterDisplay({super.key});
  @override
  State<CounterDisplay> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplay> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_counter');  // 只重建这个 Widget
  }
}
```

### 7.2 使用 ValueListenableBuilder 局部更新

```dart
final _counter = ValueNotifier<int>(0);

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      const Text('This never rebuilds'),  // 不重建
      ValueListenableBuilder<int>(
        valueListenable: _counter,
        builder: (context, value, child) {
          return Text('Count: $value');  // 只有这里重建
        },
      ),
    ],
  );
}
```

### 7.3 Builder 的 child 参数

```dart
// ✅ 利用 child 参数避免重建不变的部分
AnimatedBuilder(
  animation: _animation,
  child: const Icon(Icons.star, size: 50),  // 不随动画变化，只创建一次
  builder: (context, child) {
    return Transform.rotate(
      angle: _animation.value * 2 * pi,
      child: child,  // 复用传入的 child
    );
  },
)
```

## 8. DevTools 性能分析

### 8.1 启动 DevTools

```bash
# 方法 1：从命令行
flutter run --profile    # 必须用 profile 模式
# 然后在控制台输出的 URL 打开 DevTools

# 方法 2：从 IDE
# VS Code: Ctrl+Shift+P → "Open DevTools"
# Android Studio: View → Tool Windows → Flutter DevTools
```

### 8.2 Performance 面板

关注的指标：

- **Frame Build Time**：构建时间（Build 阶段）
- **Frame Raster Time**：光栅化时间（Paint + GPU 阶段）
- **Jank**：掉帧（超过 16ms 的帧）

```
Build   ████████░░░░░░░░ 8ms  ← 正常
Raster  ██████░░░░░░░░░░ 6ms  ← 正常

Build   ████████████████████████ 24ms  ← 卡顿！超过 16ms
Raster  ██████░░░░░░░░░░ 6ms
```

### 8.3 Widget Rebuild 追踪

```dart
// 在 Debug 模式下，可以开启 Widget 重建指示器
MaterialApp(
  // 显示重建次数
  showPerformanceOverlay: true,
)
```

### 8.4 Profile 模式的重要性

```
Debug 模式   → JIT 编译，有断言检查，性能不准确
Profile 模式 → AOT 编译，有性能分析支持，接近真实性能
Release 模式 → AOT 编译，完全优化，最终用户体验
```

**永远在 Profile 模式下做性能分析！**

## 9. 最佳实践清单

### 9.1 Widget 层面

- [x] 尽可能使用 `const` 构造函数
- [x] 将变化频繁的部分提取为独立 Widget
- [x] 使用 `const` 修饰不变的子树
- [x] 利用 `AnimatedBuilder` 的 `child` 参数

### 9.2 列表和滚动

- [x] 使用 `ListView.builder` 而非 `ListView`
- [x] 设置 `itemExtent` 或 `prototypeItem`
- [x] 对复杂列表项使用 `RepaintBoundary`
- [x] 避免在 `itemBuilder` 中做耗时操作

### 9.3 图片和资源

- [x] 使用适当尺寸的图片
- [x] 设置 `cacheWidth`/`cacheHeight`
- [x] 预加载关键图片

### 9.4 计算和数据

- [x] 耗时计算放到 Isolate 中
- [x] 避免在 `build` 方法中做重计算
- [x] 缓存计算结果

### 9.5 动画

- [x] 使用 `RepaintBoundary` 隔离动画区域
- [x] 避免 `Opacity` Widget（使用 `AnimatedOpacity` 或 `FadeTransition`）
- [x] 避免 `ClipRRect`、`BackdropFilter` 等昂贵操作（必要时加 RepaintBoundary）

### 9.6 避免的反模式

```dart
// ❌ 在 build 中创建 Stream/Future
Widget build(BuildContext context) {
  return FutureBuilder(
    future: fetchData(),  // 每次 build 都创建新 Future！
    builder: ...
  );
}

// ✅ 在 initState 中创建
late final Future<Data> _dataFuture;

@override
void initState() {
  super.initState();
  _dataFuture = fetchData();
}

Widget build(BuildContext context) {
  return FutureBuilder(
    future: _dataFuture,  // 使用缓存的 Future
    builder: ...
  );
}
```

---

## 总结

| 优化方向 | 关键技术 |
|---------|---------|
| 减少重建 | `const`、提取 Widget、`ValueListenableBuilder` |
| 减少重绘 | `RepaintBoundary` |
| 列表优化 | `ListView.builder`、`itemExtent` |
| 图片优化 | `cacheWidth`/`cacheHeight`、预加载 |
| 计算优化 | `Isolate.run`、`compute` |
| 分析工具 | DevTools、Profile 模式 |

性能优化是一个持续的过程，核心原则是：**先测量，再优化，避免过早优化**。

**下一章**：[第10章：发布与 CI/CD](ch10_release_cicd.md)
