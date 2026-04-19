import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 第五章：Repository 模式
/// 演示 Repository 模式的设计思想：接口定义、本地/远程数据源、缓存策略

void main() => runApp(const Ch05App());

// ============================================================
// 数据模型
// ============================================================

class User {
  final int id;
  final String name;
  final String email;
  final String avatar;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  /// 从 JSON Map 创建 User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String,
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatar': avatar};
  }
}

// ============================================================
// 数据源接口（抽象层）
// ============================================================

/// 用户数据源接口 —— Repository 模式的核心抽象
abstract class UserDataSource {
  Future<List<User>> getUsers();
  Future<User?> getUserById(int id);
  Future<void> saveUsers(List<User> users);
}

// ============================================================
// 远程数据源（模拟网络请求）
// ============================================================

class RemoteUserDataSource implements UserDataSource {
  final _random = Random();

  /// 模拟的用户数据
  final List<User> _mockServerData = [
    const User(id: 1, name: '张三', email: 'zhangsan@example.com', avatar: '👨‍💻'),
    const User(id: 2, name: '李四', email: 'lisi@example.com', avatar: '👩‍🔬'),
    const User(id: 3, name: '王五', email: 'wangwu@example.com', avatar: '👨‍🎨'),
    const User(id: 4, name: '赵六', email: 'zhaoliu@example.com', avatar: '👩‍🚀'),
    const User(id: 5, name: '孙七', email: 'sunqi@example.com', avatar: '👨‍🍳'),
  ];

  /// 模拟网络延迟和偶尔的失败
  Future<void> _simulateNetwork() async {
    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(1200)));
    // 20% 概率模拟网络错误
    if (_random.nextInt(5) == 0) {
      throw Exception('网络请求失败：连接超时');
    }
  }

  @override
  Future<List<User>> getUsers() async {
    await _simulateNetwork();
    return List.from(_mockServerData);
  }

  @override
  Future<User?> getUserById(int id) async {
    await _simulateNetwork();
    try {
      return _mockServerData.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUsers(List<User> users) async {
    // 远程数据源不需要外部保存，数据由服务器管理
    throw UnimplementedError('远程数据源不支持 saveUsers');
  }
}

// ============================================================
// 本地数据源（内存缓存）
// ============================================================

class LocalUserDataSource implements UserDataSource {
  final List<User> _cache = [];
  DateTime? _lastUpdated;

  /// 缓存是否有效（5分钟过期）
  bool get isCacheValid {
    if (_lastUpdated == null || _cache.isEmpty) return false;
    return DateTime.now().difference(_lastUpdated!).inMinutes < 5;
  }

  /// 获取缓存时间描述
  String get cacheInfo {
    if (_lastUpdated == null) return '无缓存';
    final diff = DateTime.now().difference(_lastUpdated!);
    return '${diff.inSeconds}秒前更新';
  }

  @override
  Future<List<User>> getUsers() async {
    return List.from(_cache);
  }

  @override
  Future<User?> getUserById(int id) async {
    try {
      return _cache.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUsers(List<User> users) async {
    _cache
      ..clear()
      ..addAll(users);
    _lastUpdated = DateTime.now();
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _lastUpdated = null;
  }
}

// ============================================================
// Repository（仓库层）—— 协调本地与远程数据源
// ============================================================

/// 数据加载结果，包含数据来源信息
class DataResult<T> {
  final T data;
  final DataSource source;
  final String? errorMessage;

  const DataResult({
    required this.data,
    required this.source,
    this.errorMessage,
  });
}

enum DataSource { cache, remote, cacheFallback }

class UserRepository {
  final RemoteUserDataSource _remoteSource;
  final LocalUserDataSource _localSource;

  UserRepository({
    RemoteUserDataSource? remoteSource,
    LocalUserDataSource? localSource,
  })  : _remoteSource = remoteSource ?? RemoteUserDataSource(),
        _localSource = localSource ?? LocalUserDataSource();

  /// 获取用户列表 —— 缓存优先策略
  /// 1. 如果缓存有效，直接返回缓存数据
  /// 2. 否则请求远程数据，成功则更新缓存
  /// 3. 如果远程失败，尝试返回过期缓存作为降级
  Future<DataResult<List<User>>> getUsers({bool forceRefresh = false}) async {
    // 步骤1：检查缓存
    if (!forceRefresh && _localSource.isCacheValid) {
      final cached = await _localSource.getUsers();
      return DataResult(data: cached, source: DataSource.cache);
    }

    // 步骤2：尝试从远程获取
    try {
      final remote = await _remoteSource.getUsers();
      await _localSource.saveUsers(remote);
      return DataResult(data: remote, source: DataSource.remote);
    } catch (e) {
      // 步骤3：远程失败，尝试用过期缓存降级
      final cached = await _localSource.getUsers();
      if (cached.isNotEmpty) {
        return DataResult(
          data: cached,
          source: DataSource.cacheFallback,
          errorMessage: e.toString(),
        );
      }
      // 没有任何数据可用
      rethrow;
    }
  }

  /// 根据 ID 获取单个用户
  Future<User?> getUserById(int id) async {
    // 先查缓存
    final cached = await _localSource.getUserById(id);
    if (cached != null) return cached;
    // 缓存未命中，查远程
    return _remoteSource.getUserById(id);
  }

  /// 获取缓存状态信息
  String get cacheStatus => _localSource.cacheInfo;
  bool get hasCacheData => _localSource.isCacheValid;

  /// 清除缓存
  void clearCache() => _localSource.clearCache();
}

// ============================================================
// UI 层
// ============================================================

class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ch05 - Repository 模式',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserRepository _repository = UserRepository();

  List<User> _users = [];
  bool _loading = false;
  String _statusMessage = '点击按钮加载数据';
  DataSource? _lastSource;

  /// 加载用户数据
  Future<void> _loadUsers({bool forceRefresh = false}) async {
    setState(() => _loading = true);

    try {
      final result = await _repository.getUsers(forceRefresh: forceRefresh);
      setState(() {
        _users = result.data;
        _lastSource = result.source;
        _loading = false;

        switch (result.source) {
          case DataSource.cache:
            _statusMessage = '✅ 数据来自缓存（${_repository.cacheStatus}）';
          case DataSource.remote:
            _statusMessage = '🌐 数据来自远程服务器（已缓存）';
          case DataSource.cacheFallback:
            _statusMessage = '⚠️ 网络失败，使用过期缓存\n${result.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = '❌ 加载失败：$e';
      });
    }
  }

  /// 清除缓存
  void _clearCache() {
    _repository.clearCache();
    setState(() {
      _statusMessage = '🗑️ 缓存已清除';
      _lastSource = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository 模式演示'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除缓存',
            onPressed: _clearCache,
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态信息卡片
          _buildStatusCard(colorScheme),
          // 操作按钮
          _buildActionButtons(),
          // 用户列表
          Expanded(child: _buildUserList(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme colorScheme) {
    Color cardColor;
    switch (_lastSource) {
      case DataSource.cache:
        cardColor = Colors.green.withValues(alpha: 0.1);
      case DataSource.remote:
        cardColor = Colors.blue.withValues(alpha: 0.1);
      case DataSource.cacheFallback:
        cardColor = Colors.orange.withValues(alpha: 0.1);
      case null:
        cardColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('数据状态', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(_statusMessage),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _loadUsers(),
              icon: const Icon(Icons.download),
              label: const Text('加载数据'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _loadUsers(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('强制刷新'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(ColorScheme colorScheme) {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(user.avatar, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Text('#${user.id}',
                style: TextStyle(color: colorScheme.primary)),
          ),
        );
      },
    );
  }
}
