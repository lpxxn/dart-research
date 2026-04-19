# 第六章：WebSocket 实时通信

## 概述

WebSocket 是一种在单个 TCP 连接上进行**全双工通信**的协议。与 HTTP 的"请求-响应"模式不同，WebSocket 建立连接后，客户端和服务器可以**随时互发消息**，非常适合聊天、实时推送、在线协作等场景。

## WebSocket vs HTTP

| 特性 | HTTP | WebSocket |
|------|------|-----------|
| 通信模式 | 请求-响应（半双工） | 全双工 |
| 连接方式 | 每次请求新建连接（HTTP/1.1 可复用） | 一次握手，持久连接 |
| 开销 | 每次请求携带完整头部 | 握手后头部开销极小 |
| 适用场景 | REST API、文件下载 | 聊天、实时推送、游戏 |
| 协议 | `http://` / `https://` | `ws://` / `wss://` |

## WebSocket 连接生命周期

```
客户端                        服务器
  |                            |
  |--- HTTP 升级请求 --------->|  (握手)
  |<-- 101 Switching Proto ---|
  |                            |
  |<===== WebSocket 连接 =====>|  (全双工通信)
  |--- 发送消息 ------------->|
  |<-- 接收消息 --------------|
  |--- 发送消息 ------------->|
  |                            |
  |--- 关闭帧 --------------->|  (断开)
  |<-- 关闭确认 --------------|
```

## 在 Flutter 中使用 WebSocket

### 依赖配置

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  web_socket_channel: ^3.0.0
```

`web_socket_channel` 是 Dart 官方维护的 WebSocket 库，跨平台支持好。

### 基本用法

#### 1. 建立连接

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

// 连接到 WebSocket 服务器
final channel = WebSocketChannel.connect(
  Uri.parse('wss://echo.websocket.events'),
);
```

#### 2. 发送消息

```dart
// 发送文本消息
channel.sink.add('Hello WebSocket!');

// 发送二进制数据
channel.sink.add(Uint8List.fromList([1, 2, 3]));
```

#### 3. 接收消息

```dart
// 监听服务器消息
channel.stream.listen(
  (message) {
    print('收到消息: $message');
  },
  onError: (error) {
    print('连接错误: $error');
  },
  onDone: () {
    print('连接已关闭');
  },
);
```

#### 4. 关闭连接

```dart
// 正常关闭
await channel.sink.close();

// 带状态码关闭
await channel.sink.close(1000, '正常关闭');
```

### WebSocket 关闭状态码

| 状态码 | 含义 |
|--------|------|
| 1000 | 正常关闭 |
| 1001 | 端点离开（页面关闭） |
| 1002 | 协议错误 |
| 1003 | 不支持的数据类型 |
| 1006 | 异常关闭（未发送关闭帧） |
| 1011 | 服务器内部错误 |

## 心跳保活机制

WebSocket 连接可能因为网络不稳定、服务器超时等原因静默断开。心跳机制通过**定期发送小数据包**来保持连接活跃：

```dart
/// 启动心跳
void _startHeartbeat() {
  _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) {
      if (_state == ConnectionState.connected) {
        _channel?.sink.add('__ping__');  // 发送心跳包
      }
    },
  );
}
```

服务端通常会回复 `__pong__`（或者 echo 服务器会原样返回）。如果一段时间没收到回复，说明连接可能已断开。

## 断线重连策略

网络不可靠，自动重连是 WebSocket 应用的必备功能：

```dart
void _handleDisconnect() {
  _stopHeartbeat();
  _updateState(ConnectionState.disconnected);

  if (_reconnectAttempts < maxReconnectAttempts) {
    _reconnectAttempts++;
    // 延迟后尝试重连
    _reconnectTimer = Timer(reconnectDelay, connect);
  }
}
```

### 重连策略选择

1. **固定间隔**：每隔 N 秒重连一次（简单）
2. **指数退避**：1s → 2s → 4s → 8s...（推荐）
3. **指数退避 + 抖动**：在退避基础上加随机偏移，避免服务器重启时所有客户端同时重连

```dart
/// 指数退避示例
Duration _getReconnectDelay() {
  final baseDelay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
  final jitter = Duration(milliseconds: Random().nextInt(1000));
  return baseDelay + jitter;
}
```

## WebSocket 管理器封装

实际项目中，建议将 WebSocket 逻辑封装到独立的管理类中：

```dart
class WebSocketManager {
  final String url;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // 回调
  void Function(String message)? onMessage;
  void Function(ConnectionState state)? onStateChange;
  void Function(String error)? onError;

  /// 连接
  void connect() { ... }

  /// 发送消息
  void send(String message) { ... }

  /// 断开连接
  void disconnect() { ... }

  /// 释放资源
  void dispose() {
    disconnect();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}
```

### 在 Widget 中使用

```dart
class _ChatPageState extends State<ChatPage> {
  late final WebSocketManager _wsManager;

  @override
  void initState() {
    super.initState();
    _wsManager = WebSocketManager(url: 'wss://echo.websocket.events');
    _wsManager.onMessage = (msg) {
      setState(() => _messages.add(msg));
    };
    _wsManager.onStateChange = (state) {
      setState(() => _connectionState = state);
    };
  }

  @override
  void dispose() {
    _wsManager.dispose();  // 重要：释放资源！
    super.dispose();
  }
}
```

## 示例代码说明

`lib/ch06_websocket.dart` 实现了一个完整的聊天界面：

- **WebSocketManager**：封装连接、心跳、重连逻辑
- **连接到 `wss://echo.websocket.events`**：公共 echo 服务器，会原样返回你发送的消息
- **UI 功能**：
  - 连接/断开按钮
  - 连接状态指示灯（绿/黄/红）
  - 消息气泡（发送蓝色靠右，接收灰色靠左）
  - 错误提示横幅
  - 自动滚动到最新消息

运行方式：
```bash
flutter run -t lib/ch06_websocket.dart
```

## 最佳实践

1. **及时释放**：在 `dispose()` 中关闭 WebSocket 连接和定时器
2. **心跳保活**：30 秒一次心跳是常见选择
3. **指数退避重连**：避免服务器雪崩
4. **最大重连次数**：设置上限，超过后提示用户手动操作
5. **消息队列**：断线期间的消息可先入队，重连后发送
6. **JSON 协议**：实际项目中用 JSON 封装消息，区分类型
7. **安全连接**：生产环境必须使用 `wss://`（加密）

## 进阶话题

### 使用 JSON 消息协议

实际项目中不会发送纯文本，通常定义消息协议：

```dart
// 发送
final message = jsonEncode({
  'type': 'chat',
  'content': '你好！',
  'timestamp': DateTime.now().toIso8601String(),
});
channel.sink.add(message);

// 接收并解析
channel.stream.listen((data) {
  final msg = jsonDecode(data);
  switch (msg['type']) {
    case 'chat': handleChatMessage(msg);
    case 'notification': handleNotification(msg);
    case 'ping': handlePing(msg);
  }
});
```

### 配合状态管理

WebSocket 消息流天然适合响应式编程，可以配合 `StreamProvider`（Riverpod）或 `StreamBuilder` 使用：

```dart
StreamBuilder<dynamic>(
  stream: channel.stream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('最新消息: ${snapshot.data}');
    }
    return const Text('等待消息...');
  },
)
```
