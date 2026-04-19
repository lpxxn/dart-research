/// 第15章：Dart 3 新特性 — Records、Patterns 与密封类 完整演示
///
/// 运行方式: dart run bin/ch15_dart3_features.dart
library;

// ============================================================
// 类型定义（需要在顶层定义）
// ============================================================

// --- sealed class：Shape 层次结构 ---
sealed class Shape {}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
  @override
  String toString() => 'Circle(radius: $radius)';
}

class Square extends Shape {
  final double side;
  Square(this.side);
  @override
  String toString() => 'Square(side: $side)';
}

class Triangle extends Shape {
  final double base;
  final double height;
  Triangle(this.base, this.height);
  @override
  String toString() => 'Triangle(base: $base, height: $height)';
}

// --- sealed class：Result 泛型类型 ---
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T value;
  Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  Failure(this.message);
}

// --- sealed class：表达式 AST ---
sealed class Expr {}

class NumberExpr extends Expr {
  final double value;
  NumberExpr(this.value);
}

class AddExpr extends Expr {
  final Expr left;
  final Expr right;
  AddExpr(this.left, this.right);
}

class MulExpr extends Expr {
  final Expr left;
  final Expr right;
  MulExpr(this.left, this.right);
}

class NegExpr extends Expr {
  final Expr operand;
  NegExpr(this.operand);
}

// --- Point 类（用于对象解构演示）---
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
  @override
  String toString() => 'Point($x, $y)';
}

// --- class modifiers 演示 ---
base class Animal {
  final String name;
  Animal(this.name);
  void breathe() => print('    $name 在呼吸');
}

base class Dog extends Animal {
  Dog(super.name);
  void bark() => print('    $name 汪汪！');
}

interface class Printable {
  void printSelf() => print('    ${toString()}');
}

class Document implements Printable {
  final String content;
  Document(this.content);
  @override
  void printSelf() => print('    文档内容: $content');
  @override
  String toString() => 'Document($content)';
}

final class AppConfig {
  final String appName;
  final String version;
  AppConfig(this.appName, this.version);
  @override
  String toString() => '$appName v$version';
}

mixin class LoggerMixin {
  void log(String msg) => print('    [LOG] $msg');
}

class Service with LoggerMixin {
  final String name;
  Service(this.name);
  void doWork() {
    log('$name 开始执行任务');
  }
}

// ============================================================
// 辅助函数
// ============================================================

/// 计算 Shape 面积（sealed class + switch 穷尽匹配）
double area(Shape shape) => switch (shape) {
      Circle(radius: var r) => 3.14159 * r * r,
      Square(side: var s) => s * s,
      Triangle(base: var b, height: var h) => 0.5 * b * h,
    };

/// 描述 Shape（另一种匹配方式）
String describeShape(Shape shape) => switch (shape) {
      Circle(radius: var r) => '圆形，半径 $r，面积 ${area(shape).toStringAsFixed(2)}',
      Square(side: var s) => '正方形，边长 $s，面积 ${area(shape).toStringAsFixed(2)}',
      Triangle(base: var b, height: var h) =>
        '三角形，底 $b 高 $h，面积 ${area(shape).toStringAsFixed(2)}',
    };

/// 处理 Result（泛型 sealed class）
String displayResult<T>(Result<T> result) => switch (result) {
      Success(value: var v) => '✅ 成功: $v',
      Failure(message: var m) => '❌ 失败: $m',
    };

/// 表达式求值（递归 sealed class）
double evaluate(Expr expr) => switch (expr) {
      NumberExpr(value: var v) => v,
      AddExpr(left: var l, right: var r) => evaluate(l) + evaluate(r),
      MulExpr(left: var l, right: var r) => evaluate(l) * evaluate(r),
      NegExpr(operand: var e) => -evaluate(e),
    };

/// 表达式转字符串
String exprToString(Expr expr) => switch (expr) {
      NumberExpr(value: var v) => v.toString(),
      AddExpr(left: var l, right: var r) => '(${exprToString(l)} + ${exprToString(r)})',
      MulExpr(left: var l, right: var r) => '(${exprToString(l)} × ${exprToString(r)})',
      NegExpr(operand: var e) => '(-${exprToString(e)})',
    };

