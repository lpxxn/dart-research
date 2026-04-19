# 第9章 空安全 (Null Safety)

## 9.1 什么是空安全

在编程语言的发展历史中，**空引用错误**（Null Reference Error）堪称最臭名昭著的 bug 来源之一。Tony Hoare——null 引用的发明者——曾将其称为"十亿美元的错误"。在没有空安全机制的语言中，任何变量都可能是 `null`，而你只有在运行时才能发现这个问题——程序突然崩溃，抛出 `NoSuchMethodError` 或 `NullPointerException`。

Dart 从 **2.12** 版本开始默认启用**健全的空安全**（Sound Null Safety），这意味着：

- **类型默认不可空**：`String`、`int`、`List` 等类型的变量不能赋值为 `null`。
- **可空必须显式声明**：只有声明为 `String?`、`int?` 等可空类型的变量才能持有 `null`。
- **编译期检查**：编译器会在编译阶段就发现潜在的空引用错误，而不是等到运行时。

空安全的核心目标是将**运行时空引用错误**提前到**编译期**暴露，大幅减少线上崩溃。

```dart
String name = 'Dart';  // ✅ 正确，不可空类型
String name = null;     // ❌ 编译错误！String 类型不能为 null

String? nickname = null; // ✅ 正确，可空类型可以为 null
```

## 9.2 可空类型 vs 不可空类型

Dart 空安全的类型系统中，每个类型都有两个变体：

| 类型 | 含义 | 能否为 null |
|------|------|-------------|
| `String` | 不可空字符串 | ❌ 不能 |
| `String?` | 可空字符串 | ✅ 可以 |
| `int` | 不可空整数 | ❌ 不能 |
| `int?` | 可空整数 | ✅ 可以 |

### 类型层次关系

在 Dart 的类型系统中，`Null` 是一个独立的类型，它唯一的实例就是 `null`。可空类型 `String?` 本质上等价于 `String | Null` 的联合类型——它表示"要么是一个 `String`，要么是 `null`"。

```
        Object?
       /       \
    Object     Null
   /   |  \
String int  ...
```

- `Object?` 是所有类型的顶层类型（Top Type），任何值都是 `Object?` 类型。
- `Object` 是所有**非空**类型的顶层类型。
- `Null` 类型只有一个值：`null`。
- `Never` 是底层类型（Bottom Type），表示永远不会产生值（比如总是抛异常的函数）。

### 赋值规则

```dart
String greeting = 'Hello'; // 不可空类型
// greeting = null;  // ❌ 编译错误

String? farewell = 'Goodbye'; // 可空类型
farewell = null;               // ✅ 没问题

// 不可空可以赋值给可空（子类型关系）
String? maybeName = greeting;  // ✅ String 是 String? 的子类型

// 可空不能直接赋值给不可空
// String definite = farewell;  // ❌ 编译错误
String definite = farewell ?? 'default'; // ✅ 提供默认值
```

## 9.3 空安全操作符全家福

Dart 提供了一系列操作符来优雅地处理可空类型，避免冗长的 `if (x != null)` 判断。

### `?.` 安全访问操作符

当对象可能为 null 时，用 `?.` 安全地访问属性或调用方法。如果对象是 `null`，整个表达式返回 `null`，而不是抛异常。

```dart
String? name = null;
int? length = name?.length;  // length 为 null，不会抛异常
print(length); // null
```

### `??` 空合并操作符

当表达式的值可能为 null 时，用 `??` 提供一个默认值。

```dart
String? name = null;
String displayName = name ?? 'unknown'; // 'unknown'
```

### `??=` 空合并赋值操作符

仅当变量当前为 `null` 时才赋值。

```dart
String? name;
name ??= 'default'; // name 现在是 'default'
name ??= 'other';   // name 仍然是 'default'，因为已经不是 null 了
```

### `!` 空断言操作符

当你确信某个可空变量在此处一定不为 null 时，使用 `!` 进行断言。如果运行时实际为 null，会抛出异常。

```dart
String? name = getName(); // 可能返回 null
// 如果你确信此处 name 一定不为 null：
int length = name!.length; // 如果 name 真的为 null，抛出 TypeError
```

> ⚠️ **警告**：滥用 `!` 等于放弃了空安全的保护。尽量用 `??` 或类型提升替代。

### `?[]` 空感知索引操作符

安全地访问可空列表或映射的元素。

```dart
List<int>? numbers = null;
int? first = numbers?[0]; // null，不会抛异常

Map<String, int>? scores = null;
int? score = scores?['math']; // null
```

### `...?` 空感知展开操作符

在集合字面量中，安全地展开一个可能为 null 的集合。

```dart
List<int>? extra = null;
var list = [1, 2, 3, ...?extra]; // [1, 2, 3]
```

### 链式空安全

多个 `?.` 可以链式调用，任何一环为 null 就短路返回 null：

```dart
String? city = user?.address?.city?.toUpperCase();
// 如果 user、address 或 city 任一为 null，结果都是 null
```

## 9.4 类型提升 (Type Promotion)

Dart 编译器足够智能，能够通过**控制流分析**自动将可空类型"提升"为非空类型。

### null 检查后自动提升

```dart
void greet(String? name) {
  if (name == null) {
    print('Hello, stranger!');
    return;
  }
  // 这里 name 自动提升为 String（非空）
  print('Hello, ${name.toUpperCase()}!'); // 无需 name! 或 name?.
}
```

