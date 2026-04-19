import 'package:flutter/material.dart';

void main() {
  runApp(const LayoutTutorialApp());
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
    title: '布局原理',
    description: '约束向下传递、尺寸向上报告、父决定位置',
    file: 'ch01_layout_principle.dart',
    icon: Icons.architecture,
  ),
  _Chapter(
    number: '02',
    title: '单子布局组件',
    description: 'Container、Align、Center、SizedBox 等',
    file: 'ch02_single_child_layout.dart',
    icon: Icons.crop_square,
  ),
  _Chapter(
    number: '03',
    title: '多子布局组件',
    description: 'Row、Column、Wrap、Flow 等',
    file: 'ch03_multi_child_layout.dart',
    icon: Icons.view_column,
  ),
  _Chapter(
    number: '04',
    title: '层叠布局 (Stack)',
    description: 'Stack、Positioned、IndexedStack',
    file: 'ch04_stack_layout.dart',
    icon: Icons.layers,
  ),
  _Chapter(
    number: '05',
    title: '可滚动列表',
    description: 'ListView、GridView、PageView',
    file: 'ch05_scrollable_list.dart',
    icon: Icons.view_list,
  ),
  _Chapter(
    number: '06',
    title: 'Sliver 体系',
    description: 'CustomScrollView、SliverList、SliverGrid',
    file: 'ch06_sliver_system.dart',
    icon: Icons.view_day,
  ),
  _Chapter(
    number: '07',
    title: '响应式布局',
    description: 'MediaQuery、LayoutBuilder、自适应设计',
    file: 'ch07_responsive_layout.dart',
    icon: Icons.devices,
  ),
  _Chapter(
    number: '08',
    title: '布局调试',
    description: 'Debug painting、DevTools、常见溢出修复',
    file: 'ch08_layout_debugging.dart',
    icon: Icons.bug_report,
  ),
];

class LayoutTutorialApp extends StatelessWidget {
  const LayoutTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 布局与列表',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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
        title: const Text('Flutter 布局与列表'),
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
