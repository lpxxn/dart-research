import 'package:flutter/material.dart';

void main() => runApp(const ResponsiveApp());

// ============================================================
// 断点枚举和工具类
// ============================================================

/// 设备类型枚举
enum DeviceType { mobile, tablet, desktop }

/// 断点工具类：统一管理响应式断点阈值
class Breakpoints {
  Breakpoints._(); // 禁止实例化

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  /// 根据宽度判断设备类型
  static DeviceType getDeviceType(double width) {
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) =>
      width >= mobileMax && width < tabletMax;
  static bool isDesktop(double width) => width >= tabletMax;

  /// 根据设备类型返回对应的值
  static T responsiveValue<T>(
    double width, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (getDeviceType(width)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

// ============================================================
// 响应式间距工具
// ============================================================

/// 根据屏幕宽度提供自适应间距
class ResponsiveSpacing {
  ResponsiveSpacing._();

  static EdgeInsets pagePadding(double width) {
    return Breakpoints.responsiveValue(
      width,
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    );
  }

  static double cardSpacing(double width) {
    return Breakpoints.responsiveValue(
      width,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }
}

// ============================================================
// 响应式字体工具
// ============================================================

/// 响应式字体大小
class ResponsiveFont {
  ResponsiveFont._();

  static double title(double width) {
    return Breakpoints.responsiveValue(width,
        mobile: 20.0, tablet: 24.0, desktop: 28.0);
  }

  static double body(double width) {
    return Breakpoints.responsiveValue(width,
        mobile: 14.0, tablet: 15.0, desktop: 16.0);
  }

  static double caption(double width) {
    return Breakpoints.responsiveValue(width,
        mobile: 12.0, tablet: 13.0, desktop: 14.0);
  }
}

// ============================================================
// 应用入口
// ============================================================

class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '响应式布局示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ResponsiveHomePage(),
    );
  }
}

// ============================================================
// 导航项目定义
// ============================================================

/// 导航目的地数据
class NavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// 所有导航项
const List<NavDestination> navDestinations = [
  NavDestination(
    label: '首页',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  NavDestination(
    label: '发现',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  NavDestination(
    label: '消息',
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
  ),
  NavDestination(
    label: '我的',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

// ============================================================
// 响应式主页面 — 使用 MediaQuery 做顶层布局决策
// ============================================================

class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({super.key});

  @override
  State<ResponsiveHomePage> createState() => _ResponsiveHomePageState();
}

class _ResponsiveHomePageState extends State<ResponsiveHomePage> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 sizeOf 而非 of，减少不必要的重建
    final screenWidth = MediaQuery.sizeOf(context).width;
    final deviceType = Breakpoints.getDeviceType(screenWidth);

    return SafeArea(
      // Scaffold 自身处理了顶部，这里确保底部和侧面的安全区域
      top: false,
      child: Scaffold(
        // 移动端显示 AppBar
        appBar: deviceType == DeviceType.mobile
            ? AppBar(
                title: Text(navDestinations[_selectedIndex].label),
                centerTitle: true,
              )
            : null,

        // 移动端显示底部导航栏（Material 3 NavigationBar）
        bottomNavigationBar: deviceType == DeviceType.mobile
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: navDestinations
                    .map((d) => NavigationDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: d.label,
                        ))
                    .toList(),
              )
            : null,

        // 根据设备类型构建 body
        body: _buildBody(deviceType),
      ),
    );
  }

  /// 根据设备类型选择布局
  Widget _buildBody(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        // 移动端：单列布局，导航在底部
        return _PageContent(
          selectedIndex: _selectedIndex,
          showDetailPanel: false,
        );

      case DeviceType.tablet:
        // 平板：NavigationRail + 两列布局
        return Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Icon(Icons.menu, size: 28),
              ),
              destinations: navDestinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _PageContent(
                selectedIndex: _selectedIndex,
                showDetailPanel: false,
              ),
            ),
          ],
        );

      case DeviceType.desktop:
        // 桌面端：永久侧边导航 + 三列布局（主内容 + 详情面板）
        return Row(
          children: [
            // 永久侧边导航抽屉
            _DesktopNavDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // 主内容 + 详情面板
            Expanded(
              child: _PageContent(
                selectedIndex: _selectedIndex,
                showDetailPanel: true,
              ),
            ),
          ],
        );
    }
  }
}

// ============================================================
// 桌面端永久导航抽屉
// ============================================================

