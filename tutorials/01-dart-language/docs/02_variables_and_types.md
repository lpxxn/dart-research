# 第 2 章：变量与类型

## 2.1 变量声明

Dart 提供了多种声明变量的方式，理解它们的区别是写出高质量 Dart 代码的基础。

### var：类型推断

`var` 是最常用的变量声明方式。Dart 编译器会根据右侧的值自动推断变量类型，一旦类型确定就不能再赋值其他类型的值：

```dart
var name = 'Dart';      // 推断为 String
var age = 10;            // 推断为 int
var pi = 3.14;           // 推断为 double

name = 'Flutter';        // ✓ 可以赋值相同类型
// name = 42;            // ✗ 编译错误：不能将 int 赋给 String
```

也可以显式指定类型，效果和 `var` + 类型推断相同：

```dart
String name = 'Dart';
int age = 10;
double pi = 3.14;
```

注意：如果声明 `var` 时不赋初值，类型会被推断为 `dynamic`：

```dart
var x;         // 类型为 dynamic
x = 'hello';   // ✓
x = 42;        // ✓ dynamic 可以赋任何类型
```

### final：运行时常量

`final` 声明的变量只能赋值一次，之后不能再修改。与 `var` 不同的是，`final` 变量的值可以在运行时确定：

```dart
final name = 'Dart';
// name = 'Flutter';    // ✗ 编译错误：final 变量不能重新赋值

final time = DateTime.now();  // ✓ 运行时确定值
print(time);
```

### const：编译时常量

`const` 声明的是编译时常量，值必须在编译期就能确定。这意味着 `const` 变量不能依赖运行时的计算：

```dart
const pi = 3.14159;          // ✓ 字面量是编译时常量
const area = pi * 10 * 10;   // ✓ 编译时可以计算
// const time = DateTime.now(); // ✗ 编译错误：DateTime.now() 是运行时值
```

### final vs const 的核心区别

| 特性 | final | const |
|------|-------|-------|
| 赋值次数 | 只能一次 | 只能一次 |
| 值确定时机 | 运行时 | 编译时 |
| 典型用途 | 接收函数返回值、构造函数参数 | 数学常量、配置值、固定列表 |

一个关键的例子：

```dart
final currentTime = DateTime.now();   // ✓ final 可以在运行时赋值
// const currentTime = DateTime.now(); // ✗ const 必须在编译期确定

const list1 = [1, 2, 3];   // 编译时常量列表，不可修改
final list2 = [1, 2, 3];   // 运行时常量引用，列表内容可以修改
list2.add(4);               // ✓ final 只是引用不变，内容可变
// list1.add(4);            // ✗ 运行时错误：const 列表不可修改
```

## 2.2 基本类型

Dart 中一切皆对象，即使是基本类型如 `int`、`double` 也是对象，拥有自己的方法和属性。

### int：整数类型

`int` 表示任意精度的整数（在 Web 平台上为 64 位）：

```dart
int age = 25;
int hex = 0xFF;          // 十六进制
int bigNumber = 1000000;

// int 的常用方法
print(age.isEven);       // false —— 是否为偶数
print(age.isOdd);        // true  —— 是否为奇数
print(age.toDouble());   // 25.0  —— 转为 double
print(age.toString());   // '25'  —— 转为字符串
print(hex.toRadixString(2)); // '11111111' —— 转为二进制字符串
```

### double：浮点数类型

`double` 是 64 位 IEEE 754 浮点数：

```dart
double pi = 3.14159;
double exp = 1.42e5;    // 科学计数法：142000.0

// double 的常用方法
print(pi.round());       // 3     —— 四舍五入
print(pi.ceil());        // 4     —— 向上取整
print(pi.floor());       // 3     —— 向下取整
print(pi.toStringAsFixed(2)); // '3.14' —— 保留两位小数
```

### num：数字父类

`num` 是 `int` 和 `double` 的父类，如果一个变量可能是整数也可能是浮点数，可以用 `num`：

```dart
num x = 42;       // 当前是 int
x = 3.14;         // 可以赋值为 double
print(x.abs());   // 3.14 —— 绝对值
```

### String：字符串类型

Dart 的字符串是 UTF-16 编码的字符序列。更多字符串特性将在 2.3 节详细介绍。

```dart
String greeting = 'Hello, Dart!';
print(greeting.length);        // 12
print(greeting.toUpperCase()); // 'HELLO, DART!'
```

### bool：布尔类型

`bool` 只有两个值：`true` 和 `false`。Dart 不允许使用 0/1、null 或空字符串作为布尔值——条件表达式必须是明确的 `bool` 类型：

```dart
bool isReady = true;

// Dart 中不允许这样写：
// if (1) { ... }       // ✗ 编译错误
// if ('hello') { ... } // ✗ 编译错误

// 必须是明确的 bool
if (isReady) {
  print('Ready!');
}
```

### 类型字面量与方法

由于 Dart 中一切皆对象，你可以直接在字面量上调用方法：

```dart
print(42.toDouble());       // 42.0
print(3.14.round());        // 3
print('hello'.toUpperCase()); // HELLO
print(true.toString());     // 'true'
```

## 2.3 字符串详解

### 单引号 vs 双引号

