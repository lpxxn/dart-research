# 第15章：Dart 3 新特性 — Records、Patterns 与密封类

Dart 3 带来了一系列重大的语言特性更新，让 Dart 在类型安全和表达力上迈出了一大步。本章将深入讲解这些新特性。

---

## 15.1 Records（记录类型）

### 什么是 Records

Records 是 Dart 3 引入的**匿名复合类型**，可以将多个值打包成一个轻量级的对象，无需定义专门的类。

### 位置记录

```dart
// 定义一个包含 String 和 int 的记录
(String, int) person = ('Tom', 20);

// 访问：使用 $1, $2 ... (从 $1 开始)
print(person.$1);  // Tom
print(person.$2);  // 20
```

### 命名记录

```dart
// 使用命名字段
({String name, int age}) person = (name: 'Tom', age: 20);

// 访问：使用字段名
print(person.name);  // Tom
print(person.age);   // 20
```

### 混合使用

```dart
// 位置 + 命名混合
(String, int, {bool active}) record = ('hello', 42, active: true);
print(record.$1);      // hello
print(record.$2);      // 42
print(record.active);  // true
```

### 为什么需要 Records

**场景1：函数返回多个值**

以前要么定义一个类，要么返回 Map/List，都不够优雅：

```dart
// ❌ 旧方式：返回 Map（类型不安全）
Map<String, dynamic> divide(int a, int b) =>
    {'quotient': a ~/ b, 'remainder': a % b};

// ✅ Records 方式：类型安全又简洁
(int quotient, int remainder) divide(int a, int b) =>
    (a ~/ b, a % b);

var (q, r) = divide(17, 5);
print('商: $q, 余数: $r');  // 商: 3, 余数: 2
```

**场景2：临时组合数据**

```dart
// 用 Record 作为 Map 的复合键
var scores = <(String, String), int>{};
scores[('Alice', '数学')] = 95;
scores[('Alice', '英语')] = 88;
```

### Records 是值类型

Records 的相等性基于**内容**，而非引用：

```dart
var a = (1, 2);
var b = (1, 2);
print(a == b);  // true！内容相同即相等
print(a.hashCode == b.hashCode);  // true
```

---

## 15.2 Patterns（模式匹配）

Patterns 是 Dart 3 最强大的新特性之一。它允许你**匹配**和**解构**数据结构。

### 变量解构

```dart
// Record 解构
var (name, age) = ('Tom', 20);
print('$name is $age');

// 交换两个变量——一行搞定！
var (a, b) = (1, 2);
(a, b) = (b, a);  // 交换！
print('a=$a, b=$b');  // a=2, b=1
```

### 列表解构

```dart
var list = [1, 2, 3, 4, 5];

// 取前两个和剩余
var [first, second, ...rest] = list;
print('$first, $second, $rest');  // 1, 2, [3, 4, 5]

// 只取首尾
var [head, ..., tail] = list;
print('$head, $tail');  // 1, 5
```

### Map 解构

```dart
var json = {'name': 'Alice', 'age': 25, 'city': '北京'};

var {'name': name, 'age': age} = json;
print('$name, $age');  // Alice, 25
```

### 对象解构

```dart
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

var point = Point(3, 4);
var Point(:x, :y) = point;  // 解构对象属性
print('x=$x, y=$y');  // x=3, y=4
```

### switch 中的模式匹配

```dart
// 类型匹配
String describe(Object obj) {
  return switch (obj) {
    int n when n > 0   => '正整数: $n',
    int n when n < 0   => '负整数: $n',
    int()              => '零',
    String s           => '字符串: "$s"',
    (int x, int y)     => '坐标: ($x, $y)',
    [int a, int b, ...] => '列表，前两个: $a, $b',
    _                  => '其他类型',
  };
}
```

### 守卫子句 (when)

`when` 关键字在匹配成功后添加额外条件：

```dart
String classify(int n) => switch (n) {
  int x when x < 0   => '负数',
  0                   => '零',
  int x when x <= 10  => '小正数',
  int x when x <= 100 => '中等正数',
  _                   => '大正数',
};
```

### 逻辑模式

