// =============================================================
// 第7章：代码生成 —— 手写 vs 生成代码对比展示
// =============================================================
//
// 本文件展示手写样板代码与代码生成工具的区别。
// 不依赖 build_runner，纯展示性代码。
//
// 运行方式: flutter run -t lib/ch07_code_generation.dart
// =============================================================

import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(const Ch07App());

class Ch07App extends StatelessWidget {
  const Ch07App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第7章：代码生成',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const CodeGenDemoPage(),
    );
  }
}

// =============================================================
// 一、手写方式 —— 所有样板代码都需要手动编写
// =============================================================

/// 手写的 User 类 —— 包含 fromJson / toJson / == / hashCode / copyWith / toString
class UserManual {
  final String name;
  final int age;
  final String email;
  final bool isActive;

  const UserManual({
    required this.name,
    required this.age,
    required this.email,
    this.isActive = false,
  });

  // JSON 反序列化
  factory UserManual.fromJson(Map<String, dynamic> json) {
    return UserManual(
      name: json['name'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'email': email,
      'is_active': isActive,
    };
  }

  // 相等性比较
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserManual &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age &&
          email == other.email &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(name, age, email, isActive);

  // copyWith
  UserManual copyWith({
    String? name,
    int? age,
    String? email,
    bool? isActive,
  }) {
    return UserManual(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'UserManual(name: $name, age: $age, email: $email, isActive: $isActive)';
}

// =============================================================
// 二、模拟 freezed + json_serializable 生成的代码
// (实际项目中这些由 build_runner 自动生成)
// =============================================================

/// 模拟使用 @freezed 注解的 User 类
/// 实际写法只需要：
///
/// ```dart
/// @freezed
/// class User with _$User {
///   const factory User({
///     required String name,
///     required int age,
///     required String email,
///     @Default(false) bool isActive,
///   }) = _User;
///
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
/// }
/// ```
class UserGenerated {
  final String name;
  final int age;
  final String email;
  final bool isActive;

  const UserGenerated({
    required this.name,
    required this.age,
    required this.email,
    this.isActive = false,
  });

  // 以下所有方法在 freezed 中是自动生成的 ✨
  factory UserGenerated.fromJson(Map<String, dynamic> json) {
    return UserGenerated(
      name: json['name'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'email': email,
        'is_active': isActive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGenerated &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age &&
          email == other.email &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(name, age, email, isActive);

  UserGenerated copyWith({
    String? name,
    int? age,
    String? email,
    bool? isActive,
  }) =>
      UserGenerated(
        name: name ?? this.name,
        age: age ?? this.age,
        email: email ?? this.email,
        isActive: isActive ?? this.isActive,
      );

  @override
  String toString() =>
      'UserGenerated(name: $name, age: $age, email: $email, isActive: $isActive)';
}

// =============================================================
// 三、模拟 freezed 联合类型（Sealed Class）
// =============================================================

/// 模拟 freezed 的联合类型
/// 实际写法：
/// ```dart
/// @freezed
/// sealed class Result<T> with _$Result<T> {
///   const factory Result.success(T data) = Success;
///   const factory Result.failure(String message) = Failure;
///   const factory Result.loading() = Loading;
/// }
/// ```
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

class Loading<T> extends Result<T> {
  const Loading();
}

// =============================================================
// 展示页面
// =============================================================

class CodeGenDemoPage extends StatefulWidget {
  const CodeGenDemoPage({super.key});

  @override
  State<CodeGenDemoPage> createState() => _CodeGenDemoPageState();
}

class _CodeGenDemoPageState extends State<CodeGenDemoPage> {
  // 示例数据
  final _sampleJson = {
    'name': '张三',
    'age': 28,
    'email': 'zhangsan@example.com',
    'is_active': true,
  };

  late UserManual _manualUser;
  late UserGenerated _generatedUser;
  Result<UserGenerated> _result = const Loading();

  @override
  void initState() {
    super.initState();
    _manualUser = UserManual.fromJson(_sampleJson);
    _generatedUser = UserGenerated.fromJson(_sampleJson);

    // 模拟异步加载
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _result = Success(_generatedUser);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第7章：代码生成'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 简介 ----
            _buildSection(
              theme,
              icon: Icons.auto_fix_high,
              title: '代码生成：减少样板代码',
              child: Text(
                'Dart 不像 Kotlin 有 data class，编写模型类需要大量样板代码。\n'
                '使用 json_serializable + freezed 可以自动生成这些代码。',
                style: theme.textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 16),

            // ---- 手写 vs 生成 对比 ----
            _buildSection(
              theme,
              icon: Icons.compare_arrows,
              title: '手写 vs 代码生成',
              child: _buildComparisonTable(theme),
            ),

            const SizedBox(height: 16),

            // ---- JSON 序列化演示 ----
            _buildSection(
              theme,
              icon: Icons.data_object,
              title: 'JSON 序列化演示',
              child: _buildJsonDemo(theme),
            ),

            const SizedBox(height: 16),

            // ---- copyWith 演示 ----
            _buildSection(
              theme,
              icon: Icons.copy,
              title: 'copyWith 演示',
              child: _buildCopyWithDemo(theme),
            ),

            const SizedBox(height: 16),

            // ---- 相等性比较演示 ----
            _buildSection(
              theme,
              icon: Icons.check_circle,
              title: '相等性比较演示',
              child: _buildEqualityDemo(theme),
            ),

            const SizedBox(height: 16),

            // ---- 联合类型演示 ----
            _buildSection(
              theme,
              icon: Icons.account_tree,
              title: '联合类型 (Sealed Class) 演示',
              child: _buildSealedClassDemo(theme),
            ),

            const SizedBox(height: 16),

            // ---- freezed 源码对比 ----
            _buildSection(
              theme,
              icon: Icons.code,
              title: '实际项目中只需写这些',
              child: _buildFreezedCodePreview(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Widget child,
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
            child,
          ],
        ),
      ),
    );
  }

  // 手写 vs 生成 对比表
  Widget _buildComparisonTable(ThemeData theme) {
    final rows = [
      ['特性', '手写', 'freezed'],
      ['fromJson / toJson', '~20 行', '自动生成'],
      ['== / hashCode', '~10 行', '自动生成'],
      ['copyWith', '~10 行', '自动生成'],
      ['toString', '~3 行', '自动生成'],
      ['联合类型', '手写 sealed class', '@freezed 注解'],
      ['添加字段', '改 5+ 处', '改 1 处，重新生成'],
    ];

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return TableRow(
          decoration: isHeader
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                )
              : null,
          children: entry.value
              .map((cell) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      cell,
                      style: isHeader
                          ? theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : theme.textTheme.bodySmall,
                    ),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  // JSON 序列化演示
  Widget _buildJsonDemo(ThemeData theme) {
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(_manualUser.toJson());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('输入 JSON:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(const JsonEncoder.withIndent('  ').convert(_sampleJson), theme),
        const SizedBox(height: 12),
        Text('fromJson → 对象:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(_manualUser.toString(), theme),
        const SizedBox(height: 12),
        Text('对象 → toJson:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(jsonString, theme),
      ],
    );
  }

  // copyWith 演示
  Widget _buildCopyWithDemo(ThemeData theme) {
    final original = _generatedUser;
    final modified = original.copyWith(name: '李四', age: 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('原始对象:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(original.toString(), theme),
        const SizedBox(height: 8),
        Text('copyWith(name: "李四", age: 30):', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(modified.toString(), theme),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '原始对象不变（不可变数据），返回新对象',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 相等性比较演示
  Widget _buildEqualityDemo(ThemeData theme) {
    final user1 = UserGenerated.fromJson(_sampleJson);
    final user2 = UserGenerated.fromJson(_sampleJson);
    final user3 = user1.copyWith(name: '李四');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _equalityRow(theme, 'user1 == user2 (相同数据)', user1 == user2),
        const SizedBox(height: 4),
        _equalityRow(theme, 'user1 == user3 (不同 name)', user1 == user3),
        const SizedBox(height: 4),
        _equalityRow(
            theme, 'identical(user1, user2)', identical(user1, user2)),
        const SizedBox(height: 8),
        Text(
          '基于值的相等性比较，而不是引用比较',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _equalityRow(ThemeData theme, String label, bool result) {
    return Row(
      children: [
        Icon(
          result ? Icons.check_circle : Icons.cancel,
          color: result ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Text(
          result.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: result ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  // 联合类型演示
  Widget _buildSealedClassDemo(ThemeData theme) {
    // 使用 switch 表达式展示联合类型
    final displayText = switch (_result) {
      Success(:final data) => '✅ 加载成功: ${data.name}',
      Failure(:final message) => '❌ 加载失败: $message',
      Loading() => '⏳ 加载中...',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayText, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text('模式匹配 (switch 表达式):', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        _codeText(
          'final text = switch (result) {\n'
          '  Success(:final data) => "成功: \${data.name}",\n'
          '  Failure(:final message) => "失败: \$message",\n'
          '  Loading() => "加载中...",\n'
          '};',
          theme,
        ),
        const SizedBox(height: 12),
        // 交互按钮
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(
                  () => _result = Success(_generatedUser)),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('成功'),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(
                  () => _result = const Failure('网络超时')),
              icon: const Icon(Icons.error, size: 16),
              label: const Text('失败'),
            ),
            ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _result = const Loading()),
              icon: const Icon(Icons.hourglass_empty, size: 16),
              label: const Text('加载中'),
            ),
          ],
        ),
      ],
    );
  }

  // freezed 代码预览
  Widget _buildFreezedCodePreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('使用 freezed 只需写这些：',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.green.shade700)),
        ),
        const SizedBox(height: 8),
        _codeText(_freezedExample, theme),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('手写需要写 ~60 行代码 😩',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.red.shade700)),
        ),
      ],
    );
  }

  Widget _codeText(String text, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

const _freezedExample = '''
@freezed
class User with _\$User {
  const factory User({
    required String name,
    required int age,
    required String email,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json)
      => _\$UserFromJson(json);
}

// 自动获得:
// ✅ fromJson / toJson
// ✅ == / hashCode
// ✅ copyWith
// ✅ toString
''';
