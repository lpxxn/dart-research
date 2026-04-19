import 'package:flutter/material.dart';

void main() => runApp(const Ch05App());

/// 第五章示例应用：登录表单（用于 Widget 测试演示）
class Ch05App extends StatelessWidget {
  const Ch05App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget 测试示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

/// 登录页面 - 包含邮箱、密码输入和登录按钮
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 验证邮箱格式
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }
    if (!value.contains('@')) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  /// 验证密码
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码长度不能少于6位';
    }
    return null;
  }

  /// 处理登录逻辑
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // 显示登录成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功')),
      );
      // 导航到欢迎页面
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 应用图标
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 32),

                // 邮箱输入框
                TextFormField(
                  key: const Key('email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入您的邮箱',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // 密码输入框
                TextFormField(
                  key: const Key('password_field'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入您的密码',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),

                // 登录按钮
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '登录',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // 忘记密码按钮
                TextButton(
                  key: const Key('forgot_password'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码重置链接已发送')),
                    );
                  },
                  child: Text(
                    '忘记密码?',
                    style: TextStyle(
                      color: colorScheme.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 欢迎页面 - 登录成功后跳转到此页面
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('欢迎'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              '欢迎回来!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '您已成功登录',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
