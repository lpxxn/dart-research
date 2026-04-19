# 第8章：面向对象进阶 (OOP Advanced)

上一章我们学习了类的基础知识。本章将深入探讨面向对象的高级特性：继承、方法重写、抽象类、接口和 Mixin。这些特性让 Dart 能够优雅地组织复杂的类层次结构。

---

## 8.1 继承 extends

### 单继承

Dart 支持单继承——一个类只能有一个直接父类。使用 `extends` 关键字声明继承关系。

```dart
class Animal {
  String name;

  Animal(this.name);

  void eat() => print('$name 正在吃东西');
}

class Dog extends Animal {
  String breed;

  Dog(super.name, this.breed);

  void bark() => print('$name 汪汪叫！');
}

var dog = Dog('旺财', '柴犬');
dog.eat();  // 继承的方法：旺财 正在吃东西
dog.bark(); // 自己的方法：旺财 汪汪叫！
```

### super 调用父类构造函数

子类构造函数必须调用父类的某个构造函数。Dart 3 引入了 `super.参数` 的简洁语法：

```dart
class Animal {
  String name;
  int age;

  Animal(this.name, this.age);
  Animal.baby(this.name) : age = 0;
}

class Cat extends Animal {
  String color;

  // Dart 3 语法：super.name 和 super.age 自动传递给父类
  Cat(super.name, super.age, this.color);

  // 调用父类的命名构造函数
  Cat.kitten(String name, this.color) : super.baby(name);
}
```

### 初始化列表中的 super

在 Dart 3 之前（或需要复杂初始化时），在初始化列表末尾调用 `super`：

```dart
class Employee extends Person {
  String company;

  Employee(String name, int age, this.company)
      : super(name, age);
}
```

`super()` 调用必须放在初始化列表的最后。

---

## 8.2 方法重写 @override

### @override 注解

子类可以重写父类的方法。`@override` 注解不是强制的，但强烈推荐使用，它能帮助编译器检查你确实在重写一个父类方法：

```dart
class Animal {
  void makeSound() => print('...');
}

class Dog extends Animal {
  @override
  void makeSound() => print('汪汪！');
}

class Cat extends Animal {
  @override
  void makeSound() => print('喵喵！');
}
```

### super.method() 调用父类方法

在重写的方法中，可以通过 `super.method()` 调用父类的原始实现：

```dart
class Shape {
  String describe() => '这是一个形状';
}

class Circle extends Shape {
  double radius;

  Circle(this.radius);

  @override
  String describe() => '${super.describe()}，具体是一个半径为 $radius 的圆';
}
```

### covariant 参数

默认情况下，子类重写方法时参数类型必须与父类一致（或更宽泛）。使用 `covariant` 关键字可以缩小参数类型：

```dart
class Animal {
  void chase(covariant Animal other) {
    print('追逐 $other');
  }
}

class Dog extends Animal {
  @override
  void chase(Dog other) {
    // 参数类型从 Animal 缩小到 Dog
    print('狗追狗：$other');
  }
}
```

> ⚠️ `covariant` 把类型安全的检查推迟到了运行时，使用需谨慎。

---

## 8.3 抽象类 abstract class

### 不能实例化

抽象类使用 `abstract` 修饰符声明，不能直接实例化，只能被继承：

```dart
abstract class Shape {
  // 抽象方法：没有方法体，子类必须实现
  double get area;
  double get perimeter;

  // 具体方法：有默认实现，子类可以直接使用或重写
  void describe() {
    print('面积: $area，周长: $perimeter');
  }
}

// var s = Shape(); // 编译错误！不能实例化抽象类
```

### 抽象方法

没有方法体的方法就是抽象方法。子类必须实现所有抽象方法，否则子类自身也必须声明为抽象类：

```dart
class Circle extends Shape {
  final double radius;

  Circle(this.radius);

  @override
  double get area => 3.14159 * radius * radius;

  @override
  double get perimeter => 2 * 3.14159 * radius;
}

class Rectangle extends Shape {
  final double width, height;

  Rectangle(this.width, this.height);

  @override
  double get area => width * height;

  @override
  double get perimeter => 2 * (width + height);
}
```

