# 第2章：Dio 进阶网络请求

> 📁 本章配套代码位于 `lib/ch02_dio.dart`

在上一章中，我们学习了 Dart 原生 `http` 包的基本用法。虽然 `http` 包能满足简单的网络请求需求，但在实际项目中，我们往往需要更强大的功能：拦截器、请求取消、文件上传下载、全局配置等。这就是 **Dio** 登场的时候了。

---

## 2.1 Dio 简介与为什么选择 Dio

[Dio](https://pub.dev/packages/dio) 是 Flutter/Dart 生态中最流行的 HTTP 客户端库，由中国开发者社区维护，功能丰富、扩展性强。

### Dio vs http 包对比

| 功能特性 | `http` 包 | `dio` 包 |
|---------|-----------|----------|
| 基本 GET/POST 请求 | ✅ 支持 | ✅ 支持 |
| 拦截器（Interceptor） | ❌ 不支持 | ✅ 强大的拦截器链 |
| 请求取消（CancelToken） | ❌ 不支持 | ✅ 支持 |
| 文件上传（FormData） | ⚠️ 需手动构建 MultipartRequest | ✅ 内置 FormData，使用简单 |
| 文件下载与进度监听 | ❌ 不支持 | ✅ 支持下载 + 进度回调 |
| 全局配置（BaseOptions） | ❌ 不支持 | ✅ baseUrl、超时、默认 headers |
| 请求/响应转换器 | ❌ 不支持 | ✅ 自定义 Transformer |
| 自动 JSON 序列化 | ❌ 需手动 jsonDecode | ✅ 自动解析 JSON |
| 超时设置 | ⚠️ 仅支持整体超时 | ✅ 连接超时、接收超时、发送超时 |
| 重试机制 | ❌ 需自行实现 | ✅ 可通过拦截器优雅实现 |
| 社区生态 | 官方维护，较轻量 | 社区活跃，插件丰富 |
| 包大小 | 🟢 轻量 | 🟡 稍大，但功能更全 |
| 学习曲线 | 🟢 简单 | 🟡 稍有学习成本，但值得 |

**总结**：如果你只是做简单的 API 调用，`http` 包足够了；但如果你在构建一个正式的 Flutter 项目，**Dio 是更好的选择**，它的拦截器、取消请求、文件上传下载等功能会让你的开发效率大幅提升。

---

## 2.2 安装和基本配置

### 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  dio: ^5.4.0
```

然后运行：

```bash
flutter pub get
```

### 基本配置（BaseOptions）

Dio 的核心配置通过 `BaseOptions` 来设置，它包含了所有请求的默认参数：

```dart
import 'package:dio/dio.dart';

// 创建 Dio 实例并配置 BaseOptions
final dio = Dio(BaseOptions(
  // 基础 URL，后续请求只需写相对路径
  baseUrl: 'https://jsonplaceholder.typicode.com',

  // 连接超时时间（与服务器建立连接的最大等待时间）
  connectTimeout: const Duration(seconds: 10),

  // 接收超时时间（等待服务器响应数据的最大时间）
  receiveTimeout: const Duration(seconds: 15),

  // 发送超时时间（发送请求数据的最大时间，上传大文件时需要调大）
  sendTimeout: const Duration(seconds: 10),

  // 默认请求头，所有请求都会携带这些 headers
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-App-Version': '1.0.0',
  },

  // 响应类型，默认为 JSON
  responseType: ResponseType.json,

  // 验证状态码：自定义哪些状态码被视为成功
  // 默认情况下 200-299 是成功的
  validateStatus: (status) {
    return status != null && status < 500;
  },
));
```

### BaseOptions 常用属性详解

| 属性 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `baseUrl` | `String` | 基础 URL，拼接在路径前 | `'https://api.example.com'` |
| `connectTimeout` | `Duration` | 连接超时 | `Duration(seconds: 10)` |
| `receiveTimeout` | `Duration` | 接收超时 | `Duration(seconds: 15)` |
| `sendTimeout` | `Duration` | 发送超时 | `Duration(seconds: 10)` |
| `headers` | `Map<String, dynamic>` | 默认请求头 | `{'Authorization': 'Bearer xxx'}` |
| `responseType` | `ResponseType` | 响应类型 | `ResponseType.json` |
| `contentType` | `String` | 请求内容类型 | `'application/json'` |
| `queryParameters` | `Map<String, dynamic>` | 默认查询参数 | `{'api_key': 'xxx'}` |

> 💡 **提示**：`baseUrl` 设置后，发起请求时只需写相对路径。例如 `dio.get('/posts')` 实际请求的是 `https://jsonplaceholder.typicode.com/posts`。

---

## 2.3 基本请求（GET / POST / PUT / DELETE）

### GET 请求

