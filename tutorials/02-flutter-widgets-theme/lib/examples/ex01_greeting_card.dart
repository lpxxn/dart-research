import 'package:flutter/material.dart';
import 'package:theme_demo/widgets/greeting_card.dart';

/// 第1章示例页面：展示 GreetingCard 控件的多种用法
class GreetingCardExample extends StatelessWidget {
  const GreetingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('第1章：自定义 GreetingCard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 小标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '以下展示 GreetingCard 的 4 种不同配置：',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          // 1. 基础用法：只传 name
          _buildSection(context, '1. 基础用法（仅传 name）'),
          const GreetingCard(
            name: '李明',
          ),

          const SizedBox(height: 8),

          // 2. 自定义问候语 + 在线状态
          _buildSection(context, '2. 自定义问候语 + 在线状态'),
          const GreetingCard(
            name: '王芳',
            greeting: '下午好！今天天气不错 ☀️',
            isOnline: true,
          ),

          const SizedBox(height: 8),

          // 3. 带头像 URL
          _buildSection(context, '3. 带网络头像'),
          const GreetingCard(
            name: '张伟',
            greeting: '很高兴认识你！',
            avatarUrl: 'https://i.pravatar.cc/150?img=3',
            isOnline: true,
          ),

          const SizedBox(height: 8),

          // 4. 带 onTap 回调
          _buildSection(context, '4. 带点击回调（点击试试）'),
          GreetingCard(
            name: '赵六',
            greeting: '点击我会弹出提示 👆',
            isOnline: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('你点击了赵六的卡片！'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 代码说明
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 说明',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'GreetingCard 是一个 StatelessWidget，\n'
                      '通过构造函数参数控制显示内容和行为。\n'
                      '头像在没有提供 avatarUrl 时会显示姓名首字母。\n'
                      '在线状态通过右下角小绿点指示。',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分节标题
  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
