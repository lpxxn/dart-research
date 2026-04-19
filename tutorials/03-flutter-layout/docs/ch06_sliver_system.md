# 第六章：Sliver 体系 —— Flutter 高级滚动布局

## 目录

1. [什么是 Sliver？](#1-什么是-sliver)
2. [CustomScrollView —— Sliver 的容器](#2-customscrollview--sliver-的容器)
3. [SliverAppBar —— 可折叠的应用栏](#3-sliverappbar--可折叠的应用栏)
4. [SliverList 和 SliverGrid —— 列表与网格](#4-sliverlist-和-slivergrid--列表与网格)
5. [SliverToBoxAdapter —— 普通 Widget 的桥梁](#5-slivertoboadapter--普通-widget-的桥梁)
6. [SliverPersistentHeader —— 自定义吸顶效果](#6-sliverpersistentheader--自定义吸顶效果)
7. [SliverFillRemaining —— 填充剩余空间](#7-sliverfillremaining--填充剩余空间)
8. [NestedScrollView —— 协调内外滚动](#8-nestedscrollview--协调内外滚动)
9. [实战：仿应用商店详情页](#9-实战仿应用商店详情页)
10. [最佳实践与常见问题](#10-最佳实践与常见问题)

---

## 1. 什么是 Sliver？

### 1.1 Sliver 的概念

在 Flutter 中，**Sliver** 是一种特殊的 Widget，专门用于在可滚动区域内实现**按需加载**和**惰性渲染**。Sliver 这个词本身意味着"薄片"——每个 Sliver 只负责渲染滚动区域中的一小部分内容。

### 1.2 为什么需要 Sliver？

普通的 `ListView` 或 `GridView` 已经能满足大多数滚动需求，但当我们需要实现以下效果时，普通 Widget 就力不从心了：

| 需求 | 普通 Widget | Sliver 体系 |
|------|------------|-------------|
| 可折叠的 AppBar | ❌ 无法实现 | ✅ SliverAppBar |
| 多种列表混合滚动 | ❌ 嵌套滚动冲突 | ✅ CustomScrollView |
| 吸顶效果 | ❌ 需要复杂 hack | ✅ SliverPersistentHeader |
| 异构滚动内容 | ❌ 困难 | ✅ SliverToBoxAdapter |
| 内外滚动协调 | ❌ 几乎不可能 | ✅ NestedScrollView |

### 1.3 Sliver 与普通 Widget 的本质区别

```
普通 Widget 的布局协议：BoxConstraints → Size
Sliver 的布局协议：   SliverConstraints → SliverGeometry
```

- **普通 Widget**：接收 `BoxConstraints`（最大/最小宽高），返回 `Size`（实际宽高）
- **Sliver Widget**：接收 `SliverConstraints`（滚动方向、剩余绘制空间、已滚动距离等），返回 `SliverGeometry`（绘制范围、滚动范围、缓存范围等）

这意味着 Sliver 天然具备"知道自己在滚动区域中的位置"的能力，从而可以实现各种复杂的滚动效果。

### 1.4 核心 SliverConstraints 字段

```dart
SliverConstraints(
  axisDirection: AxisDirection.down,      // 滚动方向
  scrollOffset: 150.0,                    // 当前已滚动的偏移量
  remainingPaintExtent: 600.0,            // 剩余可绘制空间
  overlap: 0.0,                           // 与前一个 Sliver 的重叠量
  crossAxisExtent: 375.0,                 // 交叉轴宽度（如屏幕宽度）
  viewportMainAxisExtent: 800.0,          // 视口主轴长度
  remainingCacheExtent: 850.0,            // 剩余缓存空间
  cacheOrigin: -250.0,                    // 缓存起点
)
```

---

## 2. CustomScrollView —— Sliver 的容器

### 2.1 基本概念

`CustomScrollView` 是所有 Sliver 的**容器**，它扮演着"滚动视口"的角色。你可以把它想象成一个"画卷"，而各个 Sliver 就是画卷上的不同段落。

```dart
CustomScrollView(
  // 滚动方向，默认垂直
  scrollDirection: Axis.vertical,
  // 是否反向
  reverse: false,
  // 滚动控制器
  controller: ScrollController(),
  // 滚动物理效果
  physics: const BouncingScrollPhysics(),
  // 核心：Sliver 列表
  slivers: <Widget>[
    SliverAppBar(...),
    SliverList(...),
    SliverGrid(...),
    SliverToBoxAdapter(...),
  ],
)
```

### 2.2 关键要点

1. **slivers 列表中只能放 Sliver 类型的 Widget**，普通 Widget 需要用 `SliverToBoxAdapter` 包裹
2. 所有 Sliver 共享同一个滚动上下文，不会出现嵌套滚动冲突
3. `CustomScrollView` 内部使用 `Viewport` 来管理所有 Sliver 的布局

### 2.3 与 ListView 的关系

实际上，`ListView` 内部就是一个 `CustomScrollView` + `SliverList` 的组合：

```dart
// ListView 本质上等价于：
CustomScrollView(
  slivers: [
    SliverList(
      delegate: SliverChildListDelegate(children),
    ),
  ],
)
```

---

## 3. SliverAppBar —— 可折叠的应用栏

### 3.1 核心属性详解

`SliverAppBar` 是 Sliver 体系中最常用也最强大的组件之一，它支持滚动时的折叠、展开、浮动等多种效果。

```dart
SliverAppBar(
  // ========== 展开/折叠相关 ==========
  expandedHeight: 200.0,        // 展开时的总高度
  collapsedHeight: 60.0,        // 折叠后的高度（默认为 toolbarHeight）
  toolbarHeight: 56.0,          // 工具栏高度（标题栏部分）

  // ========== 行为控制 ==========
  floating: false,               // 向下滚动时是否立即显示
  pinned: true,                  // 折叠后是否固定在顶部
  snap: false,                   // 配合 floating 使用，是否有弹性吸附效果

  // ========== 外观 ==========
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
  elevation: 4.0,

  // ========== 内容 ==========
  title: const Text('应用详情'),
  leading: const BackButton(),
  actions: [IconButton(...)],

  // ========== 折叠区域 ==========
  flexibleSpace: FlexibleSpaceBar(
    title: const Text('应用名称'),
    background: Image.network(
      'https://example.com/banner.jpg',
      fit: BoxFit.cover,
    ),
    collapseMode: CollapseMode.parallax,  // 视差效果
  ),
)
```

### 3.2 floating / pinned / snap 组合效果

这三个属性的不同组合决定了 AppBar 在滚动时的行为：

| floating | pinned | snap | 效果描述 |
|----------|--------|------|---------|
| false | false | false | 随内容滚动，完全消失 |
| false | true | false | **最常用**：折叠后固定在顶部 |
| true | false | false | 向下滚动时立即浮现 |
| true | false | true | 浮现时有弹性吸附效果 |
| true | true | false | 固定 + 浮现（少用） |
| true | true | true | 固定 + 弹性吸附 |

> **注意**：`snap: true` 必须配合 `floating: true` 使用，否则会报错。

### 3.3 FlexibleSpaceBar 的折叠模式

```dart
FlexibleSpaceBar(
  collapseMode: CollapseMode.parallax,  // 视差滚动（默认）
  // CollapseMode.pin,                  // 固定不动
  // CollapseMode.none,                 // 无效果，直接裁剪
)
```

### 3.4 动态标题透明度

通常我们希望在完全折叠时才显示标题，可以利用 `LayoutBuilder` 或监听滚动：

```dart
SliverAppBar(
  flexibleSpace: LayoutBuilder(
    builder: (context, constraints) {
      // constraints.maxHeight 会在展开和折叠之间变化
      final double ratio =
          (constraints.maxHeight - kToolbarHeight) /
          (expandedHeight - kToolbarHeight);
      return FlexibleSpaceBar(
        title: Text(
          '应用名称',
          style: TextStyle(
            color: Colors.white.withValues(alpha: ratio.clamp(0.0, 1.0)),
          ),
        ),
      );
    },
  ),
)
```

---

## 4. SliverList 和 SliverGrid —— 列表与网格

### 4.1 Delegate 模式

Sliver 列表和网格使用 **delegate 模式** 来提供子元素，这是实现懒加载的关键。

#### SliverChildBuilderDelegate（推荐：懒加载）

```dart
SliverList(
  delegate: SliverChildBuilderDelegate(
    (BuildContext context, int index) {
      return ListTile(
        title: Text('Item $index'),
        subtitle: Text('这是第 $index 个列表项'),
      );
    },
    childCount: 100,                  // 必须指定，否则无限构建
    addAutomaticKeepAlives: true,     // 自动保持状态（默认 true）
    addRepaintBoundaries: true,       // 添加重绘边界（默认 true）
    addSemanticIndexes: true,         // 添加语义索引（默认 true）
  ),
)
```

> **原理**：`SliverChildBuilderDelegate` 只会构建当前可见区域 + 缓存区域内的子元素。当子元素滚出屏幕后会被回收，滚入时重新构建。这就是 Sliver 的"惰性渲染"核心。

#### SliverChildListDelegate（适用于少量固定子元素）

```dart
SliverList(
  delegate: SliverChildListDelegate([
    const Header(),
    const InfoSection(),
    const DescriptionSection(),
    // 所有子元素在初始化时就创建好了
  ]),
)
```

### 4.2 SliverList 用法

```dart
// 基础用法
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(title: Text('列表项 $index')),
    ),
    childCount: 50,
  ),
)

// Flutter 3.x 新语法（更简洁）
SliverList.builder(
  itemCount: 50,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)

SliverList.separated(
  itemCount: 50,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
  separatorBuilder: (context, index) => const Divider(),
)
```

### 4.3 SliverGrid 用法

```dart
// 使用 delegate + gridDelegate
SliverGrid(
  delegate: SliverChildBuilderDelegate(
    (context, index) => Container(
      color: Colors.primaries[index % Colors.primaries.length],
      alignment: Alignment.center,
      child: Text('$index', style: const TextStyle(color: Colors.white)),
    ),
    childCount: 20,
  ),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,          // 每行 3 个
    mainAxisSpacing: 8.0,       // 主轴间距
    crossAxisSpacing: 8.0,      // 交叉轴间距
    childAspectRatio: 1.0,      // 宽高比
  ),
)

// 按最大宽度自适应列数
SliverGrid(
  delegate: SliverChildBuilderDelegate(...),
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 150.0,  // 每个子元素最大宽度
    mainAxisSpacing: 8.0,
    crossAxisSpacing: 8.0,
    childAspectRatio: 1.0,
  ),
)

// Flutter 3.x 简洁写法
SliverGrid.builder(
  itemCount: 20,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
  ),
  itemBuilder: (context, index) => Card(child: Center(child: Text('$index'))),
)
```

---

## 5. SliverToBoxAdapter —— 普通 Widget 的桥梁

### 5.1 为什么需要它？

`CustomScrollView` 的 `slivers` 列表中**只能放 Sliver 类型的 Widget**。当你想在滚动列表中插入一个普通的 Widget（如 `Container`、`Card`、`Text`）时，就需要 `SliverToBoxAdapter` 来做"翻译"。

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(...),

    // ❌ 错误：普通 Widget 不能直接放入 slivers
    // Container(height: 100, color: Colors.red),

    // ✅ 正确：用 SliverToBoxAdapter 包裹
    SliverToBoxAdapter(
      child: Container(
        height: 100,
        color: Colors.red,
        alignment: Alignment.center,
        child: const Text('我是一个普通 Widget'),
      ),
    ),

    SliverList(...),
  ],
)
```

### 5.2 常见用途

- 在列表顶部/中间插入 **标题区域**
- 插入 **分隔线** 或 **间距**
- 放置 **搜索框**、**轮播图** 等非列表内容
- 放置 **加载更多** 指示器

```dart
// 用作分隔标题
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text(
      '推荐应用',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
  ),
)
```

### 5.3 注意事项

> ⚠️ **不要在 SliverToBoxAdapter 中放高度无限的 Widget**（如没有限制高度的 `ListView`），这会导致布局错误。如果需要放一个列表，直接使用 `SliverList`。

---

## 6. SliverPersistentHeader —— 自定义吸顶效果

### 6.1 基本概念

`SliverPersistentHeader` 可以创建一个在滚动时**保持可见**或**逐渐收缩**的头部。这是实现"吸顶 TabBar"、"悬浮搜索栏"等效果的利器。

### 6.2 创建 Delegate

你需要创建一个继承 `SliverPersistentHeaderDelegate` 的类：

```dart
class MyStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  MyStickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;  // 完全折叠时的高度

  @override
  double get maxExtent => maxHeight;  // 完全展开时的高度

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,     // 当前收缩的偏移量（0 表示完全展开）
    bool overlapsContent,    // 是否与下方内容重叠
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant MyStickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
}
```

### 6.3 使用方式

```dart
// 吸顶效果（pinned: true）
SliverPersistentHeader(
  pinned: true,        // 滚动到顶部时固定
  floating: false,     // 不浮动
  delegate: MyStickyHeaderDelegate(
    minHeight: 48.0,   // 固定后的高度
    maxHeight: 48.0,   // 展开时的高度（与 min 相同则不收缩）
    child: Container(
      color: Colors.white,
      child: const TabBar(tabs: [...]),
    ),
  ),
)
```

### 6.4 利用 shrinkOffset 实现动态效果

```dart
@override
Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
  // 计算收缩进度 0.0 ~ 1.0
  final double shrinkRatio = shrinkOffset / (maxExtent - minExtent);

  return Container(
    color: Color.lerp(Colors.transparent, Colors.blue, shrinkRatio),
    alignment: Alignment.center,
    child: Text(
      '标题',
      style: TextStyle(
        fontSize: lerpDouble(24.0, 16.0, shrinkRatio),
        color: Colors.white,
      ),
    ),
  );
}
```

---

## 7. SliverFillRemaining —— 填充剩余空间

### 7.1 基本概念

`SliverFillRemaining` 会**填充视口中的剩余空间**。当上方内容不够填满整个屏幕时，它会自动扩展以填满剩余区域。

### 7.2 常见用途

#### 底部填充（空状态页面）

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(title: const Text('我的列表')),
    // 当列表为空时，展示空状态
    SliverFillRemaining(
      hasScrollBody: false,  // 重要：设为 false 以正确填充
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无数据', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ),
  ],
)
```

#### 表单页面底部按钮

```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            TextField(decoration: InputDecoration(labelText: '用户名')),
            TextField(decoration: InputDecoration(labelText: '密码')),
          ],
        ),
      ),
    ),
    SliverFillRemaining(
      hasScrollBody: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('提交'),
          ),
        ),
      ),
    ),
  ],
)
```

### 7.3 hasScrollBody 参数

- `hasScrollBody: true`（默认）：子 Widget 会被包裹在一个可滚动的区域中
- `hasScrollBody: false`：子 Widget 只是简单地被放置在剩余空间中，不可滚动

---

## 8. NestedScrollView —— 协调内外滚动

### 8.1 为什么需要 NestedScrollView？

当页面结构是"可折叠头部 + TabBarView（内部各 Tab 可独立滚动）"时，外部的 `CustomScrollView` 和内部的 `ListView` 会产生**滚动冲突**。`NestedScrollView` 就是为了解决这个问题。

### 8.2 基本结构

```dart
NestedScrollView(
  // 外部滚动区域的头部（Sliver 列表）
  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
    return [
      SliverAppBar(
        expandedHeight: 200.0,
        pinned: true,
        // innerBoxIsScrolled 指示内部是否已经开始滚动
        forceElevated: innerBoxIsScrolled,
        flexibleSpace: FlexibleSpaceBar(
          title: const Text('标题'),
          background: Image.network('...', fit: BoxFit.cover),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: TabBarDelegate(tabBar: const TabBar(tabs: [...])),
      ),
    ];
  },
  // 内部可滚动区域（通常是 TabBarView）
  body: TabBarView(
    children: [
      ListView.builder(...),
      GridView.builder(...),
      ListView.builder(...),
    ],
  ),
)
```

### 8.3 工作原理

```
┌─────────────────────────┐
│  NestedScrollView        │
│  ┌───────────────────┐  │
│  │ headerSliverBuilder│  │  ← 外部滚动（outer ScrollController）
│  │ - SliverAppBar     │  │
│  │ - SliverTabBar     │  │
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │ body               │  │  ← 内部滚动（inner ScrollController）
│  │ - TabBarView       │  │
│  │   - ListView       │  │
│  │   - ListView       │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

`NestedScrollView` 内部维护了两个 `ScrollController`：
- **outer**：控制头部区域的滚动（折叠 SliverAppBar 等）
- **inner**：控制 body 中的滚动

滚动优先级：先消费外部滚动（折叠头部），然后才传递给内部。

### 8.4 floatHeaderSlivers 属性

```dart
NestedScrollView(
  floatHeaderSlivers: true,  // 向下滑动时头部是否浮现
  headerSliverBuilder: ...,
  body: ...,
)
```

当设为 `true` 时，配合 `SliverAppBar(floating: true)` 可以实现向下滑动时 AppBar 立即浮现的效果。

### 8.5 注意事项

1. **不要在 body 中使用 `CustomScrollView`**，直接使用 `ListView`、`GridView` 等即可
2. 如果使用 `TabBarView`，确保配合 `DefaultTabController` 或显式 `TabController`
3. `innerBoxIsScrolled` 参数可以用来控制 AppBar 的阴影效果

---

## 9. 实战：仿应用商店详情页

完整的代码请参见 `lib/ch06_sliver_system.dart`，这里说明关键设计思路。

### 9.1 页面结构分析

```
┌──────────────────────────────┐
│  SliverAppBar (可折叠)        │  ← 应用横幅图
│  FlexibleSpaceBar             │
├──────────────────────────────┤
│  应用信息区域                  │  ← SliverToBoxAdapter
│  (图标、名称、评分、下载按钮)   │
├──────────────────────────────┤
│  TabBar (吸顶)                │  ← SliverPersistentHeader(pinned)
├──────────────────────────────┤
│  TabBarView                   │  ← body
│  ├─ 详情 Tab (描述 + 截图)    │
│  ├─ 评论 Tab (评论列表)        │
│  └─ 相关 Tab (推荐应用网格)    │
└──────────────────────────────┘
```

### 9.2 关键实现点

1. 使用 `NestedScrollView` 作为顶层容器
2. `headerSliverBuilder` 中放置 SliverAppBar + 应用信息 + 吸顶 TabBar
3. `body` 中放置 `TabBarView`
4. 吸顶 TabBar 使用 `SliverPersistentHeader(pinned: true)`
5. 相关应用使用 `GridView` 展示

---

## 10. 最佳实践与常见问题

### 10.1 性能优化

```dart
// ✅ 使用 builder delegate 实现懒加载
SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) => ItemWidget(data: items[index]),
    childCount: items.length,
  ),
)

// ❌ 避免一次性创建所有子元素（数据量大时）
SliverList(
  delegate: SliverChildListDelegate(
    items.map((item) => ItemWidget(data: item)).toList(),
  ),
)
```

### 10.2 避免常见错误

```dart
// ❌ 错误：在 CustomScrollView 中放普通 Widget
CustomScrollView(
  slivers: [
    Container(),  // 报错！
  ],
)

// ✅ 正确：用 SliverToBoxAdapter 包裹
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: Container()),
  ],
)
```

### 10.3 Sliver 之间的间距

```dart
// 使用 SliverToBoxAdapter + SizedBox
SliverToBoxAdapter(
  child: SizedBox(height: 16),
)

