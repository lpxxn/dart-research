// 第8章：面向对象进阶 (OOP Advanced) —— 全面示例
//
// 运行方式：dart run bin/ch08_oop_advanced.dart

void main() {
  print('=== 第8章：面向对象进阶 (OOP Advanced) ===\n');

  _demoInheritance();
  _demoAbstractClass();
  _demoInterface();
  _demoMixin();
  _demoMixinOn();
  _demoPolymorphism();
}

// ============================================================
// 8.1 & 8.2 继承 + 方法重写
// ============================================================

/// 抽象基类：Shape
abstract class Shape {
  String get name;
  double get area;
  double get perimeter;

  void describe() {
    print('    $name — 面积: ${area.toStringAsFixed(2)}, '
        '周长: ${perimeter.toStringAsFixed(2)}');
  }
}

/// 圆形
class Circle extends Shape {
  final double radius;

  Circle(this.radius);

  @override
  String get name => '圆形(r=$radius)';

  @override
  double get area => 3.14159265 * radius * radius;

  @override
  double get perimeter => 2 * 3.14159265 * radius;
}

/// 矩形
class Rectangle extends Shape {
  final double width;
  final double height;

  Rectangle(this.width, this.height);

  /// 命名构造函数：正方形
  Rectangle.square(double side) : this(side, side);

  @override
  String get name => '矩形(${width}x$height)';

  @override
  double get area => width * height;

  @override
  double get perimeter => 2 * (width + height);
}

/// 三角形（继承并扩展）
class Triangle extends Shape {
  final double a, b, c; // 三边长

  Triangle(this.a, this.b, this.c) {
    if (a + b <= c || a + c <= b || b + c <= a) {
      throw ArgumentError('不合法的三角形边长');
    }
  }

  @override
  String get name => '三角形($a, $b, $c)';

  @override
  double get perimeter => a + b + c;

  @override
  double get area {
    // 海伦公式
    var s = perimeter / 2;
    var sq = s * (s - a) * (s - b) * (s - c);
    // 简易开方
    if (sq <= 0) return 0;
    var guess = sq / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + sq / guess) / 2;
    }
    return guess;
  }

  @override
  void describe() {
    super.describe(); // 调用父类方法
    print('      (使用海伦公式计算面积)');
  }
}

void _demoInheritance() {
  print('--- 8.1 & 8.2 继承 + 方法重写 ---');

  var circle = Circle(5);
  circle.describe();

  var rect = Rectangle(10, 5);
  rect.describe();

  var square = Rectangle.square(4);
  square.describe();

  var triangle = Triangle(3, 4, 5);
  triangle.describe(); // 调用重写的 describe（包含 super 调用）

  print('');
}

// ============================================================
// 8.3 抽象类
// ============================================================

void _demoAbstractClass() {
  print('--- 8.3 抽象类（Shape 已在上方展示） ---');

  // Shape 不能直接实例化
  // var s = Shape(); // 编译错误！

  // 但可以作为类型使用
  Shape shape = Circle(3);
  shape.describe();

  shape = Rectangle(6, 4);
  shape.describe();

  print('');
}

// ============================================================
// 8.4 接口 implements
// ============================================================

/// 可打印接口
abstract class Printable {
  String format();
}

/// 可序列化接口
abstract class Serializable {
  Map<String, dynamic> toMap();
  String serialize() => toMap().toString();
}

/// 学生类：实现多个接口
class Student implements Printable, Serializable {
  final String name;
  final int age;
  final double score;

  Student(this.name, this.age, this.score);

  @override
  String format() => '学生 $name ($age岁, 成绩: $score)';

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'score': score,
      };

  @override
  String serialize() => 'Student${toMap()}';
}

void _demoInterface() {
  print('--- 8.4 接口 implements ---');

  var student = Student('小明', 18, 95.5);

  // 通过 Printable 接口使用
  Printable printable = student;
  print('  Printable: ${printable.format()}');

  // 通过 Serializable 接口使用
  Serializable serializable = student;
  print('  Serializable: ${serializable.serialize()}');
  print('  toMap: ${serializable.toMap()}');

  print('');
}

// ============================================================
// 8.5 Mixin
// ============================================================

/// 动物基类
class Animal {
  final String name;
  Animal(this.name);

  void eat() => print('    $name 正在进食 🍽️');

  @override
  String toString() => name;
}

/// 游泳能力
mixin Swimmer on Animal {
  void swim() => print('    $name 正在游泳 🏊');

  int get maxDiveDepth => 10;

}

