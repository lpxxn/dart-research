import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第六章：修饰符 — autoDispose 与 family
// 演示：autoDispose 自动销毁、keepAlive 缓存、family 参数化
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class UserDetail {
  final String id;
  final String name;
  final String bio;
  final int followers;

  const UserDetail({
    required this.id,
    required this.name,
    required this.bio,
    required this.followers,
  });
}

// 模拟用户数据库
final _mockUsers = {
  'u1': const UserDetail(id: 'u1', name: 'Alice', bio: 'Flutter 开发者', followers: 1200),
  'u2': const UserDetail(id: 'u2', name: 'Bob', bio: 'Dart 爱好者', followers: 860),
  'u3': const UserDetail(id: 'u3', name: 'Charlie', bio: '全栈工程师', followers: 3400),
  'u4': const UserDetail(id: 'u4', name: 'Diana', bio: 'UI 设计师', followers: 5600),
};

// -----------------------------------------------------------------------------
// 2. autoDispose 示例：页面计数器
// -----------------------------------------------------------------------------

/// ✅ autoDispose：离开页面后，状态自动清零（下次进入重新初始化）
final pageCounterProvider = StateProvider.autoDispose<int>((ref) {
  debugPrint('📦 pageCounterProvider 创建');
  ref.onDispose(() => debugPrint('🗑️ pageCounterProvider 销毁'));
  return 0;
});

/// 普通版（对比）：离开页面后，状态仍然保留
final persistentCounterProvider = StateProvider<int>((ref) {
  debugPrint('📦 persistentCounterProvider 创建');
  return 0;
});

// -----------------------------------------------------------------------------
// 3. family 示例：根据 userId 获取用户详情
// -----------------------------------------------------------------------------

/// ✅ family：根据不同的 userId 创建不同的 Provider 实例
final userDetailProvider =
    FutureProvider.family<UserDetail, String>((ref, userId) async {
  debugPrint('🌐 获取用户 $userId 的详情...');
  await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求

  final user = _mockUsers[userId];
  if (user == null) throw Exception('用户 $userId 不存在');
  return user;
});

// -----------------------------------------------------------------------------
// 4. autoDispose + family 组合 + keepAlive 缓存
// -----------------------------------------------------------------------------

/// ✅ autoDispose + family：离开页面自动销毁 + 参数化
/// 加上 keepAlive，离开页面后缓存 5 秒
final cachedUserDetailProvider =
    FutureProvider.autoDispose.family<UserDetail, String>((ref, userId) async {
  // keepAlive 链接：控制缓存
  final link = ref.keepAlive();

  // 5 秒后允许销毁
  final timer = Timer(const Duration(seconds: 5), () {
    debugPrint('⏰ 用户 $userId 缓存过期，允许销毁');
    link.close();
  });

  ref.onDispose(() {
    timer.cancel();
    debugPrint('🗑️ cachedUserDetailProvider($userId) 销毁');
  });

  debugPrint('🌐 加载用户 $userId（带缓存）...');
  await Future.delayed(const Duration(seconds: 1));

  final user = _mockUsers[userId];
  if (user == null) throw Exception('用户 $userId 不存在');
  return user;
});

// -----------------------------------------------------------------------------
// 5. family + Record 多参数
// -----------------------------------------------------------------------------

/// 使用 Dart 3 Record 作为 family 的多参数
typedef SearchParams = ({String query, int page});

final searchProvider =
    FutureProvider.autoDispose.family<List<String>, SearchParams>(
  (ref, params) async {
    debugPrint('🔍 搜索: query="${params.query}", page=${params.page}');
    await Future.delayed(const Duration(milliseconds: 500));

    // 模拟搜索结果
    return List.generate(
      5,
      (i) => '${params.query} 结果 #${params.page * 5 + i + 1}',
    );
  },
);

// -----------------------------------------------------------------------------
// 6. 销毁日志 Provider（用于演示 onDispose）
// -----------------------------------------------------------------------------

class DisposeLogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addLog(String message) {
    state = [...state, '${DateTime.now().second}s - $message'];
  }
}

final disposeLogProvider =
    NotifierProvider<DisposeLogNotifier, List<String>>(DisposeLogNotifier.new);

