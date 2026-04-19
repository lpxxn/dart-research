import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// 第八章：Provider 组合与依赖
// 演示：Provider 间依赖、派生状态、依赖注入、分层架构
// =============================================================================

// -----------------------------------------------------------------------------
// 1. 数据模型
// -----------------------------------------------------------------------------

class Todo {
  final String id;
  final String title;
  final bool done;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
  });

  Todo copyWith({String? title, bool? done}) {
    return Todo(id: id, title: title ?? this.title, done: done ?? this.done, createdAt: createdAt);
  }
}

enum TodoFilter { all, active, completed }
enum TodoSort { newest, oldest, alphabetical }

// -----------------------------------------------------------------------------
// 2. Repository 层（依赖注入）
// -----------------------------------------------------------------------------

/// 抽象 Repository 接口
abstract class TodoRepository {
  List<Todo> getAll();
}

/// 内存实现
class InMemoryTodoRepository implements TodoRepository {
  @override
  List<Todo> getAll() {
    return [
      Todo(id: '1', title: '学习 Provider 组合', createdAt: DateTime(2024, 1, 1)),
      Todo(id: '2', title: '理解依赖注入', done: true, createdAt: DateTime(2024, 1, 2)),
      Todo(id: '3', title: '掌握派生状态', createdAt: DateTime(2024, 1, 3)),
      Todo(id: '4', title: '构建分层架构', createdAt: DateTime(2024, 1, 4)),
      Todo(id: '5', title: '完成实战项目', done: true, createdAt: DateTime(2024, 1, 5)),
    ];
  }
}

/// Repository Provider（依赖注入点，可在测试中 override）
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return InMemoryTodoRepository();
});

// -----------------------------------------------------------------------------
// 3. 核心状态 Notifier
// -----------------------------------------------------------------------------

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // ✅ 依赖 Repository Provider
    final repo = ref.watch(todoRepositoryProvider);
    return repo.getAll();
  }

  void addTodo(String title) {
    state = [
      ...state,
      Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
  }

  void removeTodo(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// -----------------------------------------------------------------------------
// 4. 筛选和排序 StateProvider
// -----------------------------------------------------------------------------

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);
final todoSortProvider = StateProvider<TodoSort>((ref) => TodoSort.newest);
final todoSearchProvider = StateProvider<String>((ref) => '');

// -----------------------------------------------------------------------------
// 5. 派生 Provider — 组合多个 Provider
// -----------------------------------------------------------------------------

/// ✅ 核心派生：组合 list + filter + sort + search
final filteredSortedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);
  final sort = ref.watch(todoSortProvider);
  final search = ref.watch(todoSearchProvider);

  // 1. 筛选
  var result = todos.where((t) {
    switch (filter) {
      case TodoFilter.all:
        return true;
      case TodoFilter.active:
        return !t.done;
      case TodoFilter.completed:
        return t.done;
    }
  });

  // 2. 搜索
  if (search.isNotEmpty) {
    result = result.where((t) => t.title.contains(search));
  }

  // 3. 排序
  final list = result.toList();
  switch (sort) {
    case TodoSort.newest:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case TodoSort.oldest:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    case TodoSort.alphabetical:
      list.sort((a, b) => a.title.compareTo(b.title));
  }

  return list;
});

/// 派生：统计信息
final todoStatsProvider = Provider<({int total, int active, int completed, double progress})>((ref) {
  final todos = ref.watch(todoListProvider);
  final total = todos.length;
  final completed = todos.where((t) => t.done).length;
  final active = total - completed;
  final progress = total == 0 ? 0.0 : completed / total;
  return (total: total, active: active, completed: completed, progress: progress);
});

// -----------------------------------------------------------------------------
// 6. 入口
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: Ch08App()));
}

class Ch08App extends StatelessWidget {
  const Ch08App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch08 - Provider 组合',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const TodoAppPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. Todo App 页面
// -----------------------------------------------------------------------------

class TodoAppPage extends ConsumerStatefulWidget {
  const TodoAppPage({super.key});

  @override
  ConsumerState<TodoAppPage> createState() => _TodoAppPageState();
}

class _TodoAppPageState extends ConsumerState<TodoAppPage> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(filteredSortedTodosProvider);
    final stats = ref.watch(todoStatsProvider);
    final currentFilter = ref.watch(todoFilterProvider);
    final currentSort = ref.watch(todoSortProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('第八章：Provider 组合')),
      body: Column(
        children: [
          // 统计栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('总计', '${stats.total}', Icons.list),
                _statItem('进行中', '${stats.active}', Icons.radio_button_unchecked),
                _statItem('已完成', '${stats.completed}', Icons.check_circle),
                Column(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: stats.progress,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(stats.progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => ref.read(todoSearchProvider.notifier).state = v,
            ),
          ),

          // 筛选 + 排序
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // 筛选
                Expanded(
                  child: SegmentedButton<TodoFilter>(
                    segments: const [
                      ButtonSegment(value: TodoFilter.all, label: Text('全部')),
                      ButtonSegment(value: TodoFilter.active, label: Text('进行')),
                      ButtonSegment(value: TodoFilter.completed, label: Text('完成')),
                    ],
                    selected: {currentFilter},
                    onSelectionChanged: (s) =>
                        ref.read(todoFilterProvider.notifier).state = s.first,
                  ),
                ),
                const SizedBox(width: 8),
                // 排序下拉
                DropdownButton<TodoSort>(
                  value: currentSort,
                  items: const [
                    DropdownMenuItem(value: TodoSort.newest, child: Text('最新')),
                    DropdownMenuItem(value: TodoSort.oldest, child: Text('最早')),
                    DropdownMenuItem(value: TodoSort.alphabetical, child: Text('字母')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(todoSortProvider.notifier).state = v;
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // 添加 Todo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: const InputDecoration(
                      hintText: '添加新任务...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _addTodo,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addTodo(_addController.text),
                  child: const Text('添加'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Todo 列表
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('没有匹配的任务'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return ListTile(
                        leading: Checkbox(
                          value: todo.done,
                          onChanged: (_) => ref
                              .read(todoListProvider.notifier)
                              .toggleTodo(todo.id),
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            decoration:
                                todo.done ? TextDecoration.lineThrough : null,
                            color: todo.done ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => ref
                              .read(todoListProvider.notifier)
                              .removeTodo(todo.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addTodo(String title) {
    if (title.trim().isEmpty) return;
    ref.read(todoListProvider.notifier).addTodo(title.trim());
    _addController.clear();
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// =============================================================================
// 知识点总结：
//
// 1. Provider 间依赖：ref.watch 构建自动更新的依赖链
// 2. 派生状态：用 Provider 组合 filter + sort + search 得到最终列表
// 3. 统计 Provider：从核心状态派生出统计信息
// 4. 依赖注入：Repository 通过 Provider 注入，便于测试时 override
// 5. 分层架构：Repository → Notifier → 派生 Provider → UI
// =============================================================================
