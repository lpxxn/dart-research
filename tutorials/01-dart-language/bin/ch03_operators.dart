void main() {
  // ========================================
  // 3.1 算术运算符
  // ========================================
  print('===== 3.1 算术运算符 =====');
  print('2 + 3 = ${2 + 3}');
  print('5 - 2 = ${5 - 2}');
  print('3 * 4 = ${3 * 4}');
  print('7 / 2 = ${7 / 2}');       // 3.5（double）
  print('7 ~/ 2 = ${7 ~/ 2}');     // 3（int，整除）
  print('7 % 3 = ${7 % 3}');       // 1（取余）
  print('');
  print('/ 与 ~/ 的区别:');
  print('  10 / 3 = ${10 / 3}');    // 3.3333...
  print('  10 ~/ 3 = ${10 ~/ 3}'); // 3

  // ========================================
  // 3.2 自增自减
  // ========================================
  print('\n===== 3.2 自增自减 =====');
  var a = 5;
  print('初始值 a = $a');
  print('++a = ${++a}'); // 6（先加后返回）
  print('a++ = ${a++}'); // 6（先返回后加）
  print('此时 a = $a');  // 7
  print('--a = ${--a}'); // 6（先减后返回）
  print('a-- = ${a--}'); // 6（先返回后减）
  print('此时 a = $a');  // 5

  // ========================================
  // 3.3 比较运算符
  // ========================================
  print('\n===== 3.3 比较运算符 =====');
  print('3 == 3: ${3 == 3}');
  print('3 != 4: ${3 != 4}');
  print('5 > 3: ${5 > 3}');
  print('3 < 5: ${3 < 5}');
  print('5 >= 5: ${5 >= 5}');
  print('3 <= 2: ${3 <= 2}');

  // == 比较值而非引用
  var s1 = 'Hello';
  var s2 = 'Hello';
  print('字符串 == 比较值: ${s1 == s2}'); // true

  // ========================================
  // 3.4 逻辑运算符
  // ========================================
  print('\n===== 3.4 逻辑运算符 =====');
  print('true && true: ${true && true}');
  print('true && false: ${true && false}');
  print('false || true: ${false || true}');
  print('!true: ${!true}');

  // 短路求值演示
  var callCount = 0;
  bool sideEffect() {
    callCount++;
    print('  sideEffect() 被调用了 (第 $callCount 次)');
    return true;
  }

  // 使用函数返回值避免编译器常量折叠
  bool getBool(bool v) => v;

  print('短路求值 - false && sideEffect():');
  var r1 = getBool(false) && sideEffect(); // sideEffect() 不会被调用
  print('  结果: $r1, sideEffect 调用次数: $callCount');

  print('短路求值 - true || sideEffect():');
  var r2 = getBool(true) || sideEffect(); // sideEffect() 不会被调用
  print('  结果: $r2, sideEffect 调用次数: $callCount');

  print('非短路 - true && sideEffect():');
  var r3 = getBool(true) && sideEffect(); // sideEffect() 会被调用
  print('  结果: $r3, sideEffect 调用次数: $callCount');

  // ========================================
  // 3.5 位运算符
  // ========================================
  print('\n===== 3.5 位运算符 =====');
  print('0xF0 & 0x0F = 0x${(0xF0 & 0x0F).toRadixString(16).toUpperCase()}');
  print('0xF0 | 0x0F = 0x${(0xF0 | 0x0F).toRadixString(16).toUpperCase()}');
  print('0xFF ^ 0x0F = 0x${(0xFF ^ 0x0F).toRadixString(16).toUpperCase()}');
  print('1 << 3 = ${1 << 3}');  // 8
  print('8 >> 2 = ${8 >> 2}');  // 2

  // 位运算做权限标志
  print('\n--- 位运算：权限标志 ---');
  const read = 1 << 0; // 0001 = 1
  const write = 1 << 1; // 0010 = 2
  const execute = 1 << 2; // 0100 = 4

  var permission = read | write; // 0011 = 3
  print('初始权限: ${permission.toRadixString(2).padLeft(4, '0')} ($permission)');
  print('  可读: ${(permission & read) != 0}');
  print('  可写: ${(permission & write) != 0}');
  print('  可执行: ${(permission & execute) != 0}');

  // 添加执行权限
  permission |= execute;
  print('添加执行权限后: ${permission.toRadixString(2).padLeft(4, '0')} ($permission)');

  // 移除写权限
  permission &= ~write;
  print('移除写权限后: ${permission.toRadixString(2).padLeft(4, '0')} ($permission)');
  print('  可读: ${(permission & read) != 0}');
  print('  可写: ${(permission & write) != 0}');
  print('  可执行: ${(permission & execute) != 0}');

  // ========================================
  // 3.6 赋值运算符
  // ========================================
  print('\n===== 3.6 赋值运算符 =====');
  var x = 10;
  x += 5;
  print('x += 5 → $x'); // 15
  x -= 3;
  print('x -= 3 → $x'); // 12
  x *= 2;
  print('x *= 2 → $x'); // 24
  x ~/= 5;
  print('x ~/= 5 → $x'); // 4
  x %= 3;
  print('x %= 3 → $x'); // 1

  // ??= 空值赋值
  print('\n--- ??= 空值赋值 ---');
  String? nickname;
  print('nickname 初始值: $nickname');
  nickname ??= 'Dart 用户';
  print('nickname ??= "Dart 用户" → $nickname');
  // 用函数返回可空类型，展示 ??= 对已有值不生效
  String? getNickname() => nickname;
  var nickname2 = getNickname();
  nickname2 ??= 'Flutter 用户';
  print('nickname2 ??= "Flutter 用户" → $nickname2（未改变，因为已有值）');

  // ========================================
  // 3.7 条件运算符
  // ========================================
  print('\n===== 3.7 条件运算符 =====');

  // 三目运算符
  var score = 85;
  var grade = score >= 60 ? '及格' : '不及格';
  print('成绩 $score → $grade');

  // ?? 空合并运算符
  String? input;
  print('input ?? "默认值" → ${input ?? "默认值"}');
  input = '用户输入';
  // 用一个函数来保持可空类型，避免类型提升后的 lint 警告
  String? getInput() => input;
  print('input ?? "默认值" → ${getInput() ?? "默认值"}');

  // ========================================
  // 3.8 级联运算符 .. 和 ?..
  // ========================================
  print('\n===== 3.8 级联运算符 =====');

  // 使用级联构建 StringBuffer
  var sb = StringBuffer()
    ..write('Hello')
    ..write(', ')
    ..write('Dart')
    ..write('!');
  print('StringBuffer 级联结果: $sb');

  // 级联操作 List
  var list = <int>[];
  list
    ..add(1)
    ..add(2)
    ..add(3)
    ..addAll([4, 5]);
  print('List 级联结果: $list');

  // ?.. 空安全级联
  List<int>? getNullableList(bool returnNull) => returnNull ? null : [0];

  var nullableList = getNullableList(true);
  nullableList?..add(1)..add(2);
  print('null 对象的 ?.. 级联: $nullableList'); // null

  nullableList = getNullableList(false);
  nullableList?..add(1)..add(2);
  print('非 null 对象的 ?.. 级联: $nullableList'); // [0, 1, 2]

  // ========================================
  // 3.9 展开运算符 ... 和 ...?
  // ========================================
  print('\n===== 3.9 展开运算符 =====');

  var list1 = [1, 2, 3];
  var list2 = [0, ...list1, 4, 5];
  print('展开列表: $list2'); // [0, 1, 2, 3, 4, 5]

  // ...? 空安全展开
  List<int>? maybeNull;
  var result = [0, ...?maybeNull, 4];
  print('空安全展开(null): $result'); // [0, 4]

  List<int>? getNonNullList() => [1, 2, 3];
  var maybeNull2 = getNonNullList();
  result = [0, ...?maybeNull2, 4];
  print('空安全展开(非null): $result'); // [0, 1, 2, 3, 4]

  // 展开 Set
  var set1 = {1, 2, 3};
  var set2 = {0, ...set1, 4};
  print('展开 Set: $set2');

  // 展开 Map
  var map1 = {'a': 1, 'b': 2};
  var map2 = {'z': 0, ...map1};
  print('展开 Map: $map2');

  // ========================================
  // 3.10 类型测试运算符
  // ========================================
  print('\n===== 3.10 类型测试运算符 =====');
  Object value = 'Hello, Dart!';
  print('value is String: ${value is String}');
  print('value is! int: ${value is! int}');

  if (value is String) {
    print('类型提升 - 大写: ${value.toUpperCase()}');
  }

  var converted = value as String;
  print('as 转换: $converted');
}
