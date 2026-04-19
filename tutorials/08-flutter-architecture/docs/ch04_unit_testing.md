# 第四章：单元测试

## 4.1 什么是单元测试？

单元测试（Unit Testing）是软件开发中最基础、最重要的测试类型之一。它针对程序中**最小的可测试单元**（通常是函数或方法）进行验证，确保每个单元在隔离状态下能够正确工作。

### 为什么单元测试如此重要？

1. **尽早发现 Bug**：在开发阶段就能捕获逻辑错误，而不是等到集成测试或上线后才发现。
2. **安全重构**：有了完善的测试用例，重构代码时可以放心修改，测试会帮你验证功能是否依然正确。
3. **活文档**：测试用例本身就是代码行为的最佳文档，比注释更准确、更可靠。
4. **提高代码质量**：编写可测试的代码往往意味着更好的架构设计——低耦合、高内聚。
5. **加速开发**：虽然初期需要投入时间编写测试，但长期来看能显著减少调试时间。

---

## 4.2 Dart test 包基础

Dart 官方提供了 `test` 包用于编写和运行测试。在 Flutter 项目中，我们使用 `flutter_test` 包，它是对 `test` 包的扩展，增加了 Widget 测试相关的工具。

### 添加依赖

在 `pubspec.yaml` 中确保有以下依赖：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 基本测试结构

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('描述这个测试的目的', () {
    // 准备（Arrange）
    final calculator = Calculator();

    // 执行（Act）
    final result = calculator.add(2, 3);

    // 验证（Assert）
    expect(result, equals(5));
  });
}
```

每个测试遵循 **AAA 模式**（Arrange-Act-Assert）：
- **Arrange（准备）**：设置测试所需的对象和数据
- **Act（执行）**：调用被测试的方法
- **Assert（断言）**：验证结果是否符合预期

---

## 4.3 核心函数详解

### test() 函数

`test()` 是最基本的测试函数，用于定义一个测试用例：

```dart
test('两个正数相加应返回正确结果', () {
  expect(2 + 3, equals(5));
});

// 带超时的测试
test('网络请求不应超时', () async {
  final result = await fetchData();
  expect(result, isNotNull);
}, timeout: Timeout(Duration(seconds: 10)));

