# 第6章：集合 (Collections)

集合是编程中最常用的数据结构。Dart 提供了三种核心集合类型：List（有序列表）、Set（无序不重复集合）和 Map（键值对映射）。此外，Dart 还提供了强大的集合操作方法和独特的 collection-if/for 语法。

---

## 6.1 List

List 是 Dart 中最常用的集合类型，表示一组有序的元素。

### 创建 List

```dart
// 字面量创建（最常用）
var fruits = ['苹果', '香蕉', '橙子'];
List<int> numbers = [1, 2, 3, 4, 5];

// List.filled：创建固定长度的 List，所有元素初始化为同一个值
var zeros = List.filled(5, 0);       // [0, 0, 0, 0, 0]

// List.generate：通过生成函数创建
var squares = List.generate(5, (i) => i * i); // [0, 1, 4, 9, 16]

// List.of：从另一个可迭代对象创建（保留泛型类型）
var copy = List.of(fruits); // ['苹果', '香蕉', '橙子']

// List.from：从另一个可迭代对象创建（可以改变类型）
var fromSet = List<String>.from({'a', 'b', 'c'});
```

### 增删改查

```dart
var list = [1, 2, 3];

// 增
list.add(4);            // [1, 2, 3, 4]
list.addAll([5, 6]);    // [1, 2, 3, 4, 5, 6]
list.insert(0, 0);      // [0, 1, 2, 3, 4, 5, 6]

// 删
list.remove(0);         // [1, 2, 3, 4, 5, 6]
list.removeAt(0);       // [2, 3, 4, 5, 6]
list.removeWhere((e) => e > 4); // [2, 3, 4]

// 改
list[0] = 10;           // [10, 3, 4]

// 查
var first = list[0];    // 10
var length = list.length; // 3
```

### 排序

```dart
var numbers = [3, 1, 4, 1, 5, 9];

// 默认升序排序
numbers.sort();
print(numbers); // [1, 1, 3, 4, 5, 9]

// 自定义 Comparator：降序
numbers.sort((a, b) => b.compareTo(a));
print(numbers); // [9, 5, 4, 3, 1, 1]

// 对象排序
var users = [
  {'name': '小明', 'age': 25},
  {'name': '小红', 'age': 20},
];
users.sort((a, b) => (a['age'] as int).compareTo(b['age'] as int));
```

### 查找

```dart
var list = [1, 2, 3, 4, 5, 3];

print(list.indexOf(3));    // 2（第一次出现的位置）
print(list.contains(4));   // true

// firstWhere：找到第一个满足条件的元素
var first = list.firstWhere((e) => e > 3); // 4

// lastWhere：找到最后一个满足条件的元素
var last = list.lastWhere((e) => e < 4);   // 3

// singleWhere：找到唯一满足条件的元素（多个则抛异常）
var single = list.singleWhere((e) => e == 5); // 5
```

### 切片

```dart
var list = [0, 1, 2, 3, 4, 5];

// sublist：返回新 List
var sub = list.sublist(1, 4); // [1, 2, 3]

// getRange：返回 Iterable（惰性）
var range = list.getRange(2, 5); // (2, 3, 4)
```

### 不可变 List

```dart
// const 字面量：编译期常量
var constList = const [1, 2, 3];
// constList.add(4); // 运行时错误！

// List.unmodifiable：运行时创建不可变 List
var mutable = [1, 2, 3];
var immutable = List.unmodifiable(mutable);
// immutable.add(4); // 运行时错误！
```

---

## 6.2 Set

Set 是无序、不包含重复元素的集合。

### 创建 Set

```dart
// 字面量创建
var fruits = {'苹果', '香蕉', '橙子'};
Set<int> numbers = {1, 2, 3};

// 注意：{} 默认创建的是 Map，不是 Set
var emptySet = <String>{}; // 这是空 Set
// var emptyMap = {};        // 这是空 Map

// Set.from
var fromList = Set.from([1, 2, 2, 3, 3]); // {1, 2, 3}
```

### 增删与查询

```dart
var set = {1, 2, 3};

set.add(4);       // {1, 2, 3, 4}
set.remove(2);    // {1, 3, 4}
print(set.contains(3)); // true
print(set.length);      // 3
```

### 集合运算

Set 支持数学中的集合运算，这是 Set 最强大的特性：

