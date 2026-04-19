import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 第1章：导航基础
/// 演示 Navigator.push/pop、传参、返回值、PopScope 拦截返回
void main() => runApp(const Ch01App());

class Ch01App extends StatelessWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第1章：导航基础',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// =============================================================================
// 商品数据模型
// =============================================================================

class Product {
  final int id;
  final String name;
  final String description;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}

/// 模拟商品列表数据
const List<Product> _products = [
  Product(id: 1, name: 'Flutter 实战', description: '全面讲解 Flutter 开发技术', price: 79.0),
  Product(id: 2, name: 'Dart 编程语言', description: '深入理解 Dart 语言特性', price: 59.0),
  Product(id: 3, name: 'Widget 大全', description: '常用 Widget 速查手册', price: 49.0),
];

// =============================================================================
// 首页 — 展示商品列表，演示 push 跳转和接收返回值
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _lastResult = '暂无评分结果';

  /// 跳转到详情页，并等待返回结果
  Future<void> _navigateToDetail(Product product) async {
    // Navigator.push 返回 Future，await 可以接收 pop 时传递的值
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(product: product),
      ),
    );

    // 检查 mounted 防止在异步操作后 Widget 已被销毁
    if (result != null && mounted) {
      setState(() {
        _lastResult = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收到评分: $result')),
      );
    }
  }

  /// 跳转到编辑页，演示 CupertinoPageRoute 和 fullscreenDialog
  void _navigateToEdit() {
    // 使用 CupertinoPageRoute 实现 iOS 风格的页面过渡动画
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const EditPage(),
        fullscreenDialog: true, // 全屏对话框模式，AppBar 显示关闭按钮
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第1章：导航基础'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 显示上次的评分结果
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '上次评分结果: $_lastResult',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          // 商品列表
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${product.id}')),
                  title: Text(product.name),
                  subtitle: Text('¥${product.price.toStringAsFixed(0)} - ${product.description}'),
                  trailing: const Icon(Icons.chevron_right),
                  // 点击跳转到详情页，通过构造函数传参
                  onTap: () => _navigateToDetail(product),
                );
              },
            ),
          ),
        ],
      ),
      // 编辑按钮 — 演示 CupertinoPageRoute + fullscreenDialog
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEdit,
        tooltip: '编辑（演示 PopScope）',
        child: const Icon(Icons.edit),
      ),
    );
  }
}

// =============================================================================
// 详情页 — 接收构造函数参数，通过 pop 返回评分结果
// =============================================================================

class DetailPage extends StatefulWidget {
  /// 通过构造函数接收参数（类型安全，推荐方式）
  final Product product;

  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品信息
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '价格: ¥${widget.product.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 40),

            // 评分选择
            Text('请为商品评分:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text('当前评分: $_rating 星'),
            const Spacer(),

            // 提交评分并返回 — 通过 Navigator.pop 传递返回值
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // pop 时传递评分结果给上一页面
                  Navigator.pop(
                    context,
                    '${widget.product.name} - $_rating 星',
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('提交评分并返回'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 编辑页 — 演示 PopScope 拦截返回
// =============================================================================

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController _controller = TextEditingController();
  bool _hasUnsavedChanges = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 显示退出确认对话框
  Future<void> _showExitConfirmDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出？'),
        content: const Text('你有未保存的内容，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );

    // 用户确认退出后，手动 pop
    if (shouldExit == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope 替代已弃用的 WillPopScope
    return PopScope(
      // canPop: false 表示拦截返回操作
      // 当有未保存内容时拦截，否则允许直接返回
      canPop: !_hasUnsavedChanges,
      // 当用户尝试返回时触发
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // 如果已经 pop 了（canPop 为 true 的情况），不再处理
        if (didPop) return;
        // 显示确认对话框
        _showExitConfirmDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑页面（PopScope 演示）'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PopScope 拦截返回演示',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('输入内容后，按返回键会弹出确认对话框。\n清空内容后可以直接返回。'),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '输入一些内容...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    // 根据是否有内容动态控制 canPop
                    _hasUnsavedChanges = value.isNotEmpty;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                _hasUnsavedChanges ? '⚠️ 有未保存的内容，返回会弹出确认' : '✅ 无未保存内容，可以直接返回',
                style: TextStyle(
                  color: _hasUnsavedChanges ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 模拟保存操作
                    setState(() => _hasUnsavedChanges = false);
                    _controller.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已保存！现在可以安全返回')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