// 跳过测试
test('此功能暂未实现', () {
  // ...
}, skip: '等待后端 API 完成');
```

### group() 函数

`group()` 用于将相关的测试用例组织在一起，形成逻辑分组：

```dart
group('Calculator', () {
  group('加法运算', () {
    test('两个正数相加', () {
      expect(Calculator().add(2, 3), equals(5));
    });

    test('正数和负数相加', () {
      expect(Calculator().add(5, -3), equals(2));
    });

    test('两个负数相加', () {
      expect(Calculator().add(-2, -3), equals(-5));
    });
  });

  group('除法运算', () {
    test('正常除法', () {
      expect(Calculator().divide(10, 2), equals(5.0));
    });

    test('除以零应抛出异常', () {
      expect(() => Calculator().divide(10, 0), throwsArgumentError);
    });
  });
});
```

分组的好处：
- 测试输出更清晰，层级结构一目了然
- 可以为一组测试共享 `setUp` 和 `tearDown`
- 便于单独运行某一组测试

### setUp() 和 tearDown()

`setUp()` 在每个测试用例**之前**执行，`tearDown()` 在每个测试用例**之后**执行：

```dart
group('UserService 测试', () {
  late UserService userService;
  late MockUserDataSource mockDataSource;

  setUp(() {
    // 每个测试执行前都会运行
    mockDataSource = MockUserDataSource();
    userService = UserService(mockDataSource);
    print('测试准备完毕');
  });

  tearDown(() {
    // 每个测试执行后都会运行
    // 清理资源、重置状态等
    print('测试清理完毕');
  });

  test('获取用户信息', () async {
    final user = await userService.getUser(1);
    expect(user['name'], isNotNull);
  });

  test('获取所有用户', () async {
    final users = await userService.getAllUsers();
    expect(users, isNotEmpty);
  });
});
```

还有 `setUpAll()` 和 `tearDownAll()`，它们只在整个 group **开始前**和**结束后**各执行一次：

```dart
group('数据库测试', () {
  setUpAll(() async {
    // 整个 group 只执行一次——初始化数据库连接
    await Database.initialize();
  });

  tearDownAll(() async {
    // 整个 group 只执行一次——关闭数据库连接
    await Database.close();
  });

  // 测试用例...
});
```

---

## 4.4 expect() 和常用 Matcher

`expect()` 是测试中最核心的断言函数，配合各种 Matcher 使用：

### 基本相等

```dart
expect(result, equals(42));          // 值相等
expect(result, 42);                  // 简写形式，等价于 equals(42)
expect(result, isNot(equals(0)));    // 不等于
expect(identical_obj, same(original)); // 引用相同（同一对象）
```

### 布尔值

```dart
expect(isValid, isTrue);
expect(isEmpty, isFalse);
```

### 空值判断

```dart
expect(value, isNull);
expect(value, isNotNull);
```

### 数值比较

```dart
expect(score, greaterThan(60));
expect(score, lessThan(100));
expect(score, greaterThanOrEqualTo(60));
expect(score, lessThanOrEqualTo(100));
expect(score, inInclusiveRange(0, 100));  // 在范围内
expect(temperature, closeTo(36.5, 0.1));  // 近似相等（浮点数）
```

### 字符串匹配

```dart
expect(message, contains('hello'));
expect(email, matches(RegExp(r'^[\w]+@[\w]+\.[\w]+$')));
expect(name, startsWith('张'));
expect(name, endsWith('明'));
expect(emptyStr, isEmpty);
expect(name, isNotEmpty);
```

### 集合匹配

```dart
expect(list, contains(42));
expect(list, containsAll([1, 2, 3]));
expect(list, hasLength(5));
expect(list, isNotEmpty);
expect(list, everyElement(greaterThan(0)));  // 每个元素都大于0
expect(list, orderedEquals([1, 2, 3]));      // 顺序和值都相等
expect(list, unorderedEquals([3, 1, 2]));    // 值相等，顺序不限
```

### 类型匹配

```dart
expect(value, isA<String>());
expect(value, isA<int>());
expect(widget, isA<Text>());
```

### 异常匹配

```dart
expect(() => divide(10, 0), throwsArgumentError);
expect(() => parseJson('invalid'), throwsFormatException);
expect(() => riskyOperation(), throwsA(isA<CustomException>()));
expect(
  () => validate(null),
  throwsA(predicate((e) =>
    e is ValidationError && e.message.contains('不能为空')
  )),
);
```

---

## 4.5 测试异步代码

在 Dart 中，异步操作无处不在。测试异步代码需要一些特殊处理：

### 使用 async/await

```dart
test('获取用户数据', () async {
  final service = UserService(MockUserDataSource());

  // 使用 await 等待异步操作完成
  final user = await service.getUser(1);

  expect(user['name'], equals('张三'));
  expect(user['id'], equals(1));
});
```

### 使用 expectLater

`expectLater` 用于异步断言，返回一个 Future：

```dart
test('Stream 应按顺序发出值', () async {
  final stream = Stream.fromIterable([1, 2, 3]);

  await expectLater(
    stream,
    emitsInOrder([1, 2, 3]),
  );
});

test('Future 应在指定时间内完成', () async {
  final future = Future.delayed(
    Duration(milliseconds: 100),
    () => 42,
  );

  await expectLater(future, completion(equals(42)));
});

