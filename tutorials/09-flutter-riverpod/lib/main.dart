import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Flutter Riverpod 系统教程 — 导航首页
// =============================================================================

void main() {
  runApp(const ProviderScope(child: RiverpodTutorialApp()));
}

class RiverpodTutorialApp extends StatelessWidget {
  const RiverpodTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod 系统教程',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ChapterListPage(),
    );
  }
}

/// 章节数据
class Chapter {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;

  const Chapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const _chapters = [
  Chapter(number: '01', title: 'Riverpod 简介与环境搭建', subtitle: 'ProviderScope、第一个计数器', icon: Icons.rocket_launch),
  Chapter(number: '02', title: 'Provider 基础类型', subtitle: 'Provider、StateProvider', icon: Icons.inventory_2),
  Chapter(number: '03', title: 'Notifier 与 NotifierProvider', subtitle: 'build()、状态修改、copyWith', icon: Icons.edit_notifications),
  Chapter(number: '04', title: 'ref 详解', subtitle: 'watch / read / listen / select', icon: Icons.link),
  Chapter(number: '05', title: '异步 Provider', subtitle: 'FutureProvider、StreamProvider、AsyncNotifier', icon: Icons.cloud_sync),
  Chapter(number: '06', title: '修饰符', subtitle: 'autoDispose、family、keepAlive', icon: Icons.tune),
  Chapter(number: '07', title: 'Riverpod Generator', subtitle: '@riverpod 注解、代码生成', icon: Icons.auto_fix_high),
  Chapter(number: '08', title: 'Provider 组合与依赖', subtitle: '状态派生、依赖注入', icon: Icons.account_tree),
  Chapter(number: '09', title: '高级模式', subtitle: 'Observer、Container、Scope', icon: Icons.psychology),
  Chapter(number: '10', title: '测试', subtitle: '单元测试、mock、Widget 测试', icon: Icons.science),
  Chapter(number: '11', title: '最佳实践与常见陷阱', subtitle: '架构分层、性能优化', icon: Icons.star),
  Chapter(number: '12', title: '实战：天气查询 App', subtitle: 'MVVM + Repository + Riverpod', icon: Icons.wb_sunny),
];

class ChapterListPage extends StatelessWidget {
  const ChapterListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod 系统教程'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _chapters.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ch = _chapters[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(ch.number, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(ch.title),
              subtitle: Text(ch.subtitle),
              trailing: Icon(ch.icon),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('请运行: flutter run -t lib/ch${ch.number}_xxx.dart')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
