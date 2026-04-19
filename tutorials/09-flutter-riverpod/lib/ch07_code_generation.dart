import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第七章：Riverpod Generator（代码生成）
// 本章用手写方式展示生成后的等价代码，帮助理解 @riverpod 注解的作用
// 注意：实际项目中使用 @riverpod 注解 + build_runner 生成
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 函数式 Provider（等价 @riverpod 函数）
// -----------------------------------------------------------------------------

// @riverpod
// String appTitle(AppTitleRef ref) => 'Riverpod Generator 教程';
// ↓ 生成等价代码 ↓
final appTitleProvider = Provider.autoDispose<String>((ref) {
  return 'Riverpod Generator 教程';
});

// @riverpod
// String greeting(GreetingRef ref) {
//   final title = ref.watch(appTitleProvider);
//   return '欢迎来到 $title';
// }
// ↓ 生成等价代码 ↓
final greetingProvider = Provider.autoDispose<String>((ref) {
  final title = ref.watch(appTitleProvider);
  return '欢迎来到 $title';
});

// @Riverpod(keepAlive: true)
// String permanentValue(PermanentValueRef ref) => '我不会被自动销毁';
// ↓ 生成等价代码（不带 autoDispose） ↓
final permanentValueProvider = Provider<String>((ref) {
  return '我不会被自动销毁';
});

// -----------------------------------------------------------------------------
// 2. 类式 Notifier（等价 @riverpod 类）
// -----------------------------------------------------------------------------

// @riverpod
// class Counter extends _$Counter {
//   @override
//   int build() => 0;
//   void increment() => state++;
//   void decrement() => state--;
// }
// ↓ 生成等价代码 ↓

class CounterNotifier extends AutoDisposeNotifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final counterProvider =
    NotifierProvider.autoDispose<CounterNotifier, int>(CounterNotifier.new);

// -----------------------------------------------------------------------------
// 3. 异步 Notifier（等价 @riverpod 异步类）
// -----------------------------------------------------------------------------

// @riverpod
// class TodoList extends _$TodoList {
//   @override
//   Future<List<String>> build() async { ... }
//   Future<void> addTodo(String title) async { ... }
// }
// ↓ 生成等价代码 ↓

class TodoListNotifier extends AutoDisposeAsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['学习 @riverpod 注解', '理解代码生成', '对比手写与生成'];
  }

  Future<void> addTodo(String title) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      return [...(state.value ?? []), title];
    });
  }

  Future<void> removeTodo(int index) async {
    state = await AsyncValue.guard(() async {
      final list = List<String>.from(state.value ?? []);
      list.removeAt(index);
      return list;
    });
  }
}

final todoListProvider =
    AsyncNotifierProvider.autoDispose<TodoListNotifier, List<String>>(
        TodoListNotifier.new);

// -----------------------------------------------------------------------------
// 4. family（等价 @riverpod 带参数的函数/类）
// -----------------------------------------------------------------------------

// @riverpod
// Future<String> userGreeting(UserGreetingRef ref, String name) async { ... }
// ↓ 生成等价代码 ↓
final userGreetingProvider =
    FutureProvider.autoDispose.family<String, String>((ref, name) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return '你好，$name！欢迎使用 Riverpod。';
});

// @riverpod
// Future<Map<String, dynamic>> userProfile(UserProfileRef ref, String userId, {int? cacheDuration}) async { ... }
// 多参数用 Record
typedef UserProfileParams = ({String userId, int cacheDuration});

final userProfileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, UserProfileParams>((ref, params) async {
  await Future.delayed(Duration(seconds: params.cacheDuration));
  return {
    'id': params.userId,
    'name': 'User ${params.userId}',
    'cacheDuration': '${params.cacheDuration}s',
  };
});

// -----------------------------------------------------------------------------
// 5. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch07App()));
}

