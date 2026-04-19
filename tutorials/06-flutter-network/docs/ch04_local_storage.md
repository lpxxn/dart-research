# 第4章：本地存储

> 本章配套代码见 `lib/ch04_local_storage.dart`

---

## 目录

1. [本地存储概述](#1-本地存储概述)
2. [SharedPreferences 详解](#2-sharedpreferences-详解)
3. [sqflite 数据库](#3-sqflite-数据库)
4. [Hive 轻量级 NoSQL](#4-hive-轻量级-nosql)
5. [drift 类型安全的 SQLite 封装](#5-drift-类型安全的-sqlite-封装)
6. [选型对比表](#6-选型对比表)
7. [SharedPreferences 最佳实践](#7-sharedpreferences-最佳实践)
8. [本章小结](#8-本章小结)

---

## 1. 本地存储概述

### 1.1 为什么需要本地存储？

在移动应用开发中，几乎所有的 App 都需要在设备本地保存一些数据。这些数据可能是用户的偏好设置、登录凭证、缓存的网络数据，或者是应用本身的业务数据。如果所有数据都依赖网络请求来获取，那么在无网络环境下应用将无法正常工作，同时频繁的网络请求也会带来不必要的流量消耗和延迟。

本地存储的核心价值在于：

- **离线可用**：用户在没有网络连接时依然能使用应用的核心功能。
- **性能提升**：从本地读取数据比网络请求快几个数量级，可以显著提升用户体验。
- **减少流量消耗**：避免重复请求相同的数据，节省用户的流量开支。
- **数据持久化**：App 被杀死或设备重启后，数据依然存在。

### 1.2 常见的本地存储场景

| 场景 | 说明 | 推荐方案 |
|------|------|----------|
| 用户设置 | 主题模式、语言、通知开关等 | SharedPreferences |
| 登录状态 | Token、用户 ID、上次登录时间 | SharedPreferences / Flutter Secure Storage |
| 首次启动标记 | 是否显示引导页 | SharedPreferences |
| 结构化业务数据 | 订单、聊天记录、联系人列表 | sqflite / drift |
| 大量键值对缓存 | 离线缓存、本地草稿 | Hive |
| 文件型数据 | 图片、视频、文档 | path_provider + 文件系统 |
| 敏感数据 | 密码、密钥、证书 | flutter_secure_storage |

### 1.3 Flutter 本地存储方案全景

Flutter 提供了多种本地存储方案，每种方案都有其特定的适用场景：

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter 本地存储方案                     │
├──────────────┬──────────────┬─────────────┬─────────────┤
│ SharedPrefs  │   sqflite    │    Hive     │    drift    │
│  键值对存储   │  SQLite 数据库│ NoSQL 存储  │ 类型安全 ORM │
│  简单配置     │  结构化数据   │ 高性能缓存  │  复杂查询    │
└──────────────┴──────────────┴─────────────┴─────────────┘
```

---

## 2. SharedPreferences 详解

### 2.1 原理

`shared_preferences` 是 Flutter 官方维护的键值对存储插件。它在不同平台上的底层实现各不相同：

- **iOS / macOS**：基于 `NSUserDefaults`，这是 Apple 平台提供的标准用户偏好存储机制。数据以 plist 格式存储在应用沙盒中。
- **Android**：基于 `android.content.SharedPreferences`，数据以 XML 文件的形式存储在应用的私有目录下（`/data/data/<包名>/shared_prefs/`）。
- **Web**：基于浏览器的 `localStorage` API。
- **Windows / Linux**：基于本地文件系统的 JSON 文件存储。

其核心原理非常简单：将数据以 **键值对（Key-Value）** 的方式存储在设备本地文件中。每次读取时从文件中解析数据，写入时将数据序列化后写入文件。

```
┌──────────────────────────────────────────────────┐
│            shared_preferences 插件                │
│                                                  │
│  Flutter Dart API（统一接口）                      │
│       ↓                ↓              ↓          │
│  iOS/macOS         Android          Web          │
│  NSUserDefaults    SharedPrefs      localStorage │
│       ↓                ↓              ↓          │
│  .plist 文件       .xml 文件        浏览器存储     │
└──────────────────────────────────────────────────┘
```

> **注意**：SharedPreferences 并不适合存储大量数据或敏感数据。它的设计初衷是用于保存轻量级的用户偏好设置。

### 2.2 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  shared_preferences: ^2.2.2
```

然后运行安装命令：

```bash
flutter pub get
```

### 2.3 支持的数据类型

SharedPreferences 支持以下 5 种基本数据类型：

| 数据类型 | 写入方法 | 读取方法 | 说明 |
|----------|----------|----------|------|
| `String` | `setString(key, value)` | `getString(key)` | 字符串 |
| `int` | `setInt(key, value)` | `getInt(key)` | 整数 |
| `double` | `setDouble(key, value)` | `getDouble(key)` | 浮点数 |
| `bool` | `setBool(key, value)` | `getBool(key)` | 布尔值 |
| `List<String>` | `setStringList(key, value)` | `getStringList(key)` | 字符串列表 |

> **提示**：如果需要存储复杂对象（如 Map 或自定义类），可以先将其转换为 JSON 字符串，再用 `setString` 存储。

### 2.4 基本用法：存储数据

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 存储各种类型的数据
Future<void> saveUserPreferences() async {
  // 获取 SharedPreferences 实例（单例模式，首次调用会初始化）
  final prefs = await SharedPreferences.getInstance();

  // 存储字符串
  await prefs.setString('username', '张三');

  // 存储整数
  await prefs.setInt('login_count', 42);

  // 存储浮点数
  await prefs.setDouble('app_version', 1.2);

  // 存储布尔值
  await prefs.setBool('is_dark_mode', true);

  // 存储字符串列表
  await prefs.setStringList('favorite_cities', ['北京', '上海', '深圳']);

  print('所有用户偏好已保存');
}
```

### 2.5 基本用法：读取数据

```dart
/// 读取各种类型的数据
Future<void> loadUserPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  // 读取字符串，如果 key 不存在则返回 null
  final String? username = prefs.getString('username');
  print('用户名: ${username ?? "未设置"}');

  // 读取整数，提供默认值
  final int loginCount = prefs.getInt('login_count') ?? 0;
  print('登录次数: $loginCount');

  // 读取浮点数
  final double? appVersion = prefs.getDouble('app_version');
  print('应用版本: $appVersion');

  // 读取布尔值
  final bool isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  print('深色模式: $isDarkMode');

  // 读取字符串列表
  final List<String>? cities = prefs.getStringList('favorite_cities');
  print('收藏城市: $cities');

  // 检查某个 key 是否存在
  final bool hasUsername = prefs.containsKey('username');
  print('是否已设置用户名: $hasUsername');

  // 获取所有已存储的 key
  final Set<String> allKeys = prefs.getKeys();
  print('所有存储的键: $allKeys');
}
```

### 2.6 基本用法：删除与清空

```dart
/// 删除单个键值对和清空全部数据
Future<void> removeData() async {
  final prefs = await SharedPreferences.getInstance();

  // 删除单个键值对
  await prefs.remove('username');
  print('已删除 username');

  // 清空所有数据（慎用！会删除所有 SharedPreferences 中的数据）
  await prefs.clear();
  print('已清空所有本地存储数据');
}
```

### 2.7 异步 API 的正确使用

SharedPreferences 的所有操作都是 **异步** 的，这意味着必须使用 `async/await` 或 `.then()` 来处理。

```dart
/// 方式一：使用 async/await（推荐）
Future<void> saveWithAsyncAwait() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('key', 'value');
  // 写入完成后继续执行
  print('数据已写入');
}

/// 方式二：使用 .then() 链式调用
void saveWithThen() {
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString('key', 'value').then((_) {
      print('数据已写入');
    });
  });
}

/// 在 Widget 中使用的完整示例
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 页面初始化时加载设置
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isLoading = false;
    });
  }

  /// 保存设置到本地存储
  Future<void> _saveSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SwitchListTile(
        title: const Text('深色模式'),
        subtitle: const Text('切换应用的主题模式'),
        value: _isDarkMode,
        onChanged: _saveSettings,
      ),
    );
  }
}
```

### 2.8 存储复杂对象（JSON 序列化）

虽然 SharedPreferences 只支持基本类型，但通过 JSON 序列化可以存储复杂对象：

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户信息模型
class UserInfo {
  final String name;
  final int age;
  final String email;

  UserInfo({required this.name, required this.age, required this.email});

  /// 将对象转换为 Map
  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'email': email,
      };

  /// 从 Map 创建对象
  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        name: json['name'] as String,
        age: json['age'] as int,
        email: json['email'] as String,
      );
}

/// 保存用户信息对象
Future<void> saveUserInfo(UserInfo user) async {
  final prefs = await SharedPreferences.getInstance();
  // 将对象序列化为 JSON 字符串后存储
  final jsonString = jsonEncode(user.toJson());
  await prefs.setString('user_info', jsonString);
  print('用户信息已保存: $jsonString');
}

/// 读取用户信息对象
Future<UserInfo?> loadUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('user_info');
  if (jsonString == null) return null;

  // 将 JSON 字符串反序列化为对象
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  return UserInfo.fromJson(jsonMap);
}
```

