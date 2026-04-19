/// 第16章：实战项目 — 命令行待办事项应用
///
/// 演示模式：预定义命令序列，依次执行并展示结果。
/// 运行方式: dart run bin/ch16_todo_app.dart
library;

import 'dart:io';

import 'package:dart_tutorial/src/todo_cli.dart';
import 'package:dart_tutorial/src/todo_store.dart';

Future<void> main() async {
  // 使用临时文件存储演示数据（运行结束后清理）
  var dataFile = Directory.current.uri.resolve('.todo_demo_data.json').toFilePath();

  // 初始化存储和 CLI
  var store = TodoStore(dataFile);
  await store.load();
  var cli = TodoCli(store);

  // 打印欢迎信息
  print(cli.welcome());
  print('');

  // 演示模式：预定义命令序列
  final commands = [
    'help',
    'add 学习 Dart 基础语法 -p high',
    'add 完成集合章节练习 -p medium',
    'add 阅读异步编程文档 -p low',
    'add 编写 CLI 待办应用 -p high',
    'add 复习 Patterns 模式匹配 -p medium',
    'list',
    'done 1',
    'done 3',
    'list',
    'search Dart',
    'search 编写',
    'remove 2',
    'list',
    'stats',
    'export',
    'quit',
  ];

  // 依次执行每条命令
  for (var cmd in commands) {
    print('─' * 50);
    print('> $cmd');
    print('');

    var (output, shouldQuit) = await cli.handleCommand(cmd);
    print(output);
    print('');

    if (shouldQuit) break;
  }

  // 清理演示数据文件
  try {
    var file = File(dataFile);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // 忽略清理错误
  }

  print('✅ 第16章演示完成！');
}
