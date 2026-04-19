import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第四章：ref 详解
// 演示：ref.watch / ref.read / ref.listen / select / Consumer 组件对比
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class UserProfile {
  final String name;
  final int age;
  final String email;

  const UserProfile({
    required this.name,
    required this.age,
    required this.email,
  });

  UserProfile copyWith({String? name, int? age, String? email}) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }

  @override
  String toString() => 'UserProfile(name: $name, age: $age, email: $email)';
}

// -----------------------------------------------------------------------------
// 2. Providers
// -----------------------------------------------------------------------------

/// 用户资料 Notifier
class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return const UserProfile(name: 'Alice', age: 25, email: 'alice@example.com');
  }

  void updateName(String name) => state = state.copyWith(name: name);
  void incrementAge() => state = state.copyWith(age: state.age + 1);
  void updateEmail(String email) => state = state.copyWith(email: email);
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

/// 计数器
final counterProvider = StateProvider<int>((ref) => 0);

/// 操作日志 Notifier
class LogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addLog(String message) {
    final time = TimeOfDay.now().format(navigatorKey.currentContext!);
    state = [...state, '[$time] $message'];
  }
}

final logProvider = NotifierProvider<LogNotifier, List<String>>(LogNotifier.new);

/// 用于获取 context 的 GlobalKey
final navigatorKey = GlobalKey<NavigatorState>();

// -----------------------------------------------------------------------------
// 3. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch04App()));
}

class Ch04App extends StatelessWidget {
  const Ch04App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ch04 - ref 详解',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const RefDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. 主页面：演示 ref.watch / ref.read / ref.listen
// -----------------------------------------------------------------------------

class RefDemoPage extends ConsumerWidget {
  const RefDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.watch：响应式监听，值变化时重建
    final user = ref.watch(userProfileProvider);
    final count = ref.watch(counterProvider);

