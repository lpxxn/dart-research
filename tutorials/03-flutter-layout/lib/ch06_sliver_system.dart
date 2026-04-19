// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

/// 第六章：Sliver 体系 —— 仿应用商店详情页
///
/// 演示了以下 Sliver 组件的综合运用：
/// - NestedScrollView（协调内外滚动）
/// - SliverAppBar + FlexibleSpaceBar（可折叠应用栏）
/// - SliverToBoxAdapter（普通 Widget 嵌入 Sliver）
/// - SliverPersistentHeader（吸顶 TabBar）
/// - SliverGrid（网格布局，用于相关应用）
/// - SliverList（列表布局，用于评论）

void main() => runApp(const Ch06SliverSystemApp());

// ============================================================================
// 应用入口
// ============================================================================

class Ch06SliverSystemApp extends StatelessWidget {
  const Ch06SliverSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sliver 体系示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const AppStoreDetailPage(),
    );
  }
}

// ============================================================================
// 仿应用商店详情页 —— 使用 NestedScrollView 协调内外滚动
// ============================================================================

class AppStoreDetailPage extends StatefulWidget {
  const AppStoreDetailPage({super.key});

  @override
  State<AppStoreDetailPage> createState() => _AppStoreDetailPageState();
}

class _AppStoreDetailPageState extends State<AppStoreDetailPage>
    with SingleTickerProviderStateMixin {
  /// 显式 TabController，用于控制 TabBar 和 TabBarView
  late final TabController _tabController;

  /// Tab 标签列表
  static const List<String> _tabTitles = ['详情', '评论', '相关'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  @override
  void dispose() {
    // 必须释放 TabController，避免内存泄漏
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NestedScrollView：协调 header 中的 Sliver 与 body 中 TabBarView 的滚动
      body: NestedScrollView(
        // 外部 header 区域：SliverAppBar + 应用信息 + 吸顶 TabBar
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            // ---- 可折叠的 SliverAppBar ----
            _buildSliverAppBar(innerBoxIsScrolled),
            // ---- 应用基本信息区域 ----
            _buildAppInfoSection(),
            // ---- 吸顶 TabBar ----
            _buildStickyTabBar(),
          ];
        },
        // 内部 body 区域：TabBarView，各 Tab 可独立滚动
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DetailTab(),
            _ReviewsTab(),
            _RelatedAppsTab(),
          ],
        ),
      ),
    );
  }

  /// 构建可折叠的 SliverAppBar
  ///
  /// - pinned: true → 折叠后固定在顶部
  /// - expandedHeight: 250 → 展开时的总高度
  /// - FlexibleSpaceBar 提供视差背景图效果
  SliverAppBar _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      // 当内部列表滚动时，显示 AppBar 阴影
      forceElevated: innerBoxIsScrolled,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      title: const Text('应用详情'),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => print('分享'),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => print('更多'),
        ),
      ],
      // FlexibleSpaceBar：折叠时产生视差效果的背景区域
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            // 渐变背景模拟应用横幅图
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF42A5F5),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // 应用图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apps,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Flutter 超级应用',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '效率工具 · 4.8 ★',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建应用基本信息区域
  ///
  /// 使用 SliverToBoxAdapter 将普通 Widget 放入 Sliver 环境
  SliverToBoxAdapter _buildAppInfoSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用名称行
            Row(
              children: [
                // 小图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.apps, size: 32, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                // 应用名称和开发者
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flutter 超级应用',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Flutter 团队',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // 下载按钮
                FilledButton(
                  onPressed: () => print('下载应用'),
                  child: const Text('下载'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 评分和统计信息
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: '评分', value: '4.8 ★'),
                _StatItem(label: '下载量', value: '120万+'),
                _StatItem(label: '大小', value: '45 MB'),
                _StatItem(label: '年龄', value: '4+'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建吸顶的 TabBar
  ///
  /// 使用 SliverPersistentHeader(pinned: true) 实现吸顶效果
  SliverPersistentHeader _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        tabBar: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// 统计信息组件
// ============================================================================

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SliverPersistentHeaderDelegate —— 吸顶 TabBar 的 Delegate
// ============================================================================

/// 自定义 SliverPersistentHeaderDelegate
///
/// 关键属性：
/// - minExtent / maxExtent：定义收缩和展开时的高度
/// - build()：构建实际显示的 Widget，接收 shrinkOffset 参数
/// - shouldRebuild()：判断是否需要重建
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _StickyTabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 用 Material 包裹以提供背景色和阴影
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: shrinkOffset > 0 ? 2.0 : 0.0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

// ============================================================================
// 详情 Tab —— 展示应用描述和截图
// ============================================================================

class _DetailTab extends StatelessWidget {
  const _DetailTab();

  @override
  Widget build(BuildContext context) {
    // NestedScrollView 的 body 中直接使用 ListView
    // NestedScrollView 会自动协调内外滚动
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ---- 应用描述区域 ----
        const Text(
          '应用介绍',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '这是一款基于 Flutter 框架开发的超级应用，集成了多种强大功能。'
          '它展示了 Flutter Sliver 体系的各种高级用法，包括可折叠的应用栏、'
          '吸顶效果、内外滚动协调等特性。\n\n'
          '主要特性：\n'
          '• 流畅的滚动体验，媲美原生应用\n'
          '• Material Design 3 设计语言\n'
          '• 响应式布局，适配各种屏幕尺寸\n'
          '• 高性能懒加载列表\n'
          '• 精美的动画和过渡效果',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // ---- 应用截图区域 ----
        const Text(
          '应用截图',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // 水平滚动的截图列表
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _ScreenshotCard(index: index);
            },
          ),
        ),
        const SizedBox(height: 24),

        // ---- 新功能区域 ----
        const Text(
          '新功能',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '版本 3.0.0',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '• 全新的 Material Design 3 界面\n'
          '• 优化了列表滚动性能\n'
          '• 修复了若干已知问题\n'
          '• 新增深色模式支持',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // ---- 信息区域 ----
        const Text(
          '信息',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const _InfoRow(label: '开发者', value: 'Flutter 团队'),
        const _InfoRow(label: '类别', value: '效率工具'),
        const _InfoRow(label: '兼容性', value: 'iOS 12.0+，Android 5.0+'),
        const _InfoRow(label: '语言', value: '中文、英文等 20 种语言'),
        const _InfoRow(label: '隐私政策', value: '查看详情 →'),
      ],
    );
  }
}

/// 应用截图卡片
class _ScreenshotCard extends StatelessWidget {
  final int index;

  const _ScreenshotCard({required this.index});

  /// 截图的渐变颜色列表
  static const List<List<Color>> _gradients = [
    [Color(0xFF6A11CB), Color(0xFF2575FC)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    return Container(
      width: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          '截图 ${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 信息行组件
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 评论 Tab —— SliverList 风格的评论列表
// ============================================================================

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      // 模拟 20 条评论
      itemCount: 20,
      itemBuilder: (context, index) {
        return _ReviewCard(index: index);
      },
    );
  }
}

/// 评论卡片
class _ReviewCard extends StatelessWidget {
  final int index;

  const _ReviewCard({required this.index});

  /// 模拟评论数据
  static const List<Map<String, String>> _reviews = [
    {'user': '张三', 'comment': '非常好用的应用，界面流畅，功能丰富！强烈推荐给大家。'},
    {'user': '李四', 'comment': '用了一段时间，整体体验不错，希望能增加更多自定义选项。'},
    {'user': '王五', 'comment': 'Flutter 技术实现的效果确实很棒，滑动非常丝滑。'},
    {'user': '赵六', 'comment': '更新后比之前好了很多，特别是性能方面有明显提升。'},
    {'user': '孙七', 'comment': '设计简洁大方，使用起来很方便，期待更多功能。'},
  ];

  @override
  Widget build(BuildContext context) {
    final review = _reviews[index % _reviews.length];
    // 模拟不同评分
    final stars = (index % 3) + 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行
            Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.primaries[index % Colors.primaries.length],
                  child: Text(
                    review['user']![0],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                // 用户名
                Text(
                  review['user']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 星级评分
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 评论内容
            Text(
              review['comment']!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            // 日期
            Text(
              '2024 年 ${(index % 12) + 1} 月 ${(index % 28) + 1} 日',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 相关应用 Tab —— 使用 GridView 展示推荐应用
// ============================================================================

class _RelatedAppsTab extends StatelessWidget {
  const _RelatedAppsTab();

  /// 模拟相关应用数据
  static const List<Map<String, dynamic>> _relatedApps = [
    {'name': '代码编辑器', 'icon': Icons.code, 'color': Color(0xFF6A11CB)},
    {'name': '笔记本', 'icon': Icons.note, 'color': Color(0xFFFC466B)},
    {'name': '日历', 'icon': Icons.calendar_today, 'color': Color(0xFF11998E)},
    {'name': '天气', 'icon': Icons.cloud, 'color': Color(0xFF4FACFE)},
    {'name': '计算器', 'icon': Icons.calculate, 'color': Color(0xFFF093FB)},
    {'name': '时钟', 'icon': Icons.access_time, 'color': Color(0xFFFF6B6B)},
    {'name': '相机', 'icon': Icons.camera_alt, 'color': Color(0xFF48C6EF)},
    {'name': '音乐', 'icon': Icons.music_note, 'color': Color(0xFFF5576C)},
    {'name': '地图', 'icon': Icons.map, 'color': Color(0xFF38EF7D)},
    {'name': '通讯录', 'icon': Icons.contacts, 'color': Color(0xFF667EEA)},
    {'name': '文件管理', 'icon': Icons.folder, 'color': Color(0xFFFF9A9E)},
    {'name': '翻译', 'icon': Icons.translate, 'color': Color(0xFFA18CD1)},
  ];

  @override
  Widget build(BuildContext context) {
    // 在 NestedScrollView 的 body 中，使用 CustomScrollView
    // 可以混合 SliverToBoxAdapter 和 SliverGrid
    return CustomScrollView(
      slivers: [
        // ---- 推荐标题 ----
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '你可能还喜欢',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ---- 推荐应用网格 ----
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = _relatedApps[index % _relatedApps.length];
                return _RelatedAppCard(
                  name: app['name'] as String,
                  icon: app['icon'] as IconData,
                  color: app['color'] as Color,
                );
              },
              childCount: _relatedApps.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 0.85,
            ),
          ),
        ),
        // ---- 底部间距 ----
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
        // ---- 更多推荐标题 ----
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '热门排行',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ---- 热门列表 ----
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final app = _relatedApps[index % _relatedApps.length];
                return _RankingItem(
                  rank: index + 1,
                  name: app['name'] as String,
                  icon: app['icon'] as IconData,
                  color: app['color'] as Color,
                );
              },
              childCount: 10,
            ),
          ),
        ),
        // ---- 底部安全距离 ----
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }
}

/// 相关应用卡片
class _RelatedAppCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _RelatedAppCard({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 应用图标
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        // 应用名称
        Text(
          name,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 排行榜列表项
class _RankingItem extends StatelessWidget {
  final int rank;
  final String name;
  final IconData icon;
  final Color color;

  const _RankingItem({
    required this.rank,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // 排名序号
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.orange : Colors.grey,
              ),
            ),
          ),
          // 应用图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          // 应用信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '效率工具',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // 下载按钮
          OutlinedButton(
            onPressed: () => print('下载 $name'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('获取', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
