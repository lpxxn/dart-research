import 'dart:math';

import 'package:flutter/material.dart';

/// 第7章：自定义页面转场
/// 演示内容：5 种自定义页面转场效果
/// 1. 淡入转场（Fade）
/// 2. 滑入转场（Slide）
/// 3. 缩放转场（Scale）
/// 4. 旋转转场（Rotation）
/// 5. 3D 翻转转场（3D Flip）

void main() => runApp(const Ch07CustomTransitionsApp());

class Ch07CustomTransitionsApp extends StatelessWidget {
  const Ch07CustomTransitionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第7章：自定义页面转场',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const TransitionHomePage(),
    );
  }
}

// ==================== 转场效果枚举 ====================

enum TransitionType {
  fade('淡入转场', Icons.opacity, Colors.blue),
  slide('滑入转场', Icons.swipe_right, Colors.green),
  scale('缩放转场', Icons.zoom_out_map, Colors.orange),
  rotation('旋转转场', Icons.rotate_right, Colors.purple),
  flip3D('3D 翻转转场', Icons.flip, Colors.red);

  final String label;
  final IconData icon;
  final Color color;

  const TransitionType(this.label, this.icon, this.color);
}

// ==================== 首页 ====================

class TransitionHomePage extends StatelessWidget {
  const TransitionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第7章：自定义页面转场')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: TransitionType.values.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final type = TransitionType.values[index];
          return _TransitionCard(type: type);
        },
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  final TransitionType type;

  const _TransitionCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateWithTransition(context, type),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type.icon, color: type.color, size: 28),
              ),
              const SizedBox(width: 16),
              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击查看 ${type.label} 效果',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 转场路由构建 ====================

void _navigateWithTransition(BuildContext context, TransitionType type) {
  final route = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _DetailPage(type: type);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (type) {
        case TransitionType.fade:
          return _buildFadeTransition(animation, child);
        case TransitionType.slide:
          return _buildSlideTransition(animation, child);
        case TransitionType.scale:
          return _buildScaleTransition(animation, child);
        case TransitionType.rotation:
          return _buildRotationTransition(animation, child);
        case TransitionType.flip3D:
          return _buildFlip3DTransition(animation, child);
      }
    },
  );

  Navigator.push(context, route);
}

// ---- 淡入转场 ----
Widget _buildFadeTransition(Animation<double> animation, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

// ---- 滑入转场（从右向左滑入，带淡入效果） ----
Widget _buildSlideTransition(Animation<double> animation, Widget child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation),
    child: FadeTransition(
      opacity: curvedAnimation,
      child: child,
    ),
  );
}

// ---- 缩放转场（从小到大，带淡入和回弹效果） ----
Widget _buildScaleTransition(Animation<double> animation, Widget child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutBack,
  );
  return ScaleTransition(
    scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
    child: FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
      child: child,
    ),
  );
}

// ---- 旋转转场（旋转 + 缩放 + 淡入） ----
Widget _buildRotationTransition(Animation<double> animation, Widget child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );
  return RotationTransition(
    turns: Tween<double>(begin: 0.5, end: 0.0).animate(curvedAnimation),
    child: ScaleTransition(
      scale: curvedAnimation,
      child: FadeTransition(
        opacity: curvedAnimation,
        child: child,
      ),
    ),
  );
}

// ---- 3D 翻转转场 ----
Widget _buildFlip3DTransition(Animation<double> animation, Widget child) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutBack,
  );
  return AnimatedBuilder(
    animation: curvedAnimation,
    child: child,
    builder: (context, child) {
      // 翻转角度：从 π（180°）到 0
      final angle = (1.0 - curvedAnimation.value) * pi;
      // 当翻转超过 90° 时隐藏背面（避免镜像显示）
      if (angle > pi / 2) {
        return Container(color: Colors.black);
      }
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.001) // 透视效果
        ..rotateY(angle);
      return Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: child,
      );
    },
  );
}

// ==================== 详情页 ====================

class _DetailPage extends StatelessWidget {
  final TransitionType type;

  const _DetailPage({required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        backgroundColor: type.color.withValues(alpha: 0.1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 大图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, size: 60, color: type.color),
              ),
              const SizedBox(height: 32),
              // 标题
              Text(
                type.label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // 说明
              Text(
                _getDescription(type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              // 返回按钮
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回（带反向动画）'),
                style: FilledButton.styleFrom(
                  backgroundColor: type.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription(TransitionType type) {
    switch (type) {
      case TransitionType.fade:
        return '使用 FadeTransition 实现\n新页面的透明度从 0 渐变到 1\n搭配 Curves.easeInOut 缓动曲线';
      case TransitionType.slide:
        return '使用 SlideTransition 实现\n页面从右侧（Offset(1,0)）滑入到原位（Offset.zero）\n搭配淡入效果和 Curves.easeOutCubic 曲线';
      case TransitionType.scale:
        return '使用 ScaleTransition 实现\n页面从 0 缩放到 1（全尺寸）\n搭配 Curves.easeOutBack 回弹效果';
      case TransitionType.rotation:
        return '使用 RotationTransition 实现\n页面旋转半圈（turns: 0.5→0）进入\n搭配缩放和淡入组合效果';
      case TransitionType.flip3D:
        return '使用 Transform + Matrix4 实现\n绕 Y 轴翻转 180°\n通过 setEntry(3,2,0.001) 添加透视效果';
    }
  }
}