test('Future 应抛出异常', () async {
  final future = Future.error(Exception('网络错误'));

  await expectLater(future, throwsA(isA<Exception>()));
});
```

### Stream 相关的 Matcher

```dart
test('Stream 测试示例', () async {
  final controller = StreamController<int>();

  // 向 Stream 中添加数据
  controller.add(1);
  controller.add(2);
  controller.add(3);
  controller.close();

  await expectLater(
    controller.stream,
    emitsInOrder([
      1,
      2,
      emits(greaterThan(2)),  // 值大于2
      emitsDone,              // Stream 结束
    ]),
  );
});
```

---

## 4.6 Mock 对象

### 什么是 Mock？

Mock（模拟对象）用于替代真实的依赖项，使得测试可以在隔离环境中运行。常见场景：
- 模拟网络请求（不依赖真实 API）
- 模拟数据库操作（不依赖真实数据库）
- 模拟第三方服务

### 手动创建 Mock

最简单的方式是手动实现接口：

```dart
// 定义抽象接口
abstract class UserDataSource {
  Future<Map<String, dynamic>> fetchUser(int id);
  Future<List<Map<String, dynamic>>> fetchAllUsers();
  Future<bool> saveUser(String name, String email);
}

// 手动创建 Mock 实现
class MockUserDataSource implements UserDataSource {
  @override
  Future<Map<String, dynamic>> fetchUser(int id) async {
    // 返回模拟数据，不发起真实网络请求
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
    ];
  }

  @override
  Future<bool> saveUser(String name, String email) async {
    return name.isNotEmpty && email.isNotEmpty;
  }
}
```

### 在测试中使用 Mock

```dart
group('UserService 测试', () {
  late UserService service;
  late MockUserDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockUserDataSource();
    service = UserService(mockDataSource);
  });

  test('getUser 应返回正确的用户数据', () async {
    final user = await service.getUser(1);
    expect(user['id'], equals(1));
    expect(user['name'], contains('测试用户'));
  });
});
```

### 使用 mockito 包（进阶）

对于更复杂的场景，可以使用 `mockito` 包：

```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([UserDataSource])
void main() {
  // 使用生成的 MockUserDataSource
  final mock = MockUserDataSource();

  // 设置行为
  when(mock.fetchUser(1)).thenAnswer(
    (_) async => {'id': 1, 'name': '张三'},
  );

  // 验证调用
  verify(mock.fetchUser(1)).called(1);
}
```

---

## 4.7 测试命名规范和组织方式

### 命名规范

好的测试名称应该清楚地描述：**在什么条件下，执行什么操作，期望什么结果**。

```dart
// ✅ 好的命名
test('当除数为零时，divide 方法应抛出 ArgumentError', () { ... });
test('输入有效邮箱格式时，isValidEmail 应返回 true', () { ... });
test('密码少于8位时，isValidPassword 应返回 false', () { ... });

// ❌ 不好的命名
test('测试1', () { ... });
test('divide test', () { ... });
test('验证', () { ... });
```

### 文件组织

```
test/
├── unit/
│   ├── calculator_test.dart
│   ├── string_validator_test.dart
│   └── user_service_test.dart
├── widget/
│   ├── home_page_test.dart
│   └── login_form_test.dart
├── integration/
│   └── app_test.dart
└── helpers/
    ├── mocks.dart            # 共享的 Mock 类
    └── test_helpers.dart     # 测试辅助函数
