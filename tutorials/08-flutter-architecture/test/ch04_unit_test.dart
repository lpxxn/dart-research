import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture/ch04_unit_testing.dart';

// ============================================================
// Mock 数据源——手动实现 UserDataSource 接口用于测试
// ============================================================

class MockUserDataSource implements UserDataSource {
  @override
  Future<Map<String, dynamic>> fetchUser(int id) async {
    // 返回模拟数据
    return {
      'id': id,
      'name': '测试用户$id',
      'email': 'user$id@test.com',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    return [
      {'id': 1, 'name': '张三', 'email': 'zhangsan@test.com'},
      {'id': 2, 'name': '李四', 'email': 'lisi@test.com'},
      {'id': 3, 'name': '王五', 'email': 'wangwu@test.com'},
    ];
  }

  @override
  Future<bool> saveUser(String name, String email) async {
    // 模拟保存成功
    return name.isNotEmpty && email.isNotEmpty;
  }
}

void main() {
  // ============================================================
  // Calculator 测试组
  // ============================================================
  group('Calculator Tests', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    test('加法：两个正数相加应返回正确结果', () {
      expect(calculator.add(2, 3), equals(5));
    });

    test('加法：正数和负数相加应返回正确结果', () {
      expect(calculator.add(10, -3), equals(7));
    });

    test('加法：两个零相加应返回零', () {
      expect(calculator.add(0, 0), equals(0));
    });

    test('减法：正常减法应返回正确结果', () {
      expect(calculator.subtract(10, 3), equals(7));
    });

    test('减法：结果为负数时应返回负值', () {
      expect(calculator.subtract(3, 10), equals(-7));
    });

    test('乘法：两个正数相乘应返回正确结果', () {
      expect(calculator.multiply(4, 5), equals(20));
    });

    test('乘法：任意数与零相乘应返回零', () {
      expect(calculator.multiply(999, 0), equals(0));
    });

    test('乘法：负数相乘应返回正数', () {
      expect(calculator.multiply(-3, -4), equals(12));
    });

    test('除法：正常除法应返回正确结果', () {
      expect(calculator.divide(10, 2), equals(5.0));
    });

    test('除法：结果为小数时应返回精确值', () {
      expect(calculator.divide(7, 2), equals(3.5));
    });

    test('除以零应抛出 ArgumentError', () {
      expect(
        () => calculator.divide(10, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('除以零时异常消息应包含提示信息', () {
      expect(
        () => calculator.divide(10, 0),
        throwsA(
          predicate((e) =>
              e is ArgumentError && e.message.toString().contains('除数不能为零')),
        ),
      );
    });
  });

  // ============================================================
  // StringValidator 测试组
  // ============================================================
  group('StringValidator Tests', () {
    late StringValidator validator;

    setUp(() {
      validator = StringValidator();
    });

    group('邮箱验证', () {
      test('合法邮箱应返回 true', () {
        expect(validator.isValidEmail('user@example.com'), isTrue);
      });

      test('带点号的用户名邮箱应返回 true', () {
        expect(validator.isValidEmail('first.last@domain.com'), isTrue);
      });

      test('空字符串应返回 false', () {
        expect(validator.isValidEmail(''), isFalse);
      });

      test('缺少 @ 符号应返回 false', () {
        expect(validator.isValidEmail('userexample.com'), isFalse);
      });

      test('缺少域名部分应返回 false', () {
        expect(validator.isValidEmail('user@'), isFalse);
      });
    });

    group('密码验证', () {
      test('长度>=8且包含数字的密码应返回 true', () {
        expect(validator.isValidPassword('abcdefg1'), isTrue);
      });

      test('复杂密码应返回 true', () {
        expect(validator.isValidPassword('MyP@ssw0rd!'), isTrue);
      });

      test('少于8位的密码应返回 false', () {
        expect(validator.isValidPassword('abc1'), isFalse);
      });

      test('没有数字的密码应返回 false', () {
        expect(validator.isValidPassword('abcdefgh'), isFalse);
      });

      test('空密码应返回 false', () {
        expect(validator.isValidPassword(''), isFalse);
      });
    });
  });

  // ============================================================
  // UserService 测试组
  // ============================================================
  group('UserService Tests', () {
    late UserService userService;
    late MockUserDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockUserDataSource();
      userService = UserService(mockDataSource);
    });

    test('getUser 应返回包含正确 id 的用户数据', () async {
      final user = await userService.getUser(1);
      expect(user['id'], equals(1));
    });

    test('getUser 返回的用户应包含 name 和 email 字段', () async {
      final user = await userService.getUser(1);
      expect(user, containsPair('name', contains('测试用户')));
      expect(user, containsPair('email', contains('@test.com')));
    });

    test('getUser 传入非法 id 应抛出 ArgumentError', () async {
      expect(
        () => userService.getUser(0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => userService.getUser(-1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getAllUsers 应返回非空列表', () async {
      final users = await userService.getAllUsers();
      expect(users, isNotEmpty);
    });

    test('getAllUsers 返回的列表长度应正确', () async {
      final users = await userService.getAllUsers();
      expect(users, hasLength(3));
    });

    test('getAllUsers 中每个用户都应包含 id 字段', () async {
      final users = await userService.getAllUsers();
      for (final user in users) {
        expect(user, contains('id'));
      }
    });

    test('createUser 传入有效数据应返回 true', () async {
      final result = await userService.createUser('张三', 'zhangsan@test.com');
      expect(result, isTrue);
    });

    test('createUser 名称为空应返回 false', () async {
      final result = await userService.createUser('', 'test@test.com');
      expect(result, isFalse);
    });

    test('createUser 邮箱为空应返回 false', () async {
      final result = await userService.createUser('张三', '');
      expect(result, isFalse);
    });

    test('getUser 返回的是 Future 类型（异步验证）', () {
      // 验证返回值确实是 Future
      final result = userService.getUser(1);
      expect(result, isA<Future<Map<String, dynamic>>>());
    });
  });
}
