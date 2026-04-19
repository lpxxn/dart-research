import 'package:flutter/material.dart';

void main() {
  runApp(const NetworkTutorialApp());
}

class NetworkTutorialApp extends StatelessWidget {
  const NetworkTutorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 网络与数据',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const NetworkHomePage(),
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
  _ChapterInfo(number: '01', title: 'HTTP 基础', subtitle: 'http 包与基本请求', icon: Icons.http, file: 'ch01_http_basics.dart'),
  _ChapterInfo(number: '02', title: 'Dio', subtitle: 'Dio 网络库', icon: Icons.cloud_sync, file: 'ch02_dio.dart'),
  _ChapterInfo(number: '03', title: 'JSON 序列化', subtitle: 'JSON 序列化与反序列化', icon: Icons.data_object, file: 'ch03_json_serialization.dart'),
  _ChapterInfo(number: '04', title: '本地存储', subtitle: 'SharedPreferences / SQLite', icon: Icons.storage, file: 'ch04_local_storage.dart'),
  _ChapterInfo(number: '05', title: 'Repository 模式', subtitle: '数据层抽象', icon: Icons.account_tree, file: 'ch05_repository_pattern.dart'),
  _ChapterInfo(number: '06', title: 'WebSocket', subtitle: '实时通信', icon: Icons.cable, file: 'ch06_websocket.dart'),
  _ChapterInfo(number: '07', title: 'GraphQL', subtitle: 'GraphQL 客户端', icon: Icons.hub, file: 'ch07_graphql.dart'),
  _ChapterInfo(number: '08', title: '天气应用实战', subtitle: '综合网络项目', icon: Icons.wb_sunny, file: 'ch08_weather_app.dart'),
];

class NetworkHomePage extends StatelessWidget {
  const NetworkHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 网络与数据'),
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
