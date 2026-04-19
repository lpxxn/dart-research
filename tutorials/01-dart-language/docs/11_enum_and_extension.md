# 第11章 枚举与扩展 (Enum & Extension)

## 11.1 基础枚举

枚举（`enum`）用于定义一组**固定的命名常量**。它是表达"有限选项"的最佳方式——比如一周七天、订单状态、方向等。

### 声明枚举

```dart
enum Color { red, green, blue }
enum Direction { north, south, east, west }
enum OrderStatus { pending, processing, shipped, delivered, cancelled }
```

### 内置属性

每个枚举值都有两个内置属性：

- **`index`**：枚举值的索引（从 0 开始）
- **`name`**：枚举值的名称（字符串形式）

```dart
print(Color.red.index);   // 0
print(Color.green.index); // 1
print(Color.blue.name);   // 'blue'
```

### values 列表

每个枚举类型都有一个 `values` 静态属性，返回所有枚举值的列表：

```dart
for (var color in Color.values) {
  print('${color.name}: ${color.index}');
}
// red: 0
// green: 1
// blue: 2
```

### 在 switch 中使用（穷尽检查）

枚举和 `switch` 是天生一对。Dart 编译器会检查你是否覆盖了所有枚举值——如果遗漏了某个值，会发出警告：

```dart
String describeColor(Color color) {
  return switch (color) {
    Color.red => '红色：热情奔放',
    Color.green => '绿色：生机盎然',
    Color.blue => '蓝色：沉静深邃',
    // 如果去掉任何一个分支，编译器会警告
  };
}
```

这种**穷尽性检查**（exhaustiveness check）确保你不会遗漏任何情况，非常强大。

## 11.2 增强枚举 (Enhanced Enum, Dart 2.17+)

从 Dart 2.17 起，枚举可以拥有**字段、构造函数、方法和 getter**，甚至可以实现接口。这使得枚举从简单的常量列表升级为功能完备的类型。

### 带字段和构造函数的枚举

```dart
enum Planet {
  mercury(3.7, 2440),
  venus(8.87, 6052),
  earth(9.81, 6371),
  mars(3.72, 3390);

  final double gravity;    // 表面重力 (m/s²)
  final double radius;     // 半径 (km)

  const Planet(this.gravity, this.radius);
}
```

> **注意**：枚举的构造函数必须是 `const` 的。

### 添加方法和 getter

```dart
enum Planet {
  mercury(3.7, 2440),
  venus(8.87, 6052),
  earth(9.81, 6371),
  mars(3.72, 3390);

  final double gravity;
  final double radius;

  const Planet(this.gravity, this.radius);

  // 计算表面积
  double get surfaceArea => 4 * 3.14159 * radius * radius;

  // 判断是否宜居
  bool get isHabitable => this == earth;

  // 自定义方法
  String describe() =>
      '$name: 重力=${gravity}m/s², 半径=${radius}km';
}
```

### 实现接口

增强枚举可以实现接口（但不能被继承）：

```dart
enum Season implements Comparable<Season> {
  spring(1, '万物复苏'),
  summer(2, '骄阳似火'),
  autumn(3, '金风送爽'),
  winter(4, '银装素裹');

  final int order;
  final String description;

  const Season(this.order, this.description);

  @override
  int compareTo(Season other) => order.compareTo(other.order);
}
```

### 增强枚举的限制

- 构造函数必须是 `const`
- 不能被继承（extends）
- 不能手动实例化（只有预定义的枚举值）
- 不能重写 `index`、`hashCode`、`==` 操作符
- 不能声明名为 `values` 的成员

## 11.3 扩展方法 (Extension Methods)

扩展方法允许你**给已有的类型添加新的方法**，而无需修改原始类的源码。这对于给第三方库的类型或 Dart 内置类型添加功能特别有用。

### 基本语法

```dart
extension StringExtras on String {
  // 扩展方法
  bool get isEmail => contains('@') && contains('.');

  // 带参数的扩展方法
  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;

  // 扩展 getter
  String get reversed => split('').reversed.join('');

  // 获取单词列表
  List<String> get words => trim().split(RegExp(r'\s+'));
}
```

使用扩展方法就像调用类型自身的方法一样自然：

```dart
print('hello@world.com'.isEmail);        // true
print('Hello World'.truncate(5));         // Hello...
print('Dart'.reversed);                   // traD
print('hello world foo'.words);           // [hello, world, foo]
```

### 扩展运算符

扩展方法也可以添加运算符：

```dart
extension NumRange on int {
  bool operator <=(int other) => this <= other; // 内置已有

  // 生成从 this 到 end 的列表
  List<int> to(int end) =>
      [for (var i = this; i <= end; i++) i];
}
```

