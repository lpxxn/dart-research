import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第九章：高级模式
// 演示：ProviderObserver、ProviderScope override、ref.invalidate/refresh
// =============================================================================

// -----------------------------------------------------------------------------
// 1. ProviderObserver — 全局日志
// -----------------------------------------------------------------------------

/// 日志存储
class LogStore {
  static final List<String> logs = [];
  static void add(String message) {
    final time = DateTime.now();
    final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    logs.insert(0, '[$timeStr] $message');
    if (logs.length > 50) logs.removeLast();
  }
}

/// ✅ ProviderObserver：监听所有 Provider 的生命周期
class AppObserver extends ProviderObserver {
  @override
  void didAddProvider(
      ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    final msg = '✅ 创建: ${provider.name ?? provider.runtimeType}';
    LogStore.add(msg);
    debugPrint(msg);
  }

  @override
  void didUpdateProvider(
      ProviderBase<Object?> provider, Object? previousValue, Object? newValue,
      ProviderContainer container) {
    final msg = '🔄 更新: ${provider.name ?? provider.runtimeType}: $previousValue → $newValue';
    LogStore.add(msg);
    debugPrint(msg);
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    final msg = '🗑️ 销毁: ${provider.name ?? provider.runtimeType}';
    LogStore.add(msg);
    debugPrint(msg);
  }
}

// -----------------------------------------------------------------------------
// 2. Provider 定义
// -----------------------------------------------------------------------------

/// 计数器 Provider
final counterProvider = StateProvider<int>((ref) => 0);

/// 配置 Provider（可被 override）
final themeColorProvider = Provider<Color>((ref) => Colors.blue);

/// 数据 Provider（演示 invalidate/refresh）
final timestampProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
});

/// 列表项 Provider（用于 ProviderScope override）
final currentIndexProvider = Provider<int>((ref) => throw UnimplementedError());
final currentItemProvider = Provider<String>((ref) => throw UnimplementedError());

/// 日志刷新触发器
final logRefreshProvider = StateProvider<int>((ref) => 0);

// 模拟数据列表
final itemListProvider = Provider<List<String>>((ref) {
  return List.generate(10, (i) => '项目 ${i + 1}: ${_descriptions[i % _descriptions.length]}');
});

const _descriptions = ['学习 Riverpod', '写代码', '读文档', '跑测试', '提交 PR'];

// -----------------------------------------------------------------------------
// 3. 入口（注册 Observer）
// -----------------------------------------------------------------------------

void main() {
  runApp(
    ProviderScope(
      // ✅ 注册 ProviderObserver
      observers: [AppObserver()],
      child: const Ch09App(),
    ),
  );
}

class Ch09App extends StatelessWidget {
  const Ch09App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch09 - 高级模式',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const AdvancedDemoPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. 主页面
// -----------------------------------------------------------------------------

class AdvancedDemoPage extends StatelessWidget {
  const AdvancedDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('第九章：高级模式'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bug_report), text: 'Observer'),
              Tab(icon: Icon(Icons.layers), text: 'Scope Override'),
              Tab(icon: Icon(Icons.refresh), text: 'Invalidate'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ObserverTab(),
            _ScopeOverrideTab(),
            _InvalidateTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1：ProviderObserver 日志
// -----------------------------------------------------------------------------

class _ObserverTab extends ConsumerWidget {
  const _ObserverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    // 触发日志列表刷新
    ref.watch(logRefreshProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('修改状态会被 ProviderObserver 记录：'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      ref.read(counterProvider.notifier).state++;
                      // 刷新日志显示
                      ref.read(logRefreshProvider.notifier).state++;
                    },
                    child: Text('计数器 +1 (当前: $count)'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(counterProvider.notifier).state = 0;
                      ref.read(logRefreshProvider.notifier).state++;
                    },
                    child: const Text('重置'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('📋 Observer 日志：',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  LogStore.logs.clear();
                  ref.read(logRefreshProvider.notifier).state++;
                },
                child: const Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: LogStore.logs.isEmpty
              ? const Center(child: Text('暂无日志'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: LogStore.logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      LogStore.logs[i],
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2：ProviderScope Override
// -----------------------------------------------------------------------------

class _ScopeOverrideTab extends ConsumerWidget {
  const _ScopeOverrideTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '每个列表项通过 ProviderScope override 注入当前项数据：',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          // 颜色 override 演示
          Row(
            children: [
              const Text('全局主题色：'),
              const SizedBox(width: 8),
              _ColoredBox(label: '默认蓝色'),
              const SizedBox(width: 8),
              // ✅ ProviderScope override：子树中替换颜色
              ProviderScope(
                overrides: [themeColorProvider.overrideWithValue(Colors.red)],
                child: _ColoredBox(label: 'Override 红色'),
              ),
              const SizedBox(width: 8),
              ProviderScope(
                overrides: [themeColorProvider.overrideWithValue(Colors.green)],
                child: _ColoredBox(label: 'Override 绿色'),
              ),
            ],
          ),
          const Divider(),
          // 列表项 override
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                // ✅ 每个列表项 override 当前索引和内容
                return ProviderScope(
                  overrides: [
                    currentIndexProvider.overrideWithValue(index),
                    currentItemProvider.overrideWithValue(items[index]),
                  ],
                  child: const _OverriddenListTile(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ColoredBox extends ConsumerWidget {
  final String label;
  const _ColoredBox({required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(themeColorProvider);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// 列表项组件：通过 override 的 Provider 获取数据
class _OverriddenListTile extends ConsumerWidget {
  const _OverriddenListTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 读取被 override 的 Provider
    final index = ref.watch(currentIndexProvider);
    final item = ref.watch(currentItemProvider);

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(item),
        subtitle: Text('通过 ProviderScope override 注入'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 3：ref.invalidate / ref.refresh
// -----------------------------------------------------------------------------

class _InvalidateTab extends ConsumerWidget {
  const _InvalidateTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestamp = ref.watch(timestampProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ref.invalidate 和 ref.refresh 的区别：',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前时间戳：', style: TextStyle(color: Colors.grey)),
                  Text(timestamp,
                      style: const TextStyle(fontSize: 32, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              // ✅ invalidate：标记为过期，下次 read/watch 时重新计算
              ref.invalidate(timestampProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('ref.invalidate（重新计算）'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // ✅ refresh：立即重新计算并返回新值
              final newValue = ref.refresh(timestampProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('refresh 返回: $newValue')),
              );
            },
            icon: const Icon(Icons.sync),
            label: const Text('ref.refresh（重新计算并返回值）'),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📖 区别', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• ref.invalidate(p): 标记过期，懒执行'),
                  Text('• ref.refresh(p): 立即重算并返回新值'),
                  SizedBox(height: 8),
                  Text('两者都会导致监听此 Provider 的 Widget 重建。'),
                ],
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
// 1. ProviderObserver：全局监听 Provider 创建/更新/销毁/错误
// 2. ProviderScope observers：在根 ProviderScope 中注册 Observer
// 3. ProviderScope overrides：子树中替换 Provider 的值
// 4. currentXxxProvider + override：列表项注入模式
// 5. ref.invalidate：标记 Provider 过期，下次读取时重新计算
// 6. ref.refresh：立即重新计算并返回新值
// =============================================================================
