# 第10章 异常处理 (Error Handling)

## 10.1 Exception vs Error

Dart 中的异常体系分为两大类：**Exception** 和 **Error**，它们都可以被 `throw` 抛出，但设计意图截然不同。

### Exception：可预见的异常情况

`Exception` 表示程序运行中**可以预见、应当处理**的异常状况。这类问题不是代码的 bug，而是外部环境或输入导致的：

- `FormatException`：格式错误（如解析非法 JSON）
- `IOException`：I/O 操作失败（文件不存在、网络中断）
- `TimeoutException`：操作超时
- `HttpException`：HTTP 请求失败
- `IntegerDivisionByZeroException`：整数除零

程序应当**捕获**这些异常并优雅地处理（显示错误提示、重试、使用默认值等）。

### Error：程序 bug

`Error` 表示**程序本身的逻辑错误**，通常意味着代码有 bug，不应该在正常流程中被捕获：

- `TypeError`：类型转换错误
- `RangeError`：索引越界
- `StateError`：对象状态不正确（如对空列表调用 `first`）
- `ArgumentError`：传入了非法参数
- `UnsupportedError`：调用了不支持的操作
- `StackOverflowError`：栈溢出
- `OutOfMemoryError`：内存不足
- `AssertionError`：断言失败

遇到 `Error` 时，正确的做法通常是**修复代码**，而不是 catch 住忽略它。

### 类型层次

```
Object
├── Exception（可预见、应处理）
│   ├── FormatException
│   ├── IOException
│   └── ...
└── Error（程序 bug、一般不捕获）
    ├── TypeError
    ├── RangeError
    ├── StateError
    └── ...
```

> **注意**：在 Dart 中，`throw` 可以抛出**任何对象**，不仅限于 `Exception` 和 `Error`。但强烈建议只抛出实现了 `Exception` 接口或继承了 `Error` 的对象。

## 10.2 throw 抛出异常

使用 `throw` 关键字抛出异常：

```dart
throw FormatException('无效的日期格式');
throw ArgumentError.value(age, 'age', '年龄不能为负数');
throw StateError('连接已关闭');
```

### throw 是表达式

`throw` 在 Dart 中是**表达式**（不是语句），这意味着它可以出现在任何需要表达式的地方：

```dart
// 在箭头函数中使用
String getOrThrow(String? value) =>
    value ?? (throw ArgumentError('值不能为 null'));

// 在条件表达式中使用
var result = data.isNotEmpty
    ? data.first
    : throw StateError('数据为空');
```

### 抛出自定义消息

虽然 Dart 允许抛出任何对象（包括字符串），但**不推荐**这样做：

```dart
// ❌ 不推荐：抛出字符串
throw '出错了';

// ✅ 推荐：抛出 Exception/Error 的子类
throw Exception('出错了');
throw FormatException('无效输入');
```

## 10.3 try / on / catch / finally

Dart 提供了灵活的异常捕获机制，通过 `try`、`on`、`catch` 和 `finally` 的组合来处理异常。

### 基本用法：catch 所有异常

```dart
try {
  var result = riskyOperation();
  print(result);
} catch (e) {
  print('出错了: $e');
}
```

### 按类型捕获：on

使用 `on` 可以按异常类型精确捕获：

```dart
try {
  var number = int.parse(input);
} on FormatException {
  // 只捕获 FormatException，不需要异常对象时可省略 catch
  print('输入的不是有效数字');
}
```

### 获取异常对象和堆栈：catch

`catch` 最多接受两个参数：异常对象和堆栈跟踪。

```dart
try {
  var number = int.parse('abc');
} on FormatException catch (e) {
  // e 是 FormatException 类型
  print('格式错误: $e');
} catch (e, stackTrace) {
  // 捕获所有其他异常，同时获取堆栈
  print('未知错误: $e');
  print('堆栈: $stackTrace');
}
```

### 多个 on/catch 子句

可以用多个 `on` 子句捕获不同类型的异常，按**从上到下**的顺序匹配：

```dart
try {
  await fetchData();
} on TimeoutException catch (e) {
  print('请求超时: $e');
} on HttpException catch (e) {
  print('HTTP 错误: $e');
} on FormatException catch (e) {
  print('数据格式错误: $e');
} catch (e) {
  print('其他错误: $e');
}
```

> **提示**：更具体的异常类型应放在前面，通用的 `catch` 放在最后。

### finally：无论如何都执行

`finally` 块中的代码无论是否发生异常都会执行，常用于资源清理：

```dart
var file = openFile('data.txt');
try {
  var data = file.readAll();
  processData(data);
} catch (e) {
  print('处理文件时出错: $e');
} finally {
  file.close(); // 无论成功还是失败，都关闭文件
  print('文件已关闭');
}
```

### try-finally（不 catch）

即使不捕获异常，也可以用 `finally` 确保清理代码执行：

```dart
var connection = openConnection();
try {
  connection.sendData(data);
} finally {
  connection.close(); // 异常会继续向上传播，但清理代码一定执行
}
```

