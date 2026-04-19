// 第7章：面向对象基础 (OOP Basics) —— 全面示例
//
// 运行方式：dart run bin/ch07_oop_basics.dart

void main() {
  print('=== 第7章：面向对象基础 (OOP Basics) ===\n');

  _demoPointClass();
  _demoGetterSetter();
  _demoPrivateAndStatic();
  _demoEquality();
  _demoSingleton();
  _demoCallableClass();
}

// ============================================================
// 7.2 Point 类：展示所有6种构造函数
// ============================================================

class Point {
  final double x;
  final double y;

  // 1. 语法糖构造函数（也是默认构造函数）
  const Point(this.x, this.y);

  // 2. 命名构造函数：原点
  const Point.origin()
      : x = 0,
        y = 0;

  // 3. 命名构造函数：从 JSON 创建
  Point.fromJson(Map<String, double> json)
      : x = json['x'] ?? 0,
        y = json['y'] ?? 0;

  // 4. 重定向构造函数
  const Point.alongXAxis(double x) : this(x, 0);
  const Point.alongYAxis(double y) : this(0, y);

  // 5. 工厂构造函数：根据极坐标创建
  factory Point.fromPolar(double r, double theta) {
    return Point(
      r * _cos(theta),
      r * _sin(theta),
    );
  }

