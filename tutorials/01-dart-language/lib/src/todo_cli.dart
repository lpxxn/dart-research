/// 命令行待办事项交互层
///
/// 使用 sealed class 定义命令类型，Patterns 解析命令，ANSI 彩色输出。
library;

import 'package:dart_tutorial/src/todo_model.dart';
import 'package:dart_tutorial/src/todo_store.dart';

// ============================================================
// ANSI 颜色工具
// ============================================================

/// ANSI 转义码颜色扩展
extension AnsiColor on String {
  String get red => '\x1B[31m$this\x1B[0m';
  String get green => '\x1B[32m$this\x1B[0m';
  String get yellow => '\x1B[33m$this\x1B[0m';
  String get blue => '\x1B[34m$this\x1B[0m';
  String get magenta => '\x1B[35m$this\x1B[0m';
  String get cyan => '\x1B[36m$this\x1B[0m';
  String get bold => '\x1B[1m$this\x1B[0m';
  String get dim => '\x1B[2m$this\x1B[0m';
}

// ============================================================
// 命令定义（sealed class）
// ============================================================

/// 所有命令的基类
sealed class Command {}

/// 添加待办事项
class AddCommand extends Command {
  final String title;
  final Priority priority;
  AddCommand(this.title, {this.priority = Priority.medium});
}

/// 列出所有待办事项
class ListCommand extends Command {}

/// 标记完成
class DoneCommand extends Command {
  final int id;
  DoneCommand(this.id);
}

/// 删除待办事项
class RemoveCommand extends Command {
  final int id;
  RemoveCommand(this.id);
}

/// 搜索
class SearchCommand extends Command {
  final String keyword;
  SearchCommand(this.keyword);
}

/// 统计
class StatsCommand extends Command {}

/// 导出 JSON
class ExportCommand extends Command {}

/// 帮助
class HelpCommand extends Command {}

/// 退出
class QuitCommand extends Command {}

/// 未知命令
class UnknownCommand extends Command {
  final String input;
  UnknownCommand(this.input);
}

// ============================================================
// CLI 交互层
// ============================================================

/// 命令行交互层
class TodoCli {
  final TodoStore store;

  TodoCli(this.store);

  /// 解析命令字符串为 Command 对象
  Command parseCommand(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return UnknownCommand('');

    var parts = trimmed.split(RegExp(r'\s+'));

    return switch (parts) {
      ['add', ...var rest] when rest.isNotEmpty => _parseAddCommand(rest),
      ['list'] => ListCommand(),
      ['done', var id] => DoneCommand(int.tryParse(id) ?? -1),
      ['remove' || 'rm' || 'delete', var id] => RemoveCommand(int.tryParse(id) ?? -1),
      ['search' || 'find', ...var keywords] when keywords.isNotEmpty =>
        SearchCommand(keywords.join(' ')),
      ['stats'] => StatsCommand(),
      ['export'] => ExportCommand(),
      ['help' || '?'] => HelpCommand(),
      ['quit' || 'exit' || 'q'] => QuitCommand(),
      _ => UnknownCommand(trimmed),
    };
  }

  /// 解析 add 命令的参数
  AddCommand _parseAddCommand(List<String> parts) {
    var priority = Priority.medium;
    var titleParts = <String>[];

    for (var i = 0; i < parts.length; i++) {
      if ((parts[i] == '-p' || parts[i] == '--priority') && i + 1 < parts.length) {
        priority = Priority.fromString(parts[i + 1]);
        i++; // 跳过优先级值
      } else {
        titleParts.add(parts[i]);
      }
    }

    return AddCommand(titleParts.join(' '), priority: priority);
  }

  /// 执行命令并返回输出字符串
  Future<String> execute(Command command) async {
    return switch (command) {
      AddCommand(:var title, :var priority) => _executeAdd(title, priority),
      ListCommand() => _executeList(),
      DoneCommand(:var id) => _executeDone(id),
      RemoveCommand(:var id) => _executeRemove(id),
      SearchCommand(:var keyword) => _executeSearch(keyword),
      StatsCommand() => _executeStats(),
      ExportCommand() => _executeExport(),
      HelpCommand() => _executeHelp(),
      QuitCommand() => '👋 再见！',
      UnknownCommand(:var input) => '⚠️ 未知命令: "$input"，输入 help 查看帮助'.yellow,
    };
  }

  /// 处理一条命令：解析 + 执行
  Future<(String output, bool shouldQuit)> handleCommand(String input) async {
    var command = parseCommand(input);
    var output = await execute(command);
    return (output, command is QuitCommand);
  }