### 2.9 适用场景总结

SharedPreferences 最适合以下场景：

- ✅ **用户设置**：主题、语言、字体大小等偏好配置
- ✅ **首次启动标记**：是否展示引导页、版本更新提示
- ✅ **简单缓存**：上次选择的城市、最近搜索关键词
- ✅ **登录状态**：Token、用户 ID（非敏感场景）
- ✅ **应用状态**：上次退出时的页面位置、阅读进度

不适合的场景：

- ❌ 大量结构化数据（应使用 sqflite / drift）
- ❌ 高频读写操作（应使用 Hive）
- ❌ 敏感数据如密码、密钥（应使用 flutter_secure_storage）
- ❌ 二进制文件数据（应使用文件系统）

---

## 3. sqflite 数据库

### 3.1 SQLite 在移动端的优势

SQLite 是全球部署量最大的数据库引擎，几乎所有的手机和平板电脑都内置了 SQLite。它具有以下显著优势：

- **零配置**：不需要安装、不需要管理员、不需要服务器进程。
- **跨平台**：同一个数据库文件可以在不同平台之间复制使用。
- **轻量级**：库体积小（约 600KB），内存占用低。
- **事务支持**：完整的 ACID 事务支持，保证数据一致性。
- **SQL 标准**：支持大部分 SQL 标准语法，学习成本低。
- **可靠稳定**：经过数十年的生产环境验证，极其稳定。

