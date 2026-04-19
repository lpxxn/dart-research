# 第7章：面向对象基础 (OOP Basics)

Dart 是一门纯粹的面向对象语言——一切皆对象，包括数字、函数和 `null`。每个对象都是一个类的实例，所有类都继承自 `Object`。本章将深入介绍 Dart 中类的定义、实例化以及各种构造函数。

---

## 7.1 类的定义与实例化

### class 关键字

使用 `class` 关键字定义类：

```dart
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('我叫 $name，今年 $age 岁。');
  }
}
```

### 成员变量与方法

类的成员包括**实例变量**（字段）和**实例方法**。实例变量在声明时如果没有初始化且类型不可空，则必须在构造函数中初始化。

```dart
class Circle {
  double radius; // 必须在构造函数中初始化
  double x = 0;  // 声明时初始化
  double y = 0;

  Circle(this.radius);

  double get area => 3.14159 * radius * radius;
}
```

### this 引用

`this` 指向当前实例。大部分情况下可以省略 `this`，除非存在命名冲突：

```dart
class Point {
  double x, y;

  // 此处必须用 this 区分参数和字段
  Point(double x, double y) {
    this.x = x;
    this.y = y;
  }
}
```

### new 关键字（可省略）

Dart 2 起，`new` 关键字是可选的：

```dart
// Dart 1 风格
var p = new Person('小明', 25);

// Dart 2+ 风格（推荐）
var p = Person('小明', 25);
```

---

## 7.2 构造函数大全

Dart 提供了非常丰富的构造函数类型，这是 Dart 区别于大多数语言的一个特色。

### 默认构造函数

与类同名的构造函数。如果不定义任何构造函数，Dart 会提供一个无参的默认构造函数。

```dart
class Animal {
  String name;
  int age;

  // 默认构造函数
  Animal(String name, int age) {
    this.name = name;
    this.age = age;
  }
}
```

### 语法糖构造函数

Dart 独有的简洁语法，使用 `this.参数名` 自动将参数赋值给同名字段：

```dart
class Point {
  double x, y;

  // 语法糖：等价于 { this.x = x; this.y = y; }
  Point(this.x, this.y);
}
```

这是 Dart 最常用的构造函数形式，大幅减少样板代码。

### 命名构造函数

Dart 不支持构造函数重载，但可以通过命名构造函数提供多种创建对象的方式：

```dart
class Point {
  double x, y;

  Point(this.x, this.y);

  // 命名构造函数
  Point.origin()
      : x = 0,
        y = 0;

  Point.fromJson(Map<String, double> json)
      : x = json['x']!,
        y = json['y']!;
}

var p1 = Point(3, 4);
var p2 = Point.origin();
var p3 = Point.fromJson({'x': 1.0, 'y': 2.0});
```

### 初始化列表

初始化列表在构造函数体执行之前运行，用于初始化 `final` 字段或进行断言验证：

```dart
class Rectangle {
  final double width, height;

  Rectangle(double w, double h)
      : width = w,
        height = h,
        assert(w > 0, '宽度必须为正'),
        assert(h > 0, '高度必须为正');
}
```

初始化列表中不能访问 `this`，因为此时对象尚未完全构造。

### 重定向构造函数

一个构造函数可以重定向到同一个类的另一个构造函数：

```dart
class Point {
  double x, y;

  Point(this.x, this.y);

  // 重定向到主构造函数
  Point.alongXAxis(double x) : this(x, 0);
  Point.alongYAxis(double y) : this(0, y);
}
```

### 常量构造函数

如果类的所有实例变量都是 `final` 的，可以定义 `const` 构造函数，创建编译期常量对象：

```dart
class Color {
  final int r, g, b;

  const Color(this.r, this.g, this.b);

  static const red = Color(255, 0, 0);
  static const green = Color(0, 255, 0);
  static const blue = Color(0, 0, 255);
}
```

`const` 构造函数的特殊之处在于：相同参数的 `const` 实例会被复用（是同一个对象）：

```dart
var c1 = const Color(255, 0, 0);
var c2 = const Color(255, 0, 0);
print(identical(c1, c2)); // true — 同一个对象
```

### 工厂构造函数

`factory` 构造函数不一定创建新实例，它可以返回缓存的实例、子类实例或从其他来源获取的对象。最经典的应用是单例模式：

```dart
class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() {
    return _instance;
  }

  Logger._internal();

  void log(String msg) => print('[LOG] $msg');
}

// 每次调用 Logger() 都返回同一个实例
var a = Logger();
var b = Logger();
print(identical(a, b)); // true
```

---

## 7.3 getter / setter

Dart 中，每个实例变量都隐式拥有一个 getter（如果不是 `final` 还有 setter）。你也可以显式定义计算属性。

### getter 简写语法

```dart
class Rectangle {
  double width, height;

  Rectangle(this.width, this.height);

  // 计算属性：只读
  double get area => width * height;
  double get perimeter => 2 * (width + height);
  bool get isSquare => width == height;
}
```

