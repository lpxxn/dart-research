import 'package:flutter/material.dart';

/// 问候卡片控件
/// 展示用户头像、姓名、问候语和在线状态。
///
/// 使用示例：
/// ```dart
/// GreetingCard(
///   name: '张三',
///   greeting: '早上好！',
///   isOnline: true,
///   onTap: () => print('点击了卡片'),
/// )
/// ```
class GreetingCard extends StatelessWidget {
  /// 用户姓名（必填）
  final String name;

  /// 问候语，默认 "你好！"
  final String greeting;

  /// 头像网络地址，为 null 时显示姓名首字母
  final String? avatarUrl;

  /// 是否在线，在线时头像右下角显示小绿点
  final bool isOnline;

  /// 点击卡片的回调
  final VoidCallback? onTap;

  const GreetingCard({
    super.key,
    required this.name,
    this.greeting = '你好！',
    this.avatarUrl,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 取姓名首字符作为头像 fallback
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 头像区域：用 Stack 叠加在线状态小绿点
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            initial,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  // 在线状态指示器（小绿点）
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // 姓名和问候语
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 右侧箭头
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
