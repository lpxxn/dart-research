import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第四章：Riverpod 状态管理 - Todo List 示例
// 使用 Riverpod 2.x NotifierProvider 模式
// =============================================================================

// -----------------------------------------------------------------------------
// 数据模型
// -----------------------------------------------------------------------------

/// Todo 数据类
class Todo {
  final String id;
  final String title;
  final bool isDone;

  const Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });
}

// -----------------------------------------------------------------------------
// 过滤枚举
// -----------------------------------------------------------------------------

/// Todo 过滤类型
enum TodoFilter {
  all,
  active,
  completed,
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

/// Todo 列表状态管理 Notifier
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // 初始状态：包含一些示例数据
    return [
      const Todo(id: '1', title: '学习 Riverpod 基础概念'),
      const Todo(id: '2', title: '理解 ref.watch 和 ref.read 的区别'),
      const Todo(id: '3', title: '完成 Todo List 示例', isDone: true),
    ];
  }

  /// 添加新的 Todo
  void addTodo(String title) {
    if (title.trim().isEmpty) return;
    state = [
      ...state,
      Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
      ),
    ];
  }

  /// 切换 Todo 的完成状态
  void toggleTodo(String id) {
    state = state.map((todo) {
      if (todo.id == id) {
        return Todo(id: todo.id, title: todo.title, isDone: !todo.isDone);
      }
      return todo;
    }).toList();
  }

  /// 删除指定 Todo
  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

/// Todo 列表 Provider（使用 NotifierProvider）
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(() {
  return TodoListNotifier();
});

/// 过滤条件 Provider（使用 StateProvider 管理简单枚举状态）
final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

/// 过滤后的 Todo 列表（派生状态，根据过滤条件自动计算）
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoFilterProvider);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoFilter.all:
      return todos;
    case TodoFilter.active:
      return todos.where((t) => !t.isDone).toList();
    case TodoFilter.completed:
      return todos.where((t) => t.isDone).toList();
  }
});

/// 各状态的 Todo 数量统计（派生状态）
final todoStatsProvider = Provider<({int total, int active, int completed})>((ref) {
  final todos = ref.watch(todoListProvider);
  final completed = todos.where((t) => t.isDone).length;
  return (
    total: todos.length,
    active: todos.length - completed,
    completed: completed,
  );
});

// =============================================================================
// 应用入口
// =============================================================================

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod Todo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const TodoApp(),
    );
  }
}

// =============================================================================
// 主页面 - 使用 ConsumerWidget 访问 Provider
// =============================================================================

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todoStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Todo List'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // 统计信息栏
          _StatsBar(stats: stats),
          // 添加 Todo 输入区域
          const _AddTodoField(),
          // 过滤按钮
          const _FilterButtons(),
          // Todo 列表
          const Expanded(child: _TodoList()),
        ],
      ),
    );
  }
}

// =============================================================================
// 统计信息栏
// =============================================================================

class _StatsBar extends StatelessWidget {
  final ({int total, int active, int completed}) stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: '全部', count: stats.total, color: colorScheme.primary),
          _StatItem(label: '待完成', count: stats.active, color: Colors.orange),
          _StatItem(label: '已完成', count: stats.completed, color: Colors.green),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 添加 Todo 输入区域 - 使用 ConsumerStatefulWidget（需要 TextEditingController）
// =============================================================================

class _AddTodoField extends ConsumerStatefulWidget {
  const _AddTodoField();

  @override
  ConsumerState<_AddTodoField> createState() => _AddTodoFieldState();
}

class _AddTodoFieldState extends ConsumerState<_AddTodoField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    // 使用 ref.read 在回调中触发操作
    ref.read(todoListProvider.notifier).addTodo(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '添加新的 Todo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 过滤按钮 - 使用 ConsumerWidget
// =============================================================================

class _FilterButtons extends ConsumerWidget {
  const _FilterButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 ref.watch 监听当前过滤状态，变化时自动重建
    final currentFilter = ref.watch(todoFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: TodoFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(_filterLabel(filter)),
              onSelected: (_) {
                // 使用 ref.read 在回调中修改状态
                ref.read(todoFilterProvider.notifier).state = filter;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return '全部';
      case TodoFilter.active:
        return '待完成';
      case TodoFilter.completed:
        return '已完成';
    }
  }
}

// =============================================================================
// Todo 列表 - 使用 ConsumerWidget
// =============================================================================

class _TodoList extends ConsumerWidget {
  const _TodoList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听过滤后的 Todo 列表（派生状态）
    final filteredTodos = ref.watch(filteredTodosProvider);

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无 Todo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = filteredTodos[index];
        return _TodoItem(todo: todo);
      },
    );
  }
}

// =============================================================================
// 单个 Todo 项 - 使用 ConsumerWidget
// =============================================================================

class _TodoItem extends ConsumerWidget {
  final Todo todo;

  const _TodoItem({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) {
            // 使用 ref.read 触发状态变更
            ref.read(todoListProvider.notifier).toggleTodo(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone
                ? colorScheme.onSurface.withValues(alpha: 0.5)
                : colorScheme.onSurface,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
          onPressed: () {
            ref.read(todoListProvider.notifier).removeTodo(todo.id);
          },
        ),
      ),
    );
  }
}
