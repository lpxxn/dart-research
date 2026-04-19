import 'dart:math';
import 'package:flutter/material.dart';

/// 第1章：隐式动画示例
/// 展示 AnimatedContainer、AnimatedOpacity、AnimatedCrossFade、
/// AnimatedSwitcher、TweenAnimationBuilder 等组件的用法。

void main() => runApp(const Ch01App());

class Ch01App extends StatelessWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第1章：隐式动画',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ImplicitAnimationsDemo(),
    );
  }
}

class ImplicitAnimationsDemo extends StatefulWidget {
  const ImplicitAnimationsDemo({super.key});

  @override
  State<ImplicitAnimationsDemo> createState() =>
      _ImplicitAnimationsDemoState();
}

class _ImplicitAnimationsDemoState extends State<ImplicitAnimationsDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第1章：隐式动画')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('1. AnimatedContainer'),
          _AnimatedContainerDemo(),
          Divider(height: 32),
          _SectionTitle('2. AnimatedOpacity'),
          _AnimatedOpacityDemo(),
          Divider(height: 32),
          _SectionTitle('3. AnimatedCrossFade'),
          _AnimatedCrossFadeDemo(),
          Divider(height: 32),
          _SectionTitle('4. AnimatedSwitcher'),
          _AnimatedSwitcherDemo(),
          Divider(height: 32),
          _SectionTitle('5. TweenAnimationBuilder'),
          _TweenAnimationBuilderDemo(),
          Divider(height: 32),
          _SectionTitle('6. AnimatedPadding + DefaultTextStyle'),
          _AnimatedPaddingTextDemo(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// 标题组件
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ============================================================
// 1. AnimatedContainer —— 多属性动画
// ============================================================
class _AnimatedContainerDemo extends StatefulWidget {
  const _AnimatedContainerDemo();

  @override
  State<_AnimatedContainerDemo> createState() =>
      _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<_AnimatedContainerDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedContainer 会自动在新旧属性之间做补间动画
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: _expanded ? 220 : 120,
            height: _expanded ? 220 : 120,
            decoration: BoxDecoration(
              color: _expanded ? Colors.indigo : Colors.orange,
              borderRadius: BorderRadius.circular(_expanded ? 32 : 12),
              boxShadow: [
                BoxShadow(
                  color: (_expanded ? Colors.indigo : Colors.orange)
                      .withValues(alpha: 0.4),
                  blurRadius: _expanded ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '点我',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '状态: ${_expanded ? "展开" : "收起"}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============================================================
// 2. AnimatedOpacity —— 淡入淡出
// ============================================================
class _AnimatedOpacityDemo extends StatefulWidget {
  const _AnimatedOpacityDemo();

  @override
  State<_AnimatedOpacityDemo> createState() => _AnimatedOpacityDemoState();
}

class _AnimatedOpacityDemoState extends State<_AnimatedOpacityDemo> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedOpacity 在 opacity 改变时自动过渡
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: _visible ? 1.0 : 0.0,
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '我会淡入淡出',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => setState(() => _visible = !_visible),
          child: Text(_visible ? '隐藏' : '显示'),
        ),
      ],
    );
  }
}

// ============================================================
// 3. AnimatedCrossFade —— 两个子组件交叉切换
// ============================================================
class _AnimatedCrossFadeDemo extends StatefulWidget {
  const _AnimatedCrossFadeDemo();

  @override
  State<_AnimatedCrossFadeDemo> createState() =>
      _AnimatedCrossFadeDemoState();
}

class _AnimatedCrossFadeDemoState extends State<_AnimatedCrossFadeDemo> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedCrossFade 在两个子组件之间做交叉淡入淡出
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState: _showFirst
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
          ),
          secondChild: Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.pause, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => setState(() => _showFirst = !_showFirst),
          child: const Text('切换'),
        ),
      ],
    );
  }
}

// ============================================================
// 4. AnimatedSwitcher —— 子组件替换时的过渡动画
// ============================================================
class _AnimatedSwitcherDemo extends StatefulWidget {
  const _AnimatedSwitcherDemo();

  @override
  State<_AnimatedSwitcherDemo> createState() => _AnimatedSwitcherDemoState();
}

class _AnimatedSwitcherDemoState extends State<_AnimatedSwitcherDemo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedSwitcher 通过 key 判断子组件是否改变
        // 改变时自动执行 transitionBuilder 中定义的过渡动画
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            // 缩放 + 淡入淡出
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            '$_count',
            // 重要：必须给子组件不同的 key，否则不会触发动画
            key: ValueKey<int>(_count),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('计数 +1'),
        ),
      ],
    );
  }
}

// ============================================================
// 5. TweenAnimationBuilder —— 自定义任意值的隐式动画
// ============================================================
class _TweenAnimationBuilderDemo extends StatefulWidget {
  const _TweenAnimationBuilderDemo();

  @override
  State<_TweenAnimationBuilderDemo> createState() =>
      _TweenAnimationBuilderDemoState();
}

class _TweenAnimationBuilderDemoState
    extends State<_TweenAnimationBuilderDemo> {
  double _targetAngle = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TweenAnimationBuilder 可以动画化任意可插值类型
        // 这里我们动画化旋转角度
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _targetAngle),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value,
              child: child, // child 参数优化：不会每帧重建
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() => _targetAngle += pi / 2); // 每次旋转 90°
          },
          child: const Text('旋转 90°'),
        ),
      ],
    );
  }
}

// ============================================================
// 6. AnimatedPadding + AnimatedDefaultTextStyle
// ============================================================
class _AnimatedPaddingTextDemo extends StatefulWidget {
  const _AnimatedPaddingTextDemo();

  @override
  State<_AnimatedPaddingTextDemo> createState() =>
      _AnimatedPaddingTextDemoState();
}

class _AnimatedPaddingTextDemoState extends State<_AnimatedPaddingTextDemo> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _highlighted = !_highlighted),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(_highlighted ? 32.0 : 12.0),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: _highlighted
                    ? const TextStyle(
                        fontSize: 24,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      )
                    : const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                child: const Text('点击我改变样式和间距'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
