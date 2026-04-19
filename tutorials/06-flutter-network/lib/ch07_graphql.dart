import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/// 第七章：GraphQL 基础
/// 用模拟方式演示 GraphQL 查询构造、变量、响应解析
/// 实际项目中推荐使用 graphql_flutter 包

void main() => runApp(const Ch07App());

// ============================================================
// GraphQL 查询/变更定义（模拟）
// ============================================================

/// 模拟 GraphQL 查询字符串
class GqlQueries {
  /// 查询所有用户
  static const String getUsers = '''
    query GetUsers {
      users {
        id
        name
        email
        role
      }
    }
  ''';

  /// 带变量的查询 —— 根据 ID 获取用户
  static const String getUserById = '''
    query GetUserById(\$id: ID!) {
      user(id: \$id) {
        id
        name
        email
        role
        posts {
          id
          title
          createdAt
        }
      }
    }
  ''';

  /// 查询用户的文章列表
  static const String getUserPosts = '''
    query GetUserPosts(\$userId: ID!, \$limit: Int) {
      posts(userId: \$userId, limit: \$limit) {
        id
        title
        content
        createdAt
        comments {
          id
          text
        }
      }
    }
  ''';

  /// 变更操作 —— 创建用户
  static const String createUser = '''
    mutation CreateUser(\$input: CreateUserInput!) {
      createUser(input: \$input) {
        id
        name
        email
        role
      }
    }
  ''';
}

// ============================================================
// 模拟 GraphQL 客户端
// ============================================================

/// 模拟的 GraphQL 请求
class GqlRequest {
  final String query;
  final Map<String, dynamic>? variables;

  const GqlRequest({required this.query, this.variables});

  /// 转为 JSON（实际发送给服务器的格式）
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      if (variables != null) 'variables': variables,
    };
  }
}

/// 模拟的 GraphQL 响应
class GqlResponse {
  final Map<String, dynamic>? data;
  final List<String>? errors;

  const GqlResponse({this.data, this.errors});

  bool get hasErrors => errors != null && errors!.isNotEmpty;
}

/// 模拟 GraphQL 客户端 —— 在实际项目中由 graphql_flutter 提供
class MockGraphQLClient {
  /// 模拟数据库
  final List<Map<String, dynamic>> _users = [
    {
      'id': '1',
      'name': '张三',
      'email': 'zhangsan@example.com',
      'role': 'ADMIN',
      'posts': [
        {'id': 'p1', 'title': 'Flutter 入门指南', 'createdAt': '2024-01-15', 'content': '本文介绍 Flutter 的基础知识...', 'comments': [{'id': 'c1', 'text': '写得很好！'}]},
        {'id': 'p2', 'title': 'Dart 语言精髓', 'createdAt': '2024-02-20', 'content': 'Dart 是一门优雅的语言...', 'comments': []},
      ],
    },
    {
      'id': '2',
      'name': '李四',
      'email': 'lisi@example.com',
      'role': 'USER',
      'posts': [
        {'id': 'p3', 'title': 'Widget 深入理解', 'createdAt': '2024-03-10', 'content': 'Widget 是 Flutter 的核心概念...', 'comments': [{'id': 'c2', 'text': '期待后续'}]},
      ],
    },
    {
      'id': '3',
      'name': '王五',
      'email': 'wangwu@example.com',
      'role': 'USER',
      'posts': [],
    },
  ];

  int _nextId = 4;

  /// 执行 GraphQL 请求（模拟服务端处理）
  Future<GqlResponse> execute(GqlRequest request) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 600));

    final query = request.query.trim();

    // 根据查询内容分发处理
    if (query.contains('GetUsers')) {
      return _handleGetUsers();
    } else if (query.contains('GetUserById')) {
      return _handleGetUserById(request.variables);
    } else if (query.contains('GetUserPosts')) {
      return _handleGetUserPosts(request.variables);
    } else if (query.contains('CreateUser')) {
      return _handleCreateUser(request.variables);
    }

    return const GqlResponse(errors: ['未知的查询操作']);
  }

  GqlResponse _handleGetUsers() {
    final userList = _users.map((u) => {
      'id': u['id'],
      'name': u['name'],
      'email': u['email'],
      'role': u['role'],
    }).toList();
    return GqlResponse(data: {'users': userList});
  }

  GqlResponse _handleGetUserById(Map<String, dynamic>? vars) {
    final id = vars?['id']?.toString();
    if (id == null) return const GqlResponse(errors: ['缺少参数 id']);

    final user = _users.where((u) => u['id'] == id).firstOrNull;
    if (user == null) return const GqlResponse(errors: ['用户不存在']);
    return GqlResponse(data: {'user': user});
  }

  GqlResponse _handleGetUserPosts(Map<String, dynamic>? vars) {
    final userId = vars?['userId']?.toString();
    final limit = vars?['limit'] as int? ?? 10;
    if (userId == null) return const GqlResponse(errors: ['缺少参数 userId']);

    final user = _users.where((u) => u['id'] == userId).firstOrNull;
    if (user == null) return const GqlResponse(errors: ['用户不存在']);

    final posts = (user['posts'] as List).take(limit).toList();
    return GqlResponse(data: {'posts': posts});
  }

  GqlResponse _handleCreateUser(Map<String, dynamic>? vars) {
    final input = vars?['input'] as Map<String, dynamic>?;
    if (input == null) return const GqlResponse(errors: ['缺少参数 input']);

    final newUser = {
      'id': '${_nextId++}',
      'name': input['name'] ?? '新用户',
      'email': input['email'] ?? 'new@example.com',
      'role': input['role'] ?? 'USER',
      'posts': <Map<String, dynamic>>[],
    };
    _users.add(newUser);
    return GqlResponse(data: {
      'createUser': {
        'id': newUser['id'],
        'name': newUser['name'],
        'email': newUser['email'],
        'role': newUser['role'],
      }
    });
  }
}

