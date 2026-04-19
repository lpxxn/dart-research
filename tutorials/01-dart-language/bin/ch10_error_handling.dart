/// 第10章 异常处理 (Error Handling) 示例
///
/// 运行方式: dart run bin/ch10_error_handling.dart
library;

// ============================================================
// 自定义异常：余额不足
// ============================================================
class InsufficientBalanceException implements Exception {
  final double amount;
  final double balance;

  InsufficientBalanceException(this.amount, this.balance);

  @override
  String toString() => '余额不足: 需要 $amount 元, 当前余额 $balance 元';
}

// ============================================================
// 自定义异常：账户被冻结
// ============================================================
class AccountFrozenException implements Exception {
  final String accountId;
  final String reason;

  AccountFrozenException(this.accountId, this.reason);

  @override
  String toString() => '账户 $accountId 已被冻结: $reason';
}

// ============================================================
// 银行账户类
// ============================================================
class BankAccount {
  final String id;
  double _balance;
  final bool _isFrozen;

  BankAccount(this.id, this._balance, {bool frozen = false})
      : _isFrozen = frozen;

  double get balance => _balance;
  bool get isFrozen => _isFrozen;

  /// 取款
  void withdraw(double amount) {
    if (_isFrozen) {
      throw AccountFrozenException(id, '存在异常交易');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', '取款金额必须为正数');
    }
    if (amount > _balance) {
      throw InsufficientBalanceException(amount, _balance);
    }
    _balance -= amount;
  }

  /// 存款
  void deposit(double amount) {
    if (_isFrozen) {
      throw AccountFrozenException(id, '存在异常交易');
    }
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', '存款金额必须为正数');
    }
    _balance += amount;
  }

  /// 转账
  void transfer(BankAccount target, double amount) {
    withdraw(amount); // 可能抛出异常
    try {
      target.deposit(amount);
    } catch (e) {
      // 如果目标账户存款失败，回滚源账户
      _balance += amount;
      rethrow; // 重新抛出异常
    }
  }
}

// ============================================================
// 演示异常链：多层函数调用
// ============================================================
void layer3() {
  print('  layer3: 抛出 FormatException');
  throw FormatException('数据格式错误');
}

void layer2() {
  try {
    layer3();
  } catch (e) {
    print('  layer2: 捕获到异常，记录日志后 rethrow');
    rethrow;
  }
}

void layer1() {
  try {
    layer2();
  } catch (e) {
    print('  layer1: 最终处理异常 → $e');
  }
}

// ============================================================
// 演示 throw 是表达式
// ============================================================
String getOrThrow(String? value) =>
    value ?? (throw ArgumentError('值不能为 null'));

