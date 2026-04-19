/// 第13章：异步编程 — Future 与 async/await 完整演示
///
/// 运行方式: dart run bin/ch13_async_future.dart
library;

import 'dart:async';

// ============================================================
// 辅助函数
// ============================================================

/// 模拟 API 请求，延迟 [delayMs] 毫秒后返回结果
Future<String> fetchApi(String name, int delayMs) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return '$name 的数据 (耗时 ${delayMs}ms)';
}

/// 模拟可能失败的请求
Future<String> unreliableFetch(String name, {bool shouldFail = false}) async {
  await Future.delayed(Duration(milliseconds: 100));
  if (shouldFail) {
    throw Exception('$name 请求失败！');
  }
  return '$name 成功';
}

// ============================================================
// 演示函数
// ============================================================

/// 演示1：Future 创建与基本用法
Future<void> demoFutureBasics() async {
  print('=== 1. Future 创建与基本用法 ===\n');

  // Future.value — 立即以值完成
  var f1 = Future.value(42);
  print('Future.value 结果: ${await f1}');

  // Future.delayed — 延迟执行
  var f2 = Future.delayed(Duration(milliseconds: 100), () => '延迟100ms的结果');
  print('Future.delayed 结果: ${await f2}');

  // Future() — 在事件队列中执行
  var f3 = Future(() => 100 + 200);
  print('Future() 计算结果: ${await f3}');

  // Future.microtask — 在微任务队列中执行
  var f4 = Future.microtask(() => '来自微任务');
  print('Future.microtask 结果: ${await f4}');

  print('');
}

/// 演示2：async/await 语法
Future<void> demoAsyncAwait() async {
  print('=== 2. async/await 语法 ===\n');

  // 基本 async/await
  Future<int> computeSum(int n) async {
    var sum = 0;
    for (var i = 1; i <= n; i++) {
      sum += i;
    }
    return sum;
  }

  var result = await computeSum(100);
  print('1 到 100 的和: $result');

  // 链式 await
  Future<String> greet(String name) async {
    var upper = await Future.value(name.toUpperCase());
    return '你好, $upper!';
  }

  print(await greet('Dart'));
  print('');
}

/// 演示3：事件循环顺序
Future<void> demoEventLoopOrder() async {
  print('=== 3. 事件循环顺序演示 ===\n');
  print('（同步代码 → 微任务 → 事件队列）\n');

  // 使用 Completer 来等待所有异步任务完成
  var completer = Completer<void>();
  var output = <String>[];

  output.add('1. 同步代码 - 开始');

  // 事件队列
  Future(() {
    output.add('5. 事件队列 - Future()');
  });

  // 另一个事件队列任务
  Future(() {
    output.add('6. 事件队列 - 第二个 Future()');
    // 所有任务完成，通知 completer
    completer.complete();
  });

  // 微任务队列
  Future.microtask(() {
    output.add('3. 微任务队列 - Future.microtask() 第一个');
  });

  // 另一个微任务
  scheduleMicrotask(() {
    output.add('4. 微任务队列 - scheduleMicrotask()');
  });

  output.add('2. 同步代码 - 结束');

  // 等待所有事件处理完成
  await completer.future;

  for (var line in output) {
    print('  $line');
  }

  print('\n  → 执行顺序: 同步(1,2) → 微任务(3,4) → 事件(5,6)\n');
}

/// 演示4：try/catch 捕获异步异常
Future<void> demoAsyncException() async {
  print('=== 4. try/catch 捕获异步异常 ===\n');

  // async/await 风格
  try {
    var result = await unreliableFetch('服务器A', shouldFail: true);
    print('结果: $result');
  } catch (e) {
    print('  捕获到异常 (async/await): $e');
  }

  // then/catchError 风格
  await unreliableFetch('服务器B', shouldFail: true)
      .then((result) => print('结果: $result'))
      .catchError((e) => print('  捕获到异常 (catchError): $e'));

  // whenComplete（类似 finally）
  await unreliableFetch('服务器C', shouldFail: true)
      .then((result) => print('结果: $result'))
      .catchError((e) => print('  捕获到异常: $e'))
      .whenComplete(() => print('  whenComplete: 无论成功失败都执行'));

  print('');
}