class _DesktopNavDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _DesktopNavDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 240,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        child: Column(
          children: [
            // 应用标题区域
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.dashboard_rounded,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '响应式布局',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),
            // 导航项列表
            ...List.generate(navDestinations.length, (index) {
              final dest = navDestinations[index];
              final isSelected = index == selectedIndex;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ListTile(
                  leading: Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                  title: Text(
                    dest.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => onDestinationSelected(index),
                ),
              );
            }),
            const Spacer(),
            // 底部设置项
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 页面内容区域 — 使用 LayoutBuilder 做约束感知布局
// ============================================================

class _PageContent extends StatelessWidget {
  final int selectedIndex;
  final bool showDetailPanel;

  const _PageContent({
    required this.selectedIndex,
    required this.showDetailPanel,
  });

  @override
  Widget build(BuildContext context) {
    // 根据选中的导航项显示不同页面
    final pages = [
      _HomePage(showDetailPanel: showDetailPanel),
      const _DiscoverPage(),
      const _MessagesPage(),
      const _ProfilePage(),
    ];

    return pages[selectedIndex];
  }
}

// ============================================================
// 首页 — 展示 LayoutBuilder 和弹性网格
// ============================================================

class _HomePage extends StatelessWidget {
  final bool showDetailPanel;

  const _HomePage({required this.showDetailPanel});

  @override
  Widget build(BuildContext context) {
    if (!showDetailPanel) {
      return const _HomeMainContent();
    }

    // 桌面端三列布局：主内容 + 详情面板
    return const Row(
      children: [
        // 主内容区域
        Expanded(flex: 3, child: _HomeMainContent()),
        VerticalDivider(thickness: 1, width: 1),
        // 右侧详情面板
        Expanded(flex: 2, child: _DetailPanel()),
      ],
    );
  }
}

/// 首页主内容 — 使用 LayoutBuilder 构建弹性网格
class _HomeMainContent extends StatelessWidget {
  const _HomeMainContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveSpacing.pagePadding(width);
        final spacing = ResponsiveSpacing.cardSpacing(width);
        final titleSize = ResponsiveFont.title(width);
        final bodySize = ResponsiveFont.body(width);

        // 根据可用宽度计算网格列数（每列最小 160px）
        final columns = (width / 180).floor().clamp(1, 4);

        return CustomScrollView(
          slivers: [
            // 屏幕信息卡片
            SliverToBoxAdapter(
              child: Padding(
                padding: padding,
                child: _ScreenInfoCard(
                  titleSize: titleSize,
                  bodySize: bodySize,
                ),
              ),
            ),

            // 欢迎区域
            SliverToBoxAdapter(
              child: Padding(
                padding: padding.copyWith(top: 0),
                child: Text(
                  '功能卡片',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 弹性网格
            SliverPadding(
              padding: padding.copyWith(top: 0),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FeatureCard(
                    index: index,
                    bodySize: bodySize,
                  ),
                  childCount: 8,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// 屏幕信息卡片 — 展示 MediaQuery 数据
// ============================================================

class _ScreenInfoCard extends StatelessWidget {
  final double titleSize;
  final double bodySize;

  const _ScreenInfoCard({
    required this.titleSize,
    required this.bodySize,
  });

  @override
  Widget build(BuildContext context) {
    // 使用细粒度查询，各自只在对应属性变化时重建
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final deviceType = Breakpoints.getDeviceType(size.width);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '屏幕信息（MediaQuery）',
                  style: TextStyle(
                    fontSize: titleSize * 0.85,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 信息表格
            _InfoRow(
              label: '设备类型',
              value: deviceType.name.toUpperCase(),
              fontSize: bodySize,
            ),
            _InfoRow(
              label: '屏幕尺寸',
              value:
                  '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)}',
              fontSize: bodySize,
            ),
            _InfoRow(
              label: '屏幕方向',
              value: orientation == Orientation.portrait ? '竖屏' : '横屏',
              fontSize: bodySize,
            ),
            _InfoRow(
              label: '像素密度',
              value: '${dpr.toStringAsFixed(1)}x',
              fontSize: bodySize,
            ),
            _InfoRow(
              label: '安全区域(上/下)',
              value:
                  '${padding.top.toStringAsFixed(0)} / ${padding.bottom.toStringAsFixed(0)}',
              fontSize: bodySize,
            ),
            _InfoRow(
              label: '键盘高度',
              value: viewInsets.bottom.toStringAsFixed(0),
              fontSize: bodySize,
            ),
          ],
        ),
      ),
    );
  }
}

/// 信息行组件
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.7))),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================
// 功能卡片
// ============================================================

class _FeatureCard extends StatelessWidget {
  final int index;
  final double bodySize;

  const _FeatureCard({required this.index, required this.bodySize});

  static const _icons = [
    Icons.widgets_outlined,
    Icons.grid_view_outlined,
    Icons.layers_outlined,
    Icons.auto_awesome_outlined,
    Icons.palette_outlined,
    Icons.animation_outlined,
    Icons.data_object_outlined,
    Icons.rocket_launch_outlined,
  ];

  static const _labels = [
    '组件库',
    '网格布局',
    '图层管理',
    '智能推荐',
    '主题配色',
    '动画效果',
    '数据管理',
    '快速上手',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconIndex = index % _icons.length;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icons[iconIndex],
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _labels[iconIndex],
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 右侧详情面板（桌面端第三列）
// ============================================================

class _DetailPanel extends StatelessWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详情面板',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '这是桌面端独有的第三列详情面板。\n\n'
              '在宽度 > 1024px 的屏幕上显示，'
              '用于展示选中项目的详细信息，'
              '避免用户频繁切换页面。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 24),
            // 模拟详情内容
            _DetailItem(
              icon: Icons.devices,
              title: '多端适配',
              subtitle: '手机 / 平板 / 桌面',
            ),
            _DetailItem(
              icon: Icons.speed,
              title: '性能优化',
              subtitle: '使用 MediaQuery.sizeOf 等细粒度查询',
            ),
            _DetailItem(
              icon: Icons.safety_check,
              title: '安全区域',
              subtitle: '使用 SafeArea 处理刘海屏',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: colorScheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 发现页面 — 使用 OrientationBuilder 示例
// ============================================================

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage();

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = ResponsiveSpacing.pagePadding(width);
            final titleSize = ResponsiveFont.title(width);
            final bodySize = ResponsiveFont.body(width);
            final columns = orientation == Orientation.landscape ? 3 : 2;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '发现',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '方向: ${orientation == Orientation.portrait ? "竖屏" : "横屏"} · '
                          '列数: $columns',
                          style: TextStyle(
                            fontSize: bodySize,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: padding.copyWith(top: 0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _DiscoverCard(index: index),
                      childCount: 12,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: ResponsiveSpacing.cardSpacing(width),
                      mainAxisSpacing: ResponsiveSpacing.cardSpacing(width),
                      childAspectRatio: 1.4,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final int index;

  const _DiscoverCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    return Card(
      elevation: 0,
      color: colors[index % colors.length].withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(
          '推荐 ${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 消息页面
// ============================================================

class _MessagesPage extends StatelessWidget {
  const _MessagesPage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveSpacing.pagePadding(width);
        final titleSize = ResponsiveFont.title(width);

        return ListView(
          padding: padding,
          children: [
            Text(
              '消息',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(15, (index) => _MessageTile(index: index)),
          ],
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final int index;

  const _MessageTile({required this.index});

  static const _names = ['张三', '李四', '王五', '赵六', '钱七'];
  static const _messages = [
    '你好，最近怎么样？',
    '明天的会议改到下午了',
    '代码已经提交了，帮忙看一下',
    '周末一起吃饭吗？',
    '这个布局方案不错！',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _names[index % _names.length];
    final message = _messages[index % _messages.length];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            colorScheme.primaryContainer.withValues(alpha: 0.7),
        child: Text(
          name[0],
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Text(
        '${(index * 3 + 1) % 24}:${(index * 17) % 60 < 10 ? "0" : ""}${(index * 17) % 60}',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ============================================================
// 个人资料页面
// ============================================================

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveSpacing.pagePadding(width);
        final titleSize = ResponsiveFont.title(width);
        // 平板和桌面端限制内容最大宽度，提高可读性
        final maxContentWidth = Breakpoints.isMobile(width) ? width : 600.0;

        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // 头像
                  CircleAvatar(
                    radius: Breakpoints.responsiveValue(width,
                        mobile: 40.0, tablet: 50.0, desktop: 60.0),
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: Breakpoints.responsiveValue(width,
                          mobile: 40.0, tablet: 50.0, desktop: 60.0),
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Flutter 开发者',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'flutter@example.com',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 设置项列表
                  _ProfileMenuItem(
                    icon: Icons.palette_outlined,
                    title: '外观设置',
                    subtitle: '主题、字体大小',
                  ),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: '通知设置',
                    subtitle: '推送、免打扰',
                  ),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline,
                    title: '隐私安全',
                    subtitle: '密码、权限管理',
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: '帮助与反馈',
                    subtitle: '常见问题、联系我们',
                  ),
                  _ProfileMenuItem(
                    icon: Icons.info_outline,
                    title: '关于',
                    subtitle: '版本 1.0.0',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
