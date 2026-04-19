import 'package:flutter/material.dart';

void main() {
  runApp(const NavigationTutorialApp());
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
    title: '导航基础',
    description: 'Navigator.push/pop、MaterialPageRoute',
    file: 'ch01_navigation_basics.dart',
    icon: Icons.navigation,
  ),
  _Chapter(
    number: '02',
    title: '命名路由',
    description: 'routes 表、onGenerateRoute、参数传递',
    file: 'ch02_named_routes.dart',
    icon: Icons.signpost,
  ),
  _Chapter(
    number: '03',
    title: 'GoRouter',
    description: '声明式路由、嵌套路由、重定向',
    file: 'ch03_go_router.dart',
    icon: Icons.router,
  ),
  _Chapter(
    number: '04',
    title: '深度链接',
    description: 'Deep Linking 配置与平台集成',
    file: 'ch04_deep_linking.dart',
    icon: Icons.link,
  ),
  _Chapter(
    number: '05',
    title: '页面转场动画',
    description: '自定义 PageRouteBuilder、Hero 动画',
    file: 'ch05_page_transitions.dart',
    icon: Icons.animation,
  ),
  _Chapter(
    number: '06',
    title: 'Tab 与 Drawer',
    description: 'TabBar、BottomNavigationBar、Drawer',
    file: 'ch06_tab_drawer.dart',
    icon: Icons.tab,
  ),
  _Chapter(
    number: '07',
    title: '对话框',
    description: 'AlertDialog、BottomSheet、SnackBar',
    file: 'ch07_dialogs.dart',
    icon: Icons.chat_bubble_outline,
  ),
  _Chapter(
    number: '08',
    title: '导航实战',
    description: '登录流、Tab+嵌套导航、完整路由架构',
    file: 'ch08_navigation_practice.dart',
    icon: Icons.rocket_launch,
  ),
];

class NavigationTutorialApp extends StatelessWidget {
  const NavigationTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 导航与路由',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
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
        title: const Text('Flutter 导航与路由'),
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
