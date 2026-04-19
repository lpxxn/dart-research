import 'dart:convert';
import 'package:flutter/material.dart';

// ============================================================
// 入口
// ============================================================

void main() => runApp(const Ch03App());

// ============================================================
// 数据模型
// ============================================================

/// 地址模型
class Address {
  final String street;
  final String city;
  final String zipcode;

  const Address({
    required this.street,
    required this.city,
    required this.zipcode,
  });

  /// 从 JSON Map 创建 Address 实例
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      zipcode: json['zipcode'] as String,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'zipcode': zipcode,
    };
  }

  @override
  String toString() => 'Address(street: $street, city: $city, zipcode: $zipcode)';
}

/// 用户模型（嵌套 Address）
class User {
  final int id;
  final String name;
  final String email;
  final Address? address;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address,
  });

  /// 从 JSON Map 创建 User 实例，嵌套解析 Address
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address?.toJson(),
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, address: $address)';
}

/// 文章模型
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// 从 JSON Map 创建 Post 实例
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }

  @override
  String toString() => 'Post(id: $id, userId: $userId, title: $title)';
}

/// 泛型 API 响应包装
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// 从 JSON Map 创建 ApiResponse 实例
  /// [dataFromJson] 回调用于将 data 字段反序列化为泛型 T
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) dataFromJson,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null ? dataFromJson(json['data']) : null,
    );
  }

  @override
  String toString() => 'ApiResponse(code: $code, message: $message, data: $data)';
}

// ============================================================
// 硬编码的 JSON 测试数据
// ============================================================

/// 基础用户 JSON（无地址）
const String _userJson = '''
{
  "id": 1,
  "name": "张三",
  "email": "zhangsan@example.com",
  "address": null
}''';

/// 文章 JSON
const String _postJson = '''
{
  "id": 101,
  "userId": 1,
  "title": "Flutter JSON 序列化入门",
  "body": "本文介绍如何在 Flutter 中手动实现 JSON 的序列化与反序列化。"
}''';

/// 带嵌套地址的用户 JSON
const String _userWithAddressJson = '''
{
  "id": 2,
  "name": "李四",
  "email": "lisi@example.com",
  "address": {
    "street": "中关村大街1号",
    "city": "北京",
    "zipcode": "100080"
  }
}''';

/// 用户列表 JSON
const String _userListJson = '''
[
  {
    "id": 1,
    "name": "张三",
    "email": "zhangsan@example.com",
    "address": null
  },
  {
    "id": 2,
    "name": "李四",
    "email": "lisi@example.com",
    "address": {
      "street": "中关村大街1号",
      "city": "北京",
      "zipcode": "100080"
    }
  },
  {
    "id": 3,
    "name": "王五",
    "email": "wangwu@example.com",
    "address": {
      "street": "南京路100号",
      "city": "上海",
      "zipcode": "200000"
    }
  }
]''';

/// 泛型响应 — 单个用户
const String _apiResponseUserJson = '''
{
  "code": 200,
  "message": "请求成功",
  "data": {
    "id": 1,
    "name": "张三",
    "email": "zhangsan@example.com",
    "address": null
  }
}''';

/// 泛型响应 — 文章列表
const String _apiResponsePostsJson = '''
{
  "code": 200,
  "message": "获取文章列表成功",
  "data": [
    {
      "id": 101,
      "userId": 1,
      "title": "Flutter 入门指南",
      "body": "Flutter 是 Google 推出的跨平台 UI 框架。"
    },
    {
      "id": 102,
      "userId": 2,
      "title": "Dart 语言基础",
      "body": "Dart 是一门面向对象的编程语言。"
    }
  ]
}''';

// ============================================================
// 应用入口 Widget
// ============================================================

class Ch03App extends StatelessWidget {
  const Ch03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch03 JSON 序列化',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

// ============================================================
// 首页 — 带 TabBar
// ============================================================

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = <Tab>[
    Tab(text: '基础序列化'),
    Tab(text: '嵌套对象'),
    Tab(text: 'List 序列化'),
    Tab(text: '泛型响应'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON 序列化演示'),
        bottom: TabBar(controller: _tabController, tabs: _tabs, isScrollable: true),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BasicTab(),
          _NestedTab(),
          _ListTab(),
          _GenericTab(),
        ],
      ),
    );
  }
}

// ============================================================
// 通用卡片组件 — 显示「原始 JSON」和「解析结果」
// ============================================================

class _JsonCard extends StatelessWidget {
  final String title;
  final String rawJson;
  final List<Widget> parsedChildren;

  const _JsonCard({
    required this.title,
    required this.rawJson,
    required this.parsedChildren,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),

            // 原始 JSON 区域
            Text('📄 原始 JSON', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                rawJson.trim(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            // 解析结果区域
            Text('✅ 解析结果', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ...parsedChildren,
          ],
        ),
      ),
    );
  }
}

/// 显示 key-value 的小组件
class _KVRow extends StatelessWidget {
  final String label;
  final String value;

  const _KVRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 1 — 基础序列化
// ============================================================

class _BasicTab extends StatelessWidget {
  const _BasicTab();