`sqflite` 是 Flutter 中使用最广泛的 SQLite 插件，它为 iOS 和 Android 提供了统一的 Dart API。

```
┌─────────────────────────────────────────┐
│           Flutter App (Dart)            │
│               sqflite API               │
├────────────────┬────────────────────────┤
│     iOS        │       Android          │
│  FMDB/SQLite   │  android.database.sql  │
├────────────────┴────────────────────────┤
│           SQLite 数据库引擎              │
│         （嵌入式、单文件存储）             │
└─────────────────────────────────────────┘
```

### 3.2 安装

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3   # 用于构建数据库文件路径
```

### 3.3 打开/创建数据库

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // 单例模式，确保全局只有一个数据库实例
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// 获取数据库实例（懒加载）
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取数据库存储路径
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_app.db');

    return await openDatabase(
      path,
      version: 1,
      // 数据库首次创建时调用，用于建表
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        print('数据库表创建完成');
      },
      // 数据库版本升级时调用，用于迁移数据
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0');
        }
      },
    );
  }
}
```

### 3.4 CRUD 操作

```dart
/// 待办事项模型
class Todo {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为数据库可存储的 Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'is_completed': isCompleted ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  /// 从数据库 Map 创建对象
  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as int,
        title: map['title'] as String,
        description: map['description'] as String?,
        isCompleted: (map['is_completed'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class TodoDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 插入一条待办事项（Create）
  Future<int> insert(Todo todo) async {
    final db = await _dbHelper.database;
    // insert 返回新记录的 id
    return await db.insert('todos', todo.toMap());
  }

  /// 查询所有待办事项（Read）
  Future<List<Todo>> queryAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      orderBy: 'created_at DESC', // 按创建时间降序排列
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  /// 根据 ID 查询单条记录
  Future<Todo?> queryById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todos',
      where: 'id = ?',       // 使用占位符防止 SQL 注入
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  /// 查询未完成的待办事项
  Future<List<Todo>> queryIncomplete() async {
    final db = await _dbHelper.database;
    // 也可以使用 rawQuery 执行原始 SQL
    final maps = await db.rawQuery(
      'SELECT * FROM todos WHERE is_completed = ? ORDER BY created_at DESC',
      [0],
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  /// 更新待办事项（Update）
  Future<int> update(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// 切换完成状态
  Future<int> toggleComplete(int id, bool isCompleted) async {
    final db = await _dbHelper.database;
    return await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除一条待办事项（Delete）
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量操作（使用事务保证原子性）
  Future<void> batchInsert(List<Todo> todos) async {
    final db = await _dbHelper.database;
    // 使用事务：要么全部成功，要么全部回滚
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final todo in todos) {
        batch.insert('todos', todo.toMap());
      }
      await batch.commit(noResult: true);
    });
    print('批量插入 ${todos.length} 条记录完成');
  }

  /// 获取记录总数
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
```

### 3.5 使用示例

```dart
Future<void> sqfliteDemo() async {
  final dao = TodoDao();

  // 插入数据
  final id = await dao.insert(Todo(
    title: '学习 Flutter',
    description: '完成第四章本地存储的学习',
  ));
  print('插入成功，ID: $id');

  // 查询所有数据
  final todos = await dao.queryAll();
  for (final todo in todos) {
    print('${todo.id}: ${todo.title} - 完成: ${todo.isCompleted}');
  }

  // 更新数据
  await dao.toggleComplete(id, true);

  // 删除数据
  await dao.delete(id);
}
```

### 3.6 适用场景

sqflite 适合以下场景：

- ✅ **结构化数据存储**：具有明确表结构的业务数据
- ✅ **复杂查询**：需要 JOIN、GROUP BY、子查询等 SQL 操作
- ✅ **大数据量**：数千甚至数万条记录的高效存取
- ✅ **事务支持**：需要原子性操作保证数据一致性
- ✅ **数据关系**：表与表之间存在关联关系

---

## 4. Hive 轻量级 NoSQL

### 4.1 什么是 Hive

Hive 是一个用纯 Dart 编写的轻量级、高性能的键值对数据库。与 sqflite 不同，Hive 是一个 **NoSQL** 数据库，不需要编写 SQL 语句，也不需要定义表结构。

Hive 的核心特点：

- **纯 Dart 实现**：不依赖任何原生代码，支持所有 Flutter 平台（包括 Web）。
- **极快的读写速度**：使用内存映射文件和延迟写入策略，性能远超 SharedPreferences。
- **类型安全**：通过 TypeAdapter 支持自定义类型的直接存储。
- **加密支持**：内置 AES-256 加密功能，可以加密整个 Box。
- **无需原生依赖**：不像 sqflite 需要平台特定的 SQLite 库。

```
┌──────────────────────────────────────────┐
│              Hive 架构                    │
│                                          │
│  Box<UserInfo>    Box<Settings>    Box    │
│    (类型 Box)       (类型 Box)   (通用)   │
│        ↓               ↓           ↓     │
│  ┌─────────────────────────────────────┐ │
│  │        Hive 存储引擎（纯 Dart）       │ │
│  │   内存缓存 + 文件持久化 + 可选加密     │ │
│  └─────────────────────────────────────┘ │
│        ↓               ↓           ↓     │
│     .hive 文件      .hive 文件   .hive   │
└──────────────────────────────────────────┘
```

