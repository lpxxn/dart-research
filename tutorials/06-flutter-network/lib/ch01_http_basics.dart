// ch01_http_basics.dart
// HTTP 基础知识演示应用
//
// 本文件演示了 Flutter 中常用的 HTTP 请求方法：GET、POST、PUT、DELETE。
// 使用 JSONPlaceholder 作为测试 API，展示如何发送请求、解析响应和处理错误。

import 'dart:convert'; // JSON 编解码工具库

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 请求库

// ============================================================================
// 入口函数
// ============================================================================

/// 应用入口，启动 Ch01App
void main() => runApp(const Ch01App());

// ============================================================================
// API 基础地址常量
// ============================================================================

/// JSONPlaceholder API 的基础地址
const String _baseUrl = 'https://jsonplaceholder.typicode.com';

// ============================================================================
// 网络请求辅助函数
// ============================================================================

/// 获取帖子列表（GET 请求）
///
/// 向 /posts 端点发送 GET 请求，限制返回 10 条数据。
/// 包含请求头设置、超时处理和状态码检查。
///
/// 返回值：帖子列表，每个帖子是一个 Map 对象。
/// 异常：当请求失败、超时或状态码非 200 时抛出异常。
Future<List<dynamic>> fetchPosts() async {
  try {
    // 构造请求 URL，使用 _limit 参数限制返回数量
    final uri = Uri.parse('$_baseUrl/posts?_limit=10');

    // 发送 GET 请求，设置请求头并指定 10 秒超时
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    // 检查响应状态码是否为 200（成功）
    if (response.statusCode == 200) {
      // 使用 dart:convert 将 JSON 字符串解析为 Dart 对象
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      // 状态码异常，抛出包含状态码的错误信息
      throw Exception('请求失败，状态码：${response.statusCode}');
    }
  } on http.ClientException catch (e) {
    // 捕获 HTTP 客户端异常（如网络不可达）
    throw Exception('网络请求异常：$e');
  } catch (e) {
    // 捕获其他所有异常（包括超时）
    throw Exception('获取帖子失败：$e');
  }
}

/// 创建新帖子（POST 请求）
///
/// 向 /posts 端点发送 POST 请求，提交新帖子数据。
/// 请求体为 JSON 格式，包含标题和正文。
///
/// 参数：
///   [title] - 帖子标题
///   [body]  - 帖子正文内容
///
/// 返回值：服务器返回的帖子数据（包含新生成的 id）。
/// 异常：当请求失败或状态码非 201 时抛出异常。
Future<Map<String, dynamic>> createPost(String title, String body) async {
  try {
    final uri = Uri.parse('$_baseUrl/posts');

    // 发送 POST 请求，将数据编码为 JSON 字符串放入请求体
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          // 使用 jsonEncode 将 Map 转换为 JSON 字符串
          body: jsonEncode({
            'title': title,
            'body': body,
            'userId': 1, // 模拟用户 ID
          }),
        )
        .timeout(const Duration(seconds: 10));

    // POST 请求成功的状态码通常是 201（已创建）
    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('创建帖子失败，状态码：${response.statusCode}');
    }
  } catch (e) {
    throw Exception('创建帖子异常：$e');
  }
}

/// 更新帖子（PUT 请求）
///
/// 向 /posts/{id} 端点发送 PUT 请求，替换整个帖子资源。
/// PUT 请求要求提供完整的资源数据。
///
/// 参数：
///   [id]    - 要更新的帖子 ID
///   [title] - 新的帖子标题
///   [body]  - 新的帖子正文
///
/// 返回值：更新后的帖子数据。
/// 异常：当请求失败或状态码非 200 时抛出异常。
Future<Map<String, dynamic>> updatePost(
  int id,
  String title,
  String body,
) async {
  try {
    final uri = Uri.parse('$_baseUrl/posts/$id');

    // 发送 PUT 请求，提供完整的资源数据
    final response = await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'id': id,
            'title': title,
            'body': body,
            'userId': 1,
          }),
        )
        .timeout(const Duration(seconds: 10));

    // PUT 请求成功返回 200
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('更新帖子失败，状态码：${response.statusCode}');
    }
  } catch (e) {
    throw Exception('更新帖子异常：$e');
  }
}