## 10.4 自定义异常

对于业务逻辑中的异常情况，建议创建自定义异常类，而不是使用通用的 `Exception`。

### 实现 Exception 接口

```dart
class InsufficientBalanceException implements Exception {
  final double amount;
  final double balance;

  InsufficientBalanceException(this.amount, this.balance);

  @override
  String toString() => '余额不足: 需要 $amount 元, 当前余额 $balance 元';
}
```

### 使用自定义异常

```dart
class BankAccount {
  double _balance;

  BankAccount(this._balance);

  void withdraw(double amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', '取款金额必须为正数');
    }
    if (amount > _balance) {
      throw InsufficientBalanceException(amount, _balance);
    }
    _balance -= amount;
  }
}
```

### 异常类的设计建议

1. **实现 `Exception` 接口**：而不是继承 `Error`，因为这是可预见的业务异常。
2. **携带上下文信息**：在异常类中保存相关数据（金额、余额等），方便调用者做出决策。
3. **重写 `toString()`**：提供人类可读的错误描述。
4. **命名规范**：以 `Exception` 结尾（如 `InsufficientBalanceException`）。

## 10.5 rethrow

有时候你需要捕获异常做一些处理（如记录日志），但仍然希望异常继续向上传播。此时应使用 `rethrow`。

### rethrow vs throw e

```dart
// ✅ 推荐：rethrow 保留原始堆栈跟踪
try {
  riskyOperation();
} catch (e) {
  logError(e);
  rethrow; // 原始堆栈信息完整保留
}

// ❌ 不推荐：throw e 可能丢失原始堆栈信息
try {
  riskyOperation();
} catch (e) {
  logError(e);
  throw e; // 堆栈跟踪从这里重新开始
}
```

### 实际应用场景

```dart
Future<String> fetchUserName(int userId) async {
  try {
    var response = await httpClient.get('/users/$userId');
    return parseResponse(response);
  } on FormatException catch (e) {
    // 记录日志后重新抛出
    logger.warning('解析用户 $userId 数据失败: $e');
    rethrow;
  }
}
```

### 异常链：多层调用的异常传播

在多层函数调用中，异常会沿着调用栈向上传播，直到被某一层捕获：

```dart
void layer3() {
  throw FormatException('数据格式错误');
}

void layer2() {
  try {
    layer3();
  } catch (e) {
    print('layer2 捕获到异常，记录日志后重新抛出');
    rethrow; // 传给 layer1
  }
}

void layer1() {
  try {
    layer2();
  } catch (e) {
    print('layer1 最终处理异常: $e');
  }
}
```

## 10.6 最佳实践

### 1. 用 on 指定类型，避免 catch-all

捕获具体的异常类型，而不是用通用的 `catch (e)` 捕获一切。这样可以：
- 只处理你知道如何处理的异常
- 让未预料到的异常继续传播（暴露潜在的 bug）

```dart
// ❌ 不好：吞掉了所有异常
try {
  doSomething();
} catch (e) {
  // 可能吞掉了重要的错误
}

// ✅ 好：只捕获预期的异常
try {
  doSomething();
} on NetworkException catch (e) {
  showRetryDialog(e.message);
} on FormatException catch (e) {
  showErrorMessage('数据格式错误');
}
```

### 2. 在适当层级处理异常

不要在每个函数中都 try-catch。异常应该在**有能力处理它的层级**被捕获：

- **数据访问层**：处理 I/O 异常，转换为业务异常
- **业务逻辑层**：处理业务规则异常
- **UI 层**：向用户展示错误信息

### 3. 不要用异常控制正常流程

异常是针对**异常情况**的，不要用它来控制正常的程序流程：

```dart
// ❌ 不好：用异常控制流程
try {
  var value = map['key']!;
} catch (e) {
  value = defaultValue;
}

// ✅ 好：用条件判断
var value = map['key'] ?? defaultValue;
```

### 4. finally 不要吞掉异常

```dart
// ❌ 危险：finally 中的 return 会吞掉异常
try {
  throw Exception('重要错误');
} finally {
  return; // 异常被吞掉了！
}
```

### 5. Result 模式预告

对于频繁发生的"失败"（如数据验证），可以考虑用返回值代替异常。在后续泛型章节中，我们将用 `sealed class` 实现 `Result<T, E>` 模式——这是函数式编程中常用的错误处理方式：

```dart
// 预告：Result 模式
sealed class Result<T, E> {}
class Success<T, E> extends Result<T, E> { final T value; ... }
class Failure<T, E> extends Result<T, E> { final E error; ... }
```

## 小结

异常处理是编写健壮程序的基础。Dart 的异常体系清晰地区分了 `Exception`（可预见、应处理）和 `Error`（程序 bug、应修复），配合灵活的 `try/on/catch/finally` 语法，可以优雅地处理各种错误场景。记住核心原则：**按类型精确捕获、在适当层级处理、用 rethrow 保留堆栈、不要吞掉异常**。在实际项目中，合理的异常处理策略能显著提升程序的可靠性和可维护性。