### 4.2 安装

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0   # Flutter 集成包，提供初始化方法

dev_dependencies:
  hive_generator: ^2.0.1  # 代码生成器（用于 TypeAdapter）
  build_runner: ^2.4.6    # 代码生成工具
```

### 4.3 初始化

```dart
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  // 初始化 Hive（Flutter 项目中使用 hive_flutter 提供的方法）
  await Hive.initFlutter();

  // 注册自定义类型适配器（如果有的话，必须在打开 Box 之前注册）
  Hive.registerAdapter(UserAdapter());

  runApp(const MyApp());
}
```

### 4.4 Box 的概念与基本操作

在 Hive 中，`Box` 是数据存储的基本单元，类似于 SQL 数据库中的"表"，但更加灵活。

```dart
/// Hive 基本操作演示
Future<void> hiveBasicDemo() async {
  // 打开一个 Box（如果不存在会自动创建）
  final box = await Hive.openBox('settings');

  // ========== 写入数据 ==========
  // 使用 put 方法存储键值对
  await box.put('username', '李四');
  await box.put('age', 28);
  await box.put('is_vip', true);

  // 也可以使用 Map 语法
  box.put('theme', 'dark');

  // 存储复杂对象（List、Map 都支持）
  await box.put('tags', ['Flutter', 'Dart', '移动开发']);
  await box.put('profile', {
    'name': '李四',
    'city': '深圳',
    'skills': ['Flutter', 'Swift', 'Kotlin'],
  });

  // ========== 读取数据 ==========
  final username = box.get('username');                   // '李四'
  final age = box.get('age');                             // 28
  final score = box.get('score', defaultValue: 0);        // 0（不存在时返回默认值）

  print('用户: $username, 年龄: $age, 积分: $score');

  // ========== 删除数据 ==========
  await box.delete('age');

  // ========== 检查与遍历 ==========
  print('Box 中共有 ${box.length} 条数据');
  print('是否包含 username: ${box.containsKey("username")}');

  // 遍历所有数据
  for (var key in box.keys) {
    print('$key: ${box.get(key)}');
  }

  // ========== 清空 Box ==========
  await box.clear();

  // 关闭 Box（通常在应用退出时调用）
  await box.close();
}
```

### 4.5 TypeAdapter：存储自定义对象

Hive 通过 TypeAdapter 支持直接存储自定义 Dart 对象，无需手动序列化。

```dart
import 'package:hive/hive.dart';

// part 指令用于代码生成
part 'user.g.dart';

/// 使用 @HiveType 注解标记需要存储的类
@HiveType(typeId: 0) // typeId 必须唯一且在 0-223 之间
class User extends HiveObject {
  @HiveField(0) // 字段编号，一旦确定不可更改
  final String name;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final String email;

  @HiveField(3, defaultValue: false) // 可以设置默认值
  final bool isActive;

  User({
    required this.name,
    required this.age,
    required this.email,
    this.isActive = false,
  });