/// 删除帖子（DELETE 请求）
///
/// 向 /posts/{id} 端点发送 DELETE 请求，删除指定帖子。
///
/// 参数：
///   [id] - 要删除的帖子 ID
///
/// 返回值：删除成功返回 true。
/// 异常：当请求失败或状态码非 200 时抛出异常。
Future<bool> deletePost(int id) async {
  try {
    final uri = Uri.parse('$_baseUrl/posts/$id');

    // 发送 DELETE 请求
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    // DELETE 请求成功返回 200
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('删除帖子失败，状态码：${response.statusCode}');
    }
  } catch (e) {
    throw Exception('删除帖子异常：$e');
  }
}

// ============================================================================
// 应用根组件
// ============================================================================

/// Ch01App - 应用的根组件
///
/// 使用 MaterialApp 作为应用框架，配置主题和首页。
class Ch01App extends StatelessWidget {
  const Ch01App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP 基础演示',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用 ColorScheme.fromSeed 生成配色方案
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Ch01HomePage(),
    );
  }
}

// ============================================================================
// 首页 - 带有标签栏的页面
// ============================================================================

/// Ch01HomePage - 首页，包含三个标签页
///
/// 使用 TabController 管理标签页切换，展示 GET、POST、PUT/DELETE 三种请求方式。
class Ch01HomePage extends StatefulWidget {
  const Ch01HomePage({super.key});

  @override
  State<Ch01HomePage> createState() => _Ch01HomePageState();
}

/// Ch01HomePage 的状态类
///
/// 混入 SingleTickerProviderStateMixin 以提供 TabController 所需的 Ticker。
class _Ch01HomePageState extends State<Ch01HomePage>
    with SingleTickerProviderStateMixin {
  /// 标签控制器，管理三个标签页的切换动画和状态
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始化 TabController，设置标签页数量为 3
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // 释放 TabController 资源，防止内存泄漏
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的配色方案
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('第一章：HTTP 基础'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        // 底部放置标签栏
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onPrimaryContainer,
          unselectedLabelColor: Color.fromRGBO(
            colorScheme.onPrimaryContainer.r.toInt(),
            colorScheme.onPrimaryContainer.g.toInt(),
            colorScheme.onPrimaryContainer.b.toInt(),
            0.6,
          ),
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.download), text: 'GET 请求'),
            Tab(icon: Icon(Icons.upload), text: 'POST 请求'),
            Tab(icon: Icon(Icons.edit), text: 'PUT/DELETE'),
          ],
        ),
      ),
      // 标签页视图，每个标签对应一个演示组件
      body: TabBarView(
        controller: _tabController,
        children: const [
          GetRequestDemo(), // 第一个标签：GET 请求演示
          PostRequestDemo(), // 第二个标签：POST 请求演示
          PutDeleteDemo(), // 第三个标签：PUT/DELETE 请求演示
        ],
      ),
    );
  }
}

// ============================================================================
// 标签页 1：GET 请求演示
// ============================================================================

/// GetRequestDemo - GET 请求演示组件
///
/// 使用 FutureBuilder 异步获取帖子列表并展示在 ListView 中。
/// 展示了 GET 请求的完整流程：发送请求 -> 等待响应 -> 解析数据 -> 渲染界面。
class GetRequestDemo extends StatefulWidget {
  const GetRequestDemo({super.key});

  @override
  State<GetRequestDemo> createState() => _GetRequestDemoState();
}

