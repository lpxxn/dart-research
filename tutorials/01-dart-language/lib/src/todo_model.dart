/// 待办事项数据模型
///
/// 包含 [Priority] 优先级枚举和 [Todo] 数据类
library;

/// 优先级枚举
enum Priority {
  low('低', '🟢'),
  medium('中', '🟡'),
  high('高', '🔴');

  final String label;
  final String emoji;
  const Priority(this.label, this.emoji);

  /// 从字符串解析优先级，不区分大小写
  static Priority fromString(String value) {
    return switch (value.toLowerCase()) {
      'low' || '低' => Priority.low,
      'medium' || '中' => Priority.medium,
      'high' || '高' => Priority.high,
      _ => Priority.medium,
    };
  }
}

/// 待办事项模型
class Todo {
  final int id;
  final String title;
  final Priority priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Todo({
    required this.id,
    required this.title,
    this.priority = Priority.medium,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
  });

  /// 创建副本并更新指定字段
  Todo copyWith({
    int? id,
    String? title,
    Priority? priority,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  /// 从 JSON Map 反序列化
  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as int,
        title: json['title'] as String,
        priority: Priority.values.byName(json['priority'] as String),
        completed: json['completed'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  @override
  String toString() {
    var status = completed ? '✅' : '⬜';
    return '$status [$id] ${priority.emoji} $title';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
