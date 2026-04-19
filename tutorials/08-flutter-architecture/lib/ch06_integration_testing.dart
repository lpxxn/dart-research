// =============================================================
// 第6章：集成测试 —— 示例应用
// =============================================================
//
// 本文件是一个可独立运行的计数器应用，同时在文档中讲解如何
// 为这个应用编写集成测试。
//
// 运行方式: flutter run -t lib/ch06_integration_testing.dart
// =============================================================

import 'package:flutter/material.dart';

void main() => runApp(const Ch06App());

/// 第6章示例应用 —— 一个增强版计数器，用于演示集成测试
class Ch06App extends StatelessWidget {
  const Ch06App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第6章：集成测试',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const CounterHomePage(),
    );
  }
}

// =============================================================
// 计数器首页 —— 集成测试的目标页面
// =============================================================

class CounterHomePage extends StatefulWidget {
  const CounterHomePage({super.key});

  @override
  State<CounterHomePage> createState() => _CounterHomePageState();
}

class _CounterHomePageState extends State<CounterHomePage> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);
  void _decrement() => setState(() => _counter = _counter > 0 ? _counter - 1 : 0);
  void _reset() => setState(() => _counter = 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第6章：集成测试'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          // 导航到详情页 —— 测试多页面流程
          IconButton(
            key: const Key('detail_button'),
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CounterDetailPage(count: _counter),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---- 说明区域 ----
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.integration_instructions,
                      size: 48, color: theme.colorScheme.tertiary),
                  const SizedBox(height: 8),
                  Text(
                    '集成测试示例',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这是一个计数器应用，用于演示如何编写集成测试。\n'
                    '集成测试在真实设备/模拟器上运行，验证完整的用户流程。',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ---- 计数器显示 ----
            Text(
              '当前计数',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$_counter',
              key: const Key('counter_text'),
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 32),

            // ---- 操作按钮 ----
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 减少按钮
                FloatingActionButton(
                  key: const Key('decrement_button'),
                  heroTag: 'decrement',
                  onPressed: _decrement,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                // 重置按钮
                FloatingActionButton.extended(
                  key: const Key('reset_button'),
                  heroTag: 'reset',
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置'),
                ),
                const SizedBox(width: 16),
                // 增加按钮
                FloatingActionButton(
                  key: const Key('increment_button'),
                  heroTag: 'increment',
                  onPressed: _increment,
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // ---- 集成测试代码预览 ----
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('集成测试代码示例',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CodeBlock(code: _integrationTestCode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 详情页 —— 用于测试多页面导航流程
// =============================================================

class CounterDetailPage extends StatelessWidget {
  final int count;

  const CounterDetailPage({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计数详情'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '当前计数值',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              key: const Key('detail_count'),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              count == 0
                  ? '还没有开始计数'
                  : count < 10
                      ? '刚刚开始！'
                      : count < 50
                          ? '继续加油！'
                          : '太棒了！🎉',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '提示：在集成测试中，可以验证从首页导航到此页面的流程，\n'
                '确保计数值正确传递。',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 代码展示组件
// =============================================================

class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// =============================================================
// 集成测试代码示例字符串
// =============================================================

const _integrationTestCode = '''
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_architecture/ch06_integration_testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('计数器完整流程测试', (tester) async {
    main();  // 启动应用
    await tester.pumpAndSettle();

    // 1. 验证初始状态
    expect(find.text('0'), findsOneWidget);

    // 2. 点击增加按钮 3 次
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byKey(Key('increment_button')));
      await tester.pumpAndSettle();
    }
    expect(find.text('3'), findsOneWidget);

    // 3. 点击减少按钮 1 次
    await tester.tap(find.byKey(Key('decrement_button')));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // 4. 导航到详情页
    await tester.tap(find.byKey(Key('detail_button')));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);  // 详情页也显示 2

    // 5. 返回首页
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 6. 重置
    await tester.tap(find.byKey(Key('reset_button')));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
  });
}
''';
