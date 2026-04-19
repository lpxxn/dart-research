import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture/ch05_widget_testing.dart';

void main() {
  // 辅助方法：创建包裹在 MaterialApp 中的 LoginPage
  Widget createLoginPage() {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }

  group('登录表单渲染测试', () {
    testWidgets('renders login form correctly - 验证登录表单元素存在',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 验证邮箱输入框存在
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      // 验证密码输入框存在
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      // 验证登录按钮存在
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      // 验证登录按钮文字
      expect(find.text('登录'), findsWidgets);
    });

    testWidgets('forgot password button exists - 验证忘记密码按钮存在',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 验证忘记密码按钮存在
      expect(find.byKey(const Key('forgot_password')), findsOneWidget);
      // 验证忘记密码文字
      expect(find.text('忘记密码?'), findsOneWidget);
    });

    testWidgets('password field is obscured - 验证密码字段是隐藏的',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 获取密码输入框的 EditableText Widget，验证 obscureText
      final editableText = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('password_field')),
          matching: find.byType(EditableText),
        ),
      );

      // 验证 obscureText 为 true
      expect(editableText.obscureText, isTrue);
    });
  });

  group('表单验证测试', () {
    testWidgets('shows error when email is empty - 空邮箱显示错误',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 不输入任何内容，直接点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 验证邮箱错误提示出现
      expect(find.text('请输入邮箱'), findsOneWidget);
    });

    testWidgets('shows error when email is invalid - 无效邮箱显示错误',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入无效的邮箱（不含 @）
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 验证邮箱格式错误提示
      expect(find.text('请输入有效的邮箱地址'), findsOneWidget);
    });

    testWidgets('shows error when password is empty - 空密码显示错误',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入有效邮箱但不输入密码
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 验证密码错误提示出现
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('shows error when password is too short - 密码过短显示错误',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入有效邮箱
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );

      // 输入过短的密码（少于6位）
      await tester.enterText(
        find.byKey(const Key('password_field')),
        '12345',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 验证密码长度错误提示
      expect(find.text('密码长度不能少于6位'), findsOneWidget);
    });
  });

  group('用户交互测试', () {
    testWidgets('can enter text in fields - 验证文本输入功能',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      const testEmail = 'test@example.com';
      const testPassword = 'mypassword123';

      // 在邮箱字段输入文本
      await tester.enterText(
        find.byKey(const Key('email_field')),
        testEmail,
      );
      await tester.pump();

      // 在密码字段输入文本
      await tester.enterText(
        find.byKey(const Key('password_field')),
        testPassword,
      );
      await tester.pump();

      // 验证邮箱字段包含输入的文本
      expect(find.text(testEmail), findsOneWidget);
      // 密码字段因为 obscureText 不会直接显示文本，
      // 但可以通过 controller 验证值已被设置
    });

    testWidgets('successful login shows snackbar - 登录成功显示提示',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入有效邮箱
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );

      // 输入有效密码
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 验证 SnackBar 出现并显示"登录成功"
      expect(find.text('登录成功'), findsOneWidget);
    });

    testWidgets('navigates to welcome page on success - 登录成功后导航到欢迎页',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入有效邮箱
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );

      // 输入有效密码
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // 点击登录按钮
      await tester.tap(find.byKey(const Key('login_button')));
      // 等待导航动画完成
      await tester.pumpAndSettle();

      // 验证已导航到欢迎页面
      expect(find.text('欢迎回来!'), findsOneWidget);
      expect(find.text('您已成功登录'), findsOneWidget);
    });

    testWidgets('forgot password shows snackbar - 忘记密码按钮显示提示',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 点击忘记密码按钮
      await tester.tap(find.byKey(const Key('forgot_password')));
      await tester.pump();

      // 验证 SnackBar 出现
      expect(find.text('密码重置链接已发送'), findsOneWidget);
    });
  });

  group('综合场景测试', () {
    testWidgets('multiple validation errors shown simultaneously - 同时显示多个验证错误',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 不输入任何内容，直接点击登录
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 邮箱和密码的错误提示应同时出现
      expect(find.text('请输入邮箱'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('valid email but invalid password - 有效邮箱但无效密码',
        (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      // 输入有效邮箱
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'user@example.com',
      );

      // 输入过短密码
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'abc',
      );

      // 点击登录
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // 邮箱不应有错误提示
      expect(find.text('请输入邮箱'), findsNothing);
      expect(find.text('请输入有效的邮箱地址'), findsNothing);

      // 密码应显示长度不足的错误
      expect(find.text('密码长度不能少于6位'), findsOneWidget);
    });
  });
}
