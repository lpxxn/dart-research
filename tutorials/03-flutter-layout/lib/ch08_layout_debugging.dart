// 第八章：布局调试示例
// 演示常见布局错误及其修复方案，以及调试工具的使用

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const LayoutDebuggingApp());

/// 布局调试示例应用
class LayoutDebuggingApp extends StatelessWidget {
  const LayoutDebuggingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第八章：布局调试',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LayoutDebuggingHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主页面，使用 TabBar 展示不同的调试示例
class LayoutDebuggingHome extends StatefulWidget {
  const LayoutDebuggingHome({super.key});

  @override
  State<LayoutDebuggingHome> createState() => _LayoutDebuggingHomeState();
}

class _LayoutDebuggingHomeState extends State<LayoutDebuggingHome>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // 调试标志状态
  bool _paintSizeEnabled = false;
  bool _paintBaselinesEnabled = false;
  bool _repaintRainbowEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 退出时重置调试标志
    debugPaintSizeEnabled = false;
    debugPaintBaselinesEnabled = false;
    debugRepaintRainbowEnabled = false;
    super.dispose();
  }

  /// 切换调试标志并刷新界面
  void _toggleDebugFlag(String flag) {
    setState(() {
      switch (flag) {
        case 'size':
          _paintSizeEnabled = !_paintSizeEnabled;
          debugPaintSizeEnabled = _paintSizeEnabled;
        case 'baselines':
          _paintBaselinesEnabled = !_paintBaselinesEnabled;
          debugPaintBaselinesEnabled = _paintBaselinesEnabled;
        case 'repaint':
          _repaintRainbowEnabled = !_repaintRainbowEnabled;
          debugRepaintRainbowEnabled = _repaintRainbowEnabled;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第八章：布局调试'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '1. Overflow'),
            Tab(text: '2. 无限高度'),
            Tab(text: '3. 无限宽度'),
            Tab(text: '4. OverflowBar'),
            Tab(text: '5. RepaintBoundary'),
          ],
        ),
        actions: [
          // 调试标志切换菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.bug_report),
            tooltip: '调试工具',
            onSelected: _toggleDebugFlag,
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'size',
                checked: _paintSizeEnabled,
                child: const Text('debugPaintSizeEnabled'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'baselines',
                checked: _paintBaselinesEnabled,
                child: const Text('debugPaintBaselinesEnabled'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'repaint',
                checked: _repaintRainbowEnabled,
                child: const Text('debugRepaintRainbowEnabled'),
              ),
            ],
          ),
          // 打印渲染树按钮
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: '打印渲染树',
            onPressed: () {
              debugDumpRenderTree();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('渲染树已打印到控制台'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OverflowDemo(),
          UnboundedHeightDemo(),
          InfiniteWidthDemo(),
          OverflowBarDemo(),
          RepaintBoundaryDemo(),
        ],
      ),
    );
  }
}

// ============================================================
// 通用组件
// ============================================================

/// 问题/修复切换组件
/// 每个示例都包含"问题描述"和"修复版本"两个视图
class ProblemFixToggle extends StatefulWidget {
  final String problemTitle;
  final String problemDescription;
  final String errorMessage;
  final String problemCode;
  final String fixTitle;
  final Widget fixWidget;

  const ProblemFixToggle({
    super.key,
    required this.problemTitle,
    required this.problemDescription,
    required this.errorMessage,
    required this.problemCode,
    required this.fixTitle,
    required this.fixWidget,
  });

  @override
  State<ProblemFixToggle> createState() => _ProblemFixToggleState();
}

class _ProblemFixToggleState extends State<ProblemFixToggle> {
  bool _showFix = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 切换开关
          Card(
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _showFix ? Icons.check_circle : Icons.error,
                    color: _showFix
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _showFix ? '✅ 修复版本' : '❌ 问题描述',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Switch(
                    value: _showFix,
                    onChanged: (value) => setState(() => _showFix = value),
                  ),
                  Text(
                    _showFix ? '修复' : '问题',
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 内容区域
          Expanded(
            child: _showFix ? _buildFixView() : _buildProblemView(context),
          ),
        ],
      ),
    );
  }

  /// 构建问题描述视图（用 Card 展示错误信息和代码，不实际运行错误代码）
  Widget _buildProblemView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 问题标题和描述
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.problemTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.problemDescription),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 错误信息卡片
          Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Text(
                        '错误信息',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.errorMessage,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 问题代码卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '问题代码',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.problemCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
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

  /// 构建修复后的实际运行 Widget
  Widget _buildFixView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  widget.fixTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            Expanded(child: widget.fixWidget),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 示例 1：RenderFlex Overflow
// ============================================================

/// 演示 RenderFlex overflow 错误及修复
class OverflowDemo extends StatelessWidget {
  const OverflowDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ProblemFixToggle(
      problemTitle: 'RenderFlex Overflowed',
      problemDescription:
          '当 Row 或 Column 中的子元素总尺寸超过可用空间时，'
          '会出现黄黑条纹的溢出警告。这是 Flutter 中最常见的布局错误。',
      errorMessage:
          'A RenderFlex overflowed by 42 pixels on the right.\n\n'
          'The relevant error-causing widget was:\n'
          '  Row\n\n'
          'The overflowing RenderFlex has an orientation of\n'
          'Axis.horizontal.',
      problemCode: '''// ❌ 子元素总宽度超过屏幕
Row(
  children: [
    Container(width: 200, height: 50, color: Colors.red),
    Container(width: 200, height: 50, color: Colors.blue),
    Container(width: 200, height: 50, color: Colors.green),
  ],
)''',
      fixTitle: '修复方案：使用 Expanded + SingleChildScrollView + Wrap',
      fixWidget: const _OverflowFixWidget(),
    );
  }
}

