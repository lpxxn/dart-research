import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// 全局服务定位器实例
// get_it 采用 Service Locator 模式，提供一个全局注册表来管理依赖
GetIt getIt = GetIt.instance;

// ============================================================
// 抽象服务定义（面向接口编程，符合依赖倒置原则）
// ============================================================

/// API 服务抽象类 - 定义网络请求的接口
abstract class ApiService {
  Future<String> fetchData(String endpoint);
  String get serviceName;
}

/// 数据库服务抽象类 - 定义本地数据存储的接口
abstract class DatabaseService {
  Future<void> saveData(String key, String value);
  Future<String?> getData(String key);
  String get serviceName;
}

// ============================================================
// 具体实现类（细节依赖抽象，而非抽象依赖细节）
// ============================================================

/// API 服务的具体实现
class ApiServiceImpl implements ApiService {
  ApiServiceImpl() {
    debugPrint('🌐 ApiServiceImpl 被创建 - hashCode: $hashCode');
  }

  @override
  Future<String> fetchData(String endpoint) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));
    return '从 $endpoint 获取的数据（时间: ${DateTime.now().toIso8601String()}）';
  }

  @override
  String get serviceName => 'ApiServiceImpl';
}

/// 数据库服务的具体实现
class DatabaseServiceImpl implements DatabaseService {
  // 使用内存 Map 模拟数据库存储
  final Map<String, String> _store = {};

  DatabaseServiceImpl() {
    debugPrint('💾 DatabaseServiceImpl 被创建 - hashCode: $hashCode');
  }

  @override
  Future<void> saveData(String key, String value) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _store[key] = value;
  }

  @override
  Future<String?> getData(String key) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _store[key];
  }

  @override
  String get serviceName => 'DatabaseServiceImpl';
}

// ============================================================
// 依赖消费者（通过 DI 获取所需的服务，不关心具体实现）
// ============================================================

/// 用户仓库 - 依赖 ApiService 和 DatabaseService
/// 演示构造函数注入：通过构造参数接收所有依赖
class UserRepository {
  final ApiService _apiService;
  final DatabaseService _dbService;

  // 构造函数注入：依赖由外部传入，而非内部创建
  UserRepository(this._apiService, this._dbService) {
    debugPrint('📦 UserRepository 被创建 - hashCode: $hashCode');
  }

  /// 获取用户数据，优先从缓存读取
  Future<String> fetchUserData(String userId) async {
    // 先查本地缓存
    final cached = await _dbService.getData('user_$userId');
    if (cached != null) {
      return '📋 [缓存] $cached';
    }
    // 缓存未命中，调用 API
    final data = await _apiService.fetchData('/users/$userId');
    // 写入缓存
    await _dbService.saveData('user_$userId', data);
    return '🌐 [网络] $data';
  }

  /// 获取当前依赖的服务信息
  String get dependencyInfo =>
      'ApiService: ${_apiService.serviceName} (${_apiService.hashCode})\n'
      'DatabaseService: ${_dbService.serviceName} (${_dbService.hashCode})';
}

// ============================================================
// 依赖注册（在应用启动时统一配置所有依赖关系）
// ============================================================

/// 设置依赖注入
/// 演示三种注册方式的区别：
/// - registerSingleton: 立即创建，全局唯一
/// - registerLazySingleton: 首次使用时创建，全局唯一
/// - registerFactory: 每次获取时创建新实例
void setupDependencies() {
  // 1. registerSingleton - 立即创建单例
  // 适用于应用核心服务，启动时就需要初始化的组件
  getIt.registerSingleton<DatabaseService>(DatabaseServiceImpl());

  // 2. registerLazySingleton - 懒加载单例
  // 适用于可能用到也可能用不到的服务，按需创建以节省资源
  getIt.registerLazySingleton<ApiService>(() => ApiServiceImpl());

  // 3. registerFactory - 工厂模式，每次获取新实例
  // 适用于需要独立状态的对象，如 ViewModel、临时处理器
  getIt.registerFactory<UserRepository>(
    () => UserRepository(getIt<ApiService>(), getIt<DatabaseService>()),
  );
}

// ============================================================
// 应用入口
// ============================================================

void main() {
  // 在 runApp 之前完成依赖注册
  setupDependencies();
  runApp(const Ch03App());
}

/// 第三章示例应用
class Ch03App extends StatelessWidget {
  const Ch03App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第三章：依赖注入',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用 ColorScheme.fromSeed 生成主题色板
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const DependencyInjectionPage(),
    );
  }
}

/// 主页面 - 演示依赖注入的各种用法
class DependencyInjectionPage extends StatefulWidget {
  const DependencyInjectionPage({super.key});

  @override
  State<DependencyInjectionPage> createState() =>
      _DependencyInjectionPageState();
}