### 作为模板方法模式

抽象类可以定义算法的骨架，将某些步骤交给子类实现——这就是模板方法模式：

```dart
abstract class DataParser {
  // 模板方法：定义解析流程
  List<Map<String, dynamic>> parse(String raw) {
    var lines = splitLines(raw);
    var filtered = lines.where((l) => l.isNotEmpty).toList();
    return filtered.map(parseLine).toList();
  }

  // 抽象方法：由子类决定如何分行和解析
  List<String> splitLines(String raw);
  Map<String, dynamic> parseLine(String line);
}
```

---

## 8.4 接口 implements

### 每个类都隐式定义了接口

Dart 没有专门的 `interface` 关键字。每个类都隐式定义了一个接口，包含了类的所有公开成员。任何类都可以通过 `implements` 来实现另一个类的接口。

```dart
class Printable {
  void printInfo() => print('Printable info');
}

// 实现 Printable 接口
class Student implements Printable {
  final String name;

  Student(this.name);

  @override
  void printInfo() => print('学生：$name');
}
```

### 必须实现所有成员

与 `extends` 不同，`implements` 要求你**重新实现所有成员**（包括方法和属性），不会继承任何实现代码：

```dart
class JsonSerializable {
  Map<String, dynamic> toJson() => {};
  String toJsonString() => toJson().toString();
}

// 必须实现 toJson 和 toJsonString
class User implements JsonSerializable {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  @override
  String toJsonString() => toJson().toString();
}
```

### 可以实现多个接口

```dart
class Saveable {
  void save() {}
}

class Deletable {
  void delete() {}
}

class Document implements Saveable, Deletable {
  @override
  void save() => print('保存文档');

  @override
  void delete() => print('删除文档');
}
```

### extends vs implements 的选择

| 方面 | extends | implements |
|------|---------|------------|
| 数量 | 只能一个 | 可以多个 |
| 继承代码 | 是，继承所有实现 | 否，必须全部重写 |
| 语义 | "是一种" (is-a) | "能做到" (can-do) |
| 典型用途 | 代码复用 | 定义契约 |

---

## 8.5 Mixin

### 什么是 Mixin

Mixin 是一种在多个类之间**复用代码**的机制。它解决了单继承的局限性——通过 Mixin，一个类可以"混入"多个能力，而不需要多重继承。

### mixin 关键字声明

```dart
mixin Swimmer {
  void swim() => print('$runtimeType 正在游泳 🏊');
}

mixin Flyer {
  void fly() => print('$runtimeType 正在飞翔 🦅');
}

mixin Runner {
  void run() => print('$runtimeType 正在奔跑 🏃');
}
```

### with 关键字使用

使用 `with` 将 Mixin 混入到类中：

```dart
class Animal {
  String name;
  Animal(this.name);
}

class Duck extends Animal with Swimmer, Flyer {
  Duck(super.name);
}

class Dog extends Animal with Swimmer, Runner {
  Dog(super.name);
}

var duck = Duck('唐老鸭');
duck.swim(); // Duck 正在游泳 🏊
duck.fly();  // Duck 正在飞翔 🦅

var dog = Dog('旺财');
dog.swim();  // Dog 正在游泳 🏊
dog.run();   // Dog 正在奔跑 🏃
```

### on 约束

`on` 关键字限制 Mixin 只能应用于特定父类的子类。这允许 Mixin 安全地访问父类的成员：

```dart
class Musician {
  String name;
  Musician(this.name);

  void perform() => print('$name 开始表演');
}

// 这个 Mixin 只能用在 Musician 的子类上
mixin Singer on Musician {
  void sing() {
    perform(); // 可以安全地调用 Musician 的方法
    print('$name 正在唱歌 🎤');
  }
}

mixin Guitarist on Musician {
  void playGuitar() {
    perform();
    print('$name 正在弹吉他 🎸');
  }
}

class RockStar extends Musician with Singer, Guitarist {
  RockStar(super.name);
}
```

### 多个 Mixin 的线性化顺序