class _OverflowFixWidget extends StatelessWidget {
  const _OverflowFixWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 方案一：Expanded
          const Text('方案一：使用 Expanded 均分空间',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  color: Colors.red.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('Expanded', style: TextStyle(color: Colors.white)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  color: Colors.blue.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('Expanded', style: TextStyle(color: Colors.white)),
                ),
              ),
              Expanded(
                child: Container(
                  height: 50,
                  color: Colors.green.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('Expanded', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 方案二：SingleChildScrollView
          const Text('方案二：使用 SingleChildScrollView 允许滚动',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  width: 200, height: 50,
                  color: Colors.red.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('200px', style: TextStyle(color: Colors.white)),
                ),
                Container(
                  width: 200, height: 50,
                  color: Colors.blue.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('200px', style: TextStyle(color: Colors.white)),
                ),
                Container(
                  width: 200, height: 50,
                  color: Colors.green.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: const Text('200px（← 水平滚动）',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 方案三：Wrap
          const Text('方案三：使用 Wrap 自动换行',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                width: 150, height: 50,
                color: Colors.red.withValues(alpha: 0.7),
                alignment: Alignment.center,
                child: const Text('150px', style: TextStyle(color: Colors.white)),
              ),
              Container(
                width: 150, height: 50,
                color: Colors.blue.withValues(alpha: 0.7),
                alignment: Alignment.center,
                child: const Text('150px', style: TextStyle(color: Colors.white)),
              ),
              Container(
                width: 150, height: 50,
                color: Colors.green.withValues(alpha: 0.7),
                alignment: Alignment.center,
                child: const Text('150px（自动换行）',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 示例 2：Unbounded Height（无限高度）
// ============================================================

/// 演示 ListView 在 Column 中的无限高度错误
class UnboundedHeightDemo extends StatelessWidget {
  const UnboundedHeightDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ProblemFixToggle(
      problemTitle: 'Unbounded Height（无限高度）',
      problemDescription:
          'ListView 在滚动方向上会扩展到无限大。当它被放在 Column 中且没有'
          '高度约束时，就会出现此错误。这是初学者第二常见的布局错误。',
      errorMessage:
          'Vertical viewport was given unbounded height.\n\n'
          'Viewports expand in the scrolling direction to fill their\n'
          'container. In this case, a vertical viewport was given an\n'
          'unlimited amount of vertical space in which to expand.\n\n'
          'This situation typically happens when a scrollable widget\n'
          'is nested inside another scrollable widget.',
      problemCode: '''// ❌ Column 不限制 ListView 的高度
Column(
  children: [
    Text('标题'),
    ListView(  // 需要有限高度约束！
      children: [
        ListTile(title: Text('项目 1')),
        ListTile(title: Text('项目 2')),
        // ...
      ],
    ),
  ],
)''',
      fixTitle: '修复方案：Expanded / SizedBox / shrinkWrap',
      fixWidget: const _UnboundedHeightFixWidget(),
    );
  }
}

class _UnboundedHeightFixWidget extends StatelessWidget {
  const _UnboundedHeightFixWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 方案一：Expanded
          const Text('方案一：用 Expanded 包裹 ListView',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            // 模拟 Column + Expanded + ListView 的效果
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: colorScheme.primaryContainer,
                  child: Text('标题栏（固定高度）',
                      style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) => ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('Expanded 包裹的列表项 ${index + 1}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 方案二：SizedBox
          const Text('方案二：用 SizedBox 限制固定高度',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                leading: Icon(Icons.list, color: colorScheme.primary),
                title: Text('SizedBox 限高的列表项 ${index + 1}'),
                dense: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 方案三：shrinkWrap
          const Text('方案三：shrinkWrap: true（适合少量数据）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '⚠️ 注意：shrinkWrap 会失去懒加载优势，不推荐用于大量数据',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              3,
              (index) => ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('shrinkWrap 列表项 ${index + 1}'),
                subtitle: const Text('此列表不会滚动'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 示例 3：Infinite Width（无限宽度）
// ============================================================

/// 演示嵌套 Flex 导致的无限宽度错误
class InfiniteWidthDemo extends StatelessWidget {
  const InfiniteWidthDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ProblemFixToggle(
      problemTitle: 'BoxConstraints Forces an Infinite Width',
      problemDescription:
          '当嵌套使用弹性布局 Widget（如 Row 内嵌 Row、Column 内放 ListView）时，'
          '内层 Widget 可能获得无限的宽度或高度约束，从而导致错误。',
      errorMessage:
          'BoxConstraints forces an infinite width.\n\n'
          'These invalid constraints were provided to\n'
          "RenderDecoratedBox's layout() by RenderConstrainedBox.\n\n"
          'The relevant error-causing widget was:\n'
          '  Row\n\n'
          'The constraints that applied were:\n'
          '  BoxConstraints(0.0<=w<=Infinity, 0.0<=h<=600.0)',
      problemCode: '''// ❌ Row 内嵌 Row，内层 Row 没有宽度约束
Row(
  children: [
    Row(  // 获得无限宽度！
      children: [Text('嵌套内容')],
    ),
  ],
)

// ❌ Row 中 Container 无约束
Row(
  children: [
    Container(
      color: Colors.red,
      child: Text('很长的文字会导致溢出...'),
    ),
  ],
)''',
      fixTitle: '修复方案：使用 Expanded / Flexible 提供约束',
      fixWidget: const _InfiniteWidthFixWidget(),
    );
  }
}

class _InfiniteWidthFixWidget extends StatelessWidget {
  const _InfiniteWidthFixWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 修复 1：Row 嵌套 Row
          const Text('修复一：Row 嵌套 Row → 用 Expanded 包裹内层 Row',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  color: colorScheme.primaryContainer,
                  alignment: Alignment.center,
                  child: const Text('固定'),
                ),
                const SizedBox(width: 8),
                // 用 Expanded 包裹内层 Row
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          color: colorScheme.tertiaryContainer,
                          alignment: Alignment.center,
                          child: const Text('内层 A'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 40,
                          color: colorScheme.secondaryContainer,
                          alignment: Alignment.center,
                          child: const Text('内层 B'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 修复 2：长文本在 Row 中
          const Text('修复二：Row 中长文本 → 用 Expanded 包裹',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: colorScheme.surfaceContainerHighest,
                    child: const Text(
                      '这是一段很长很长很长很长很长的文字，'
                      '如果不用 Expanded 包裹会导致溢出错误，'
                      '使用 Expanded 后文字会自动换行或截断。',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 修复 3：Column 中嵌套 ListView
          const Text('修复三：Column 中 ListView → 用 Expanded 包裹',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: colorScheme.primaryContainer,
                  child: const Text('Column 中的标题'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 15,
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      title: Text('列表项 ${index + 1}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 嵌套规则提示
          Card(
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 嵌套规则速查',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Column → ListView → 用 Expanded 包裹\n'
                    '• Row → Row → 用 Expanded 包裹内层\n'
                    '• Row → 长文本 → 用 Expanded 包裹\n'
                    '• ListView → ListView → shrinkWrap + NeverScrollable',
                    style: TextStyle(
                      color: colorScheme.onTertiaryContainer,
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

// ============================================================
// 示例 4：OverflowBar 用法
// ============================================================

/// 演示 OverflowBar 的智能溢出处理
class OverflowBarDemo extends StatelessWidget {
  const OverflowBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 说明卡片
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OverflowBar 介绍',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当子元素在水平方向放不下时，OverflowBar 会自动切换为垂直排列。'
                    '它是 ButtonBar（已废弃）的推荐替代品。\n\n'
                    '提示：调整窗口宽度，观察按钮如何自动从水平排列变为垂直排列。',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 示例 1：基本用法
          const Text('基本用法',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OverflowBar(
                spacing: 8,
                overflowSpacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {},
                    child: const Text('保存'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('重置'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 示例 2：多个按钮（更容易触发溢出）
          const Text('多按钮溢出场景',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OverflowBar(
                spacing: 8,
                overflowSpacing: 8,
                overflowAlignment: OverflowBarAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('编辑'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete),
                    label: const Text('删除'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.copy),
                    label: const Text('复制链接'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark),
                    label: const Text('收藏'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 示例 3：在对话框风格中使用
          const Text('对话框风格',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('确认删除',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('确定要删除这个项目吗？此操作不可撤销。'),
                  const SizedBox(height: 16),
                  OverflowBar(
                    spacing: 8,
                    overflowSpacing: 8,
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('稍后再说'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: const Text('确认删除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 对比代码说明
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 代码对比',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      '// ❌ 已废弃\n'
                      'ButtonBar(children: [...])\n'
                      '\n'
                      '// ✅ 推荐\n'
                      'OverflowBar(\n'
                      '  spacing: 8,\n'
                      '  overflowSpacing: 8,\n'
                      '  children: [...],\n'
                      ')',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
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

// ============================================================
// 示例 5：RepaintBoundary 演示
// ============================================================

/// 演示 RepaintBoundary 的使用和效果
class RepaintBoundaryDemo extends StatefulWidget {
  const RepaintBoundaryDemo({super.key});

  @override
  State<RepaintBoundaryDemo> createState() => _RepaintBoundaryDemoState();
}

class _RepaintBoundaryDemoState extends State<RepaintBoundaryDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _useRepaintBoundary = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 说明卡片
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RepaintBoundary 演示',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RepaintBoundary 创建独立绘制层，隔离动画区域的重绘，'
                    '避免影响其他静态内容。\n\n'
                    '开启 debugRepaintRainbowEnabled（右上角虫子菜单）后，'
                    '可以观察重绘范围的变化。',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RepaintBoundary 开关
          Card(
            child: SwitchListTile(
              title: const Text('使用 RepaintBoundary 包裹动画'),
              subtitle: Text(
                _useRepaintBoundary
                    ? '✅ 动画重绘被隔离，静态内容不受影响'
                    : '❌ 动画重绘可能影响周围的静态内容',
              ),
              value: _useRepaintBoundary,
              onChanged: (value) =>
                  setState(() => _useRepaintBoundary = value),
            ),
          ),
          const SizedBox(height: 16),

          // 布局区域：静态 + 动画 + 静态
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 静态内容 1
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.image, size: 32),
                        SizedBox(height: 8),
                        Text('静态内容区域（上方）'),
                        Text('此区域内容不会变化'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 动画内容（可选是否用 RepaintBoundary）
                  _buildAnimatedSection(),
                  const SizedBox(height: 12),

                  // 静态内容 2
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.text_fields, size: 32),
                        SizedBox(height: 8),
                        Text('静态内容区域（下方）'),
                        Text('此区域内容也不会变化'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 代码对比
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 使用建议',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      '// 适合使用 RepaintBoundary 的场景：\n'
                      '// 1. 动画 Widget（如进度条、旋转图标）\n'
                      '// 2. 频繁更新的区域（如计时器、实时数据）\n'
                      '// 3. 复杂的自定义绘制（CustomPaint）\n'
                      '\n'
                      '// 不需要手动添加的场景：\n'
                      '// 1. ListView/GridView 子项（已自动添加）\n'
                      '// 2. 简单的静态 Widget\n'
                      '// 3. 整个页面只有少量 Widget',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 调试函数介绍
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔧 常用调试函数',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  _buildDebugFunctionTile(
                    'debugDumpRenderTree()',
                    '打印完整渲染树（约束、尺寸等）',
                    Icons.account_tree,
                    () => debugDumpRenderTree(),
                  ),
                  _buildDebugFunctionTile(
                    'debugDumpApp()',
                    '打印完整 Widget 树',
                    Icons.widgets,
                    () => debugDumpApp(),
                  ),
                  _buildDebugFunctionTile(
                    'debugDumpLayerTree()',
                    '打印 Layer 树结构',
                    Icons.layers,
                    () => debugDumpLayerTree(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建动画区域（根据开关决定是否使用 RepaintBoundary）
  Widget _buildAnimatedSection() {
    final animWidget = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.lerp(
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
              _animController.value,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Transform.rotate(
                angle: _animController.value * 3.14159 * 2,
                child: const Icon(Icons.refresh, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                '🎬 动画区域（${(_animController.value * 100).toInt()}%）',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_useRepaintBoundary
                  ? '已用 RepaintBoundary 隔离'
                  : '未隔离，重绘可能扩散'),
            ],
          ),
        );
      },
    );

    if (_useRepaintBoundary) {
      return RepaintBoundary(child: animWidget);
    }
    return animWidget;
  }

  /// 构建调试函数列表项
  Widget _buildDebugFunctionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontFamily: 'monospace')),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        tooltip: '执行（输出到控制台）',
        onPressed: () {
          onTap();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 已执行，查看控制台输出'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
