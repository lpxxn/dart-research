/// 第14章：Stream 与 Isolate 完整演示
///
/// 运行方式: dart run bin/ch14_async_stream.dart
library;

import 'dart:async';
import 'dart:isolate';

// ============================================================
// 辅助函数
// ============================================================

/// 判断是否为质数
bool _isPrime(int n) {
  if (n < 2) return false;
  if (n < 4) return true;
  if (n.isEven || n % 3 == 0) return false;
  for (var i = 5; i * i <= n; i += 6) {
    if (n % i == 0 || n % (i + 2) == 0) return false;
  }
  return true;
}

/// 质因数分解（CPU 密集任务，在 Isolate 中运行）
Map<String, dynamic> factorize(int number) {
  var n = number;
  var factors = <int, int>{};
  var d = 2;
  while (d * d <= n) {
    while (n % d == 0) {
      factors[d] = (factors[d] ?? 0) + 1;
      n ~/= d;
    }
    d++;
  }
  if (n > 1) {
    factors[n] = (factors[n] ?? 0) + 1;
  }
  // 返回 Map（Isolate 通信需要可序列化数据）
  return {
    'number': number,
    'factors': factors.entries.map((e) => '${e.key}^${e.value}').join(' × '),
  };
}

// ============================================================
// 演示函数
// ============================================================

/// 演示1：Stream.periodic 定时器
Future<void> demoStreamPeriodic() async {
  print('=== 1. Stream.periodic 定时器 ===\n');

  // 每200ms产出一个值，取前5个
  var stream = Stream.periodic(
    Duration(milliseconds: 200),
    (count) => '第 ${count + 1} 次心跳',
  ).take(5);

  await for (var value in stream) {
    print('  $value');
  }

  print('  → 定时器结束（取了5个值）\n');
}

/// 演示2：async* / yield 自定义 Stream 生成器
Future<void> demoAsyncGenerator() async {
  print('=== 2. async* / yield 自定义 Stream（倒计时）===\n');

  // 倒计时生成器
  Stream<String> countdown(int from) async* {
    for (var i = from; i >= 0; i--) {
      await Future.delayed(Duration(milliseconds: 150));
      if (i == 0) {
        yield '🚀 发射！';
      } else {
        yield '⏳ $i...';
      }
    }
  }

  // 使用 await for 消费
  await for (var msg in countdown(5)) {
    print('  $msg');
  }

  print('');
}

/// 演示3：await for 消费 Stream
Future<void> demoAwaitFor() async {
  print('=== 3. await for 消费 Stream ===\n');

  // 从 Iterable 创建 Stream
  var stream = Stream.fromIterable(['Dart', 'Flutter', 'Isolate', 'Stream', 'Future']);

  var index = 0;
  await for (var item in stream) {
    index++;
    print('  [$index] $item');
  }
  print('  → Stream 结束，共 $index 个元素\n');
}

/// 演示4：StreamController 自定义流 + 广播流多监听者
Future<void> demoStreamController() async {
  print('=== 4. StreamController + 广播流 ===\n');

  // 创建广播 StreamController
  var controller = StreamController<String>.broadcast();

  // 监听者 A
  var listenerAData = <String>[];
  var subA = controller.stream.listen((data) {
    listenerAData.add(data);
  });

  // 监听者 B：只接收包含"重要"的消息
  var listenerBData = <String>[];
  var subB = controller.stream
      .where((msg) => msg.contains('重要'))
      .listen((data) {
    listenerBData.add(data);
  });

  // 发送数据
  controller.sink.add('普通消息 1');
  controller.sink.add('[重要] 系统更新');
  controller.sink.add('普通消息 2');
  controller.sink.add('[重要] 安全警告');
  controller.sink.add('普通消息 3');

  // 关闭 controller
  await controller.close();

  // 等待所有事件处理完毕
  await subA.asFuture<void>();
  await subB.asFuture<void>();

  print('  监听者 A（全部消息）: $listenerAData');
  print('  监听者 B（仅重要消息）: $listenerBData');
  print('');
}