当多个 Mixin 定义了同名方法时，Dart 使用**线性化**来确定调用顺序。规则很简单：**最后 `with` 的 Mixin 优先**。

```dart
mixin A {
  String greet() => 'A';
}

mixin B {
  String greet() => 'B';
}

class MyClass with A, B {}

print(MyClass().greet()); // 输出 'B'，因为 B 在 A 后面
```

这形成了一个线性的方法解析顺序（MRO）：`MyClass -> B -> A -> Object`。

### mixin class（Dart 3）

Dart 3 引入了 `mixin class`，同时可以作为普通类和 Mixin 使用：

```dart
mixin class Describable {
  String describe() => '我是 $runtimeType';
}

// 作为普通类使用
class A extends Describable {}

// 作为 Mixin 使用
class B with Describable {}
```

> 注意：`mixin class` 不能使用 `on` 约束，因为普通类不支持 `on`。

---

## 8.6 选择指南

### extends vs implements vs mixin

在设计类层次结构时，选择哪种机制取决于你想表达的关系：

- **extends（继承）**：表达 **"是什么"** 的关系。
  - 示例：`Dog extends Animal`——狗**是**动物。
  - 继承父类的所有实现代码。
  - 只能单继承。

- **implements（接口）**：表达 **"能做什么"** 的关系。
  - 示例：`JsonUser implements Serializable`——用户**能被**序列化。
  - 不继承任何代码，必须全部自己实现。
  - 可以实现多个接口。

- **mixin（混入）**：表达 **"附加能力"** 的关系。
  - 示例：`Duck with Swimmer, Flyer`——鸭子**拥有**游泳和飞翔的能力。
  - 复用代码但不建立父子关系。
  - 可以混入多个 Mixin。

### 实际案例：动物类层次

```dart
// 基类：所有动物共有的属性和行为
abstract class Animal {
  String name;
  Animal(this.name);
  void eat() => print('$name 正在进食');
}

// 能力 Mixin
mixin Swimmer on Animal {
  void swim() => print('$name 在水里游');
}

mixin Flyer on Animal {
  void fly() => print('$name 在天上飞');
}

// 接口：定义契约
abstract class Domesticated {
  String get owner;
  void obey();
}

// 具体类：组合继承、Mixin 和接口
class Pet extends Animal with Swimmer implements Domesticated {
  @override
  final String owner;

  Pet(super.name, this.owner);

  @override
  void obey() => print('$name 听从 $owner 的命令');
}
```

### 决策流程图

1. **需要复用已有代码？**
   - 是 → 考虑 `extends` 或 `mixin`
   - 否 → 考虑 `implements`

2. **是"是什么"关系吗？**
   - 是 → 使用 `extends`
   - 否 → 继续判断

3. **需要在多个无关类之间共享代码？**
   - 是 → 使用 `mixin`
   - 否 → 使用 `extends`

4. **需要强制实现一组方法？**
   - 是 → 使用 `implements`

5. **需要同时继承、混入和实现？**
   - Dart 允许：`class A extends B with C, D implements E, F`

---

## 本章小结

| 特性 | 关键字 | 数量限制 | 代码复用 | 典型用途 |
|------|--------|---------|---------|---------|
| 继承 | `extends` | 单个 | ✅ 继承实现 | is-a 关系 |
| 接口 | `implements` | 多个 | ❌ 全部重写 | can-do 契约 |
| Mixin | `with` | 多个 | ✅ 混入代码 | 附加能力 |
| 抽象类 | `abstract` | — | 部分 | 模板、契约 |

| 概念 | 说明 |
|------|------|
| @override | 标记方法重写，推荐始终使用 |
| super | 调用父类构造函数或方法 |
| covariant | 允许子类缩小参数类型 |
| on | 限制 Mixin 的适用范围 |
| mixin class | Dart 3 新特性，类与 Mixin 双重身份 |
| 线性化 | 多 Mixin 同名方法按声明顺序解析 |

掌握了这些面向对象的高级特性，你就能设计出灵活、可扩展的 Dart 应用架构。下一章我们将学习 Dart 的枚举、扩展方法和更多高级类特性。
