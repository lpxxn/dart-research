// =============================================================
// 第10章：发布与 CI/CD —— 配置说明展示页
// =============================================================
//
// 本文件展示 Flutter 应用发布和 CI/CD 流程的关键配置信息。
//
// 运行方式: flutter run -t lib/ch10_release_cicd.dart
// =============================================================

import 'package:flutter/material.dart';

void main() => runApp(const Ch10App());

class Ch10App extends StatelessWidget {
  const Ch10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第10章：发布与 CI/CD',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ReleaseCiCdPage(),
    );
  }
}

// =============================================================
// 主页面 —— 展示发布和 CI/CD 的各个环节
// =============================================================

class ReleaseCiCdPage extends StatelessWidget {
  const ReleaseCiCdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第10章：发布与 CI/CD'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.build), text: '构建命令'),
              Tab(icon: Icon(Icons.security), text: '签名与混淆'),
              Tab(icon: Icon(Icons.settings), text: 'Flavor 配置'),
              Tab(icon: Icon(Icons.rocket_launch), text: 'CI/CD'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BuildCommandsTab(),
            _SigningTab(),
            _FlavorTab(),
            _CiCdTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 一、构建命令
// =============================================================

class _BuildCommandsTab extends StatelessWidget {
  const _BuildCommandsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          theme,
          icon: Icons.info,
          title: '三种构建模式',
          content: const _BuildModesTable(),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme,
          icon: Icons.terminal,
          title: '构建命令',
          content: const _CommandsList(commands: [
            _CommandItem(
              platform: 'Android APK',
              command: 'flutter build apk --release',
              output: 'build/app/outputs/flutter-apk/app-release.apk',
            ),
            _CommandItem(
              platform: 'Android Bundle',
              command: 'flutter build appbundle --release',
              output: 'build/app/outputs/bundle/release/app-release.aab',
            ),
            _CommandItem(
              platform: 'iOS',
              command: 'flutter build ipa --release',
              output: 'build/ios/ipa/Runner.ipa',
            ),
            _CommandItem(
              platform: 'Web',
              command: 'flutter build web --release',
              output: 'build/web/',
            ),
            _CommandItem(
              platform: 'macOS',
              command: 'flutter build macos --release',
              output: 'build/macos/Build/Products/Release/',
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme,
          icon: Icons.tune,
          title: '自定义参数',
          content: const _CodePreview(code: '''
# 自定义版本号
flutter build apk --build-name=1.2.0 --build-number=42

# 编译时常量
flutter build apk \\
  --dart-define=API_URL=https://api.prod.com \\
  --dart-define=ENV=production

# 在代码中使用
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost',
);'''),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme,
          icon: Icons.compress,
          title: '体积优化',
          content: const _CodePreview(code: '''
# 分架构 APK（减小体积）
flutter build apk --split-per-abi

# 移除未使用的图标
flutter build apk --tree-shake-icons

# 分析 APK 体积
flutter build apk --analyze-size'''),
        ),
      ],
    );
  }
}

// =============================================================
// 二、签名与混淆
// =============================================================

class _SigningTab extends StatelessWidget {
  const _SigningTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          theme,
          icon: Icons.key,
          title: 'Android 签名配置',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. 创建 keystore', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              const _CodePreview(code: '''
keytool -genkey -v \\
  -keystore ~/key.jks \\
  -keyalg RSA -keysize 2048 \\
  -validity 10000 \\
  -alias my-key-alias'''),
              const SizedBox(height: 12),
              Text('2. 创建 key.properties（不要提交到 Git！）',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              const _CodePreview(code: '''
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=my-key-alias
storeFile=/path/to/key.jks'''),
              const SizedBox(height: 12),
              Text('3. 配置 build.gradle',
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              const _CodePreview(code: '''
android {
  signingConfigs {
    release {
      keyAlias keystoreProperties['keyAlias']
      keyPassword keystoreProperties['keyPassword']
      storeFile file(keystoreProperties['storeFile'])
      storePassword keystoreProperties['storePassword']
    }
  }
}'''),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme,
          icon: Icons.visibility_off,
          title: '代码混淆',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CodePreview(code: '''
# 启用混淆 + 分离调试信息
flutter build apk \\
  --obfuscate \\
  --split-debug-info=build/debug-info

# 还原混淆后的崩溃日志
flutter symbolize \\
  -i crash_log.txt \\
  -d build/debug-info/'''),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '务必保存 debug-info 目录！没有它就无法还原崩溃日志。',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          theme,
          icon: Icons.no_encryption,
          title: '.gitignore 安全配置',
          content: const _CodePreview(code: '''
# 签名文件 —— 绝对不要提交！
android/key.properties
android/app/keystore.jks
ios/fastlane/AuthKey_*.p8

# 环境配置
config/*.json
.env

# 构建产物
build/
*.apk
*.aab
*.ipa'''),
        ),
      ],
    );
  }
}

// =============================================================
// 三、Flavor 环境配置
// =============================================================

class _FlavorTab extends StatelessWidget {
  const _FlavorTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 演示当前运行环境
    const currentEnv = String.fromEnvironment('ENV', defaultValue: 'dev');
    const currentApi = String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:8080',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 当前环境信息
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.dns, size: 32),
                const SizedBox(height: 8),
                Text('当前运行环境', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _envInfoRow(theme, 'ENV', currentEnv),
                _envInfoRow(theme, 'API_URL', currentApi),
                const SizedBox(height: 8),
                Text(
                  '提示: 使用 --dart-define=ENV=prod 切换环境',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.layers,
          title: 'Flavor 概念',
          content: const _FlavorTable(),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.code,
          title: '使用 --dart-define',
          content: const _CodePreview(code: '''
# 开发环境
flutter run \\
  --dart-define=ENV=dev \\
  --dart-define=API_URL=http://dev-api.example.com

# 生产环境
flutter build apk \\
  --dart-define=ENV=prod \\
  --dart-define=API_URL=https://api.example.com

# 从文件加载配置
flutter run --dart-define-from-file=config/dev.json'''),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.settings_applications,
          title: '代码中读取环境变量',
          content: const _CodePreview(code: '''
class AppConfig {
  static const env = String.fromEnvironment(
    'ENV', defaultValue: 'dev'
  );
  static const apiUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'http://localhost:8080'
  );

  static bool get isDev => env == 'dev';
  static bool get isProd => env == 'prod';
}'''),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.android,
          title: 'Android Flavor 配置',
          content: const _CodePreview(code: '''
// android/app/build.gradle
android {
  flavorDimensions "environment"
  productFlavors {
    dev {
      dimension "environment"
      applicationIdSuffix ".dev"
      versionNameSuffix "-dev"
    }
    prod {
      dimension "environment"
    }
  }
}

// 运行命令
// flutter run --flavor dev
// flutter build apk --flavor prod --release'''),
        ),
      ],
    );
  }

  Widget _envInfoRow(ThemeData theme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$key: ', style: theme.textTheme.bodySmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// 四、CI/CD 配置
// =============================================================

class _CiCdTab extends StatelessWidget {
  const _CiCdTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CI/CD 流水线图
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('CI/CD 流水线', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                const _PipelineVisualization(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.check_circle,
          title: 'GitHub Actions —— CI 基础',
          content: const _CodePreview(code: '''
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          cache: true
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - run: dart format --output=none \\
             --set-exit-if-changed .'''),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.cloud_upload,
          title: 'GitHub Actions —— Android 发布',
          content: const _CodePreview(code: '''
# .github/workflows/android-release.yml
name: Android Release
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test

      # 构建 + 签名
      - run: flutter build appbundle --release \\
             --obfuscate \\
             --split-debug-info=build/debug-info

      # 上传到 GitHub Release
      - uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/bundle/
                 release/app-release.aab'''),
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          theme,
          icon: Icons.web,
          title: 'Web 部署到 GitHub Pages',
          content: const _CodePreview(code: '''
# .github/workflows/deploy-web.yml
name: Deploy Web
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release \\
             --base-href /\${{ github.event
             .repository.name }}/
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: \${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web'''),
        ),

        const SizedBox(height: 12),

        // 发布检查清单
        _buildInfoCard(
          theme,
          icon: Icons.checklist,
          title: '发布检查清单',
          content: const _ReleaseChecklist(),
        ),

        const SizedBox(height: 12),

        // Secrets 管理
        _buildInfoCard(
          theme,
          icon: Icons.vpn_key,
          title: 'GitHub Secrets 配置',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '在 Settings → Secrets and variables → Actions 中配置：',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...[
                ('KEYSTORE_BASE64', 'Android keystore (base64)'),
                ('STORE_PASSWORD', 'keystore 密码'),
                ('KEY_PASSWORD', 'key 密码'),
                ('KEY_ALIAS', 'key 别名'),
                ('PLAY_STORE_JSON', 'Google Play 服务账号'),
                ('APPSTORE_API_KEY_ID', 'App Store Connect Key'),
              ].map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 12,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Text(item.$1,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(item.$2,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================
// 通用组件
// =============================================================

Widget _buildInfoCard(
  ThemeData theme, {
  required IconData icon,
  required String title,
  required Widget content,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    ),
  );
}

/// 代码预览组件
class _CodePreview extends StatelessWidget {
  final String code;

  const _CodePreview({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code.trim(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 构建模式对比表
class _BuildModesTable extends StatelessWidget {
  const _BuildModesTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      ['模式', '编译', '用途', '参数'],
      ['Debug', 'JIT', '开发调试', '默认'],
      ['Profile', 'AOT', '性能分析', '--profile'],
      ['Release', 'AOT', '发布上线', '--release'],
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return TableRow(
          decoration: isHeader
              ? BoxDecoration(color: theme.colorScheme.primaryContainer)
              : null,
          children: entry.value.map((cell) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Text(cell,
                  style: isHeader
                      ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                      : const TextStyle(fontSize: 12)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// 构建命令列表
class _CommandsList extends StatelessWidget {
  final List<_CommandItem> commands;

  const _CommandsList({required this.commands});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: commands.map((cmd) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cmd.platform,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(cmd.command,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
              const SizedBox(height: 2),
              Text('→ ${cmd.output}',
                  style: TextStyle(
                      fontSize: 10, color: theme.colorScheme.outline)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CommandItem {
  final String platform;
  final String command;
  final String output;

  const _CommandItem({
    required this.platform,
    required this.command,
    required this.output,
  });
}

/// Flavor 对比表
class _FlavorTable extends StatelessWidget {
  const _FlavorTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      ['环境', '服务器', 'App ID 后缀', '图标'],
      ['dev', '测试服务器', '.dev', '🟢'],
      ['staging', '预发布服务器', '.staging', '🟡'],
      ['prod', '生产服务器', '(无)', '🔵'],
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return TableRow(
          decoration: isHeader
              ? BoxDecoration(color: theme.colorScheme.primaryContainer)
              : null,
          children: entry.value.map((cell) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Text(cell,
                  style: isHeader
                      ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                      : const TextStyle(fontSize: 12)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// CI/CD 流水线可视化
class _PipelineVisualization extends StatelessWidget {
  const _PipelineVisualization();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = [
      ('📝', '代码提交', 'push / PR'),
      ('🔍', '代码分析', 'flutter analyze'),
      ('🧪', '运行测试', 'flutter test'),
      ('🏗️', '构建', 'flutter build'),
      ('🚀', '发布', 'deploy'),
    ];

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Text(stages[i].$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stages[i].$2,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(stages[i].$3,
                        style: TextStyle(
                            fontSize: 11, color: theme.colorScheme.outline)),
                  ],
                ),
              ],
            ),
          ),
          if (i < stages.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(Icons.arrow_downward,
                  size: 20, color: theme.colorScheme.outline),
            ),
        ],
      ],
    );
  }
}

/// 发布检查清单
class _ReleaseChecklist extends StatefulWidget {
  const _ReleaseChecklist();

  @override
  State<_ReleaseChecklist> createState() => _ReleaseChecklistState();
}

class _ReleaseChecklistState extends State<_ReleaseChecklist> {
  final _items = [
    _CheckItem('版本号已更新'),
    _CheckItem('所有测试通过'),
    _CheckItem('flutter analyze 无警告'),
    _CheckItem('代码已混淆'),
    _CheckItem('调试信息已分离保存'),
    _CheckItem('隐私政策已更新'),
    _CheckItem('应用截图已更新'),
    _CheckItem('更新日志已编写'),
    _CheckItem('签名文件安全保管'),
  ];

  @override
  Widget build(BuildContext context) {
    final checked = _items.where((i) => i.checked).length;
    final total = _items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: checked / total),
        const SizedBox(height: 4),
        Text('$checked / $total 已完成',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        ..._items.map((item) => CheckboxListTile(
              value: item.checked,
              onChanged: (v) => setState(() => item.checked = v ?? false),
              title: Text(item.label, style: const TextStyle(fontSize: 13)),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }
}

class _CheckItem {
  final String label;
  bool checked;

  _CheckItem(this.label) : checked = false;
}
