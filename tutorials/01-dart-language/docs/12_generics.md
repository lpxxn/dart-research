# 第12章 泛型 (Generics)

## 12.1 为什么需要泛型

在没有泛型的世界里，如果你想写一个通用的数据结构（比如栈、队列），就得面临一个两难选择：

### 方案1：为每种类型写一个版本

```dart
class IntStack {
  final List<int> _items = [];
  void push(int item) => _items.add(item);
  int pop() => _items.removeLast();
}

class StringStack {
  final List<String> _items = [];
  void push(String item) => _items.add(item);
  String pop() => _items.removeLast();
}

// 还有 DoubleStack、BoolStack... 无穷无尽
```

代码完全重复，只有类型不同——这严重违反了 DRY（Don't Repeat Yourself）原则。

### 方案2：使用 dynamic

```dart
class DynamicStack {
  final List<dynamic> _items = [];
  void push(dynamic item) => _items.add(item);
  dynamic pop() => _items.removeLast();
}
```

虽然代码只写了一份，但完全丢失了类型安全：

```dart
var stack = DynamicStack();
stack.push(42);
stack.push('hello'); // 意外混入字符串，编译器不会报错！
int value = stack.pop() as int; // 💥 运行时 TypeError
```

### 方案3：泛型 —— 两全其美

```dart
class Stack<T> {
  final List<T> _items = [];
  void push(T item) => _items.add(item);
  T pop() => _items.removeLast();
}

var intStack = Stack<int>();
intStack.push(42);
// intStack.push('hello'); // ❌ 编译错误！类型安全
int value = intStack.pop(); // ✅ 无需强转，类型已知
```

泛型让你写**一份代码**，同时保持**完整的类型安全**。

### 泛型 ≠ dynamic

这是初学者常见的困惑。关键区别在于：

| 特性 | 泛型 `<T>` | dynamic |
|------|-----------|---------|
| 类型检查 | 编译时检查 | 运行时检查 |
| 类型安全 | ✅ 安全 | ❌ 不安全 |
| 自动补全 | ✅ IDE 支持 | ❌ 无提示 |
| 性能 | 无额外开销 | 可能有拆装箱开销 |

简单记忆：**泛型 = 延迟指定但编译时确定的类型；dynamic = 放弃类型检查**。

## 12.2 泛型类

### 基本泛型类

类型参数用尖括号 `<>` 声明，惯例使用单个大写字母：

- `T` — Type（通用类型）
- `E` — Element（集合元素）
- `K`, `V` — Key, Value（键值对）
- `R` — Return（返回类型）

```dart
class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);

  T pop() {
    if (_items.isEmpty) throw StateError('栈为空');
    return _items.removeLast();
  }

  T get peek => _items.last;
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  @override
  String toString() => 'Stack($_items)';
}
```

使用时指定具体类型：

```dart
var intStack = Stack<int>();
intStack.push(1);
intStack.push(2);
print(intStack.pop()); // 2

var stringStack = Stack<String>();
stringStack.push('hello');
print(stringStack.peek); // hello
```

### 多个类型参数

泛型类可以有多个类型参数：

```dart
class Pair<A, B> {
  final A first;
  final B second;

  Pair(this.first, this.second);

  @override
  String toString() => 'Pair($first, $second)';
}

var pair = Pair<String, int>('age', 25);
print(pair.first);  // age (String 类型)
print(pair.second); // 25 (int 类型)
```

### Dart 内置的泛型类

Dart 的集合类都是泛型的：

```dart
List<int> numbers = [1, 2, 3];
Map<String, int> ages = {'Alice': 30, 'Bob': 25};
Set<String> names = {'Alice', 'Bob'};
Future<String> fetchName() async => 'Dart';
Stream<int> countDown() async* { yield 3; yield 2; yield 1; }
```

## 12.3 泛型方法

除了泛型类，你还可以在**方法级别**定义类型参数。

### 泛型函数

```dart
T first<T>(List<T> items) {
  if (items.isEmpty) throw StateError('列表为空');
  return items.first;
}

// 使用
int n = first<int>([1, 2, 3]);     // 显式指定类型
String s = first(['a', 'b', 'c']); // Dart 自动推断 T 为 String
```

### 泛型方法 vs 泛型类

```dart
// 类级别的泛型：整个类共享一个类型
class Printer<T> {
  void print(T value) => print(value);
}

// 方法级别的泛型：每次调用可以用不同类型
class Converter {
  R convert<R>(Object input) => input as R;
}

var converter = Converter();
int n = converter.convert<int>(42);
String s = converter.convert<String>('hello');
```

方法级别泛型更灵活——同一个对象的不同方法调用可以使用不同的类型。

## 12.4 泛型约束

默认情况下，类型参数 `T` 可以是任何类型。但有时我们需要限制 `T` 必须满足某些条件，这就是**泛型约束**（bounded type parameters）。

### 基本约束：extends

```dart
// T 必须是 Comparable<T> 的子类型
T max<T extends Comparable<T>>(T a, T b) {
  return a.compareTo(b) >= 0 ? a : b;
}

print(max(3, 7));           // 7
print(max('apple', 'banana')); // banana

// max(Object(), Object()); // ❌ 编译错误：Object 没有实现 Comparable
```

