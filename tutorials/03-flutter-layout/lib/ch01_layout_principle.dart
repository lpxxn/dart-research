import 'package:flutter/material.dart';

/// Chapter 1: Flutter 布局原理演示
/// 核心思想：约束向下传递，尺寸向上报告，父决定位置
void main() => runApp(const LayoutPrincipleApp());

class LayoutPrincipleApp extends StatelessWidget {
  const LayoutPrincipleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch01 布局原理',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LayoutPrincipleHome(),
    );
  }
}

class LayoutPrincipleHome extends StatelessWidget {
  const LayoutPrincipleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapter 1: 布局原理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // —— 第一节：LayoutBuilder 打印约束信息 ——
          _SectionTitle('1. LayoutBuilder 打印约束信息'),
          _ConstraintPrinterDemo(),
          SizedBox(height: 24),

          // —— 第二节：Tight vs Loose 约束 ——
          _SectionTitle('2. Tight vs Loose 约束'),
          _TightVsLooseDemo(),
          SizedBox(height: 24),

          // —— 第三节：嵌套容器约束变化 ——
          _SectionTitle('3. 嵌套容器约束变化'),
          _NestedConstraintsDemo(),
          SizedBox(height: 24),

          // —— 第四节：UnconstrainedBox 演示 ——
          _SectionTitle('4. UnconstrainedBox 演示'),
          _UnconstrainedBoxDemo(),
          SizedBox(height: 24),

          // —— 第五节：OverflowBox 演示 ——
          _SectionTitle('5. OverflowBox 演示'),
          _OverflowBoxDemo(),
          SizedBox(height: 24),

