import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================
// 数据模型：表示一个待办事项
// ============================================================
class TodoModel {
  final String id;
  final String title;
  bool isDone;

  TodoModel({
    required this.id,
    required this.title,
    this.isDone = false,
  });
}

// ============================================================
// 状态管理：TodoListNotifier
// 继承 ChangeNotifier，管理待办事项列表
// ============================================================
class TodoListNotifier extends ChangeNotifier {
  final List<TodoModel> _todos = [];

  /// 获取所有待办事项（返回不可变列表，防止外部直接修改）
  List<TodoModel> get todos => List.unmodifiable(_todos);

  /// 获取已完成的待办数量
  int get doneCount => _todos.where((t) => t.isDone).length;

  /// 添加一个新的待办事项
  void add(String title) {
    final todo = TodoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _todos.add(todo);
    notifyListeners();
  }

  /// 切换待办事项的完成状态
  void toggle(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index].isDone = !_todos[index].isDone;
      notifyListeners();
    }
  }

  /// 删除一个待办事项
  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

// ============================================================
// 入口：使用 ChangeNotifierProvider 提供状态
// ============================================================
void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => TodoListNotifier(),
        child: const TodoApp(),
      ),
    );

// ============================================================
// 应用根组件
// ============================================================
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const TodoHomePage(),
    );
  }
}

// ============================================================
// 主页面：组合各个子组件
// ============================================================
class TodoHomePage extends StatelessWidget {
  const TodoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
        // 使用 Selector 只在总数变化时更新副标题
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Selector<TodoListNotifier, int>(
            selector: (_, notifier) => notifier.todos.length,
            builder: (context, total, child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '共 $total 项',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.8),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: const Column(
        children: [
          // 统计信息：展示已完成数量
          TodoStatsWidget(),
          Divider(height: 1),
          // 添加待办
          AddTodoWidget(),
          Divider(height: 1),
          // 待办列表
          Expanded(child: TodoListWidget()),
        ],
      ),
    );
  }
}

// ============================================================
// 统计组件：使用 Selector 精准监听已完成数量
// 只有 doneCount 变化时才会重建
// ============================================================
class TodoStatsWidget extends StatelessWidget {
  const TodoStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<TodoListNotifier, int>(
      selector: (_, notifier) => notifier.doneCount,
      builder: (context, doneCount, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 8),
              Text(
                '已完成: $doneCount 项',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// 添加待办组件：使用 context.read 触发添加操作
// ============================================================
class AddTodoWidget extends StatefulWidget {
  const AddTodoWidget({super.key});

  @override
  State<AddTodoWidget> createState() => _AddTodoWidgetState();
}

class _AddTodoWidgetState extends State<AddTodoWidget> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // 使用 context.read 在事件回调中读取 Provider（不监听变化）
    context.read<TodoListNotifier>().add(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '输入待办事项...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
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

// ============================================================
// 待办列表组件：使用 Consumer 监听列表变化
// ============================================================
class TodoListWidget extends StatelessWidget {
  const TodoListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 限制重建范围，只有列表区域会因数据变化而重建
    return Consumer<TodoListNotifier>(
      builder: (context, todoList, child) {
        final todos = todoList.todos;
        if (todos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无待办事项',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '点击上方添加按钮开始',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return TodoItemWidget(
              key: ValueKey(todo.id),
              todo: todo,
            );
          },
        );
      },
    );
  }
}

// ============================================================
// 单个待办项组件
// ============================================================
class TodoItemWidget extends StatelessWidget {
  final TodoModel todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(todo.id),
      // 滑动删除
      onDismissed: (_) {
        context.read<TodoListNotifier>().remove(todo.id);
      },
      background: Container(
        color: Colors.red.withValues(alpha: 0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      child: ListTile(
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) {
            // 使用 context.read 在回调中触发状态变更
            context.read<TodoListNotifier>().toggle(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)
                : null,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red.withValues(alpha: 0.6),
          ),
          onPressed: () {
            context.read<TodoListNotifier>().remove(todo.id);
          },
        ),
      ),
    );
  }
}