```dart
var a = {1, 2, 3, 4};
var b = {3, 4, 5, 6};

// 并集
print(a.union(b));        // {1, 2, 3, 4, 5, 6}

// 交集
print(a.intersection(b)); // {3, 4}

// 差集（a 中有但 b 中没有的）
print(a.difference(b));   // {1, 2}
```

### 去重技巧

利用 Set 不包含重复元素的特性，可以快速去重：

```dart
var listWithDuplicates = [1, 2, 2, 3, 3, 3, 4];
var unique = listWithDuplicates.toSet().toList();
print(unique); // [1, 2, 3, 4]
```

---

## 6.3 Map

Map 是键值对集合，键必须唯一。

### 创建 Map

```dart
// 字面量创建
var scores = {'小明': 90, '小红': 85, '小蓝': 95};
Map<String, int> ages = {'Alice': 25, 'Bob': 30};

// Map.fromEntries
var fromEntries = Map.fromEntries([
  MapEntry('a', 1),
  MapEntry('b', 2),
]);

// Map.fromIterables
var keys = ['x', 'y', 'z'];
var values = [1, 2, 3];
var fromIterables = Map.fromIterables(keys, values);
// {x: 1, y: 2, z: 3}
```

### 操作

```dart
var map = {'name': '小明', 'age': '25'};

// 读取
print(map['name']);  // 小明

// 添加/修改
map['email'] = 'xm@example.com';
map['age'] = '26';

// putIfAbsent：不存在时才添加
map.putIfAbsent('phone', () => '13800000000');

// update：更新已有的值
map.update('age', (value) => '${int.parse(value) + 1}');

// remove
map.remove('phone');

// 检查
print(map.containsKey('name'));   // true
print(map.containsValue('小明')); // true
```

### 遍历

```dart
var scores = {'语文': 90, '数学': 95, '英语': 88};

// forEach
scores.forEach((key, value) {
  print('$key: $value 分');
});

// entries
for (var entry in scores.entries) {
  print('${entry.key}: ${entry.value}');
}

// keys 和 values
print(scores.keys);   // (语文, 数学, 英语)
print(scores.values); // (90, 95, 88)
```

### Map.map 转换

```dart
var original = {'a': 1, 'b': 2, 'c': 3};

// 将所有值翻倍
var doubled = original.map((key, value) => MapEntry(key, value * 2));
print(doubled); // {a: 2, b: 4, c: 6}

// 转换键
var upper = original.map((key, value) => MapEntry(key.toUpperCase(), value));
print(upper); // {A: 1, B: 2, C: 3}
```

---

## 6.4 Iterable 与惰性求值

### Iterable 是 List/Set 的基类

`Iterable<E>` 是 `List<E>` 和 `Set<E>` 的超类。它表示一组可以逐个遍历的元素。与 List 不同，Iterable 不支持通过索引直接访问元素。

```dart
Iterable<int> numbers = [1, 2, 3]; // List 是 Iterable
Iterable<int> digits = {1, 2, 3};  // Set 也是 Iterable
```

### 惰性求值

`map`、`where` 等方法返回的是**惰性 Iterable**——不会立即计算，而是在遍历时逐个计算。这意味着如果你只需要前几个结果，不必计算所有元素。

```dart
var numbers = [1, 2, 3, 4, 5];

// map 返回惰性 Iterable，此时还没有计算
var mapped = numbers.map((n) {
  print('正在计算 $n * 2');
  return n * 2;
});

// 只有在遍历时才会计算
print('开始遍历...');
for (var n in mapped) {
  print('得到: $n');
}
```

### toList() / toSet() 强制求值

如果需要立即计算所有结果，使用 `toList()` 或 `toSet()` 强制求值：

```dart
// 惰性：每次遍历都会重新计算
var lazy = numbers.map((n) => n * 2);

// 立即求值：结果被缓存在 List 中
var eager = numbers.map((n) => n * 2).toList();
```

---

## 6.5 集合操作符大全

Dart 的集合操作方法非常丰富，以下是全面的分类整理。

### 转换

```dart
var numbers = [1, 2, 3];

// map：一对一转换
var doubled = numbers.map((n) => n * 2); // (2, 4, 6)

// expand（相当于 flatMap）：一对多转换并展平
var expanded = numbers.expand((n) => [n, n * 10]);
// (1, 10, 2, 20, 3, 30)

// 实际应用：展平嵌套列表
var nested = [[1, 2], [3, 4], [5]];
var flat = nested.expand((list) => list).toList();
// [1, 2, 3, 4, 5]
```