```dart
/// 获取帖子列表
Future<void> fetchPosts() async {
  try {
    // 基本 GET 请求
    final response = await dio.get('/posts');
    print('状态码: ${response.statusCode}');
    print('帖子数量: ${(response.data as List).length}');

    // 带查询参数的 GET 请求
    final response2 = await dio.get(
      '/posts',
      queryParameters: {
        'userId': 1,    // 筛选用户 ID 为 1 的帖子
        '_limit': 5,    // 限制返回 5 条
      },
    );
    print('用户1的帖子数量: ${(response2.data as List).length}');
  } on DioException catch (e) {
    print('请求失败: ${e.message}');
  }
}

/// 获取单个帖子详情
Future<void> fetchPostById(int id) async {
  try {
    final response = await dio.get('/posts/$id');
    final post = response.data;
    print('标题: ${post['title']}');
    print('内容: ${post['body']}');
  } on DioException catch (e) {
    print('获取帖子详情失败: ${e.message}');
  }
}
```

### POST 请求

```dart
/// 创建新帖子
Future<void> createPost() async {
  try {
    final response = await dio.post(
      '/posts',
      // Dio 会自动将 Map 序列化为 JSON，无需手动 jsonEncode
      data: {
        'title': 'Flutter Dio 教程',
        'body': '这是一篇关于 Dio 网络请求库的详细教程',
        'userId': 1,
      },
    );

    print('创建成功！');
    print('状态码: ${response.statusCode}');  // 201
    print('新帖子 ID: ${response.data['id']}');
  } on DioException catch (e) {
    print('创建帖子失败: ${e.message}');
  }
}

/// 发送表单格式的 POST 请求
Future<void> createPostWithFormData() async {
  try {
    final response = await dio.post(
      '/posts',
      data: {
        'title': '表单格式的帖子',
        'body': '使用 x-www-form-urlencoded 格式',
        'userId': 1,
      },
      options: Options(
        // 设置内容类型为表单格式
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    print('表单提交成功: ${response.statusCode}');
  } on DioException catch (e) {
    print('表单提交失败: ${e.message}');
  }
}
```

### PUT 请求（全量更新）

```dart
/// 更新帖子（全量替换）
Future<void> updatePost(int id) async {
  try {
    final response = await dio.put(
      '/posts/$id',
      data: {
        'id': id,
        'title': '更新后的标题',
        'body': '更新后的内容，使用 PUT 方法进行全量替换',
        'userId': 1,
      },
    );
    print('更新成功: ${response.data['title']}');
  } on DioException catch (e) {
    print('更新帖子失败: ${e.message}');
  }
}
```

### PATCH 请求（部分更新）

```dart
/// 部分更新帖子
Future<void> patchPost(int id) async {
  try {
    final response = await dio.patch(
      '/posts/$id',
      data: {
        'title': '只更新标题，其他字段保持不变',
      },
    );
    print('部分更新成功: ${response.data['title']}');
  } on DioException catch (e) {
    print('部分更新失败: ${e.message}');
  }
}
```

### DELETE 请求

```dart
/// 删除帖子
Future<void> deletePost(int id) async {
  try {
    final response = await dio.delete('/posts/$id');
    print('删除成功，状态码: ${response.statusCode}');  // 200
  } on DioException catch (e) {
    print('删除帖子失败: ${e.message}');
  }
}
```

### 使用 Options 自定义单次请求

```dart
/// 使用 Options 为单次请求设置自定义配置
Future<void> customRequest() async {
  final response = await dio.get(
    '/posts/1',
    options: Options(
      // 单次请求的自定义 headers（会与 BaseOptions 中的 headers 合并）
      headers: {
        'X-Custom-Header': 'custom-value',
      },
      // 单次请求的超时设置（覆盖 BaseOptions 中的设置）
      receiveTimeout: const Duration(seconds: 30),
      // 指定响应类型
      responseType: ResponseType.json,
    ),
  );
  print('自定义请求成功: ${response.data['title']}');
}
```

---

## 2.4 拦截器（Interceptor）详解

拦截器是 Dio 最强大的特性之一，它允许你在请求发出前、响应到达后、以及发生错误时进行统一处理。

### 2.4.1 拦截器原理和生命周期

拦截器的执行顺序遵循 **洋葱模型**：

```
请求发出 → onRequest(拦截器1) → onRequest(拦截器2) → 服务器
                                                        ↓
响应返回 ← onResponse(拦截器1) ← onResponse(拦截器2) ← 服务器响应
```

如果发生错误：

```
onError(拦截器2) → onError(拦截器1) → 调用者 catch
```

每个拦截器都有三个回调方法：