    // ✅ ref.listen：副作用监听，不会触发重建
    ref.listen(counterProvider, (previous, next) {
      if (next % 5 == 0 && next > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 计数器达到 $next！（每 5 次提醒）'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('第四章：ref 详解'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'select 示例',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SelectDemoPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.widgets),
            tooltip: 'Consumer 对比',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ConsumerDemoPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ref.watch 展示 ---
            _buildSection(context, 'ref.watch — 响应式监听', Icons.visibility),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('用户：${user.name}', style: const TextStyle(fontSize: 18)),
                    Text('年龄：${user.age}'),
                    Text('邮箱：${user.email}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => ref
                              .read(userProfileProvider.notifier)
                              .updateName('Bob'),
                          child: const Text('改名 Bob'),
                        ),
                        FilledButton(
                          onPressed: () => ref
                              .read(userProfileProvider.notifier)
                              .updateName('Alice'),
                          child: const Text('改名 Alice'),
                        ),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(userProfileProvider.notifier)
                              .incrementAge(),
                          child: const Text('年龄 +1'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ref.read 展示 ---
            _buildSection(context, 'ref.read — 一次性读取（回调中使用）', Icons.touch_app),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('计数器：$count',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          // ✅ 在回调中使用 ref.read
                          onPressed: () =>
                              ref.read(counterProvider.notifier).state--,
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () =>
                              ref.read(counterProvider.notifier).state++,
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () =>
                              ref.read(counterProvider.notifier).state = 0,
                          child: const Text('重置'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ref.listen 说明 ---
            _buildSection(context, 'ref.listen — 副作用监听', Icons.notifications_active),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '上方计数器每到 5 的倍数时，会弹出 SnackBar 提醒。\n'
                  '这就是 ref.listen 的典型用法：不重建 Widget，只执行副作用。',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. select 示例页面
// -----------------------------------------------------------------------------

class SelectDemoPage extends ConsumerWidget {
  const SelectDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('select 精确监听')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '下面三个组件各自只监听 UserProfile 的一个字段：\n'
              '修改名字只重建"名字"组件，修改年龄只重建"年龄"组件。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // 只监听 name
            _SelectNameWidget(),
            const SizedBox(height: 8),

            // 只监听 age
            _SelectAgeWidget(),
            const SizedBox(height: 8),

            // 只监听 email
            _SelectEmailWidget(),

            const SizedBox(height: 24),
            const Text('操作：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      ref.read(userProfileProvider.notifier).updateName('Charlie'),
                  child: const Text('改名 Charlie'),
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(userProfileProvider.notifier).incrementAge(),
                  child: const Text('年龄 +1'),
                ),
                FilledButton(
                  onPressed: () => ref
                      .read(userProfileProvider.notifier)
                      .updateEmail('new@example.com'),
                  child: const Text('改邮箱'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 只监听 name 字段
class _SelectNameWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ select：只有 name 变化时才重建此 Widget
    final name = ref.watch(userProfileProvider.select((u) => u.name));
    debugPrint('🔄 _SelectNameWidget 重建');
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: const Icon(Icons.person),
        title: const Text('名字（select name）'),
        subtitle: Text(name, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

/// 只监听 age 字段
class _SelectAgeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = ref.watch(userProfileProvider.select((u) => u.age));
    debugPrint('🔄 _SelectAgeWidget 重建');
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.cake),
        title: const Text('年龄（select age）'),
        subtitle: Text('$age 岁', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

/// 只监听 email 字段
class _SelectEmailWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(userProfileProvider.select((u) => u.email));
    debugPrint('🔄 _SelectEmailWidget 重建');
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.email),
        title: const Text('邮箱（select email）'),
        subtitle: Text(email, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. Consumer 组件对比页面
// -----------------------------------------------------------------------------

class ConsumerDemoPage extends StatelessWidget {
  const ConsumerDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumer 组件对比')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 方式一：使用 Consumer 包裹局部
            Text('方式一：Consumer（局部包裹）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('只有 Consumer 内部会因状态变化而重建：'),
                    const SizedBox(height: 8),
                    // ✅ Consumer：只包裹需要 ref 的部分
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(counterProvider);
                        debugPrint('🔄 Consumer builder 重建');
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('计数器：$count',
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            IconButton.filled(
                              onPressed: () =>
                                  ref.read(counterProvider.notifier).state++,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('↑ 只有上面这行会重建，本 Card 其余部分不会'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 方式二：ConsumerStatefulWidget 示例
            Text('方式二：ConsumerStatefulWidget',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _StatefulConsumerExample(),
          ],
        ),
      ),
    );
  }
}

/// ConsumerStatefulWidget 示例：需要 initState / dispose 等生命周期
class _StatefulConsumerExample extends ConsumerStatefulWidget {
  const _StatefulConsumerExample();

  @override
  ConsumerState<_StatefulConsumerExample> createState() =>
      _StatefulConsumerExampleState();
}

class _StatefulConsumerExampleState
    extends ConsumerState<_StatefulConsumerExample> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // ✅ initState 中使用 ref.read
    final user = ref.read(userProfileProvider);
    _controller = TextEditingController(text: user.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ build 中使用 ref.watch
    final user = ref.watch(userProfileProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ConsumerStatefulWidget 可使用 initState/dispose：'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '修改用户名',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                ref.read(userProfileProvider.notifier).updateName(value);
              },
            ),
            const SizedBox(height: 8),
            Text('当前用户：${user.name}（按 Enter 提交修改）'),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. ref.watch：build 中使用，值变化时重建 Widget
// 2. ref.read：回调中使用，一次性读取/调用方法
// 3. ref.listen：副作用监听（SnackBar、导航、日志）
// 4. .select((state) => field)：精确监听某个字段，减少不必要的重建
// 5. ConsumerWidget：替代 StatelessWidget，最常用
// 6. ConsumerStatefulWidget：替代 StatefulWidget，需要生命周期
// 7. Consumer：局部包裹，限制重建范围
// =============================================================================
