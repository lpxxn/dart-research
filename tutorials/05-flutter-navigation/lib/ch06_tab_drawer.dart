import 'package:flutter/material.dart';

/// 第6章：Tab 与抽屉导航
/// 实现一个 3 Tab + Drawer 的完整导航框架
/// 展示 BottomNavigationBar、NavigationBar、TabBar、Drawer、嵌套 Navigator
void main() => runApp(const Ch06App());

class Ch06App extends StatelessWidget {
  const Ch06App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch06 Tab与抽屉导航',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================
// 主屏幕：3 Tab + Drawer 导航框架
// ============================================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _drawerSelectedIndex = 0;

  // 每个 Tab 的 Navigator Key（用于嵌套导航）
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    // 使用 PopScope 替代已弃用的 WillPopScope
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 先尝试在当前 Tab 的嵌套 Navigator 中返回
        final currentNav = _navigatorKeys[_currentIndex].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_currentIndex]),
        ),
        // 抽屉导航
        drawer: _buildDrawer(),
        // 使用 IndexedStack 保持各 Tab 的状态
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // 每个 Tab 拥有独立的嵌套 Navigator
            _buildTabNavigator(0, const HomeTab()),
            _buildTabNavigator(1, const ExploreTab()),
            _buildTabNavigator(2, const SettingsTab()),
          ],
        ),
        // Material 3 风格底部导航栏
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == _currentIndex) {
              // 再次点击当前 Tab，回到根页面
              _navigatorKeys[index].currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              setState(() => _currentIndex = index);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: '发现',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }

  final List<String> _tabTitles = ['首页', '发现', '设置'];

  /// 构建嵌套 Navigator，使每个 Tab 拥有独立的路由栈
  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => rootPage);
      },
    );
  }

  /// 构建 Drawer 抽屉菜单
  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _drawerSelectedIndex,
      onDestinationSelected: (index) {
        setState(() => _drawerSelectedIndex = index);
        Navigator.pop(context); // 关闭 Drawer

        // 根据选择执行不同操作
        switch (index) {
          case 0:
            setState(() => _currentIndex = 0);
            break;
          case 1:
            // 打开 TabBar 示例页面
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TabBarDemoPage()),
            );
            break;
          case 2:
            // 打开 NavigationRail 示例页面
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NavigationRailDemoPage()),
            );
            break;
        }
      },
      children: [
        // Drawer 头部
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 16, 16),
          child: Text(
            'Tab 与抽屉导航',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('首页'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.tab_outlined),
          selectedIcon: Icon(Icons.tab),
          label: Text('TabBar 示例'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.view_sidebar_outlined),
          selectedIcon: Icon(Icons.view_sidebar),
          label: Text('NavigationRail 示例'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        // Drawer 底部附加信息
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 16, 16),
          child: Text(
            '第6章教程示例',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Tab 1：首页（带 PageStorageKey 保持滚动位置）
// ============================================================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // PageStorageKey 保持滚动位置
      key: const PageStorageKey<String>('home-tab-list'),
      itemCount: 50,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text('首页项目 ${index + 1}'),
        subtitle: const Text('点击查看详情（嵌套导航）'),
        onTap: () {
          // 在嵌套 Navigator 中推入新页面，底部导航栏不会消失
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailInTab(
                title: '首页详情 ${index + 1}',
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Tab 2：发现页
// ============================================================
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey<String>('explore-tab-list'),
      itemCount: 30,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.article),
        title: Text('发现内容 ${index + 1}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailInTab(
                title: '发现详情 ${index + 1}',
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// Tab 3：设置页
// ============================================================
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('settings-tab-list'),
      children: [
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('关于嵌套导航'),
          subtitle: Text('每个 Tab 拥有独立的路由栈，底部导航栏始终可见'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('主题设置'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DetailInTab(title: '主题设置'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('语言设置'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DetailInTab(title: '语言设置'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('通知设置'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DetailInTab(title: '通知设置'),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// 嵌套导航的详情页（底部导航栏仍然可见）
// ============================================================
class DetailInTab extends StatelessWidget {
  final String title;

  const DetailInTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            const Text('这是嵌套 Navigator 中的页面'),
            const Text('注意底部导航栏仍然可见！'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // 继续在嵌套 Navigator 中推入更深层页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailInTab(title: '$title → 子页面'),
                  ),
                );
              },
              child: const Text('进入更深层页面'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TabBar + TabBarView 示例页面（从 Drawer 进入）
// ============================================================
class TabBarDemoPage extends StatelessWidget {
  const TabBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 DefaultTabController 简化 TabBar 管理
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar 示例'),
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
            _TabContent(
              icon: Icons.directions_car,
              label: '汽车出行',
              color: Colors.blue,
            ),
            _TabContent(
              icon: Icons.directions_transit,
              label: '地铁出行',
              color: Colors.green,
            ),
            _TabContent(
              icon: Icons.directions_bike,
              label: '自行车出行',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TabContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 24, color: color)),
          const SizedBox(height: 8),
          const Text('TabBar + TabBarView 示例'),
          const Text('左右滑动或点击 Tab 切换'),
        ],
      ),
    );
  }
}

// ============================================================
// NavigationRail 示例页面（从 Drawer 进入，适配宽屏）
// ============================================================
class NavigationRailDemoPage extends StatefulWidget {
  const NavigationRailDemoPage({super.key});

  @override
  State<NavigationRailDemoPage> createState() => _NavigationRailDemoPageState();
}

class _NavigationRailDemoPageState extends State<NavigationRailDemoPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('邮件页面', style: TextStyle(fontSize: 24))),
    Center(child: Text('聊天页面', style: TextStyle(fontSize: 24))),
    Center(child: Text('空间页面', style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NavigationRail 示例')),
      body: Row(
        children: [
          // 侧边导航栏
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            // 显示所有标签文字
            labelType: NavigationRailLabelType.all,
            // 顶部可以放一个 FAB 或 Logo
            leading: FloatingActionButton(
              onPressed: () {},
              elevation: 0,
              child: const Icon(Icons.add),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.mail_outlined),
                selectedIcon: Icon(Icons.mail),
                label: Text('邮件'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('聊天'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: Text('空间'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主体内容
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