// ============================================================
// UI 层
// ============================================================

class Ch07App extends StatelessWidget {
  const Ch07App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch07 - GraphQL',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const GraphQLDemoPage(),
    );
  }
}

class GraphQLDemoPage extends StatefulWidget {
  const GraphQLDemoPage({super.key});

  @override
  State<GraphQLDemoPage> createState() => _GraphQLDemoPageState();
}

class _GraphQLDemoPageState extends State<GraphQLDemoPage> {
  final MockGraphQLClient _client = MockGraphQLClient();
  bool _loading = false;
  String _queryDisplay = ''; // 显示发送的查询
  String _resultDisplay = ''; // 显示结果
  String? _error;

  /// 执行查询并更新 UI
  Future<void> _executeQuery(GqlRequest request, String label) async {
    setState(() {
      _loading = true;
      _error = null;
      _queryDisplay = '【$label】\n${const JsonEncoder.withIndent('  ').convert(request.toJson())}';
      _resultDisplay = '';
    });

    try {
      final response = await _client.execute(request);
      setState(() {
        _loading = false;
        if (response.hasErrors) {
          _error = response.errors!.join('\n');
        } else {
          _resultDisplay = const JsonEncoder.withIndent('  ').convert(response.data);
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('GraphQL 模拟演示')),
      body: Column(
        children: [
          // 操作按钮
          _buildQueryButtons(colorScheme),
          const Divider(height: 1),
          // 查询和结果显示
          Expanded(child: _buildResultArea(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildQueryButtons(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Query: 获取所有用户
          ActionChip(
            avatar: const Icon(Icons.search, size: 18),
            label: const Text('查询所有用户'),
            onPressed: () => _executeQuery(
              const GqlRequest(query: GqlQueries.getUsers),
              'Query: GetUsers',
            ),
          ),
          // Query: 带变量查询
          ActionChip(
            avatar: const Icon(Icons.person_search, size: 18),
            label: const Text('查询用户(id=1)'),
            onPressed: () => _executeQuery(
              const GqlRequest(
                query: GqlQueries.getUserById,
                variables: {'id': '1'},
              ),
              'Query: GetUserById',
            ),
          ),
          // Query: 嵌套查询
          ActionChip(
            avatar: const Icon(Icons.article, size: 18),
            label: const Text('查询文章(userId=1)'),
            onPressed: () => _executeQuery(
              const GqlRequest(
                query: GqlQueries.getUserPosts,
                variables: {'userId': '1', 'limit': 5},
              ),
              'Query: GetUserPosts',
            ),
          ),
          // Mutation: 创建用户
          ActionChip(
            avatar: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('创建用户(Mutation)'),
            onPressed: () => _executeQuery(
              const GqlRequest(
                query: GqlQueries.createUser,
                variables: {
                  'input': {
                    'name': '新用户',
                    'email': 'newuser@example.com',
                    'role': 'USER',
                  }
                },
              ),
              'Mutation: CreateUser',
            ),
          ),
          // Query: 查询不存在的用户（演示错误）
          ActionChip(
            avatar: const Icon(Icons.error_outline, size: 18),
            label: const Text('查询不存在用户'),
            onPressed: () => _executeQuery(
              const GqlRequest(
                query: GqlQueries.getUserById,
                variables: {'id': '999'},
              ),
              'Query: 错误演示',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 发送的查询
          if (_queryDisplay.isNotEmpty) ...[
            Text('📤 发送的请求',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _queryDisplay,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 加载指示
          if (_loading) const Center(child: CircularProgressIndicator()),
          // 错误信息
          if (_error != null) ...[
            Text('❌ 错误',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.error)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: TextStyle(color: colorScheme.error)),
            ),
          ],
          // 结果
          if (_resultDisplay.isNotEmpty) ...[
            Text('📥 响应数据',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: SelectableText(
                _resultDisplay,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
          // 空状态提示
          if (_queryDisplay.isEmpty && !_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.data_object,
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      '点击上方按钮执行 GraphQL 查询',
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
