/// 第9章 空安全 (Null Safety) 示例
///
/// 运行方式: dart run bin/ch09_null_safety.dart
library;

// 教学文件：以下警告是故意演示空安全操作符的用法
// ignore_for_file: dead_code, invalid_null_aware_operator
// ignore_for_file: dead_null_aware_expression, unnecessary_non_null_assertion

// ============================================================
// 辅助类：用于演示链式空安全
// ============================================================
class Address {
  final String? city;
  const Address(this.city);
}

class User {
  final String name;
  final Address? address;
  const User(this.name, {this.address});
}

// ============================================================
// 演示 late 惰性计算
// ============================================================
class DataProcessor {
  late final int heavyResult = _doExpensiveWork();

  int _doExpensiveWork() {
    print('  [惰性计算] 正在执行耗时运算...');
    return 42;
  }
}

// ============================================================
// 演示 required 关键字
// ============================================================
class Profile {
  final String name;
  final int age;
  final String? bio;

  // name 和 age 是 required 的，bio 是可选的
  Profile({required this.name, required this.age, this.bio});

  @override
  String toString() =>
      'Profile(name: $name, age: $age, bio: ${bio ?? "未填写"})';
}

// ============================================================
// 演示类型提升中字段不能提升的问题
// ============================================================
class FieldPromotionDemo {
  String? title;

  void printTitle() {
    // 字段不能自动提升，需要用局部变量
    final localTitle = title;
    if (localTitle != null) {
      print('  标题长度: ${localTitle.length}');
    } else {
      print('  标题为 null');
    }
  }
}

