# 第16章：实战项目 — 命令行待办事项应用

## 16.1 项目需求

本章我们将综合运用前面所学的知识，构建一个**命令行待办事项应用（CLI Todo App）**。

### 功能清单

| 命令 | 说明 | 示例 |
|------|------|------|
| `add` | 添加待办事项 | `add 学习 Dart -p high` |
| `list` | 显示所有待办事项 | `list` |
| `done` | 标记为已完成 | `done 1` |
| `remove` | 删除待办事项 | `remove 2` |
| `search` | 搜索待办事项 | `search Dart` |
| `stats` | 显示统计信息 | `stats` |
| `export` | 导出为 JSON | `export` |
| `help` | 显示帮助 | `help` |
| `quit` | 退出程序 | `quit` |

### 技术要求

- 数据持久化：使用 JSON 文件存储
- 优先级：高 🔴 / 中 🟡 / 低 🟢
- 彩色输出：使用 ANSI 转义码
- 错误处理：友好的错误提示
- 架构清晰：三层分离

---

## 16.2 架构设计

### 三层架构

```
┌─────────────────────────────────┐
│  bin/ch16_todo_app.dart          │  入口层
│  （程序入口 + 命令演示）          │
├─────────────────────────────────┤
│  lib/src/todo_cli.dart           │  CLI 交互层
│  （命令解析 + 格式化输出）        │
├─────────────────────────────────┤
│  lib/src/todo_store.dart         │  存储层
│  （JSON 文件读写 + CRUD 操作）    │
├─────────────────────────────────┤
│  lib/src/todo_model.dart         │  模型层
│  （数据模型 + 序列化）            │
└─────────────────────────────────┘
```

### 文件结构

```
dart-tutorial/
├── lib/
│   └── src/
│       ├── todo_model.dart    # Todo 数据模型 + Priority 枚举
│       ├── todo_store.dart    # JSON 文件持久化存储
│       └── todo_cli.dart      # CLI 交互层 + 命令解析
├── bin/
│   └── ch16_todo_app.dart     # 程序入口
```

### 数据流

```
用户命令 → CLI 解析命令 → Store 执行操作 → Model 数据转换
                ↑                                    │
                └────────── 格式化输出 ←──────────────┘
```

---

## 16.3 知识点运用

本项目综合运用了教程中 **13 章以上** 的知识点：

### Enhanced Enum（增强枚举）

`Priority` 枚举使用了增强枚举特性，每个枚举值携带 `label` 和 `emoji` 属性：

```dart
enum Priority {
  low('低', '🟢'),
  medium('中', '🟡'),
  high('高', '🔴');
  
  final String label;
  final String emoji;
  const Priority(this.label, this.emoji);
}
```

### sealed class 定义命令类型

使用密封类定义所有可能的命令，编译器确保 switch 穷尽检查：

```dart
sealed class Command {}
class AddCommand extends Command { ... }
class ListCommand extends Command { ... }
class DoneCommand extends Command { ... }
// ...
```

### Patterns 解析命令

使用模式匹配解析用户输入的命令字符串：

```dart
Command parse(String input) {
  return switch (parts) {
    ['add', ...var titleParts] => AddCommand(...),
    ['list']                   => ListCommand(),
    ['done', var id]           => DoneCommand(int.parse(id)),
    // ...
  };
}
```

### Records 返回复合结果

搜索操作返回 Record 类型，包含匹配的待办事项和匹配数量：

```dart
(List<Todo> results, int total) search(String keyword) { ... }
```

### async/await 文件 IO

存储层使用异步文件操作：

```dart
Future<void> save() async {
  var json = jsonEncode(todos.map((t) => t.toJson()).toList());
  await File(filePath).writeAsString(json);
}
```

### 异常处理

使用 try/catch 处理文件不存在、JSON 解析失败等异常：

```dart
try {
  var content = await File(filePath).readAsString();
  // ...
} on FileSystemException {
  // 文件不存在，使用空列表
}
```

### 泛型

Store 中的方法使用泛型来保持类型安全。

### Extension Methods

可以为 String 添加扩展方法来实现彩色输出。

---

## 16.4 完整代码解析

### todo_model.dart — 数据模型

核心类 `Todo` 包含：
- **属性**：id, title, priority, completed, createdAt, completedAt
- **copyWith**：不可变对象的更新模式，返回新实例
- **toJson / fromJson**：JSON 序列化与反序列化
- **toString**：格式化的字符串表示

`Priority` 增强枚举包含中文标签和 emoji 图标，通过 `byName` 静态方法从字符串解析。

### todo_store.dart — 持久化存储

`TodoStore` 类负责：
- **文件读写**：使用 `dart:io` 的 File 类和 `dart:convert` 的 JSON 编解码
- **CRUD 操作**：add（自动分配 ID）、getAll、getById、update、remove
- **搜索**：关键词搜索，返回 Record 类型 `(List<Todo>, int)`
- **统计**：total（总数）、completed（已完成）、pending（待完成）
- **自动保存**：每次修改操作后自动持久化到文件

### todo_cli.dart — CLI 交互

`TodoCli` 类负责：
- **命令解析**：使用 sealed class `Command` + Patterns 将字符串解析为类型安全的命令对象
- **命令执行**：switch 表达式分发到对应处理方法
- **格式化输出**：ANSI 转义码实现彩色终端输出
- **帮助信息**：展示所有可用命令

### ch16_todo_app.dart — 入口

入口文件使用**演示模式**：预定义一组命令序列，依次执行并展示结果。这样可以在不需要交互式终端的情况下完整展示所有功能：

```dart
final commands = [
  'add 学习 Dart 基础语法 -p high',
  'add 完成集合章节练习 -p medium',
  'list',
  'done 1',
  'stats',
  'export',
];
```

---

## 小结

通过这个项目，我们综合运用了：

| 知识点 | 在项目中的应用 |
|--------|--------------|
| 增强枚举 | Priority 优先级定义 |
| 类与构造函数 | Todo 数据模型 |
| sealed class | Command 命令类型 |
| Patterns | 命令解析 |
| switch 表达式 | 命令分发 |
| Records | 搜索结果返回 |
| async/await | 文件异步 IO |
| 异常处理 | 错误友好提示 |
| JSON 序列化 | 数据持久化 |
| ANSI 转义码 | 彩色终端输出 |

这个项目虽然功能简单，但展示了如何用 Dart 构建一个**架构清晰、类型安全、代码优雅**的命令行应用。这些设计理念和编码技巧可以直接应用到更大型的项目中。