  @override
  String toString() => 'User(name: $name, age: $age, email: $email)';
}
```

运行代码生成命令来生成 TypeAdapter：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

使用类型化 Box 存储自定义对象：

```dart
Future<void> hiveTypedBoxDemo() async {
  // 注册 Adapter（必须在打开 Box 之前）
  Hive.registerAdapter(UserAdapter());

  // 打开类型化的 Box
  final userBox = await Hive.openBox<User>('users');

  // 存储用户对象
  final user = User(name: '王五', age: 30, email: 'wangwu@example.com');
  await userBox.put('user_001', user);

  // 也可以使用自动递增的整数 key
  await userBox.add(User(name: '赵六', age: 25, email: 'zhaoliu@example.com'));

  // 读取时直接获得类型化的对象
  final User? savedUser = userBox.get('user_001');
  print('读取用户: ${savedUser?.name}, ${savedUser?.age}岁');

  // 遍历所有用户
  for (final u in userBox.values) {
    print('用户列表: ${u.name} - ${u.email}');
  }

  await userBox.close();
}
```

### 4.6 加密 Box

```dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 使用加密 Box 存储敏感数据
Future<void> encryptedBoxDemo() async {
  // 生成或获取加密密钥（实际项目中应安全存储此密钥）
  const secureStorage = FlutterSecureStorage();
  var encryptionKeyString = await secureStorage.read(key: 'hive_key');

  if (encryptionKeyString == null) {
    // 首次使用，生成新密钥
    final key = Hive.generateSecureKey();
    await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
    encryptionKeyString = base64UrlEncode(key);
  }

  final encryptionKey = base64Url.decode(encryptionKeyString);

  // 使用加密密钥打开 Box
  final encryptedBox = await Hive.openBox(
    'secrets',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  // 正常使用，数据会自动加密存储
  await encryptedBox.put('api_token', 'sk-xxxxxxxxxxxx');
  final token = encryptedBox.get('api_token');
  print('Token: $token');
}
```

### 4.7 Hive vs SharedPreferences 对比

| 对比维度 | SharedPreferences | Hive |
|----------|-------------------|------|
| **实现语言** | 平台原生 + Dart 桥接 | 纯 Dart |
| **Web 支持** | ✅ | ✅ |
| **数据类型** | 5 种基本类型 | 任意类型（含自定义对象） |
| **读写性能** | 较慢（每次都需跨平台桥接） | 极快（内存映射 + 纯 Dart） |
| **加密** | ❌ 不支持 | ✅ AES-256 |
| **适合数据量** | 少量（< 100 个键值对） | 中等（数千条记录） |
| **查询能力** | 仅按 Key 查询 | 按 Key 查询 + 值过滤 |
| **复杂度** | 极简 | 简单（需代码生成） |
| **官方维护** | Flutter 官方 | 社区维护 |

---

## 5. drift 类型安全的 SQLite 封装

### 5.1 什么是 drift

drift（原名 moor）是一个功能强大的 Flutter SQLite 封装库。它的最大特点是 **类型安全** 和 **代码生成**：你用 Dart 代码定义表结构，drift 自动生成类型安全的查询 API，在编译时就能发现 SQL 错误。

drift 的核心优势：

- **类型安全**：所有查询在编译时检查，避免运行时 SQL 错误。
- **代码生成**：自动生成数据类、DAO、查询方法，减少样板代码。
- **响应式查询**：内置 `watch` 方法，数据变化时自动通知 UI 更新。
- **数据库迁移**：提供完善的版本迁移机制。
- **多平台支持**：支持 iOS、Android、Web、桌面端。

```
┌──────────────────────────────────────────────┐
│               drift 架构                      │
│                                              │
│  Dart 表定义 → 代码生成 → 类型安全的 API       │
│       ↓                       ↓              │
│  class Todos       TodosCompanion / Todo     │
│  extends Table     自动生成的数据类            │
│       ↓                       ↓              │
│  ┌──────────────────────────────────────┐    │
│  │    drift 查询引擎（编译时类型检查）     │    │
│  └──────────────────────────────────────┘    │
│       ↓                                      │
│  ┌──────────────────────────────────────┐    │
│  │       sqflite / sqlite3 (FFI)        │    │
│  └──────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

### 5.2 安装

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0  # 提供原生 SQLite 库
  path_provider: ^2.1.1
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.14.0      # 代码生成器
  build_runner: ^2.4.6     # 代码生成工具
```

### 5.3 定义表结构与数据库

```dart
import 'package:drift/drift.dart';

// 代码生成的 part 文件
part 'app_database.g.dart';

/// 定义待办事项表（使用 Dart 类描述表结构）
class Todos extends Table {
  // 自增主键
  IntColumn get id => integer().autoIncrement()();
  // 标题（非空，长度限制）
  TextColumn get title => text().withLength(min: 1, max: 100)();
  // 描述（可空）
  TextColumn get description => text().nullable()();
  // 是否完成（默认 false）
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // 优先级（默认 0）
  IntColumn get priority => integer().withDefault(const Constant(0))();
  // 创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 定义分类表
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text().withDefault(const Constant('#FF0000'))();
}

/// 数据库定义（指定包含的表和版本号）
@DriftDatabase(tables: [Todos, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // 数据库版本号，修改表结构时需要递增
  @override
  int get schemaVersion => 1;

  // ========== 待办事项 CRUD ==========

  /// 查询所有待办事项
  Future<List<Todo>> getAllTodos() => select(todos).get();

  /// 监听所有待办事项（响应式查询，数据变化时自动更新）
  Stream<List<Todo>> watchAllTodos() {
    return (select(todos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// 根据完成状态查询
  Stream<List<Todo>> watchTodosByStatus(bool completed) {
    return (select(todos)..where((t) => t.isCompleted.equals(completed))).watch();
  }

  /// 插入待办事项
  Future<int> insertTodo(TodosCompanion entry) {
    return into(todos).insert(entry);
  }

  /// 更新待办事项
  Future<bool> updateTodo(Todo entry) {
    return update(todos).replace(entry);
  }

  /// 删除待办事项
  Future<int> deleteTodo(Todo entry) {
    return delete(todos).delete(entry);
  }

  /// 切换完成状态
  Future<void> toggleTodoStatus(int todoId) {
    return customStatement(
      'UPDATE todos SET is_completed = NOT is_completed WHERE id = ?',
      [todoId],
    );
  }

  // ========== 数据库迁移 ==========
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // 首次创建所有表
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // 版本 2 新增 priority 列
            await m.addColumn(todos, todos.priority);
          }
        },
      );
}

/// 打开数据库连接
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

运行代码生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5.4 在 Widget 中使用（响应式查询）

```dart
class TodoListPage extends StatelessWidget {
  final AppDatabase database;

  const TodoListPage({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('待办事项')),
      body: StreamBuilder<List<Todo>>(
        // 使用 watch 实现响应式：数据变化时 UI 自动更新
        stream: database.watchAllTodos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const Center(child: Text('暂无待办事项'));
          }

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo.title),
                subtitle: Text(todo.description ?? ''),
                trailing: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => database.toggleTodoStatus(todo.id),
                ),
                onLongPress: () => database.deleteTodo(todo),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          database.insertTodo(TodosCompanion.insert(
            title: '新任务 ${DateTime.now().millisecondsSinceEpoch}',
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 5.5 适用场景

drift 适合以下场景：

- ✅ **中大型项目**：需要严格的类型检查和代码规范
- ✅ **复杂数据模型**：多表关联、复杂查询
- ✅ **响应式 UI**：数据变化需要实时反映到界面
- ✅ **团队协作**：代码生成减少人为错误，提高可维护性
- ✅ **数据库迁移**：频繁的表结构变更

---

## 6. 选型对比表

### 6.1 核心维度对比

| 对比维度 | SharedPreferences | sqflite | Hive | drift |
|----------|:-:|:-:|:-:|:-:|
| **存储类型** | 键值对 | 关系型 SQL | 键值对 NoSQL | 关系型 ORM |
| **支持的数据类型** | 5 种基本类型 | SQL 标准类型 | 任意 Dart 类型 | Dart 类型映射 SQL |
| **自定义对象存储** | 需 JSON 序列化 | 需手动映射 | TypeAdapter 直接存储 | 自动代码生成 |
| **读取性能** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **写入性能** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **复杂查询** | ❌ 不支持 | ✅ 完整 SQL | ❌ 仅按 Key | ✅ 类型安全 SQL |
| **JOIN 多表查询** | ❌ | ✅ | ❌ | ✅ |
| **事务支持** | ❌ | ✅ | ✅（有限） | ✅ |
| **响应式查询** | ❌ | ❌（需手动实现） | ✅ `listenable()` | ✅ `watch()` |
| **加密支持** | ❌ | ❌（需插件） | ✅ AES-256 | ❌（需插件） |
| **Web 支持** | ✅ | ❌ | ✅ | ✅ |
| **代码生成** | 不需要 | 不需要 | 可选 | 必须 |
| **学习曲线** | ⭐ 极低 | ⭐⭐⭐ 中等 | ⭐⭐ 低 | ⭐⭐⭐⭐ 较高 |
| **维护方** | Flutter 官方 | 社区（tekartik） | 社区（isar） | 社区（simolus3） |
| **包大小影响** | 极小 | 较大（含 SQLite） | 小 | 较大（含 SQLite） |

### 6.2 场景推荐速查

| 使用场景 | 推荐方案 | 原因 |
|----------|----------|------|
| 用户偏好设置（主题、语言） | SharedPreferences | 最简单，官方维护 |
| 首次启动标志 | SharedPreferences | 单个 bool 值，无需复杂方案 |
| 少量缓存数据 | SharedPreferences 或 Hive | 数据量小用 SP，中等用 Hive |
| 用户登录 Token | flutter_secure_storage | 安全存储敏感数据 |
| 离线缓存（文章、商品列表） | Hive | 高性能读写，支持自定义对象 |
| 聊天记录 | sqflite 或 drift | 结构化数据，需要复杂查询和排序 |
| 电商订单系统 | drift | 多表关联，类型安全，响应式更新 |
| 记账/日记应用 | sqflite 或 drift | 需要按日期统计、分组等 SQL 操作 |
| 跨平台应用（含 Web） | Hive 或 drift | sqflite 不支持 Web |
| 高频读写场景 | Hive | 纯 Dart 实现，内存映射，极高性能 |

### 6.3 决策流程图

```
需要本地存储？
  │
  ├─ 仅存少量配置/标记？ ──→ SharedPreferences
  │
  ├─ 存储敏感数据？ ──→ flutter_secure_storage
  │
  ├─ 需要复杂 SQL 查询？
  │   ├─ 需要类型安全 + 代码生成？ ──→ drift
  │   └─ 手写 SQL 即可？ ──→ sqflite
  │
  ├─ 需要高性能键值存储？ ──→ Hive
  │
  ├─ 需要支持 Web？
  │   ├─ 键值存储 ──→ Hive
  │   └─ SQL 查询 ──→ drift
  │
  └─ 不确定？ ──→ 先用 SharedPreferences，不够再升级
```

---

## 7. SharedPreferences 最佳实践

### 7.1 Key 常量管理

在实际项目中，直接使用字符串作为 Key 容易出现拼写错误且难以维护。推荐将所有 Key 统一管理在一个常量类中。

```dart
/// 集中管理所有 SharedPreferences 的 Key
/// 使用 abstract final class 防止被实例化
abstract final class StorageKeys {
  // ========== 用户相关 ==========
  static const String username = 'sp_username';
  static const String userId = 'sp_user_id';
  static const String userToken = 'sp_user_token';
  static const String loginTime = 'sp_login_time';

  // ========== 应用设置 ==========
  static const String isDarkMode = 'sp_is_dark_mode';
  static const String language = 'sp_language';
  static const String fontSize = 'sp_font_size';
  static const String notificationEnabled = 'sp_notification_enabled';

  // ========== 应用状态 ==========
  static const String isFirstLaunch = 'sp_is_first_launch';
  static const String lastVersion = 'sp_last_version';
  static const String onboardingCompleted = 'sp_onboarding_completed';

  // ========== 缓存 ==========
  static const String cachedCityList = 'sp_cached_city_list';
  static const String lastSearchKeyword = 'sp_last_search_keyword';
}
```

使用方式：

```dart
// 使用常量 Key，避免拼写错误
final prefs = await SharedPreferences.getInstance();
await prefs.setBool(StorageKeys.isDarkMode, true);
final isDark = prefs.getBool(StorageKeys.isDarkMode) ?? false;
```

### 7.2 封装 StorageService

将 SharedPreferences 的操作封装为一个统一的服务类，提供更简洁、更安全的 API。

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务（单例模式）
/// 封装 SharedPreferences，提供类型安全的读写 API
class StorageService {
  // 私有构造函数
  StorageService._();

  // 单例实例
  static final StorageService _instance = StorageService._();

  /// 获取单例实例
  static StorageService get instance => _instance;

  // SharedPreferences 实例
  late final SharedPreferences _prefs;

  // 是否已初始化
  bool _initialized = false;

  /// 初始化（必须在 App 启动时调用）
  /// 通常在 main() 函数中调用
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 检查是否已初始化
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('StorageService 尚未初始化，请先调用 init() 方法');
    }
  }

  // ========== 基本类型操作 ==========

  /// 存储字符串
  Future<bool> setString(String key, String value) {
    _checkInitialized();
    return _prefs.setString(key, value);
  }

  /// 读取字符串
  String? getString(String key) {
    _checkInitialized();
    return _prefs.getString(key);
  }

  /// 存储整数
  Future<bool> setInt(String key, int value) {
    _checkInitialized();
    return _prefs.setInt(key, value);
  }

  /// 读取整数
  int? getInt(String key) {
    _checkInitialized();
    return _prefs.getInt(key);
  }

  /// 存储浮点数
  Future<bool> setDouble(String key, double value) {
    _checkInitialized();
    return _prefs.setDouble(key, value);
  }

  /// 读取浮点数
  double? getDouble(String key) {
    _checkInitialized();
    return _prefs.getDouble(key);
  }

  /// 存储布尔值
  Future<bool> setBool(String key, bool value) {
    _checkInitialized();
    return _prefs.setBool(key, value);
  }

  /// 读取布尔值
  bool? getBool(String key) {
    _checkInitialized();
    return _prefs.getBool(key);
  }

  /// 存储字符串列表
  Future<bool> setStringList(String key, List<String> value) {
    _checkInitialized();
    return _prefs.setStringList(key, value);
  }

  /// 读取字符串列表
  List<String>? getStringList(String key) {
    _checkInitialized();
    return _prefs.getStringList(key);
  }

  // ========== 高级操作 ==========

  /// 存储 JSON 对象（Map 或 List 都可以）
  Future<bool> setJson(String key, Object jsonObject) {
    _checkInitialized();
    final jsonString = jsonEncode(jsonObject);
    return _prefs.setString(key, jsonString);
  }

  /// 读取 JSON 对象
  T? getJson<T>(String key, T Function(dynamic json) fromJson) {
    _checkInitialized();
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString);
      return fromJson(decoded);
    } catch (e) {
      // JSON 解析失败时返回 null，避免崩溃
      print('StorageService: JSON 解析失败 key=$key, error=$e');
      return null;
    }
  }

  /// 带默认值的读取（泛型方法）
  T getOrDefault<T>(String key, T defaultValue) {
    _checkInitialized();
    final value = _prefs.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  /// 删除指定 key
  Future<bool> remove(String key) {
    _checkInitialized();
    return _prefs.remove(key);
  }

  /// 清空所有数据
  Future<bool> clear() {
    _checkInitialized();
    return _prefs.clear();
  }

  /// 检查 key 是否存在
  bool containsKey(String key) {
    _checkInitialized();
    return _prefs.containsKey(key);
  }

  /// 获取所有 key
  Set<String> getKeys() {
    _checkInitialized();
    return _prefs.getKeys();
  }

  // ========== 业务便捷方法 ==========

  /// 保存登录信息
  Future<void> saveLoginInfo({
    required String token,
    required String userId,
    required String username,
  }) async {
    await Future.wait([
      setString(StorageKeys.userToken, token),
      setString(StorageKeys.userId, userId),
      setString(StorageKeys.username, username),
      setString(StorageKeys.loginTime, DateTime.now().toIso8601String()),
    ]);
  }

  /// 清除登录信息
  Future<void> clearLoginInfo() async {
    await Future.wait([
      remove(StorageKeys.userToken),
      remove(StorageKeys.userId),
      remove(StorageKeys.username),
      remove(StorageKeys.loginTime),
    ]);
  }

  /// 检查是否已登录
  bool get isLoggedIn => containsKey(StorageKeys.userToken);

  /// 获取当前 Token
  String? get token => getString(StorageKeys.userToken);

  /// 是否首次启动
  bool get isFirstLaunch => getBool(StorageKeys.isFirstLaunch) ?? true;

  /// 标记已完成首次启动
  Future<void> markFirstLaunchDone() async {
    await setBool(StorageKeys.isFirstLaunch, false);
  }
}
```

在 `main.dart` 中初始化并使用：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 在 App 启动时初始化存储服务
  await StorageService.instance.init();

  runApp(const MyApp());
}

// 在任意位置使用
class SomePage extends StatelessWidget {
  const SomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;

    // 直接使用封装好的便捷方法
    if (storage.isFirstLaunch) {
      // 显示引导页
    }

    final username = storage.getString(StorageKeys.username) ?? '游客';
    return Text('欢迎, $username');
  }
}
```

### 7.3 数据迁移

当应用版本更新后，本地存储的数据结构可能需要迁移。以下是一个简单的迁移方案：

```dart
/// 数据迁移管理器
class DataMigration {
  final StorageService _storage = StorageService.instance;