  // 简易三角函数（避免引入 dart:math 以保持示例简洁）
  static double _cos(double radians) {
    // 使用泰勒级数近似
    var result = 1.0;
    var term = 1.0;
    for (var i = 1; i <= 10; i++) {
      term *= -radians * radians / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _sin(double radians) {
    var result = radians;
    var term = radians;
    for (var i = 1; i <= 10; i++) {
      term *= -radians * radians / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  // getter：计算到原点的距离
  double get distanceToOrigin {
    var d = x * x + y * y;
    // 简易开方（牛顿迭代法）
    if (d == 0) return 0;
    var guess = d / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + d / guess) / 2;
    }
    return guess;
  }

  // 6. const 构造函数 —— 上面的 Point(this.x, this.y) 已是 const
  // 演示 const 实例复用

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point($x, $y)';
}

void _demoPointClass() {
  print('--- Point 类：6种构造函数 ---');

  // 语法糖构造
  var p1 = Point(3, 4);
  print('  语法糖构造：$p1');

  // 命名构造：原点
  var p2 = Point.origin();
  print('  命名构造 origin：$p2');

  // 命名构造：fromJson
  var p3 = Point.fromJson({'x': 1.0, 'y': 2.0});
  print('  命名构造 fromJson：$p3');

  // 重定向构造
  var p4 = Point.alongXAxis(5);
  print('  重定向构造 alongXAxis：$p4');

  // 工厂构造：从极坐标
  var p5 = Point.fromPolar(1, 0); // r=1, theta=0 → (1, 0)
  print('  工厂构造 fromPolar(1, 0)：$p5');

  // const 构造函数：实例复用
  var c1 = const Point(1, 2);
  var c2 = const Point(1, 2);
  print('  const 实例相同：${identical(c1, c2)}'); // true

  // 距离
  print('  Point(3, 4) 到原点距离：${p1.distanceToOrigin.toStringAsFixed(2)}');

  print('');
}

// ============================================================
// 7.3 getter / setter 示例：Rectangle
// ============================================================

class Rectangle {
  double width;
  double height;

  Rectangle(this.width, this.height);

  // getter：计算属性
  double get area => width * height;
  double get perimeter => 2 * (width + height);
  bool get isSquare => width == height;

  @override
  String toString() => 'Rectangle(${width}x$height)';
}

/// 带验证的 setter
class Temperature {
  double _celsius;

  Temperature(this._celsius);

  double get celsius => _celsius;
  set celsius(double value) {
    if (value < -273.15) {
      throw ArgumentError('温度不能低于绝对零度 (-273.15°C)');
    }
    _celsius = value;
  }

  double get fahrenheit => _celsius * 9 / 5 + 32;
  set fahrenheit(double value) {
    celsius = (value - 32) * 5 / 9;
  }

  @override
  String toString() => '${_celsius.toStringAsFixed(1)}°C / ${fahrenheit.toStringAsFixed(1)}°F';
}

void _demoGetterSetter() {
  print('--- getter / setter ---');

  var rect = Rectangle(10, 5);
  print('  $rect');
  print('  面积：${rect.area}');
  print('  周长：${rect.perimeter}');
  print('  是正方形：${rect.isSquare}');

  rect.width = 5;
  print('  修改后 $rect，是正方形：${rect.isSquare}');

  // Temperature：setter 带验证
  var temp = Temperature(100);
  print('  温度：$temp');
  temp.fahrenheit = 32;
  print('  设置 32°F 后：$temp');

  try {
    temp.celsius = -300; // 低于绝对零度
  } catch (e) {
    print('  设置 -300°C 报错：$e');
  }

  print('');
}

// ============================================================
// 7.4 & 7.5 私有成员 + 静态成员
// ============================================================

class User {
  static int _count = 0;

  final int id;
  final String name;
  String _password; // 库级别私有

  User(this.name, String password)
      : _password = password,
        id = ++_count;

  bool verify(String input) => input == _password;

  void changePassword(String oldPwd, String newPwd) {
    if (verify(oldPwd)) {
      _password = newPwd;
      print('    密码修改成功');
    } else {
      print('    旧密码错误，修改失败');
    }
  }

  static int get totalUsers => _count;
  static void resetCount() => _count = 0;

  @override
  String toString() => 'User(id=$id, name=$name)';
}

void _demoPrivateAndStatic() {
  print('--- 私有成员 + 静态成员 ---');

  User.resetCount();
  var u1 = User('小明', 'pass123');
  var u2 = User('小红', 'secret');
  var u3 = User('小蓝', 'abc');

  print('  $u1');
  print('  $u2');
  print('  $u3');
  print('  总用户数（静态）：${User.totalUsers}');

  // 验证密码
  print('  u1 验证 "pass123"：${u1.verify("pass123")}');
  print('  u1 验证 "wrong"：${u1.verify("wrong")}');

  // 修改密码
  u1.changePassword('pass123', 'newpass');
  print('  u1 验证 "newpass"：${u1.verify("newpass")}');

  print('');
}

// ============================================================
// 7.6 operator== 和 hashCode
// ============================================================

void _demoEquality() {
  print('--- operator== 和 hashCode ---');

  var p1 = Point(3, 4);
  var p2 = Point(3, 4);
  var p3 = Point(1, 2);

  print('  p1 = $p1, p2 = $p2, p3 = $p3');
  print('  p1 == p2：${p1 == p2}'); // true（值相等）
  print('  p1 == p3：${p1 == p3}'); // false
  print('  identical(p1, p2)：${identical(p1, p2)}'); // false（不同对象）

  // hashCode 一致性
  print('  p1.hashCode == p2.hashCode：${p1.hashCode == p2.hashCode}');

  // 在 Set 中使用
  var pointSet = {p1, p2, p3};
  print('  Set 中的点（去重）：$pointSet'); // 只有2个

  print('');
}

// ============================================================
// 工厂构造函数实现单例 Logger
// ============================================================

class Logger {
  static final Logger _instance = Logger._internal();

  final List<String> _logs = [];

  factory Logger() {
    return _instance;
  }

  Logger._internal();

  void log(String msg) {
    _logs.add(msg);
    print('    [LOG] $msg');
  }

  List<String> get logs => List.unmodifiable(_logs);
  int get count => _logs.length;
}

void _demoSingleton() {
  print('--- 工厂构造函数：单例 Logger ---');

  var logger1 = Logger();
  var logger2 = Logger();

  print('  logger1 和 logger2 是同一个实例：${identical(logger1, logger2)}');

  logger1.log('应用启动');
  logger2.log('用户登录');
  logger1.log('数据加载完成');

  print('  日志总数：${logger1.count}');
  print('  所有日志：${logger1.logs}');

  print('');
}

// ============================================================
// 7.7 可调用类
// ============================================================

/// 乘法器：可以像函数一样调用
class Multiplier {
  final int factor;
  const Multiplier(this.factor);

  int call(int value) => value * factor;

  @override
  String toString() => 'Multiplier(x$factor)';
}

/// 格式化器
class Formatter {
  final String prefix;
  final String suffix;

  const Formatter(this.prefix, this.suffix);

  String call(String text) => '$prefix$text$suffix';
}

void _demoCallableClass() {
  print('--- 可调用类 ---');

  // Multiplier
  var double_ = Multiplier(2);
  var triple = Multiplier(3);

  print('  $double_ 调用 5：${double_(5)}');
  print('  $triple 调用 5：${triple(5)}');

  // 可以像函数一样传递
  var numbers = [1, 2, 3, 4, 5];
  var tripled = numbers.map(triple.call).toList();
  print('  用 Multiplier(3) map：$tripled');

  // Formatter
  var bracket = Formatter('[', ']');
  var tag = Formatter('<b>', '</b>');

  print('  bracket("hello")：${bracket("hello")}');
  print('  tag("bold")：${tag("bold")}');

  // 组合使用
  var words = ['Dart', 'Flutter', 'Pub'];
  var formatted = words.map(bracket.call).toList();
  print('  格式化列表：$formatted');

  print('');
}
