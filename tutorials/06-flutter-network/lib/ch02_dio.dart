import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// ============================================================
// DioClient: 封装 Dio 的单例客户端
// ============================================================

/// 自定义认证拦截器，为每个请求添加假的 Token
class AuthInterceptor extends Interceptor {
  final void Function(String log)? onLog;

  AuthInterceptor({this.onLog});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer fake_token_abc123';
    onLog?.call('[Auth] 添加 Token 到请求: ${options.method} ${options.path}');
    handler.next(options);
  }
}

/// 自定义错误拦截器，处理各种 DioException 类型
class ErrorInterceptor extends Interceptor {
  final void Function(String log)? onLog;

  ErrorInterceptor({this.onLog});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _mapError(err);
    onLog?.call('[Error] $message');
    handler.next(err);
  }

  static String _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送超时，请稍后重试';
      case DioExceptionType.receiveTimeout:
        return '接收超时，服务器响应太慢';
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return '服务器错误: $code';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '无法连接到服务器';
      case DioExceptionType.badCertificate:
        return '证书验证失败';
      case DioExceptionType.unknown:
        return '未知错误: ${err.message}';
    }
  }

  /// 将 DioException 转换为用户友好的消息
  static String friendlyMessage(DioException err) => _mapError(err);
}

/// 简单的日志拦截器，记录请求和响应信息
class SimpleLogInterceptor extends Interceptor {
  final void Function(String log)? onLog;

  SimpleLogInterceptor({this.onLog});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final msg =
        '[Request] ${options.method} ${options.baseUrl}${options.path}';
    debugPrint(msg);
    onLog?.call(msg);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final msg =
        '[Response] ${response.statusCode} ${response.requestOptions.path}';
    debugPrint(msg);
    onLog?.call(msg);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final msg = '[Log] 请求出错: ${err.type} ${err.requestOptions.path}';
    debugPrint(msg);
    onLog?.call(msg);
    handler.next(err);
  }
}

/// DioClient 单例，封装 Dio 的常用操作
class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio dio;

  /// 拦截器日志收集器，外部可监听
  final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>([]);

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 添加日志拦截器
    dio.interceptors.add(SimpleLogInterceptor(onLog: _addLog));
    // 添加认证拦截器
    dio.interceptors.add(AuthInterceptor(onLog: _addLog));
    // 添加错误拦截器
    dio.interceptors.add(ErrorInterceptor(onLog: _addLog));
  }

  void _addLog(String log) {
    logs.value = [...logs.value, log];
  }

  /// 清空日志
  void clearLogs() {
    logs.value = [];
  }

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException {
      rethrow;
    }
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post(path, data: data, cancelToken: cancelToken);
    } on DioException {
      rethrow;
    }
  }

  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.put(path, data: data, cancelToken: cancelToken);
    } on DioException {
      rethrow;
    }
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete(path, data: data, cancelToken: cancelToken);
    } on DioException {
      rethrow;
    }
  }
}

// ============================================================
// 入口
// ============================================================

void main() => runApp(const Ch02App());

class Ch02App extends StatelessWidget {
  const Ch02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dio 网络请求示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Ch02HomePage(),
    );
  }
}

// ============================================================
// 主页：包含三个 Tab
// ============================================================

class Ch02HomePage extends StatefulWidget {
  const Ch02HomePage({super.key});

  @override
  State<Ch02HomePage> createState() => _Ch02HomePageState();
}

class _Ch02HomePageState extends State<Ch02HomePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ch02 Dio 示例'),
        backgroundColor: colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.cloud_download), text: '基本请求'),
            Tab(icon: Icon(Icons.bug_report), text: '拦截器演示'),
            Tab(icon: Icon(Icons.cancel), text: '取消请求'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BasicRequestTab(),
          _InterceptorTab(),
          _CancelTokenTab(),
        ],
      ),
    );
  }
}

// ============================================================
// Tab 1: 基本请求 - 使用 FutureBuilder 展示 posts 列表
// ============================================================

class _BasicRequestTab extends StatefulWidget {
  const _BasicRequestTab();

  @override
  State<_BasicRequestTab> createState() => _BasicRequestTabState();
}

