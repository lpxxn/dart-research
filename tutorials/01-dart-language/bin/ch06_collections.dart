// 第6章：集合 (Collections) —— 全面示例
//
// 运行方式：dart run bin/ch06_collections.dart

void main() {
  print('=== 第6章：集合 (Collections) ===\n');

  _demoList();
  _demoSet();
  _demoMap();
  _demoLazyEvaluation();
  _demoCollectionOperators();
  _demoCollectionIfFor();
  _demoImmutableCollections();
}

// ============================================================
// 6.1 List
// ============================================================
void _demoList() {
  print('--- 6.1 List ---');

  // 创建方式
  var fruits = ['苹果', '香蕉', '橙子'];
  var zeros = List.filled(5, 0);
  var squares = List.generate(5, (i) => i * i);
  var copy = List.of(fruits);
  var fromSet = List<String>.from({'a', 'b', 'c'});

  print('  字面量：$fruits');
  print('  filled：$zeros');
  print('  generate：$squares');
  print('  of：$copy');
  print('  from Set：$fromSet');

  // 增删改查
  var list = [1, 2, 3];
  list.add(4);
  print('  add(4)：$list');
  list.addAll([5, 6]);
  print('  addAll([5,6])：$list');
  list.insert(0, 0);
  print('  insert(0, 0)：$list');
  list.remove(0);
  print('  remove(0)：$list');
  list.removeAt(0);
  print('  removeAt(0)：$list');
  list.removeWhere((e) => e > 4);
  print('  removeWhere(>4)：$list');
  list[0] = 10;
  print('  [0]=10：$list');

  // 排序
  var numbers = [3, 1, 4, 1, 5, 9, 2, 6];
  numbers.sort();
  print('  升序排序：$numbers');
  numbers.sort((a, b) => b.compareTo(a));
  print('  降序排序：$numbers');

  // 查找
  var data = [1, 2, 3, 4, 5, 3];
  print('  indexOf(3)：${data.indexOf(3)}');
  print('  contains(4)：${data.contains(4)}');
  print('  firstWhere(>3)：${data.firstWhere((e) => e > 3)}');
  print('  lastWhere(<4)：${data.lastWhere((e) => e < 4)}');

  // 切片
  var items = [0, 1, 2, 3, 4, 5];
  print('  sublist(1,4)：${items.sublist(1, 4)}');
  print('  getRange(2,5)：${items.getRange(2, 5).toList()}');

  print('');
}

// ============================================================
// 6.2 Set
// ============================================================
void _demoSet() {
  print('--- 6.2 Set ---');

  // 创建
  var fruits = {'苹果', '香蕉', '橙子'};
  var fromList = <int>{};
  for (var n in [1, 2, 2, 3, 3]) {
    fromList.add(n);
  }
  print('  字面量：$fruits');
  print('  from List（去重）：$fromList');

  // 增删查
  var set = {1, 2, 3};
  set.add(4);
  print('  add(4)：$set');
  set.remove(2);
  print('  remove(2)：$set');
  print('  contains(3)：${set.contains(3)}');

  // 集合运算
  var a = {1, 2, 3, 4};
  var b = {3, 4, 5, 6};
  print('  A = $a');
  print('  B = $b');
  print('  并集 A∪B：${a.union(b)}');
  print('  交集 A∩B：${a.intersection(b)}');
  print('  差集 A-B：${a.difference(b)}');
  print('  差集 B-A：${b.difference(a)}');

  // 去重技巧
  var listWithDups = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4];
  var unique = listWithDups.toSet().toList();
  print('  去重前：$listWithDups');
  print('  去重后：$unique');

  print('');
}

// ============================================================
// 6.3 Map
// ============================================================
void _demoMap() {
  print('--- 6.3 Map ---');

  // 创建
  var scores = {'小明': 90, '小红': 85, '小蓝': 95};
  print('  字面量：$scores');

  var fromEntries = Map.fromEntries([
    MapEntry('a', 1),
    MapEntry('b', 2),
    MapEntry('c', 3),
  ]);
  print('  fromEntries：$fromEntries');

  var keys = ['x', 'y', 'z'];
  var values = [10, 20, 30];
  var fromIterables = Map.fromIterables(keys, values);
  print('  fromIterables：$fromIterables');

  // 操作
  var map = {'name': '小明', 'age': '25'};
  map['email'] = 'xm@example.com';
  print('  添加 email：$map');
  map['age'] = '26';
  print('  修改 age：$map');
  map.putIfAbsent('phone', () => '13800000000');
  print('  putIfAbsent phone：$map');
  map.update('age', (value) => '${int.parse(value) + 1}');
  print('  update age+1：$map');
  map.remove('phone');
  print('  remove phone：$map');
  print('  containsKey("name")：${map.containsKey('name')}');
  print('  containsValue("小明")：${map.containsValue('小明')}');

  // 遍历
  print('  遍历 scores：');
  scores.forEach((key, value) {
    print('    $key: $value 分');
  });

  print('  keys：${scores.keys.toList()}');
  print('  values：${scores.values.toList()}');

  // Map.map 转换
  var original = {'a': 1, 'b': 2, 'c': 3};
  var doubled = original.map((key, value) => MapEntry(key, value * 2));
  print('  map 值翻倍：$doubled');
  var upper = original.map((key, value) => MapEntry(key.toUpperCase(), value));
  print('  map 键大写：$upper');

  print('');
}

