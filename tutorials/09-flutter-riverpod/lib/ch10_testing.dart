import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第十章：测试
// 演示：ProviderContainer 测试、Override Mock、Widget 测试
// 注：实际测试代码应在 test/ 目录下，这里用 UI 展示测试概念
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 被测试的 Provider 和 Notifier
// -----------------------------------------------------------------------------

/// 简单计数器
final counterProvider = StateProvider<int>((ref) => 0);

/// Repository 接口
abstract class TodoRepository {
  List<String> getAll();
}

/// 真实实现
class RealTodoRepository implements TodoRepository {
  @override
  List<String> getAll() => ['真实 Todo 1', '真实 Todo 2', '真实 Todo 3'];
}

/// Mock 实现
class MockTodoRepository implements TodoRepository {
  @override
  List<String> getAll() => ['Mock Todo A', 'Mock Todo B'];
}

/// Repository Provider
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return RealTodoRepository();
});

/// Todo 列表（依赖 Repository）
final todoListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return repo.getAll();
});

/// 购物车 Notifier
class CartNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addItem(String item) {
    if (item.isNotEmpty && !state.contains(item)) {
      state = [...state, item];
    }
  }

  void removeItem(String item) {
    state = state.where((i) => i != item).toList();
  }

  void clear() => state = [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<String>>(CartNotifier.new);

// -----------------------------------------------------------------------------
// 2. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch10App()));
}

