# 第五章：滚动列表（Scrollable List）

Flutter 中的列表和网格是构建数据密集型界面的核心组件。本章将深入讲解 `ListView`、`GridView`、滚动控制、下拉刷新与无限滚动加载等关键技术。

---

## 目录

1. [ListView 的四种构造方式](#1-listview-的四种构造方式)
2. [ListView.builder 懒加载机制与性能优势](#2-listviewbuilder-懒加载机制与性能优势)
3. [itemExtent / prototypeItem 优化](#3-itemextent--prototypeitem-优化)
4. [GridView 网格列表](#4-gridview-网格列表)
5. [ScrollController 控制滚动](#5-scrollcontroller-控制滚动)
6. [下拉刷新 RefreshIndicator](#6-下拉刷新-refreshindicator)
7. [无限滚动加载更多](#7-无限滚动加载更多)
8. [addAutomaticKeepAlives / addRepaintBoundaries 参数](#8-addautomatickeepalives--addrepaintboundaries-参数)
9. [最佳实践总结](#9-最佳实践总结)

---

## 1. ListView 的四种构造方式

`ListView` 是 Flutter 中最常用的可滚动组件，提供了四种构造方式，适用于不同的场景。

### 1.1 默认 ListView 构造函数

直接传入 `children` 列表，适合**数量较少且固定**的子项。所有子项会在构建时**一次性全部创建**。

```dart
ListView(
  padding: const EdgeInsets.all(8),
  children: const <Widget>[
    ListTile(title: Text('第一项')),
    ListTile(title: Text('第二项')),
    ListTile(title: Text('第三项')),
  ],
)
```

> ⚠️ **注意**：当子项数量较多时（例如超过几十个），不要使用默认构造函数，因为它会一次性构建所有子 Widget，导致性能问题。

### 1.2 ListView.builder

按需构建子项，只有**即将进入可视区域**的子项才会被创建。适合**大数据列表**或**无限列表**。

```dart
ListView.builder(
  itemCount: 1000,
  itemBuilder: (BuildContext context, int index) {
    return ListTile(
      leading: CircleAvatar(child: Text('$index')),
      title: Text('列表项 $index'),
      subtitle: Text('这是第 $index 个元素的描述'),
    );
  },
)
```

**核心原理**：`ListView.builder` 内部使用 `SliverChildBuilderDelegate`，配合视口（Viewport）的懒加载机制，只为可见区域及其缓冲区内的索引调用 `itemBuilder`。

### 1.3 ListView.separated

在每两个列表项之间插入一个分隔 Widget，非常适合需要**分隔线**的列表。

```dart
ListView.separated(
  itemCount: 100,
  // 构建列表项
  itemBuilder: (BuildContext context, int index) {
    return ListTile(title: Text('列表项 $index'));
  },
  // 构建分隔线
  separatorBuilder: (BuildContext context, int index) {
    return const Divider(height: 1);
  },
)
```

> 💡 **技巧**：`separatorBuilder` 可以根据 `index` 返回不同的分隔组件，例如每隔 5 项插入一个广告 Banner。

### 1.4 ListView.custom

最灵活的构造方式，允许你自定义 `SliverChildDelegate`。可以完全控制子项的创建、回收和估算逻辑。

```dart
ListView.custom(
  childrenDelegate: SliverChildBuilderDelegate(
    (BuildContext context, int index) {
      return ListTile(title: Text('自定义项 $index'));
    },
    childCount: 50,
    // 根据索引查找已有的子项（用于复用优化）
    findChildIndexCallback: (Key key) {
      // 自定义查找逻辑，用于高效重排序
      return null;
    },
  ),
)
```

**使用场景**：当你需要在列表重新排序时保持子项状态，或者需要自定义 `estimateMaxScrollOffset` 时使用。

### 四种方式对比

| 构造方式 | 是否懒加载 | 分隔线 | 灵活性 | 适用场景 |
|---------|-----------|-------|--------|---------|
| `ListView()` | ❌ 全量构建 | ❌ | 低 | 少量固定子项 |
| `ListView.builder` | ✅ 按需构建 | ❌ | 中 | 大量数据、无限列表 |
| `ListView.separated` | ✅ 按需构建 | ✅ 内置 | 中 | 需要分隔线的列表 |
| `ListView.custom` | ✅ 按需构建 | 自定义 | 高 | 高级定制需求 |

---

## 2. ListView.builder 懒加载机制与性能优势

### 懒加载原理

Flutter 的滚动列表基于 **Sliver** 协议。视口（`Viewport`）会告诉 Sliver 当前可见的区域范围和缓冲区大小（`cacheExtent`，默认 250 像素）。Sliver 只会为落在**可见区域 + 缓冲区**内的索引调用 `itemBuilder`。

```
┌─────────────────────────────┐
│       缓冲区（上方）          │  ← cacheExtent 内的项已创建但不可见
├─────────────────────────────┤
│                             │
│       可见区域               │  ← 用户能看到的列表项
│                             │
├─────────────────────────────┤
│       缓冲区（下方）          │  ← cacheExtent 内的项已创建但不可见
└─────────────────────────────┘
│       未创建的项             │  ← 不会调用 itemBuilder
```

### 性能优势

1. **内存节省**：只保持可见区域及缓冲区的 Widget 树和 Element 树
2. **构建开销低**：不会一次性构建成百上千个 Widget
3. **自动回收**：滑出缓冲区的子项会被自动销毁（除非 `addAutomaticKeepAlives` 为 `true` 且子项使用了 `AutomaticKeepAliveClientMixin`）

### cacheExtent 配置

```dart
ListView.builder(
  // 增大缓冲区可以减少快速滚动时的空白，但会增加内存占用
  cacheExtent: 500.0,
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)
```

> 💡 **建议**：在大多数场景下，默认的 `cacheExtent`（250 像素）已经足够。只有在用户快速滑动时出现明显空白闪烁时，才考虑增大该值。

---

## 3. itemExtent / prototypeItem 优化

当列表中每一项的高度（或宽度）固定时，提供 `itemExtent` 或 `prototypeItem` 可以**显著提升滚动性能**。

### 3.1 itemExtent

直接指定每一项的固定像素高度：

```dart
ListView.builder(
  itemExtent: 72.0, // 每一项固定 72 像素高
  itemCount: 10000,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text('固定高度项 $index'),
    );
  },
)
```

### 3.2 prototypeItem

提供一个原型 Widget，Flutter 会用它的实际渲染高度作为所有子项的预估高度：

```dart
ListView.builder(
  prototypeItem: const ListTile(title: Text('原型')),
  itemCount: 10000,
  itemBuilder: (context, index) {
    return ListTile(title: Text('列表项 $index'));
  },
)
```

### 为什么能提升性能？

1. **跳转优化**：当调用 `scrollController.jumpTo(offset)` 时，如果没有 `itemExtent`，框架需要逐个布局子项来确定目标偏移。有了固定高度，可以直接通过数学计算定位。
2. **滚动条精度**：固定高度使得滚动条的大小和位置计算更准确。
3. **减少布局次数**：框架不需要实际测量每个子项就能确定可见范围。

> ⚠️ **注意**：`itemExtent` 和 `prototypeItem` 不能同时使用，只能二选一。

---

## 4. GridView 网格列表

`GridView` 将子项排列成二维网格，提供了四种构造方式。

### 4.1 GridView.count

直接指定**每行的列数**（crossAxisCount）：

```dart
GridView.count(
  crossAxisCount: 3,          // 每行 3 列
  mainAxisSpacing: 8.0,       // 主轴（垂直）间距
  crossAxisSpacing: 8.0,      // 交叉轴（水平）间距
  childAspectRatio: 1.0,      // 子项宽高比
  padding: const EdgeInsets.all(8),
  children: List.generate(20, (index) {
    return Card(
      child: Center(child: Text('网格 $index')),
    );
  }),
)
```

> ⚠️ **注意**：与默认 `ListView` 类似，`GridView.count` 会**一次性构建所有子项**，不适合大数据。

### 4.2 GridView.extent

指定子项的**最大交叉轴尺寸**，Flutter 自动计算每行能放几个：

```dart
GridView.extent(
  maxCrossAxisExtent: 150,     // 每个子项最大宽度 150
  mainAxisSpacing: 8.0,
  crossAxisSpacing: 8.0,
  children: List.generate(20, (index) {
    return Card(
      child: Center(child: Text('网格 $index')),
    );
  }),
)
```

**适用场景**：当你希望网格在不同屏幕宽度下自动调整列数时，`GridView.extent` 比 `GridView.count` 更灵活。

### 4.3 GridView.builder

懒加载版本，配合 `SliverGridDelegate` 使用，适合**大量数据**：

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.75,
  ),
  itemCount: 100,
  itemBuilder: (context, index) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.primaries[index % Colors.primaries.length],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('商品 $index'),
          ),
        ],
      ),
    );
  },
)
```

### 4.4 GridView.custom

最灵活的版本，可以自定义 `SliverChildDelegate` 和 `SliverGridDelegate`：

```dart
GridView.custom(
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
  ),
  childrenDelegate: SliverChildBuilderDelegate(
    (context, index) => Card(child: Center(child: Text('$index'))),
    childCount: 50,
  ),
)
```

### 两种 SliverGridDelegate 对比

| Delegate | 参数 | 特点 |
|----------|------|------|
| `SliverGridDelegateWithFixedCrossAxisCount` | `crossAxisCount` | 固定列数 |
| `SliverGridDelegateWithMaxCrossAxisExtent` | `maxCrossAxisExtent` | 自适应列数 |

---

## 5. ScrollController 控制滚动

`ScrollController` 用于**监听滚动事件**和**程序化控制滚动位置**。

### 5.1 基本用法

```dart
class _MyListPageState extends State<MyListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 监听滚动事件
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // 获取当前滚动偏移
    final offset = _scrollController.offset;
    // 获取最大可滚动范围
    final maxExtent = _scrollController.position.maxScrollExtent;
    debugPrint('当前偏移: $offset / $maxExtent');
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 必须释放！
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 100,
      itemBuilder: (context, index) => ListTile(title: Text('项 $index')),
    );
  }
}
```

### 5.2 滚动到顶部

```dart
void _scrollToTop() {
  _scrollController.animateTo(
    0.0,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
}
```

### 5.3 滚动到底部

```dart
void _scrollToBottom() {
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
}
```

### 5.4 监听是否滚动到底部

```dart
_scrollController.addListener(() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    // 距离底部不到 200 像素，触发加载更多
    _loadMore();
  }
});
```

### 5.5 使用 NotificationListener 替代

对于更细粒度的滚动控制，可以使用 `NotificationListener<ScrollNotification>`：

```dart
NotificationListener<ScrollNotification>(
  onNotification: (ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      debugPrint('开始滚动');
    } else if (notification is ScrollUpdateNotification) {
      debugPrint('滚动中: ${notification.metrics.pixels}');
    } else if (notification is ScrollEndNotification) {
      debugPrint('滚动结束');
    }
    return false; // 返回 false 允许通知继续冒泡
  },
  child: ListView.builder(
    itemCount: 100,
    itemBuilder: (context, index) => ListTile(title: Text('项 $index')),
  ),
)
```

> 💡 **NotificationListener vs ScrollController**：`NotificationListener` 不需要持有 controller 引用，适合在父组件中监听子列表的滚动事件。`ScrollController` 更适合需要主动控制滚动位置的场景。

---

## 6. 下拉刷新 RefreshIndicator

`RefreshIndicator` 是 Material Design 风格的下拉刷新组件，包裹在可滚动 Widget 外面即可。

### 基本用法

```dart
RefreshIndicator(
  onRefresh: () async {
    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      items = fetchNewItems(); // 刷新数据
    });
  },
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return ListTile(title: Text(items[index]));
    },
  ),
)
```

### 注意事项

1. **onRefresh 必须返回 Future**：刷新指示器会等到 Future 完成后才收起。
2. **子组件必须可滚动**：`RefreshIndicator` 需要检测到向下滚动手势。
3. **内容不足以滚动时**：需要设置 `physics: const AlwaysScrollableScrollPhysics()` 让列表始终可以被下拉。

```dart
RefreshIndicator(
  onRefresh: _handleRefresh,
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(), // 关键！
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(title: Text(items[index])),
  ),
)
```

### 自定义外观

```dart
RefreshIndicator(
  onRefresh: _handleRefresh,
  color: Colors.white,             // 指示器前景色
  backgroundColor: Colors.blue,     // 指示器背景色
  displacement: 40.0,              // 下拉触发距离
  strokeWidth: 3.0,                // 指示器线宽
  child: listView,
)
```

---

## 7. 无限滚动加载更多

实现"加载更多"（Load More / Infinite Scroll）的核心思路：监听滚动到底部 → 触发加载 → 追加数据。

### 完整实现

```dart
class _InfiniteListState extends State<InfiniteList> {
  final ScrollController _controller = ScrollController();
  final List<String> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _controller.addListener(() {
      // 距离底部 200 像素时触发加载
      if (_controller.position.maxScrollExtent - _controller.offset < 200) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // 模拟 API 请求
    await Future.delayed(const Duration(seconds: 1));
    final newItems = List.generate(20, (i) => '项目 ${_page * 20 + i}');

    setState(() {
      _page++;
      _items.addAll(newItems);
      _isLoading = false;
      _hasMore = _page < 5; // 假设最多加载 5 页
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      // 多出一项用于显示加载指示器
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ListTile(title: Text(_items[index]));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 实现要点

1. **防重复加载**：用 `_isLoading` 标志防止同时触发多次加载
2. **终止条件**：用 `_hasMore` 标记是否还有更多数据
3. **加载指示器**：`itemCount` 多加 1，最后一项显示 `CircularProgressIndicator`
4. **提前触发**：在距离底部还有一段距离时就开始加载（如 200 像素），提升用户体验

---

## 8. addAutomaticKeepAlives / addRepaintBoundaries 参数

这两个参数在 `ListView.builder`、`ListView.separated`、`GridView.builder` 等构造函数中都有，直接影响列表的性能表现。

### 8.1 addAutomaticKeepAlives

- **默认值**：`true`
- **作用**：为每个子项包裹 `AutomaticKeepAlive` Widget
- **效果**：当子项混入了 `AutomaticKeepAliveClientMixin` 时，滑出视口的子项**不会被销毁**，而是保持状态

```dart
class _MyItemState extends State<MyItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持存活

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return ExpensiveWidget();
  }
}
```

**使用场景**：
- 子项包含视频播放器、文本输入框等有状态组件时启用
- 纯展示型列表可以设为 `false` 以节省内存

### 8.2 addRepaintBoundaries

- **默认值**：`true`
- **作用**：为每个子项包裹 `RepaintBoundary` Widget
- **效果**：将每个子项的重绘隔离，当某个子项需要重绘时，不会影响其他子项

```dart
ListView.builder(
  addRepaintBoundaries: true,   // 默认 true，通常不需要改
  addAutomaticKeepAlives: true, // 默认 true
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(item: items[index]),
)
```

**什么时候设为 false？**
- 子项非常简单（如纯文本），`RepaintBoundary` 的开销反而大于收益时
- 使用性能分析工具确认 `RepaintBoundary` 成为瓶颈时

### 性能优化决策表

| 场景 | addAutomaticKeepAlives | addRepaintBoundaries |
|------|----------------------|---------------------|
| 简单文本列表 | `false` | `false` |
| 包含图片的列表 | `true` | `true` |
| 包含输入框/视频 | `true` | `true` |
| 极长列表（10万+） | `false` | `true` |

---

## 9. 最佳实践总结

### 选择正确的列表类型

```
数据量 < 20 且固定？ → ListView() 或 GridView.count()
数据量大或动态？     → ListView.builder() 或 GridView.builder()
需要分隔线？        → ListView.separated()
需要深度定制？      → ListView.custom() 或 GridView.custom()
```

### 性能优化清单

1. ✅ **始终使用 builder 构造函数**处理大列表
2. ✅ **提供 itemExtent 或 prototypeItem**（如果高度固定）
3. ✅ **使用 const 构造函数**减少不必要的重建
4. ✅ **为图片使用缓存**（如 `cached_network_image` 包）
5. ✅ **合理设置 cacheExtent**
6. ✅ **及时释放 ScrollController**（在 `dispose` 中）
7. ❌ **避免在 itemBuilder 中做耗时操作**
8. ❌ **避免对大列表使用默认构造函数**

### 常见陷阱

1. **忘记 dispose ScrollController**：导致内存泄漏
2. **RefreshIndicator 无法下拉**：添加 `AlwaysScrollableScrollPhysics`
3. **无限加载不触发**：检查 `maxScrollExtent` 的判断条件
4. **列表项状态丢失**：正确使用 Key 和 `AutomaticKeepAliveClientMixin`
5. **使用 withOpacity()**：应该使用 `withValues(alpha: x)` 替代，避免创建不必要的 Color 对象

### 调试工具

- **Flutter DevTools**：Performance 面板观察帧率
- **Widget Inspector**：查看列表实际构建了多少子项
- `debugPrintMarkNeedsPaintStacks = true`：打印重绘调用栈

---

## 延伸阅读

- [Flutter 官方文档 - ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)
- [Flutter 官方文档 - GridView](https://api.flutter.dev/flutter/widgets/GridView-class.html)
- [Flutter 官方文档 - ScrollController](https://api.flutter.dev/flutter/widgets/ScrollController-class.html)
- [Flutter Cookbook - 长列表](https://docs.flutter.dev/cookbook/lists/long-lists)
- [Slivers 深入理解](https://docs.flutter.dev/ui/layout/scrolling/slivers)
