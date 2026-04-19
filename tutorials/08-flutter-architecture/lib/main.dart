import 'package:flutter/material.dart';

void main() {
  runApp(const ArchitectureTutorialApp());
}

class ArchitectureTutorialApp extends StatelessWidget {
  const ArchitectureTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 架构与工程化',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ArchitectureHomePage(),
    );
  }
}

class _ChapterInfo {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String file;

  const _ChapterInfo({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
  });
}

const _chapters = <_ChapterInfo>[
  _ChapterInfo(number: '01', title: '项目结构', subtitle: '目录与分层组织', icon: Icons.folder_open, file: 'ch01_project_structure.dart'),
  _ChapterInfo(number: '02', title: '架构模式', subtitle: 'MVC / MVVM / Clean', icon: Icons.architecture, file: 'ch02_architecture_patterns.dart'),
  _ChapterInfo(number: '03', title: '依赖注入', subtitle: 'GetIt / Injectable', icon: Icons.settings_input_component, file: 'ch03_dependency_injection.dart'),
  _ChapterInfo(number: '04', title: '单元测试', subtitle: 'test / mockito', icon: Icons.science, file: 'ch04_unit_testing.dart'),
  _ChapterInfo(number: '05', title: 'Widget 测试', subtitle: 'WidgetTester', icon: Icons.widgets, file: 'ch05_widget_testing.dart'),
  _ChapterInfo(number: '06', title: '集成测试', subtitle: 'integration_test', icon: Icons.integration_instructions, file: 'ch06_integration_testing.dart'),
  _ChapterInfo(number: '07', title: '代码生成', subtitle: 'build_runner / freezed', icon: Icons.auto_fix_high, file: 'ch07_code_generation.dart'),
  _ChapterInfo(number: '08', title: '国际化', subtitle: 'i18n / l10n', icon: Icons.language, file: 'ch08_internationalization.dart'),
  _ChapterInfo(number: '09', title: '性能优化', subtitle: 'DevTools / 优化技巧', icon: Icons.speed, file: 'ch09_performance.dart'),
  _ChapterInfo(number: '10', title: '发布与 CI/CD', subtitle: '构建 / 签名 / 流水线', icon: Icons.rocket_launch, file: 'ch10_release_cicd.dart'),
];

class ArchitectureHomePage extends StatelessWidget {
  const ArchitectureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 架构与工程化'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final ch = _chapters[index];
                return Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('请运行: flutter run -t lib/${ch.file}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(ch.icon, size: 32, color: colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            '第 ${ch.number} 章',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              '请使用 flutter run -t lib/chXX_xxx.dart 运行各章节示例',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
