import 'package:flutter/material.dart';

/// 第0章：设计哲学演示页面
/// 通过三个 Tab 展示 Flutter 的核心设计理念：
/// 1. 组合 vs 继承
/// 2. 声明式 UI
/// 3. Key 的作用
class PhilosophyDemoPage extends StatefulWidget {
  const PhilosophyDemoPage({super.key});

  @override
  State<PhilosophyDemoPage> createState() => _PhilosophyDemoPageState();
}

class _PhilosophyDemoPageState extends State<PhilosophyDemoPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第0章：设计哲学演示'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.widgets), text: '组合 vs 继承'),
              Tab(icon: Icon(Icons.refresh), text: '声明式 UI'),
              Tab(icon: Icon(Icons.vpn_key), text: 'Key 的作用'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CompositionTab(),
            _DeclarativeTab(),
            _KeyDemoTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Tab 1: 组合 vs 继承
// ============================================================

/// 演示 Flutter 中"组合优于继承"的设计哲学。
/// 我们不需要继承一个 Card 类来定制它，而是通过组合多个基础 Widget 来构建。
class _CompositionTab extends StatelessWidget {
  const _CompositionTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明文字
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 组合优于继承',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Flutter 中没有"继承 Button 来做自定义按钮"这种模式。\n'
                    '取而代之的是：把小的 Widget 像积木一样组合起来。\n'
                    '下面这张卡片就是用 Container + Column + Row + Text + Icon 组合而成。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 用组合方式构建的"用户资料卡片"
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：头像 + 名字
                Row(
                  children: [
                    // CircleAvatar — 不是继承来的，是组合进来的
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    // Column 嵌套 — 这就是组合
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flutter 开发者',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '热爱组合，拒绝继承',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 信息行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(Icons.star, '收藏', '128'),
                    _buildStat(Icons.code, '项目', '42'),
                    _buildStat(Icons.people, '关注', '1.2k'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 结构说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🧱 组合结构', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Container (装饰/渐变)\n'
                    '  └─ Column\n'
                    '       ├─ Row (头像 + 文字)\n'
                    '       │    ├─ CircleAvatar\n'
                    '       │    └─ Column (姓名 + 简介)\n'
                    '       └─ Row (统计数据)\n'
                    '            ├─ Column (收藏)\n'
                    '            ├─ Column (项目)\n'
                    '            └─ Column (关注)\n'
                    '\n没有任何继承，全部通过组合完成！',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计项（组合方式：Icon + Text + Text）
  static Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================
// Tab 2: 声明式 UI
// ============================================================

/// 演示声明式 UI：状态变了，UI 自动重建。
/// 开发者只需要描述"UI 应该长什么样"，而不是"怎么去改 UI"。
class _DeclarativeTab extends StatefulWidget {
  const _DeclarativeTab();

  @override
  State<_DeclarativeTab> createState() => _DeclarativeTabState();
}

class _DeclarativeTabState extends State<_DeclarativeTab> {
  int _count = 0;
  Color _color = Colors.blue;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 说明
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 声明式 UI',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在声明式 UI 中，你只需描述"当前状态下 UI 应该长什么样"。\n'
                    '当状态改变时，调用 setState()，Flutter 自动重新调用 build() 方法，\n'
                    'UI 就会自动更新。你不需要手动去 setText() 或 setColor()。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 计数器展示区域
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _color, width: 2),
            ),
            child: Column(
              children: [
                // 数字随状态自动变化
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: _count > 10 ? 64 : 48,
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                  child: Text('$_count'),
                ),
                const SizedBox(height: 8),
                Text(
                  '← 这个数字是 build() 方法里写的 Text(\'\$$_count\')',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '状态变了 → setState() → build() 重新执行 → UI 自动更新',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  // 这就是声明式的精髓：
                  // 只需要改变 _count 的值，UI 自动更新
                  setState(() {
                    _count++;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('计数 +1'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _count = 0;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    // 切换颜色，同样只需改变状态
                    final currentIndex = _colors.indexOf(_color);
                    _color = _colors[(currentIndex + 1) % _colors.length];
                  });
                },
                icon: const Icon(Icons.palette),
                label: const Text('换色'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 对比说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📝 声明式 vs 命令式', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '命令式 (Android/iOS 传统方式):\n'
                    '  textView.setText("\$count")\n'
                    '  container.setBackgroundColor(color)\n'
                    '\n'
                    '声明式 (Flutter 方式):\n'
                    '  setState(() { _count++; })\n'
                    '  // build() 自动重新执行，返回新的 Widget 树\n'
                    '  // Text("\$_count") 自然就显示新值了',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
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
// Tab 3: Key 的作用
// ============================================================

/// 演示 Key 在 Widget 列表中的作用。
/// 没有 Key 时，交换两个带状态的 Widget，状态不会跟随；
/// 有 Key 时，状态正确跟随 Widget。
class _KeyDemoTab extends StatefulWidget {
  const _KeyDemoTab();

  @override
  State<_KeyDemoTab> createState() => _KeyDemoTabState();
}

class _KeyDemoTabState extends State<_KeyDemoTab> {
  /// 是否使用 Key
  bool _useKeys = false;

  /// 两个项目的数据
  List<_ItemData> _items = [
    _ItemData(title: '🍎 苹果', color: Colors.red),
    _ItemData(title: '🍊 橘子', color: Colors.orange),
  ];

  /// 交换列表中两个项目的顺序
  void _swapItems() {
    setState(() {
      _items = [_items[1], _items[0]];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 说明
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Key 的作用',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当列表中的 Widget 被重新排序时，Flutter 通过 Key 来判断\n'
                    '哪个 Element 对应哪个 Widget。\n\n'
                    '没有 Key → Flutter 按位置匹配 → 状态不跟随\n'
                    '有 Key → Flutter 按 Key 匹配 → 状态正确跟随',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 切换开关
          SwitchListTile(
            title: Text(
              _useKeys ? '✅ 使用 Key（状态会跟随）' : '❌ 不使用 Key（状态不跟随）',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(_useKeys ? 'ValueKey 已启用' : 'Key 未设置'),
            value: _useKeys,
            onChanged: (value) {
              setState(() {
                _useKeys = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // 提示操作步骤
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '操作步骤：先勾选其中一个 checkbox，然后点击"交换顺序"按钮，\n'
                      '观察 checkbox 的勾选状态是否跟随文字一起移动。',
                      style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 两个可勾选项目
          ..._buildItemList(),

          const SizedBox(height: 24),

          // 交换按钮
          FilledButton.icon(
            onPressed: _swapItems,
            icon: const Icon(Icons.swap_vert),
            label: const Text('交换顺序'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

          const SizedBox(height: 24),

          // 当前模式提示
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔍 当前模式', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _useKeys
                        ? '使用 ValueKey → 交换后 checkbox 状态跟随项目移动\n'
                            '原理：Flutter 通过 Key 找到了对应的 Element，复用了正确的 State'
                        : '不使用 Key → 交换后 checkbox 状态留在原位\n'
                            '原理：Flutter 按位置匹配 Element，位置0的 State 还是位置0的',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 根据是否使用 Key 构建不同的列表项
  List<Widget> _buildItemList() {
    return _items.map((item) {
      if (_useKeys) {
        // 使用 ValueKey，让 Flutter 能通过 Key 追踪 Widget
        return _CheckableItem(
          key: ValueKey(item.title),
          title: item.title,
          color: item.color,
        );
      } else {
        // 不使用 Key，Flutter 按位置匹配
        return _CheckableItem(
          title: item.title,
          color: item.color,
        );
      }
    }).toList();
  }
}

/// 项目数据模型
class _ItemData {
  final String title;
  final Color color;

  _ItemData({required this.title, required this.color});
}

/// 带 checkbox 的列表项 — StatefulWidget，内部持有勾选状态
class _CheckableItem extends StatefulWidget {
  final String title;
  final Color color;

  const _CheckableItem({
    super.key,
    required this.title,
    required this.color,
  });

  @override
  State<_CheckableItem> createState() => _CheckableItemState();
}

class _CheckableItemState extends State<_CheckableItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color.withValues(alpha: 0.1),
      child: CheckboxListTile(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.color.withValues(alpha: 0.8),
          ),
        ),
        subtitle: Text('勾选状态: ${_checked ? "✅ 已勾选" : "⬜ 未勾选"}'),
        value: _checked,
        activeColor: widget.color,
        onChanged: (value) {
          setState(() {
            _checked = value ?? false;
          });
        },
      ),
    );
  }
}
