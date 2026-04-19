import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第一章：Riverpod 简介与环境搭建
// 本示例演示：ProviderScope、StateProvider、ConsumerWidget、ref.watch/ref.read
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 声明 Provider
// StateProvider 适合管理简单的可变值（int、String、bool 等）
// -----------------------------------------------------------------------------

/// 计数器 Provider：管理一个 int 值，初始值为 0
final counterProvider = StateProvider<int>((ref) => 0);

/// 主题模式 Provider：管理一个 bool 值，控制明暗模式
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// -----------------------------------------------------------------------------
// 2. 入口：ProviderScope 包裹整个 App
// -----------------------------------------------------------------------------

void main() {
  runApp(
    const ProviderScope(
      child: Ch01App(),
    ),
  );
}

/// 根 Widget：使用 ConsumerWidget 监听主题状态
class Ch01App extends ConsumerWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch 监听暗黑模式状态，值变化时自动重建
    final isDark = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Ch01 - Riverpod 入门',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: isDark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. 计数器页面：演示 ref.watch 和 ref.read
// -----------------------------------------------------------------------------

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 在 build 中使用 ref.watch：当 counterProvider 的值变化时，自动重建
    final count = ref.watch(counterProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第一章：Riverpod 入门'),
        actions: [
          // 暗黑模式切换
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // ✅ 在回调中使用 ref.read：一次性读取并修改，不监听
              ref.read(isDarkModeProvider.notifier).state = !isDark;
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('你已经按了这么多次按钮：', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // 显示计数器值
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            // 重置按钮
            OutlinedButton.icon(
              onPressed: () {
                // 将状态重置为初始值
                ref.read(counterProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重置'),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 加 1 按钮
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: () {
              // ✅ ref.read 在回调中使用
              ref.read(counterProvider.notifier).state++;
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // 减 1 按钮
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: () {
              ref.read(counterProvider.notifier).state--;
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. ProviderScope：Riverpod 的根容器，必须包裹在 App 最外层
// 2. StateProvider：管理简单可变状态的 Provider
// 3. ConsumerWidget：替代 StatelessWidget，build 方法多一个 WidgetRef ref 参数
// 4. ref.watch(provider)：响应式监听，在 build 中使用
// 5. ref.read(provider.notifier).state：一次性读取/修改，在回调中使用
// =============================================================================