### 约束的意义

没有约束时，编译器只知道 `T` 是 `Object?`，不能调用任何特定方法。有了约束，编译器知道 `T` 一定有约束类型的所有方法：

```dart
// 没有约束：只能调用 Object? 的方法
void process<T>(T item) {
  // item.compareTo(...)  // ❌ 编译错误
  print(item.toString()); // ✅ Object 的方法
}

// 有约束：可以调用 Comparable 的方法
void sort<T extends Comparable<T>>(List<T> items) {
  // 可以安全地调用 compareTo
  items.sort((a, b) => a.compareTo(b));
}
```

### 多重约束的替代方案

Dart 不支持多个 `extends`（如 `T extends A & B`），但可以通过定义一个组合接口来实现：

```dart
// 定义组合接口
abstract class ComparableAndPrintable<T> implements Comparable<T> {
  String prettyPrint();
}

// 使用组合约束
void processItem<T extends ComparableAndPrintable<T>>(T item) {
  print(item.prettyPrint());
  // 也可以调用 compareTo
}
```

## 12.5 协变与类型关系

### Dart 的协变泛型

Dart 的泛型是**协变的**（covariant）：如果 `Dog` 是 `Animal` 的子类型，那么 `List<Dog>` 也是 `List<Animal>` 的子类型。

```dart
class Animal {
  String name;
  Animal(this.name);
}

class Dog extends Animal {
  Dog(super.name);
  void bark() => print('$name: 汪汪！');
}

// Dog 是 Animal 的子类型
// 所以 List<Dog> 也是 List<Animal> 的子类型
List<Dog> dogs = [Dog('旺财'), Dog('小白')];
List<Animal> animals = dogs; // ✅ 编译通过（协变）
```

### 协变的风险

协变在某些场景下会导致**运行时错误**：

```dart
List<Dog> dogs = [Dog('旺财')];
List<Animal> animals = dogs; // 协变，编译通过

// animals.add(Animal('猫咪')); // 💥 运行时错误！
// 因为 animals 的实际类型仍然是 List<Dog>，不能放入非 Dog 对象
```

这是 Dart 为了方便性而做出的设计取舍——编译时允许协变赋值，但在运行时进行类型检查。相比之下，Java 使用通配符（`List<? extends Animal>`）在编译时就限制了这种不安全操作。

### 实际中的协变

在大多数实际场景中，协变是安全且有用的：

```dart
void printAnimalNames(List<Animal> animals) {
  for (var animal in animals) {
    print(animal.name);
  }
}

List<Dog> myDogs = [Dog('旺财'), Dog('小白')];
printAnimalNames(myDogs); // ✅ 安全，只是读取，不会添加
```

只要你**只读取不写入**，协变就是完全安全的。

## 12.6 实战：Result<T, E>

用泛型和 `sealed class` 实现一个类型安全的错误处理模式——`Result<T, E>`。这是函数式编程中广泛使用的模式，比异常更适合表达"可能成功也可能失败"的操作。

### 定义 Result

```dart
sealed class Result<T, E> {
  const Result();
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}
```

### 使用 Result

```dart
Result<int, String> divide(int a, int b) {
  if (b == 0) return Failure('除数不能为零');
  return Success(a ~/ b);
}

var result = divide(10, 3);
switch (result) {
  case Success(:final value):
    print('结果: $value');
  case Failure(:final error):
    print('错误: $error');
}
```

### Result 的优势

1. **穷尽性检查**：`sealed class` + `switch` 确保你处理了成功和失败两种情况。
2. **类型安全**：成功值和错误值都有明确的类型。
3. **无异常开销**：不需要 try-catch，没有异常栈展开的性能开销。
4. **显式错误处理**：函数签名明确告诉调用者"这个操作可能失败"。

### 模拟网络请求

```dart
// 模拟用户数据
class User {
  final String name;
  final String email;
  User(this.name, this.email);
}

Result<User, String> fetchUser(int id) {
  if (id <= 0) return Failure('无效的用户 ID');
  if (id > 100) return Failure('用户不存在');
  return Success(User('用户$id', 'user$id@example.com'));
}

void main() {
  var result = fetchUser(42);
  switch (result) {
    case Success(:final value):
      print('获取成功: ${value.name} (${value.email})');
    case Failure(:final error):
      print('获取失败: $error');
  }
}
```

## 小结

泛型是 Dart 类型系统中最强大的工具之一，它让你在保持代码通用性的同时不牺牲类型安全。本章涵盖了：

1. **泛型类**：`Stack<T>`、`Pair<A, B>` 等通用数据结构的基石。
2. **泛型方法**：方法级别的类型参数化，更加灵活。
3. **泛型约束**：`T extends Comparable<T>` 限制类型参数必须满足的条件。
4. **协变**：`List<Dog>` 是 `List<Animal>` 的子类型——方便但需注意写入安全。
5. **Result 模式**：泛型 + sealed class 实现的函数式错误处理，比异常更优雅。

掌握泛型，你就掌握了编写**类型安全、高度复用**代码的钥匙。在实际项目中，泛型无处不在——从集合操作到状态管理，从网络请求到数据库访问，几乎每个有意义的抽象都离不开泛型的支持。
