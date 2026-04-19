// ============================================================================
// 第二章：架构模式 - Clean Architecture 完整示例
//
// 本文件在一个文件中演示 Clean Architecture 的所有层级：
//   - Domain Layer（领域层）：Entity、Repository 接口、Use Case
//   - Data Layer（数据层）：Model、DTO、Repository 实现
//   - Presentation Layer（表示层）：ViewModel、View
//
// 注意：实际项目中应将每一层拆分到独立的目录和文件中。
// ============================================================================

import 'package:flutter/material.dart';

// ============================================================================
// 🟢 Domain Layer（领域层）
//
// 领域层是架构的核心，包含业务实体和业务规则。
// 该层不依赖任何外部框架，是纯 Dart 代码。
// ============================================================================

/// 用户实体 - 领域层的核心业务对象
/// Entity 只包含业务属性和业务逻辑，不含序列化方法
class UserEntity {
  final int id;
  final String name;
  final String email;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });

  /// 业务逻辑：验证邮箱格式是否有效
  bool get isValidEmail => email.contains('@');
}

/// 用户仓库接口 - 定义数据操作的抽象契约
/// 领域层只定义接口，具体实现由数据层提供（依赖倒置原则）
abstract class UserRepository {
  /// 获取所有用户
  Future<List<UserEntity>> getUsers();

  /// 根据 ID 获取单个用户
  Future<UserEntity?> getUserById(int id);
}

/// 获取用户列表用例 - 封装"获取用户列表"这一业务操作
/// 每个 Use Case 遵循单一职责原则，只做一件事
class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  /// 执行用例，返回用户列表
  Future<List<UserEntity>> call() async {
    return await repository.getUsers();
  }
}

// ============================================================================
// 🔵 Data Layer（数据层）
//
// 数据层负责数据的获取、转换和持久化。
// 包含 Model（含序列化）、DTO（数据传输对象）和 Repository 的具体实现。
// ============================================================================

/// 用户数据模型 - 继承自 UserEntity，增加序列化能力
/// Model 用于数据持久化和本地存储场景
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  /// 从 JSON Map 反序列化为 UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  /// 从 Entity 创建 Model（层级转换辅助方法）
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
    );
  }
}

/// 用户 DTO（数据传输对象） - 专门用于 API 数据传输
/// DTO 的字段名可能与 Entity 不同，对应 API 的数据格式
class UserDTO {
  final int userId;
  final String userName;
  final String userEmail;

  const UserDTO({
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  /// 从 API 响应构造 DTO
  factory UserDTO.fromApiResponse(Map<String, dynamic> json) {
    return UserDTO(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
    );
  }

  /// 将 DTO 转换为领域层 Entity
  UserEntity toEntity() {
    return UserEntity(
      id: userId,
      name: userName,
      email: userEmail,
    );
  }

  /// 转为 API 请求格式
  Map<String, dynamic> toApiRequest() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}

/// 用户仓库实现 - 实现领域层定义的 UserRepository 接口
/// 在实际项目中，这里会调用远程 API 或本地数据库
/// 此处使用模拟数据进行演示
class UserRepositoryImpl implements UserRepository {
  /// 模拟的用户数据，实际项目中应从 API 或数据库获取
  final List<Map<String, dynamic>> _mockApiData = const [
    {'user_id': 1, 'user_name': '张三', 'user_email': 'zhangsan@example.com'},
    {'user_id': 2, 'user_name': '李四', 'user_email': 'lisi@example.com'},
    {'user_id': 3, 'user_name': '王五', 'user_email': 'wangwu@example.com'},
    {'user_id': 4, 'user_name': '赵六', 'user_email': 'zhaoliu@example.com'},
    {'user_id': 5, 'user_name': '孙七', 'user_email': 'sunqi@example.com'},
  ];

  @override
  Future<List<UserEntity>> getUsers() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 通过 DTO 将 API 数据转换为 Entity
    return _mockApiData
        .map((json) => UserDTO.fromApiResponse(json).toEntity())
        .toList();
  }

  @override
  Future<UserEntity?> getUserById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final json = _mockApiData.firstWhere(
        (item) => item['user_id'] == id,
      );
      return UserDTO.fromApiResponse(json).toEntity();
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// 🟠 Presentation Layer（表示层）
//
// 表示层处理 UI 展示和用户交互。
// 包含 ViewModel（状态管理）和 View（Widget）。
// ============================================================================

/// 用户列表 ViewModel - 管理用户列表页面的状态
/// 使用 ChangeNotifier 实现响应式状态管理
class UserListViewModel extends ChangeNotifier {
  final GetUsersUseCase _getUsersUseCase;

  /// 用户列表数据
  List<UserEntity> _users = [];
  List<UserEntity> get users => _users;

  /// 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserListViewModel(this._getUsersUseCase);

  /// 加载用户列表 - 调用 Use Case 获取数据并更新状态
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // 通知 View 开始加载

    try {
      _users = await _getUsersUseCase.call();
    } catch (e) {
      _errorMessage = '加载失败：$e';
    } finally {
      _isLoading = false;
      notifyListeners(); // 通知 View 加载完成
    }
  }
}

// ============================================================================
// 🚀 应用入口
// ============================================================================

void main() => runApp(const Ch02App());

/// 应用根组件
class Ch02App extends StatelessWidget {
  const Ch02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Architecture 演示',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用 ColorScheme.fromSeed 生成主题色
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const UserListPage(),
    );
  }
}