// 或使用 SliverPadding
SliverPadding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  sliver: SliverList(...),
)
```

### 10.4 ScrollController 注意事项

```dart
class _MyPageState extends State<MyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();  // 必须在 dispose 中释放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [...],
    );
  }
}
```

### 10.5 调试 Sliver 布局

使用 Flutter DevTools 的 Layout Explorer 可以可视化 Sliver 的布局约束和几何信息。也可以在代码中打印：

```dart
SliverLayoutBuilder(
  builder: (BuildContext context, SliverConstraints constraints) {
    debugPrint('scrollOffset: ${constraints.scrollOffset}');
    debugPrint('remainingPaintExtent: ${constraints.remainingPaintExtent}');
    return SliverToBoxAdapter(child: ...);
  },
)
```

### 10.6 何时使用 Sliver vs 普通 Widget？

| 场景 | 建议 |
|------|------|
| 简单列表 | `ListView` |
| 简单网格 | `GridView` |
| 可折叠 AppBar | `CustomScrollView` + `SliverAppBar` |
| 多种内容混合滚动 | `CustomScrollView` + 多种 Sliver |
| 吸顶 + Tab 切换 | `NestedScrollView` |
| 复杂滚动效果 | 自定义 Sliver |

### 10.7 withValues 替代 withOpacity

Flutter 新版本推荐使用 `withValues` 来设置颜色透明度，避免使用已废弃的 `withOpacity`：

```dart
// ❌ 旧写法（已废弃）
Colors.black.withOpacity(0.5)

// ✅ 新写法
Colors.black.withValues(alpha: 0.5)
```

---

## 小结

Sliver 体系是 Flutter 布局中的**高级武器**，掌握它可以实现几乎所有复杂的滚动效果。关键点回顾：

1. **CustomScrollView** 是 Sliver 的容器，所有 Sliver 必须放在其中
2. **SliverAppBar** 提供了丰富的可折叠应用栏效果
3. **SliverList / SliverGrid** 使用 delegate 模式实现懒加载
4. **SliverToBoxAdapter** 是普通 Widget 进入 Sliver 世界的桥梁
5. **SliverPersistentHeader** 是实现吸顶效果的核心组件
6. **SliverFillRemaining** 用于填充视口剩余空间
7. **NestedScrollView** 解决了内外滚动协调的难题

掌握这些组件，你就能构建出媲美原生应用的复杂滚动页面！
