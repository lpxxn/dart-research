/// 第12章 泛型 (Generics) 示例
///
/// 运行方式: dart run bin/ch12_generics.dart
library;

// ============================================================
// 12.1 泛型类：Stack<T>
// ============================================================
class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);

  T pop() {
    if (_items.isEmpty) throw StateError('栈为空，无法 pop');
    return _items.removeLast();
  }

  T get peek {
    if (_items.isEmpty) throw StateError('栈为空，无法 peek');
    return _items.last;
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  @override
  String toString() => 'Stack($_items)';
}

// ============================================================
// 12.2 多类型参数：Pair<A, B>
// ============================================================
class Pair<A, B> {
  final A first;
  final B second;

  const Pair(this.first, this.second);

  /// 交换两个元素的位置
  Pair<B, A> swap() => Pair(second, first);

  /// 对 first 应用变换
  Pair<C, B> mapFirst<C>(C Function(A) transform) =>
      Pair(transform(first), second);

  /// 对 second 应用变换
  Pair<A, C> mapSecond<C>(C Function(B) transform) =>
      Pair(first, transform(second));

  @override
  String toString() => 'Pair($first, $second)';
}

// ============================================================
// 12.3 泛型约束：可比较的最大值
// ============================================================
T max<T extends Comparable<T>>(T a, T b) {
  return a.compareTo(b) >= 0 ? a : b;
}

T min<T extends Comparable<T>>(T a, T b) {
  return a.compareTo(b) <= 0 ? a : b;
}

/// 在列表中查找满足条件的第一个元素
T? firstWhere<T>(List<T> items, bool Function(T) test) {
  for (var item in items) {
    if (test(item)) return item;
  }
  return null;
}

// ============================================================
// 12.4 泛型约束：可排序的范围
// ============================================================
class Range<T extends Comparable<T>> {
  final T start;
  final T end;

  Range(this.start, this.end) {
    if (start.compareTo(end) > 0) {
      throw ArgumentError('start ($start) 不能大于 end ($end)');
    }
  }

  bool contains(T value) =>
      value.compareTo(start) >= 0 && value.compareTo(end) <= 0;

  @override
  String toString() => 'Range[$start, $end]';
}

// ============================================================
// 12.5 Result<T, E> — sealed class 实现
// ============================================================
sealed class Result<T, E> {
  const Result();

  /// 如果是 Success 返回 value，否则返回 defaultValue
  T getOrElse(T defaultValue) => switch (this) {
        Success(:final value) => value,
        Failure() => defaultValue,
      };

  /// 对成功值进行变换
  Result<U, E> map<U>(U Function(T) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failure(:final error) => Failure(error),
      };
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

// ============================================================
// 用 Result 模拟网络请求
// ============================================================
class User {
  final int id;
  final String name;
  final String email;

  const User(this.id, this.name, this.email);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

/// 模拟网络请求获取用户
Result<User, String> fetchUser(int id) {
  if (id <= 0) return Failure('无效的用户 ID: $id');
  if (id > 100) return Failure('用户不存在: id=$id');
  return Success(User(id, '用户$id', 'user$id@example.com'));
}

/// 模拟解析数字
Result<int, String> parseAge(String input) {
  var age = int.tryParse(input);
  if (age == null) return Failure('无法解析 "$input" 为数字');
  if (age < 0 || age > 150) return Failure('年龄 $age 不在合理范围内');
  return Success(age);
}

// ============================================================
// 12.6 协变示例
// ============================================================
class Animal {
  final String name;
  Animal(this.name);

  @override
  String toString() => 'Animal($name)';
}

class Dog extends Animal {
  Dog(super.name);
  void bark() => print('  $name: 汪汪！');

  @override
  String toString() => 'Dog($name)';
}

class Cat extends Animal {
  Cat(super.name);
  void meow() => print('  $name: 喵喵！');

