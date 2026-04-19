import 'package:flutter/material.dart';

/// Chapter 2：单子布局控件完整示例
/// 演示 Container、SizedBox、Padding、Center、Align、
/// FractionallySizedBox、ConstrainedBox、LimitedBox、
/// AspectRatio、FittedBox、IntrinsicWidth / IntrinsicHeight

void main() => runApp(const SingleChildLayoutApp());

class SingleChildLayoutApp extends StatelessWidget {
  const SingleChildLayoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch02 单子布局控件',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SingleChildLayoutDemo(),
    );
  }
}

class SingleChildLayoutDemo extends StatelessWidget {
  const SingleChildLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单子布局控件')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================== 1. Container ====================
          _buildSectionTitle('1. Container — 多层装饰器的组合'),
          _buildDescription('Container 集成了 alignment、padding、decoration、'
              'constraints、transform 等功能，内部层层嵌套基础控件。'),
          Container(
            width: double.infinity,
            height: 100,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Container：背景色 + 圆角 + 阴影 + 内边距',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 2. SizedBox ====================
          _buildSectionTitle('2. SizedBox — 轻量级尺寸约束'),
          _buildDescription('只需要设置宽高时，优先使用 SizedBox 而不是 Container。'),
          const SizedBox(
            width: 200,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.orange),
              child: Center(
                child: Text(
                  'SizedBox 200×60',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // SizedBox 用作间距
          Row(
            children: [
              Container(width: 50, height: 50, color: Colors.red),
              const SizedBox(width: 16), // 水平间距
              Container(width: 50, height: 50, color: Colors.green),
              const SizedBox(width: 16),
              Container(width: 50, height: 50, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          _buildDescription('上面的红、绿、蓝方块之间用 SizedBox(width:16) 做间距'),
          const SizedBox(height: 24),

          // ==================== 3. Padding ====================
          _buildSectionTitle('3. Padding — 内边距控件'),
          _buildDescription('不需要装饰时，直接使用 Padding 比 Container 更轻量。\n'
              'margin 是在 decoration 外面，padding 在里面。'),
          Container(
            color: Colors.grey.withValues(alpha: 0.2),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text(
                'margin=20（灰色区域）\npadding=16（边框内）',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 4. Center 和 Align ====================
          _buildSectionTitle('4. Center 和 Align — 对齐控件'),
          _buildDescription('Center 是 Align(alignment: Alignment.center) 的简写。\n'
              'Alignment 坐标系：(-1,-1) 左上角 → (1,1) 右下角。'),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // 左上角
                const Align(
                  alignment: Alignment.topLeft,
                  child: _AlignLabel('topLeft\n(-1,-1)'),
                ),
                // 右上角
                const Align(
                  alignment: Alignment.topRight,
                  child: _AlignLabel('topRight\n(1,-1)'),
                ),
                // 中心
                const Center(
                  child: _AlignLabel('center\n(0,0)'),
                ),
                // 左下角
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: _AlignLabel('bottomLeft\n(-1,1)'),
                ),
                // 右下角
                const Align(
                  alignment: Alignment.bottomRight,
                  child: _AlignLabel('bottomRight\n(1,1)'),
                ),
                // 自定义位置
                Align(
                  alignment: const Alignment(-0.5, 0.5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '(-0.5, 0.5)',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 5. FractionallySizedBox ====================
          _buildSectionTitle('5. FractionallySizedBox — 按比例设置大小'),
          _buildDescription('子控件大小 = 父控件大小 × factor。适合响应式布局。'),
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.7,
              heightFactor: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '宽 70%, 高 60%',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 6. ConstrainedBox ====================
          _buildSectionTitle('6. ConstrainedBox — 约束限制'),
          _buildDescription('对子控件施加额外的 min/max 约束。\n'
              '注意：ConstrainedBox 只能收紧约束，不能放宽。'),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 200,
              maxWidth: 300,
              minHeight: 60,
              maxHeight: 100,
            ),
            child: Container(
              color: Colors.indigo,
              child: const Center(
                child: Text(
                  '宽 200~300, 高 60~100',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 7. LimitedBox ====================
          _buildSectionTitle('7. LimitedBox — 无约束时的兜底'),
          _buildDescription('仅当父控件是无界约束（unbounded）时才生效。\n'
              '此处在 ListView 中，垂直方向无约束，LimitedBox 生效。'),
          // 注意：我们当前就在 ListView 中，垂直方向是无约束的
          LimitedBox(
            maxHeight: 80,
            child: Container(
              color: Colors.brown,
              child: const Center(
                child: Text(
                  'LimitedBox maxHeight=80',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 8. AspectRatio ====================
          _buildSectionTitle('8. AspectRatio — 宽高比'),
          _buildDescription('根据父控件宽度和指定比例自动计算高度。常用于视频/图片。'),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '16 : 9',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 9. FittedBox ====================
          _buildSectionTitle('9. FittedBox — 内容缩放'),
          _buildDescription('将子控件缩放到适合自身大小。常用于文字自适应。'),
          // BoxFit.contain 示例
          SizedBox(
            width: 250,
            height: 50,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                '这段文字会自动缩放以适应容器',
                style: TextStyle(
                  fontSize: 50,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // BoxFit.scaleDown 示例（只缩小不放大）
          SizedBox(
            width: 250,
            height: 50,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '短文字',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildDescription(
            '上面第一行 BoxFit.contain（缩放适配），第二行 BoxFit.scaleDown（只缩不放）',
          ),
          const SizedBox(height: 24),

          // ==================== 10. IntrinsicWidth ====================
          _buildSectionTitle('10. IntrinsicWidth — 固有宽度（慎用）'),
          _buildDescription('让所有子控件等宽（等于最宽的那个）。\n'
              '⚠️ 性能开销大（O(n²)），避免在复杂布局中使用。'),
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('短'),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('这个按钮文字比较长'),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('中等长度'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 11. IntrinsicHeight ====================
          _buildSectionTitle('11. IntrinsicHeight — 固有高度（慎用）'),
          _buildDescription('让 Row 中的子控件等高（等于最高的那个）。'),
          IntrinsicHeight(
            child: Row(
              children: [
                // 左侧竖线，高度自动匹配右侧内容
                Container(
                  width: 4,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                // 右侧内容（多行文字，比较高）
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '标题',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('第一行内容'),
                      Text('第二行内容'),
                      Text('第三行内容'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==================== 总结 ====================
          _buildSectionTitle('选型总结'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• 固定宽高 → SizedBox'),
                Text('• 空白间距 → SizedBox'),
                Text('• 内边距 → Padding'),
                Text('• 背景装饰 → Container'),
                Text('• 居中 → Center'),
                Text('• 自定义对齐 → Align'),
                Text('• 按比例大小 → FractionallySizedBox'),
                Text('• 约束限制 → ConstrainedBox'),
                Text('• 无约束兜底 → LimitedBox'),
                Text('• 宽高比 → AspectRatio'),
                Text('• 内容缩放 → FittedBox'),
                Text('• 等宽/等高 → IntrinsicWidth/Height（慎用）'),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  /// 构建章节标题
  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  /// 构建说明文字
  static Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Alignment 演示用的标签控件
class _AlignLabel extends StatelessWidget {
  const _AlignLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
