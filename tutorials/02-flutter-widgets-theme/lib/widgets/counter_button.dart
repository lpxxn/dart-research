import 'package:flutter/material.dart';

/// 计数器按钮控件
///
/// 一个带动画效果的圆形计数器按钮：
/// - 点击 +1
/// - 长按重置为 0
/// - 数字变化时有滑入/滑出动画（AnimatedSwitcher + SlideTransition）
/// - 带涟漪效果
///
/// 使用示例：
/// ```dart
/// CounterButton(
///   initialValue: 0,
///   color: Colors.blue,
///   size: 80,
///   onChanged: (value) => print('当前计数: $value'),
/// )
/// ```
class CounterButton extends StatefulWidget {
  /// 初始计数值
  final int initialValue;

  /// 计数值变化时的回调
  final ValueChanged<int>? onChanged;

  /// 按钮主色调
  final Color? color;

  /// 按钮直径
  final double size;

  const CounterButton({
    super.key,
    this.initialValue = 0,
    this.onChanged,
    this.color,
    this.size = 72,
  });

  @override
  State<CounterButton> createState() => CounterButtonState();
}

class CounterButtonState extends State<CounterButton> {
  late int _count;

  /// 外部可读取当前计数值
  int get count => _count;

  /// 外部可调用重置方法
  void reset() {
    setState(() {
      _count = 0;
    });
    widget.onChanged?.call(_count);
  }

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
  }

  /// 点击 +1
  void _increment() {
    setState(() {
      _count++;
    });
    widget.onChanged?.call(_count);
  }

  /// 长按重置为 0
  void _resetToZero() {
    setState(() {
      _count = 0;
    });
    widget.onChanged?.call(_count);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    return GestureDetector(
      onLongPress: _resetToZero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _increment,
          borderRadius: BorderRadius.circular(widget.size / 2),
          splashColor: effectiveColor.withValues(alpha: 0.3),
          highlightColor: effectiveColor.withValues(alpha: 0.1),
          child: Ink(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveColor,
                  effectiveColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // 数字切换动画
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  // 新数字从下方滑入，旧数字向上滑出
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$_count',
                  // 用 key 确保 AnimatedSwitcher 能识别变化
                  key: ValueKey<int>(_count),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
