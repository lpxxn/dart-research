# 第5章：函数 (Functions)

函数是 Dart 程序的基本构建块。Dart 是一门真正的面向对象语言，但同时也是一门函数式语言——函数在 Dart 中是一等公民，可以赋值给变量、作为参数传递、作为返回值返回。本章将全面介绍 Dart 函数的方方面面。

---

## 5.1 函数声明

### 基本语法

Dart 中函数声明的标准格式为：**返回类型 + 函数名 + 参数列表 + 函数体**。

```dart
int add(int a, int b) {
  return a + b;
}

String greet(String name) {
  return '你好，$name！';
}
```

### 省略返回类型（不推荐）

Dart 允许省略返回类型，此时函数的返回类型会被推断为 `dynamic`。但这样做会丧失类型检查的优势，**不推荐在正式代码中使用**。

```dart
// 不推荐：省略返回类型
add(a, b) {
  return a + b;
}

// 推荐：显式声明返回类型
int add(int a, int b) {
  return a + b;
}
```

### void 函数

当函数不返回任何值时，使用 `void` 作为返回类型。

```dart
void sayHello(String name) {
  print('Hello, $name!');
}
```

`void` 函数中可以使用不带值的 `return;` 提前退出：

```dart
void printPositive(int n) {
  if (n < 0) return; // 提前退出
  print(n);
}
```

---

## 5.2 参数类型

Dart 提供了三种参数类型：必须位置参数、可选位置参数和命名参数。灵活运用这些参数类型可以让 API 更加清晰易用。

### 位置参数（必须）

默认情况下，函数参数是按位置传递的必须参数，调用时必须提供且顺序固定。

```dart
void greet(String name, int age) {
  print('$name 今年 $age 岁');
}

greet('小明', 18); // 必须按顺序传入两个参数
```

### 可选位置参数

用方括号 `[]` 包裹的参数是可选的，调用时可以省略。可选位置参数的类型必须是可空类型或提供默认值。

```dart
void greet(String name, [String? title, int age = 0]) {
  var prefix = title != null ? '$title ' : '';
  print('$prefix$name，年龄：$age');
}

greet('小明');              // 小明，年龄：0
greet('小明', '工程师');     // 工程师 小明，年龄：0
greet('小明', '工程师', 25); // 工程师 小明，年龄：25
```

### 命名参数

用花括号 `{}` 包裹的参数通过名字传递。命名参数默认是可选的，除非标记为 `required`。

```dart
void createUser({
  required String name,
  required String email,
  int age = 0,
  String? phone,
}) {
  print('用户：$name, 邮箱：$email, 年龄：$age, 电话：${phone ?? "未填写"}');
}

createUser(name: '小红', email: 'xh@example.com');
createUser(name: '小蓝', email: 'xl@example.com', age: 30, phone: '13800000000');
```

### 默认值

可选位置参数和命名参数都可以指定默认值。默认值必须是编译期常量。

```dart
void connect(String host, {int port = 8080, int timeout = 30}) {
  print('连接 $host:$port，超时 $timeout 秒');
}
```

### required 修饰符

`required` 用于标记命名参数为必须提供的。这在 API 设计中非常有用——既享受命名参数的可读性，又确保关键参数不被遗漏。

```dart
void sendEmail({
  required String to,
  required String subject,
  String body = '',
}) {
  print('发送邮件到 $to：$subject');
}
```

---

## 5.3 箭头函数

当函数体只有一个表达式时，可以使用箭头语法 `=>` 来简写。

```dart
// 标准写法
int add(int a, int b) {
  return a + b;
}

// 箭头函数写法（等价）
int add(int a, int b) => a + b;
```

箭头函数 `=> expression` 等价于 `{ return expression; }`。注意：

- **只能用于单个表达式**，不能包含多条语句。
- 箭头后面是表达式（expression），不是语句（statement），因此不能写 `=> if (...)`，但可以写 `=> condition ? a : b`。