### is 检查后提升

```dart
void process(Object? value) {
  if (value is String) {
    // value 自动提升为 String
    print(value.toUpperCase());
  }
}
```

### 局部变量 vs 字段

**重要限制**：类型提升只对**局部变量**生效，对**实例字段**不生效。

原因在于：实例字段可能被其他代码修改（getter 可能每次返回不同值，其他线程可能写入 null），编译器无法保证检查之后字段仍然非空。

```dart
class MyClass {
  String? name;

  void printName() {
    if (name != null) {
      // ❌ name 仍然是 String? 类型，不会自动提升
      // print(name.length); // 编译错误
    }

    // 解决方案1：使用局部变量
    final localName = name;
    if (localName != null) {
      print(localName.length); // ✅ 局部变量可以提升
    }

    // 解决方案2：使用 ! 断言（确信安全时）
    if (name != null) {
      print(name!.length); // ✅ 但有一点风险
    }
  }
}
```

## 9.5 late 关键字

`late` 修饰符用于告诉编译器："这个变量虽然现在没有初始化，但我保证在使用之前一定会给它赋值。"

### late 延迟初始化

```dart
late String description;

void init() {
  description = '这是一个延迟初始化的变量';
}

void main() {
  init();
  print(description); // ✅ 正常使用
}
```

### late final

`late final` 结合了延迟初始化和只赋值一次的特性：

```dart
late final String config;
config = loadConfig();  // 第一次赋值 ✅
// config = 'other';    // ❌ 再次赋值会抛异常
```

### late 的惰性计算特性

当 `late` 变量有初始化表达式时，该表达式只在变量**首次被访问**时执行。这对于昂贵的计算非常有用：

```dart
class DataProcessor {
  late var heavyResult = _doExpensiveWork();

  int _doExpensiveWork() {
    print('执行耗时计算...');
    return 42;
  }
}

// heavyResult 只有在第一次被读取时才会执行 _doExpensiveWork()
// 如果从未读取，计算就不会发生
```

### LateInitializationError

如果在赋值之前就访问 `late` 变量，会抛出 `LateInitializationError`：

```dart
late String name;
print(name); // 💥 LateInitializationError: Field 'name' has not been initialized.
```

## 9.6 required 关键字

在 Dart 中，命名参数默认是**可选的**。在空安全环境下，如果一个命名参数是非空类型且没有默认值，就必须标记为 `required`。

```dart
// 没有 required 时，age 必须是可空类型或有默认值
void greet1({String? name, int age = 0}) {
  print('$name, $age');
}

// 有 required 时，调用者必须传参，参数可以是非空类型
void greet2({required String name, required int age}) {
  print('$name, $age');
}

greet2(name: 'Alice', age: 30); // ✅
// greet2(name: 'Bob');          // ❌ 编译错误：缺少 required 参数 age
```

`required` 与空安全的配合使得 API 设计更加清晰：调用者明确知道哪些参数是必须提供的，且函数内部不需要处理 null 的情况。

## 9.7 最佳实践

### 1. 尽量使用非空类型

默认使用非空类型，只在真正需要表达"可能没有值"的语义时才用可空类型。

```dart
// ❌ 不好：没必要的可空
String? name = 'Alice';

// ✅ 好：明确不可空
String name = 'Alice';
```

### 2. 在边界处处理 null

在程序的"边界"（解析 JSON、读取数据库、调用 API）处理 null，将数据转换为非空类型后传入内部逻辑。

```dart
// 边界层：处理可能的 null
User parseUser(Map<String, dynamic> json) {
  return User(
    name: json['name'] as String? ?? 'unknown',
    age: json['age'] as int? ?? 0,
  );
}

// 内部逻辑：全部使用非空类型
void processUser(User user) {
  print(user.name.toUpperCase()); // 安心使用，不需要 null 检查
}
```

### 3. 避免滥用 `!` 操作符

`!` 操作符本质上是在告诉编译器"闭嘴，我知道我在干什么"。滥用它等于放弃了空安全的保护。

```dart
// ❌ 危险：到处用 !
void printLength(String? s) {
  print(s!.length); // 如果 s 是 null 就崩溃了
}

// ✅ 安全：用 ?? 或条件判断
void printLength(String? s) {
  print(s?.length ?? 0);
}
```

### 4. 善用类型提升

```dart
// ❌ 笨拙
void process(String? value) {
  if (value != null) {
    print(value!.toUpperCase()); // ! 是多余的
  }
}

// ✅ 优雅
void process(String? value) {
  if (value != null) {
    print(value.toUpperCase()); // 编译器已经知道 value 不为 null
  }
}
```

### 5. 合理使用 late

`late` 适用场景：
- 依赖注入时的延迟初始化
- 循环引用需要先声明后赋值
- 昂贵计算的惰性求值

`late` 不适用场景：
- 可以在声明时就初始化的变量（直接赋值即可）
- 不确定是否会在使用前赋值（用可空类型 + null 检查更安全）

## 小结

空安全是 Dart 语言最重要的特性之一，它通过类型系统在编译期消除了大量潜在的空引用错误。掌握空安全的核心概念——可空与不可空类型、空安全操作符、类型提升、`late` 和 `required` 关键字——对于编写健壮的 Dart 代码至关重要。记住核心原则：**默认不可空，需要时才可空；在边界处理 null，在内部享受类型安全**。