```dart
class MyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 在请求发出之前执行
    // 可以修改请求参数、添加 headers、打印日志等
    print('即将发送请求: ${options.method} ${options.uri}');

    // 必须调用以下方法之一来继续处理：
    handler.next(options);       // 继续执行下一个拦截器
    // handler.resolve(response); // 直接返回响应，跳过后续拦截器和实际请求
    // handler.reject(dioError);  // 直接抛出错误，跳过后续处理
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 在响应到达之后、返回给调用者之前执行
    // 可以修改响应数据、做数据转换等
    print('收到响应: ${response.statusCode}');

    handler.next(response);       // 继续执行下一个拦截器
    // handler.resolve(response); // 直接返回，跳过后续拦截器
    // handler.reject(dioError);  // 将成功响应转为错误
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 在请求发生错误时执行
    // 可以做错误重试、错误转换、统一错误处理等
    print('请求出错: ${err.message}');

    handler.next(err);            // 继续传递错误给下一个拦截器
    // handler.resolve(response); // 将错误转为成功响应（错误恢复）
    // handler.reject(err);       // 直接传递错误，跳过后续拦截器
  }
}
```

### handler 方法总结

| 方法 | 所在回调 | 作用 |
|------|---------|------|
| `handler.next()` | 三个回调都可用 | 继续执行拦截器链中的下一个拦截器 |
| `handler.resolve()` | 三个回调都可用 | 直接返回成功响应，跳过后续拦截器 |
| `handler.reject()` | 三个回调都可用 | 直接抛出错误，跳过后续拦截器 |

> ⚠️ **注意**：每个回调中 **必须** 调用 `handler` 的方法之一，否则请求会被挂起（不会超时也不会返回）。

### 添加拦截器

```dart
final dio = Dio();

// 添加多个拦截器，执行顺序为添加顺序
dio.interceptors.addAll([
  LogInterceptor(),    // 日志拦截器（先执行）
  TokenInterceptor(),  // Token 拦截器
  ErrorInterceptor(),  // 错误处理拦截器（后执行）
]);
```

### 2.4.2 日志拦截器实现

Dio 自带了一个 `LogInterceptor`，但我们也可以自定义一个更详细的日志拦截器：

```dart
/// 自定义日志拦截器
/// 记录请求和响应的详细信息，方便调试
class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('┌────────────────────────────────────────────');
    print('│ 🚀 请求开始');
    print('│ 方法: ${options.method}');
    print('│ URL: ${options.uri}');

    // 打印请求头
    if (options.headers.isNotEmpty) {
      print('│ 请求头:');
      options.headers.forEach((key, value) {
        print('│   $key: $value');
      });
    }

    // 打印查询参数
    if (options.queryParameters.isNotEmpty) {
      print('│ 查询参数: ${options.queryParameters}');
    }

    // 打印请求体（注意不要打印敏感信息如密码）
    if (options.data != null) {
      print('│ 请求体: ${options.data}');
    }

    print('├────────────────────────────────────────────');

    // 继续请求
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('│ ✅ 响应成功');
    print('│ 状态码: ${response.statusCode}');
    print('│ 数据类型: ${response.data.runtimeType}');

    // 如果数据是 List，打印数量；如果是 Map，打印 keys
    if (response.data is List) {
      print('│ 数据条数: ${(response.data as List).length}');
    } else if (response.data is Map) {
      print('│ 数据字段: ${(response.data as Map).keys.toList()}');
    }

    print('└────────────────────────────────────────────');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('│ ❌ 请求失败');
    print('│ 错误类型: ${err.type}');
    print('│ 错误信息: ${err.message}');
    if (err.response != null) {
      print('│ 状态码: ${err.response?.statusCode}');
      print('│ 响应数据: ${err.response?.data}');
    }
    print('└────────────────────────────────────────────');

    handler.next(err);
  }
}
```

使用 Dio 内置的 `LogInterceptor`：

```dart
// Dio 自带的日志拦截器，开箱即用
dio.interceptors.add(LogInterceptor(
  request: true,         // 打印请求信息
  requestHeader: true,   // 打印请求头
  requestBody: true,     // 打印请求体
  responseHeader: false,  // 不打印响应头（通常不需要）
  responseBody: true,    // 打印响应体
  error: true,           // 打印错误信息
  logPrint: (log) {
    // 自定义日志输出方式，可以对接 Logger 框架
    print('📡 DIO: $log');
  },
));
```

### 2.4.3 Token 拦截器（自动添加 Authorization Header）

在实际项目中，大部分 API 请求都需要携带用户的认证 Token。通过拦截器可以统一处理，避免在每个请求中手动添加：

```dart
/// Token 管理类（模拟）
class TokenManager {
  static String? _accessToken;
  static String? _refreshToken;

  /// 获取 Access Token
  static String? get accessToken => _accessToken;

  /// 获取 Refresh Token
  static String? get refreshToken => _refreshToken;

  /// 保存 Token（登录成功后调用）
  static void saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// 清除 Token（退出登录时调用）
  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// 判断是否已登录
  static bool get isLoggedIn => _accessToken != null;
}

/// Token 拦截器
/// 自动为需要认证的请求添加 Authorization Header
class TokenInterceptor extends Interceptor {
  /// 不需要 Token 的白名单路径
  final List<String> _whiteList = [
    '/auth/login',
    '/auth/register',
    '/public/',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;

    // 检查是否在白名单中（这些接口不需要 Token）
    final isWhiteListed = _whiteList.any(
      (whitePath) => path.contains(whitePath),
    );

    if (!isWhiteListed && TokenManager.isLoggedIn) {
      // 自动添加 Authorization 请求头
      options.headers['Authorization'] = 'Bearer ${TokenManager.accessToken}';
      print('🔑 已添加 Token 到请求头');
    }

    handler.next(options);
  }
}
```