class _BasicRequestTabState extends State<_BasicRequestTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<dynamic>> _postsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<dynamic>> _fetchPosts() async {
    // 只获取前 20 条，避免数据过多
    final response = await DioClient().get(
      '/posts',
      queryParameters: {'_limit': 20},
    );
    return response.data as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 刷新按钮
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _postsFuture = _fetchPosts();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final errMsg = snapshot.error is DioException
                    ? ErrorInterceptor.friendlyMessage(
                        snapshot.error! as DioException,
                      )
                    : snapshot.error.toString();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '加载失败: $errMsg',
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(child: Text('暂无数据'));
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.secondaryContainer,
                        child: Text('${post['id']}'),
                      ),
                      title: Text(
                        post['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        post['body'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

// ============================================================
// Tab 2: 拦截器演示 - 展示拦截器日志
// ============================================================

class _InterceptorTab extends StatefulWidget {
  const _InterceptorTab();

  @override
  State<_InterceptorTab> createState() => _InterceptorTabState();
}

class _InterceptorTabState extends State<_InterceptorTab>
    with AutomaticKeepAliveClientMixin {
  final DioClient _client = DioClient();
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  /// 发起 GET 请求，触发拦截器
  Future<void> _triggerGet() async {
    setState(() => _loading = true);
    try {
      await _client.get('/posts/1');
    } on DioException {
      // 错误已在拦截器中记录
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 发起 POST 请求，触发拦截器
  Future<void> _triggerPost() async {
    setState(() => _loading = true);
    try {
      await _client.post('/posts', data: {
        'title': '测试标题',
        'body': '测试内容',
        'userId': 1,
      });
    } on DioException {
      // 错误已在拦截器中记录
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 触发一个会失败的请求（404）
  Future<void> _triggerError() async {
    setState(() => _loading = true);
    try {
      await _client.get('/not-exist-endpoint');
    } on DioException {
      // 错误已在拦截器中记录
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 操作按钮区域
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _triggerGet,
                icon: const Icon(Icons.download),
                label: const Text('GET 请求'),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _triggerPost,
                icon: const Icon(Icons.upload),
                label: const Text('POST 请求'),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _triggerError,
                icon: const Icon(Icons.error_outline),
                label: const Text('错误请求'),
              ),
              OutlinedButton.icon(
                onPressed: () => _client.clearLogs(),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('清空日志'),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        const Divider(),
        // 日志列表
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _client.logs,
            builder: (context, logList, _) {
              if (logList.isEmpty) {
                return Center(
                  child: Text(
                    '暂无日志，点击上方按钮触发请求',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: logList.length,
                itemBuilder: (context, index) {
                  final log = logList[index];
                  // 根据日志类型选择颜色
                  Color bgColor;
                  if (log.startsWith('[Auth]')) {
                    bgColor = Colors.orange.withValues(alpha: 0.15);
                  } else if (log.startsWith('[Error]') ||
                      log.startsWith('[Log] 请求出错')) {
                    bgColor = Colors.red.withValues(alpha: 0.15);
                  } else if (log.startsWith('[Response]')) {
                    bgColor = Colors.green.withValues(alpha: 0.15);
                  } else {
                    bgColor = Colors.blue.withValues(alpha: 0.1);
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}  $log',
                      style: const TextStyle(fontSize: 13),
                    ),
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

// ============================================================
// Tab 3: 取消请求 - 使用 CancelToken 演示搜索取消
// ============================================================

class _CancelTokenTab extends StatefulWidget {
  const _CancelTokenTab();

  @override
  State<_CancelTokenTab> createState() => _CancelTokenTabState();
}

class _CancelTokenTabState extends State<_CancelTokenTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final DioClient _client = DioClient();

  CancelToken? _cancelToken;
  List<dynamic> _results = [];
  bool _loading = false;
  String _statusMessage = '输入关键词搜索文章';

  @override
  bool get wantKeepAlive => true;

  /// 搜索方法：取消上一次请求，发起新请求
  Future<void> _search(String query) async {
    // 取消正在进行的请求
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('新的搜索请求，取消上一个');
    }

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _statusMessage = '输入关键词搜索文章';
        _loading = false;
      });
      return;
    }

    // 创建新的 CancelToken
    _cancelToken = CancelToken();
    setState(() {
      _loading = true;
      _statusMessage = '正在搜索 "$query"...';
    });

    try {
      final response = await _client.get(
        '/posts',
        queryParameters: {'_limit': 10},
        cancelToken: _cancelToken,
      );
      final allPosts = response.data as List<dynamic>;
      // 本地过滤标题（jsonplaceholder 不支持 title_like）
      final filtered = allPosts.where((post) {
        final title = (post['title'] ?? '') as String;
        return title.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = filtered;
        _loading = false;
        _statusMessage = '找到 ${filtered.length} 条结果';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.cancel) {
        // 被取消的请求不更新 UI，因为新请求正在进行
        debugPrint('请求已取消: ${e.message}');
      } else {
        setState(() {
          _loading = false;
          _statusMessage = ErrorInterceptor.friendlyMessage(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('页面销毁');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '输入关键词搜索（如 qui, est, aut）',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _search('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
            ),
            onChanged: _search,
          ),
        ),
        // 状态信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_loading) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        // 搜索结果列表
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loading ? '搜索中...' : '没有搜索结果',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final post = _results[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.tertiaryContainer,
                          child: Text('${post['id']}'),
                        ),
                        title: Text(
                          post['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          post['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