  @override
  String toString() => 'Cat($name)';
}

/// 只读取列表中的动物名称（安全的协变使用）
void printAnimalNames(List<Animal> animals) {
  for (var animal in animals) {
    print('  - ${animal.name}');
  }
}

void main() {
  print('=' * 60);
  print('第12章 泛型 (Generics) 示例');
  print('=' * 60);

  // ----------------------------------------------------------
  // 12.1 Stack<T> 泛型类
  // ----------------------------------------------------------
  print('\n--- 12.1 Stack<T> 泛型类 ---');

  // 整数栈
  var intStack = Stack<int>();
  intStack.push(10);
  intStack.push(20);
  intStack.push(30);
  print('整数栈: $intStack');
  print('peek: ${intStack.peek}');
  print('pop: ${intStack.pop()}');
  print('pop 后: $intStack');

  // 字符串栈
  var stringStack = Stack<String>();
  stringStack.push('Hello');
  stringStack.push('World');
  stringStack.push('Dart');
  print('\n字符串栈: $stringStack');
  while (stringStack.isNotEmpty) {
    print('  弹出: ${stringStack.pop()}');
  }
  print('栈是否为空: ${stringStack.isEmpty}');

  // 空栈异常
  try {
    stringStack.pop();
  } on StateError catch (e) {
    print('空栈 pop: $e');
  }

  // ----------------------------------------------------------
  // 12.2 Pair<A, B> 多类型参数
  // ----------------------------------------------------------
  print('\n--- 12.2 Pair<A, B> 多类型参数 ---');

  var nameAge = Pair<String, int>('Alice', 30);
  print('nameAge = $nameAge');
  print('first = ${nameAge.first} (${nameAge.first.runtimeType})');
  print('second = ${nameAge.second} (${nameAge.second.runtimeType})');

  // 交换
  var swapped = nameAge.swap();
  print('swap() = $swapped');

  // 变换
  var uppered = nameAge.mapFirst((name) => name.toUpperCase());
  print('mapFirst(toUpperCase) = $uppered');

  var doubled = nameAge.mapSecond((age) => age * 2);
  print('mapSecond(*2) = $doubled');

  // 坐标对
  var point = Pair<double, double>(3.14, 2.72);
  print('\n坐标: $point');

  // ----------------------------------------------------------
  // 12.3 泛型方法
  // ----------------------------------------------------------
  print('\n--- 12.3 泛型方法 ---');

  // firstWhere 泛型方法
  var numbers = [1, 5, 12, 8, 3, 20, 7];
  var firstBig = firstWhere(numbers, (n) => n > 10);
  print('numbers = $numbers');
  print('第一个 > 10 的数: $firstBig');

  var words = ['apple', 'banana', 'cherry', 'date'];
  var longWord = firstWhere(words, (w) => w.length > 5);
  print('\nwords = $words');
  print('第一个长度 > 5 的词: $longWord');

  var notFound = firstWhere(numbers, (n) => n > 100);
  print('\n第一个 > 100 的数: $notFound (null 表示未找到)');

  // ----------------------------------------------------------
  // 12.4 泛型约束
  // ----------------------------------------------------------
  print('\n--- 12.4 泛型约束 ---');

  // max / min — 注意: int 实现的是 Comparable<num>，需要用 num 类型
  print('max<num>(3, 7) = ${max<num>(3, 7)}');
  print('max("apple", "banana") = ${max("apple", "banana")}');
  print('min<num>(3.14, 2.72) = ${min<num>(3.14, 2.72)}');

  // Range<T extends Comparable<T>> — 用 num 类型
  var ageRange = Range<num>(18, 65);
  print('\n$ageRange:');
  for (var age in [15, 18, 30, 65, 70]) {
    print('  $age 在范围内: ${ageRange.contains(age)}');
  }

  var nameRange = Range<String>('A', 'M');
  print('\n$nameRange:');
  for (var name in ['Alice', 'Bob', 'Nancy', 'Zoe']) {
    print('  "$name" 在范围内: ${nameRange.contains(name)}');
  }

  // 无效范围
  try {
    Range<num>(100, 1);
  } on ArgumentError catch (e) {
    print('\n无效范围: $e');
  }

  // ----------------------------------------------------------
  // 12.5 Result<T, E> sealed class
  // ----------------------------------------------------------
  print('\n--- 12.5 Result<T, E> sealed class ---');

  // 模拟获取用户
  print('\n用户请求:');
  for (var id in [42, -1, 200]) {
    var result = fetchUser(id);
    switch (result) {
      case Success(:final value):
        print('  ✅ id=$id → $value');
      case Failure(:final error):
        print('  ❌ id=$id → $error');
    }
  }

  // 模拟解析年龄
  print('\n年龄解析:');
  for (var input in ['25', 'abc', '-5', '200', '30']) {
    var result = parseAge(input);
    switch (result) {
      case Success(:final value):
        print('  ✅ "$input" → $value 岁');
      case Failure(:final error):
        print('  ❌ "$input" → $error');
    }
  }

  // getOrElse 方法
  print('\ngetOrElse:');
  var user1 = fetchUser(1);
  var user2 = fetchUser(-1);
  var defaultUser = User(0, '匿名用户', 'anonymous@example.com');
  print('  fetchUser(1).getOrElse = ${user1.getOrElse(defaultUser)}');
  print('  fetchUser(-1).getOrElse = ${user2.getOrElse(defaultUser)}');

  // map 变换
  print('\nmap 变换:');
  var nameResult = fetchUser(5).map((user) => user.name);
  print('  fetchUser(5).map(name) = $nameResult');
  var failResult = fetchUser(-1).map((user) => user.name);
  print('  fetchUser(-1).map(name) = $failResult');

  // Result 链式处理
  print('\n链式处理:');
  var greeting = fetchUser(10)
      .map((user) => user.name)
      .map((name) => '你好, $name!')
      .getOrElse('你好, 陌生人!');
  print('  fetchUser(10) 链式 → $greeting');

  var failGreeting = fetchUser(999)
      .map((user) => user.name)
      .map((name) => '你好, $name!')
      .getOrElse('你好, 陌生人!');
  print('  fetchUser(999) 链式 → $failGreeting');

  // ----------------------------------------------------------
  // 12.6 协变示例
  // ----------------------------------------------------------
  print('\n--- 12.6 协变示例 ---');

  var dogs = [Dog('旺财'), Dog('小白'), Dog('大黄')];
  var cats = [Cat('咪咪'), Cat('花花')];

  // 协变：List<Dog> 可以赋值给 List<Animal>
  List<Animal> animals = dogs;
  print('dogs 赋值给 List<Animal>:');
  printAnimalNames(animals);

  // 直接传 List<Dog> 给接受 List<Animal> 的函数
  print('\n传 List<Cat> 给 printAnimalNames:');
  printAnimalNames(cats);

  // 协变的安全使用：只读取
  print('\n安全的协变使用（只读取）:');
  void describeAnimals(List<Animal> list) {
    print('  共 ${list.length} 只动物:');
    for (var a in list) {
      print('    ${a.runtimeType}: ${a.name}');
    }
  }

  describeAnimals(dogs);
  describeAnimals(cats);

  // 混合列表
  print('\n混合列表:');
  List<Animal> mixed = [Dog('旺财'), Cat('咪咪'), Dog('小白'), Cat('花花')];
  for (var animal in mixed) {
    // 使用 is 检查进行类型提升
    if (animal is Dog) {
      animal.bark();
    } else if (animal is Cat) {
      animal.meow();
    }
  }

  // 协变的风险演示（注释说明）
  print('\n协变风险说明:');
  print('  List<Dog> dogs = [Dog("旺财")];');
  print('  List<Animal> animals = dogs; // 编译通过（协变）');
  print('  // animals.add(Cat("咪咪")); // 运行时会报错！');
  print('  // 因为 animals 的实际类型仍是 List<Dog>');

  // ----------------------------------------------------------
  // 12.7 泛型 vs dynamic 对比
  // ----------------------------------------------------------
  print('\n--- 12.7 泛型 vs dynamic 对比 ---');

  // 泛型：类型安全
  var typedList = <int>[1, 2, 3];
  // typedList.add('hello'); // ❌ 编译错误
  print('泛型 List<int>: $typedList (类型安全，编译期检查)');

  // dynamic：无类型检查
  var dynamicList = <dynamic>[1, 'hello', true];
  print('dynamic List: $dynamicList (无类型检查)');

  // 泛型推断
  var inferred = [1, 2, 3]; // Dart 自动推断为 List<int>
  print('类型推断: ${inferred.runtimeType}');

  print('\n${'=' * 60}');
  print('第12章示例运行完毕！');
  print('=' * 60);
}