使用示例：

```dart
void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ));

  // 添加 Token 拦截器
  dio.interceptors.add(TokenInterceptor());

  // 模拟登录，保存 Token
  TokenManager.saveTokens(
    accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    refreshToken: 'refresh_token_value_here',
  );

  // 后续所有请求都会自动携带 Token
  final response = await dio.get('/posts');
  print('获取帖子成功: ${(response.data as List).length} 条');
}
```

### 2.4.4 Token 刷新拦截器（401 时自动刷新 Token 并重试）

当 Access Token 过期时，服务器会返回 401 状态码。我们可以通过拦截器自动刷新 Token 并重新发送原始请求，实现 **无感刷新**：

```dart
/// Token 自动刷新拦截器
/// 当收到 401 错误时，自动使用 Refresh Token 获取新的 Access Token，
/// 然后重新发送原始请求，对上层调用者完全透明。
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;

  /// 是否正在刷新 Token（防止并发刷新）
  bool _isRefreshing = false;

  /// 等待 Token 刷新完成的请求队列
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _pendingRequests = [];

  TokenRefreshInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 只处理 401 未授权错误
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 如果没有 Refresh Token，直接返回错误（需要重新登录）
    if (TokenManager.refreshToken == null) {
      print('⚠️ 没有 Refresh Token，需要重新登录');
      handler.next(err);
      return;
    }

    // 如果当前正在刷新 Token，将请求加入等待队列
    if (_isRefreshing) {
      print('⏳ Token 正在刷新中，将请求加入等待队列');
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    // 开始刷新 Token
    _isRefreshing = true;
    print('🔄 开始刷新 Token...');

    try {
      // 使用新的 Dio 实例发送刷新请求（避免被拦截器循环拦截）
      final refreshDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
      ));

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': TokenManager.refreshToken},
      );

      // 保存新的 Token
      final newAccessToken = refreshResponse.data['accessToken'] as String;
      final newRefreshToken = refreshResponse.data['refreshToken'] as String;
      TokenManager.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      print('✅ Token 刷新成功');

      // 使用新 Token 重新发送原始请求
      final response = await _retryRequest(err.requestOptions);
      handler.resolve(response);

      // 处理等待队列中的请求
      for (final pending in _pendingRequests) {
        try {
          final retryResponse = await _retryRequest(pending.options);
          pending.handler.resolve(retryResponse);
        } on DioException catch (e) {
          pending.handler.reject(e);
        }
      }
    } on DioException catch (refreshError) {
      print('❌ Token 刷新失败: ${refreshError.message}');

      // 刷新失败，清除 Token，需要重新登录
      TokenManager.clearTokens();

      // 拒绝原始请求
      handler.reject(err);

      // 拒绝等待队列中的所有请求
      for (final pending in _pendingRequests) {
        pending.handler.reject(err);
      }
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }

  /// 使用新的 Token 重试请求
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    // 更新请求头中的 Token
    requestOptions.headers['Authorization'] =
        'Bearer ${TokenManager.accessToken}';

    // 使用原始 Dio 实例重新发送请求
    return _dio.fetch(requestOptions);
  }
}
```

添加到 Dio 实例：

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://jsonplaceholder.typicode.com',
));