// ============================================================
// 演示函数
// ============================================================

/// 演示1：Records 基础
void demoRecords() {
  print('=== 1. Records（记录类型）===\n');

  // 位置记录
  (String, int) person = ('Alice', 25);
  print('  位置记录: ${person.$1}, ${person.$2}');

  // 命名记录
  ({String name, int age, String city}) user = (name: 'Bob', age: 30, city: '北京');
  print('  命名记录: ${user.name}, ${user.age}岁, ${user.city}');

  // 混合记录
  (String, int, {bool active}) mixed = ('hello', 42, active: true);
  print('  混合记录: ${mixed.$1}, ${mixed.$2}, active=${mixed.active}');

  // 函数返回多值
  (int quotient, int remainder) divide(int a, int b) => (a ~/ b, a % b);
  var (q, r) = divide(17, 5);
  print('  17 ÷ 5 = 商 $q 余 $r');

  // 多值返回：获取字符串统计
  ({int length, int words, int digits}) analyze(String s) {
    var words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    var digits = s.runes.where((c) => c >= 48 && c <= 57).length;
    return (length: s.length, words: words, digits: digits);
  }

  var stats = analyze('Hello Dart 3 有 42 个新特性');
  print('  字符串分析: 长度=${stats.length}, 单词数=${stats.words}, 数字=${stats.digits}');

  // Records 是值类型
  var a = (1, 'hello');
  var b = (1, 'hello');
  print('  值相等: (1, "hello") == (1, "hello") → ${a == b}');

  print('');
}

/// 演示2：Patterns 解构
void demoPatterns() {
  print('=== 2. Patterns（模式匹配）===\n');

  // --- 变量解构 ---
  print('  【变量解构】');
  var (name, age) = ('Charlie', 28);
  print('  Record 解构: name=$name, age=$age');

  // 交换变量
  var (x, y) = (10, 20);
  (x, y) = (y, x);
  print('  交换变量: x=$x, y=$y');

  // --- 列表解构 ---
  print('\n  【列表解构】');
  var list = [1, 2, 3, 4, 5];
  var [first, second, ...rest] = list;
  print('  [1,2,3,4,5] → first=$first, second=$second, rest=$rest');

  var [head, ..., tail] = [10, 20, 30, 40, 50];
  print('  取首尾: head=$head, tail=$tail');

  // --- Map 解构 ---
  print('\n  【Map 解构】');
  var json = {'name': 'Diana', 'age': 22, 'city': '上海'};
  var {'name': userName, 'age': userAge} = json;
  print('  Map 解构: name=$userName, age=$userAge');

  // --- 对象解构 ---
  print('\n  【对象解构】');
  var point = Point(3, 4);
  var Point(x: pointX, y: pointY) = point;
  print('  Point 解构: x=$pointX, y=$pointY');

  // 在 switch 中对象解构
  String describePoint(Point p) => switch (p) {
        Point(x: 0, y: 0) => '原点',
        Point(x: 0, y: var py) => 'Y轴上 (y=$py)',
        Point(x: var px, y: 0) => 'X轴上 (x=$px)',
        Point(x: var px, y: var py) => '第${px > 0 && py > 0 ? '一' : '其他'}象限 ($px, $py)',
      };

  for (var p in [Point(0, 0), Point(0, 5), Point(3, 0), Point(3, 4)]) {
    print('  $p → ${describePoint(p)}');
  }

  print('');
}

