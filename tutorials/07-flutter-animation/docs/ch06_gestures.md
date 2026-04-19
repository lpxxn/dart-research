# 第6章：手势系统

## 概述

Flutter 的手势系统是用户与应用交互的核心。本章将深入讲解 Flutter 手势系统的原理和常用组件，包括 GestureDetector、Draggable/DragTarget、InteractiveViewer、手势竞技场机制以及 Dismissible 组件。

---

## 6.1 手势系统原理

### 事件传递流程

Flutter 的手势处理分为三个阶段：

1. **PointerEvent（指针事件）**：最底层的触摸事件，包括 `PointerDownEvent`、`PointerMoveEvent`、`PointerUpEvent` 等
2. **GestureRecognizer（手势识别器）**：将原始指针事件识别为语义化手势（点击、拖拽、缩放等）
3. **GestureDetector（手势检测器）**：便捷的 Widget 封装，内部使用各种 GestureRecognizer

```
触摸屏幕 → PointerEvent → HitTest → GestureRecognizer → 手势回调
```

### 命中测试（Hit Test）

当用户触摸屏幕时，Flutter 从根节点开始向下遍历 Widget 树，找到所有包含触摸点的 Widget。命中测试的顺序是**从上到下、从后往前**，即最上层的 Widget 最先接收到事件。

---

## 6.2 GestureDetector 全解

`GestureDetector` 是 Flutter 中最常用的手势检测 Widget，它可以识别多种手势。

### 基本用法

```dart
GestureDetector(
  onTap: () => print('点击'),
  onDoubleTap: () => print('双击'),
  onLongPress: () => print('长按'),
  child: Container(
    width: 100,
    height: 100,
    color: Colors.blue,
    child: const Center(child: Text('点我')),
  ),
)
```

### 支持的手势类型

| 手势类型 | 回调方法 | 说明 |
|---------|---------|------|
| 点击 | `onTap`, `onTapDown`, `onTapUp`, `onTapCancel` | 单击手势 |
| 双击 | `onDoubleTap`, `onDoubleTapDown`, `onDoubleTapCancel` | 快速点击两次 |
| 长按 | `onLongPress`, `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd` | 长时间按住 |
| 垂直拖拽 | `onVerticalDragStart`, `onVerticalDragUpdate`, `onVerticalDragEnd` | 垂直方向拖动 |
| 水平拖拽 | `onHorizontalDragStart`, `onHorizontalDragUpdate`, `onHorizontalDragEnd` | 水平方向拖动 |
| 任意方向拖拽 | `onPanStart`, `onPanUpdate`, `onPanEnd` | 任意方向拖动 |
| 缩放 | `onScaleStart`, `onScaleUpdate`, `onScaleEnd` | 双指缩放和旋转 |

### 拖拽示例

```dart
GestureDetector(
  onPanUpdate: (details) {
    setState(() {
      // details.delta 是相对于上一次回调的偏移量
      _offset += details.delta;
    });
  },
  child: Transform.translate(
    offset: _offset,
    child: const FlutterLogo(size: 80),
  ),
)
```

### 缩放示例

```dart
GestureDetector(
  onScaleStart: (details) {
    _baseScale = _currentScale;
  },
  onScaleUpdate: (details) {
    setState(() {
      // details.scale 是相对于 onScaleStart 时的缩放比例
      _currentScale = _baseScale * details.scale;
    });
  },
  child: Transform.scale(
    scale: _currentScale,
    child: Image.network('https://example.com/image.jpg'),
  ),
)
```

> **注意**：`onPanXxx` 和 `onScaleXxx` 不能同时使用，因为缩放手势已经包含了平移信息。如果需要同时处理平移和缩放，请使用 `onScaleXxx`，通过 `details.focalPointDelta` 获取平移信息。

---

## 6.3 Draggable 与 DragTarget

`Draggable` 和 `DragTarget` 提供了拖放（drag-and-drop）功能。

### Draggable

```dart
Draggable<String>(
  // 携带的数据
  data: 'Hello',
  // 正常状态下的外观
  child: const Chip(label: Text('拖我')),
  // 拖拽时跟随手指的外观
  feedback: Material(
    child: Chip(
      label: const Text('拖拽中'),
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
    ),
  ),
  // 拖拽时原位置的外观
  childWhenDragging: const Chip(
    label: Text('已拖走'),
    backgroundColor: Colors.grey,
  ),
)
```

### DragTarget

```dart
DragTarget<String>(
  // 当拖拽物进入区域时
  onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
  // 当拖拽物被放下时
  onAcceptWithDetails: (details) {
    setState(() {
      _receivedData = details.data;
    });
  },
  builder: (context, candidateData, rejectedData) {
    return Container(
      width: 200,
      height: 200,
      color: candidateData.isNotEmpty ? Colors.green : Colors.grey,
      child: Center(child: Text('放这里: $_receivedData')),
    );
  },
)
```

### LongPressDraggable

`LongPressDraggable` 与 `Draggable` 类似，但需要长按才能开始拖拽，适用于列表项排序等场景：

```dart
LongPressDraggable<int>(
  data: index,
  child: ListTile(title: Text('项目 $index')),
  feedback: Material(
    elevation: 4,
    child: SizedBox(
      width: 300,
      child: ListTile(title: Text('项目 $index')),
    ),
  ),
)
```

---

## 6.4 InteractiveViewer

`InteractiveViewer` 提供了开箱即用的平移和缩放功能，非常适合查看图片、地图等场景。

### 基本用法

