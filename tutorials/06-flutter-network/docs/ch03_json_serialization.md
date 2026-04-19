# 第3章：JSON 序列化与数据模型

> 📁 本章配套代码：`lib/ch03_json_serialization.dart`
>
> ⚠️ 本章示例代码全部使用**手写序列化**方式，不依赖 `build_runner` 或任何代码生成工具。

---

## 目录

1. [JSON 序列化概述](#1-json-序列化概述)
2. [手写 fromJson / toJson 详解](#2-手写-fromjson--tojson-详解)
3. [嵌套对象序列化](#3-嵌套对象序列化)
4. [List 序列化](#4-list-序列化)
5. [json_serializable + build_runner](#5-json_serializable--build_runner)
6. [freezed 不可变数据模型](#6-freezed-不可变数据模型)
7. [泛型响应包装 ApiResponse\<T\>](#7-泛型响应包装-apiresponset)
8. [最佳实践](#8-最佳实践)
9. [本章小结](#9-本章小结)

---

## 1. JSON 序列化概述

### 1.1 为什么需要 JSON 序列化？

在 Flutter 开发中，我们几乎无法避免与后端 API 打交道。后端返回的数据绝大多数是 **JSON 格式**的字符串，而 Dart 是强类型语言，直接操作 `Map<String, dynamic>` 既不安全也不方便。

**不使用模型类的痛点：**

```dart
// ❌ 直接使用 Map，容易出错
final json = {'id': 1, 'name': '张三', 'email': 'zhangsan@example.com'};

// 拼写错误不会在编译期报错，运行时才会发现
final name = json['nmae']; // 拼错了！返回 null，不会报错
final id = json['id'] as String; // 类型转换错误！id 是 int，运行时崩溃
```

**使用模型类的好处：**

```dart
// ✅ 使用模型类，编译期就能发现错误
final user = User.fromJson(json);
print(user.name);  // 有代码补全，不会拼错
print(user.id);    // 类型安全，id 一定是 int
```

总结来说，JSON 序列化（将 JSON 转为 Dart 对象）和反序列化（将 Dart 对象转为 JSON）的核心目标是：

| 目标 | 说明 |
|------|------|
| **类型安全** | 编译期检查，避免运行时类型错误 |
| **代码补全** | IDE 自动提示字段名，减少拼写错误 |
| **可维护性** | 字段变更只需修改模型类一处 |
| **可读性** | 代码意图清晰，一眼看出数据结构 |

### 1.2 dart:convert 基础

Dart 内置的 `dart:convert` 库提供了 JSON 编解码能力：

```dart
import 'dart:convert';

void main() {
  // === JSON 字符串 → Dart 对象 ===
  final jsonString = '{"id": 1, "name": "张三", "email": "zhangsan@example.com"}';

  // jsonDecode 将 JSON 字符串解析为 Map<String, dynamic>
  final Map<String, dynamic> map = jsonDecode(jsonString);
  print(map['name']); // 输出：张三
  print(map.runtimeType); // 输出：_Map<String, dynamic>

  // === Dart 对象 → JSON 字符串 ===
  final data = {
    'id': 1,
    'name': '李四',
    'scores': [90, 85, 92],
  };

  // jsonEncode 将 Map/List 转为 JSON 字符串
  final encoded = jsonEncode(data);
  print(encoded); // 输出：{"id":1,"name":"李四","scores":[90,85,92]}

  // === 解析 JSON 数组 ===
  final listString = '[{"id": 1}, {"id": 2}]';
  final List<dynamic> list = jsonDecode(listString);
  print(list.length); // 输出：2
}
```

**关键函数说明：**

| 函数 | 输入 | 输出 | 用途 |
|------|------|------|------|
| `jsonDecode()` | `String` | `dynamic`（通常是 `Map` 或 `List`） | 解析 JSON 字符串 |
| `jsonEncode()` | `Object?` | `String` | 将对象编码为 JSON 字符串 |

> 💡 `jsonDecode` 返回的类型是 `dynamic`。如果 JSON 顶层是对象 `{}`，返回 `Map<String, dynamic>`；如果顶层是数组 `[]`，返回 `List<dynamic>`。

---

## 2. 手写 fromJson / toJson 详解

### 2.1 简单模型：User

这是最基础也是最常用的模式。我们为一个简单的 `User` 类手写序列化代码：

```dart
/// 用户模型
class User {
  final int id;
  final String name;
  final String email;

  // 普通构造函数
  User({
    required this.id,
    required this.name,
    required this.email,
  });

  /// 工厂构造函数：从 JSON Map 创建 User 对象
  /// 这是 Dart 社区约定俗成的命名方式
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,          // 明确类型转换
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  /// 将 User 对象转为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
```

**使用示例：**

```dart
import 'dart:convert';

void main() {
  // 模拟从 API 获取的 JSON 字符串
  final jsonString = '{"id": 1, "name": "张三", "email": "zhangsan@example.com"}';

  // 第一步：JSON 字符串 → Map
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

  // 第二步：Map → User 对象
  final user = User.fromJson(jsonMap);
  print(user.name);  // 输出：张三
  print(user.email); // 输出：zhangsan@example.com

  // 反向操作：User 对象 → Map → JSON 字符串
  final map = user.toJson();
  final backToString = jsonEncode(map);
  print(backToString); // 输出：{"id":1,"name":"张三","email":"zhangsan@example.com"}
}
```

### 2.2 为什么用工厂构造函数（factory）？

你可能会问：为什么 `fromJson` 用 `factory` 而不是普通的命名构造函数？

```dart
// 方式一：工厂构造函数（推荐）
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

// 方式二：普通命名构造函数（也可以，但灵活性较低）
User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      name = json['name'] as String,
      email = json['email'] as String;
```

**工厂构造函数的优势：**

- 可以包含逻辑判断（例如根据类型返回不同子类）
- 可以返回缓存的实例
- 可以返回 `null`（如果返回类型是 `User?`）
- 代码生成工具（如 `json_serializable`）也采用这种模式

### 2.3 注意事项：类型安全

后端返回的 JSON 数据类型可能和你预期的不一致，需要特别小心：

```dart
/// 类型安全的 fromJson 写法
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    // 后端可能返回 int 或 String 类型的 id
    // 安全做法：兼容两种类型
    id: json['id'] is String
        ? int.parse(json['id'] as String)
        : json['id'] as int,

    name: json['name'] as String,
    email: json['email'] as String,
  );
}
```

**常见的类型陷阱：**

```dart
// ⚠️ 后端返回的数字可能是 int 也可能是 double
// JSON: {"price": 9.9}  → Dart 中是 double
// JSON: {"price": 10}   → Dart 中是 int（不是 double！）
// 安全做法：
final price = (json['price'] as num).toDouble();

// ⚠️ 后端返回的 id 可能是字符串
// JSON: {"id": "123"}
// 安全做法：
final id = json['id'] is String
    ? int.parse(json['id'] as String)
    : json['id'] as int;

// ⚠️ bool 值可能以 int 形式传递
// JSON: {"is_active": 1}
final isActive = json['is_active'] == 1 || json['is_active'] == true;
```

### 2.4 注意事项：null 处理

后端返回的字段可能为 `null` 或者缺失，需要正确处理：

```dart
/// 包含可选字段的用户模型
class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;     // 头像，可能为 null
  final String? bio;        // 个人简介，可能为 null
  final int followerCount;  // 粉丝数，缺失时默认为 0

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
    this.followerCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // 可选字段：使用 as String? 允许 null
      avatar: json['avatar'] as String?,
      // 可选字段：字段可能完全不存在
      bio: json['bio'] as String?,
      // 带默认值的字段：字段缺失时给默认值
      followerCount: json['follower_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      // 可选字段也要写入，值为 null 时 JSON 中会是 null
      'avatar': avatar,
      'bio': bio,
      'follower_count': followerCount,
    };
  }
}
```

**处理 null 的几种方式：**

```dart
// 方式一：直接转换为可空类型
final avatar = json['avatar'] as String?;

// 方式二：提供默认值
final count = json['count'] as int? ?? 0;
final name = json['name'] as String? ?? '未知用户';

// 方式三：字段缺失检查
final bio = json.containsKey('bio') ? json['bio'] as String? : null;

// 方式四：条件解析（字段存在才解析）
final address = json['address'] != null
    ? Address.fromJson(json['address'] as Map<String, dynamic>)
    : null;
```

---

## 3. 嵌套对象序列化

实际开发中，模型之间经常存在嵌套关系。例如一个用户可能包含地址信息：

### 3.1 定义嵌套模型

```dart
/// 地址模型
class Address {
  final String street;   // 街道
  final String city;     // 城市
  final String province; // 省份
  final String zipCode;  // 邮编

  Address({
    required this.street,
    required this.city,
    required this.province,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      zipCode: json['zip_code'] as String, // 注意：JSON 字段名用下划线
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'province': province,
      'zip_code': zipCode, // 保持与后端一致的字段名
    };
  }

  @override
  String toString() => '$province $city $street ($zipCode)';
}

/// 包含地址的用户模型
class UserWithAddress {
  final int id;
  final String name;
  final String email;
  final Address? address; // 地址是可选的，用户可能没有填写地址

  UserWithAddress({
    required this.id,
    required this.name,
    required this.email,
    this.address,
  });

  factory UserWithAddress.fromJson(Map<String, dynamic> json) {
    return UserWithAddress(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // 嵌套对象：先判断是否为 null，再递归调用 fromJson
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      // 嵌套对象：调用其 toJson 方法，null 则输出 null
      'address': address?.toJson(),
    };
  }
}
```

### 3.2 使用示例

```dart
void main() {
  // 模拟后端返回的 JSON（包含嵌套的 address 对象）
  final jsonString = '''
  {
    "id": 1,
    "name": "张三",
    "email": "zhangsan@example.com",
    "address": {
      "street": "中关村大街1号",
      "city": "北京",
      "province": "北京市",
      "zip_code": "100080"
    }
  }
  ''';

  final user = UserWithAddress.fromJson(jsonDecode(jsonString));
  print(user.name);              // 输出：张三
  print(user.address?.city);     // 输出：北京
  print(user.address);           // 输出：北京市 北京 中关村大街1号 (100080)

  // 没有地址的用户
  final jsonWithoutAddress = '{"id": 2, "name": "李四", "email": "lisi@example.com"}';
  final user2 = UserWithAddress.fromJson(jsonDecode(jsonWithoutAddress));
  print(user2.address); // 输出：null
}
```

### 3.3 多层嵌套

如果嵌套层级更深，原理一样——每一层都实现自己的 `fromJson` / `toJson`：

```dart
/// 公司模型（包含地址）
class Company {
  final String name;
  final Address address;

  Company({required this.name, required this.address});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address.toJson(),
    };
  }
}

/// 员工模型（包含公司，公司又包含地址）
class Employee {
  final int id;
  final String name;
  final Company company;

  Employee({required this.id, required this.name, required this.company});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      // 每层嵌套各自处理自己的 fromJson
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company.toJson(),
    };
  }
}
```

---

## 4. List 序列化

### 4.1 基本 List 序列化：List\<Post\>

后端常常返回数组数据，比如文章列表：

```dart
/// 文章模型
class Post {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      // DateTime 的处理：后端通常返回 ISO 8601 格式的字符串
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      // DateTime 转回 ISO 8601 字符串
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Post(id: $id, title: $title, author: $author)';
}
```

**解析 JSON 数组：**

```dart
void main() {
  // 模拟后端返回的文章列表
  final jsonString = '''
  [
    {
      "id": 1,
      "title": "Flutter 入门指南",
      "content": "Flutter 是 Google 推出的跨平台框架...",
      "author": "张三",
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "title": "Dart 语言精要",
      "content": "Dart 是一门面向对象的编程语言...",
      "author": "李四",
      "created_at": "2024-01-16T14:20:00Z"
    }
  ]
  ''';

  // 解析 JSON 数组 → List<Post>
  final List<dynamic> jsonList = jsonDecode(jsonString);

  // 方式一：使用 map + toList（最常用）
  final List<Post> posts = jsonList
      .map((json) => Post.fromJson(json as Map<String, dynamic>))
      .toList();

  // 方式二：使用 for 循环
  final List<Post> posts2 = [
    for (final json in jsonList)
      Post.fromJson(json as Map<String, dynamic>),
  ];

  print(posts.length); // 输出：2
  for (final post in posts) {
    print('${post.title} - ${post.author}');
  }
  // 输出：
  // Flutter 入门指南 - 张三
  // Dart 语言精要 - 李四

  // 反向操作：List<Post> → JSON 字符串
  final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
  print(encoded);
}
```

### 4.2 对象中包含 List 字段

更常见的情况是，一个对象的某个字段是 List：

```dart
/// 包含文章列表的用户模型
class UserWithPosts {
  final int id;
  final String name;
  final List<Post> posts;     // 用户发布的文章列表
  final List<String> tags;    // 用户标签（简单类型的 List）

  UserWithPosts({
    required this.id,
    required this.name,
    required this.posts,
    required this.tags,
  });

  factory UserWithPosts.fromJson(Map<String, dynamic> json) {
    return UserWithPosts(
      id: json['id'] as int,
      name: json['name'] as String,
      // 解析对象数组：先转为 List<dynamic>，再 map 为具体类型
      posts: (json['posts'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      // 解析简单类型数组：直接 cast
      tags: (json['tags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      // 或者简写为：
      // tags: List<String>.from(json['tags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // 对象数组：每个元素调用 toJson
      'posts': posts.map((p) => p.toJson()).toList(),
      // 简单类型数组：直接放入
      'tags': tags,
    };
  }
}
```

**使用示例：**

```dart
void main() {
  final jsonString = '''
  {
    "id": 1,
    "name": "张三",
    "posts": [
      {
        "id": 101,
        "title": "我的第一篇文章",
        "content": "大家好...",
        "author": "张三",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "tags": ["Flutter", "Dart", "移动开发"]
  }
  ''';

  final user = UserWithPosts.fromJson(jsonDecode(jsonString));
  print(user.name);              // 输出：张三
  print(user.posts.length);      // 输出：1
  print(user.posts[0].title);    // 输出：我的第一篇文章
  print(user.tags);              // 输出：[Flutter, Dart, 移动开发]
}
```

### 4.3 处理空 List 和 null List

```dart
factory UserWithPosts.fromJson(Map<String, dynamic> json) {
  return UserWithPosts(
    id: json['id'] as int,
    name: json['name'] as String,
    // 安全处理：字段可能为 null 或缺失，给空列表默认值
    posts: json['posts'] != null
        ? (json['posts'] as List<dynamic>)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList()
        : [],   // 缺失或 null 时返回空列表
    tags: json['tags'] != null
        ? List<String>.from(json['tags'] as List)
        : [],
  );
}
```

---

## 5. json_serializable + build_runner

> ⚠️ 本节仅做**原理讲解**，帮助你理解这套方案的工作机制。本章配套代码不使用代码生成。

当项目中模型类很多时，手写 `fromJson` / `toJson` 会变得繁琐且容易出错。`json_serializable` 包可以自动生成这些代码。

### 5.1 工作原理概览

```
你写的代码            →    代码生成器           →    生成的代码
user.dart                  build_runner              user.g.dart
（包含注解和字段声明）     （读取注解，分析字段）     （包含 fromJson/toJson 实现）
```

**整体流程：**

1. 你在模型类上添加 `@JsonSerializable()` 注解
2. 你声明字段和构造函数，但**不写** `fromJson` / `toJson` 的具体实现
3. 运行 `build_runner`，它会读取你的代码，自动生成 `.g.dart` 文件
4. 生成的文件中包含 `_$UserFromJson()` 和 `_$UserToJson()` 两个函数
5. 你的代码通过 `part` 指令引入生成的文件

### 5.2 使用步骤详解

**第一步：添加依赖**

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1   # 提供注解

dev_dependencies:
  json_serializable: ^6.7.1  # 代码生成器
  build_runner: ^2.4.6        # 构建工具
```

**第二步：编写模型类**

```dart
// 文件：lib/models/user.dart

import 'package:json_annotation/json_annotation.dart';

// 这一行引入生成的代码文件
// 文件名规则：原文件名去掉 .dart 后缀，加上 .g.dart
part 'user.g.dart';

// @JsonSerializable() 注解告诉代码生成器：这个类需要生成序列化代码
@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  // 工厂构造函数：调用生成的 _$UserFromJson 函数
  // _$ 前缀 + 类名 + FromJson 是固定命名规则
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // toJson 方法：调用生成的 _$UserToJson 函数
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**第三步：运行代码生成**

```bash
# 一次性生成
flutter pub run build_runner build

# 监听模式：文件变化时自动重新生成
flutter pub run build_runner watch

# 如果遇到冲突，先清除再生成
flutter pub run build_runner build --delete-conflicting-outputs
```

**第四步：查看生成的代码**

```dart
// 自动生成的文件：lib/models/user.g.dart
// 不要手动修改这个文件！

part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };
```

> 💡 看到了吗？生成的代码和我们手写的几乎一模一样！`json_serializable` 本质上就是自动帮你写手写代码。

### 5.3 @JsonKey 自定义字段名

后端的字段命名风格（通常是 `snake_case`）和 Dart 的命名风格（`camelCase`）不同，用 `@JsonKey` 可以做映射：

```dart
@JsonSerializable()
class User {
  final int id;

  // @JsonKey 指定 JSON 中的字段名
  @JsonKey(name: 'user_name')
  final String userName;

  // 指定默认值
  @JsonKey(defaultValue: 0)
  final int followerCount;

  // 忽略字段：序列化和反序列化时都忽略
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localCache;

  // JSON 字段名和 Dart 字段名相同时，不需要 @JsonKey
  final String email;

  User({
    required this.id,
    required this.userName,
    this.followerCount = 0,
    this.localCache,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

**也可以全局配置命名策略：**

```dart
// fieldRename: FieldRename.snake 会自动将所有 camelCase 字段名转为 snake_case
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String userName;      // 自动映射为 "user_name"
  final int followerCount;    // 自动映射为 "follower_count"

  // ...
}
```

### 5.4 代码生成原理

`build_runner` 的工作原理：

```
┌──────────────────────────────────────────────────────────┐
│                    build_runner 执行流程                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. 扫描项目中的所有 .dart 文件                             │
│                      ↓                                    │
│  2. 找到带有 @JsonSerializable() 注解的类                   │
│                      ↓                                    │
│  3. 使用 Dart 分析器（analyzer）解析类的结构                 │
│     - 读取所有字段名、类型                                  │
│     - 读取 @JsonKey 注解的配置                              │
│     - 分析构造函数参数                                      │
│                      ↓                                    │
│  4. 根据分析结果，生成 fromJson / toJson 代码               │
│                      ↓                                    │
│  5. 将生成的代码写入 .g.dart 文件                           │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**核心概念：**

- **Source Generation（源代码生成）**：在编译前生成代码，不影响运行时性能
- **part / part of**：Dart 的文件拆分机制，让生成的代码和你的代码属于同一个库
- **注解驱动**：通过注解标记哪些类需要生成代码

### 5.5 何时使用 json_serializable？

| 场景 | 推荐方案 |
|------|----------|
| 模型类 < 5 个 | 手写 fromJson / toJson |
| 模型类 5~20 个 | 可以考虑 json_serializable |
| 模型类 > 20 个 | 强烈推荐 json_serializable |
| 字段经常变化 | 推荐 json_serializable（修改字段后重新生成即可） |
| 团队项目 | 推荐 json_serializable（风格统一） |
| 学习/原型 | 手写（理解原理更重要） |

---

## 6. freezed 不可变数据模型

> ⚠️ 本节仅做**原理讲解**，帮助你了解 `freezed` 的设计理念和使用场景。

### 6.1 什么是 freezed？

`freezed` 是 Dart 社区非常流行的代码生成包，由 Remi Rousselet（也是 Riverpod 的作者）开发。它的核心理念是：**让数据类（Data Class）的创建变得简单，同时保证数据不可变性**。

**freezed 自动生成的功能：**

- `fromJson` / `toJson`（序列化）
- `copyWith`（创建修改后的副本）
- `==` 和 `hashCode`（值相等比较）
- `toString`（可读的字符串表示）
- 联合类型 / 密封类（Union types / Sealed classes）

### 6.2 基本用法

```dart
// 文件：lib/models/user.dart

import 'package:freezed_annotation/freezed_annotation.dart';

// freezed 会生成两个文件
part 'user.freezed.dart';   // 包含 copyWith、==、toString 等
part 'user.g.dart';          // 包含 fromJson / toJson（需要同时依赖 json_serializable）

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    String? avatar,           // 可选字段
    @Default(0) int followerCount, // 带默认值的字段
  }) = _User;

  // fromJson 的声明（实现由代码生成器自动生成）
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

> 💡 注意 `freezed` 的语法和普通类很不一样：使用 `const factory` 构造函数，并且通过 `= _User` 重定向到生成的私有类。

### 6.3 copyWith：创建修改后的副本

由于 `freezed` 创建的对象是不可变的（所有字段都是 `final`），如果你想修改某个字段，需要创建一个新对象。`copyWith` 让这变得很方便：

```dart
void main() {
  final user = User(id: 1, name: '张三', email: 'zhangsan@example.com');

  // 使用 copyWith 创建新对象，只修改 name 字段
  final updatedUser = user.copyWith(name: '李四');

  print(user.name);        // 输出：张三（原对象不变）
  print(updatedUser.name); // 输出：李四（新对象）

  // copyWith 可以同时修改多个字段
  final anotherUser = user.copyWith(
    name: '王五',
    email: 'wangwu@example.com',
    followerCount: 100,
  );
}
```

**为什么不可变性很重要？**

```dart
// ❌ 可变对象的隐患
class MutableUser {
  String name;
  MutableUser(this.name);
}

final user = MutableUser('张三');
final list = [user];
user.name = '李四';          // 修改了原对象
print(list[0].name);         // 输出：李四 —— list 中的数据也被意外修改了！

// ✅ 不可变对象是安全的
final user2 = User(id: 1, name: '张三', email: 'test@test.com');
final list2 = [user2];
final user3 = user2.copyWith(name: '李四'); // 创建新对象
print(list2[0].name);        // 输出：张三 —— list 中的数据不受影响
```

### 6.4 == 操作符：值相等

`freezed` 自动生成基于所有字段的 `==` 和 `hashCode`：

```dart
void main() {
  final user1 = User(id: 1, name: '张三', email: 'zhangsan@example.com');
  final user2 = User(id: 1, name: '张三', email: 'zhangsan@example.com');

  // 普通类：比较的是引用（内存地址），两个不同的对象不相等
  // freezed 类：比较的是值（所有字段），字段相同就相等
  print(user1 == user2);   // 输出：true（如果是普通类，会输出 false）

  // 这对于状态管理非常有用
  // 例如在 Riverpod/Bloc 中，只有状态真正改变了才会触发 UI 重建
}
```

### 6.5 联合类型（Union Types / Sealed Classes）

这是 `freezed` 最强大的特性之一。联合类型让一个类可以有多种"形态"，非常适合表示有限的状态集合：

```dart
@freezed
class AuthState with _$AuthState {
  /// 未认证状态
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// 登录中状态
  const factory AuthState.loading() = AuthLoading;

  /// 已认证状态（携带用户信息）
  const factory AuthState.authenticated({
    required User user,
    required String token,
  }) = Authenticated;

  /// 认证失败状态（携带错误信息）
  const factory AuthState.error({
    required String message,
  }) = AuthError;
}
```

**使用联合类型进行模式匹配：**

```dart
// 在 Widget 中根据状态显示不同的 UI
Widget buildAuthUI(AuthState state) {
  // 使用 when 进行穷举匹配（必须处理所有情况）
  return state.when(
    unauthenticated: () => LoginPage(),
    loading: () => CircularProgressIndicator(),
    authenticated: (user, token) => HomePage(user: user),
    error: (message) => ErrorPage(message: message),
  );
}

// 也可以使用 maybeWhen（只处理部分情况）
String getStatusText(AuthState state) {
  return state.maybeWhen(
    authenticated: (user, token) => '欢迎回来，${user.name}！',
    orElse: () => '请先登录',
  );
}

// 还可以使用 map / maybeMap 获取具体类型
void handleState(AuthState state) {
  state.map(
    unauthenticated: (_) => print('未登录'),
    loading: (_) => print('加载中...'),
    authenticated: (s) => print('已登录：${s.user.name}'),
    error: (s) => print('错误：${s.message}'),
  );
}
```

> 💡 **Dart 3.0+ 原生密封类：** Dart 3.0 引入了 `sealed class` 关键字，可以在不使用 `freezed` 的情况下实现类似的联合类型和穷举匹配。但 `freezed` 额外提供了 `copyWith`、`==`、`toJson` 等功能。

### 6.6 何时使用 freezed？

| 场景 | 推荐方案 |
|------|----------|
| 简单的 API 数据模型 | `json_serializable` 或手写即可 |
| 需要 `copyWith` | 使用 `freezed` |
| 需要值相等（`==`） | 使用 `freezed` 或手动覆写 |
| 状态管理（Bloc/Riverpod） | 强烈推荐 `freezed` |
| 有多种状态/类型（联合类型） | 强烈推荐 `freezed` |
| 追求不可变性 | 推荐 `freezed` |

---

## 7. 泛型响应包装 ApiResponse\<T\>

### 7.1 后端统一响应格式

大多数后端 API 会采用统一的响应格式，例如：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "name": "张三",
    "email": "zhangsan@example.com"
  }
}
```

```json
{
  "code": 200,
  "message": "success",
  "data": [
    {"id": 1, "title": "文章一"},
    {"id": 2, "title": "文章二"}
  ]
}
```

```json
{
  "code": 401,
  "message": "token 已过期，请重新登录",
  "data": null
}
```

不管返回什么数据，外层结构总是 `{code, message, data}`，只是 `data` 的类型不同。这种情况非常适合用**泛型**来处理。

### 7.2 定义泛型响应类

```dart
/// 通用 API 响应包装类
/// T 是 data 字段的类型，可以是任意类型
class ApiResponse<T> {
  final int code;        // 业务状态码
  final String message;  // 提示信息
  final T? data;         // 响应数据，类型由泛型 T 决定

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// 判断请求是否成功
  bool get isSuccess => code == 200;

  /// 从 JSON 创建 ApiResponse
  /// [fromJsonT] 是一个函数参数，用于告诉 ApiResponse 如何解析 data 字段
  /// 因为 ApiResponse 不知道 T 的具体类型，所以需要外部传入解析函数
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      // data 可能为 null（比如错误响应）
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value)? toJsonT) {
    return {
      'code': code,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
    };
  }

  @override
  String toString() =>
      'ApiResponse(code: $code, message: $message, data: $data)';
}
```

### 7.3 使用示例

```dart
import 'dart:convert';

void main() {
  // === 示例 1：data 是单个 User 对象 ===
  final userResponseJson = '''
  {
    "code": 200,
    "message": "success",
    "data": {"id": 1, "name": "张三", "email": "zhangsan@example.com"}
  }
  ''';

  final userResponse = ApiResponse<User>.fromJson(
    jsonDecode(userResponseJson),
    // 传入 User 的解析函数
    (json) => User.fromJson(json as Map<String, dynamic>),
  );

  if (userResponse.isSuccess) {
    print('用户名：${userResponse.data?.name}'); // 输出：用户名：张三
  }

  // === 示例 2：data 是 List<Post> ===
  final postsResponseJson = '''
  {
    "code": 200,
    "message": "success",
    "data": [
      {"id": 1, "title": "文章一", "content": "内容一", "author": "张三", "created_at": "2024-01-15T10:30:00Z"},
      {"id": 2, "title": "文章二", "content": "内容二", "author": "李四", "created_at": "2024-01-16T14:20:00Z"}
    ]
  }
  ''';

  final postsResponse = ApiResponse<List<Post>>.fromJson(
    jsonDecode(postsResponseJson),
    // 解析函数：将 dynamic（实际上是 List）转为 List<Post>
    (json) => (json as List<dynamic>)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  if (postsResponse.isSuccess) {
    final posts = postsResponse.data!;
    print('共 ${posts.length} 篇文章'); // 输出：共 2 篇文章
    for (final post in posts) {
      print('  - ${post.title}');
    }
  }

  // === 示例 3：请求失败 ===
  final errorResponseJson = '''
  {
    "code": 401,
    "message": "token 已过期，请重新登录",
    "data": null
  }
  ''';

  final errorResponse = ApiResponse<User>.fromJson(
    jsonDecode(errorResponseJson),
    (json) => User.fromJson(json as Map<String, dynamic>),
  );

  if (!errorResponse.isSuccess) {
    print('请求失败：${errorResponse.message}');
    // 输出：请求失败：token 已过期，请重新登录
  }
}
```

### 7.4 封装分页响应

后端分页数据通常长这样：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "page_size": 20
  }
}
```

我们可以再定义一个分页包装类：

```dart
/// 分页数据包装类
class PaginatedData<T> {
  final List<T> items;   // 当前页的数据列表
  final int total;       // 总数据条数
  final int page;        // 当前页码
  final int pageSize;    // 每页条数

  PaginatedData({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  /// 是否还有更多数据
  bool get hasMore => page * pageSize < total;

  /// 总页数
  int get totalPages => (total / pageSize).ceil();

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedData(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }
}

// 使用方式：
// final response = ApiResponse<PaginatedData<Post>>.fromJson(
//   jsonDecode(responseString),
//   (json) => PaginatedData.fromJson(
//     json as Map<String, dynamic>,
//     (item) => Post.fromJson(item),
//   ),
// );
//
// final posts = response.data!.items;      // List<Post>
// final hasMore = response.data!.hasMore;  // 是否有下一页
```

### 7.5 配合 HTTP 客户端使用

在实际项目中，我们通常会封装一个网络请求方法，自动处理响应解析：

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 封装网络请求，自动解析 ApiResponse
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// 发送 GET 请求，返回 ApiResponse<T>
  Future<ApiResponse<T>> get<T>(
    String path, {
    required T Function(dynamic json) fromJsonT,
    Map<String, String>? headers,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResponse.fromJson(jsonMap, fromJsonT);
  }
}

// 使用示例：
// final client = ApiClient(baseUrl: 'https://api.example.com');
//
// // 获取单个用户
// final userResponse = await client.get<User>(
//   '/users/1',
//   fromJsonT: (json) => User.fromJson(json as Map<String, dynamic>),
// );
//
// // 获取文章列表
// final postsResponse = await client.get<List<Post>>(
//   '/posts',
//   fromJsonT: (json) => (json as List)
//       .map((e) => Post.fromJson(e as Map<String, dynamic>))
//       .toList(),
// );
```

---

## 8. 最佳实践

### 8.1 小项目用手写，大项目用代码生成

这是最核心的决策原则：

```
小项目（< 10 个模型）
├── 手写 fromJson / toJson
├── 优点：无额外依赖，简单直接
└── 缺点：手写容易出错，字段多了很繁琐

中型项目（10~50 个模型）
├── json_serializable + build_runner
├── 优点：自动生成，减少错误
└── 缺点：需要配置 build_runner，有学习成本

大型项目（50+ 个模型，复杂状态管理）
├── freezed + json_serializable
├── 优点：不可变性、copyWith、联合类型、值相等
└── 缺点：学习成本较高，生成文件多
```

### 8.2 工厂构造函数模式

始终使用 `factory` 构造函数来实现 `fromJson`，这是 Dart 社区的标准做法：

```dart
class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  // ✅ 推荐：工厂构造函数
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  // ✅ 推荐：实例方法
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
```

**一致的命名约定：**

| 方法 | 命名 | 说明 |
|------|------|------|
| JSON → 对象 | `fromJson` | 工厂构造函数，接收 `Map<String, dynamic>` |
| 对象 → JSON | `toJson` | 实例方法，返回 `Map<String, dynamic>` |

### 8.3 错误处理

在实际项目中，JSON 解析经常会出错（后端返回格式变了、字段类型不对等）。良好的错误处理至关重要：

```dart
/// 方式一：在 fromJson 中捕获异常
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );
    } catch (e, stackTrace) {
      // 记录日志，方便排查问题
      print('User.fromJson 解析失败: $e');
      print('原始 JSON: $json');
      print('堆栈: $stackTrace');
      rethrow; // 重新抛出异常
    }
  }
}

/// 方式二：提供安全的解析方法，返回 null 而不是抛异常
class User {
  // ... 字段和构造函数 ...

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  /// 安全解析：解析失败返回 null
  static User? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return User.fromJson(json);
    } catch (e) {
      print('User 解析失败: $e');
      return null;
    }
  }
}

// 使用安全解析
final user = User.tryFromJson(jsonData);
if (user != null) {
  // 解析成功
  print(user.name);
} else {
  // 解析失败，显示兜底 UI
  print('数据加载失败');
}
```

**批量解析时的错误处理：**

```dart
/// 安全地解析列表，跳过解析失败的元素
List<User> parseUserList(List<dynamic> jsonList) {
  final users = <User>[];
  for (final json in jsonList) {
    try {
      users.add(User.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      // 跳过解析失败的元素，打印日志
      print('跳过无法解析的用户数据: $json, 错误: $e');
    }
  }
  return users;
}

// 或者使用函数式写法
List<User> parseUserListSafe(List<dynamic> jsonList) {
  return jsonList
      .map((json) => User.tryFromJson(json as Map<String, dynamic>?))
      .whereType<User>() // 过滤掉 null
      .toList();
}
```

### 8.4 模型类组织建议

```
lib/
├── models/              # 所有模型类放在这个目录
│   ├── user.dart        # User 模型
│   ├── post.dart        # Post 模型
│   ├── address.dart     # Address 模型
│   ├── api_response.dart # 通用响应包装类
│   └── models.dart      # 统一导出文件（barrel file）
├── services/            # 网络请求层
│   ├── api_client.dart
│   └── user_service.dart
└── ...
```

**统一导出文件 `models.dart`：**

```dart
// lib/models/models.dart
// 一行导入所有模型
export 'user.dart';
export 'post.dart';
export 'address.dart';
export 'api_response.dart';
```

```dart
// 在其他文件中使用
import 'package:my_app/models/models.dart';

// 现在可以直接使用所有模型类
final user = User.fromJson(json);
final post = Post.fromJson(json);
```

---

## 9. 本章小结

本章我们系统学习了 Flutter 中 JSON 序列化的方方面面：

### 核心知识点回顾

| 主题 | 要点 |
|------|------|
| **dart:convert** | `jsonDecode` / `jsonEncode` 是所有 JSON 操作的基础 |
| **手写序列化** | `fromJson`（工厂构造函数）+ `toJson`（实例方法）是标准模式 |
| **类型安全** | 注意 `int` / `double` / `String` 的转换，使用 `as` 和 `num` |
| **null 处理** | 可空类型用 `as String?`，默认值用 `?? 0` |
| **嵌套对象** | 递归调用内层对象的 `fromJson` / `toJson` |
| **List 序列化** | `(json['field'] as List).map(...).toList()` |
| **json_serializable** | 注解 + 代码生成，适合中大型项目 |
| **freezed** | 不可变数据类 + copyWith + 联合类型，适合复杂状态管理 |
| **泛型 ApiResponse** | 统一处理后端响应格式，用泛型支持不同的 data 类型 |
| **错误处理** | `tryFromJson` 模式，批量解析时跳过失败元素 |

### 方案选择速查

```
你的项目有多少个模型类？
├── < 10 个 → 手写 fromJson / toJson ✅（本章重点）
├── 10~50 个 → json_serializable + build_runner
└── 50+ 个，且需要状态管理 → freezed + json_serializable
```

### 下一步学习

- 在实际项目中练习手写 `fromJson` / `toJson`
- 尝试处理真实 API 返回的复杂 JSON 数据
- 当模型类增多后，尝试引入 `json_serializable`
- 学习状态管理时，了解 `freezed` 的实际使用

> 📁 本章完整示例代码请查看 `lib/ch03_json_serialization.dart`，所有示例均使用手写序列化方式实现。