```

### 测试文件命名约定

- 测试文件名以 `_test.dart` 结尾
- 与被测试文件名对应，如 `calculator.dart` → `calculator_test.dart`

---

## 4.8 TDD（测试驱动开发）简介

TDD 是一种开发方法论，其核心流程是：

### 红-绿-重构 循环

1. **红（Red）**：先编写一个失败的测试用例
2. **绿（Green）**：编写最少量的代码使测试通过
3. **重构（Refactor）**：优化代码结构，同时确保测试仍然通过

### TDD 示例：实现一个 Calculator

**第一步：编写失败的测试（红）**

```dart
test('add 方法应返回两数之和', () {
  final calc = Calculator();
  expect(calc.add(2, 3), equals(5));
});
```

此时 `Calculator` 类还不存在，测试会编译失败。

**第二步：编写最少代码使测试通过（绿）**

```dart
class Calculator {
  int add(int a, int b) => a + b;
}
```

**第三步：重构（如有必要）**

在这个简单例子中可能无需重构，但在实际项目中可能需要：
- 提取公共逻辑
- 改善命名
- 优化性能

### TDD 的优势

- 确保高测试覆盖率
- 促进更好的设计（因为要先想清楚接口）
- 小步迭代，降低风险
- 代码天然就是可测试的

---

## 4.9 最佳实践

### 1. 每个测试只验证一件事

```dart
// ✅ 好：每个测试关注一个行为
test('add 方法应返回两个正数之和', () {
  expect(Calculator().add(2, 3), equals(5));
});

test('add 方法应正确处理负数', () {
  expect(Calculator().add(-2, 3), equals(1));
});

// ❌ 不好：一个测试验证太多东西
test('Calculator 全部测试', () {
  final calc = Calculator();
  expect(calc.add(2, 3), equals(5));
  expect(calc.subtract(5, 3), equals(2));
  expect(calc.multiply(2, 3), equals(6));
  expect(calc.divide(10, 2), equals(5));
});
```

### 2. 测试应该独立运行

- 测试之间不应有依赖关系
- 每个测试都应从干净的状态开始
- 使用 `setUp()` 和 `tearDown()` 管理状态

### 3. 测试应该快速执行

- 单元测试不应依赖外部资源（网络、文件系统、数据库）
- 使用 Mock 替代真实依赖
- 避免不必要的 `sleep` 或 `delay`

### 4. 测试边界条件

```dart
group('边界条件测试', () {
  test('空字符串', () {
    expect(validator.isValidEmail(''), isFalse);
  });

  test('极大数值', () {
    expect(calc.add(2147483647, 0), equals(2147483647));
  });

  test('null 安全', () {
    // Dart 的空安全特性让许多 null 测试在编译期就能捕获
  });
});
```

### 5. 使用有意义的测试数据

```dart
// ✅ 好：测试数据有明确含义
test('合法邮箱应通过验证', () {
  expect(validator.isValidEmail('zhang.san@company.com'), isTrue);
});

// ❌ 不好：随意的测试数据
test('邮箱验证', () {
  expect(validator.isValidEmail('aaa@bbb.ccc'), isTrue);
});
```

### 6. 覆盖正常路径和异常路径

```dart
group('divide 方法', () {
  test('正常除法应返回正确结果', () {
    expect(calc.divide(10, 2), equals(5.0));
  });

  test('除以零应抛出 ArgumentError', () {
    expect(() => calc.divide(10, 0), throwsArgumentError);
  });
});
```

### 7. 运行测试的命令

```bash
# 运行所有测试
flutter test

# 运行指定测试文件
flutter test test/ch04_unit_test.dart

# 运行带覆盖率报告的测试
flutter test --coverage

# 只运行名称匹配的测试
flutter test --name "Calculator"
```

---

## 4.10 小结

本章我们学习了：

| 主题 | 要点 |
|------|------|
| 单元测试基础 | test()、group()、setUp()、tearDown() |
| 断言和匹配器 | expect() 配合各种 Matcher |
| 异步测试 | async/await、expectLater |
| Mock 对象 | 手动 Mock 和 mockito 包 |
| TDD | 红-绿-重构 循环 |
| 最佳实践 | 独立、快速、有意义的测试 |

下一章我们将学习 Widget 测试，了解如何测试 Flutter UI 组件。

---

> **练习**：为本章示例中的 `Calculator`、`StringValidator` 和 `UserService` 编写完整的单元测试，
> 目标是达到 100% 的代码覆盖率。参考 `test/ch04_unit_test.dart` 文件中的测试用例。
