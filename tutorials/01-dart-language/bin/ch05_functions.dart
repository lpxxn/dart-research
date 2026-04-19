// 第5章：函数 (Functions) —— 全面示例
//
// 运行方式：dart run bin/ch05_functions.dart

// ============================================================
// typedef 定义回调类型
// ============================================================
typedef IntTransformer = int Function(int);
typedef StringCallback = void Function(String message);

void main() {
  print('=== 第5章：函数 (Functions) ===\n');

  _demoParameters();
  _demoArrowFunctions();
  _demoFirstClassFunctions();
  _demoClosure();
  _demoHigherOrderFunctions();
  _demoTypedef();
  _demoRecursion();
}

// ============================================================
// 5.1 & 5.2 参数类型
// ============================================================
void _demoParameters() {
  print('--- 5.2 参数类型 ---');

  // 位置参数（必须）
  print(add(3, 5));

  // 可选位置参数
  greetOptional('小明');
  greetOptional('小明', '工程师');
  greetOptional('小明', '工程师', 25);

  // 命名参数
  createUser(name: '小红', email: 'xh@example.com');
  createUser(name: '小蓝', email: 'xl@example.com', age: 30, phone: '13800000000');

  // 默认值
  connect('localhost');
  connect('example.com', port: 3306, timeout: 60);

  print('');
}

/// 位置参数（必须）
int add(int a, int b) {
  return a + b;
}

/// 可选位置参数
void greetOptional(String name, [String? title, int age = 0]) {
  var prefix = title != null ? '$title ' : '';
  print('  $prefix$name，年龄：$age');
}

/// 命名参数 + required + 默认值
void createUser({
  required String name,
  required String email,
  int age = 0,
  String? phone,
}) {
  print('  用户：$name, 邮箱：$email, 年龄：$age, 电话：${phone ?? "未填写"}');
}

/// 默认值示例
void connect(String host, {int port = 8080, int timeout = 30}) {
  print('  连接 $host:$port，超时 $timeout 秒');
}

// ============================================================
// 5.3 箭头函数
// ============================================================
void _demoArrowFunctions() {
  print('--- 5.3 箭头函数 ---');

  // 箭头函数：单表达式简写
  int multiply(int a, int b) => a * b;
  String describe(int n) => n > 0 ? '正数' : (n < 0 ? '负数' : '零');

  print('  3 * 4 = ${multiply(3, 4)}');
  print('  5 是${describe(5)}，-3 是${describe(-3)}，0 是${describe(0)}');

  // void 箭头函数
  void logMsg(String msg) => print('  [LOG] $msg');
  logMsg('箭头函数也可以用于 void 函数');

  print('');
}

// ============================================================
// 5.4 函数作为一等公民
// ============================================================
void _demoFirstClassFunctions() {
  print('--- 5.4 函数作为一等公民 ---');

  // 赋值给变量
  void say(String msg) => print('  $msg');
  say('匿名函数赋值给变量');

  // Function 类型
  int Function(int, int) operation;
  operation = (a, b) => a + b;
  print('  3 + 4 = ${operation(3, 4)}');
  operation = (a, b) => a * b;
  print('  3 * 4 = ${operation(3, 4)}');

  // 作为参数传递
  void repeat(int times, void Function(int) action) {
    for (var i = 0; i < times; i++) {
      action(i);
    }
  }

  repeat(3, (i) => print('  第 $i 次执行'));

  // 作为返回值
  Function makeGreeter(String greeting) {
    return (String name) => '$greeting，$name！';
  }

  var hello = makeGreeter('你好');
  var hi = makeGreeter('嗨');
  print('  ${hello('小明')}');
  print('  ${hi('小红')}');

  print('');
}