void main() {
  print('=' * 60);
  print('第9章 空安全 (Null Safety) 示例');
  print('=' * 60);

  // ----------------------------------------------------------
  // 9.1 可空 vs 不可空声明
  // ----------------------------------------------------------
  print('\n--- 9.1 可空 vs 不可空声明 ---');

  String name = 'Dart'; // 不可空，不能赋值为 null
  String? nickname; // 可空，默认为 null
  print('name = $name (不可空类型 String)');
  print('nickname = $nickname (可空类型 String?)');

  nickname = 'Flutter';
  print('nickname 赋值后 = $nickname');

  // 不可空可以赋值给可空
  String? maybeName = name;
  print('maybeName = $maybeName (String 赋值给 String?)');

  // ----------------------------------------------------------
  // 9.2 安全访问操作符 ?.
  // ----------------------------------------------------------
  print('\n--- 9.2 安全访问操作符 ?. ---');

  String? nullableName;
  print('nullableName?.length = ${nullableName?.length}'); // null
  nullableName = 'Hello';
  print('nullableName?.length = ${nullableName?.length}'); // 5

  // ----------------------------------------------------------
  // 9.3 空合并操作符 ??
  // ----------------------------------------------------------
  print('\n--- 9.3 空合并操作符 ?? ---');

  String? city;
  String displayCity = city ?? '未知城市';
  print('city ?? "未知城市" = $displayCity');

  city = '北京';
  displayCity = city ?? '未知城市';
  print('city ?? "未知城市" = $displayCity');

  // ----------------------------------------------------------
  // 9.4 空合并赋值操作符 ??=
  // ----------------------------------------------------------
  print('\n--- 9.4 空合并赋值操作符 ??= ---');

  String? color;
  print('color 初始值: $color');
  color ??= '红色'; // color 是 null，所以赋值
  print('color ??= "红色" 后: $color');
  color ??= '蓝色'; // color 不是 null，所以不赋值
  print('color ??= "蓝色" 后: $color (保持不变)');

  // ----------------------------------------------------------
  // 9.5 空断言操作符 !
  // ----------------------------------------------------------
  print('\n--- 9.5 空断言操作符 ! ---');

  String? greeting = '你好世界';
  // 我们确信 greeting 不为 null
  int length = greeting!.length;
  print('greeting!.length = $length');

  // 演示 ! 操作符在 null 时抛异常
  String? emptyValue;
  try {
    emptyValue!.length;
  } on TypeError {
    print('空断言失败！emptyValue 为 null，抛出 TypeError');
  }

  // ----------------------------------------------------------
  // 9.6 空感知索引操作符 ?[]
  // ----------------------------------------------------------
  print('\n--- 9.6 空感知索引操作符 ?[] ---');

  List<int>? numbers;
  print('numbers?[0] = ${numbers?[0]}'); // null

  numbers = [10, 20, 30];
  print('numbers?[0] = ${numbers?[0]}'); // 10

  Map<String, int>? scores;
  print('scores?["math"] = ${scores?["math"]}'); // null

  scores = {'math': 95, 'english': 88};
  print('scores?["math"] = ${scores?["math"]}'); // 95

  // ----------------------------------------------------------
  // 9.7 空感知展开操作符 ...?
  // ----------------------------------------------------------
  print('\n--- 9.7 空感知展开操作符 ...? ---');

  List<int>? extra;
  var list = [1, 2, 3, ...?extra];
  print('[1, 2, 3, ...?null] = $list'); // [1, 2, 3]

  extra = [4, 5];
  list = [1, 2, 3, ...?extra];
  print('[1, 2, 3, ...?[4,5]] = $list'); // [1, 2, 3, 4, 5]

  // ----------------------------------------------------------
  // 9.8 链式空安全
  // ----------------------------------------------------------
  print('\n--- 9.8 链式空安全 ---');

  User? user1 = User('Alice', address: Address('上海'));
  User? user2 = User('Bob', address: Address(null));
  User? user3 = User('Charlie');
  User? user4;

  String getCity(User? user) =>
      user?.address?.city?.toUpperCase() ?? 'UNKNOWN';

  print('user1 城市: ${getCity(user1)}'); // 上海
  print('user2 城市: ${getCity(user2)}'); // UNKNOWN（city 为 null）
  print('user3 城市: ${getCity(user3)}'); // UNKNOWN（address 为 null）
  print('user4 城市: ${getCity(user4)}'); // UNKNOWN（user 为 null）

  // ----------------------------------------------------------
  // 9.9 类型提升 (Type Promotion)
  // ----------------------------------------------------------
  print('\n--- 9.9 类型提升 (Type Promotion) ---');

  // null 检查后自动提升
  void greet(String? name) {
    if (name == null) {
      print('  Hello, stranger!');
      return;
    }
    // 这里 name 自动提升为 String（非空），无需 name!
    print('  Hello, ${name.toUpperCase()}!');
  }

  greet(null);
  greet('Dart');

  // is 检查后自动提升
  void processValue(Object? value) {
    if (value is String) {
      // value 自动提升为 String
      print('  字符串: ${value.toUpperCase()}, 长度: ${value.length}');
    } else if (value is int) {
      // value 自动提升为 int
      print('  整数: $value, 是偶数: ${value.isEven}');
    } else {
      print('  其他类型: $value');
    }
  }

  processValue('hello');
  processValue(42);
  processValue(null);

  // 字段不能自动提升 — 演示
  print('\n  字段不能自动提升的演示:');
  var demo = FieldPromotionDemo();
  demo.title = null;
  demo.printTitle();
  demo.title = 'Dart 空安全';
  demo.printTitle();

  // ----------------------------------------------------------
  // 9.10 late 变量
  // ----------------------------------------------------------
  print('\n--- 9.10 late 变量 ---');

  // late 延迟初始化
  late String description;
  description = '这是一个延迟初始化的变量';
  print('late 变量: $description');

  // late final：只赋值一次
  late final String config;
  config = '生产环境配置';
  print('late final 变量: $config');
  // config = '其他配置'; // 会抛出 Error

  // LateInitializationError 演示
  try {
    var lateDemo = _LateDemo();
    lateDemo.access(); // 访问未初始化的 late 字段
  } catch (e) {
    print('LateInitializationError: $e');
  }

  // ----------------------------------------------------------
  // 9.11 late 惰性计算
  // ----------------------------------------------------------
  print('\n--- 9.11 late 惰性计算 ---');

  var processor = DataProcessor();
  print('DataProcessor 已创建，但 heavyResult 尚未计算');
  print('首次访问 heavyResult: ${processor.heavyResult}');
  print('再次访问 heavyResult: ${processor.heavyResult} (不会重复计算)');

  // ----------------------------------------------------------
  // 9.12 required 关键字
  // ----------------------------------------------------------
  print('\n--- 9.12 required 关键字 ---');

  var profile1 = Profile(name: 'Alice', age: 30, bio: 'Dart 开发者');
  var profile2 = Profile(name: 'Bob', age: 25); // bio 是可选的
  print('profile1: $profile1');
  print('profile2: $profile2');

  // required 参数示例函数
  void createUser({required String name, required int age, String? email}) {
    print('  创建用户: $name, 年龄: $age, 邮箱: ${email ?? "未提供"}');
  }

  createUser(name: '张三', age: 28);
  createUser(name: '李四', age: 35, email: 'lisi@example.com');

  print('\n${'=' * 60}');
  print('第9章示例运行完毕！');
  print('=' * 60);
}

/// 用于演示 LateInitializationError 的辅助类
class _LateDemo {
  late String value;
  void access() => print(value);
}
