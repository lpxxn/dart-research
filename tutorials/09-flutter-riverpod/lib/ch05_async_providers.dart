import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第五章：异步 Provider
// 演示：FutureProvider、StreamProvider、AsyncNotifier、AsyncValue
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class User {
  final String id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});
}

// -----------------------------------------------------------------------------
// 2. FutureProvider — 一次性异步数据
// -----------------------------------------------------------------------------

/// 模拟获取应用配置（一次性）
final appConfigProvider = FutureProvider<Map<String, String>>((ref) async {
  await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟
  return {
    'appName': 'Riverpod 教程',
    'version': '2.5.0',
    'apiUrl': 'https://api.example.com',
  };
});

// -----------------------------------------------------------------------------
// 3. StreamProvider — 实时数据流
// -----------------------------------------------------------------------------

/// 实时时钟：每秒更新一次
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// 模拟实时消息流
final messageStreamProvider = StreamProvider<List<String>>((ref) {
  final controller = StreamController<List<String>>();
  final messages = <String>[];

  // 每 3 秒收到一条新消息
  int count = 0;
  final timer = Timer.periodic(const Duration(seconds: 3), (_) {
    count++;
    messages.add('消息 #$count - ${DateTime.now().second}s');
    controller.add(List.from(messages));
  });

  // 初始发送空列表
  controller.add([]);

  // 当 Provider 被销毁时清理
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// -----------------------------------------------------------------------------
// 4. AsyncNotifier — 可变异步状态
// -----------------------------------------------------------------------------

class UserListNotifier extends AsyncNotifier<List<User>> {
  int _nextId = 1;

  @override
  Future<List<User>> build() async {
    // 初始加载：模拟 API 请求
    return await _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    await Future.delayed(const Duration(seconds: 1));
    _nextId = 4;
    return const [
      User(id: '1', name: 'Alice', email: 'alice@example.com'),
      User(id: '2', name: 'Bob', email: 'bob@example.com'),
      User(id: '3', name: 'Charlie', email: 'charlie@example.com'),
    ];
  }

  /// 添加用户
  Future<void> addUser(String name) async {
    // 使用 AsyncValue.guard 自动处理 try/catch
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟 API
      final newUser = User(
        id: '${_nextId++}',
        name: name,
        email: '${name.toLowerCase()}@example.com',
      );
      return [...(state.value ?? []), newUser];
    });
  }

  /// 删除用户
  Future<void> removeUser(String userId) async {
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      return (state.value ?? []).where((u) => u.id != userId).toList();
    });
  }

  /// 刷新数据
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUsers);
  }

  /// 模拟请求失败
  Future<void> simulateError() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      throw Exception('模拟的网络错误：连接超时');
    });
  }
}

final userListProvider =
    AsyncNotifierProvider<UserListNotifier, List<User>>(UserListNotifier.new);

// -----------------------------------------------------------------------------
// 5. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch05App()));
}

class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch05 - 异步 Provider',
      theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true),
      home: const AsyncDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 6. 主页面：Tab 展示三种异步 Provider
// -----------------------------------------------------------------------------

class AsyncDemoPage extends StatelessWidget {
  const AsyncDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第五章：异步 Provider'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.download), text: 'FutureProvider'),
              Tab(icon: Icon(Icons.stream), text: 'StreamProvider'),
              Tab(icon: Icon(Icons.people), text: 'AsyncNotifier'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FutureProviderTab(),
            _StreamProviderTab(),
            _AsyncNotifierTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1：FutureProvider 演示
// -----------------------------------------------------------------------------

class _FutureProviderTab extends ConsumerWidget {
  const _FutureProviderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FutureProvider 一次性异步数据',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('模拟获取应用配置（1秒延迟）：'),
          const SizedBox(height: 16),

          // ✅ AsyncValue.when 处理三种状态
          configAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text('$error'),
              ),
            ),
            data: (config) => Card(
              child: Column(
                children: config.entries
                    .map((e) => ListTile(
                          leading: const Icon(Icons.settings),
                          title: Text(e.key),
                          trailing: Text(e.value),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // 重新加载按钮
          FilledButton.icon(
            onPressed: () {
              // ✅ ref.invalidate 重新触发 FutureProvider
              ref.invalidate(appConfigProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2：StreamProvider 演示
// -----------------------------------------------------------------------------

class _StreamProviderTab extends ConsumerWidget {
  const _StreamProviderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockAsync = ref.watch(clockProvider);
    final messagesAsync = ref.watch(messageStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 实时时钟
          Text('StreamProvider 实时数据流',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time, size: 32),
              title: const Text('实时时钟（每秒更新）'),
              subtitle: clockAsync.when(
                loading: () => const Text('加载中...'),
                error: (e, s) => Text('错误：$e'),
                data: (time) => Text(
                  '${time.hour.toString().padLeft(2, '0')}'
                  ':${time.minute.toString().padLeft(2, '0')}'
                  ':${time.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 24, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 实时消息流
          const Text('模拟实时消息（每 3 秒一条）：'),
          const SizedBox(height: 8),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('错误：$e'),
              data: (messages) => messages.isEmpty
                  ? const Center(child: Text('等待消息...'))
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(messages[index]),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 3：AsyncNotifier 演示
// -----------------------------------------------------------------------------

class _AsyncNotifierTab extends ConsumerStatefulWidget {
  const _AsyncNotifierTab();

  @override
  ConsumerState<_AsyncNotifierTab> createState() => _AsyncNotifierTabState();
}

class _AsyncNotifierTabState extends ConsumerState<_AsyncNotifierTab> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AsyncNotifier 可变异步状态',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // 添加用户输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: '输入用户名',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    ref.read(userListProvider.notifier).addUser(_nameController.text);
                    _nameController.clear();
                  }
                },
                child: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 操作按钮
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => ref.read(userListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(userListProvider.notifier).simulateError(),
                icon: const Icon(Icons.error_outline),
                label: const Text('模拟错误'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 用户列表
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 8),
                    Text('$error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(userListProvider.notifier).refresh(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (users) => ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(user.name[0])),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => ref
                            .read(userListProvider.notifier)
                            .removeUser(user.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. FutureProvider：一次性异步数据，返回 AsyncValue<T>
// 2. StreamProvider：实时数据流，返回 AsyncValue<T>
// 3. AsyncValue.when：处理 loading / error / data 三种状态
// 4. AsyncNotifier：可变异步状态，build() 返回 Future<T>
// 5. AsyncValue.guard：自动处理 try/catch 的便捷方法
// 6. ref.invalidate：重新触发 Provider 的 build()
// 7. ref.onDispose：Provider 销毁时执行清理逻辑
// =============================================================================
