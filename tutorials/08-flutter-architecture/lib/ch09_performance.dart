// =============================================================
// 第9章：性能优化 —— 对比示例
// =============================================================
//
// 本文件展示各种性能优化技巧的对比效果，
// 包括 const Widget、RepaintBoundary、ListView 优化、Isolate 等。
//
// 运行方式: flutter run -t lib/ch09_performance.dart
// =============================================================

import 'dart:isolate';
import 'package:flutter/material.dart';

void main() => runApp(const Ch09App());

class Ch09App extends StatelessWidget {
  const Ch09App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第9章：性能优化',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const PerformanceDemoPage(),
    );
  }
}

// =============================================================
// 主演示页面 —— Tab 切换各种优化对比
// =============================================================

class PerformanceDemoPage extends StatelessWidget {
  const PerformanceDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第9章：性能优化'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.speed), text: 'const 优化'),
              Tab(icon: Icon(Icons.border_all), text: 'RepaintBoundary'),
              Tab(icon: Icon(Icons.list), text: 'ListView'),
              Tab(icon: Icon(Icons.memory), text: 'Isolate'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ConstWidgetDemo(),
            _RepaintBoundaryDemo(),
            _ListViewDemo(),
            _IsolateDemo(),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 一、const Widget 优化对比
// =============================================================

class _ConstWidgetDemo extends StatefulWidget {
  const _ConstWidgetDemo();

  @override
  State<_ConstWidgetDemo> createState() => _ConstWidgetDemoState();
}

class _ConstWidgetDemoState extends State<_ConstWidgetDemo> {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明卡片
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('const Widget 原理',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '• const Widget 在编译期创建，运行时不重新分配内存\n'
                    '• Flutter 可以跳过 const 子树的重建\n'
                    '• 点击下方按钮触发 setState，观察 build 计数',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 触发重建的按钮
          Center(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _rebuildCount++),
              icon: const Icon(Icons.refresh),
              label: Text('触发 setState (第 $_rebuildCount 次)'),
            ),
          ),

          const SizedBox(height: 16),

          // ❌ 非 const —— 每次 setState 都重建
          _buildComparisonCard(
            theme,
            title: '❌ 非 const Widget',
            subtitle: '每次 setState 都会重新创建',
            code: "Text('Hello')  // 每次 build 创建新实例",
            color: Colors.red,
            child: _NonConstWidget(rebuildCount: _rebuildCount),
          ),

          const SizedBox(height: 12),

          // ✅ const —— 跳过重建
          _buildComparisonCard(
            theme,
            title: '✅ const Widget',
            subtitle: '编译期创建，build 时复用',
            code: "const Text('Hello')  // 始终同一个实例",
            color: Colors.green,
            child: const _ConstWidget(),
          ),

          const SizedBox(height: 16),

          // 最佳实践
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 最佳实践', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 给所有可能的 Widget 添加 const\n'
                    '2. 给自定义 Widget 添加 const 构造函数\n'
                    '3. 将不变的部分提取为独立 const Widget\n'
                    '4. 开启 lint 规则: prefer_const_constructors',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String code,
    required Color color,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: color),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// 非 const Widget —— 每次父级 build 都重新创建
class _NonConstWidget extends StatelessWidget {
  final int rebuildCount;

