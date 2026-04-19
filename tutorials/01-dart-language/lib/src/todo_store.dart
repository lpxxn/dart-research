/// 待办事项 JSON 文件持久化存储
///
/// 使用 JSON 文件存储待办事项数据，提供 CRUD 操作、搜索和统计功能。
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_tutorial/src/todo_model.dart';

/// 待办事项存储层
class TodoStore {
  final String filePath;
  List<Todo> _todos = [];
  int _nextId = 1;

  TodoStore(this.filePath);

  /// 从文件加载数据
  Future<void> load() async {
    try {
      var file = File(filePath);
      if (await file.exists()) {
        var content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          var jsonList = jsonDecode(content) as List;
          _todos = jsonList
              .map((item) => Todo.fromJson(item as Map<String, dynamic>))
              .toList();
          if (_todos.isNotEmpty) {
            _nextId = _todos.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
          }
        }
      }
    } on FileSystemException {
      // 文件不存在或无法读取，使用空列表
      _todos = [];
    } on FormatException {
      // JSON 格式错误，使用空列表
      _todos = [];
    }
  }

  /// 保存数据到文件
  Future<void> save() async {
    var json = jsonEncode(_todos.map((t) => t.toJson()).toList());
    var file = File(filePath);
    // 确保目录存在
    await file.parent.create(recursive: true);
    await file.writeAsString(json);
  }

  /// 添加待办事项，返回新创建的 Todo
  Future<Todo> add(String title, {Priority priority = Priority.medium}) async {
    var todo = Todo(
      id: _nextId++,
      title: title,
      priority: priority,
      createdAt: DateTime.now(),
    );
    _todos.add(todo);
    await save();
    return todo;
  }

  /// 获取所有待办事项
  List<Todo> getAll() => List.unmodifiable(_todos);

  /// 按 ID 获取
  Todo? getById(int id) {
    for (var todo in _todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  /// 更新待办事项
  Future<Todo?> update(int id, {String? title, Priority? priority, bool? completed}) async {
    var index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return null;

    var old = _todos[index];
    var updated = old.copyWith(
      title: title,
      priority: priority,
      completed: completed,
      completedAt: (completed == true) ? DateTime.now() : old.completedAt,
    );
    _todos[index] = updated;
    await save();
    return updated;
  }

  /// 标记为已完成
  Future<Todo?> complete(int id) async {
    return update(id, completed: true);
  }

  /// 删除待办事项，返回是否成功
  Future<bool> remove(int id) async {
    var before = _todos.length;
    _todos.removeWhere((t) => t.id == id);
    if (_todos.length < before) {
      await save();
      return true;
    }
    return false;
  }

  /// 搜索待办事项，返回 (匹配列表, 匹配总数) 记录类型
  (List<Todo> results, int total) search(String keyword) {
    var kw = keyword.toLowerCase();
    var results = _todos.where((t) => t.title.toLowerCase().contains(kw)).toList();
    return (results, results.length);
  }

  /// 统计信息，返回 Record
  ({int total, int completed, int pending, Map<Priority, int> byPriority}) stats() {
    var completed = _todos.where((t) => t.completed).length;
    var byPriority = <Priority, int>{};
    for (var p in Priority.values) {
      byPriority[p] = _todos.where((t) => t.priority == p).length;
    }
    return (
      total: _todos.length,
      completed: completed,
      pending: _todos.length - completed,
      byPriority: byPriority,
    );
  }

  /// 导出为 JSON 字符串
  String exportJson() {
    var encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_todos.map((t) => t.toJson()).toList());
  }
}