  @override
  Widget build(BuildContext context) {
    // 解析用户 JSON
    final userMap = jsonDecode(_userJson) as Map<String, dynamic>;
    final user = User.fromJson(userMap);
    // 重新序列化
    final userReJson = const JsonEncoder.withIndent('  ').convert(user.toJson());

    // 解析文章 JSON
    final postMap = jsonDecode(_postJson) as Map<String, dynamic>;
    final post = Post.fromJson(postMap);
    final postReJson = const JsonEncoder.withIndent('  ').convert(post.toJson());

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 用户基础序列化卡片
        _JsonCard(
          title: 'User 序列化 / 反序列化',
          rawJson: _userJson,
          parsedChildren: [
            _KVRow('id', '${user.id}'),
            _KVRow('name', user.name),
            _KVRow('email', user.email),
            _KVRow('address', '${user.address ?? "null"}'),
            const SizedBox(height: 8),
            Text('🔄 重新序列化 (toJson)', style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 128, 0, 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color.fromRGBO(0, 128, 0, 0.2)),
              ),
              child: SelectableText(
                userReJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),

        // 文章基础序列化卡片
        _JsonCard(
          title: 'Post 序列化 / 反序列化',
          rawJson: _postJson,
          parsedChildren: [
            _KVRow('id', '${post.id}'),
            _KVRow('userId', '${post.userId}'),
            _KVRow('title', post.title),
            _KVRow('body', post.body),
            const SizedBox(height: 8),
            Text('🔄 重新序列化 (toJson)', style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 128, 0, 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color.fromRGBO(0, 128, 0, 0.2)),
              ),
              child: SelectableText(
                postReJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// Tab 2 — 嵌套对象
// ============================================================

class _NestedTab extends StatelessWidget {
  const _NestedTab();

  @override
  Widget build(BuildContext context) {
    final userMap = jsonDecode(_userWithAddressJson) as Map<String, dynamic>;
    final user = User.fromJson(userMap);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _JsonCard(
          title: '嵌套对象解析 — User + Address',
          rawJson: _userWithAddressJson,
          parsedChildren: [
            _KVRow('id', '${user.id}'),
            _KVRow('name', user.name),
            _KVRow('email', user.email),
            const Divider(),
            Text('📍 嵌套 Address 字段',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.tertiary,
                )),
            const SizedBox(height: 4),
            if (user.address != null) ...[
              _KVRow('street', user.address!.street),
              _KVRow('city', user.address!.city),
              _KVRow('zipcode', user.address!.zipcode),
            ],
            const SizedBox(height: 8),
            Text('🔄 重新序列化 (toJson)', style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 128, 0, 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color.fromRGBO(0, 128, 0, 0.2)),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(user.toJson()),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// Tab 3 — List 序列化
// ============================================================

class _ListTab extends StatelessWidget {
  const _ListTab();

  @override
  Widget build(BuildContext context) {
    // 解析 JSON 数组为 List<User>
    final list = jsonDecode(_userListJson) as List<dynamic>;
    final users = list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();

    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 原始 JSON 卡片
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('List<User> 序列化',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                Text('📄 原始 JSON 数组', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _userListJson.trim(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Text('共解析 ${users.length} 个用户',
                    style: TextStyle(color: colorScheme.secondary)),
              ],
            ),
          ),
        ),

        // 每个用户一张卡片
        ...users.map((user) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text('${user.id}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: user.address != null
                    ? Tooltip(
                        message: '${user.address!.city} ${user.address!.street}',
                        child: Icon(Icons.location_on, color: colorScheme.tertiary),
                      )
                    : const Icon(Icons.location_off_outlined, color: Colors.grey),
              ),
            )),
      ],
    );
  }
}

// ============================================================
// Tab 4 — 泛型响应
// ============================================================

class _GenericTab extends StatelessWidget {
  const _GenericTab();

  @override
  Widget build(BuildContext context) {
    // 解析 ApiResponse<User>
    final userRespMap = jsonDecode(_apiResponseUserJson) as Map<String, dynamic>;
    final userResp = ApiResponse<User>.fromJson(
      userRespMap,
      (data) => User.fromJson(data as Map<String, dynamic>),
    );

    // 解析 ApiResponse<List<Post>>
    final postsRespMap = jsonDecode(_apiResponsePostsJson) as Map<String, dynamic>;
    final postsResp = ApiResponse<List<Post>>.fromJson(
      postsRespMap,
      (data) => (data as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ApiResponse<User> 卡片
        _JsonCard(
          title: 'ApiResponse<User>',
          rawJson: _apiResponseUserJson,
          parsedChildren: [
            _KVRow('code', '${userResp.code}'),
            _KVRow('message', userResp.message),
            const Divider(),
            Text('📦 data (User)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.tertiary,
                )),
            const SizedBox(height: 4),
            if (userResp.data != null) ...[
              _KVRow('id', '${userResp.data!.id}'),
              _KVRow('name', userResp.data!.name),
              _KVRow('email', userResp.data!.email),
            ],
          ],
        ),

        // ApiResponse<List<Post>> 卡片
        _JsonCard(
          title: 'ApiResponse<List<Post>>',
          rawJson: _apiResponsePostsJson,
          parsedChildren: [
            _KVRow('code', '${postsResp.code}'),
            _KVRow('message', postsResp.message),
            const Divider(),
            Text('📦 data (List<Post>，共 ${postsResp.data?.length ?? 0} 篇)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.tertiary,
                )),
            const SizedBox(height: 4),
            if (postsResp.data != null)
              ...postsResp.data!.map((post) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KVRow('id', '${post.id}'),
                        _KVRow('userId', '${post.userId}'),
                        _KVRow('title', post.title),
                        _KVRow('body', post.body),
                      ],
                    ),
                  )),
          ],
        ),
      ],
    );
  }
}