// ============================================================
// 6.4 惰性求值 vs 立即求值
// ============================================================
void _demoLazyEvaluation() {
  print('--- 6.4 惰性求值 vs 立即求值 ---');

  var numbers = [1, 2, 3, 4, 5];
  var callCount = 0;

  // 惰性：map 返回惰性 Iterable
  var lazy = numbers.map((n) {
    callCount++;
    return n * 2;
  });
  print('  创建惰性 Iterable 后，调用次数：$callCount'); // 0

  // 遍历时才计算
  print('  惰性遍历结果：${lazy.toList()}');
  print('  第一次遍历后，调用次数：$callCount'); // 5

  // 再次遍历会重新计算
  var _ = lazy.toList();
  print('  第二次遍历后，调用次数：$callCount'); // 10

  // 立即求值：toList() 缓存结果
  callCount = 0;
  var eager = numbers.map((n) {
    callCount++;
    return n * 2;
  }).toList(); // 立即计算并缓存
  print('  立即求值结果：$eager');
  print('  调用次数：$callCount'); // 5
  // 再次使用 eager 不会重新计算

  print('');
}

// ============================================================
// 6.5 集合操作符大全（链式操作）
// ============================================================
void _demoCollectionOperators() {
  print('--- 6.5 集合操作符 ---');

  var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  // 链式操作：筛选偶数 -> 翻倍 -> 转字符串
  var result = numbers
      .where((n) => n.isEven)
      .map((n) => n * 2)
      .toList();
  print('  偶数翻倍：$result');

  // expand（flatMap）
  var nested = [
    [1, 2],
    [3, 4],
    [5],
  ];
  var flat = nested.expand((list) => list).toList();
  print('  展平：$flat');

  // whereType：按类型过滤
  var mixed = [1, 'hello', 2, 'world', 3, true];
  var strings = mixed.whereType<String>().toList();
  var ints = mixed.whereType<int>().toList();
  print('  whereType<String>：$strings');
  print('  whereType<int>：$ints');

  // skip / take
  print('  skip(3)：${numbers.skip(3).toList()}');
  print('  take(3)：${numbers.take(3).toList()}');
  print('  skipWhile(<5)：${numbers.skipWhile((n) => n < 5).toList()}');
  print('  takeWhile(<5)：${numbers.takeWhile((n) => n < 5).toList()}');

  // 聚合
  var sum = numbers.reduce((a, b) => a + b);
  var product = numbers.fold<int>(1, (a, b) => a * b);
  print('  reduce 求和：$sum');
  print('  fold 求积：$product');
  print('  any(>8)：${numbers.any((n) => n > 8)}');
  print('  every(>0)：${numbers.every((n) => n > 0)}');
  print('  join：${numbers.join(', ')}');

  // first / last / firstWhere
  print('  first：${numbers.first}');
  print('  last：${numbers.last}');
  print('  firstWhere(>5)：${numbers.firstWhere((n) => n > 5)}');

  print('');
}

// ============================================================
// 6.6 Collection-if 和 Collection-for
// ============================================================
void _demoCollectionIfFor() {
  print('--- 6.6 Collection-if 和 Collection-for ---');

  // Collection-if
  var isAdmin = true;
  var nav = [
    '首页',
    '产品',
    if (isAdmin) '管理后台',
    '关于',
  ];
  print('  isAdmin=true 的导航：$nav');

  // collection-if + else（通过参数动态决定）
  List<String> buildMenu({required bool loggedIn}) {
    return [
      '首页',
      if (loggedIn) '个人中心',
      if (!loggedIn) '登录',
    ];
  }

  print('  未登录的菜单：${buildMenu(loggedIn: false)}');
  print('  已登录的菜单：${buildMenu(loggedIn: true)}');

  // Collection-for
  var items = [1, 2, 3, 4, 5];
  var doubled = [
    for (var item in items) item * 2,
  ];
  print('  collection-for 翻倍：$doubled');

  // 组合使用
  var showExtra = true;
  var categories = ['水果', '蔬菜'];
  var combined = {
    '主食',
    for (var c in categories) c,
    if (showExtra) '零食',
  };
  print('  组合 if+for：$combined');

  // 与 spread 操作符配合
  var base = [1, 2, 3];
  var extra = [7, 8, 9];
  var spread = [
    ...base,
    4, 5, 6,
    if (extra.isNotEmpty) ...extra,
  ];
  print('  spread + if：$spread');

  // 在 Map 中使用
  var pairs = [('name', '小明'), ('age', '25')];
  var map = {
    for (var (k, v) in pairs) k: v,
    'active': 'yes',
  };
  print('  Map 中的 for+if：$map');

  print('');
}

// ============================================================
// 不可变集合
// ============================================================
void _demoImmutableCollections() {
  print('--- 不可变集合 ---');

  // const 字面量
  var constList = const [1, 2, 3];
  print('  const List：$constList');
  try {
    (constList as List).add(4);
  } catch (e) {
    print('  修改 const List 报错：$e');
  }

  // List.unmodifiable
  var mutable = [1, 2, 3];
  var immutable = List.unmodifiable(mutable);
  print('  unmodifiable List：$immutable');
  try {
    immutable.add(4);
  } catch (e) {
    print('  修改 unmodifiable List 报错：$e');
  }

  // const Set
  var constSet = const {'a', 'b', 'c'};
  print('  const Set：$constSet');

  // const Map
  var constMap = const {'key': 'value'};
  print('  const Map：$constMap');

  print('');
}