```dart
// ✅ 正确：三元表达式是合法的表达式
String describe(int n) => n > 0 ? '正数' : (n < 0 ? '负数' : '零');

// ✅ void 函数也可以用箭头语法
void log(String msg) => print('[LOG] $msg');
```

---

## 5.4 函数作为一等公民

在 Dart 中，函数是对象（类型为 `Function`），因此可以像其他值一样被赋值、传递和返回。

### 赋值给变量

```dart
// 将匿名函数赋值给变量
var say = (String msg) => print(msg);
say('你好！');

// 指定类型
void Function(String) logger = (msg) => print('[INFO] $msg');
logger('服务启动');
```

### Function 类型

Dart 中可以用具体的函数签名作为类型声明：

```dart
int Function(int, int) operation;
operation = (a, b) => a + b;
print(operation(3, 4)); // 7
operation = (a, b) => a * b;
print(operation(3, 4)); // 12
```

### 作为参数传递

函数可以作为参数传递给另一个函数，这是高阶函数的基础。

```dart
void repeat(int times, void Function(int) action) {
  for (var i = 0; i < times; i++) {
    action(i);
  }
}

repeat(3, (i) => print('第 $i 次执行'));
```

### 作为返回值

函数可以作为另一个函数的返回值。

```dart
Function makeGreeter(String greeting) {
  return (String name) => '$greeting，$name！';
}

var hello = makeGreeter('你好');
print(hello('小明')); // 你好，小明！
```

---

## 5.5 闭包 (Closure)

### 定义

闭包是**捕获了其所在词法作用域中变量的函数**。即使外部函数已经返回，闭包仍然可以访问和修改这些被捕获的变量。

### 词法作用域

Dart 使用词法作用域（Lexical Scoping），即变量的作用域在编写代码时就已经确定，而非运行时确定。嵌套函数可以访问其外层作用域中的所有变量。

```dart
void outer() {
  var message = '来自外部';

  void inner() {
    print(message); // 可以访问 outer 中的 message
  }

  inner();
}
```

### 经典示例：计数器工厂

```dart
Function makeCounter() {
  var count = 0; // 被闭包捕获
  return () {
    count++;
    return count;
  };
}

var counter = makeCounter();
print(counter()); // 1
print(counter()); // 2
print(counter()); // 3
```

每次调用 `makeCounter()` 都会创建一个新的 `count` 变量，因此不同的计数器是互相独立的：

```dart
var c1 = makeCounter();
var c2 = makeCounter();
print(c1()); // 1
print(c2()); // 1（独立计数）
print(c1()); // 2
```

### 闭包的生命周期

闭包捕获的是变量本身（而非变量的值），只要闭包存在，被捕获的变量就不会被垃圾回收。这意味着：

- 闭包可以持续修改捕获的变量。
- 在循环中创建闭包时需要注意变量捕获的问题。
- 大量闭包持有大对象的引用可能导致内存泄漏。

---

## 5.6 高阶函数

高阶函数是指**接受函数作为参数**或**返回函数**的函数。Dart 的集合库大量使用了高阶函数。

### 接受函数参数

Dart 集合中内置了许多高阶函数：

```dart
var numbers = [3, 1, 4, 1, 5, 9, 2, 6];

// sort：自定义排序规则
numbers.sort((a, b) => a.compareTo(b));

// map：转换每个元素
var doubled = numbers.map((n) => n * 2);

// where：过滤元素
var evens = numbers.where((n) => n.isEven);

// reduce：聚合为单个值
var sum = numbers.reduce((a, b) => a + b);
```

### 返回函数：工厂模式

```dart
Comparator<String> createSorter({bool ascending = true}) {
  return ascending
      ? (a, b) => a.compareTo(b)
      : (a, b) => b.compareTo(a);
}

var names = ['Charlie', 'Alice', 'Bob'];
names.sort(createSorter(ascending: false));
print(names); // [Charlie, Bob, Alice]
```