```dart
// OR 模式
String dayType(String day) => switch (day) {
  'Monday' || 'Tuesday' || 'Wednesday' || 'Thursday' || 'Friday' => '工作日',
  'Saturday' || 'Sunday' => '周末',
  _ => '无效',
};

// AND 模式（较少用）
// case int n && > 0:  // n 是 int 且 > 0
```

---

## 15.3 switch 表达式

Dart 3 将 `switch` 从语句升级为**表达式**——可以返回值！

### 基本语法

```dart
// switch 表达式（注意：用 => 而非 :，用 , 分隔）
var message = switch (statusCode) {
  200 => 'OK',
  301 => '永久重定向',
  404 => '未找到',
  500 => '服务器错误',
  _ => '未知状态码',
};
```

对比传统 switch 语句：

```dart
// 传统 switch 语句
String message;
switch (statusCode) {
  case 200:
    message = 'OK';
    break;
  case 404:
    message = '未找到';
    break;
  default:
    message = '未知';
}
```

switch 表达式明显更简洁。

### 配合 Patterns 使用

```dart
String describeList(List<int> list) => switch (list) {
  []          => '空列表',
  [var a]     => '单元素: $a',
  [var a, var b] => '两个元素: $a, $b',
  [var a, ..., var z] => '首: $a, 尾: $z, 共 ${list.length} 个',
};
```

### 穷尽检查

当 switch 表达式用于枚举或密封类时，编译器会检查是否覆盖了所有情况：

```dart
enum Color { red, green, blue }

// ❌ 编译错误：没有覆盖 blue
var name = switch (color) {
  Color.red => '红',
  Color.green => '绿',
};

// ✅ 覆盖所有枚举值
var name = switch (color) {
  Color.red => '红',
  Color.green => '绿',
  Color.blue => '蓝',
};
```

---

## 15.4 if-case

`if-case` 将模式匹配的能力带入 `if` 语句，非常适合**条件解构**。

### 基本语法

```dart
var json = {'name': 'Alice', 'age': 25};

// 如果 json 匹配这个模式，则执行 if 体
if (json case {'name': String name, 'age': int age}) {
  print('$name 今年 $age 岁');
} else {
  print('JSON 格式不正确');
}
```

### 实际应用：API 响应解析

```dart
void handleResponse(Map<String, dynamic> response) {
  if (response case {'status': 'ok', 'data': Map data}) {
    print('成功: $data');
  } else if (response case {'status': 'error', 'message': String msg}) {
    print('失败: $msg');
  } else {
    print('未知响应格式');
  }
}
```

### 配合 when 子句

```dart
if (value case int n when n.isEven && n > 0) {
  print('$n 是正偶数');
}
```

---

## 15.5 sealed class 密封类

### 什么是密封类

`sealed` 修饰的类有两个特性：
1. **抽象**：不能直接实例化
2. **密封**：只能在**同一个库**中被继承/实现

编译器因此知道一个 sealed class 的**所有子类**，可以在 switch 中进行**穷尽检查**。

### 定义

```dart
sealed class Shape {}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}

class Square extends Shape {
  final double side;
  Square(this.side);
}

class Triangle extends Shape {
  final double base;
  final double height;
  Triangle(this.base, this.height);
}
```

### 穷尽 switch

```dart
double area(Shape shape) => switch (shape) {
  Circle(radius: var r)           => 3.14159 * r * r,
  Square(side: var s)             => s * s,
  Triangle(base: var b, height: var h) => 0.5 * b * h,
  // 不需要 _ 通配符！编译器知道所有子类都已覆盖
};
```

如果你新增了一个 `Rectangle extends Shape` 但忘记在 switch 中处理它，编译器会**报错**——这就是密封类的威力。

### 与枚举的对比

| 特性 | enum | sealed class |
|------|------|-------------|
| 子类型 | 固定的枚举值 | 可以是不同的类（带不同字段） |
| 数据 | 每个枚举值字段相同 | 每个子类可有独特字段 |
| 穷尽检查 | ✅ | ✅ |
| 适用场景 | 简单枚举状态 | 多态数据结构（AST、状态机等） |

### 应用场景

