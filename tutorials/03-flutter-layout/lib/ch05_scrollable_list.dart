// 第五章：滚动列表 —— 商品列表示例
// 演示 ListView.builder、GridView、ScrollController、下拉刷新与无限滚动加载

import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const Ch05App());

/// 应用入口
class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第五章：滚动列表',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const ProductHomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// 数据模型
// ---------------------------------------------------------------------------

/// 商品数据模型
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.color,
    required this.icon,
  });

  final int id;
  final String name;
  final double price;
  final String description;
  final Color color;
  final IconData icon;
}

/// 模拟生成商品数据
List<Product> generateProducts(int start, int count) {
  final random = Random(start);
  const names = ['蓝牙耳机', '机械键盘', '显示器', '鼠标垫', '摄像头', '充电器', 'USB 集线器', '平板支架'];
  const icons = [
    Icons.headphones,
    Icons.keyboard,
    Icons.monitor,
    Icons.mouse,
    Icons.videocam,
    Icons.battery_charging_full,
    Icons.usb,
    Icons.tablet_mac,
  ];

  return List.generate(count, (i) {
    final idx = (start + i) % names.length;
    return Product(
      id: start + i,
      name: '${names[idx]} #${start + i}',
      price: (random.nextInt(900) + 100).toDouble(),
      description: '这是一款优质的${names[idx]}，编号 ${start + i}',
      color: Colors.primaries[(start + i) % Colors.primaries.length],
      icon: icons[idx],
    );
  });
}

// ---------------------------------------------------------------------------
// 首页 —— 底部导航切换列表视图和网格视图
// ---------------------------------------------------------------------------

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({super.key});

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  int _currentIndex = 0;

  // 页面列表（使用 IndexedStack 保持状态）
  static const List<Widget> _pages = [
    ProductListPage(),
    ProductGridPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // 底部导航栏切换列表 / 网格
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            selectedIcon: Icon(Icons.list_alt),
            label: '商品列表',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '商品网格',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 页面一：商品列表（ListView.builder + 下拉刷新 + 无限滚动）
// ---------------------------------------------------------------------------

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  /// 滚动控制器 —— 用于监听滚动位置与回到顶部
  final ScrollController _scrollController = ScrollController();

  /// 商品数据
  List<Product> _products = [];

  /// 当前页码
  int _page = 0;

  /// 每页加载数量
  static const int _pageSize = 15;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否还有更多数据
  bool _hasMore = true;

  /// 是否显示"回到顶部"按钮
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // 首次加载数据
    _loadMore();
    // 监听滚动位置
    _scrollController.addListener(_onScroll);
  }

  /// 滚动监听回调
  void _onScroll() {
    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;

    // 显示/隐藏"回到顶部"按钮
    final shouldShow = offset > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }

    // 距底部不足 200 像素时触发加载更多
    if (maxExtent - offset < 200) {
      _loadMore();
    }
  }

  /// 加载更多数据
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // 模拟网络延迟
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final newProducts = generateProducts(_page * _pageSize, _pageSize);

    if (!mounted) return;
    setState(() {
      _page++;
      _products.addAll(newProducts);
      _isLoading = false;
      // 模拟最多 5 页数据
      _hasMore = _page < 5;
    });
  }

  /// 下拉刷新 —— 重置数据并重新加载
  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _page = 0;
      _products = [];
      _hasMore = true;
    });
    await _loadMore();
  }

  /// 动画滚动到顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品列表'),
        centerTitle: true,
      ),
      // 下拉刷新包裹 ListView
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        child: ListView.builder(
          controller: _scrollController,
          // 即使内容不足也允许下拉刷新
          physics: const AlwaysScrollableScrollPhysics(),
          // 列表项数 + 底部加载指示器
          itemCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 最后一项：加载指示器
            if (index == _products.length) {
              return const _LoadingIndicator();
            }
            return _ProductListTile(product: _products[index]);
          },
        ),
      ),
      // "回到顶部"悬浮按钮
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: '回到顶部',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// 页面二：商品网格（GridView.builder）
// ---------------------------------------------------------------------------

class ProductGridPage extends StatefulWidget {
  const ProductGridPage({super.key});

  @override
  State<ProductGridPage> createState() => _ProductGridPageState();
}

class _ProductGridPageState extends State<ProductGridPage> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent - _scrollController.offset < 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    await Future<void>.delayed(const Duration(milliseconds: 800));
    final newProducts = generateProducts(_page * 12, 12);

    if (!mounted) return;
    setState(() {
      _page++;
      _products.addAll(newProducts);
      _isLoading = false;
      _hasMore = _page < 5;
    });
  }

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _page = 0;
      _products = [];
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品网格'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 网格主体
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _ProductGridCard(product: _products[index]);
                  },
                  childCount: _products.length,
                ),
              ),
            ),
            // 底部加载指示器
            if (_hasMore)
              const SliverToBoxAdapter(child: _LoadingIndicator()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 可复用组件
// ---------------------------------------------------------------------------

/// 列表页的商品卡片
class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 商品图标占位
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                // 使用 withValues 替代 withOpacity
                color: product.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(product.icon, color: product.color, size: 32),
            ),
            const SizedBox(width: 12),
            // 商品信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 价格标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '¥${product.price.toStringAsFixed(0)}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 网格页的商品卡片
class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 商品图标区域
          Expanded(
            flex: 3,
            child: Container(
              color: product.color.withValues(alpha: 0.12),
              child: Icon(product.icon, size: 48, color: product.color),
            ),
          ),
          // 商品信息区域
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部加载指示器
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