  const _NonConstWidget({required this.rebuildCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text('已重建 $rebuildCount 次',
              style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

/// const Widget —— 编译期创建，不随父级重建
class _ConstWidget extends StatelessWidget {
  const _ConstWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text('我是 const，不会随 setState 重建',
              style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

// =============================================================
// 二、RepaintBoundary 演示
// =============================================================

class _RepaintBoundaryDemo extends StatefulWidget {
  const _RepaintBoundaryDemo();

  @override
  State<_RepaintBoundaryDemo> createState() => _RepaintBoundaryDemoState();
}

class _RepaintBoundaryDemoState extends State<_RepaintBoundaryDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RepaintBoundary 原理',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '• RepaintBoundary 创建独立的绘制图层\n'
                    '• 将频繁变化的区域与静态区域隔离\n'
                    '• 减少不必要的重绘，提升性能\n'
                    '• 下方动画条展示了有无 RepaintBoundary 的区别',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ❌ 无 RepaintBoundary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('❌ 无 RepaintBoundary',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('动画导致整个卡片区域都需要重绘',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const _HeavyWidget(label: '静态内容 A（被迫重绘 😩）'),
                  const SizedBox(height: 4),
                  // 动画进度条
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: _controller.value,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const _HeavyWidget(label: '静态内容 B（被迫重绘 😩）'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 有 RepaintBoundary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('✅ 有 RepaintBoundary',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('动画被隔离，静态区域不重绘',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const _HeavyWidget(label: '静态内容 A（不受影响 ✅）'),
                  const SizedBox(height: 4),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: _controller.value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _HeavyWidget(label: '静态内容 B（不受影响 ✅）'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 使用场景', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 频繁动画的 Widget 周围\n'
                    '2. 复杂列表项中的每一项\n'
                    '3. 静态不变的复杂图表\n'
                    '4. 不要过度使用（每个 boundary 有内存开销）',
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

/// 模拟一个"重"的静态 Widget
class _HeavyWidget extends StatelessWidget {
  final String label;

  const _HeavyWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// =============================================================
// 三、ListView 优化对比
// =============================================================

class _ListViewDemo extends StatelessWidget {
  const _ListViewDemo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ListView 优化', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '• ListView() 一次性构建所有子项\n'
                    '• ListView.builder() 按需构建可见区域的子项\n'
                    '• itemExtent 跳过高度计算，提升滚动性能\n'
                    '• 对 10000 条数据，差异非常明显',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ❌ 错误方式
          _buildCodeCard(
            theme,
            title: '❌ ListView() —— 全量构建',
            code: 'ListView(\n'
                '  children: List.generate(10000,\n'
                '    (i) => ListTile(title: Text("Item \$i")),\n'
                '  ),\n'
                ')',
            description: '一次性创建 10000 个 Widget，内存占用大，初始化慢',
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          // ✅ 正确方式
          _buildCodeCard(
            theme,
            title: '✅ ListView.builder() —— 按需构建',
            code: 'ListView.builder(\n'
                '  itemCount: 10000,\n'
                '  itemBuilder: (context, index) {\n'
                '    return ListTile(title: Text("Item \$index"));\n'
                '  },\n'
                ')',
            description: '只构建屏幕可见区域的 Widget，滚动时动态创建/回收',
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          // ✅✅ 最优方式
          _buildCodeCard(
            theme,
            title: '✅✅ ListView.builder() + itemExtent',
            code: 'ListView.builder(\n'
                '  itemCount: 10000,\n'
                '  itemExtent: 56.0,  // 固定高度\n'
                '  itemBuilder: (context, index) {\n'
                '    return ListTile(title: Text("Item \$index"));\n'
                '  },\n'
                ')',
            description: '固定高度跳过逐项测量，滚动计算更快',
            color: Colors.green.shade800,
          ),

          const SizedBox(height: 16),

          // 实际列表预览
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 ListView.builder 示例（100 项）',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: 100,
                      itemExtent: 48,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text('${index + 1}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                          title: Text('Item ${index + 1}',
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text('只有可见项会被构建',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.outline)),
                        );
                      },
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

  Widget _buildCodeCard(
    ThemeData theme, {
    required String title,
    required String code,
    required String description,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 四、Isolate 并发演示
// =============================================================

class _IsolateDemo extends StatefulWidget {
  const _IsolateDemo();

  @override
  State<_IsolateDemo> createState() => _IsolateDemoState();
}

class _IsolateDemoState extends State<_IsolateDemo> {
  String _mainThreadResult = '等待运行...';
  String _isolateResult = '等待运行...';
  bool _isRunningMain = false;
  bool _isRunningIsolate = false;

  // 模拟耗时计算 —— 计算前 N 个质数
  static List<int> _findPrimes(int count) {
    final primes = <int>[];
    int candidate = 2;
    while (primes.length < count) {
      bool isPrime = true;
      for (int i = 2; i * i <= candidate; i++) {
        if (candidate % i == 0) {
          isPrime = false;
          break;
        }
      }
      if (isPrime) primes.add(candidate);
      candidate++;
    }
    return primes;
  }

  // ❌ 在主线程上计算
  Future<void> _runOnMainThread() async {
    setState(() {
      _isRunningMain = true;
      _mainThreadResult = '计算中...（UI 可能卡顿）';
    });

    final stopwatch = Stopwatch()..start();
    final primes = _findPrimes(50000);
    stopwatch.stop();

    setState(() {
      _isRunningMain = false;
      _mainThreadResult =
          '找到 ${primes.length} 个质数\n'
          '最大: ${primes.last}\n'
          '耗时: ${stopwatch.elapsedMilliseconds}ms\n'
          '⚠️ 计算期间 UI 被阻塞';
    });
  }

  // ✅ 在 Isolate 中计算
  Future<void> _runOnIsolate() async {
    setState(() {
      _isRunningIsolate = true;
      _isolateResult = '计算中...（UI 保持流畅）';
    });

    final stopwatch = Stopwatch()..start();
    final primes = await Isolate.run(() => _findPrimes(50000));
    stopwatch.stop();

    setState(() {
      _isRunningIsolate = false;
      _isolateResult =
          '找到 ${primes.length} 个质数\n'
          '最大: ${primes.last}\n'
          '耗时: ${stopwatch.elapsedMilliseconds}ms\n'
          '✅ 计算期间 UI 保持流畅';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Isolate 并发计算',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '• Flutter UI 运行在主 Isolate 上\n'
                    '• 耗时计算会阻塞 UI，导致卡顿\n'
                    '• Isolate.run() 在后台线程执行计算\n'
                    '• 下方演示：找前 50000 个质数',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 动画指示器 —— 用来观察 UI 是否卡顿
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('🎯 UI 流畅度指示器',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text('如果下方动画卡住，说明主线程被阻塞',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  const _SmoothAnimation(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 主线程计算
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('❌ 主线程计算',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_mainThreadResult),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isRunningMain ? null : _runOnMainThread,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100),
                    child: Text(
                        _isRunningMain ? '计算中...' : '在主线程计算'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Isolate 计算
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 12, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('✅ Isolate 计算',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_isolateResult),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isRunningIsolate ? null : _runOnIsolate,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100),
                    child: Text(
                        _isRunningIsolate ? '计算中...' : '在 Isolate 计算'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 使用建议
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 何时使用 Isolate',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '✅ 需要：大量 JSON 解析、图片处理、加密解密、复杂算法\n'
                    '❌ 不需要：网络请求（已异步）、少量数据处理、文件 I/O\n\n'
                    '使用方法：\n'
                    '  final result = await Isolate.run(() {\n'
                    '    return heavyComputation(data);\n'
                    '  });',
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

/// 流畅动画指示器 —— 用于直观观察 UI 是否卡顿
class _SmoothAnimation extends StatefulWidget {
  const _SmoothAnimation();

  @override
  State<_SmoothAnimation> createState() => _SmoothAnimationState();
}

class _SmoothAnimationState extends State<_SmoothAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            LinearProgressIndicator(value: _controller.value),
            const SizedBox(height: 8),
            Transform.translate(
              offset: Offset(_controller.value * 200 - 100, 0),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