### 过滤

```dart
var numbers = [1, 2, 3, 4, 5, 6, 7, 8];

// where：保留满足条件的元素
var evens = numbers.where((n) => n.isEven); // (2, 4, 6, 8)

// whereType：按类型过滤
var mixed = [1, 'hello', 2, 'world', 3];
var strings = mixed.whereType<String>(); // (hello, world)

// skip / take：跳过前 N 个 / 取前 N 个
var skipped = numbers.skip(3);  // (4, 5, 6, 7, 8)
var taken = numbers.take(3);    // (1, 2, 3)

// skipWhile / takeWhile：按条件跳过/取
var skipSmall = numbers.skipWhile((n) => n < 5); // (5, 6, 7, 8)
var takeSmall = numbers.takeWhile((n) => n < 5); // (1, 2, 3, 4)
```

### 聚合

```dart
var numbers = [1, 2, 3, 4, 5];

// reduce：从左到右聚合（要求非空列表）
var sum = numbers.reduce((a, b) => a + b); // 15

// fold：带初始值的聚合（可用于空列表）
var product = numbers.fold<int>(1, (a, b) => a * b); // 120

// any：是否有元素满足条件
print(numbers.any((n) => n > 4)); // true

// every：是否所有元素都满足条件
print(numbers.every((n) => n > 0)); // true

// join：将元素连接为字符串
print(numbers.join(', ')); // 1, 2, 3, 4, 5
```

### 查找

```dart
var numbers = [1, 2, 3, 4, 5];

print(numbers.first);  // 1
print(numbers.last);   // 5

// firstWhere：第一个满足条件的元素
var firstEven = numbers.firstWhere((n) => n.isEven); // 2

// singleWhere：唯一满足条件的元素
var onlyFive = numbers.singleWhere((n) => n == 5); // 5

// elementAt：按索引获取（Iterable 通用方法）
print(numbers.elementAt(2)); // 3
```

---

## 6.6 Collection-if 和 Collection-for

Dart 2.3 引入了 collection-if 和 collection-for 语法，让集合的构建更加声明式和优雅。

### Collection-if

在集合字面量中使用 `if` 条件决定是否包含某个元素：

```dart
var isAdmin = true;
var nav = [
  '首页',
  '产品',
  if (isAdmin) '管理后台',
  '关于',
];
print(nav); // [首页, 产品, 管理后台, 关于]
```

支持 `if-else`：

```dart
var isLoggedIn = false;
var menu = [
  '首页',
  if (isLoggedIn) '个人中心' else '登录',
];
```

### Collection-for

在集合字面量中使用 `for` 循环生成元素：

```dart
var items = [1, 2, 3];
var doubled = [
  for (var item in items) item * 2,
];
print(doubled); // [2, 4, 6]
```

### 组合使用

`if` 和 `for` 可以嵌套组合，构建复杂的集合：

```dart
var showExtra = true;
var categories = ['水果', '蔬菜'];
var items = {
  '主食',
  for (var c in categories) c,
  if (showExtra) '零食',
};
print(items); // {主食, 水果, 蔬菜, 零食}
```

在 Map 中同样适用：

```dart
var entries = [('name', '小明'), ('age', '25')];
var map = {
  for (var (k, v) in entries) k: v,
  if (true) 'active': 'yes',
};
print(map); // {name: 小明, age: 25, active: yes}
```

### 与 spread 操作符配合

```dart
var base = [1, 2, 3];
var extra = [7, 8, 9];
var combined = [
  ...base,
  4, 5, 6,
  if (extra.isNotEmpty) ...extra,
];
print(combined); // [1, 2, 3, 4, 5, 6, 7, 8, 9]
```

---

## 本章小结

| 集合类型 | 特点 | 创建语法 |
|---------|------|---------|
| List | 有序、可重复、支持索引 | `[1, 2, 3]` |
| Set | 无序、不重复 | `{1, 2, 3}` |
| Map | 键值对、键唯一 | `{'a': 1}` |

| 核心概念 | 说明 |
|---------|------|
| Iterable | List/Set 的基类，支持惰性求值 |
| 惰性求值 | map/where 返回惰性 Iterable，遍历时才计算 |
| Collection-if/for | 声明式集合构建语法 |
| 不可变集合 | `const` 或 `List.unmodifiable` |
| 集合运算 | Set 的 union/intersection/difference |

下一章我们将进入面向对象编程的世界，学习 Dart 中的类与对象。