/// 演示5：Future.wait 并行多个请求
Future<void> demoFutureWait() async {
  print('=== 5. Future.wait 并行请求 ===\n');

  var sw = Stopwatch()..start();

  var results = await Future.wait([
    fetchApi('用户', 300),
    fetchApi('订单', 200),
    fetchApi('商品', 100),
  ]);

  sw.stop();
  for (var r in results) {
    print('  $r');
  }
  print('  并行总耗时: ${sw.elapsedMilliseconds}ms（约等于最长的 300ms）\n');
}

/// 演示6：Future.any 竞速
Future<void> demoFutureAny() async {
  print('=== 6. Future.any 竞速 ===\n');

  var sw = Stopwatch()..start();

  var fastest = await Future.any([
    fetchApi('慢速服务器', 500),
    fetchApi('中速服务器', 200),
    fetchApi('快速服务器', 100),
  ]);

  sw.stop();
  print('  最先返回: $fastest');
  print('  竞速耗时: ${sw.elapsedMilliseconds}ms（约等于最快的 100ms）\n');
}

/// 演示7：sync* / yield 生成器
void demoSyncGenerator() {
  print('=== 7. sync* / yield 同步生成器 ===\n');

  // 基础生成器：范围
  Iterable<int> range(int start, int end) sync* {
    for (var i = start; i < end; i++) {
      yield i;
    }
  }

  print('  range(1, 6): ${range(1, 6).toList()}');

  // 斐波那契数列生成器
  Iterable<int> fibonacci() sync* {
    var a = 0, b = 1;
    while (true) {
      yield a;
      (a, b) = (b, a + b); // Records 交换
    }
  }

  print('  前10个斐波那契数: ${fibonacci().take(10).toList()}');

  // yield* 委托
  Iterable<String> greetings() sync* {
    yield* ['你好', '世界'];
    yield* ['Hello', 'World'];
  }

  print('  yield* 委托: ${greetings().toList()}');
  print('');
}

/// 演示8：实战 — 串行 vs 并行 API 请求
Future<void> demoSerialVsParallel() async {
  print('=== 8. 实战：串行 vs 并行 API 请求 ===\n');

  // 串行请求
  var sw1 = Stopwatch()..start();
  var r1 = await fetchApi('用户信息', 300);
  var r2 = await fetchApi('订单列表', 200);
  var r3 = await fetchApi('商品详情', 150);
  sw1.stop();

  print('  串行结果:');
  print('    $r1');
  print('    $r2');
  print('    $r3');
  print('  串行总耗时: ${sw1.elapsedMilliseconds}ms (≈ 300+200+150 = 650ms)\n');

  // 并行请求
  var sw2 = Stopwatch()..start();
  var results = await Future.wait([
    fetchApi('用户信息', 300),
    fetchApi('订单列表', 200),
    fetchApi('商品详情', 150),
  ]);
  sw2.stop();

  print('  并行结果:');
  for (var r in results) {
    print('    $r');
  }
  print('  并行总耗时: ${sw2.elapsedMilliseconds}ms (≈ max(300,200,150) = 300ms)\n');

  print('  → 并行比串行快约 ${sw1.elapsedMilliseconds - sw2.elapsedMilliseconds}ms');
}

// ============================================================
// 主函数
// ============================================================

Future<void> main() async {
  print('╔══════════════════════════════════════════════╗');
  print('║  第13章：异步编程 — Future 与 async/await    ║');
  print('╚══════════════════════════════════════════════╝\n');

  await demoFutureBasics();
  await demoAsyncAwait();
  await demoEventLoopOrder();
  await demoAsyncException();
  await demoFutureWait();
  await demoFutureAny();
  demoSyncGenerator();
  await demoSerialVsParallel();

  print('\n✅ 第13章演示完成！');
}