  // --- 命令实现 ---

  Future<String> _executeAdd(String title, Priority priority) async {
    if (title.isEmpty) {
      return '❌ 请提供待办事项标题'.red;
    }
    var todo = await store.add(title, priority: priority);
    return '✅ 已添加: ${todo.toString()}'.green;
  }

  Future<String> _executeList() async {
    var todos = store.getAll();
    if (todos.isEmpty) {
      return '📋 暂无待办事项'.dim;
    }

    var buf = StringBuffer();
    buf.writeln('📋 待办事项列表'.bold);
    buf.writeln('─' * 50);

    // 按优先级和完成状态排序
    var sorted = [...todos]..sort((a, b) {
        if (a.completed != b.completed) return a.completed ? 1 : -1;
        return b.priority.index.compareTo(a.priority.index);
      });

    for (var todo in sorted) {
      var line = _formatTodoLine(todo);
      buf.writeln(line);
    }

    buf.write('─' * 50);
    buf.write('\n共 ${todos.length} 项');
    var pending = todos.where((t) => !t.completed).length;
    if (pending > 0) buf.write('，$pending 项待完成');
    return buf.toString();
  }

  Future<String> _executeDone(int id) async {
    if (id < 0) return '❌ 无效的 ID'.red;
    var todo = await store.complete(id);
    if (todo == null) {
      return '❌ 未找到 ID 为 $id 的待办事项'.red;
    }
    return '✅ 已完成: ${todo.title}'.green;
  }

  Future<String> _executeRemove(int id) async {
    if (id < 0) return '❌ 无效的 ID'.red;
    var success = await store.remove(id);
    if (!success) {
      return '❌ 未找到 ID 为 $id 的待办事项'.red;
    }
    return '🗑️ 已删除 #$id'.yellow;
  }

  Future<String> _executeSearch(String keyword) async {
    var (results, total) = store.search(keyword);
    if (total == 0) {
      return '🔍 未找到包含 "$keyword" 的待办事项'.dim;
    }

    var buf = StringBuffer();
    buf.writeln('🔍 搜索结果: "$keyword" (找到 $total 项)'.cyan);
    for (var todo in results) {
      buf.writeln('  ${todo.toString()}');
    }
    return buf.toString().trimRight();
  }

  Future<String> _executeStats() async {
    var (:total, :completed, :pending, :byPriority) = store.stats();

    var buf = StringBuffer();
    buf.writeln('📊 统计信息'.bold);
    buf.writeln('─' * 30);
    buf.writeln('  总计:   $total 项');
    buf.writeln('  已完成: $completed 项 ✅');
    buf.writeln('  待完成: $pending 项 ⬜');
    if (total > 0) {
      var percent = (completed / total * 100).toStringAsFixed(1);
      buf.writeln('  完成率: $percent%');
    }
    buf.writeln('─' * 30);
    buf.writeln('  按优先级:');
    for (var p in Priority.values) {
      buf.writeln('    ${p.emoji} ${p.label}: ${byPriority[p]} 项');
    }
    return buf.toString().trimRight();
  }

  Future<String> _executeExport() async {
    var json = store.exportJson();
    return '📤 JSON 导出:\n$json';
  }

  String _executeHelp() {
    return '''
📖 命令帮助
${'─' * 40}
  ${'add <标题> [-p <优先级>]'.cyan}  添加待办事项
      优先级: low/medium/high (默认 medium)
  ${'list'.cyan}                   显示所有待办事项
  ${'done <ID>'.cyan}              标记为已完成
  ${'remove <ID>'.cyan}            删除待办事项
  ${'search <关键词>'.cyan}         搜索待办事项
  ${'stats'.cyan}                  显示统计信息
  ${'export'.cyan}                 导出为 JSON
  ${'help'.cyan}                   显示此帮助
  ${'quit'.cyan}                   退出程序
${'─' * 40}''';
  }

  /// 格式化单条待办事项
  String _formatTodoLine(Todo todo) {
    var status = todo.completed ? '✅' : '⬜';
    var id = '#${todo.id}'.padRight(4);
    var prio = todo.priority.emoji;
    var title = todo.completed ? todo.title.dim : todo.title;
    var date = _formatDate(todo.createdAt);
    return '  $status $id $prio $title  ${date.dim}';
  }

  /// 格式化日期
  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 打印欢迎信息
  String welcome() {
    return '''
╔══════════════════════════════════════╗
║     📝 命令行待办事项应用 (Todo CLI)  ║
║     输入 help 查看帮助               ║
╚══════════════════════════════════════╝''';
  }
}