### setter 语法与验证

```dart
class Temperature {
  double _celsius;

  Temperature(this._celsius);

  double get celsius => _celsius;
  set celsius(double value) {
    if (value < -273.15) {
      throw ArgumentError('温度不能低于绝对零度');
    }
    _celsius = value;
  }

  double get fahrenheit => _celsius * 9 / 5 + 32;
  set fahrenheit(double value) {
    celsius = (value - 32) * 5 / 9;
  }
}
```

---

## 7.4 私有成员

### 下划线 _ 前缀

Dart 使用下划线 `_` 前缀表示私有。**重要：Dart 的私有是库级别的（library-private），而不是类级别的。**

```dart
class Account {
  String _password;   // 库内可访问，库外不可访问
  final String name;

  Account(this.name, this._password);

  bool verify(String input) => input == _password;
}
```

同一个文件（库）中的代码可以直接访问 `_password`，但其他文件（库）不行。

### 库级别私有

如果想让一个类或函数只在当前文件内使用，也可以用 `_` 前缀：

```dart
// 这个类只能在当前文件内使用
class _InternalHelper {
  static String format(String s) => s.trim().toLowerCase();
}
```

---

## 7.5 静态成员

### static 变量和方法

`static` 成员属于类本身，而非某个实例：

```dart
class MathUtils {
  static const double pi = 3.14159265358979;

  static double circleArea(double radius) => pi * radius * radius;

  static int max(int a, int b) => a > b ? a : b;
}

print(MathUtils.pi);
print(MathUtils.circleArea(5));
print(MathUtils.max(3, 7));
```

### 不能访问 this

静态方法中不能使用 `this`，因为它们不关联任何实例。

### 适用场景

- **工具方法**：不依赖实例状态的纯函数。
- **常量**：类级别的配置值。
- **工厂辅助**：配合单例模式等。
- **计数器**：追踪类的实例数量。

```dart
class User {
  static int _count = 0;

  final int id;
  final String name;

  User(this.name) : id = ++_count;

  static int get totalUsers => _count;
}
```

---

## 7.6 toString / operator== / hashCode

### 重写 toString

默认的 `toString()` 返回 `Instance of 'ClassName'`，不太有用。重写它便于调试和日志输出：

```dart
class Point {
  final double x, y;
  const Point(this.x, this.y);

  @override
  String toString() => 'Point($x, $y)';
}

print(Point(3, 4)); // Point(3.0, 4.0)
```

### 值相等 vs 引用相等

默认情况下，`==` 比较的是引用（是否是同一个对象）。如果需要按值比较，必须重写 `operator==`。

```dart
var p1 = Point(3, 4);
var p2 = Point(3, 4);
print(p1 == p2); // 默认 false（不同对象）
```

### 重写 == 必须同时重写 hashCode

这是因为 Dart（和大多数语言）中有一个约定：**相等的对象必须有相同的 hashCode**。如果只重写 `==` 不重写 `hashCode`，在 Set 和 Map 中会出现不一致的行为。

```dart
class Point {
  final double x, y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point($x, $y)';
}
```

---

## 7.7 可调用类

在 Dart 中，如果一个类定义了 `call()` 方法，那么它的实例就可以像函数一样被调用。

```dart
class Multiplier {
  final int factor;
  const Multiplier(this.factor);

  int call(int value) => value * factor;
}

var triple = Multiplier(3);
print(triple(5));   // 15
print(triple(10));  // 30
```

可调用类的好处是可以携带状态（通过字段），同时像函数一样使用。它与闭包类似，但更加结构化。

```dart
class Formatter {
  final String prefix;
  final String suffix;

  const Formatter(this.prefix, this.suffix);

  String call(String text) => '$prefix$text$suffix';
}

var bracket = Formatter('[', ']');
print(bracket('hello')); // [hello]

var tag = Formatter('<b>', '</b>');
print(tag('bold'));       // <b>bold</b>
```

---

## 本章小结

| 概念 | 关键点 |
|------|--------|
| 类定义 | `class` 关键字，`new` 可省略 |
| 构造函数 | 默认、语法糖、命名、初始化列表、重定向、const、factory |
| getter/setter | 计算属性，set 中可加验证逻辑 |
| 私有成员 | `_` 前缀，库级别私有 |
| 静态成员 | `static`，属于类不属于实例 |
| toString/==/hashCode | 重写以实现值语义和调试友好 |
| 可调用类 | 定义 `call()` 方法 |

### 构造函数选择指南

| 构造函数类型 | 何时使用 |
|-------------|---------|
| 默认/语法糖 | 常规创建对象 |
| 命名构造函数 | 提供多种创建方式 |
| 初始化列表 | 初始化 final 字段、断言验证 |
| 重定向 | 减少重复代码 |
| const | 不可变对象，编译期常量 |
| factory | 单例、缓存、返回子类型 |

下一章我们将学习面向对象的高级特性：继承、抽象类、接口和 Mixin。