          // —— 第六节：Padding 对约束的影响 ——
          _SectionTitle('6. Padding 对约束的影响'),
          _PaddingConstraintDemo(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ============================================================================
// 通用组件
// ============================================================================

/// 章节标题
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// 用于在界面上显示约束信息的标签
class _ConstraintLabel extends StatelessWidget {
  final String label;
  final BoxConstraints constraints;

  const _ConstraintLabel({
    required this.label,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    // 判断约束类型
    final String type;
    if (constraints.isTight) {
      type = 'tight（紧约束）';
    } else if (constraints.minWidth == 0 && constraints.minHeight == 0) {
      type = 'loose（松约束）';
    } else {
      type = '介于 tight 和 loose 之间';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'w: ${constraints.minWidth} ~ ${constraints.maxWidth}\n'
            'h: ${constraints.minHeight} ~ ${constraints.maxHeight}\n'
            '类型: $type',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 第一节：LayoutBuilder 打印约束信息
// ============================================================================

/// 演示：在不同层级使用 LayoutBuilder 查看约束
class _ConstraintPrinterDemo extends StatelessWidget {
  const _ConstraintPrinterDemo();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        // 打印最外层（ListView 子组件）收到的约束
        debugPrint('[演示1] 外层约束: $outerConstraints');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConstraintLabel(
              label: '外层（ListView 子组件）',
              constraints: outerConstraints,
            ),

            // 在 Center 中观察约束变化
            Center(
              child: SizedBox(
                width: 280,
                height: 100,
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    debugPrint('[演示1] SizedBox(280×100) 内约束: $innerConstraints');
                    return Container(
                      color: Colors.indigo.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: _ConstraintLabel(
                        label: 'SizedBox(280×100) 内部',
                        constraints: innerConstraints,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 第二节：Tight vs Loose 约束
// ============================================================================

/// 演示：对比 tight 和 loose 约束下子组件的行为
class _TightVsLooseDemo extends StatelessWidget {
  const _TightVsLooseDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tight 约束（SizedBox 固定尺寸）：',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),

        // tight 约束示例：SizedBox 强制宽高
        SizedBox(
          width: 200,
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              debugPrint('[演示2] Tight 约束: $constraints');
              return Container(
                color: Colors.red.withValues(alpha: 0.2),
                alignment: Alignment.center,
                child: Text(
                  'tight: ${constraints.minWidth}×${constraints.minHeight}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        const Text('Loose 约束（Center 转换约束）：',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),

        // loose 约束示例：Center 将 tight 转为 loose
        SizedBox(
          width: 200,
          height: 60,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                debugPrint('[演示2] Loose 约束: $constraints');
                return Container(
                  color: Colors.green.withValues(alpha: 0.2),
                  // 在 loose 约束下，Container 会尽量收缩包裹内容
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'loose: 0~${constraints.maxWidth} × 0~${constraints.maxHeight}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 第三节：嵌套容器约束变化
// ============================================================================

/// 演示：多层嵌套下约束如何逐层收紧
class _NestedConstraintsDemo extends StatelessWidget {
  const _NestedConstraintsDemo();

  @override
  Widget build(BuildContext context) {
    // 第1层：外部 SizedBox 提供 tight 约束
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: LayoutBuilder(
        builder: (context, c1) {
          debugPrint('[演示3] 第1层约束: $c1');
          return Container(
            color: Colors.blue.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('第1层: w=${c1.minWidth}~${c1.maxWidth}',
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 4),

                // 第2层：Padding 会缩减约束
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, c2) {
                        debugPrint('[演示3] 第2层约束（Padding后）: $c2');
                        return Container(
                          color: Colors.orange.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '第2层(Padding 16后): '
                                'w=${c2.minWidth.toStringAsFixed(0)}'
                                '~${c2.maxWidth.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 4),

                              // 第3层：再嵌套 SizedBox 进一步限定
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 160,
                                    height: 60,
                                    child: LayoutBuilder(
                                      builder: (context, c3) {
                                        debugPrint(
                                            '[演示3] 第3层约束: $c3');
                                        return Container(
                                          color: Colors.purple
                                              .withValues(alpha: 0.2),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '第3层: ${c3.minWidth}×${c3.minHeight} (tight)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 第四节：UnconstrainedBox 演示
// ============================================================================

/// 演示：UnconstrainedBox 解除父组件约束
class _UnconstrainedBoxDemo extends StatelessWidget {
  const _UnconstrainedBoxDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UnconstrainedBox 让子组件突破父约束（注意溢出警告）：',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),

        // 外层限制为 200×80
        Center(
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: UnconstrainedBox(
              // 子组件被解除约束，可以设置任意尺寸
              child: LayoutBuilder(
                builder: (context, constraints) {
                  debugPrint('[演示4] UnconstrainedBox 内约束: $constraints');
                  return Container(
                    width: 260, // 超出父组件宽度 200
                    height: 40,
                    color: Colors.red.withValues(alpha: 0.4),
                    alignment: Alignment.center,
                    child: const Text(
                      '我是 260 宽，父只有 200',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '⚠️ 上方红色容器超出了灰色边框，会出现黄黑溢出条纹。'
            '这是 UnconstrainedBox 的特性——解除约束但会报告溢出。',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 第五节：OverflowBox 演示
// ============================================================================

/// 演示：OverflowBox 允许子组件安静地超出范围
class _OverflowBoxDemo extends StatelessWidget {
  const _OverflowBoxDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OverflowBox 允许子组件超出范围（无溢出警告）：',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),

        // 需要额外空间来容纳溢出的子组件视觉效果
        SizedBox(
          height: 120,
          child: Center(
            child: Container(
              width: 200,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: OverflowBox(
                // 允许子组件最大 300×100
                maxWidth: 300,
                maxHeight: 100,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    debugPrint('[演示5] OverflowBox 内约束: $constraints');
                    return Container(
                      width: 280,
                      height: 50,
                      color: Colors.blue.withValues(alpha: 0.4),
                      alignment: Alignment.center,
                      child: const Text(
                        '我是 280 宽，父只有 200（无警告）',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '💡 OverflowBox 与 UnconstrainedBox 的区别：\n'
            '• OverflowBox 可以自定义传给子组件的约束\n'
            '• OverflowBox 超出范围时不会产生溢出警告\n'
            '• 适合弹出层、下拉菜单等需要超出父组件的场景',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 第六节：Padding 对约束的影响
// ============================================================================

/// 演示：Padding 如何缩减传递给子组件的约束
class _PaddingConstraintDemo extends StatelessWidget {
  const _PaddingConstraintDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Padding 会从约束中扣除相应的空间：',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 140,
          child: LayoutBuilder(
            builder: (context, outerC) {
              return Container(
                color: Colors.teal.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '外层: w=${outerC.minWidth.toStringAsFixed(0)}'
                        '~${outerC.maxWidth.toStringAsFixed(0)}, '
                        'h=${outerC.minHeight.toStringAsFixed(0)}'
                        '~${outerC.maxHeight.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),

                    // 加 Padding 后约束缩减
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, innerC) {
                            debugPrint(
                                '[演示6] Padding(20) 后约束: $innerC');
                            return Container(
                              color: Colors.teal.withValues(alpha: 0.15),
                              alignment: Alignment.center,
                              child: Text(
                                'Padding(20) 后:\n'
                                'w=${innerC.minWidth.toStringAsFixed(0)}'
                                '~${innerC.maxWidth.toStringAsFixed(0)}, '
                                'h=${innerC.minHeight.toStringAsFixed(0)}'
                                '~${innerC.maxHeight.toStringAsFixed(0)}\n'
                                '（宽高各减少 40）',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