/// 用户列表页面 - 表示层的核心 Widget
/// 负责创建 ViewModel 并根据状态渲染 UI
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // 依赖注入：手动组装各层依赖（实际项目推荐使用 get_it 等库）
  late final UserRepository _repository;
  late final GetUsersUseCase _getUsersUseCase;
  late final UserListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // 数据层：创建仓库实现
    _repository = UserRepositoryImpl();
    // 领域层：创建用例，注入仓库
    _getUsersUseCase = GetUsersUseCase(_repository);
    // 表示层：创建 ViewModel，注入用例
    _viewModel = UserListViewModel(_getUsersUseCase);

    // 初始加载数据
    _viewModel.loadUsers();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture 演示'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              // 架构层级说明卡片
              _buildArchitectureInfo(context),
              // 主要内容区域
              Expanded(child: _buildContent(context)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _viewModel.loadUsers,
        tooltip: '刷新数据',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// 构建架构层级说明区域，展示三层架构标签
  Widget _buildArchitectureInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📐 Clean Architecture 层级结构',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // 三层架构标签
          Row(
            children: [
              _buildLayerChip(
                context,
                label: 'Presentation Layer',
                subtitle: '表示层',
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              _buildLayerChip(
                context,
                label: 'Domain Layer',
                subtitle: '领域层',
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _buildLayerChip(
                context,
                label: 'Data Layer',
                subtitle: '数据层',
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 数据流说明
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // 使用 withValues 替代已废弃的 withOpacity
              color: colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '数据流向：View → ViewModel → UseCase → Repository → DataSource',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  /// 构建层级标签 Chip
  Widget _buildLayerChip(
    BuildContext context, {
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          // 使用 withValues(alpha:) 替代 withOpacity()
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据 ViewModel 状态构建不同的内容
  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 加载中状态
    if (_viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '正在加载用户数据...',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // 错误状态
    if (_viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage!,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _viewModel.loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 空数据状态
    if (_viewModel.users.isEmpty) {
      return const Center(child: Text('暂无用户数据'));
    }

    // 正常列表展示
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _viewModel.users.length,
      itemBuilder: (context, index) {
        final user = _viewModel.users[index];
        return _UserCard(user: user);
      },
    );
  }
}

/// 用户卡片组件 - 展示单个用户的信息
class _UserCard extends StatelessWidget {
  final UserEntity user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // 使用 withValues 设置透明度
      color: colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            // 展示 Entity 的业务逻辑方法
            Row(
              children: [
                Icon(
                  user.isValidEmail ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: user.isValidEmail
                      ? Colors.green
                      : colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  user.isValidEmail ? '邮箱有效' : '邮箱无效',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: user.isValidEmail
                            ? Colors.green
                            : colorScheme.error,
                      ),
                ),
                const SizedBox(width: 12),
                // 显示数据来源层级标签
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Entity #${user.id}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