在 Dart 中，单引号和双引号完全等价，没有任何功能区别。社区惯例是优先使用单引号：

```dart
var s1 = 'Hello';
var s2 = "Hello";
// s1 == s2 → true

// 在字符串中包含引号时，可以交替使用
var s3 = "It's Dart";
var s4 = 'He said "Hello"';
```

### 字符串插值

使用 `$variable` 插入变量，`${expression}` 插入表达式：

```dart
var name = 'World';
print('Hello, $name!');           // Hello, World!
print('${name.toUpperCase()}!');  // WORLD!
print('2 + 3 = ${2 + 3}');       // 2 + 3 = 5
```

### 多行字符串

使用三引号（`'''` 或 `"""`）创建多行字符串：

```dart
var poem = '''
静夜思
床前明月光
疑是地上霜
''';
```

### 原始字符串

在字符串前加 `r` 前缀，转义符将不被解释：

```dart
var path = r'C:\Users\name\Documents';   // 不会解释 \n、\U 等
print(path);  // C:\Users\name\Documents
```

### 字符串拼接

```dart
// 相邻字面量自动拼接（编译时完成）
var s1 = 'Hello'
    ' '
    'World';   // 'Hello World'

// + 运算符
var s2 = 'Hello' + ' ' + 'World';
```

### 常用字符串方法

```dart
var s = '  Hello, Dart!  ';
print(s.contains('Dart'));       // true
print(s.startsWith('  H'));      // true
print(s.substring(2, 7));        // 'Hello'
print(s.split(','));             // ['  Hello', ' Dart!  ']
print(s.trim());                 // 'Hello, Dart!'
print(s.replaceAll('Dart', 'Flutter')); // '  Hello, Flutter!  '
print('42'.padLeft(5, '0'));     // '00042'
```

## 2.4 dynamic 与 Object

### dynamic：关闭类型检查

`dynamic` 声明的变量可以赋值任何类型，并且可以调用任何方法——编译器不会做类型检查，错误要到运行时才会暴露：

```dart
dynamic x = 'Hello';
print(x.length);     // ✓ 运行时正常：5
x = 42;
// print(x.length);  // ✗ 运行时错误：int 没有 length 属性
```

### Object：所有类的基类

`Object` 是 Dart 中所有类（除 `Null`）的基类。用 `Object` 声明的变量只能调用 `Object` 上定义的方法（`toString()`、`hashCode`、`runtimeType` 等）：

```dart
Object y = 'Hello';
print(y.toString());    // ✓ Object 有 toString()
// print(y.length);     // ✗ 编译错误：Object 没有 length
```

### 何时用 dynamic

**尽量避免使用 dynamic**。在以下情况可以考虑：
- 处理 JSON 解析的动态数据
- 与平台通道（Platform Channel）交互
- 测试或原型开发中临时使用

更好的替代方案是使用泛型或类型安全的 JSON 解析库。

## 2.5 类型检查与转换

### is / is!：类型检查

`is` 运算符检查对象是否是指定类型的实例：

```dart
Object value = 'Hello';

if (value is String) {
  // 类型提升：这里 value 自动被视为 String
  print(value.toUpperCase());  // ✓ 无需手动转换
}

if (value is! int) {
  print('value 不是 int 类型');
}
```

### as：强制类型转换

`as` 用于将对象显式转换为指定类型。如果类型不匹配，会在运行时抛出 `TypeError`：

```dart
Object obj = 'Hello';
String s = obj as String;   // ✓
// int n = obj as int;      // ✗ 运行时异常：TypeError
```

### 类型提升（Type Promotion）

Dart 的类型系统非常智能。当你使用 `is` 检查类型后，编译器会在当前作用域内自动将变量"提升"为对应类型，无需手动转换：

```dart
void printLength(Object obj) {
  if (obj is String) {
    // obj 已被提升为 String 类型
    print('字符串长度: ${obj.length}');
    print('大写: ${obj.toUpperCase()}');
  } else if (obj is List) {
    // obj 已被提升为 List 类型
    print('列表长度: ${obj.length}');
  }
}
```

## 2.6 late 延迟初始化

### 用法

`late` 关键字告诉编译器："这个变量稍后一定会被初始化，请不要报未初始化错误"。

```dart
late String description;

void initialize() {
  description = '这是一个延迟初始化的变量';
}
```

### 适用场景

1. **无法在声明时初始化**：变量的初始值依赖于其他尚未创建的对象

```dart
class Config {
  late String dbUrl;

  void loadFromFile() {
    dbUrl = 'postgres://localhost/mydb';
  }
}
```

2. **延迟计算**：`late` 变量带有初始化表达式时，只在第一次访问时才会执行计算

```dart
late int result = heavyComputation();  // 只在首次访问 result 时计算
```

### 风险

如果在赋值之前访问 `late` 变量，将抛出 `LateInitializationError`：

```dart
late String name;
// print(name);  // ✗ 运行时错误：LateInitializationError

name = 'Dart';
print(name);     // ✓ 'Dart'
```

**最佳实践**：仅在确实需要延迟初始化时使用 `late`，并确保在使用前一定会赋值。优先考虑使用可空类型（`String?`）和 `final` 来替代。
