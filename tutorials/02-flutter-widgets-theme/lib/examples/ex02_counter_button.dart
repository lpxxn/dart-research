import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/counter_button.dart';

/// 第2章示例页面：展示 CounterButton 交互控件
class CounterButtonExample extends StatefulWidget {
  const CounterButtonExample({super.key});

  @override
  State<CounterButtonExample> createState() => _CounterButtonExampleState();
}

class _CounterButtonExampleState extends State<CounterButtonExample> {
  /// 三个计数器各自的当前值，用于计算总和
  int _value1 = 0;
  int _value2 = 0;
  int _value3 = 0;

  /// 三个计数器的 GlobalKey，用于调用 reset 方法
  final _key1 = GlobalKey<CounterButtonState>();
  final _key2 = GlobalKey<CounterButtonState>();
  final _key3 = GlobalKey<CounterButtonState>();

  /// 所有计数器的总和
  int get _total => _value1 + _value2 + _value3;

  /// 重置所有计数器
  void _resetAll() {
    _key1.currentState?.reset();
    _key2.currentState?.reset();
    _key3.currentState?.reset();
    setState(() {
      _value1 = 0;
      _value2 = 0;
      _value3 = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第2章：交互控件 CounterButton'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 计数器展示区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 使用说明
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app,
                              color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '点击按钮 +1，长按重置为 0',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 三个不同配置的 CounterButton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 计数器 1：小尺寸，蓝色
                      _buildCounterColumn(
                        context,
                        label: '小号·蓝色',
                        child: CounterButton(
                          key: _key1,
                          size: 60,
                          color: Colors.blue,
                          onChanged: (value) {
                            setState(() => _value1 = value);
                          },
                        ),
                      ),
                      // 计数器 2：中尺寸，绿色
                      _buildCounterColumn(
                        context,
                        label: '中号·绿色',
                        child: CounterButton(
                          key: _key2,
                          size: 80,
                          color: Colors.green,
                          onChanged: (value) {
                            setState(() => _value2 = value);
                          },
                        ),
                      ),
                      // 计数器 3：大尺寸，橙色
                      _buildCounterColumn(
                        context,
                        label: '大号·橙色',
                        child: CounterButton(
                          key: _key3,
                          size: 100,
                          color: Colors.orange,
                          initialValue: 5,
                          onChanged: (value) {
                            setState(() => _value3 = value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 说明卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💡 实现要点',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text(
                            '• CounterButton 是 StatefulWidget，内部管理计数状态\n'
                            '• 通过 onChanged 回调通知父组件（子 → 父通信）\n'
                            '• 父组件汇总所有子组件的值，计算总和\n'
                            '• 数字变化使用 AnimatedSwitcher + SlideTransition 动画\n'
                            '• 使用 GlobalKey 可从外部调用子组件的 reset() 方法',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部：总和显示 + 重置按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // 总和显示
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '所有计数器总和',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_total',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 重置全部按钮
                  FilledButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置全部'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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

  /// 构建计数器列（标签 + 计数器）
  Widget _buildCounterColumn(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      children: [
        child,
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