/// 演示5：Stream 转换链
Future<void> demoStreamTransform() async {
  print('=== 5. Stream 转换：map → where → take ===\n');

  // 产生1~20的流
  var numbers = Stream.fromIterable(List.generate(20, (i) => i + 1));

  // 转换链：过滤质数 → 平方 → 取前5个
  var results = <String>[];
  await numbers
      .where((n) => _isPrime(n)) // 过滤质数
      .map((n) => (n, n * n)) // 映射为 (原值, 平方) Record
      .take(5) // 取前5个
      .forEach((record) {
    results.add('${record.$1}² = ${record.$2}');
  });

  print('  前5个质数的平方:');
  for (var r in results) {
    print('    $r');
  }

  // 演示 distinct 去重
  var dupes = Stream.fromIterable([1, 1, 2, 2, 3, 3, 3, 4, 5, 5]);
  var unique = await dupes.distinct().toList();
  print('  \n  distinct 去重: [1,1,2,2,3,3,3,4,5,5] → $unique');

  // 演示 expand 展开
  var expanded = await Stream.fromIterable([1, 2, 3])
      .expand((n) => [n, n * 10])
      .toList();
  print('  expand 展开: [1,2,3] → $expanded');

  print('');
}

/// 演示6：StreamTransformer 自定义转换器
Future<void> demoStreamTransformer() async {
  print('=== 6. StreamTransformer 自定义转换器 ===\n');

  // 自定义转换器：给每条消息添加时间戳
  var timestampTransformer = StreamTransformer<String, String>.fromHandlers(
    handleData: (data, sink) {
      var now = DateTime.now();
      var time = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
      sink.add('[$time] $data');
    },
    handleError: (error, stackTrace, sink) {
      sink.add('[错误] $error');
    },
    handleDone: (sink) {
      sink.close();
    },
  );

  var messages = Stream.fromIterable(['用户登录', '查询数据', '操作完成']);
  var transformed = await messages.transform(timestampTransformer).toList();

  for (var msg in transformed) {
    print('  $msg');
  }
  print('');
}

/// 演示7：Isolate.run 执行 CPU 密集任务
Future<void> demoIsolate() async {
  print('=== 7. Isolate.run — CPU 密集计算 ===\n');

  // 要分解的大数列表
  var numbers = [
    123456789,
    987654321,
    1000000007, // 质数
    999999937, // 质数
    2147483646, // 2^31 - 2
  ];

  print('  质因数分解（使用 Isolate 并行计算）:\n');

  var sw = Stopwatch()..start();

  // 使用 Future.wait 并行在多个 Isolate 中计算
  var results = await Future.wait(
    numbers.map((n) => Isolate.run(() => factorize(n))),
  );

  sw.stop();

  for (var result in results) {
    var number = result['number'];
    var factors = result['factors'];
    print('  $number = $factors');
  }

  print('\n  Isolate 并行计算耗时: ${sw.elapsedMilliseconds}ms');
}

/// 演示8：StreamController 生命周期
Future<void> demoStreamLifecycle() async {
  print('\n=== 8. StreamController 生命周期 ===\n');

  var events = <String>[];

  var controller = StreamController<int>(
    onListen: () => events.add('onListen: 有监听者加入'),
    onPause: () => events.add('onPause: 监听暂停'),
    onResume: () => events.add('onResume: 监听恢复'),
    onCancel: () => events.add('onCancel: 监听取消'),
  );

  // 添加一些数据
  controller.add(1);
  controller.add(2);
  controller.add(3);

  // 开始监听
  var data = <int>[];
  var sub = controller.stream.listen((value) {
    data.add(value);
  });

  // 暂停/恢复
  sub.pause();
  controller.add(4);
  sub.resume();
  controller.add(5);

  // 关闭
  await controller.close();
  await sub.asFuture<void>();

  print('  接收到的数据: $data');
  print('  生命周期事件:');
  for (var event in events) {
    print('    $event');
  }
}

// ============================================================
// 主函数
// ============================================================

Future<void> main() async {
  print('╔══════════════════════════════════════════════╗');
  print('║  第14章：Stream 与 Isolate                   ║');
  print('╚══════════════════════════════════════════════╝\n');

  await demoStreamPeriodic();
  await demoAsyncGenerator();
  await demoAwaitFor();
  await demoStreamController();
  await demoStreamTransform();
  await demoStreamTransformer();
  await demoIsolate();
  await demoStreamLifecycle();

  print('\n✅ 第14章演示完成！');
}
