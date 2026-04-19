# 第6章：Tab 与抽屉导航

## 概述

大多数 App 都需要顶层导航结构来组织功能模块。Flutter 提供了多种导航组件：
- **BottomNavigationBar** / **NavigationBar**：底部导航栏
- **NavigationRail**：侧边导航栏（适配宽屏）
- **TabBar + TabBarView**：顶部 Tab 切换
- **Drawer** / **NavigationDrawer**：抽屉菜单

本章将详细讲解每种组件的用法，并构建一个完整的 Tab + Drawer 导航框架。

---

## 1. BottomNavigationBar

### 1.1 基本用法

`BottomNavigationBar` 是 Material 2 风格的底部导航栏。

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

### 1.2 关键属性

| 属性 | 说明 |
|------|------|
| `type` | `BottomNavigationBarType.fixed`（固定）或 `.shifting`（移动效果） |
| `selectedItemColor` | 选中项颜色 |
| `unselectedItemColor` | 未选中项颜色 |
| `backgroundColor` | 背景颜色 |
| `elevation` | 阴影高度 |
| `iconSize` | 图标大小 |
| `showSelectedLabels` | 是否显示选中项的文字 |
| `showUnselectedLabels` | 是否显示未选中项的文字 |

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed, // 超过3个 item 时建议使用 fixed
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.grey,
  showUnselectedLabels: true,
  // ...
)
```

> **注意：** 当 item 数量 ≥ 4 时，默认 type 为 `shifting`，此时需要为每个 item 设置 `backgroundColor`，或者手动设置 `type: BottomNavigationBarType.fixed`。

---

## 2. NavigationBar（Material 3）

### 2.1 基本用法

`NavigationBar` 是 Material 3 风格的底部导航栏，推荐在使用 Material 3 主题时使用。

```dart
NavigationBar(
  selectedIndex: _currentIndex,
  onDestinationSelected: (index) => setState(() => _currentIndex = index),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: '首页'),
    NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
    NavigationDestination(icon: Icon(Icons.person), label: '我的'),
  ],
)
```

### 2.2 与 BottomNavigationBar 的区别

| 特性 | BottomNavigationBar | NavigationBar |
|------|-------------------|---------------|
| 设计规范 | Material 2 | Material 3 |
| 选中指示器 | 颜色变化 | Pill 形状背景 |
| 动画效果 | 简单 | 更丰富 |
| 推荐场景 | 旧项目 | 新项目 |

---

## 3. NavigationRail（适配宽屏）

### 3.1 基本用法

`NavigationRail` 是垂直方向的导航栏，适合平板和桌面端。

```dart
NavigationRail(
  selectedIndex: _currentIndex,
  onDestinationSelected: (index) => setState(() => _currentIndex = index),
  labelType: NavigationRailLabelType.all,
  destinations: const [
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('首页')),
    NavigationRailDestination(icon: Icon(Icons.search), label: Text('搜索')),
    NavigationRailDestination(icon: Icon(Icons.person), label: Text('我的')),
  ],
)
```

### 3.2 响应式布局：根据屏幕宽度切换

```dart
@override
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 800) {
    // 宽屏：使用 NavigationRail
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: _railDestinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  } else {
    // 窄屏：使用 BottomNavigationBar
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
```

---

## 4. TabBar + TabBarView

### 4.1 使用 DefaultTabController

`TabBar` 通常放在 `AppBar` 的 `bottom` 位置，配合 `TabBarView` 使用。

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: const Text('Tab 示例'),
      bottom: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.directions_car), text: '汽车'),
          Tab(icon: Icon(Icons.directions_transit), text: '地铁'),
          Tab(icon: Icon(Icons.directions_bike), text: '自行车'),
        ],
      ),
    ),
    body: const TabBarView(
      children: [
        Center(child: Text('汽车页面')),
        Center(child: Text('地铁页面')),
        Center(child: Text('自行车页面')),
      ],
    ),
  ),
)
```

### 4.2 手动管理 TabController

当需要更精确的控制（如监听 Tab 切换、代码切换 Tab）时，手动创建 `TabController`。

```dart
class MyTabPage extends StatefulWidget {
  @override
  State<MyTabPage> createState() => _MyTabPageState();
}

class _MyTabPageState extends State<MyTabPage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // 监听 Tab 切换
      if (!_tabController.indexIsChanging) {
        debugPrint('当前 Tab: ${_tabController.index}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(controller: _tabController, tabs: [/* ... */]),
      ),
      body: TabBarView(controller: _tabController, children: [/* ... */]),
    );
  }
}
```

---

## 5. Drawer 和 NavigationDrawer

### 5.1 基本 Drawer

```dart
Scaffold(
  appBar: AppBar(title: const Text('Drawer 示例')),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text('菜单', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('首页'),
          onTap: () {
            Navigator.pop(context); // 关闭 Drawer
            // 导航到首页
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('设置'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ],
    ),
  ),
)
```

### 5.2 NavigationDrawer（Material 3）

```dart
NavigationDrawer(
  selectedIndex: _selectedDrawerIndex,
  onDestinationSelected: (index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.pop(context); // 关闭抽屉
  },
  children: [
    const Padding(
      padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
      child: Text('导航', style: TextStyle(fontSize: 16)),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('首页'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('设置'),
    ),
    const Divider(),
    const NavigationDrawerDestination(
      icon: Icon(Icons.info_outline),
      selectedIcon: Icon(Icons.info),
      label: Text('关于'),
    ),
  ],
)
```

---

## 6. 嵌套 Navigator（每个 Tab 保持独立路由栈）

### 6.1 问题

默认情况下，在某个 Tab 页面内使用 `Navigator.push()` 会推入全局 Navigator，底部导航栏会消失。

### 6.2 解决方案

为每个 Tab 创建独立的 `Navigator`，使用不同的 `GlobalKey<NavigatorState>` 管理。

```dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 每个 Tab 的 Navigator Key
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 拦截返回键，先尝试在当前 Tab 的 Navigator 中 pop
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final currentNavigator = _navigatorKeys[_currentIndex].currentState!;
        if (currentNavigator.canPop()) {
          currentNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildNavigator(0, const HomePage()),
            _buildNavigator(1, const SearchPage()),
            _buildNavigator(2, const ProfilePage()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) {
              // 点击当前 Tab 时，pop 到根页面
              _navigatorKeys[index].currentState!
                  .popUntil((route) => route.isFirst);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          items: const [/* ... */],
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }
}
```

### 6.3 IndexedStack 的作用

`IndexedStack` 只显示指定 index 的子 Widget，但会保持所有子 Widget 的状态。这样切换 Tab 时，之前的页面状态（滚动位置、表单数据等）会被保留。

---

## 7. PageStorageKey 保持滚动位置

### 7.1 问题

使用 `IndexedStack` 时滚动位置会自动保持。但如果不用 `IndexedStack`（比如用条件判断显示不同页面），切换 Tab 后滚动位置会丢失。

### 7.2 使用 PageStorageKey

```dart
ListView.builder(
  key: const PageStorageKey<String>('home-list'), // 保持滚动位置
  itemCount: 100,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)
```

`PageStorageKey` 会将滚动位置存储在最近的 `PageStorage`（Scaffold 内置了 PageStorage）中。

### 7.3 工作原理

```
PageStorage（由 Scaffold 提供）
  ├── PageStorageKey('home-list') → ScrollPosition(offset: 1234.0)
  ├── PageStorageKey('search-list') → ScrollPosition(offset: 567.0)
  └── PageStorageKey('profile-list') → ScrollPosition(offset: 0.0)
```

---

## 8. 最佳实践

### 8.1 Tab 数量

- 底部导航：3-5 个 Tab
- 顶部 TabBar：不限，可滚动
- 如果功能过多，考虑使用 Drawer 补充

### 8.2 状态保持

- 使用 `IndexedStack` 保持 Tab 状态
- 对 `ListView` 使用 `PageStorageKey`
- 复杂状态考虑使用状态管理方案

### 8.3 响应式设计

```
窄屏（< 600dp）  → BottomNavigationBar
中屏（600-840dp） → NavigationRail（收起标签）
宽屏（> 840dp）   → NavigationRail（展开标签）或永久性 Drawer
```

### 8.4 深层链接

嵌套 Navigator 场景下处理深层链接较复杂，如需支持深层链接，建议使用 `go_router` 等路由库。

---

## 9. 小结

| 组件 | 适用场景 | 设计规范 |
|------|---------|---------|
| `BottomNavigationBar` | 手机底部导航 | Material 2 |
| `NavigationBar` | 手机底部导航 | Material 3 |
| `NavigationRail` | 平板/桌面侧边导航 | Material 3 |
| `TabBar + TabBarView` | 顶部分类切换 | Material 2/3 |
| `Drawer` | 辅助导航菜单 | Material 2 |
| `NavigationDrawer` | 辅助导航菜单 | Material 3 |

下一章我们将学习对话框与底部弹窗的使用。