### 给集合类型添加扩展

```dart
extension ListExtras<T> on List<T> {
  // 按条件分组
  Map<K, List<T>> groupBy<K>(K Function(T) keyFn) {
    final map = <K, List<T>>{};
    for (var item in this) {
      (map[keyFn(item)] ??= []).add(item);
    }
    return map;
  }
}
```

### 命名扩展 vs 匿名扩展

```dart
// 命名扩展：可以被导入和显式引用
extension StringExtras on String {
  bool get isBlank => trim().isEmpty;
}

// 匿名扩展：只在当前库中可用
extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
```

### 解决冲突

当多个扩展为同一类型定义了同名方法时，需要**显式使用扩展名**来消除歧义：

```dart
extension ExtA on String {
  String get format => 'A: $this';
}

extension ExtB on String {
  String get format => 'B: $this';
}

// 使用时显式指定扩展
print(ExtA('hello').format); // A: hello
print(ExtB('hello').format); // B: hello
```

### 扩展方法的限制

- 扩展方法是**静态解析**的，基于编译时类型而非运行时类型
- 不能访问私有成员
- 不能被重写（override）
- 对 `dynamic` 类型无效

```dart
dynamic d = 'hello';
// d.isEmail; // ❌ 运行时错误！扩展方法不适用于 dynamic
```

## 11.4 扩展类型 (Extension Types, Dart 3.3+)

扩展类型是 Dart 3.3 引入的全新特性，提供**零成本的类型包装**。它在编译时提供类型安全，但在运行时没有额外的对象分配开销。

### 基本语法

```dart
extension type UserId(int id) {
  // 可以添加方法
  bool get isValid => id > 0;

  @override
  String toString() => 'UserId($id)';
}

extension type Email(String value) {
  bool get isValid => value.contains('@') && value.contains('.');
}
```

### 使用扩展类型

```dart
var userId = UserId(42);
print(userId.id);       // 42
print(userId.isValid);  // true

var email = Email('dart@google.com');
print(email.isValid);   // true

// 类型安全：不能混用
// UserId id = 42;  // ❌ 编译错误
// int n = userId;  // ❌ 编译错误（默认不透明）
```

### implements 实现透明性

通过 `implements` 可以让扩展类型"暴露"底层类型的接口：

```dart
extension type TransparentId(int id) implements int {
  bool get isValid => id > 0;
}

TransparentId tid = TransparentId(5);
int n = tid;        // ✅ 可以赋值给 int，因为 implements int
print(tid + 3);     // 8，可以使用 int 的所有方法
print(tid.isValid); // true，也能用扩展类型的方法
```

### 零成本的含义

扩展类型在**运行时完全被擦除**，不会创建包装对象：

```dart
extension type Meters(double value) {
  Meters operator +(Meters other) => Meters(value + other.value);
}

var distance = Meters(100.0);
// 运行时 distance 就是一个普通的 double，没有 Meters 对象
// 但编译时，你不能把 Meters 和普通 double 混用
```

### 对比：typedef / wrapper class / extension method / extension type

| 特性 | typedef | wrapper class | extension method | extension type |
|------|---------|--------------|-----------------|---------------|
| 类型安全 | ❌ 只是别名 | ✅ 完整类型 | ❌ 不创建新类型 | ✅ 编译时新类型 |
| 运行时开销 | 无 | 有（对象分配） | 无 | 无 |
| 自定义方法 | ❌ | ✅ | ✅ | ✅ |
| 隐藏底层 API | ❌ | ✅ | ❌ | ✅（默认） |
| 适用场景 | 简化类型签名 | 完整封装 | 添加便利方法 | 轻量级类型包装 |

**选择指南**：
- 只想给类型起别名 → `typedef`
- 想给现有类型加方法 → Extension Method
- 想要轻量级类型安全包装 → Extension Type
- 需要完整封装和运行时行为 → Wrapper Class

## 小结

本章介绍了 Dart 中三个强大的类型增强工具：

1. **增强枚举**：让枚举不再只是简单常量，可以携带数据和行为，配合 `switch` 穷尽检查写出安全的代码。
2. **扩展方法**：无需修改源码就能给任何类型添加方法，极大提升代码的表达力和可读性。
3. **扩展类型**：零成本的编译时类型包装，在不牺牲性能的前提下提升类型安全。

善用这三个工具，可以让你的 Dart 代码既类型安全又优雅简洁。在实际项目中，增强枚举常用于状态管理和配置选项，扩展方法常用于工具函数库，扩展类型常用于 ID、单位等领域概念的类型化。