class _DependencyInjectionPageState extends State<DependencyInjectionPage> {
  // 日志列表，用于展示 DI 行为
  final List<String> _logs = [];
  bool _isLoading = false;

  /// 添加日志并刷新界面
  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  /// 清空日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  /// 演示单例模式：多次获取返回同一个实例
  void _demonstrateSingleton() {
    _addLog('═══ 单例演示（registerSingleton）═══');
    final db1 = getIt<DatabaseService>();
    final db2 = getIt<DatabaseService>();
    _addLog('第一次获取 DatabaseService - hashCode: ${db1.hashCode}');
    _addLog('第二次获取 DatabaseService - hashCode: ${db2.hashCode}');
    _addLog('是否同一实例: ${identical(db1, db2)} ✅');
    _addLog('');
  }

  /// 演示懒加载单例：首次获取时才创建，之后返回同一实例
  void _demonstrateLazySingleton() {
    _addLog('═══ 懒加载单例演示（registerLazySingleton）═══');
    final api1 = getIt<ApiService>();
    final api2 = getIt<ApiService>();
    _addLog('第一次获取 ApiService - hashCode: ${api1.hashCode}');
    _addLog('第二次获取 ApiService - hashCode: ${api2.hashCode}');
    _addLog('是否同一实例: ${identical(api1, api2)} ✅');
    _addLog('');
  }

  /// 演示工厂模式：每次获取创建新实例
  void _demonstrateFactory() {
    _addLog('═══ 工厂模式演示（registerFactory）═══');
    final repo1 = getIt<UserRepository>();
    final repo2 = getIt<UserRepository>();
    _addLog('第一次获取 UserRepository - hashCode: ${repo1.hashCode}');
    _addLog('第二次获取 UserRepository - hashCode: ${repo2.hashCode}');
    _addLog('是否同一实例: ${identical(repo1, repo2)} ❌');
    _addLog('');
  }

  /// 演示完整的 DI 链路：Repository -> ApiService + DatabaseService
  Future<void> _demonstrateDIChain() async {
    setState(() => _isLoading = true);
    _addLog('═══ DI 链路演示 ═══');

    // 通过 DI 获取 UserRepository（内部自动注入 ApiService 和 DatabaseService）
    final repo = getIt<UserRepository>();
    _addLog('获取 UserRepository，内部依赖信息:');
    _addLog(repo.dependencyInfo);

    // 第一次获取：走网络
    _addLog('--- 第一次请求（走网络）---');
    final result1 = await repo.fetchUserData('001');
    _addLog(result1);

    // 第二次获取：走缓存（使用同一个 DatabaseService 单例）
    _addLog('--- 第二次请求（走缓存）---');
    // 注意：需要获取同一个 repo 实例才能命中缓存
    // 但 Factory 每次返回新实例，所以这里演示的是同一个 repo 内的缓存
    final result2 = await repo.fetchUserData('001');
    _addLog(result2);
    _addLog('');

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('第三章：依赖注入'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作按钮区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            // 使用 withValues(alpha:) 替代已弃用的 withOpacity()
            color: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '点击按钮演示不同的注册方式',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      label: 'Singleton',
                      icon: Icons.looks_one,
                      // 使用 withValues(alpha:) 设置半透明颜色
                      color: Colors.blue.withValues(alpha: 0.9),
                      onPressed: _demonstrateSingleton,
                    ),
                    _buildActionButton(
                      label: 'LazySingleton',
                      icon: Icons.looks_two,
                      color: Colors.green.withValues(alpha: 0.9),
                      onPressed: _demonstrateLazySingleton,
                    ),
                    _buildActionButton(
                      label: 'Factory',
                      icon: Icons.looks_3,
                      color: Colors.purple.withValues(alpha: 0.9),
                      onPressed: _demonstrateFactory,
                    ),
                    _buildActionButton(
                      label: 'DI 链路',
                      icon: Icons.link,
                      color: Colors.orange.withValues(alpha: 0.9),
                      onPressed: _isLoading ? null : _demonstrateDIChain,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 加载指示器
          if (_isLoading)
            LinearProgressIndicator(
              color: colorScheme.primary,
              backgroundColor:
                  colorScheme.primary.withValues(alpha: 0.15),
            ),
          // 日志展示区域
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 48,
                          color: colorScheme.outline
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '点击上方按钮开始演示',
                          style: TextStyle(
                            color: colorScheme.outline,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      // 根据日志内容设置不同样式
                      final isHeader = log.startsWith('═══');
                      final isSeparator = log.startsWith('---');
                      final isEmpty = log.isEmpty;

                      if (isEmpty) return const SizedBox(height: 8);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isHeader ? 14 : 13,
                            fontWeight: isHeader
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isHeader
                                ? colorScheme.primary
                                : isSeparator
                                    ? colorScheme.tertiary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.85),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