// 注意拦截器的添加顺序很重要！
dio.interceptors.addAll([
  TokenInterceptor(),              // 先添加 Token（为请求添加 header）
  TokenRefreshInterceptor(dio),    // 再添加 Token 刷新（处理 401 错误）
  CustomLogInterceptor(),          // 最后添加日志（记录所有信息）
]);
```

### 2.4.5 错误处理拦截器

统一处理各类网络错误，将 Dio 异常转换为用户友好的提示：

```dart
/// 统一错误处理拦截器
/// 将各种 DioException 转换为统一的、用户友好的错误信息
class ErrorHandlerInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = '连接超时，请检查网络连接';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = '发送超时，请稍后重试';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = '接收超时，服务器响应过慢';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleHttpStatus(err.response?.statusCode);
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        errorMessage = '网络连接失败，请检查网络设置';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = '证书验证失败，请检查网络安全设置';
        break;
      case DioExceptionType.unknown:
        errorMessage = '未知网络错误: ${err.message}';
        break;
    }

    print('🚨 错误处理拦截器: $errorMessage');

    // 创建一个带有友好错误信息的新 DioException
    final newError = DioException(
      requestOptions: err.requestOptions,
      error: errorMessage,
      type: err.type,
      response: err.response,
    );

    handler.next(newError);
  }

  /// 根据 HTTP 状态码返回对应的错误描述
  String _handleHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误 (400)';
      case 401:
        return '未授权，请重新登录 (401)';
      case 403:
        return '拒绝访问，权限不足 (403)';
      case 404:
        return '请求的资源不存在 (404)';
      case 405:
        return '请求方法不允许 (405)';
      case 408:
        return '请求超时 (408)';
      case 409:
        return '数据冲突 (409)';
      case 422:
        return '数据验证失败 (422)';
      case 429:
        return '请求过于频繁，请稍后再试 (429)';
      case 500:
        return '服务器内部错误 (500)';
      case 502:
        return '网关错误 (502)';
      case 503:
        return '服务暂时不可用 (503)';
      case 504:
        return '网关超时 (504)';
      default:
        return '服务器异常 ($statusCode)';
    }
  }
}
```

---

## 2.5 CancelToken 取消请求

在某些场景下，我们需要取消正在进行的请求。最常见的场景是 **搜索防抖** —— 当用户快速输入时，取消之前未完成的搜索请求，只保留最新的一次。

### 基本用法

```dart
/// CancelToken 基本用法
Future<void> cancelTokenDemo() async {
  // 创建一个 CancelToken
  final cancelToken = CancelToken();

  // 发起请求时传入 cancelToken
  try {
    final responseFuture = dio.get(
      '/posts',
      cancelToken: cancelToken,
    );

    // 模拟：500 毫秒后取消请求（可能请求还没完成）
    Future.delayed(const Duration(milliseconds: 500), () {
      cancelToken.cancel('用户主动取消了请求');
    });

    final response = await responseFuture;
    print('请求成功: ${response.data}');
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) {
      // 请求被取消，这不是错误，不需要提示用户
      print('请求已取消: ${e.message}');
    } else {
      print('请求失败: ${e.message}');
    }
  }
}
```

### 搜索防抖场景实战

```dart
/// 搜索控制器
/// 实现搜索防抖：用户输入时自动取消上一次未完成的搜索请求
class SearchController {
  final Dio _dio;

  /// 当前的 CancelToken，用于取消上一次请求
  CancelToken? _cancelToken;

  SearchController(this._dio);

  /// 执行搜索
  /// 每次调用时会自动取消上一次未完成的请求
  Future<List<dynamic>> search(String keyword) async {
    // 取消上一次还在进行中的请求
    _cancelToken?.cancel('新的搜索请求到来，取消旧请求');

    // 创建新的 CancelToken
    _cancelToken = CancelToken();

    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: {'q': keyword},
        cancelToken: _cancelToken,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // 被取消的请求，返回空列表，不做处理
        print('搜索 "$keyword" 已被取消');
        return [];
      }
      rethrow; // 其他错误继续抛出
    }
  }

  /// 取消当前搜索
  void cancelSearch() {
    _cancelToken?.cancel('用户取消了搜索');
    _cancelToken = null;
  }

  /// 释放资源
  void dispose() {
    cancelSearch();
  }
}
```

在 Flutter Widget 中使用：

```dart
/// 搜索页面（Flutter Widget）
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = SearchController(Dio(
    BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'),
  ));
  List<dynamic> _results = [];
  bool _isLoading = false;

  /// 处理搜索输入变化
  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _searchController.search(value);

    // 只有在组件还挂载时才更新状态
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // 页面销毁时取消正在进行的请求
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          // 搜索输入框
          TextField(
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: '输入关键词搜索...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          // 搜索结果列表
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_results[index]['title'] ?? ''),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

### 同时取消多个请求

```dart
/// 使用同一个 CancelToken 取消多个并发请求
Future<void> cancelMultipleRequests() async {
  final cancelToken = CancelToken();

  // 同时发起多个请求，使用同一个 CancelToken
  final futures = [
    dio.get('/posts', cancelToken: cancelToken),
    dio.get('/users', cancelToken: cancelToken),
    dio.get('/comments', cancelToken: cancelToken),
  ];

  // 2 秒后取消所有请求
  Future.delayed(const Duration(seconds: 2), () {
    cancelToken.cancel('批量取消所有请求');
  });

  try {
    final results = await Future.wait(futures);
    print('所有请求完成');
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) {
      print('所有请求已被取消');
    }
  }
}
```

---

## 2.6 FormData 文件上传

Dio 内置了 `FormData` 支持，可以轻松实现文件上传功能。

### 单文件上传

```dart
/// 上传单个文件
Future<void> uploadSingleFile(String filePath) async {
  try {
    // 创建 FormData
    final formData = FormData.fromMap({
      // 普通表单字段
      'title': '我的头像',
      'description': '这是一张新的头像图片',

      // 文件字段：使用 MultipartFile.fromFile
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: 'avatar.jpg', // 上传后的文件名
      ),
    });

    final response = await dio.post(
      '/upload',
      data: formData,
      // 监听上传进度
      onSendProgress: (int sent, int total) {
        final progress = (sent / total * 100).toStringAsFixed(1);
        print('上传进度: $progress% ($sent/$total)');
      },
    );

    print('上传成功: ${response.data}');
  } on DioException catch (e) {
    print('上传失败: ${e.message}');
  }
}
```

