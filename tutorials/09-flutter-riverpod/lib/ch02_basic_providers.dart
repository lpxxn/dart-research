import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第二章：Provider 基础类型
// 演示：Provider（只读）、StateProvider（可变）、派生 Provider
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class Product {
  final String id;
  final String name;
  final double price;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });
}

// 排序方式枚举
enum SortType { name, priceLow, priceHigh }

// -----------------------------------------------------------------------------
// 2. Provider 声明
// -----------------------------------------------------------------------------

/// ✅ Provider（只读）：提供产品列表数据
final productsProvider = Provider<List<Product>>((ref) {
  return const [
    Product(id: '1', name: 'Flutter 实战', price: 79.0, category: '书籍'),
    Product(id: '2', name: 'Dart 编程', price: 59.0, category: '书籍'),
    Product(id: '3', name: '机械键盘', price: 299.0, category: '数码'),
    Product(id: '4', name: '显示器', price: 1899.0, category: '数码'),
    Product(id: '5', name: '鼠标垫', price: 39.0, category: '数码'),
    Product(id: '6', name: 'Riverpod 入门', price: 49.0, category: '书籍'),
    Product(id: '7', name: '耳机', price: 599.0, category: '数码'),
    Product(id: '8', name: 'Go 语言圣经', price: 89.0, category: '书籍'),
  ];
});

/// ✅ StateProvider：管理搜索关键词
final searchProvider = StateProvider<String>((ref) => '');

/// ✅ StateProvider：管理排序方式
final sortTypeProvider = StateProvider<SortType>((ref) => SortType.name);

/// ✅ StateProvider：管理分类筛选（null 表示全部）
final categoryFilterProvider = StateProvider<String?>((ref) => null);

/// ✅ Provider（派生）：组合搜索 + 排序 + 筛选，返回最终列表
final filteredProductsProvider = Provider<List<Product>>((ref) {
  // 监听所有依赖
  final products = ref.watch(productsProvider);
  final search = ref.watch(searchProvider);
  final sortType = ref.watch(sortTypeProvider);
  final category = ref.watch(categoryFilterProvider);

  // 1. 搜索过滤
  var result = products.where((p) {
    if (search.isNotEmpty && !p.name.contains(search)) return false;
    if (category != null && p.category != category) return false;
    return true;
  }).toList();

  // 2. 排序
  switch (sortType) {
    case SortType.name:
      result.sort((a, b) => a.name.compareTo(b.name));
    case SortType.priceLow:
      result.sort((a, b) => a.price.compareTo(b.price));
    case SortType.priceHigh:
      result.sort((a, b) => b.price.compareTo(a.price));
  }

  return result;
});

/// ✅ Provider（派生）：获取所有分类
final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider);
  return products.map((p) => p.category).toSet().toList()..sort();
});

// -----------------------------------------------------------------------------
// 3. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch02App()));
}

class Ch02App extends StatelessWidget {
  const Ch02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch02 - Provider 基础类型',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ProductListPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. 产品列表页面
// -----------------------------------------------------------------------------

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);
    final sortType = ref.watch(sortTypeProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('第二章：Provider 基础类型')),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索产品...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // 修改 StateProvider 的值
                ref.read(searchProvider.notifier).state = value;
              },
            ),
          ),

          // 分类筛选 Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('分类：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                // "全部" 选项
                FilterChip(
                  label: const Text('全部'),
                  selected: selectedCategory == null,
                  onSelected: (_) {
                    ref.read(categoryFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                // 各分类选项
                ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (_) {
                          ref.read(categoryFilterProvider.notifier).state =
                              selectedCategory == cat ? null : cat;
                        },
                      ),
                    )),
              ],
            ),
          ),

          // 排序选择
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('排序：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                SegmentedButton<SortType>(
                  segments: const [
                    ButtonSegment(value: SortType.name, label: Text('名称')),
                    ButtonSegment(value: SortType.priceLow, label: Text('价格↑')),
                    ButtonSegment(value: SortType.priceHigh, label: Text('价格↓')),
                  ],
                  selected: {sortType},
                  onSelectionChanged: (selected) {
                    ref.read(sortTypeProvider.notifier).state = selected.first;
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // 结果数量
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('共 ${products.length} 件商品',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),

          // 产品列表
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('没有找到匹配的产品'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(product.name[0]),
                          ),
                          title: Text(product.name),
                          subtitle: Text(product.category),
                          trailing: Text(
                            '¥${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. Provider（只读）：提供常量数据、工具类实例、派生计算值
// 2. StateProvider（可变）：管理简单状态（int、bool、String、enum）
// 3. 派生 Provider：通过 ref.watch 依赖其他 Provider，自动重新计算
// 4. .notifier.state = xxx：修改 StateProvider 的值
// 5. 多个 Provider 组合：搜索 + 排序 + 筛选 → 最终列表
// =============================================================================
