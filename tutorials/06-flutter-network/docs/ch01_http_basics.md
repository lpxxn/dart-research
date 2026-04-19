# 第1章：HTTP 基础

> 本章配套代码位于 `lib/ch01_http_basics.dart`

在 Flutter 开发中，与服务器进行数据交互是最常见的需求之一。无论是获取用户列表、提交表单数据还是上传文件，都离不开 HTTP 协议。本章将从 HTTP 协议的基础知识讲起，逐步带你掌握 Flutter 中使用 `http` 包进行网络请求的核心技能。

---

## 目录

1. [HTTP 协议基础](#1-http-协议基础)
2. [Flutter 的 http 包基本用法](#2-flutter-的-http-包基本用法)
3. [GET 请求详解](#3-get-请求详解)
4. [POST 请求详解](#4-post-请求详解)
5. [PUT 和 DELETE 请求](#5-put-和-delete-请求)
6. [请求头设置方法](#6-请求头设置方法)
7. [超时处理](#7-超时处理)
8. [响应解析和错误处理](#8-响应解析和错误处理)
9. [使用 FutureBuilder 展示异步数据](#9-使用-futurebuilder-展示异步数据)
10. [最佳实践](#10-最佳实践)
11. [本章小结](#11-本章小结)

---

## 1. HTTP 协议基础

HTTP（HyperText Transfer Protocol，超文本传输协议）是互联网上应用最广泛的应用层协议。它采用**请求-响应**模型：客户端（如 Flutter 应用）发送请求，服务器返回响应。

### 1.1 请求方法

HTTP 定义了多种请求方法，每种方法表达不同的语义。在 RESTful API 设计中，最常用的有以下四种：

| 方法 | 语义 | 是否有请求体 | 幂等性 | 典型用途 |
|------|------|-------------|--------|---------|
| **GET** | 获取资源 | 否 | 是 | 获取用户列表、查询文章详情 |
| **POST** | 创建资源 | 是 | 否 | 注册用户、提交订单 |
| **PUT** | 更新资源（整体替换） | 是 | 是 | 修改用户信息、更新配置 |
| **DELETE** | 删除资源 | 通常无 | 是 | 删除用户、移除收藏 |

> **幂等性**：同一个请求执行多次，效果与执行一次相同。GET、PUT、DELETE 是幂等的，POST 不是。

除此之外还有一些不太常用但值得了解的方法：

- **PATCH**：部分更新资源（只修改指定字段，而非整体替换）
- **HEAD**：与 GET 类似，但服务器只返回响应头，不返回响应体
- **OPTIONS**：用于获取服务器支持的请求方法（常见于 CORS 预检请求）

### 1.2 HTTP 状态码

服务器通过状态码告诉客户端请求的处理结果。状态码是一个三位数字，按首位数字分为五类：

| 分类 | 范围 | 含义 | 说明 |
|------|------|------|------|
| **1xx** | 100-199 | 信息性状态码 | 表示请求已接收，需要继续处理。实际开发中很少直接遇到 |
| **2xx** | 200-299 | 成功状态码 | 表示请求已被成功接收、理解并处理 |
| **3xx** | 300-399 | 重定向状态码 | 表示需要进一步操作才能完成请求 |
| **4xx** | 400-499 | 客户端错误状态码 | 表示客户端发送的请求存在错误 |
| **5xx** | 500-599 | 服务器错误状态码 | 表示服务器在处理请求时发生了错误 |

#### 常见状态码详解

**2xx 成功：**

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 200 | OK | 请求成功，最常见的成功状态码 |
| 201 | Created | 资源创建成功，通常在 POST 请求后返回 |
| 204 | No Content | 请求成功但没有返回内容，通常在 DELETE 请求后返回 |

**3xx 重定向：**

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 301 | Moved Permanently | 资源已永久移动到新位置 |
| 302 | Found | 资源临时移动到新位置 |
| 304 | Not Modified | 资源未修改，可使用缓存版本 |

**4xx 客户端错误：**

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 400 | Bad Request | 请求格式错误或参数无效 |
| 401 | Unauthorized | 未认证，需要登录 |
| 403 | Forbidden | 已认证但权限不足 |
| 404 | Not Found | 请求的资源不存在 |
| 422 | Unprocessable Entity | 请求格式正确但语义有误（如字段校验失败） |
| 429 | Too Many Requests | 请求过于频繁，触发了速率限制 |

**5xx 服务器错误：**

| 状态码 | 名称 | 说明 |
|--------|------|------|
| 500 | Internal Server Error | 服务器内部错误 |
| 502 | Bad Gateway | 网关错误，上游服务器返回了无效响应 |
| 503 | Service Unavailable | 服务暂时不可用（如维护、过载） |
| 504 | Gateway Timeout | 网关超时，上游服务器未在规定时间内响应 |

### 1.3 常见请求头

请求头（Headers）用于向服务器传递附加信息。以下是开发中最常用的几个请求头：

| 请求头 | 作用 | 常见值 |
|--------|------|--------|
| **Content-Type** | 告诉服务器请求体的数据格式 | `application/json`、`application/x-www-form-urlencoded`、`multipart/form-data` |
| **Authorization** | 携带认证信息 | `Bearer <token>`、`Basic <base64编码的用户名:密码>` |
| **Accept** | 告诉服务器客户端能接受的响应格式 | `application/json`、`text/html`、`*/*` |
| **User-Agent** | 标识客户端类型和版本 | `MyFlutterApp/1.0.0` |
| **Cache-Control** | 控制缓存行为 | `no-cache`、`max-age=3600` |
| **Accept-Encoding** | 告诉服务器客户端支持的压缩格式 | `gzip, deflate, br` |

#### Content-Type 详解

`Content-Type` 是最重要的请求头之一，它决定了服务器如何解析请求体：

```
// JSON 格式（最常用，REST API 的标准格式）
Content-Type: application/json

// 表单格式（HTML 表单默认格式）
Content-Type: application/x-www-form-urlencoded

// 文件上传格式
Content-Type: multipart/form-data
```

#### Authorization 详解

`Authorization` 头用于在请求中携带认证凭据：

```
// Bearer Token 认证（最常见，配合 JWT 使用）
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// Basic 认证（用户名密码的 Base64 编码）
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=
```

### 1.4 HTTP 请求的完整结构

一个完整的 HTTP 请求由以下部分组成：

```
请求行:    GET /api/users?page=1 HTTP/1.1
请求头:    Host: example.com
           Content-Type: application/json
           Authorization: Bearer xxx
空行
请求体:    {"name": "张三", "email": "zhangsan@example.com"}
```

一个完整的 HTTP 响应由以下部分组成：

```
状态行:    HTTP/1.1 200 OK
响应头:    Content-Type: application/json
           Content-Length: 256
空行
响应体:    {"id": 1, "name": "张三", "email": "zhangsan@example.com"}
```

---

## 2. Flutter 的 http 包基本用法

Flutter 官方提供了 `http` 包来进行 HTTP 网络请求。它是一个轻量级、易用的 HTTP 客户端库。

### 2.1 安装 http 包

在项目的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0  # 请使用最新版本
```

然后运行以下命令安装依赖：

```bash
flutter pub get
```

> **提示**：你也可以用命令行直接添加依赖：`flutter pub add http`

### 2.2 导入包

在 Dart 文件顶部导入 `http` 包，通常使用别名 `http` 以避免命名冲突：

```dart
// 导入 http 包并设置别名
import 'package:http/http.dart' as http;

// 导入 JSON 编解码工具
import 'dart:convert';
```

### 2.3 基本 API 概览

`http` 包提供了两种使用方式：

#### 方式一：顶层函数（简单请求）

适合快速、简单的一次性请求：

```dart
// GET 请求
final response = await http.get(Uri.parse('https://example.com/api/data'));

// POST 请求
final response = await http.post(
  Uri.parse('https://example.com/api/data'),
  body: jsonEncode({'key': 'value'}),
);

// PUT 请求
final response = await http.put(Uri.parse('https://example.com/api/data/1'));

// DELETE 请求
final response = await http.delete(Uri.parse('https://example.com/api/data/1'));
```

#### 方式二：Client 对象（推荐）

适合需要发送多个请求的场景，能复用底层连接，性能更好：

```dart
// 创建 Client 实例
final client = http.Client();

try {
  // 使用 client 发送多个请求（复用 TCP 连接）
  final usersResponse = await client.get(
    Uri.parse('https://example.com/api/users'),
  );
  final postsResponse = await client.get(
    Uri.parse('https://example.com/api/posts'),
  );

  // 处理响应...
} finally {
  // 重要：使用完毕后必须关闭 client，释放资源
  client.close();
}
```

### 2.4 Response 对象

所有请求方法都返回一个 `http.Response` 对象，它包含以下关键属性：

```dart
final response = await http.get(Uri.parse('https://example.com/api'));

// 状态码（如 200、404、500）
print(response.statusCode);

// 响应体（字符串形式）
print(response.body);

// 响应头
print(response.headers);

// 响应体的字节形式
print(response.bodyBytes);

// 内容长度
print(response.contentLength);

// 请求是否重定向
print(response.isRedirect);
```

---

## 3. GET 请求详解

GET 请求是最常用的 HTTP 方法，用于从服务器获取数据。本节我们使用 [JSONPlaceholder](https://jsonplaceholder.typicode.com) 这个免费的测试 API 来演示。

> **JSONPlaceholder** 是一个免费的在线 REST API，提供了 posts、comments、users 等测试数据，非常适合学习和测试。

### 3.1 最简单的 GET 请求

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 获取所有文章列表
Future<void> fetchPosts() async {
  // 构建请求 URL
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  // 发送 GET 请求
  final response = await http.get(url);

  // 检查状态码
  if (response.statusCode == 200) {
    // 将 JSON 字符串解析为 Dart 对象
    final List<dynamic> posts = jsonDecode(response.body);
    print('获取到 ${posts.length} 篇文章');

    // 打印第一篇文章的标题
    if (posts.isNotEmpty) {
      print('第一篇文章标题：${posts[0]['title']}');
    }
  } else {
    print('请求失败，状态码：${response.statusCode}');
  }
}
```

### 3.2 带参数的 GET 请求

GET 请求的参数通过 URL 的查询字符串（Query String）传递。`Uri` 类提供了方便的构造方法来处理参数：

```dart
/// 带查询参数的 GET 请求
Future<void> fetchPostsByUser(int userId) async {
  // 方法一：使用 Uri 构造器（推荐，自动处理编码）
  final url = Uri.https(
    'jsonplaceholder.typicode.com',  // 主机名（不含 https://）
    '/posts',                         // 路径
    {'userId': userId.toString()},    // 查询参数（值必须是字符串）
  );
  // 生成的 URL: https://jsonplaceholder.typicode.com/posts?userId=1

  print('请求 URL：$url');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> posts = jsonDecode(response.body);
    print('用户 $userId 共有 ${posts.length} 篇文章');
  } else {
    print('请求失败，状态码：${response.statusCode}');
  }
}

/// 多个查询参数的 GET 请求
Future<void> fetchPostsWithPagination({
  required int page,
  required int limit,
}) async {
  // 方法二：使用 Uri.parse 拼接（适合简单场景）
  final url = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts?_page=$page&_limit=$limit',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> posts = jsonDecode(response.body);
    print('第 $page 页，获取到 ${posts.length} 篇文章');
  } else {
    print('请求失败，状态码：${response.statusCode}');
  }
}

/// 使用 replace 方法动态添加查询参数
Future<void> fetchWithDynamicParams(Map<String, String> params) async {
  final baseUrl = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  // 在已有 URL 的基础上添加查询参数
  final url = baseUrl.replace(queryParameters: params);

  print('最终请求 URL：$url');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('请求成功，返回数据类型：${data.runtimeType}');
  }
}
```

### 3.3 获取单个资源

```dart
/// 根据 ID 获取单篇文章
Future<Map<String, dynamic>?> fetchPostById(int postId) async {
  final url = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts/$postId',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    // 解析为 Map（单个 JSON 对象）
    final Map<String, dynamic> post = jsonDecode(response.body);
    print('文章标题：${post['title']}');
    print('文章内容：${post['body']}');
    print('作者 ID：${post['userId']}');
    return post;
  } else if (response.statusCode == 404) {
    print('文章不存在：ID = $postId');
    return null;
  } else {
    print('请求失败，状态码：${response.statusCode}');
    return null;
  }
}
```

### 3.4 解析 JSON 响应为模型类

在实际项目中，我们通常会将 JSON 数据转换为 Dart 模型类，以获得类型安全和代码提示：

```dart
/// 文章模型类
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  // 构造函数
  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// 从 JSON Map 创建 Post 对象（工厂构造函数）
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// 将 Post 对象转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }

  @override
  String toString() => 'Post(id: $id, title: $title)';
}

/// 获取文章列表并解析为模型类
Future<List<Post>> fetchPostsAsModels() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // 解析 JSON 数组
    final List<dynamic> jsonList = jsonDecode(response.body);

    // 将每个 JSON 对象转换为 Post 模型
    final List<Post> posts = jsonList
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();

    print('成功解析 ${posts.length} 篇文章');
    return posts;
  } else {
    throw Exception('获取文章失败：${response.statusCode}');
  }
}

/// 用户模型类（演示嵌套 JSON 解析）
class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// 获取用户列表
Future<List<User>> fetchUsers() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  } else {
    throw Exception('获取用户失败：${response.statusCode}');
  }
}
```

---

## 4. POST 请求详解

POST 请求用于向服务器提交数据以创建新资源。请求数据放在请求体（body）中。

### 4.1 发送 JSON 数据

```dart
/// 创建一篇新文章
Future<Post> createPost({
  required String title,
  required String body,
  required int userId,
}) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  // 发送 POST 请求
  final response = await http.post(
    url,
    // 设置请求头，告诉服务器我们发送的是 JSON 数据
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    // 将 Dart Map 编码为 JSON 字符串
    body: jsonEncode({
      'title': title,
      'body': body,
      'userId': userId,
    }),
  );

  // 201 Created 表示资源创建成功
  if (response.statusCode == 201) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    print('文章创建成功！ID：${responseData['id']}');
    return Post.fromJson(responseData);
  } else {
    throw Exception('创建文章失败：${response.statusCode}');
  }
}
```

### 4.2 发送表单数据

有些 API 需要接收表单格式的数据，而不是 JSON：

```dart
/// 以表单格式提交数据
Future<void> createPostAsForm() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  // 发送表单数据（默认 Content-Type 就是 application/x-www-form-urlencoded）
  final response = await http.post(
    url,
    // 直接传入 Map，http 包会自动编码为表单格式
    body: {
      'title': '我的新文章',
      'body': '这是文章内容',
      'userId': '1',  // 注意：表单格式的值必须是字符串
    },
  );

  if (response.statusCode == 201) {
    print('表单提交成功');
    print('响应内容：${response.body}');
  } else {
    print('表单提交失败：${response.statusCode}');
  }
}
```

### 4.3 POST 请求的完整示例

```dart
/// 完整的 POST 请求示例，包含输入验证和错误处理
Future<Post?> createPostSafely({
  required String title,
  required String body,
  required int userId,
}) async {
  // 输入验证
  if (title.trim().isEmpty) {
    print('错误：标题不能为空');
    return null;
  }
  if (body.trim().isEmpty) {
    print('错误：内容不能为空');
    return null;
  }

  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'title': title.trim(),
        'body': body.trim(),
        'userId': userId,
      }),
    );

    switch (response.statusCode) {
      case 201:
        // 创建成功
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ 文章创建成功，ID：${data['id']}');
        return Post.fromJson(data);
      case 400:
        print('❌ 请求参数错误：${response.body}');
        return null;
      case 401:
        print('❌ 未认证，请先登录');
        return null;
      case 422:
        print('❌ 数据验证失败：${response.body}');
        return null;
      default:
        print('❌ 未知错误，状态码：${response.statusCode}');
        return null;
    }
  } catch (e) {
    print('❌ 网络请求异常：$e');
    return null;
  }
}
```

---

## 5. PUT 和 DELETE 请求

### 5.1 PUT 请求 —— 更新资源

PUT 请求用于更新（替换）服务器上的已有资源。它需要发送完整的资源数据。

```dart
/// 更新文章（整体替换）
Future<Post?> updatePost({
  required int postId,
  required String title,
  required String body,
  required int userId,
}) async {
  // PUT 请求的 URL 通常包含资源 ID
  final url = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts/$postId',
  );

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // PUT 请求需要发送完整的资源数据
      body: jsonEncode({
        'id': postId,
        'title': title,
        'body': body,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('✅ 文章更新成功');
      print('   新标题：${data['title']}');
      return Post.fromJson(data);
    } else {
      print('❌ 更新失败，状态码：${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ 网络请求异常：$e');
    return null;
  }
}
```

### 5.2 PATCH 请求 —— 部分更新

虽然 `http` 包没有直接提供 `patch` 顶层函数，但可以通过 `Client` 来发送 PATCH 请求：

```dart
/// 部分更新文章（只修改标题）
Future<void> patchPostTitle(int postId, String newTitle) async {
  final url = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts/$postId',
  );

  final client = http.Client();
  try {
    // 使用 client.patch 发送 PATCH 请求
    final response = await client.patch(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // PATCH 只需要发送要修改的字段
      body: jsonEncode({
        'title': newTitle,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ 标题已更新为：${data['title']}');
    } else {
      print('❌ 部分更新失败，状态码：${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
```

### 5.3 DELETE 请求 —— 删除资源

```dart
/// 删除文章
Future<bool> deletePost(int postId) async {
  final url = Uri.parse(
    'https://jsonplaceholder.typicode.com/posts/$postId',
  );

  try {
    final response = await http.delete(url);

    // DELETE 成功通常返回 200 或 204
    if (response.statusCode == 200 || response.statusCode == 204) {
      print('✅ 文章删除成功，ID：$postId');
      return true;
    } else if (response.statusCode == 404) {
      print('⚠️ 文章不存在，ID：$postId');
      return false;
    } else {
      print('❌ 删除失败，状态码：${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ 网络请求异常：$e');
    return false;
  }
}
```

### 5.4 各请求方法对比总结

```dart
/// 演示所有 CRUD 操作
Future<void> demonstrateCrud() async {
  // 1. CREATE - 创建资源
  print('--- 创建文章 ---');
  final newPost = await createPost(
    title: '学习 Flutter HTTP',
    body: '这是一篇关于网络请求的文章',
    userId: 1,
  );

  // 2. READ - 读取资源
  print('\n--- 读取文章 ---');
  final post = await fetchPostById(1);

  // 3. UPDATE - 更新资源
  print('\n--- 更新文章 ---');
  final updatedPost = await updatePost(
    postId: 1,
    title: '更新后的标题',
    body: '更新后的内容',
    userId: 1,
  );

  // 4. DELETE - 删除资源
  print('\n--- 删除文章 ---');
  final deleted = await deletePost(1);
}
```

---

## 6. 请求头设置方法

请求头是 HTTP 通信中非常重要的组成部分。合理设置请求头可以实现认证、内容协商、缓存控制等功能。

### 6.1 在单个请求中设置请求头

```dart
/// 带自定义请求头的 GET 请求
Future<void> fetchWithHeaders() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  final response = await http.get(
    url,
    headers: {
      // 告诉服务器我们接受 JSON 格式的响应
      'Accept': 'application/json',
      // 携带认证令牌
      'Authorization': 'Bearer your-jwt-token-here',
      // 自定义请求头
      'X-Custom-Header': 'custom-value',
      // 指定客户端信息
      'User-Agent': 'FlutterApp/1.0.0',
      // 指定语言偏好
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    },
  );

  // 打印响应头
  print('响应 Content-Type：${response.headers['content-type']}');
  print('状态码：${response.statusCode}');
}
```

### 6.2 使用 Client 统一设置请求头

在实际项目中，很多请求头（如认证令牌）在每次请求中都相同。我们可以封装一个带默认请求头的请求方法：

```dart
/// 封装的 HTTP 服务类，统一管理请求头
class ApiService {
  final http.Client _client;
  final String _baseUrl;
  final Map<String, String> _defaultHeaders;

  ApiService({
    required String baseUrl,
    String? authToken,
  })  : _client = http.Client(),
        _baseUrl = baseUrl,
        _defaultHeaders = {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        };

  /// 合并默认请求头和自定义请求头
  Map<String, String> _mergeHeaders(Map<String, String>? extraHeaders) {
    return {
      ..._defaultHeaders,
      if (extraHeaders != null) ...extraHeaders,
    };
  }

  /// 发送 GET 请求
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParams,
    );
    return _client.get(url, headers: _mergeHeaders(headers));
  }

  /// 发送 POST 请求
  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    return _client.post(
      url,
      headers: _mergeHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// 关闭客户端，释放资源
  void dispose() {
    _client.close();
  }
}

// 使用示例
void apiServiceExample() async {
  final api = ApiService(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    authToken: 'my-secret-token',
  );

  try {
    // 所有请求都会自动带上 Content-Type、Accept 和 Authorization 头
    final response = await api.get('/posts', queryParams: {'userId': '1'});
    print('获取文章：${response.statusCode}');

    final createResponse = await api.post('/posts', body: {
      'title': '新文章',
      'body': '内容',
      'userId': 1,
    });
    print('创建文章：${createResponse.statusCode}');
  } finally {
    api.dispose();
  }
}
```

### 6.3 动态更新认证令牌

```dart
/// 支持动态更新 Token 的 API 服务
class AuthApiService {
  final http.Client _client = http.Client();
  final String baseUrl;
  String? _authToken;

  AuthApiService({required this.baseUrl});

  /// 设置认证令牌（登录成功后调用）
  void setAuthToken(String token) {
    _authToken = token;
    print('✅ 认证令牌已更新');
  }

  /// 清除认证令牌（退出登录时调用）
  void clearAuthToken() {
    _authToken = null;
    print('✅ 认证令牌已清除');
  }

  /// 构建请求头
  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// 发送带认证的 GET 请求
  Future<http.Response> authenticatedGet(String path) async {
    if (_authToken == null) {
      throw Exception('未登录，请先设置认证令牌');
    }
    final url = Uri.parse('$baseUrl$path');
    return _client.get(url, headers: _headers);
  }

  void dispose() => _client.close();
}
```

---

## 7. 超时处理

网络请求可能因为网络不稳定、服务器响应慢等原因花费很长时间。设置超时可以避免用户无限等待。

### 7.1 使用 .timeout() 方法

Dart 的 `Future` 类提供了 `.timeout()` 方法，可以为任何异步操作设置超时时间：

```dart
import 'dart:async'; // 需要导入以使用 TimeoutException

/// 带超时的 GET 请求
Future<void> fetchWithTimeout() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  try {
    // 设置 10 秒超时
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      // 可选：超时时的回调函数
      onTimeout: () {
        // 返回一个自定义的 Response 对象
        return http.Response(
          '{"error": "请求超时"}',
          408, // 408 Request Timeout
        );
      },
    );

    if (response.statusCode == 200) {
      print('✅ 请求成功');
    } else if (response.statusCode == 408) {
      print('⏰ 请求超时，请检查网络后重试');
    } else {
      print('❌ 请求失败：${response.statusCode}');
    }
  } on TimeoutException {
    // 如果没有提供 onTimeout 回调，超时会抛出 TimeoutException
    print('⏰ 请求超时（TimeoutException）');
  } catch (e) {
    print('❌ 请求异常：$e');
  }
}
```

### 7.2 为不同类型的请求设置不同的超时时间

```dart
/// 根据请求类型设置不同的超时时间
class TimeoutConfig {
  /// GET 请求通常比较快，设置较短的超时
  static const Duration getTimeout = Duration(seconds: 15);

  /// POST 请求可能需要处理更多数据
  static const Duration postTimeout = Duration(seconds: 30);

  /// 文件上传可能需要更长时间
  static const Duration uploadTimeout = Duration(seconds: 120);

  /// 下载也可能需要较长时间
  static const Duration downloadTimeout = Duration(seconds: 60);
}

/// 带超时配置的请求示例
Future<void> fetchPostsWithConfiguredTimeout() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  try {
    final response = await http.get(url).timeout(TimeoutConfig.getTimeout);
    print('获取到数据，长度：${response.body.length} 字节');
  } on TimeoutException {
    print('请求超时（${TimeoutConfig.getTimeout.inSeconds}秒）');
  }
}

Future<void> createPostWithConfiguredTimeout() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': '超时测试',
        'body': '测试内容',
        'userId': 1,
      }),
    ).timeout(TimeoutConfig.postTimeout);

    print('创建结果：${response.statusCode}');
  } on TimeoutException {
    print('创建请求超时（${TimeoutConfig.postTimeout.inSeconds}秒）');
  }
}
```

### 7.3 带重试机制的超时处理

```dart
/// 带重试机制的网络请求
Future<http.Response> fetchWithRetry(
  Uri url, {
  int maxRetries = 3,
  Duration timeout = const Duration(seconds: 10),
  Duration retryDelay = const Duration(seconds: 2),
}) async {
  int retryCount = 0;

  while (true) {
    try {
      print('第 ${retryCount + 1} 次请求...');
      final response = await http.get(url).timeout(timeout);

      // 如果服务器返回 5xx 错误，也进行重试
      if (response.statusCode >= 500 && retryCount < maxRetries) {
        print('服务器错误（${response.statusCode}），准备重试...');
        retryCount++;
        await Future.delayed(retryDelay * retryCount); // 递增等待时间
        continue;
      }

      return response;
    } on TimeoutException {
      retryCount++;
      if (retryCount > maxRetries) {
        print('已达最大重试次数（$maxRetries），放弃请求');
        rethrow; // 重新抛出异常
      }
      print('请求超时，${retryDelay.inSeconds * retryCount}秒后重试...');
      await Future.delayed(retryDelay * retryCount);
    }
  }
}

// 使用示例
Future<void> retryExample() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

  try {
    final response = await fetchWithRetry(
      url,
      maxRetries: 3,
      timeout: const Duration(seconds: 5),
    );
    print('最终结果：${response.statusCode}');
  } on TimeoutException {
    print('所有重试均超时，请检查网络');
  }
}
```

---

## 8. 响应解析和错误处理

健壮的错误处理是生产级应用的必备特性。HTTP 请求可能遇到多种错误，我们需要妥善处理每一种情况。

### 8.1 常见错误类型

HTTP 请求中可能遇到的异常：

| 异常类型 | 触发场景 | 处理建议 |
|---------|---------|---------|
| `SocketException` | 无网络连接、DNS 解析失败 | 提示用户检查网络 |
| `TimeoutException` | 请求超时 | 提示用户重试 |
| `FormatException` | JSON 格式错误 | 检查服务器返回内容 |
| `HttpException` | HTTP 协议错误 | 记录日志、上报错误 |
| `ClientException` | 客户端连接错误 | 重试或提示用户 |
| `HandshakeException` | SSL/TLS 握手失败 | 检查证书配置 |

### 8.2 完善的 try-catch 错误处理

```dart
import 'dart:io'; // 导入以使用 SocketException

/// 封装的网络请求结果类
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult.success(this.data)
      : error = null,
        isSuccess = true;

  ApiResult.failure(this.error)
      : data = null,
        isSuccess = false;

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResult.success($data)';
    } else {
      return 'ApiResult.failure($error)';
    }
  }
}

/// 完善的错误处理示例
Future<ApiResult<List<Post>>> fetchPostsSafely() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  try {
    // 发送请求
    final response = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    // 根据状态码判断结果
    if (response.statusCode == 200) {
      // 尝试解析 JSON
      try {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final posts = jsonList
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResult.success(posts);
      } on FormatException catch (e) {
        return ApiResult.failure('数据格式错误：$e');
      } on TypeError catch (e) {
        return ApiResult.failure('数据类型不匹配：$e');
      }
    } else if (response.statusCode == 401) {
      return ApiResult.failure('认证失败，请重新登录');
    } else if (response.statusCode == 403) {
      return ApiResult.failure('权限不足，无法访问');
    } else if (response.statusCode == 404) {
      return ApiResult.failure('请求的资源不存在');
    } else if (response.statusCode >= 500) {
      return ApiResult.failure('服务器内部错误（${response.statusCode}）');
    } else {
      return ApiResult.failure('请求失败（${response.statusCode}）');
    }
  } on SocketException {
    // 网络连接失败（无网络、DNS 解析失败等）
    return ApiResult.failure('网络连接失败，请检查网络设置');
  } on TimeoutException {
    // 请求超时
    return ApiResult.failure('请求超时，请稍后重试');
  } on http.ClientException catch (e) {
    // HTTP 客户端错误
    return ApiResult.failure('网络请求错误：${e.message}');
  } catch (e) {
    // 其他未知错误
    return ApiResult.failure('未知错误：$e');
  }
}

// 使用 ApiResult
Future<void> usageExample() async {
  final result = await fetchPostsSafely();

  if (result.isSuccess) {
    print('获取到 ${result.data!.length} 篇文章');
    for (final post in result.data!.take(3)) {
      print('  - ${post.title}');
    }
  } else {
    print('出错了：${result.error}');
  }
}
```

### 8.3 状态码判断的最佳实践

```dart
/// 通用的响应处理函数
Future<Map<String, dynamic>> handleResponse(http.Response response) async {
  // 按状态码范围分类处理
  final statusCode = response.statusCode;

  if (statusCode >= 200 && statusCode < 300) {
    // 2xx：成功
    if (response.body.isEmpty) {
      return {'success': true, 'message': '操作成功'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // 解析服务器返回的错误信息
  String errorMessage;
  try {
    final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    errorMessage = errorBody['message'] ?? errorBody['error'] ?? '未知错误';
  } catch (_) {
    errorMessage = response.body.isNotEmpty ? response.body : '未知错误';
  }

  if (statusCode >= 400 && statusCode < 500) {
    // 4xx：客户端错误
    switch (statusCode) {
      case 400:
        throw ApiException('请求参数错误：$errorMessage', statusCode);
      case 401:
        throw UnauthorizedException('认证失败：$errorMessage');
      case 403:
        throw ForbiddenException('权限不足：$errorMessage');
      case 404:
        throw NotFoundException('资源不存在：$errorMessage');
      case 429:
        throw RateLimitException('请求过于频繁，请稍后重试');
      default:
        throw ApiException('客户端错误：$errorMessage', statusCode);
    }
  }

  if (statusCode >= 500) {
    // 5xx：服务器错误
    throw ServerException('服务器错误（$statusCode）：$errorMessage');
  }

  throw ApiException('未处理的状态码：$statusCode', statusCode);
}

/// 自定义异常类
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message, 429);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}
```

### 8.4 链式调用的解析模式

```dart
/// 链式解析：请求 -> 验证状态码 -> 解码 JSON -> 转换模型
Future<List<Post>> fetchAndParsePosts() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  // 第一步：发送请求
  final response = await http.get(url).timeout(
    const Duration(seconds: 15),
  );

  // 第二步：验证状态码
  if (response.statusCode != 200) {
    throw ApiException(
      '获取文章列表失败',
      response.statusCode,
    );
  }

  // 第三步：解码 JSON
  final dynamic decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw FormatException('期望返回数组，实际返回：${decoded.runtimeType}');
  }

  // 第四步：转换为模型列表
  return decoded
      .cast<Map<String, dynamic>>()
      .map(Post.fromJson)
      .toList();
}
```

---

## 9. 使用 FutureBuilder 展示异步数据

在 Flutter 中，网络请求是异步操作，而 UI 构建是同步的。`FutureBuilder` 是连接这两者的桥梁，它能根据 `Future` 的不同状态（等待中、完成、出错）自动重建 Widget。

### 9.1 FutureBuilder 基础用法

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 使用 FutureBuilder 展示文章列表
class PostListPage extends StatelessWidget {
  const PostListPage({super.key});

  /// 获取文章列表的异步方法
  Future<List<Post>> _fetchPosts() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final response = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('加载失败：${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文章列表')),
      body: FutureBuilder<List<Post>>(
        // 传入异步方法
        future: _fetchPosts(),
        // 根据异步状态构建不同的 UI
        builder: (context, snapshot) {
          // 状态一：等待中（加载中）
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载文章...'),
                ],
              ),
            );
          }

          // 状态二：出错
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败：${snapshot.error}'),
                  const SizedBox(height: 16),
                  // 注意：在 StatelessWidget 中无法刷新，
                  // 实际项目中应使用 StatefulWidget
                ],
              ),
            );
          }

          // 状态三：成功但数据为空
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无文章'));
          }

          // 状态四：成功且有数据
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 9.2 使用 StatefulWidget 支持刷新

在实际项目中，我们通常需要支持下拉刷新和错误重试。这时需要使用 `StatefulWidget`：

```dart
/// 支持刷新的文章列表页面
class RefreshablePostListPage extends StatefulWidget {
  const RefreshablePostListPage({super.key});

  @override
  State<RefreshablePostListPage> createState() =>
      _RefreshablePostListPageState();
}

class _RefreshablePostListPageState extends State<RefreshablePostListPage> {
  // 用 late 延迟初始化 Future
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化 Future（重要！不要在 build 中创建）
    _postsFuture = _fetchPosts();
  }

  /// 获取文章列表
  Future<List<Post>> _fetchPosts() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final response = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('加载失败：${response.statusCode}');
    }
  }

  /// 刷新数据
  void _refresh() {
    setState(() {
      // 重新创建 Future，触发 FutureBuilder 重新构建
      _postsFuture = _fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文章列表'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败：${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新加载'),
                  ),
                ],
              ),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('暂无文章'));
          }

          // 使用 RefreshIndicator 支持下拉刷新
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              // 等待新的 Future 完成
              await _postsFuture;
            },
            child: ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${post.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  isThreeLine: true,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

### 9.3 FutureBuilder 使用注意事项

> ⚠️ **重要提示**：不要在 `build` 方法中直接调用异步函数作为 `FutureBuilder` 的 `future` 参数。

```dart
// ❌ 错误用法：每次 build 都会创建新的 Future，导致无限重建
@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: fetchPosts(), // 每次 build 都重新请求！
    builder: (context, snapshot) { ... },
  );
}

// ✅ 正确用法：在 initState 中创建 Future，保存到变量中
late Future<List<Post>> _postsFuture;

@override
void initState() {
  super.initState();
  _postsFuture = fetchPosts(); // 只创建一次
}

@override
Widget build(BuildContext context) {
  return FutureBuilder(
    future: _postsFuture, // 使用保存的 Future
    builder: (context, snapshot) { ... },
  );
}
```

### 9.4 展示单个资源详情

```dart
/// 文章详情页面
class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    _postFuture = _fetchPost();
  }

  Future<Post> _fetchPost() async {
    final url = Uri.parse(
      'https://jsonplaceholder.typicode.com/posts/${widget.postId}',
    );
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      return Post.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('获取文章详情失败：${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('文章 #${widget.postId}')),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('文章不存在'));
          }

          final post = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 文章标题
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 作者信息
                Text(
                  '作者 ID：${post.userId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const Divider(height: 32),
                // 文章正文
                Text(
                  post.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## 10. 最佳实践

### 10.1 始终关闭 Client

使用 `http.Client()` 创建的客户端在使用完毕后必须关闭，否则会造成资源泄漏：

```dart
// ✅ 正确：使用 try-finally 确保 client 被关闭
final client = http.Client();
try {
  final response = await client.get(Uri.parse('https://example.com'));
  // 处理响应...
} finally {
  client.close(); // 无论成功还是失败，都要关闭
}

// ✅ 正确：在 StatefulWidget 的 dispose 中关闭
class _MyPageState extends State<MyPage> {
  final _client = http.Client();

  @override
  void dispose() {
    _client.close(); // 页面销毁时关闭 client
    super.dispose();
  }
}

// ❌ 错误：创建了 Client 但忘记关闭
void badExample() async {
  final client = http.Client();
  final response = await client.get(Uri.parse('https://example.com'));
  // client 没有被关闭，资源泄漏！
}
```

### 10.2 统一的错误处理模式

建议在项目中采用统一的错误处理模式，避免每个请求都写重复的 try-catch：

```dart
/// 统一的网络请求封装
class HttpHelper {
  static final _client = http.Client();

  /// 通用的 GET 请求方法
  static Future<ApiResult<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    T Function(dynamic json)? parser,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (parser != null) {
          final data = jsonDecode(response.body);
          return ApiResult.success(parser(data));
        }
        return ApiResult.success(null);
      } else {
        return ApiResult.failure(
          _parseErrorMessage(response),
        );
      }
    } on SocketException {
      return ApiResult.failure('网络连接失败');
    } on TimeoutException {
      return ApiResult.failure('请求超时');
    } on FormatException {
      return ApiResult.failure('数据格式错误');
    } catch (e) {
      return ApiResult.failure('未知错误：$e');
    }
  }

  /// 解析服务器返回的错误信息
  static String _parseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? '请求失败（${response.statusCode}）';
    } catch (_) {
      return '请求失败（${response.statusCode}）';
    }
  }

  /// 关闭客户端
  static void dispose() => _client.close();
}

// 使用示例：极简的调用方式
Future<void> cleanUsageExample() async {
  // 获取文章列表
  final result = await HttpHelper.get<List<Post>>(
    'https://jsonplaceholder.typicode.com/posts',
    parser: (json) => (json as List)
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  if (result.isSuccess) {
    print('获取到 ${result.data!.length} 篇文章');
  } else {
    print('错误：${result.error}');
  }
}
```

### 10.3 超时设置建议

```dart
/// 推荐的超时配置
class RecommendedTimeouts {
  // 普通数据请求：10-15 秒
  static const Duration normal = Duration(seconds: 15);

  // 大数据量请求（列表、搜索）：20-30 秒
  static const Duration heavy = Duration(seconds: 30);

  // 文件上传/下载：根据文件大小调整，通常 60-300 秒
  static const Duration fileTransfer = Duration(seconds: 120);

  // 连接超时（仅建立连接的时间）：5-10 秒
  static const Duration connection = Duration(seconds: 10);
}
```

### 10.4 其他建议

1. **使用模型类**：不要在业务代码中直接操作 `Map<String, dynamic>`，应将 JSON 转换为强类型的模型类。
2. **集中管理 URL**：将所有 API 地址集中定义，便于维护和切换环境。
3. **日志记录**：在开发阶段记录请求和响应日志，便于调试。
4. **缓存策略**：对于不常变化的数据，考虑添加本地缓存。
5. **取消请求**：在页面销毁时取消未完成的请求，避免在已销毁的 Widget 上调用 `setState`。

```dart
/// 集中管理 API 地址
class ApiEndpoints {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // 文章相关
  static const String posts = '$baseUrl/posts';
  static String postById(int id) => '$baseUrl/posts/$id';
  static String postComments(int postId) => '$baseUrl/posts/$postId/comments';

  // 用户相关
  static const String users = '$baseUrl/users';
  static String userById(int id) => '$baseUrl/users/$id';
  static String userPosts(int userId) => '$baseUrl/users/$userId/posts';

  // 评论相关
  static const String comments = '$baseUrl/comments';
}

// 使用示例
Future<void> endpointUsageExample() async {
  // 获取所有文章
  final allPosts = await http.get(Uri.parse(ApiEndpoints.posts));

  // 获取指定文章
  final post = await http.get(Uri.parse(ApiEndpoints.postById(1)));

  // 获取文章的评论
  final comments = await http.get(Uri.parse(ApiEndpoints.postComments(1)));
}
```

---

## 11. 本章小结

本章我们系统学习了 HTTP 基础知识以及在 Flutter 中使用 `http` 包进行网络请求的方法。以下是本章的核心知识点回顾：

### 知识点回顾

| 主题 | 要点 |
|------|------|
| **HTTP 方法** | GET（获取）、POST（创建）、PUT（更新）、DELETE（删除）是最常用的四种方法 |
| **状态码** | 2xx 成功、3xx 重定向、4xx 客户端错误、5xx 服务器错误 |
| **请求头** | Content-Type 指定数据格式、Authorization 携带认证信息、Accept 指定接受格式 |
| **http 包** | 使用 `http.get/post/put/delete` 发送请求，使用 `Client` 复用连接 |
| **JSON 解析** | 使用 `jsonDecode` 解析响应，使用模型类的 `fromJson` 工厂方法转换数据 |
| **超时处理** | 使用 `.timeout()` 方法设置超时，配合 `TimeoutException` 捕获超时异常 |
| **错误处理** | 使用 try-catch 捕获异常，根据状态码分类处理错误 |
| **FutureBuilder** | 在 Widget 中展示异步数据的桥梁，支持加载中、成功、失败三种状态 |
| **最佳实践** | 关闭 Client、统一错误处理、合理设置超时、使用模型类、集中管理 URL |

### 关键代码速查

```dart
// 1. 导入
import 'package:http/http.dart' as http;
import 'dart:convert';

// 2. GET 请求
final response = await http.get(Uri.parse('https://api.example.com/data'));

// 3. POST 请求
final response = await http.post(
  Uri.parse('https://api.example.com/data'),
  headers: {'Content-Type': 'application/json; charset=UTF-8'},
  body: jsonEncode({'key': 'value'}),
);

// 4. 解析 JSON
final data = jsonDecode(response.body);

// 5. 超时设置
final response = await http.get(url).timeout(const Duration(seconds: 15));

// 6. Client 复用
final client = http.Client();
try {
  // 使用 client 发送多个请求...
} finally {
  client.close();
}
```

### 下一章预告

在下一章中，我们将学习更强大的 HTTP 客户端库 —— **Dio**。Dio 内置了拦截器、全局配置、取消请求、文件上传下载等高级功能，是 Flutter 项目中最流行的网络请求库之一。

---

> 📖 本章配套代码：`lib/ch01_http_basics.dart`
>
> 🔗 JSONPlaceholder API 文档：[https://jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com)
>
> 📦 http 包文档：[https://pub.dev/packages/http](https://pub.dev/packages/http)