### 多文件上传

```dart
/// 上传多个文件
Future<void> uploadMultipleFiles(List<String> filePaths) async {
  try {
    final formData = FormData();

    // 添加普通字段
    formData.fields.add(const MapEntry('album', '旅行相册'));
    formData.fields.add(const MapEntry('year', '2024'));

    // 添加多个文件
    for (int i = 0; i < filePaths.length; i++) {
      formData.files.add(MapEntry(
        'photos',  // 后端接收的字段名
        await MultipartFile.fromFile(
          filePaths[i],
          filename: 'photo_$i.jpg',
        ),
      ));
    }

    final response = await dio.post(
      '/upload/multiple',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total * 100).toStringAsFixed(1);
        print('批量上传进度: $progress%');
      },
    );

    print('批量上传成功: ${response.data}');
  } on DioException catch (e) {
    print('批量上传失败: ${e.message}');
  }
}
```

### 从内存上传（Bytes）

```dart
/// 从内存字节数据上传文件（适用于截图、绘图等场景）
Future<void> uploadFromBytes(List<int> imageBytes) async {
  try {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'screenshot.png',
      ),
    });

    final response = await dio.post('/upload', data: formData);
    print('内存上传成功: ${response.data}');
  } on DioException catch (e) {
    print('内存上传失败: ${e.message}');
  }
}
```

---

## 2.7 下载文件与进度监听

### 基本文件下载

```dart
/// 下载文件到本地
Future<void> downloadFile() async {
  try {
    final savePath = '/storage/emulated/0/Download/sample.pdf';

    final response = await dio.download(
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      savePath,
      // 监听下载进度
      onReceiveProgress: (int received, int total) {
        if (total != -1) {
          // total 为 -1 表示服务器未返回 Content-Length
          final progress = (received / total * 100).toStringAsFixed(1);
          print('下载进度: $progress% ($received/$total bytes)');
        } else {
          print('已下载: $received bytes（总大小未知）');
        }
      },
    );

    print('下载完成！文件保存在: $savePath');
    print('状态码: ${response.statusCode}');
  } on DioException catch (e) {
    print('下载失败: ${e.message}');
  }
}
```

### 带取消功能的下载

```dart
/// 支持取消的文件下载
class FileDownloader {
  final Dio _dio;
  CancelToken? _cancelToken;

  FileDownloader(this._dio);

  /// 开始下载
  Future<void> download(String url, String savePath) async {
    _cancelToken = CancelToken();

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(1);
            print('⬇️ 下载进度: $progress%');
          }
        },
        // 删除已下载的不完整文件（取消或失败时）
        deleteOnError: true,
      );
      print('✅ 下载完成: $savePath');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        print('⏹️ 下载已取消');
      } else {
        print('❌ 下载失败: ${e.message}');
      }
    }
  }

  /// 取消下载
  void cancel() {
    _cancelToken?.cancel('用户取消下载');
  }
}
```

### 带进度回调的完整下载工具

```dart
/// 下载进度回调类型
typedef DownloadProgressCallback = void Function(
  int received,
  int total,
  double percentage,
);

/// 完整的文件下载管理器
class DownloadManager {
  final Dio _dio;
  final Map<String, CancelToken> _activeDownloads = {};

  DownloadManager(this._dio);

  /// 下载文件
  /// [url] 下载地址
  /// [savePath] 保存路径
  /// [onProgress] 进度回调
  /// 返回下载任务 ID，可用于取消下载
  Future<String> download({
    required String url,
    required String savePath,
    DownloadProgressCallback? onProgress,
  }) async {
    // 生成唯一任务 ID
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    _activeDownloads[taskId] = cancelToken;

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percentage = received / total * 100;
            onProgress?.call(received, total, percentage);
          }
        },
      );
      print('下载完成: $savePath');
    } finally {
      _activeDownloads.remove(taskId);
    }

    return taskId;
  }

  /// 取消指定下载任务
  void cancelDownload(String taskId) {
    _activeDownloads[taskId]?.cancel('取消下载任务: $taskId');
    _activeDownloads.remove(taskId);
  }

  /// 取消所有下载任务
  void cancelAll() {
    for (final entry in _activeDownloads.entries) {
      entry.value.cancel('取消所有下载任务');
    }
    _activeDownloads.clear();
  }

  /// 获取活跃的下载任务数量
  int get activeCount => _activeDownloads.length;
}
```

---

## 2.8 封装 DioClient 最佳实践（单例模式）

在实际项目中，我们通常需要对 Dio 进行统一封装，确保全局使用同一个配置好的实例。

