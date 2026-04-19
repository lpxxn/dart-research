void main() {
  // ========================================
  // 2.1 变量声明
  // ========================================
  print('===== 2.1 变量声明 =====');

  // --- var：类型推断 ---
  var name = 'Dart'; // 推断为 String
  var age = 10; // 推断为 int
  print('name 的类型: ${name.runtimeType}, 值: $name');
  print('age 的类型: ${age.runtimeType}, 值: $age');
  name = 'Flutter'; // 可以赋值相同类型
  print('name 重新赋值: $name');

  // --- final：运行时常量 ---
  final greeting = 'Hello, Dart!';
  final now = DateTime.now(); // 运行时确定
  print('final greeting: $greeting');
  print('final now: $now');
  // greeting = 'Hi'; // 编译错误：final 变量不能重新赋值

  // --- const：编译时常量 ---
  const pi = 3.14159;
  const area = pi * 10 * 10;
  print('const pi: $pi');
  print('const area: $area');
  // const time = DateTime.now(); // 编译错误：DateTime.now() 不是编译时常量

  // --- final vs const 的区别 ---
  const constList = [1, 2, 3]; // 编译时常量列表，不可修改
  final finalList = [1, 2, 3]; // 运行时常量引用，内容可变
  finalList.add(4);
  print('final 列表可修改内容: $finalList');
  print('const 列表不可修改内容: $constList');

  // ========================================
  // 2.2 基本类型
  // ========================================
  print('\n===== 2.2 基本类型 =====');

  // --- int ---
  int intVal = 42;
  int hexVal = 0xFF;
  print('int: $intVal, 是偶数: ${intVal.isEven}, 是奇数: ${intVal.isOdd}');
  print('十六进制 0xFF = $hexVal');
  print('42 转 double: ${intVal.toDouble()}');
  print('255 转二进制: ${hexVal.toRadixString(2)}');

  // --- double ---
  double piVal = 3.14159;
  double sciVal = 1.42e5;
  print('double: $piVal');
  print('科学计数法: $sciVal');
  print('round: ${piVal.round()}, ceil: ${piVal.ceil()}, floor: ${piVal.floor()}');
  print('保留2位小数: ${piVal.toStringAsFixed(2)}');

  // --- num ---
  num numVal = 42;
  print('num 初始值: $numVal (类型: ${numVal.runtimeType})');
  numVal = 3.14;
  print('num 赋值 double: $numVal (类型: ${numVal.runtimeType})');
  print('绝对值: ${(-5).abs()}');

  // --- String ---
  String str = 'Hello, Dart!';
  print('String: $str, 长度: ${str.length}');
  print('大写: ${str.toUpperCase()}');

  // --- bool ---
  bool isReady = true;
  bool isNotReady = !isReady;
  print('bool: isReady=$isReady, isNotReady=$isNotReady');
  // Dart 不允许 if (1) 或 if ('hello')，必须是明确的 bool

  // --- 类型字面量直接调用方法 ---
  print('\n--- 字面量调用方法 ---');
  print('42.toDouble() = ${42.toDouble()}');
  print('3.14.round() = ${3.14.round()}');
  print("'hello'.toUpperCase() = ${'hello'.toUpperCase()}");
  print('true.toString() = ${true.toString()}');

  // ========================================
  // 2.3 字符串详解
  // ========================================
  print('\n===== 2.3 字符串详解 =====');

  // --- 单引号 vs 双引号 ---
  var s1 = 'Hello';
  var s2 = "Hello";
  print('单引号 == 双引号: ${s1 == s2}');
  print("包含单引号: It's Dart");
  print('包含双引号: He said "Hello"');

  // --- 字符串插值 ---
  var lang = 'Dart';
  print('Hello, $lang!');
  print('${lang.toUpperCase()} 长度: ${lang.length}');

  // --- 多行字符串 ---
  var poem = '''
静夜思
床前明月光
疑是地上霜''';
  print('多行字符串:\n$poem');

  // --- 原始字符串 ---
  var rawStr = r'路径: C:\Users\name\n不会换行';
  print('原始字符串: $rawStr');

  // --- 相邻字面量自动拼接 ---
  var adjacent = 'Hello'
      ' '
      'World';
  print('相邻拼接: $adjacent');

  // --- 常用字符串方法 ---
  var s = '  Hello, Dart!  ';
  print('contains("Dart"): ${s.contains('Dart')}');
  print('startsWith("  H"): ${s.startsWith('  H')}');
  print('substring(2, 7): "${s.substring(2, 7)}"');
  print('split(","): ${s.split(',')}');
  print('trim(): "${s.trim()}"');
  print('replaceAll: "${s.replaceAll('Dart', 'Flutter')}"');
  print('padLeft(5, "0") on "42": ${'42'.padLeft(5, '0')}');

  // ========================================
  // 2.4 dynamic 与 Object
  // ========================================
  print('\n===== 2.4 dynamic 与 Object =====');

  // --- dynamic ---
  dynamic dynVal = 'Hello';
  print('dynamic 为 String: $dynVal, 长度: ${dynVal.length}');
  dynVal = 42;
  print('dynamic 为 int: $dynVal, 类型: ${dynVal.runtimeType}');
  // dynVal.length 会运行时报错，因为 int 没有 length

  // --- Object ---
  Object objVal = 'Hello';
  print('Object: $objVal, 类型: ${objVal.runtimeType}');
  print('Object.toString(): ${objVal.toString()}');
  // objVal.length; // 编译错误：Object 没有 length 属性

  // --- dynamic vs Object 的关键区别 ---
  print('dynamic 可以调用任何方法（编译期不检查），Object 只能调用 Object 的方法');

  // ========================================
  // 2.5 类型检查与转换
  // ========================================
  print('\n===== 2.5 类型检查与转换 =====');

  // --- is / is! ---
  Object value = 'Hello';
  print('value is String: ${value is String}');
  print('value is! int: ${value is! int}');

  // --- 类型提升 ---
  if (value is String) {
    // 此处 value 自动被提升为 String 类型
    print('类型提升后调用 toUpperCase(): ${value.toUpperCase()}');
    print('类型提升后访问 length: ${value.length}');
  }

  // --- as 强制转换 ---
  Object obj = 'Dart';
  String converted = obj as String;
  print('as 转换结果: $converted');

  // 演示多类型判断
  void printInfo(Object item) {
    if (item is String) {
      print('  String: "$item", 长度: ${item.length}');
    } else if (item is int) {
      print('  int: $item, 是偶数: ${item.isEven}');
    } else if (item is List) {
      print('  List: $item, 长度: ${item.length}');
    } else {
      print('  其他类型: $item');
    }
  }

  print('多类型判断:');
  printInfo('Hello');
  printInfo(42);
  printInfo([1, 2, 3]);
  printInfo(true);

  // ========================================
  // 2.6 late 延迟初始化
  // ========================================
  print('\n===== 2.6 late 延迟初始化 =====');

  late String description;
  // print(description); // 此时访问会抛出 LateInitializationError
  description = '这是一个延迟初始化的变量';
  print('late 变量: $description');

  // late + 延迟计算
  var computed = false;
  late int lazyResult = () {
    computed = true;
    print('  (惰性计算被执行了)');
    return 42 * 2;
  }();
  print('计算前 computed=$computed');
  print('访问 lazyResult: $lazyResult');
  print('计算后 computed=$computed');
}