```dart
InteractiveViewer(
  // 最小缩放比例
  minScale: 0.5,
  // 最大缩放比例
  maxScale: 4.0,
  // 是否允许超出边界（回弹效果）
  boundaryMargin: const EdgeInsets.all(20),
  child: Image.asset('assets/large_image.png'),
)
```

### 高级配置

```dart
InteractiveViewer(
  // 变换控制器，可以编程控制变换
  transformationController: _transformationController,
  // 是否启用缩放
  scaleEnabled: true,
  // 是否启用平移
  panEnabled: true,
  // 变换发生时的回调
  onInteractionStart: (details) {
    print('交互开始: ${details.focalPoint}');
  },
  onInteractionUpdate: (details) {
    print('缩放: ${details.scale}');
  },
  onInteractionEnd: (details) {
    print('交互结束');
  },
  child: myWidget,
)
```

### TransformationController

通过 `TransformationController` 可以编程控制和监听变换：

```dart
final _controller = TransformationController();

// 重置变换
void _resetTransform() {
  _controller.value = Matrix4.identity();
}

// 监听变换
@override
void initState() {
  super.initState();
  _controller.addListener(() {
    final matrix = _controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    print('当前缩放: $scale');
  });
}
```

---

## 6.5 手势竞技场（Gesture Arena）

### 什么是手势竞技场

当多个 GestureRecognizer 同时监听同一区域时，Flutter 使用**手势竞技场**来决定哪个手势胜出。

### 竞争规则

1. 每个识别器向竞技场"报名"
2. 当某个识别器确信自己识别了正确的手势时，它"宣告胜利"
3. 其他识别器被通知失败并清理状态
4. 如果只剩一个竞争者，它自动胜出

### 实际场景

```
场景：ListView 中的 GestureDetector
- 用户触摸屏幕
- ListView 的滚动识别器参与竞争
- GestureDetector 的点击识别器参与竞争
- 如果用户快速点击 → 点击胜出
- 如果用户开始滑动 → 滚动胜出
```

### 解决手势冲突

使用 `behavior` 属性控制命中测试行为：

```dart
GestureDetector(
  // 默认值：只在有子 Widget 的区域响应
  behavior: HitTestBehavior.deferToChild,
  
  // 在整个区域响应（即使透明区域）
  behavior: HitTestBehavior.opaque,
  
  // 允许事件穿透
  behavior: HitTestBehavior.translucent,
  
  onTap: () => print('点击'),
  child: ...,
)
```

### RawGestureDetector

当需要更精细的控制时，使用 `RawGestureDetector`：

```dart
RawGestureDetector(
  gestures: {
    // 使用 EagerGestureRecognizer 立即获胜
    EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<
        EagerGestureRecognizer>(
      () => EagerGestureRecognizer(),
      (recognizer) {},
    ),
  },
  child: myWidget,
)
```

---

## 6.6 Dismissible 组件

`Dismissible` 提供了滑动删除功能，常用于列表项。

### 基本用法

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Dismissible(
      // 每个 Dismissible 需要唯一的 key
      key: ValueKey(items[index]),
      // 滑动后的回调
      onDismissed: (direction) {
        setState(() {
          items.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${items[index]}')),
        );
      },
      // 滑动方向
      direction: DismissDirection.endToStart,
      // 背景（向右滑时显示）
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      // 次要背景（向左滑时显示）
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // 确认是否可以删除
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      child: ListTile(title: Text(items[index])),
    );
  },
)
```

### Dismissible 参数详解

| 参数 | 说明 |
|-----|------|
| `key` | 必须唯一，用于标识每个 Dismissible |
| `direction` | 滑动方向，默认 `DismissDirection.horizontal` |
| `onDismissed` | 滑动完成后的回调 |
| `confirmDismiss` | 返回 Future<bool>，用于确认是否允许滑动 |
| `background` | 从左向右滑时显示的背景 |
| `secondaryBackground` | 从右向左滑时显示的背景 |
| `dismissThresholds` | 触发 dismiss 的阈值 |
| `movementDuration` | 动画持续时间 |
| `resizeDuration` | 消失后调整大小的动画持续时间 |

---

## 6.7 最佳实践

### 1. 合理选择手势组件

```
简单点击/拖拽 → GestureDetector
拖放交互 → Draggable + DragTarget
图片/地图缩放 → InteractiveViewer
滑动删除 → Dismissible
列表排序 → ReorderableListView
```

### 2. 避免手势冲突

- 不要在同一个 Widget 上同时使用 `onPanXxx` 和 `onHorizontalDragXxx`
- 嵌套的 GestureDetector 可能导致意外的行为，优先使用单一 GestureDetector
- 使用 `AbsorbPointer` 或 `IgnorePointer` 控制事件传递

### 3. 性能优化

- 拖拽和缩放回调中避免重量级操作
- 使用 `RepaintBoundary` 隔离频繁重绘的区域
- 缩放大图片时考虑使用 `InteractiveViewer` 而非手动实现

### 4. 用户体验

- 提供视觉反馈：拖拽时改变透明度或大小
- 添加触觉反馈：`HapticFeedback.lightImpact()`
- 对于不可逆操作（删除），使用 `confirmDismiss` 添加确认

---

## 6.8 本章示例代码

示例代码文件：`lib/ch06_gestures.dart`

包含两个主要功能：
1. **可拖拽排序列表**：使用 `LongPressDraggable` + `DragTarget` 实现长按拖拽排序
2. **双指缩放图片**：使用 `InteractiveViewer` 实现图片的双指缩放和平移

运行方式：
```bash
flutter run -t lib/ch06_gestures.dart
```