密封类非常适合表示：
- **代数数据类型（ADT）**：Result<T> = Success<T> | Failure
- **抽象语法树（AST）**：Expression = Literal | BinaryOp | UnaryOp
- **状态机**：State = Loading | Loaded | Error
- **网络结果**：ApiResult = Success | NetworkError | ServerError

```dart
// 通用结果类型
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T value;
  Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  Failure(this.message);
}

// 使用
String display<T>(Result<T> result) => switch (result) {
  Success(value: var v) => '成功: $v',
  Failure(message: var m) => '失败: $m',
};
```

---

## 15.6 Class Modifiers（类修饰符）

Dart 3 引入了一组**类修饰符**，让 API 作者可以精确控制类的使用方式。

### 修饰符一览

| 修饰符 | 可继承 (extends) | 可实现 (implements) | 可实例化 |
|--------|:-:|:-:|:-:|
| `class` | ✅ | ✅ | ✅ |
| `base class` | ✅ | ❌ | ✅ |
| `interface class` | ❌ | ✅ | ✅ |
| `final class` | ❌ | ❌ | ✅ |
| `sealed class` | ✅ (同库) | ✅ (同库) | ❌ |
| `abstract class` | ✅ | ✅ | ❌ |
| `mixin class` | ✅ | ✅ | ✅ (可作 mixin) |

> **注意**：以上限制仅对**库外**代码生效。在**同一个库**中，所有类都可以自由继承和实现。

### base class

`base` 类可以被继承，但不能被实现（implements）：

```dart
base class Animal {
  void breathe() => print('呼吸');
}

class Dog extends Animal {}           // ✅ 可以继承
// class FakeAnimal implements Animal {}  // ❌ 不能 implements
```

**用途**：当你的类有内部状态和行为，不希望外部代码绕过它们。

### interface class

`interface` 类只能被实现，不能被继承：

```dart
interface class Printable {
  void printSelf() => print(toString());
}

class Doc implements Printable {         // ✅ 可以 implements
  @override
  void printSelf() => print('文档内容');
}
// class SubPrintable extends Printable {}  // ❌ 不能 extends
```

**用途**：定义接口契约，确保实现者提供所有方法的自定义实现。

### final class

`final` 类既不能被继承也不能被实现：

```dart
final class Config {
  final String apiUrl;
  Config(this.apiUrl);
}

// class MyConfig extends Config {}     // ❌
// class FakeConfig implements Config {} // ❌
```

**用途**：确保类的行为完全由库作者控制。

### mixin class

`mixin class` 既可以作为普通类使用，也可以作为 mixin 混入：

```dart
mixin class Logger {
  void log(String msg) => print('[LOG] $msg');
}

// 作为 mixin 使用
class Service with Logger {
  void doWork() {
    log('开始工作');
  }
}

// 作为普通类使用
var logger = Logger();
logger.log('直接使用');
```

### 组合使用

修饰符可以组合：

```dart
abstract base class Repository {
  Future<void> save(Object entity);
  Future<Object?> find(int id);
}

abstract interface class Serializable {
  Map<String, dynamic> toJson();
}

base mixin class Cacheable {
  final _cache = <String, dynamic>{};
  void cache(String key, dynamic value) => _cache[key] = value;
  dynamic getCache(String key) => _cache[key];
}
```

---

## 15.7 小结

Dart 3 的新特性大幅提升了语言的表达力和类型安全性：

| 特性 | 核心价值 |
|------|---------|
| Records | 轻量级复合类型，替代临时类和 Map |
| Patterns | 强大的解构和匹配能力 |
| switch 表达式 | 简洁的返回值 switch |
| if-case | 条件解构，优雅的类型检查 |
| sealed class | 穷尽检查 + 代数数据类型 |
| Class Modifiers | 精确控制 API 的使用方式 |

这些特性组合在一起，让 Dart 成为一门更加现代化、更安全的编程语言。特别是 **sealed class + Patterns + switch 表达式** 的组合，几乎可以替代传统的访问者模式（Visitor Pattern），代码更简洁，类型更安全。

下一章我们将综合运用所学知识，构建一个完整的命令行待办事项应用。