  /// 当前数据版本
  static const int currentDataVersion = 3;

  /// 执行数据迁移
  Future<void> migrate() async {
    // 获取上一次存储的数据版本
    final int storedVersion = _storage.getInt('data_version') ?? 0;

    if (storedVersion >= currentDataVersion) {
      print('数据已是最新版本 v$storedVersion，无需迁移');
      return;
    }

    print('开始数据迁移: v$storedVersion → v$currentDataVersion');

    // 按版本号逐步迁移（确保每个版本的迁移逻辑都执行到）
    if (storedVersion < 1) {
      await _migrateToV1();
    }
    if (storedVersion < 2) {
      await _migrateToV2();
    }
    if (storedVersion < 3) {
      await _migrateToV3();
    }

    // 更新数据版本号
    await _storage.setInt('data_version', currentDataVersion);
    print('数据迁移完成，当前版本: v$currentDataVersion');
  }

  /// v0 → v1：统一 Key 命名规范
  Future<void> _migrateToV1() async {
    print('执行 v1 迁移：统一 Key 命名规范');

    // 旧 Key → 新 Key 的映射
    final migrations = {
      'darkMode': StorageKeys.isDarkMode,       // 旧命名 → 新命名
      'user_name': StorageKeys.username,
      'token': StorageKeys.userToken,
    };

    for (final entry in migrations.entries) {
      if (_storage.containsKey(entry.key)) {
        // 读取旧值
        final oldValue = _storage.getString(entry.key);
        if (oldValue != null) {
          // 写入新 Key
          await _storage.setString(entry.value, oldValue);
        }
        // 删除旧 Key
        await _storage.remove(entry.key);
        print('  迁移: ${entry.key} → ${entry.value}');
      }
    }
  }

