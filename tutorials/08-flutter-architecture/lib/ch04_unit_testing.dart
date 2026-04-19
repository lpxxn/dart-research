import 'package:flutter/material.dart';

// ============================================================
// 可测试的业务逻辑类
// ============================================================

/// 计算器类——演示基本的可测试逻辑
class Calculator {
  /// 加法
  int add(int a, int b) => a + b;

  /// 减法
  int subtract(int a, int b) => a - b;

  /// 乘法
  int multiply(int a, int b) => a * b;

  /// 除法，除数为零时抛出 ArgumentError
  double divide(int a, int b) {
    if (b == 0) {
      throw ArgumentError('除数不能为零');
    }
    return a / b;
  }
}

/// 字符串验证器——演示正则和条件判断的测试
class StringValidator {
  /// 验证邮箱格式是否合法
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return emailRegExp.hasMatch(email);
  }

  /// 验证密码强度：至少8个字符且包含至少一个数字
  bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}

// ============================================================
// UserService 相关——演示依赖注入和 Mock 测试
// ============================================================

/// 用户数据源抽象接口
abstract class UserDataSource {
  /// 根据 id 获取单个用户
  Future<Map<String, dynamic>> fetchUser(int id);

  /// 获取全部用户列表
  Future<List<Map<String, dynamic>>> fetchAllUsers();

  /// 保存新用户，返回是否成功
  Future<bool> saveUser(String name, String email);
}

/// 用户服务——通过构造函数注入数据源，方便测试时替换为 Mock
class UserService {
  final UserDataSource dataSource;

  UserService(this.dataSource);

  /// 获取指定 id 的用户信息
  Future<Map<String, dynamic>> getUser(int id) async {
    if (id <= 0) {
      throw ArgumentError('用户 ID 必须为正整数');
    }
    return await dataSource.fetchUser(id);
  }

  /// 获取所有用户
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await dataSource.fetchAllUsers();
  }

  /// 创建用户，名称和邮箱不能为空
  Future<bool> createUser(String name, String email) async {
    if (name.isEmpty || email.isEmpty) {
      return false;
    }
    return await dataSource.saveUser(name, email);
  }
}

// ============================================================
// Flutter 应用入口和 UI
// ============================================================

void main() => runApp(const Ch04App());

class Ch04App extends StatelessWidget {
  const Ch04App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '第四章：单元测试',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const Ch04HomePage(),
    );
  }
}

class Ch04HomePage extends StatefulWidget {
  const Ch04HomePage({super.key});

  @override
  State<Ch04HomePage> createState() => _Ch04HomePageState();
}

class _Ch04HomePageState extends State<Ch04HomePage> {
  final Calculator _calculator = Calculator();
  final StringValidator _validator = StringValidator();

  // 计算器输入
  final _numAController = TextEditingController(text: '10');
  final _numBController = TextEditingController(text: '5');
  String _calcResult = '';

  // 验证器输入
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _emailResult = '';
  String _passwordResult = '';

  @override
  void dispose() {
    _numAController.dispose();
    _numBController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 执行四则运算并显示结果
  void _performCalculations() {
    final a = int.tryParse(_numAController.text) ?? 0;
    final b = int.tryParse(_numBController.text) ?? 0;
    final buffer = StringBuffer();

    buffer.writeln('加法: $a + $b = ${_calculator.add(a, b)}');
    buffer.writeln('减法: $a - $b = ${_calculator.subtract(a, b)}');
    buffer.writeln('乘法: $a × $b = ${_calculator.multiply(a, b)}');

    try {
      buffer.writeln('除法: $a ÷ $b = ${_calculator.divide(a, b)}');
    } on ArgumentError catch (e) {
      buffer.writeln('除法: $e');
    }

    setState(() => _calcResult = buffer.toString().trim());
  }

  /// 验证邮箱
  void _validateEmail() {
    final email = _emailController.text;
    final isValid = _validator.isValidEmail(email);
    setState(() {
      _emailResult = isValid ? '✅ 邮箱格式正确' : '❌ 邮箱格式不正确';
    });
  }

  /// 验证密码
  void _validatePassword() {
    final password = _passwordController.text;
    final isValid = _validator.isValidPassword(password);
    setState(() {
      _passwordResult = isValid ? '✅ 密码强度合格' : '❌ 密码需至少8位且包含数字';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('第四章：单元测试'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 计算器区域
            _buildSectionCard(
              context,
              title: '计算器演示',
              icon: Icons.calculate,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _numAController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '数字 A',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _numBController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '数字 B',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _performCalculations,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('计算'),
                  ),
                  if (_calcResult.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _calcResult,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 验证器区域
            _buildSectionCard(
              context,
              title: '字符串验证器',
              icon: Icons.verified_user,
              child: Column(
                children: [
                  // 邮箱验证
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '输入邮箱',
                      hintText: 'example@domain.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: (_) => _validateEmail(),
                  ),
                  if (_emailResult.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _emailResult,
                        style: TextStyle(
                          color: _emailResult.contains('✅')
                              ? Colors.green
                              : colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 密码验证
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '输入密码',
                      hintText: '至少8位，包含数字',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onChanged: (_) => _validatePassword(),
                  ),
                  if (_passwordResult.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _passwordResult,
                        style: TextStyle(
                          color: _passwordResult.contains('✅')
                              ? Colors.green
                              : colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 提示信息
            Card(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '上面的 Calculator 和 StringValidator 类都有对应的单元测试，'
                        '运行 flutter test 即可查看测试结果。',
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建带标题的卡片区域
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