class Ch07App extends StatelessWidget {
  const Ch07App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch07 - 代码生成',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const CodeGenDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. 主页面
// -----------------------------------------------------------------------------

class CodeGenDemoPage extends StatelessWidget {
  const CodeGenDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第七章：代码生成'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '函数式'),
              Tab(text: '类式 Notifier'),
              Tab(text: '异步 Notifier'),
              Tab(text: 'family'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FunctionProviderTab(),
            _ClassNotifierTab(),
            _AsyncNotifierTab(),
            _FamilyTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1：函数式 Provider
// -----------------------------------------------------------------------------

class _FunctionProviderTab extends ConsumerWidget {
  const _FunctionProviderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);
    final greeting = ref.watch(greetingProvider);
    final permanent = ref.watch(permanentValueProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeBlock(
            context,
            '// @riverpod 函数式 → 自动生成 Provider\n'
            '@riverpod\n'
            'String appTitle(AppTitleRef ref) => "...";\n'
            '// 等价于：Provider.autoDispose<String>(...)',
          ),
          const SizedBox(height: 16),
          _resultCard('appTitleProvider', title),
          _resultCard('greetingProvider', greeting),
          _resultCard('permanentValueProvider (keepAlive)', permanent),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2：类式 Notifier
// -----------------------------------------------------------------------------

class _ClassNotifierTab extends ConsumerWidget {
  const _ClassNotifierTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeBlock(
            context,
            '// @riverpod 类式 → 自动生成 NotifierProvider\n'
            '@riverpod\n'
            'class Counter extends _\$Counter {\n'
            '  @override\n'
            '  int build() => 0;\n'
            '  void increment() => state++;\n'
            '}',
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('计数器：$count',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          ref.read(counterProvider.notifier).decrement(),
                      child: const Text('- 1'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(counterProvider.notifier).reset(),
                      child: const Text('重置'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(counterProvider.notifier).increment(),
                      child: const Text('+ 1'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 3：异步 Notifier
// -----------------------------------------------------------------------------

class _AsyncNotifierTab extends ConsumerStatefulWidget {
  const _AsyncNotifierTab();

  @override
  ConsumerState<_AsyncNotifierTab> createState() => _AsyncNotifierTabState();
}

class _AsyncNotifierTabState extends ConsumerState<_AsyncNotifierTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeBlock(
            context,
            '// @riverpod 异步类式\n'
            '@riverpod\n'
            'class TodoList extends _\$TodoList {\n'
            '  @override\n'
            '  Future<List<String>> build() async { ... }\n'
            '  Future<void> addTodo(String t) async { ... }\n'
            '}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '新 Todo...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    ref.read(todoListProvider.notifier).addTodo(_controller.text);
                    _controller.clear();
                  }
                },
                child: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: todosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误：$e')),
              data: (todos) => ListView.builder(
                itemCount: todos.length,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(todos[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(todoListProvider.notifier).removeTodo(i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 4：family
// -----------------------------------------------------------------------------

class _FamilyTab extends ConsumerWidget {
  const _FamilyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ['Alice', 'Bob', 'Charlie'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeBlock(
            context,
            '// @riverpod 带参数 → 自动生成 family\n'
            '@riverpod\n'
            'Future<String> userGreeting(\n'
            '  UserGreetingRef ref, String name\n'
            ') async => "你好，\$name！";\n'
            '// build 参数 = family 参数',
          ),
          const SizedBox(height: 16),
          ...names.map((name) {
            // ✅ family：每个不同的 name 是不同的 Provider 实例
            final greetingAsync = ref.watch(userGreetingProvider(name));
            return Card(
              child: ListTile(
                title: Text('userGreetingProvider("$name")'),
                subtitle: greetingAsync.when(
                  loading: () => const Text('加载中...'),
                  error: (e, s) => Text('错误：$e'),
                  data: (greeting) => Text(greeting,
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 辅助组件
// -----------------------------------------------------------------------------

Widget _codeBlock(BuildContext context, String code) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Text(
      code,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: Colors.grey.shade800,
      ),
    ),
  );
}

Widget _resultCard(String label, String value) {
  return Card(
    child: ListTile(
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    ),
  );
}

// =============================================================================
// 知识点总结：
//
// 1. @riverpod 函数 → 自动生成 Provider.autoDispose
// 2. @riverpod 类 → 自动生成 NotifierProvider.autoDispose
// 3. @riverpod 异步函数/类 → 自动生成 FutureProvider / AsyncNotifierProvider
// 4. build() 的参数 → 自动生成 family
// 5. @Riverpod(keepAlive: true) → 关闭 autoDispose
// 6. 类名 Counter → counterProvider（首字母小写 + Provider）
// 7. 需要 part 'xxx.g.dart' + build_runner 生成
// =============================================================================