/// 演示3：switch 表达式
void demoSwitchExpression() {
  print('=== 3. switch 表达式 ===\n');

  // --- 数值匹配 ---
  print('  【HTTP 状态码】');
  for (var code in [200, 301, 404, 500, 418]) {
    var msg = switch (code) {
      200 => 'OK',
      301 => '永久重定向',
      404 => '未找到',
      500 => '服务器错误',
      418 => '我是茶壶 🫖',
      _ => '未知状态码',
    };
    print('  $code → $msg');
  }

  // --- 类型匹配 ---
  print('\n  【类型匹配】');
  String describe(Object obj) => switch (obj) {
        int n when n > 0 => '正整数: $n',
        int n when n < 0 => '负整数: $n',
        int() => '零',
        double d => '浮点数: $d',
        String s when s.isEmpty => '空字符串',
        String s => '字符串: "$s" (${s.length}字符)',
        bool b => '布尔: $b',
        List l => '列表 (${l.length}个元素)',
        (int, int) r => '坐标: (${r.$1}, ${r.$2})',
        _ => '其他: ${obj.runtimeType}',
      };

  var values = [42, -7, 0, 3.14, '', 'Dart', true, [1, 2, 3], (5, 10)];
  for (var v in values) {
    print('  ${v.toString().padRight(12)} → ${describe(v)}');
  }

  // --- 守卫子句 ---
  print('\n  【守卫子句 when】');
  String classify(int score) => switch (score) {
        int s when s >= 90 => '优秀 ⭐',
        int s when s >= 80 => '良好 👍',
        int s when s >= 60 => '及格 ✅',
        int s when s >= 0 => '不及格 ❌',
        _ => '无效分数',
      };

  for (var score in [95, 85, 72, 45, -1]) {
    print('  $score 分 → ${classify(score)}');
  }

  // --- 列表模式 ---
  print('\n  【列表模式】');
  String describeList(List<int> list) => switch (list) {
        [] => '空列表',
        [var a] => '单元素: $a',
        [var a, var b] => '两元素: $a, $b',
        [var a, ..., var z] => '首=$a, 尾=$z, 共${list.length}个',
      };

  for (var l in <List<int>>[
    [],
    [1],
    [1, 2],
    [1, 2, 3, 4, 5]
  ]) {
    print('  $l → ${describeList(l)}');
  }

  // --- 逻辑模式 ---
  print('\n  【逻辑模式 OR】');
  String dayType(String day) => switch (day) {
        'Monday' || 'Tuesday' || 'Wednesday' || 'Thursday' || 'Friday' => '工作日 💼',
        'Saturday' || 'Sunday' => '周末 🎉',
        _ => '无效',
      };

  for (var d in ['Monday', 'Saturday', 'Wednesday', 'Sunday']) {
    print('  $d → ${dayType(d)}');
  }

  print('');
}

/// 演示4：if-case
void demoIfCase() {
  print('=== 4. if-case 条件解构 ===\n');

  // --- JSON 解析场景 ---
  print('  【JSON 解析】');

  var responses = <Map<String, dynamic>>[
    {'status': 'ok', 'data': {'name': 'Alice', 'age': 25}},
    {'status': 'error', 'message': '用户未找到'},
    {'status': 'ok', 'data': 'invalid'},
    {'code': 500},
  ];

  for (var response in responses) {
    if (response case {'status': 'ok', 'data': Map<String, dynamic> data}) {
      if (data case {'name': String name, 'age': int age}) {
        print('  ✅ 成功: $name, $age 岁');
      } else {
        print('  ⚠️ 数据格式不正确: $data');
      }
    } else if (response case {'status': 'error', 'message': String msg}) {
      print('  ❌ 错误: $msg');
    } else {
      print('  ❓ 未知响应: $response');
    }
  }

  // --- 值检测 ---
  print('\n  【值检测】');
  var values = [42, 'hello', 3.14, -5, 0, 'Dart 3', null];
  for (var v in values) {
    if (v case int n when n > 0) {
      print('  $v → 正整数');
    } else if (v case String s when s.contains('Dart')) {
      print('  $v → 包含 Dart 的字符串');
    } else if (v case String s) {
      print('  "$s" → 普通字符串');
    } else if (v case null) {
      print('  null → 空值');
    } else {
      print('  $v → 其他 (${v.runtimeType})');
    }
  }

  print('');
}