// ============================================================
// 5.5 闭包 (Closure)
// ============================================================
void _demoClosure() {
  print('--- 5.5 闭包 (Closure) ---');

  // 计数器工厂：闭包捕获外部变量
  int Function() makeCounter() {
    var count = 0;
    return () {
      count++;
      return count;
    };
  }

  var counter1 = makeCounter();
  var counter2 = makeCounter();

  print('  counter1: ${counter1()}, ${counter1()}, ${counter1()}');
  print('  counter2: ${counter2()}, ${counter2()}'); // 独立计数

  // 闭包捕获变量本身（不是值）
  var functions = <int Function()>[];
  for (var i = 0; i < 3; i++) {
    functions.add(() => i); // 每次循环 i 是新变量
  }
  print('  循环闭包：${functions.map((f) => f()).toList()}'); // [0, 1, 2]

  // 累加器
  int Function(int) makeAccumulator(int initial) {
    var total = initial;
    return (int value) {
      total += value;
      return total;
    };
  }

  var acc = makeAccumulator(100);
  print('  累加器：${acc(10)}, ${acc(20)}, ${acc(30)}'); // 110, 130, 160

  print('');
}

// ============================================================
// 5.6 高阶函数
// ============================================================
void _demoHigherOrderFunctions() {
  print('--- 5.6 高阶函数 ---');

  // 内置高阶函数
  var numbers = [3, 1, 4, 1, 5, 9, 2, 6];

  var sorted = List.of(numbers)..sort();
  print('  排序：$sorted');

  var doubled = numbers.map((n) => n * 2).toList();
  print('  翻倍：$doubled');

  var evens = numbers.where((n) => n.isEven).toList();
  print('  偶数：$evens');

  var sum = numbers.reduce((a, b) => a + b);
  print('  求和：$sum');

  var allPositive = numbers.every((n) => n > 0);
  print('  全为正数：$allPositive');

  // 自己实现 myMap 函数
  List<R> myMap<T, R>(List<T> items, R Function(T) transform) {
    var result = <R>[];
    for (var item in items) {
      result.add(transform(item));
    }
    return result;
  }

  var squares = myMap(numbers, (n) => n * n);
  print('  自定义 myMap 平方：$squares');

  var strings = myMap(numbers, (n) => '[$n]');
  print('  自定义 myMap 字符串：$strings');

  // 柯里化
  int Function(int) addCurried(int a) => (int b) => a + b;
  var add5 = addCurried(5);
  print('  柯里化 add5(3) = ${add5(3)}, add5(7) = ${add5(7)}');

  print('');
}

// ============================================================
// 5.7 typedef
// ============================================================
void _demoTypedef() {
  print('--- 5.7 typedef ---');

  // 使用 typedef 定义的 IntTransformer
  List<int> applyToAll(List<int> items, IntTransformer transformer) {
    return items.map(transformer).toList();
  }

  int doubleIt(int n) => n * 2;
  int square(int n) => n * n;
  int negate(int n) => -n;

  var nums = [1, 2, 3, 4, 5];
  print('  原始：$nums');
  print('  翻倍：${applyToAll(nums, doubleIt)}');
  print('  平方：${applyToAll(nums, square)}');
  print('  取反：${applyToAll(nums, negate)}');

  // 使用 typedef 定义的 StringCallback
  void execute(StringCallback callback) {
    callback('来自 execute 的消息');
  }

  execute((msg) => print('  收到回调：$msg'));

  print('');
}

// ============================================================
// 5.8 递归
// ============================================================
void _demoRecursion() {
  print('--- 5.8 递归 ---');

  // 阶乘
  print('  5! = ${factorial(5)}');
  print('  10! = ${factorial(10)}');

  // 斐波那契（递归版 + 迭代版对比）
  print('  斐波那契前10项（递归）：${List.generate(10, fibonacci)}');
  print('  斐波那契前10项（迭代）：${List.generate(10, fibIterative)}');

  // 备忘录化
  var memo = <int, int>{};
  int fibMemo(int n) {
    if (memo.containsKey(n)) return memo[n]!;
    if (n <= 1) return n;
    memo[n] = fibMemo(n - 1) + fibMemo(n - 2);
    return memo[n]!;
  }

  print('  斐波那契(30)备忘录版：${fibMemo(30)}');

  print('');
}

/// 阶乘（递归）
int factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);
}

/// 斐波那契（递归版）
int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

/// 斐波那契（迭代版）
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
