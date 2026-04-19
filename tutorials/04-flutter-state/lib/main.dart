import 'package:flutter/material.dart';

void main() {
  runApp(const StateTutorialApp());
}

class _Chapter {
  final String number;
  final String title;
  final String description;
  final String file;
  final IconData icon;

  const _Chapter({
    required this.number,
    required this.title,
    required this.description,
    required this.file,
    required this.icon,
  });
}

const _chapters = [
  _Chapter(
    number: '01',
    title: '状态管理概论',
    description: '什么是状态、为什么需要状态管理、分类与选型思路',
    file: 'ch01_state_overview.dart',
    icon: Icons.lightbulb_outline,
  ),
  _Chapter(
    number: '02',
    title: '原生状态管理',
    description: 'setState、InheritedWidget、ValueNotifier',
    file: 'ch02_native_state.dart',
    icon: Icons.flutter_dash,
  ),
  _Chapter(
    number: '03',
    title: 'Provider',
    description: 'ChangeNotifierProvider、Consumer、Selector',
    file: 'ch03_provider.dart',
    icon: Icons.account_tree,
  ),
  _Chapter(
    number: '04',
    title: 'Riverpod',
    description: 'Provider 进化版，编译期安全的状态管理',
    file: 'ch04_riverpod.dart',
    icon: Icons.water_drop,
  ),
  _Chapter(
    number: '05',
    title: 'BLoC',
    description: 'Event → Bloc → State，业务逻辑组件模式',
    file: 'ch05_bloc.dart',
    icon: Icons.view_module,
  ),
  _Chapter(
    number: '06',
    title: 'GetX',
    description: '轻量级响应式状态管理与路由',
    file: 'ch06_getx.dart',
    icon: Icons.flash_on,
  ),
  _Chapter(
    number: '07',
    title: '状态持久化',
    description: 'SharedPreferences、Hive、SQLite 与状态恢复',
    file: 'ch07_state_persistence.dart',
    icon: Icons.save,
  ),
  _Chapter(
    number: '08',
    title: '方案对比',
    description: '各方案优缺点与适用场景综合对比',
    file: 'ch08_state_comparison.dart',
    icon: Icons.compare_arrows,
  ),
];

class StateTutorialApp extends StatelessWidget {
  const StateTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 状态管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 状态管理'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chapters.length + 1,
        itemBuilder: (context, index) {
          if (index == _chapters.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '请使用 flutter run -t lib/chXX_xxx.dart 运行各章节示例',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            );
          }

          final ch = _chapters[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(ch.icon, color: colorScheme.onPrimaryContainer),
              ),
              title: Text(
                '第 ${ch.number} 章  ${ch.title}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ch.description),
              ),
              trailing: Icon(
                Icons.terminal,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