class _GetRequestDemoState extends State<GetRequestDemo>
    with AutomaticKeepAliveClientMixin {
  /// 存储异步请求的 Future 对象，供 FutureBuilder 使用
  late Future<List<dynamic>> _postsFuture;

  @override
  bool get wantKeepAlive => true; // 保持标签页状态，切换时不重新加载

  @override
  void initState() {
    super.initState();
    // 初始化时发起网络请求
    _postsFuture = fetchPosts();
  }

  /// 刷新数据，重新发起 GET 请求
  void _refresh() {
    setState(() {
      _postsFuture = fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求调用 super.build
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 顶部说明区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Color.fromRGBO(0, 150, 136, 0.08),
          child: const Text(
            '📡 GET 请求演示\n'
            '从 JSONPlaceholder API 获取帖子列表（限制 10 条）。\n'
            '使用 FutureBuilder 管理异步状态。',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        // 刷新按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('重新获取'),
              ),
            ],
          ),
        ),
        // 帖子列表区域，使用 FutureBuilder 处理异步数据
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              // 状态一：加载中，显示进度指示器
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在获取数据...'),
                    ],
                  ),
                );
              }

              // 状态二：请求出错，显示错误信息
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          '请求失败',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 状态三：数据为空
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('暂无数据'));
              }

              // 状态四：数据加载成功，渲染列表
              final posts = snapshot.data!;
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final post = posts[index] as Map<String, dynamic>;
                  return _PostCard(
                    index: index + 1,
                    title: post['title'] as String? ?? '',
                    body: post['body'] as String? ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// _PostCard - 帖子卡片组件
///
/// 以卡片形式展示单条帖子的标题和正文。
class _PostCard extends StatelessWidget {
  /// 帖子序号
  final int index;

  /// 帖子标题
  final String title;

  /// 帖子正文
  final String body;

  const _PostCard({
    required this.index,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 帖子标题行：序号 + 标题
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 序号徽章
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 标题文本
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 帖子正文，限制最多显示 3 行
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 标签页 2：POST 请求演示
// ============================================================================

/// PostRequestDemo - POST 请求演示组件
///
/// 提供表单让用户输入标题和正文，点击提交后发送 POST 请求。
/// 请求成功后通过 SnackBar 显示服务器返回的结果。
class PostRequestDemo extends StatefulWidget {
  const PostRequestDemo({super.key});

  @override
  State<PostRequestDemo> createState() => _PostRequestDemoState();
}

class _PostRequestDemoState extends State<PostRequestDemo>
    with AutomaticKeepAliveClientMixin {
  /// 标题输入框控制器
  final _titleController = TextEditingController();

  /// 正文输入框控制器
  final _bodyController = TextEditingController();

  /// 表单全局 Key，用于表单验证
  final _formKey = GlobalKey<FormState>();

  /// 是否正在提交请求
  bool _isSubmitting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // 释放输入框控制器资源
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// 提交表单，发送 POST 请求创建新帖子
  Future<void> _submitForm() async {
    // 先验证表单是否合法
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 调用 createPost 函数发送 POST 请求
      final result = await createPost(
        _titleController.text.trim(),
        _bodyController.text.trim(),
      );

      // 检查组件是否还挂载在树上（防止异步回调后组件已销毁）
      if (!mounted) return;

      // 使用 SnackBar 展示创建成功的结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ 创建成功！\n'
            '返回 ID: ${result['id']}\n'
            '标题: ${result['title']}',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 清空表单
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;

      // 请求失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 请求失败：$e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部说明区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(63, 81, 181, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '📤 POST 请求演示\n'
              '填写表单后提交，将数据以 JSON 格式发送到服务器。\n'
              '服务器返回新创建资源的信息（包含自动生成的 ID）。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // 表单区域
          Form(
            key: _formKey,
            child: Column(
              children: [
                // 标题输入框
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '帖子标题',
                    hintText: '请输入帖子标题',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  // 表单验证：标题不能为空
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '标题不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 正文输入框
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: '帖子正文',
                    hintText: '请输入帖子正文内容',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.article),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  // 表单验证：正文不能为空
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '正文不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? '提交中...' : '发送 POST 请求'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 底部提示信息：展示将要发送的 JSON 格式
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 请求格式预览',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'POST /posts HTTP/1.1\n'
                      'Content-Type: application/json\n'
                      '\n'
                      '{\n'
                      '  "title": "你输入的标题",\n'
                      '  "body": "你输入的正文",\n'
                      '  "userId": 1\n'
                      '}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
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

// ============================================================================
// 标签页 3：PUT/DELETE 请求演示
// ============================================================================

/// PutDeleteDemo - PUT 和 DELETE 请求演示组件
///
/// 提供两个操作按钮：
/// 1. PUT 按钮 - 更新帖子（替换 /posts/1 的数据）
/// 2. DELETE 按钮 - 删除帖子（删除 /posts/1）
/// 操作结果实时显示在下方的结果区域中。
class PutDeleteDemo extends StatefulWidget {
  const PutDeleteDemo({super.key});

  @override
  State<PutDeleteDemo> createState() => _PutDeleteDemoState();
}

class _PutDeleteDemoState extends State<PutDeleteDemo>
    with AutomaticKeepAliveClientMixin {
  /// 操作结果文本，用于展示请求的返回内容
  String _resultText = '点击上方按钮执行操作，结果将在此显示。';

  /// 是否正在执行 PUT 请求
  bool _isPutLoading = false;

  /// 是否正在执行 DELETE 请求
  bool _isDeleteLoading = false;

  @override
  bool get wantKeepAlive => true;

  /// 执行 PUT 请求，更新 id=1 的帖子
  Future<void> _doPut() async {
    setState(() {
      _isPutLoading = true;
      _resultText = '⏳ 正在发送 PUT 请求...';
    });

    try {
      // 调用 updatePost 函数发送 PUT 请求
      final result = await updatePost(
        1,
        '更新后的标题 - Flutter HTTP 演示',
        '这是通过 PUT 请求更新的正文内容。PUT 会替换整个资源。',
      );

      setState(() {
        // 格式化显示返回的 JSON 数据
        final prettyJson = const JsonEncoder.withIndent('  ').convert(result);
        _resultText = '✅ PUT 请求成功！\n\n'
            '请求：PUT /posts/1\n'
            '响应数据：\n$prettyJson';
      });
    } catch (e) {
      setState(() {
        _resultText = '❌ PUT 请求失败\n\n错误信息：$e';
      });
    } finally {
      setState(() => _isPutLoading = false);
    }
  }

  /// 执行 DELETE 请求，删除 id=1 的帖子
  Future<void> _doDelete() async {
    setState(() {
      _isDeleteLoading = true;
      _resultText = '⏳ 正在发送 DELETE 请求...';
    });

    try {
      // 调用 deletePost 函数发送 DELETE 请求
      final success = await deletePost(1);

      setState(() {
        if (success) {
          _resultText = '✅ DELETE 请求成功！\n\n'
              '请求：DELETE /posts/1\n'
              '帖子 #1 已成功删除。\n\n'
              '注意：JSONPlaceholder 是模拟 API，\n'
              '实际数据并未真正删除。';
        }
      });
    } catch (e) {
      setState(() {
        _resultText = '❌ DELETE 请求失败\n\n错误信息：$e';
      });
    } finally {
      setState(() => _isDeleteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部说明区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 152, 0, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🔄 PUT / DELETE 请求演示\n'
              'PUT：用新数据完全替换服务器上的资源。\n'
              'DELETE：删除服务器上的指定资源。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // PUT 请求操作卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'PUT 请求 - 更新资源',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '将 /posts/1 的标题和正文替换为新内容。',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isPutLoading ? null : _doPut,
                      icon: _isPutLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label:
                          Text(_isPutLoading ? '请求中...' : '发送 PUT 请求'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // DELETE 请求操作卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.delete_outline, color: colorScheme.error),
                      const SizedBox(width: 8),
                      const Text(
                        'DELETE 请求 - 删除资源',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '删除 /posts/1 资源（模拟操作，不会真正删除）。',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _isDeleteLoading ? null : _doDelete,
                      icon: _isDeleteLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever),
                      label: Text(
                          _isDeleteLoading ? '请求中...' : '发送 DELETE 请求'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 结果显示区域
          Text(
            '📊 操作结果',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.fromRGBO(0, 0, 0, 0.1),
              ),
            ),
            child: SelectableText(
              _resultText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
