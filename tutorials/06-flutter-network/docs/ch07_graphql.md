# 第七章：GraphQL 基础

## 概述

GraphQL 是由 Facebook 于 2015 年开源的一种 **API 查询语言**。与 REST API 不同，GraphQL 允许客户端**精确指定需要的数据**，避免了过度获取（over-fetching）和获取不足（under-fetching）的问题。

## GraphQL vs REST

### REST 的问题

假设要显示一个用户的基本信息和最近 3 篇文章：

```
REST 方式需要多次请求：
GET /users/1            → 获取用户信息（可能返回很多不需要的字段）
GET /users/1/posts?limit=3  → 获取文章列表
GET /posts/1/comments   → 获取文章评论（如果需要的话）
```

问题：
- **多次请求**：需要 2-3 次 HTTP 请求
- **过度获取**：`/users/1` 返回了很多不需要的字段
- **获取不足**：一次请求拿不到关联数据

### GraphQL 的解决方案

```graphql
query {
  user(id: "1") {
    name
    email
    posts(limit: 3) {
      title
      comments {
        text
      }
    }
  }
}
```

**一次请求**，精确获取所需数据，不多不少。

### 对比总结

| 特性 | REST | GraphQL |
|------|------|---------|
| 端点 | 多个 URL（`/users`, `/posts`...） | 单一端点（`/graphql`） |
| 数据获取 | 服务端决定返回什么 | 客户端决定要什么 |
| 请求次数 | 可能需要多次 | 通常一次 |
| 版本控制 | URL 版本（v1, v2） | 无需版本，Schema 演进 |
| 缓存 | HTTP 缓存简单 | 需要特殊处理 |
| 学习曲线 | 低 | 中等 |

## GraphQL 核心概念

### 1. Query（查询）

查询用于读取数据，类似 REST 的 GET：

```graphql
query GetUsers {
  users {
    id
    name
    email
    role
  }
}
```

### 2. 带变量的查询

变量让查询可以复用：

```graphql
query GetUserById($id: ID!) {
  user(id: $id) {
    id
    name
    email
    posts {
      title
      createdAt
    }
  }
}

# 变量
{
  "id": "1"
}
```

`$id: ID!` 中的 `!` 表示必填参数。

### 3. Mutation（变更）

变更用于写入数据，类似 REST 的 POST/PUT/DELETE：

```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    name
    email
  }
}

# 变量
{
  "input": {
    "name": "张三",
    "email": "zhangsan@example.com",
    "role": "USER"
  }
}
```

### 4. Subscription（订阅）

订阅用于实时数据推送（基于 WebSocket）：

```graphql
subscription OnNewMessage {
  newMessage {
    id
    content
    sender {
      name
    }
  }
}
```

### 5. Schema（模式）

Schema 定义了 API 的数据类型和操作：

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  role: Role!
  posts: [Post!]!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
}

enum Role {
  ADMIN
  USER
}

type Query {
  users: [User!]!
  user(id: ID!): User
}

type Mutation {
  createUser(input: CreateUserInput!): User!
}
```

## 在 Flutter 中使用 GraphQL

### 方式一：graphql_flutter 包（推荐）

```yaml
dependencies:
  graphql_flutter: ^5.0.0
```

#### 初始化客户端

```dart
import 'package:graphql_flutter/graphql_flutter.dart';

final HttpLink httpLink = HttpLink('https://api.example.com/graphql');

// 如果需要认证
final AuthLink authLink = AuthLink(
  getToken: () async => 'Bearer $token',
);

final Link link = authLink.concat(httpLink);

final ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
  ),
);
```

#### 使用 Query Widget

```dart
Query(
  options: QueryOptions(
    document: gql('''
      query GetUsers {
        users { id name email }
      }
    '''),
  ),
  builder: (result, {fetchMore, refetch}) {
    if (result.isLoading) return CircularProgressIndicator();
    if (result.hasException) return Text('错误: ${result.exception}');

    final users = result.data?['users'] as List;
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (_, i) => ListTile(title: Text(users[i]['name'])),
    );
  },
)
```

#### 使用 Mutation Widget

```dart
Mutation(
  options: MutationOptions(
    document: gql('''
      mutation CreateUser(\$input: CreateUserInput!) {
        createUser(input: \$input) { id name }
      }
    '''),
  ),
  builder: (runMutation, result) {
    return ElevatedButton(
      onPressed: () {
        runMutation({
          'input': {'name': '新用户', 'email': 'new@example.com'}
        });
      },
      child: Text('创建用户'),
    );
  },
)
```

### 方式二：手动 HTTP 请求

如果不想引入 graphql_flutter，可以用普通 HTTP 发送 GraphQL 请求：

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> executeGraphQL(
  String query, {
  Map<String, dynamic>? variables,
}) async {
  final response = await http.post(
    Uri.parse('https://api.example.com/graphql'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'query': query,
      'variables': variables,
    }),
  );

  final data = jsonDecode(response.body);
  if (data['errors'] != null) {
    throw Exception(data['errors']);
  }
  return data['data'];
}
```

## 模拟 GraphQL 客户端

示例代码中用模拟方式演示 GraphQL 的工作原理：

```dart
/// GraphQL 请求
class GqlRequest {
  final String query;
  final Map<String, dynamic>? variables;

  Map<String, dynamic> toJson() => {
    'query': query,
    if (variables != null) 'variables': variables,
  };
}

/// GraphQL 响应
class GqlResponse {
  final Map<String, dynamic>? data;
  final List<String>? errors;
  bool get hasErrors => errors != null && errors!.isNotEmpty;
}

/// 模拟客户端 —— 解析查询并返回模拟数据
class MockGraphQLClient {
  Future<GqlResponse> execute(GqlRequest request) async {
    await Future.delayed(Duration(milliseconds: 600));
    // 根据查询内容路由到不同处理器
    if (request.query.contains('GetUsers')) {
      return _handleGetUsers();
    }
    // ...
  }
}
```

## 示例代码说明

`lib/ch07_graphql.dart` 演示了：

- **查询字符串定义**：`GqlQueries` 类中定义了多种 GraphQL 操作
- **请求/响应模型**：`GqlRequest` 和 `GqlResponse`
- **模拟 GraphQL 服务端**：`MockGraphQLClient` 模拟了查询解析和数据返回
- **5 种操作演示**：
  1. `GetUsers` — 查询所有用户
  2. `GetUserById` — 带变量的查询
  3. `GetUserPosts` — 嵌套关联查询
  4. `CreateUser` — Mutation 变更操作
  5. 错误处理 — 查询不存在的数据
- **可视化**：显示发送的 JSON 请求和返回的 JSON 响应

运行方式：
```bash
flutter run -t lib/ch07_graphql.dart
```

## GraphQL 缓存策略

GraphQL 客户端通常使用**标准化缓存**（Normalized Cache）：

```
# 服务端返回：
{
  "user": {
    "id": "1",
    "name": "张三",
    "posts": [
      { "id": "p1", "title": "Hello" }
    ]
  }
}

# 标准化后存储为：
User:1  → { id: "1", name: "张三", posts: [ref("Post:p1")] }
Post:p1 → { id: "p1", title: "Hello" }
```

这样当其他查询更新了 `Post:p1`，所有引用它的地方都会自动更新。

## 最佳实践

1. **按需查询**：只请求 UI 需要的字段，不贪多
2. **使用变量**：避免字符串拼接查询，防止注入
3. **Fragment 复用**：公共字段用 Fragment 抽取
4. **错误处理**：GraphQL 的错误在 `errors` 字段，HTTP 状态码可能仍是 200
5. **分页**：使用 Cursor-based 分页（`first` / `after`）
6. **缓存策略**：合理配置 `fetchPolicy`（`cache-first`、`network-only` 等）
7. **代码生成**：大型项目考虑使用 `graphql_codegen` 自动生成类型安全的代码

## 何时选择 GraphQL

✅ 适合：
- 数据关系复杂、嵌套深
- 移动端需要减少请求次数和数据量
- 多端（Web/iOS/Android）数据需求差异大
- 快速迭代，前端需要灵活调整数据结构

❌ 不太适合：
- 简单 CRUD 应用
- 文件上传为主的场景
- 已有成熟 REST API 且够用
- 团队对 GraphQL 不熟悉且项目紧急