  /// v1 → v2：将旧的 theme 字符串转换为 isDarkMode 布尔值
  Future<void> _migrateToV2() async {
    print('执行 v2 迁移：主题数据格式转换');
    final theme = _storage.getString('sp_theme');
    if (theme != null) {
      final isDark = theme == 'dark';
      await _storage.setBool(StorageKeys.isDarkMode, isDark);
      await _storage.remove('sp_theme');
      print('  主题 "$theme" → isDarkMode: $isDark');
    }
  }

  /// v2 → v3：清理过期的缓存数据
  Future<void> _migrateToV3() async {
    print('执行 v3 迁移：清理过期缓存');

    // 删除已废弃的 Key
    final deprecatedKeys = [
      'sp_old_cache_1',
      'sp_old_cache_2',
      'sp_deprecated_setting',
    ];

    for (final key in deprecatedKeys) {
      if (_storage.containsKey(key)) {
        await _storage.remove(key);
        print('  清理废弃 Key: $key');
      }
    }
  }
}
```

在应用启动时执行迁移：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化存储服务
  await StorageService.instance.init();

  // 2. 执行数据迁移
  await DataMigration().migrate();

  // 3. 启动应用
  runApp(const MyApp());
}
```

---

## 8. 本章小结

本章系统地介绍了 Flutter 中四种主流的本地存储方案：