// -----------------------------------------------------------------------------
// 7. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch06App()));
}

class Ch06App extends StatelessWidget {
  const Ch06App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch06 - 修饰符',
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const ModifierDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 8. 主页面
// -----------------------------------------------------------------------------

class ModifierDemoPage extends ConsumerWidget {
  const ModifierDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('第六章：修饰符')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // autoDispose 对比
          _buildSection(context, 'autoDispose 对比', Icons.delete_sweep),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('autoDispose 计数器'),
                  subtitle: const Text('离开页面后状态重置'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _AutoDisposeCounterPage()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('普通计数器（对比）'),
                  subtitle: const Text('离开页面后状态保留'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _PersistentCounterPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // family 示例
          _buildSection(context, 'family 参数化', Icons.people),
          Card(
            child: Column(
              children: _mockUsers.keys.map((userId) {
                return ListTile(
                  title: Text('查看用户 $userId'),
                  subtitle: Text(_mockUsers[userId]!.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _UserDetailPage(userId: userId),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // 多参数搜索
          _buildSection(context, 'family + Record 多参数', Icons.search),
          Card(
            child: ListTile(
              title: const Text('搜索示例'),
              subtitle: const Text('使用 Dart 3 Record 传递多参数'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _SearchDemoPage()),
              ),
            ),
          ),
        ],
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
// autoDispose 计数器页面
// -----------------------------------------------------------------------------

class _AutoDisposeCounterPage extends ConsumerWidget {
  const _AutoDisposeCounterPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pageCounterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('autoDispose 计数器')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('离开此页面后状态会自动重置：',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('$count', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(pageCounterProvider.notifier).state++,
              child: const Text('+ 1'),
            ),
            const SizedBox(height: 8),
            const Text('（返回后再进来，会发现计数器回到 0）',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// 普通计数器页面（对比）
class _PersistentCounterPage extends ConsumerWidget {
  const _PersistentCounterPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(persistentCounterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('普通计数器')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('离开此页面后状态仍然保留：',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('$count', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(persistentCounterProvider.notifier).state++,
              child: const Text('+ 1'),
            ),
            const SizedBox(height: 8),
            const Text('（返回后再进来，计数器值不变）',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// family 用户详情页面
// -----------------------------------------------------------------------------

class _UserDetailPage extends ConsumerWidget {
  final String userId;
  const _UserDetailPage({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ family：传入不同的 userId 获取不同的用户数据
    final userAsync = ref.watch(cachedUserDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text('用户详情 ($userId)')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('错误：$e')),
        data: (user) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(user.name[0], style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(user.bio, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: Text('${user.followers} 关注者'),
                ),
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '💡 此页面使用 autoDispose + family + keepAlive(5秒)\n\n'
                    '• 离开页面后，5 秒内返回不会重新加载\n'
                    '• 5 秒后缓存过期，再次进入会重新加载\n'
                    '• 查看控制台输出了解生命周期',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 搜索示例页面（family + Record 多参数）
// -----------------------------------------------------------------------------

class _SearchDemoPage extends ConsumerStatefulWidget {
  const _SearchDemoPage();

  @override
  ConsumerState<_SearchDemoPage> createState() => _SearchDemoPageState();
}

class _SearchDemoPageState extends ConsumerState<_SearchDemoPage> {
  String _query = 'Flutter';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ Record 作为 family 参数
    final resultsAsync = ref.watch(searchProvider((query: _query, page: _page)));

    return Scaffold(
      appBar: AppBar(title: const Text('搜索（多参数 family）')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _page = 0;
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  child: const Text('上一页'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('第 ${_page + 1} 页'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _page++),
                  child: const Text('下一页'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: resultsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('错误：$e'),
                data: (results) => ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(results[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. autoDispose：无监听者时自动销毁 Provider
// 2. ref.keepAlive()：延迟销毁，实现定时缓存
// 3. family：参数化 Provider，不同参数创建不同实例
// 4. autoDispose + family：最常见的组合
// 5. ref.onDispose：清理资源（Timer、Controller 等）
// 6. Record 多参数：Dart 3 的 ({String query, int page}) 作为参数
// =============================================================================
