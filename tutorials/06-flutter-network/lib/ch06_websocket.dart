import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 第六章：WebSocket 通信
/// 演示 WebSocket 连接、发送/接收消息、心跳保活、断线重连

void main() => runApp(const Ch06App());

// ============================================================
// 消息模型
// ============================================================

class ChatMessage {
  final String content;
  final bool isSent; // true=发送, false=接收
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isSent,
    required this.timestamp,
  });
}

// ============================================================
// WebSocket 管理器：封装连接、心跳、重连逻辑
// ============================================================

enum ConnectionState { disconnected, connecting, connected }

class WebSocketManager {
  final String url;
  final Duration heartbeatInterval;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  ConnectionState _state = ConnectionState.disconnected;

  // 回调
  void Function(String message)? onMessage;
  void Function(ConnectionState state)? onStateChange;
  void Function(String error)? onError;

  WebSocketManager({
    required this.url,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });

  ConnectionState get state => _state;

  /// 连接 WebSocket
  void connect() {
    if (_state == ConnectionState.connected ||
        _state == ConnectionState.connecting) {
      return;
    }

    _updateState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // 监听消息
      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0; // 成功收到消息，重置重连计数
          if (_state != ConnectionState.connected) {
            _updateState(ConnectionState.connected);
            _startHeartbeat();
          }
          final message = data.toString();
          // 过滤掉心跳消息
          if (message != '__ping__') {
            onMessage?.call(message);
          }
        },
        onError: (error) {
          onError?.call('连接错误: $error');
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // 标记为已连接（WebSocketChannel.connect 是立即返回的）
      // 实际连接状态通过 stream 事件确认
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == ConnectionState.connecting) {
          _updateState(ConnectionState.connected);
          _startHeartbeat();
        }
      });
    } catch (e) {
      onError?.call('连接失败: $e');
      _handleDisconnect();
    }
  }

  /// 发送消息
  void send(String message) {
    if (_state != ConnectionState.connected || _channel == null) {
      onError?.call('未连接，无法发送消息');
      return;
    }
    _channel!.sink.add(message);
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectAttempts = maxReconnectAttempts; // 阻止自动重连
    _channel?.sink.close();
    _channel = null;
    _updateState(ConnectionState.disconnected);
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_state == ConnectionState.connected) {
        _channel?.sink.add('__ping__');
      }
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 处理断连 —— 尝试自动重连
  void _handleDisconnect() {
    _stopHeartbeat();
    _channel = null;
    _updateState(ConnectionState.disconnected);

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      onError?.call('连接断开，${reconnectDelay.inSeconds}秒后尝试第$_reconnectAttempts次重连...');
      _reconnectTimer = Timer(reconnectDelay, connect);
    } else {
      onError?.call('已达最大重连次数，请手动重连');
    }
  }

  void _updateState(ConnectionState newState) {
    _state = newState;
    onStateChange?.call(newState);
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}

// ============================================================
// UI 层
// ============================================================

class Ch06App extends StatelessWidget {
  const Ch06App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch06 - WebSocket',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final WebSocketManager _wsManager;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _wsManager = WebSocketManager(
      url: 'wss://echo.websocket.events',
      heartbeatInterval: const Duration(seconds: 30),
      reconnectDelay: const Duration(seconds: 3),
      maxReconnectAttempts: 5,
    );

    _wsManager.onMessage = (message) {
      setState(() {
        _messages.add(ChatMessage(
          content: message,
          isSent: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    };

    _wsManager.onStateChange = (state) {
      setState(() => _connectionState = state);
    };

    _wsManager.onError = (error) {
      setState(() => _errorMessage = error);
    };
  }

  @override
  void dispose() {
    _wsManager.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connect() {
    setState(() => _errorMessage = null);
    _wsManager.connect();
  }

  void _disconnect() {
    _wsManager.disconnect();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _wsManager.send(text);
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isSent: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket 聊天'),
        actions: [
          // 连接状态指示灯
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: switch (_connectionState) {
                    ConnectionState.connected => Colors.green,
                    ConnectionState.connecting => Colors.orange,
                    ConnectionState.disconnected => Colors.red,
                  },
                ),
                const SizedBox(width: 4),
                Text(
                  switch (_connectionState) {
                    ConnectionState.connected => '已连接',
                    ConnectionState.connecting => '连接中...',
                    ConnectionState.disconnected => '未连接',
                  },
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接控制栏
          _buildConnectionBar(colorScheme),
          // 错误提示
          if (_errorMessage != null) _buildErrorBanner(),
          // 消息列表
          Expanded(child: _buildMessageList(colorScheme)),
          // 输入栏
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildConnectionBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '服务器: wss://echo.websocket.events',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (_connectionState == ConnectionState.disconnected)
            FilledButton.tonal(
              onPressed: _connect,
              child: const Text('连接'),
            )
          else
            OutlinedButton(
              onPressed: _disconnect,
              child: const Text('断开'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return MaterialBanner(
      content: Text(_errorMessage!, style: const TextStyle(fontSize: 13)),
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      leading: const Icon(Icons.warning_amber, color: Colors.orange),
      actions: [
        TextButton(
          onPressed: () => setState(() => _errorMessage = null),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildMessageList(ColorScheme colorScheme) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              '连接服务器后发送消息\nEcho 服务器会回显你的消息',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg, colorScheme);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ColorScheme colorScheme) {
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')}';

    return Align(
      alignment: msg.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: msg.isSent
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              msg.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: msg.isSent
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.isSent ? "发送" : "收到"} $timeStr',
              style: TextStyle(
                fontSize: 10,
                color: msg.isSent
                    ? colorScheme.onPrimary.withValues(alpha: 0.7)
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    final isConnected = _connectionState == ConnectionState.connected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: isConnected,
                decoration: InputDecoration(
                  hintText: isConnected ? '输入消息...' : '请先连接服务器',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isConnected ? _sendMessage : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
