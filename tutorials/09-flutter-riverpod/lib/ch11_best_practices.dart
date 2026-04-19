import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第十一章：最佳实践与常见陷阱
// 演示：正确 vs 错误用法对比、性能优化、架构分层
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 演示用 Provider
// -----------------------------------------------------------------------------

class UserProfile {
  final String name;
  final int age;
  final String email;
  const UserProfile({required this.name, required this.age, required this.email});

  UserProfile copyWith({String? name, int? age, String? email}) => UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        email: email ?? this.email,
      );
}

class UserNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() =>
      const UserProfile(name: 'Alice', age: 25, email: 'alice@example.com');

  void updateName(String name) => state = state.copyWith(name: name);
  void incrementAge() => state = state.copyWith(age: state.age + 1);
}

final userProvider = NotifierProvider<UserNotifier, UserProfile>(UserNotifier.new);
final counterProvider = StateProvider<int>((ref) => 0);

/// 演示：派生 Provider（推荐）vs 冗余状态（不推荐）
final todoListProvider = StateProvider<List<String>>((ref) => [
      '学习 select 优化',
      '理解 Consumer',
      '避免常见陷阱',
      '掌握架构分层',
    ]);

final activeTodoCountProvider = Provider<int>((ref) {
  return ref.watch(todoListProvider).length;
});

// 重建计数器（用于演示性能）
int _fullRebuildCount = 0;
int _selectRebuildCount = 0;

// -----------------------------------------------------------------------------
// 2. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch11App()));
}