```dart
import 'package:dio/dio.dart';

/// 网络请求客户端（单例模式）
/// 封装 Dio，提供统一的网络请求入口
class DioClient {
  // ========== 单例实现 ==========

  /// 私有构造函数
  DioClient._internal() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  /// 静态实例
  static final DioClient _instance = DioClient._internal();

  /// 工厂构造函数，返回单例实例
  factory DioClient() => _instance;

  /// Dio 实例
  late final Dio _dio;

  /// 暴露 Dio 实例（某些场景需要直接访问）
  Dio get dio => _dio;

  // ========== 基础配置 ==========

  /// 基础配置
  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    responseType: ResponseType.json,
  );

  // ========== 拦截器配置 ==========

  /// 配置拦截器
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Token 拦截器
      TokenInterceptor(),
      // Token 刷新拦截器
      TokenRefreshInterceptor(_dio),
      // 错误处理拦截器
      ErrorHandlerInterceptor(),
      // 日志拦截器（仅在 debug 模式下启用）
      CustomLogInterceptor(),
    ]);
  }

  // ========== 封装请求方法 ==========

  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PATCH 请求
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 文件上传
  Future<Response> upload(
    String path, {
    required FormData formData,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post(
      path,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(
        contentType: 'multipart/form-data',
        // 上传大文件时可能需要更长的超时时间
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  /// 文件下载
  Future<Response> download(
    String urlPath,
    String savePath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.download(
      urlPath,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
```

### 使用封装好的 DioClient

```dart
/// 使用 DioClient 单例进行网络请求
Future<void> useDioClient() async {
  // 获取单例实例（无论调用多少次，都是同一个实例）
  final client = DioClient();

  try {
    // GET 请求
    final postsResponse = await client.get(
      '/posts',
      queryParameters: {'_limit': 5},
    );
    print('帖子数量: ${(postsResponse.data as List).length}');

    // POST 请求
    final createResponse = await client.post(
      '/posts',
      data: {
        'title': '通过 DioClient 创建',
        'body': '使用封装好的网络请求工具',
        'userId': 1,
      },
    );
    print('创建成功: ${createResponse.data['id']}');

    // PUT 请求
    final updateResponse = await client.put(
      '/posts/1',
      data: {
        'id': 1,
        'title': '更新后的标题',
        'body': '更新后的内容',
        'userId': 1,
      },
    );
    print('更新成功: ${updateResponse.data['title']}');

    // DELETE 请求
    final deleteResponse = await client.delete('/posts/1');
    print('删除成功: ${deleteResponse.statusCode}');
  } on DioException catch (e) {
    // 错误已经被 ErrorHandlerInterceptor 统一处理过了
    print('请求失败: ${e.error}');
  }
}
```

### 在项目中使用（搭配 Repository 模式）

```dart
/// 帖子数据仓库
/// 将网络请求逻辑封装在 Repository 层，UI 层不直接接触 Dio
class PostRepository {
  final DioClient _client = DioClient();

  /// 获取帖子列表
  Future<List<Map<String, dynamic>>> getPosts({int limit = 20}) async {
    final response = await _client.get(
      '/posts',
      queryParameters: {'_limit': limit},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// 获取帖子详情
  Future<Map<String, dynamic>> getPostById(int id) async {
    final response = await _client.get('/posts/$id');
    return Map<String, dynamic>.from(response.data);
  }

  /// 创建帖子
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final response = await _client.post(
      '/posts',
      data: {
        'title': title,
        'body': body,
        'userId': userId,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// 删除帖子
  Future<void> deletePost(int id) async {
    await _client.delete('/posts/$id');
  }
}
```

---

## 2.9 错误处理（DioException 类型判断）

Dio 的所有网络错误都会抛出 `DioException`，通过其 `type` 属性可以精确判断错误类型。

### DioException 类型一览

| DioExceptionType | 说明 | 常见原因 |
|-----------------|------|---------|
| `connectionTimeout` | 连接超时 | 服务器无响应、网络不通 |
| `sendTimeout` | 发送超时 | 上传大文件、网络慢 |
| `receiveTimeout` | 接收超时 | 服务器处理过慢 |
| `badResponse` | 服务器返回错误状态码 | 4xx、5xx 错误 |
| `cancel` | 请求被取消 | 主动调用 CancelToken.cancel() |
| `connectionError` | 连接错误 | DNS 解析失败、无网络 |
| `badCertificate` | SSL 证书错误 | 证书过期、自签名证书 |
| `unknown` | 未知错误 | 其他未分类的错误 |

### 完整的错误处理示例