/// 演示5：sealed class
void demoSealedClass() {
  print('=== 5. sealed class 密封类 ===\n');

  // --- Shape 层次 ---
  print('  【Shape 面积计算】');
  var shapes = <Shape>[
    Circle(5),
    Square(4),
    Triangle(6, 3),
    Circle(10),
  ];

  for (var shape in shapes) {
    print('  $shape → ${describeShape(shape)}');
  }

  // --- Result 类型 ---
  print('\n  【Result 泛型类型】');
  var results = <Result<String>>[
    Success('数据加载成功'),
    Failure('网络连接超时'),
    Success('文件保存完成'),
    Failure('权限不足'),
  ];

  for (var result in results) {
    print('  ${displayResult(result)}');
  }

  // --- 表达式 AST ---
  print('\n  【表达式 AST 求值】');
  // 表示: (3 + 4) × 2
  var expr1 = MulExpr(
    AddExpr(NumberExpr(3), NumberExpr(4)),
    NumberExpr(2),
  );
  print('  ${exprToString(expr1)} = ${evaluate(expr1)}');

  // 表示: -(5 + 3)
  var expr2 = NegExpr(AddExpr(NumberExpr(5), NumberExpr(3)));
  print('  ${exprToString(expr2)} = ${evaluate(expr2)}');

  // 表示: (2 × 3) + (4 × 5)
  var expr3 = AddExpr(
    MulExpr(NumberExpr(2), NumberExpr(3)),
    MulExpr(NumberExpr(4), NumberExpr(5)),
  );
  print('  ${exprToString(expr3)} = ${evaluate(expr3)}');

  print('');
}

/// 演示6：Class Modifiers
void demoClassModifiers() {
  print('=== 6. Class Modifiers（类修饰符）===\n');

  // base class
  print('  【base class — 可继承，不可 implements】');
  var dog = Dog('旺财');
  dog.breathe();
  dog.bark();

  // interface class
  print('\n  【interface class — 可 implements，不可继承】');
  var doc = Document('Dart 3 新特性指南');
  doc.printSelf();

  // final class
  print('\n  【final class — 不可继承也不可 implements】');
  var config = AppConfig('DartTutorial', '1.0.0');
  print('    配置: $config');

  // mixin class
  print('\n  【mixin class — 既是类也是 mixin】');
  var service = Service('数据服务');
  service.doWork();
  var logger = LoggerMixin();
  logger.log('直接使用 mixin class 实例');

  print('');
}

/// 演示7：综合实战 — Records + Patterns + sealed
void demoComprehensive() {
  print('=== 7. 综合实战 ===\n');

  // 模拟命令解析器
  print('  【命令解析器 — sealed + Patterns】');

  // 用 Record 模拟简单命令
  var commands = [
    'add 买菜 -p high',
    'list',
    'done 1',
    'search Dart',
    'help',
    'unknown',
  ];

  for (var cmd in commands) {
    var parts = cmd.split(' ');
    var result = switch (parts) {
      ['add', ...var titleParts] => () {
          var title = titleParts.where((p) => !p.startsWith('-')).join(' ');
          var priority =
              titleParts.contains('-p') ? titleParts[titleParts.indexOf('-p') + 1] : 'medium';
          return '➕ 添加任务: "$title" (优先级: $priority)';
        }(),
      ['list'] => '📋 显示所有任务',
      ['done', var id] => '✅ 完成任务 #$id',
      ['search', ...var keywords] => '🔍 搜索: "${keywords.join(' ')}"',
      ['help'] => '❓ 显示帮助信息',
      _ => '⚠️ 未知命令: "${parts.first}"',
    };
    print('  "$cmd" → $result');
  }

  // 多返回值配合模式解构
  print('\n  【多返回值 + 解构】');

  (int min, int max, double avg) stats(List<int> numbers) {
    var sorted = [...numbers]..sort();
    var sum = numbers.fold(0, (a, b) => a + b);
    return (sorted.first, sorted.last, sum / numbers.length);
  }

  var numbers = [34, 12, 89, 56, 23, 67, 45];
  var (min, max, avg) = stats(numbers);
  print('  数据: $numbers');
  print('  最小值: $min, 最大值: $max, 平均值: ${avg.toStringAsFixed(1)}');

  print('');
}

// ============================================================
// 主函数
// ============================================================

void main() {
  print('╔══════════════════════════════════════════════╗');
  print('║  第15章：Dart 3 新特性                       ║');
  print('╚══════════════════════════════════════════════╝\n');

  demoRecords();
  demoPatterns();
  demoSwitchExpression();
  demoIfCase();
  demoSealedClass();
  demoClassModifiers();
  demoComprehensive();

  print('✅ 第15章演示完成！');
}
