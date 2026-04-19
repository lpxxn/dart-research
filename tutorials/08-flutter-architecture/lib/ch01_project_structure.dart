import 'package:flutter/material.dart';

void main() => runApp(const Ch01App());

/// 第一章：项目结构展示应用
class Ch01App extends StatelessWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 项目结构',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ProjectStructurePage(),
    );
  }
}

/// 项目结构展示页面
class ProjectStructurePage extends StatelessWidget {
  const ProjectStructurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('第一章：项目结构'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 页面标题区域
          _buildHeader(context),
          const SizedBox(height: 16),

          // 默认项目结构
          _StructureCard(
            title: 'Flutter 默认项目结构',
            icon: Icons.folder_open,
            iconColor: Colors.amber,
            description: '运行 flutter create 后生成的标准目录结构',
            treeContent: _defaultStructure,
          ),
          const SizedBox(height: 12),

          // Feature-first 结构
          _StructureCard(
            title: 'Feature-first（按功能组织）',
            icon: Icons.widgets,
            iconColor: Colors.green,
            description: '按业务功能划分目录，每个功能包含完整的分层结构。适合中大型项目和团队协作。',
            treeContent: _featureFirstStructure,
            badge: '推荐',
            badgeColor: Colors.green,
          ),
          const SizedBox(height: 12),

          // Layer-first 结构
          _StructureCard(
            title: 'Layer-first（按层级组织）',
            icon: Icons.layers,
            iconColor: Colors.orange,
            description: '按技术层级划分目录，结构简单直观。适合小型项目和快速原型。',
            treeContent: _layerFirstStructure,
          ),
          const SizedBox(height: 12),

          // 推荐的完整结构
          _StructureCard(
            title: '推荐的完整项目结构',
            icon: Icons.star,
            iconColor: Colors.blue,
            description: 'Feature-first + 清晰分层的最佳实践目录结构，包含 core、shared、features 等模块。',
            treeContent: _recommendedStructure,
            badge: '最佳实践',
            badgeColor: Colors.blue,
          ),
          const SizedBox(height: 12),

          // Barrel File 说明卡片
          _buildBarrelFileCard(context),
          const SizedBox(height: 12),

          // 对比表格卡片
          _buildComparisonCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建页面顶部标题区域
  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, color: colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Text(
                'Flutter 架构教程',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '良好的项目结构是可维护、可扩展应用的基石。\n本章将详细介绍几种常见的目录组织方式及其适用场景。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建 Barrel File 说明卡片
  Widget _buildBarrelFileCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.purple, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Barrel File（桶文件）',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              '将模块内多个文件统一导出，简化 import 语句：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // 对比：使用前
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❌ 不使用 Barrel File:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "import '.../auth/domain/entities/user.dart';\n"
                    "import '.../auth/domain/usecases/login.dart';\n"
                    "import '.../auth/presentation/screens/login_screen.dart';",
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 对比：使用后
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ 使用 Barrel File:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "import 'package:my_app/features/auth/auth.dart';",
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 好处列表
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BenefitItem(text: '简化导入语句，代码更整洁'),
                  _BenefitItem(text: '明确定义模块的公开 API'),
                  _BenefitItem(text: '文件重构时只需修改 barrel file'),
                  _BenefitItem(text: '促进模块化设计思维'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建对比表格卡片
  Widget _buildComparisonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.teal, size: 28),
                const SizedBox(width: 10),
                Text(
                  '组织方式对比',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 20),
            // 表格
            Table(
              border: TableBorder.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                // 表头
                _buildTableRow(
                  context,
                  cells: ['维度', 'Layer-first', 'Feature-first'],
                  isHeader: true,
                ),
                _buildTableRow(
                  context,
                  cells: ['复杂度', '低', '中高'],
                ),
                _buildTableRow(
                  context,
                  cells: ['可扩展性', '一般', '优秀 ⭐'],
                ),
                _buildTableRow(
                  context,
                  cells: ['团队协作', '容易冲突', '各自独立 ⭐'],
                ),
                _buildTableRow(
                  context,
                  cells: ['功能内聚', '低', '高 ⭐'],
                ),
                _buildTableRow(
                  context,
                  cells: ['学习曲线', '平缓 ⭐', '较陡'],
                ),
                _buildTableRow(
                  context,
                  cells: ['重构成本', '高', '低 ⭐'],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建表格行
  TableRow _buildTableRow(
    BuildContext context, {
    required List<String> cells,
    bool isHeader = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            )
          : null,
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            cell,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 结构展示卡片组件
class _StructureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String description;
  final String treeContent;
  final String? badge;
  final Color? badgeColor;

  const _StructureCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.description,
    required this.treeContent,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.blue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ),
        initiallyExpanded: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: [
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: SelectableText(
              treeContent,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 好处条目组件
class _BenefitItem extends StatelessWidget {
  final String text;

  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ============================================================
// 目录树字符串常量
// ============================================================

/// Flutter 默认项目结构
const _defaultStructure = '''
my_app/
├── android/          # Android 平台工程
├── ios/              # iOS 平台工程
├── linux/            # Linux 桌面平台
├── macos/            # macOS 桌面平台
├── web/              # Web 平台
├── windows/          # Windows 桌面平台
├── lib/              # 🔥 核心代码目录
│   └── main.dart     #    应用入口
├── test/             # 测试目录
├── pubspec.yaml      # 📦 项目配置
├── pubspec.lock      # 依赖锁定
├── analysis_options.yaml  # 代码分析配置
└── README.md         # 说明文档''';

/// Feature-first 组织结构
const _featureFirstStructure = '''
lib/
├── main.dart
├── app/                    # 应用配置
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── features/               # 🔥 按功能划分
│   ├── auth/               #    认证模块
│   │   ├── auth.dart       #    📦 Barrel file
│   │   ├── data/           #    数据层
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/         #    领域层
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/   #    展示层
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/
│   ├── products/           #    商品模块
│   └── orders/             #    订单模块
├── shared/                 # 共享组件
│   ├── widgets/
│   ├── utils/
│   └── extensions/
└── core/                   # 核心基础设施
    ├── network/
    ├── storage/
    └── errors/''';

/// Layer-first 组织结构
const _layerFirstStructure = '''
lib/
├── main.dart
├── models/            # 数据模型层
│   ├── user.dart
│   ├── product.dart
│   └── order.dart
├── services/          # 服务层
│   ├── auth_service.dart
│   ├── product_service.dart
│   └── order_service.dart
├── repositories/      # 仓库层
│   ├── user_repository.dart
│   └── product_repository.dart
├── providers/         # 状态管理层
│   ├── auth_provider.dart
│   └── product_provider.dart
├── screens/           # 页面层
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── product_detail_screen.dart
├── widgets/           # 可复用组件
│   ├── custom_button.dart
│   └── loading_indicator.dart
└── utils/             # 工具类
    ├── constants.dart
    └── validators.dart''';

/// 推荐的完整项目结构
const _recommendedStructure = '''
lib/
├── main.dart                  # 应用入口
├── app/                       # 应用级配置
│   ├── app.dart               #   MaterialApp
│   ├── router/                #   路由
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   └── theme/                 #   主题
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
├── core/                      # 核心基础（与业务无关）
│   ├── network/               #   网络层
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── interceptors/
│   ├── storage/               #   存储层
│   ├── errors/                #   错误处理
│   └── di/                    #   依赖注入
│       └── injection.dart
├── features/                  # 🔥 功能模块
│   ├── auth/
│   │   ├── auth.dart          #   📦 Barrel file
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── home/
│   │   ├── home.dart
│   │   └── ...
│   └── settings/
│       ├── settings.dart
│       └── ...
├── shared/                    # 跨功能共享
│   ├── widgets/
│   ├── extensions/
│   ├── utils/
│   └── constants/
├── l10n/                      # 国际化
│   ├── app_en.arb
│   └── app_zh.arb
└── generated/                 # 自动生成代码
    └── l10n/''';