### 柯里化 (Currying)

柯里化是将一个接受多个参数的函数转换为一系列接受单个参数的函数的技术。

```dart
// 普通函数
int add(int a, int b) => a + b;

// 柯里化版本
int Function(int) addCurried(int a) => (int b) => a + b;

var add5 = addCurried(5);
print(add5(3)); // 8
print(add5(7)); // 12
```

### 常用高阶函数详解

| 方法 | 功能 | 示例 |
|------|------|------|
| `map` | 转换每个元素 | `[1,2,3].map((e) => e * 2)` |
| `where` | 过滤满足条件的元素 | `[1,2,3].where((e) => e > 1)` |
| `reduce` | 从左到右聚合 | `[1,2,3].reduce((a, b) => a + b)` |
| `fold` | 带初始值的聚合 | `[1,2,3].fold(0, (a, b) => a + b)` |
| `any` | 是否有元素满足条件 | `[1,2,3].any((e) => e > 2)` |
| `every` | 是否所有元素满足 | `[1,2,3].every((e) => e > 0)` |
| `expand` | 展平嵌套 | `[[1,2],[3]].expand((e) => e)` |

---

## 5.7 typedef

`typedef` 用于为函数类型定义一个别名，使代码更具可读性。

### 旧语法（Dart 1 风格，不推荐）

```dart
typedef int OldCompare(int a, int b);
```

### 新语法（推荐）

```dart
typedef IntTransformer = int Function(int);
typedef StringCallback = void Function(String message);
typedef Comparator<T> = int Function(T a, T b);
```

### 使用示例

```dart
typedef IntTransformer = int Function(int);

// 作为参数类型
List<int> applyToAll(List<int> items, IntTransformer transformer) {
  return items.map(transformer).toList();
}

int double_(int n) => n * 2;
int square(int n) => n * n;

print(applyToAll([1, 2, 3], double_)); // [2, 4, 6]
print(applyToAll([1, 2, 3], square));  // [1, 4, 9]
```

`typedef` 也可以用于非函数类型（Dart 2.13+）：

```dart
typedef IntList = List<int>;
typedef Json = Map<String, dynamic>;
```

---

## 5.8 递归

递归是指函数在自身内部调用自己。递归是解决可分解为子问题的问题的有力工具。

### 阶乘

```dart
int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

print(factorial(5)); // 120 = 5 * 4 * 3 * 2 * 1
```

### 斐波那契数列

```dart
int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

> ⚠️ 上面的斐波那契实现时间复杂度为 O(2^n)，实际使用中应该用备忘录模式或迭代方式优化。

### 注意栈溢出

Dart 没有内置的尾递归优化（TCO），递归深度过大会导致栈溢出（StackOverflowError）。对于深度可能很大的递归，建议：

1. **改用迭代**：大多数递归都可以改写为循环。
2. **备忘录化（Memoization）**：缓存已计算的结果避免重复计算。

```dart
// 迭代版本的斐波那契
int fibIterative(int n) {
  if (n <= 1) return n;
  var a = 0, b = 1;
  for (var i = 2; i <= n; i++) {
    var temp = a + b;
    a = b;
    b = temp;
  }
  return b;
}
```

---

## 本章小结

| 概念 | 关键点 |
|------|--------|
| 函数声明 | 显式返回类型，void 表示无返回值 |
| 参数类型 | 位置必须参数、`[]` 可选位置、`{}` 命名参数 |
| 箭头函数 | `=> expr` 简写单表达式函数 |
| 一等公民 | 赋值、传参、返回均可 |
| 闭包 | 捕获外部变量，独立生命周期 |
| 高阶函数 | 接受/返回函数，集合操作核心 |
| typedef | 函数类型别名，提高可读性 |
| 递归 | 注意栈溢出，考虑迭代替代 |

下一章我们将学习 Dart 的集合类型——List、Set 和 Map，以及强大的集合操作方法。