class Ch11App extends StatelessWidget {
  const Ch11App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch11 - 最佳实践',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const BestPracticePage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 主页面
// -----------------------------------------------------------------------------

class BestPracticePage extends StatelessWidget {
  const BestPracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第十一章：最佳实践'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '性能优化'),
              Tab(text: '常见陷阱'),
              Tab(text: '架构分层'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PerformanceTab(),
            _PitfallsTab(),
            _ArchitectureTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1：性能优化 — select vs 全量监听
// -----------------------------------------------------------------------------

class _PerformanceTab extends ConsumerWidget {
  const _PerformanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('select 精确监听 vs 全量监听',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('修改 age 时，观察两种 Widget 的重建次数：'),
          const SizedBox(height: 16),

          // 操作按钮
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => ref.read(userProvider.notifier).incrementAge(),
                child: const Text('修改 Age +1'),
              ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(userProvider.notifier).updateName('Bob'),
                child: const Text('修改 Name → Bob'),
              ),
              OutlinedButton(
                onPressed: () {
                  _fullRebuildCount = 0;
                  _selectRebuildCount = 0;
                  ref.read(userProvider.notifier).updateName('Alice');
                },
                child: const Text('重置计数'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 全量监听
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❌ 全量 ref.watch(userProvider)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('name 和 age 变化都会重建'),
                  _FullWatchWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // select 监听
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ select: ref.watch(userProvider.select((u) => u.name))',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('只有 name 变化才重建'),
                  _SelectWatchWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Consumer 局部重建
          Text('Consumer 局部重建', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('只有 Consumer 内部会因 counter 变化而重建：'),
                  const SizedBox(height: 8),
                  const Text('这段文字不会重建 ✅'),
                  const SizedBox(height: 8),
                  Consumer(builder: (_, ref, __) {
                    final count = ref.watch(counterProvider);
                    return FilledButton(
                      onPressed: () =>
                          ref.read(counterProvider.notifier).state++,
                      child: Text('Consumer 内计数器: $count'),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text('这段文字也不会重建 ✅'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullWatchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    _fullRebuildCount++;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('Name: ${user.name} | 重建次数: $_fullRebuildCount',
          style: const TextStyle(fontFamily: 'monospace')),
    );
  }
}

class _SelectWatchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProvider.select((u) => u.name));
    _selectRebuildCount++;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('Name: $name | 重建次数: $_selectRebuildCount',
          style: const TextStyle(fontFamily: 'monospace')),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2：常见陷阱
// -----------------------------------------------------------------------------

class _PitfallsTab extends StatelessWidget {
  const _PitfallsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _PitfallCard(
          title: '陷阱 1: build 中使用 ref.read',
          wrong: 'Widget build(ctx, ref) {\n'
              '  final count = ref.read(counterProvider);\n'
              '  // UI 不会自动更新！\n'
              '}',
          correct: 'Widget build(ctx, ref) {\n'
              '  final count = ref.watch(counterProvider);\n'
              '  // 值变化时自动重建 ✅\n'
              '}',
        ),
        _PitfallCard(
          title: '陷阱 2: 回调中使用 ref.watch',
          wrong: 'onPressed: () {\n'
              '  ref.watch(counterProvider); // 多余的监听！\n'
              '}',
          correct: 'onPressed: () {\n'
              '  ref.read(counterProvider.notifier).state++;\n'
              '}',
        ),
        _PitfallCard(
          title: '陷阱 3: 直接修改状态',
          wrong: '// Notifier 内\n'
              'state.add(newItem); // 引用没变，不通知！',
          correct: '// Notifier 内\n'
              'state = [...state, newItem]; // 新引用，触发通知',
        ),
        _PitfallCard(
          title: '陷阱 4: Notifier 方法中用 ref.watch',
          wrong: 'void doSomething() {\n'
              '  final x = ref.watch(other); // 错误！\n'
              '}',
          correct: 'void doSomething() {\n'
              '  final x = ref.read(other); // 方法中用 read\n'
              '}\n'
              '// ref.watch 只在 build() 中使用',
        ),
        _PitfallCard(
          title: '陷阱 5: 忘记 ProviderScope',
          wrong: 'void main() {\n'
              '  runApp(MyApp()); // 运行时崩溃\n'
              '}',
          correct: 'void main() {\n'
              '  runApp(ProviderScope(child: MyApp()));\n'
              '}',
        ),
        _PitfallCard(
          title: '陷阱 6: Provider 做太多事',
          wrong: 'class AppNotifier extends Notifier<AppState> {\n'
              '  void login() { ... }\n'
              '  void addTodo() { ... }\n'
              '  void changeTheme() { ... }\n'
              '}',
          correct: 'class AuthNotifier extends Notifier<AuthState> { ... }\n'
              'class TodoNotifier extends Notifier<TodoState> { ... }\n'
              'class ThemeNotifier extends Notifier<ThemeMode> { ... }',
        ),
      ],
    );
  }
}

class _PitfallCard extends StatelessWidget {
  final String title;
  final String wrong;
  final String correct;

  const _PitfallCard({
    required this.title,
    required this.wrong,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('❌ 错误\n$wrong',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('✅ 正确\n$correct',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 3：架构分层
// -----------------------------------------------------------------------------

class _ArchitectureTab extends StatelessWidget {
  const _ArchitectureTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('推荐架构分层', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _layerCard('🖥️ UI 层', 'ConsumerWidget / ConsumerStatefulWidget',
              'ref.watch 显示状态，ref.read 触发操作', Colors.blue),
          const _ArrowDown(),
          _layerCard('🧠 ViewModel 层', 'Notifier / AsyncNotifier',
              '封装业务逻辑，管理状态', Colors.purple),
          const _ArrowDown(),
          _layerCard('📦 Repository 层', 'Provider<XxxRepository>',
              '数据访问抽象，便于测试 override', Colors.orange),
          const _ArrowDown(),
          _layerCard('💾 DataSource 层', 'API Client / 本地存储',
              '具体数据实现', Colors.grey),
          const SizedBox(height: 24),
          Text('文件组织（Feature-First）',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'lib/\n'
              '├── features/\n'
              '│   ├── auth/\n'
              '│   │   ├── data/         # Repository + API\n'
              '│   │   ├── domain/       # Model\n'
              '│   │   └── presentation/ # Notifier + Page\n'
              '│   └── todo/\n'
              '│       ├── data/\n'
              '│       ├── domain/\n'
              '│       └── presentation/\n'
              '├── shared/               # 公共 Provider/Widget\n'
              '└── main.dart',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerCard(
      String title, String subtitle, String desc, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(title.substring(0, 2)),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(desc, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ArrowDown extends StatelessWidget {
  const _ArrowDown();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Icon(Icons.arrow_downward, color: Colors.grey),
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. 性能：select 精确监听、Consumer 局部重建
// 2. 陷阱：build 用 watch、回调用 read、不要直接修改状态
// 3. 架构：UI → ViewModel(Notifier) → Repository → DataSource
// 4. 组织：单一职责、Feature-First 文件结构
// 5. 命名：xxxProvider、XxxNotifier、描述性名称
// =============================================================================