void main() {
  print('=' * 60);
  print('第10章 异常处理 (Error Handling) 示例');
  print('=' * 60);

  // ----------------------------------------------------------
  // 10.1 throw 抛出异常
  // ----------------------------------------------------------
  print('\n--- 10.1 throw 抛出异常 ---');

  try {
    throw FormatException('无效的日期格式: "2024-13-45"');
  } on FormatException catch (e) {
    print('捕获到 FormatException: $e');
  }

  // throw 是表达式
  try {
    var result = getOrThrow('Hello');
    print('getOrThrow("Hello") = $result');
    getOrThrow(null);
  } on ArgumentError catch (e) {
    print('getOrThrow(null) → $e');
  }

  // ----------------------------------------------------------
  // 10.2 try / on / catch 基本用法
  // ----------------------------------------------------------
  print('\n--- 10.2 try / on / catch 基本用法 ---');

  // 按类型捕获
  void parseNumber(String input) {
    try {
      var number = int.parse(input);
      print('  解析 "$input" 成功: $number');
    } on FormatException {
      print('  解析 "$input" 失败: 不是有效的整数');
    }
  }

  parseNumber('42');
  parseNumber('abc');
  parseNumber('3.14');

  // ----------------------------------------------------------
  // 10.3 catch 获取异常对象和堆栈
  // ----------------------------------------------------------
  print('\n--- 10.3 catch 获取异常和堆栈 ---');

  try {
    var list = <int>[];
    list[0]; // RangeError
  } catch (e, stackTrace) {
    print('异常类型: ${e.runtimeType}');
    print('异常信息: $e');
    // 只打印堆栈的前两行
    var lines = stackTrace.toString().split('\n');
    print('堆栈(前2行):');
    for (var i = 0; i < 2 && i < lines.length; i++) {
      print('  ${lines[i]}');
    }
  }

  // ----------------------------------------------------------
  // 10.4 多个 on/catch 子句
  // ----------------------------------------------------------
  print('\n--- 10.4 多个 on/catch 子句 ---');

  void processInput(String input) {
    try {
      if (input.isEmpty) {
        throw StateError('输入不能为空');
      }
      var number = int.parse(input);
      if (number < 0) {
        throw ArgumentError.value(number, 'input', '数字不能为负数');
      }
      print('  处理 "$input" → 结果: ${number * 2}');
    } on StateError catch (e) {
      print('  状态错误: $e');
    } on FormatException catch (e) {
      print('  格式错误: $e');
    } on ArgumentError catch (e) {
      print('  参数错误: $e');
    } catch (e) {
      print('  未知错误: $e');
    }
  }

  processInput('10');
  processInput('');
  processInput('abc');
  processInput('-5');

  // ----------------------------------------------------------
  // 10.5 finally 确保资源清理
  // ----------------------------------------------------------
  print('\n--- 10.5 finally 确保资源清理 ---');

  void simulateFileOperation(String filename, {bool fail = false}) {
    print('  打开文件: $filename');
    try {
      if (fail) {
        throw Exception('读取 $filename 时发生 I/O 错误');
      }
      print('  成功读取文件内容');
    } catch (e) {
      print('  捕获错误: $e');
    } finally {
      print('  关闭文件: $filename (finally 块始终执行)');
    }
  }

  simulateFileOperation('data.txt');
  print('');
  simulateFileOperation('corrupt.dat', fail: true);

  // ----------------------------------------------------------
  // 10.6 自定义异常 — 银行转账场景
  // ----------------------------------------------------------
  print('\n--- 10.6 自定义异常 — 银行转账场景 ---');

  var alice = BankAccount('A001', 1000);
  var bob = BankAccount('B001', 500);
  var frozen = BankAccount('F001', 2000, frozen: true);

  // 正常取款
  try {
    alice.withdraw(200);
    print('Alice 取款 200 元成功，余额: ${alice.balance}');
  } catch (e) {
    print('取款失败: $e');
  }

  // 余额不足
  try {
    alice.withdraw(5000);
  } on InsufficientBalanceException catch (e) {
    print('取款失败: $e');
  }

  // 金额非法
  try {
    alice.withdraw(-100);
  } on ArgumentError catch (e) {
    print('取款失败: $e');
  }

  // 账户被冻结
  try {
    frozen.withdraw(100);
  } on AccountFrozenException catch (e) {
    print('取款失败: $e');
  }

  // 正常转账
  print('\n  转账演示:');
  print('  转账前 — Alice: ${alice.balance}, Bob: ${bob.balance}');
  try {
    alice.transfer(bob, 300);
    print('  转账 300 元成功');
    print('  转账后 — Alice: ${alice.balance}, Bob: ${bob.balance}');
  } catch (e) {
    print('  转账失败: $e');
  }

  // 转账到冻结账户（演示 rethrow 和事务回滚）
  print('\n  转账到冻结账户:');
  var aliceBefore = alice.balance;
  try {
    alice.transfer(frozen, 100);
  } on AccountFrozenException catch (e) {
    print('  转账失败: $e');
    print('  Alice 余额已回滚: $aliceBefore → ${alice.balance}');
  }

  // ----------------------------------------------------------
  // 10.7 rethrow 保留原始堆栈
  // ----------------------------------------------------------
  print('\n--- 10.7 rethrow — 异常链传播 ---');
  layer1();

  // ----------------------------------------------------------
  // 10.8 Exception vs Error 对比演示
  // ----------------------------------------------------------
  print('\n--- 10.8 Exception vs Error 对比 ---');

  // Exception：可预见的，应当处理
  try {
    int.parse('not_a_number');
  } on FormatException catch (e) {
    print('Exception (可预见): $e');
  }

  // Error：程序 bug，应当修复
  try {
    var list = [1, 2, 3];
    list[10]; // RangeError
  } on RangeError catch (e) {
    print('Error (程序bug): $e');
  }

  // StateError 示例
  try {
    <int>[].first; // StateError: No element
  } on StateError catch (e) {
    print('StateError: $e');
  }

  // ----------------------------------------------------------
  // 10.9 综合示例：数据处理管道
  // ----------------------------------------------------------
  print('\n--- 10.9 综合示例：数据处理管道 ---');

  List<String> rawData = ['42', 'hello', '17', '', '-3', '99'];

  int successCount = 0;
  int errorCount = 0;

  for (var item in rawData) {
    try {
      if (item.isEmpty) {
        throw StateError('空数据');
      }
      var number = int.parse(item);
      if (number < 0) {
        throw ArgumentError('负数不允许: $number');
      }
      print('  ✅ "$item" → $number');
      successCount++;
    } on StateError catch (e) {
      print('  ❌ "$item" → 状态错误: $e');
      errorCount++;
    } on FormatException {
      print('  ❌ "$item" → 格式错误: 不是整数');
      errorCount++;
    } on ArgumentError catch (e) {
      print('  ❌ "$item" → 参数错误: $e');
      errorCount++;
    }
  }

  print('  处理完成: 成功 $successCount 条, 失败 $errorCount 条');

  print('\n${'=' * 60}');
  print('第10章示例运行完毕！');
  print('=' * 60);
}