class Ch10App extends StatelessWidget {
  const Ch10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch10 - 测试',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const TestDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 主页面：展示测试概念
// -----------------------------------------------------------------------------

class TestDemoPage extends StatelessWidget {
  const TestDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第十章：测试'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '单元测试'),
              Tab(text: 'Override Mock'),
              Tab(text: 'Widget 测试'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UnitTestTab(),
            _OverrideMockTab(),
            _WidgetTestTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1：单元测试演示
// -----------------------------------------------------------------------------

class _UnitTestTab extends StatefulWidget {
  const _UnitTestTab();

  @override
  State<_UnitTestTab> createState() => _UnitTestTabState();
}

class _UnitTestTabState extends State<_UnitTestTab> {
  final _results = <_TestResult>[];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() {
    _results.clear();

    // 测试 1：初始值
    _runTest('counterProvider 初始值为 0', () {
      final container = ProviderContainer();
      final result = container.read(counterProvider) == 0;
      container.dispose();
      return result;
    });

    // 测试 2：递增
    _runTest('counterProvider 递增', () {
      final container = ProviderContainer();
      container.read(counterProvider.notifier).state++;
      container.read(counterProvider.notifier).state++;
      final result = container.read(counterProvider) == 2;
      container.dispose();
      return result;
    });

    // 测试 3：CartNotifier 添加
    _runTest('CartNotifier 添加商品', () {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品B');
      final result = container.read(cartProvider).length == 2;
      container.dispose();
      return result;
    });

    // 测试 4：CartNotifier 不允许重复
    _runTest('CartNotifier 不允许重复添加', () {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品A');
      final result = container.read(cartProvider).length == 1;
      container.dispose();
      return result;
    });

    // 测试 5：CartNotifier 删除
    _runTest('CartNotifier 删除商品', () {
      final container = ProviderContainer();
      container.read(cartProvider.notifier).addItem('商品A');
      container.read(cartProvider.notifier).addItem('商品B');
      container.read(cartProvider.notifier).removeItem('商品A');
      final result =
          container.read(cartProvider).length == 1 &&
          container.read(cartProvider).first == '商品B';
      container.dispose();
      return result;
    });

    // 测试 6：监听状态变化
    _runTest('container.listen 捕获变化序列', () {
      final container = ProviderContainer();
      final values = <int>[];
      container.listen(counterProvider, (prev, next) => values.add(next));
      container.read(counterProvider.notifier).state = 1;
      container.read(counterProvider.notifier).state = 2;
      container.read(counterProvider.notifier).state = 3;
      container.dispose();
      return values.length == 3 && values[0] == 1 && values[2] == 3;
    });

    setState(() {});
  }

  void _runTest(String name, bool Function() test) {
    try {
      final passed = test();
      _results.add(_TestResult(name: name, passed: passed));
    } catch (e) {
      _results.add(_TestResult(name: name, passed: false, error: '$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.passed).length;
    final total = _results.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: passed == total ? Colors.green.shade50 : Colors.red.shade50,
          child: Row(
            children: [
              Icon(passed == total ? Icons.check_circle : Icons.error,
                  color: passed == total ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text('$passed/$total 测试通过',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => setState(() => _runTests()),
                child: const Text('重新运行'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) {
              final r = _results[i];
              return ListTile(
                leading: Icon(
                  r.passed ? Icons.check : Icons.close,
                  color: r.passed ? Colors.green : Colors.red,
                ),
                title: Text(r.name),
                subtitle: r.error != null ? Text(r.error!, style: const TextStyle(color: Colors.red)) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TestResult {
  final String name;
  final bool passed;
  final String? error;
  const _TestResult({required this.name, required this.passed, this.error});
}

// -----------------------------------------------------------------------------
// Tab 2：Override Mock 演示
// -----------------------------------------------------------------------------

class _OverrideMockTab extends StatelessWidget {
  const _OverrideMockTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('真实 Repository', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // 默认 Provider（真实实现）
          const _TodoListCard(useReal: true),
          const SizedBox(height: 24),
          Text('Mock Repository（Override）',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // ✅ Override 为 Mock 实现
          ProviderScope(
            overrides: [
              todoRepositoryProvider.overrideWithValue(MockTodoRepository()),
            ],
            child: const _TodoListCard(useReal: false),
          ),
          const SizedBox(height: 16),
          _codeBlock(
            '// 测试代码中的 Override\n'
            'final container = ProviderContainer(\n'
            '  overrides: [\n'
            '    todoRepoProvider.overrideWithValue(\n'
            '      MockTodoRepository(),\n'
            '    ),\n'
            '  ],\n'
            ');',
          ),
        ],
      ),
    );
  }
}

class _TodoListCard extends ConsumerWidget {
  final bool useReal;
  const _TodoListCard({required this.useReal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    return Card(
      child: Column(
        children: todos
            .map((t) => ListTile(
                  leading: Icon(useReal ? Icons.storage : Icons.science,
                      color: useReal ? Colors.blue : Colors.orange),
                  title: Text(t),
                ))
            .toList(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 3：Widget 测试概念
// -----------------------------------------------------------------------------

class _WidgetTestTab extends StatelessWidget {
  const _WidgetTestTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Widget 测试模板', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _codeBlock(
            "testWidgets('显示计数器', (tester) async {\n"
            "  await tester.pumpWidget(\n"
            "    const ProviderScope(\n"
            "      child: MaterialApp(home: CounterPage()),\n"
            "    ),\n"
            "  );\n"
            "\n"
            "  expect(find.text('0'), findsOneWidget);\n"
            "\n"
            "  await tester.tap(find.byIcon(Icons.add));\n"
            "  await tester.pump();\n"
            "\n"
            "  expect(find.text('1'), findsOneWidget);\n"
            "});",
          ),
          const SizedBox(height: 24),
          Text('带 Override 的 Widget 测试',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _codeBlock(
            "testWidgets('使用 Mock', (tester) async {\n"
            "  await tester.pumpWidget(\n"
            "    ProviderScope(\n"
            "      overrides: [\n"
            "        todoRepoProvider.overrideWithValue(\n"
            "          MockTodoRepository(),\n"
            "        ),\n"
            "      ],\n"
            "      child: const MaterialApp(home: TodoPage()),\n"
            "    ),\n"
            "  );\n"
            "\n"
            "  await tester.pumpAndSettle();\n"
            "  expect(find.text('Mock Todo A'), findsOneWidget);\n"
            "});",
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 测试要点', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• 每个测试创建独立的 ProviderContainer'),
                  Text('• 用 addTearDown(container.dispose) 清理'),
                  Text('• override 外部依赖（API、数据库）'),
                  Text('• 用 .future 等待异步完成'),
                  Text('• Widget 测试用 ProviderScope 包裹'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _codeBlock(String code) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Text(
      code,
      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey.shade800),
    ),
  );
}

// =============================================================================
// 知识点总结：
//
// 1. ProviderContainer：独立容器，不依赖 Widget 树，用于单元测试
// 2. container.read(provider)：读取 Provider 值
// 3. container.listen(provider, callback)：监听状态变化序列
// 4. overrides：替换 Provider 为 Mock 实现
// 5. ProviderScope overrides：Widget 测试中注入 Mock
// 6. .future：获取异步 Provider 的 Future 结果
// =============================================================================