### 核心知识点回顾

1. **SharedPreferences**：最简单的键值对存储方案，适合保存用户偏好设置和简单的应用状态。底层依赖平台原生实现（iOS 的 NSUserDefaults 和 Android 的 SharedPreferences），支持 5 种基本数据类型。

2. **sqflite**：基于 SQLite 的关系型数据库方案，适合存储结构化的业务数据。支持完整的 SQL 语法、事务和复杂查询，但需要手动编写 SQL 和数据映射代码。

3. **Hive**：纯 Dart 实现的高性能 NoSQL 数据库，读写速度极快。通过 TypeAdapter 支持自定义类型的直接存储，还内置了 AES-256 加密功能，非常适合需要高性能读写的缓存场景。

4. **drift**：类型安全的 SQLite ORM 框架，通过代码生成提供编译时类型检查和响应式查询能力。适合中大型项目中复杂的数据库操作需求。

### 选型建议

- **刚接触 Flutter**：从 SharedPreferences 开始，满足大部分简单需求。
- **需要存储结构化数据**：使用 sqflite（手写 SQL）或 drift（类型安全 ORM）。
- **追求极致性能**：选择 Hive，尤其是在高频读写场景。
- **大型团队项目**：推荐 drift，代码生成减少人为错误，类型安全提升可维护性。
- **需要 Web 支持**：排除 sqflite，从 Hive 和 drift 中选择。

### 最佳实践要点

- 将 SharedPreferences 的 Key 统一管理在常量类中，避免硬编码字符串。
- 封装 StorageService 提供统一的存储 API，简化业务层调用。
- 制定数据迁移策略，确保应用升级时本地数据平滑过渡。
- 敏感数据（密码、密钥）永远不要使用 SharedPreferences，应使用 `flutter_secure_storage`。
- 所有存储操作都是异步的，务必正确处理 `Future` 和 `async/await`。

> 📖 下一章我们将学习 Flutter 的状态管理方案，了解如何在应用中高效地管理和传递状态。