/// 飞翔能力
mixin Flyer on Animal {
  void fly() => print('    $name 正在飞翔 🦅');

  int get maxAltitude => 100;

}

/// 奔跑能力
mixin Runner on Animal {
  void run() => print('    $name 正在奔跑 🏃');

  int get maxSpeed => 30;

}

/// 鸭子：能游泳、能飞
class Duck extends Animal with Swimmer, Flyer {
  Duck(super.name);

  @override
  int get maxAltitude => 50; // 鸭子飞不高
}

/// 狗：能游泳、能跑
class Dog extends Animal with Swimmer, Runner {
  Dog(super.name);

  @override
  int get maxSpeed => 45; // 狗跑得快
}

/// 企鹅：只能游泳
class Penguin extends Animal with Swimmer {
  Penguin(super.name);

  @override
  int get maxDiveDepth => 500; // 企鹅潜水很深
}

/// 猎鹰：能飞、能跑
class Falcon extends Animal with Flyer, Runner {
  Falcon(super.name);

  @override
  int get maxAltitude => 3000;

  @override
  int get maxSpeed => 60;
}

void _demoMixin() {
  print('--- 8.5 Mixin 组合 ---');

  var duck = Duck('唐老鸭');
  duck.eat();
  duck.swim();
  duck.fly();
  print('    最大飞行高度：${duck.maxAltitude}m');

  print('');

  var dog = Dog('旺财');
  dog.eat();
  dog.swim();
  dog.run();
  print('    最大速度：${dog.maxSpeed}km/h');

  print('');

  var penguin = Penguin('帝企鹅');
  penguin.eat();
  penguin.swim();
  print('    最大潜水深度：${penguin.maxDiveDepth}m');

  print('');

  var falcon = Falcon('猎鹰');
  falcon.eat();
  falcon.fly();
  falcon.run();
  print('    最大飞行高度：${falcon.maxAltitude}m, 最大速度：${falcon.maxSpeed}km/h');

  print('');
}

// ============================================================
// 8.5 Mixin on 约束示例
// ============================================================

/// 音乐家基类
class Musician {
  final String name;
  Musician(this.name);

  void perform() => print('    $name 开始表演');
}

/// Singer mixin：只能用在 Musician 的子类上
mixin Singer on Musician {
  void sing() {
    perform();
    print('    $name 正在唱歌 🎤');
  }
}

/// Guitarist mixin：也限定在 Musician 上
mixin Guitarist on Musician {
  void playGuitar() {
    perform();
    print('    $name 正在弹吉他 🎸');
  }
}

/// 摇滚明星：组合多个能力
class RockStar extends Musician with Singer, Guitarist {
  RockStar(super.name);
}

/// 歌手
class PopSinger extends Musician with Singer {
  PopSinger(super.name);
}

void _demoMixinOn() {
  print('--- Mixin on 约束 ---');

  var rockStar = RockStar('周杰伦');
  rockStar.sing();
  rockStar.playGuitar();

  print('');

  var popSinger = PopSinger('邓紫棋');
  popSinger.sing();

  // 线性化顺序演示
  print('');
  print('  Mixin 线性化顺序：');
  print('  RockStar → Guitarist → Singer → Musician → Object');

  print('');
}

// ============================================================
// 多态：List<Shape> 遍历调用 area()
// ============================================================

void _demoPolymorphism() {
  print('--- 多态：List<Shape> ---');

  List<Shape> shapes = [
    Circle(5),
    Rectangle(10, 5),
    Rectangle.square(4),
    Triangle(3, 4, 5),
    Circle(1),
  ];

  print('  所有图形：');
  for (var shape in shapes) {
    shape.describe();
  }

  // 计算总面积
  var totalArea = shapes.fold<double>(0, (sum, s) => sum + s.area);
  print('  总面积: ${totalArea.toStringAsFixed(2)}');

  // 按面积排序
  shapes.sort((a, b) => a.area.compareTo(b.area));
  print('  按面积排序：');
  for (var shape in shapes) {
    print('    ${shape.name}: ${shape.area.toStringAsFixed(2)}');
  }

  // 筛选大面积图形
  var largeShapes = shapes.where((s) => s.area > 20).toList();
  print('  面积 > 20 的图形：');
  for (var shape in largeShapes) {
    print('    ${shape.name}: ${shape.area.toStringAsFixed(2)}');
  }

  print('');
}