```dart
/// 统一的网络异常处理类
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final DioExceptionType type;

  NetworkException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  @override
  String toString() => 'NetworkException: $message (code: $statusCode)';
}

/// 将 DioException 转换为 NetworkException
NetworkException handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return NetworkException(
        message: '连接服务器超时，请检查网络后重试',
        type: e.type,
      );

    case DioExceptionType.sendTimeout:
      return NetworkException(
        message: '数据发送超时，请检查网络后重试',
        type: e.type,
      );

    case DioExceptionType.receiveTimeout:
      return NetworkException(
        message: '服务器响应超时，请稍后重试',
        type: e.type,
      );

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final serverMessage = _extractServerMessage(e.response);
      return NetworkException(
        message: serverMessage ?? '服务器错误 ($statusCode)',
        statusCode: statusCode,
        type: e.type,
      );

    case DioExceptionType.cancel:
      return NetworkException(
        message: '请求已取消',
        type: e.type,
      );

    case DioExceptionType.connectionError:
      return NetworkException(
        message: '无法连接到服务器，请检查网络连接',
        type: e.type,
      );

    case DioExceptionType.badCertificate:
      return NetworkException(
        message: '安全证书验证失败',
        type: e.type,
      );

    case DioExceptionType.unknown:
      return NetworkException(
        message: '网络异常，请稍后重试',
        type: e.type,
      );
  }
}

/// 尝试从服务器响应中提取错误信息
String? _extractServerMessage(Response? response) {
  if (response?.data == null) return null;

  final data = response!.data;
  if (data is Map<String, dynamic>) {
    // 常见的错误信息字段名
    return data['message'] as String? ??
        data['error'] as String? ??
        data['msg'] as String? ??
        data['errorMessage'] as String?;
  }
  return null;
}

/// 在实际项目中使用
Future<void> safeApiCall() async {
  final client = DioClient();

  try {
    final response = await client.get('/posts/1');
    print('帖子标题: ${response.data['title']}');
  } on DioException catch (e) {
    final error = handleDioException(e);

    // 根据不同类型做不同处理
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      // 网络不通：显示"无网络"界面
      print('😵 网络异常: ${error.message}');
    } else if (e.type == DioExceptionType.badResponse) {
      if (error.statusCode == 401) {
        // Token 过期：跳转登录页
        print('🔒 需要重新登录');
      } else if (error.statusCode == 404) {
        // 资源不存在：显示 404 界面
        print('🔍 找不到请求的资源');
      } else {
        // 其他服务器错误：显示错误提示
        print('⚠️ 服务器错误: ${error.message}');
      }
    } else if (e.type == DioExceptionType.cancel) {
      // 请求被取消：通常不需要处理
    } else {
      // 未知错误：显示通用错误提示
      print('❌ ${error.message}');
    }
  }
}
```

### 配合 Flutter 显示错误 SnackBar

```dart
/// 显示网络错误提示（在 Flutter UI 中使用）
void showNetworkError(BuildContext context, DioException e) {
  final error = handleDioException(e);

  // 被取消的请求不需要提示用户
  if (e.type == DioExceptionType.cancel) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.message),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: '重试',
        textColor: Colors.white,
        onPressed: () {
          // 触发重试逻辑
        },
      ),
    ),
  );
}
```

---

## 2.10 本章小结

在本章中，我们深入学习了 Dio 网络请求库的方方面面：

### 知识点回顾

| 知识点 | 要点 |
|-------|------|
| **Dio vs http** | Dio 功能更全面，适合正式项目；http 更轻量，适合简单场景 |
| **BaseOptions** | 统一配置 baseUrl、超时、headers，避免重复代码 |
| **基本请求** | GET/POST/PUT/PATCH/DELETE，Dio 自动处理 JSON 序列化 |
| **拦截器** | 洋葱模型，onRequest → onResponse → onError，必须调用 handler |
| **Token 拦截器** | 自动添加 Authorization header，白名单机制 |
| **Token 刷新** | 401 时自动刷新并重试，请求队列防止并发刷新 |
| **CancelToken** | 取消进行中的请求，搜索防抖的核心工具 |
| **FormData** | 文件上传，支持单文件、多文件、内存上传 |
| **文件下载** | download 方法 + onReceiveProgress 进度监听 |
| **DioClient** | 单例模式封装，全局统一的网络请求入口 |
| **错误处理** | DioException 类型判断，友好的错误信息转换 |

### 最佳实践清单

1. ✅ 始终使用 `DioClient` 单例，避免创建多个 Dio 实例
2. ✅ 通过拦截器统一处理 Token、日志、错误，而不是在每个请求中重复
3. ✅ Token 刷新要考虑并发情况，使用请求队列
4. ✅ 搜索场景使用 `CancelToken` 实现防抖
5. ✅ 页面销毁时取消未完成的请求，避免内存泄漏
6. ✅ 使用 Repository 模式分离网络请求逻辑与 UI 逻辑
7. ✅ 错误处理要用户友好，区分网络错误和业务错误
8. ✅ 上传大文件时调大 `sendTimeout`
9. ✅ 下载文件时提供进度反馈，提升用户体验
10. ✅ Debug 模式下启用详细日志，Release 模式下关闭

### 下一步

在下一章中，我们将学习如何将 Dio 与 JSON 序列化结合使用，利用 `json_serializable` 和 `freezed` 实现类型安全的网络请求。

---

> 📁 完整的可运行代码请参考 `lib/ch02_dio.dart`
