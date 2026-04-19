# 第14章：Stream 与 Isolate

## 14.1 Stream 概念

### Future vs Stream

在上一章中我们学习了 `Future`——它代表**一个**异步操作的结果。而 `Stream` 代表的是**一系列**异步值。

| 特性 | Future | Stream |
|------|--------|--------|
| 值的数量 | 单个值 | 多个值（序列） |
| 类比 | 一个快递包裹 | 一条流水线 |
| 获取方式 | `await` / `then` | `await for` / `listen` |

打个比方：
- **Future** 就像你在网上买了一件商品，等快递送到——只有**一个**包裹。
- **Stream** 就像工厂的流水线，产品**源源不断**地传出来，你在末端逐个处理。

### 典型应用场景

- **WebSocket 消息**：服务器持续推送数据
- **文件读取**：逐行或逐块读取大文件
- **传感器数据**：加速度计、GPS 持续产生读数
- **定时器**：每隔固定时间触发事件
- **用户输入**：键盘、鼠标事件流

---

## 14.2 创建 Stream

### 从已有数据创建

```dart
// 从 Iterable 创建
var s1 = Stream.fromIterable([1, 2, 3, 4, 5]);

// 从单个 Future 创建
var s2 = Stream.fromFuture(Future.value(42));

// 从多个 Future 创建
var s3 = Stream.fromFutures([
  Future.delayed(Duration(seconds: 1), () => 'A'),
  Future.delayed(Duration(seconds: 2), () => 'B'),
]);
```

### 定时 Stream

```dart
// 每秒产出一个值
var timer = Stream.periodic(
  Duration(seconds: 1),
  (count) => count, // 转换函数：接收计数器，返回值
);
```

### async* 生成器

最灵活的方式——使用 `async*` 标记的异步生成器函数：

```dart
Stream<int> countdown(int from) async* {
  for (var i = from; i >= 0; i--) {
    await Future.delayed(Duration(seconds: 1));
    yield i;  // 产出一个值
  }
}

// yield* 委托另一个 Stream
Stream<int> countdownTwice(int from) async* {
  yield* countdown(from);  // 先倒计时一轮
  yield* countdown(from);  // 再倒计时一轮
}
```

**关键区别：**
- `sync*` + `yield` → 返回 `Iterable<T>`（同步）
- `async*` + `yield` → 返回 `Stream<T>`（异步）

---

## 14.3 监听 Stream

### listen 方法

`listen` 是最基础的 Stream 监听方式：

```dart
var subscription = stream.listen(
  (data) => print('数据: $data'),      // onData
  onError: (err) => print('错误: $err'), // onError
  onDone: () => print('完成'),           // onDone
  cancelOnError: false,                  // 出错时是否取消订阅
);
```

### await for 循环

在 `async` 函数中，可以用 `await for` 优雅地消费 Stream：

```dart
Future<void> consume(Stream<int> stream) async {
  await for (var value in stream) {
    print('收到: $value');
  }
  print('Stream 结束');
}
```

**注意**：`await for` 会等到 Stream 关闭才退出循环。如果 Stream 永不结束，循环也永不退出。

### StreamSubscription 控制

`listen` 返回一个 `StreamSubscription` 对象，提供精细控制：

```dart
var sub = stream.listen((data) => print(data));

sub.pause();   // 暂停接收
sub.resume();  // 恢复接收
sub.cancel();  // 取消订阅（释放资源）
```

---

## 14.4 单订阅流 vs 广播流

### 单订阅流 (Single-subscription)

**默认**创建的 Stream 都是单订阅流——只能有**一个**监听者：

```dart
var stream = Stream.fromIterable([1, 2, 3]);
stream.listen(print);  // ✅ 第一个监听者
stream.listen(print);  // ❌ 抛出 StateError！
```

适用场景：文件读取、HTTP 响应——数据只需被消费一次。

### 广播流 (Broadcast)

广播流允许**多个**监听者同时监听：

```dart
var stream = Stream.fromIterable([1, 2, 3]).asBroadcastStream();
stream.listen((d) => print('监听者A: $d'));
stream.listen((d) => print('监听者B: $d'));
```

**注意**：广播流不会为后加入的监听者重放之前的数据。

### StreamController

`StreamController` 是创建自定义 Stream 的核心工具：

```dart
// 单订阅 controller
var controller = StreamController<int>();

// 广播 controller
var broadcastController = StreamController<int>.broadcast();

// 添加数据
controller.sink.add(1);
controller.sink.add(2);
controller.sink.addError('出错了');
controller.sink.close();  // 关闭 Stream

// 监听
controller.stream.listen(
  (data) => print(data),
  onError: (e) => print('错误: $e'),
  onDone: () => print('关闭'),
);
```

---

## 14.5 Stream 转换

Stream 提供了丰富的转换方法，类似于 Iterable 的操作，但它们是**异步**的。

### 基础转换

```dart
var numbers = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

numbers
  .where((n) => n.isEven)      // 过滤偶数
  .map((n) => n * n)            // 平方
  .take(3)                      // 只取前3个
  .listen(print);               // 4, 16, 36
```

常用转换方法：

| 方法 | 说明 | 示例 |
|------|------|------|
| `map` | 转换每个元素 | `.map((x) => x * 2)` |
| `where` | 过滤元素 | `.where((x) => x > 0)` |
| `expand` | 一对多展开 | `.expand((x) => [x, x])` |
| `take` | 取前 N 个 | `.take(5)` |
| `skip` | 跳过前 N 个 | `.skip(2)` |
| `distinct` | 去除连续重复 | `.distinct()` |
| `takeWhile` | 满足条件时持续取 | `.takeWhile((x) => x < 10)` |
| `skipWhile` | 满足条件时持续跳过 | `.skipWhile((x) => x < 5)` |

### 异步转换

```dart
// asyncMap：每个元素经过异步函数转换
stream.asyncMap((url) async {
  var response = await http.get(url);
  return response.body;
});

// asyncExpand：每个元素异步展开为新 Stream
stream.asyncExpand((userId) {
  return fetchUserOrders(userId);  // 返回 Stream<Order>
});
```

### StreamTransformer

对于复杂的转换逻辑，可以自定义 `StreamTransformer`：

```dart
var transformer = StreamTransformer<int, String>.fromHandlers(
  handleData: (data, sink) {
    if (data.isEven) {
      sink.add('偶数: $data');
    }
  },
  handleError: (error, stackTrace, sink) {
    sink.add('错误已处理');
  },
  handleDone: (sink) {
    sink.close();
  },
);

stream.transform(transformer).listen(print);
```

---

## 14.6 StreamController 深入

### 创建自定义 Stream

```dart
StreamController<String> createMessageStream() {
  late StreamController<String> controller;

  controller = StreamController<String>(
    onListen: () => print('有人开始监听了'),
    onPause: () => print('监听暂停'),
    onResume: () => print('监听恢复'),
    onCancel: () {
      print('监听取消，清理资源');
      controller.close();
    },
  );

  return controller;
}
```

### 生命周期管理

StreamController 的生命周期回调让你可以：
- **onListen**：第一个监听者加入时初始化资源
- **onCancel**：最后一个监听者离开时释放资源
- **onPause / onResume**：控制数据生产速率（背压）

### 重要提醒

**始终记得关闭 StreamController！** 未关闭的 controller 会导致内存泄漏：

```dart
// ✅ 好的做法
await controller.close();

// 或者在 onCancel 中关闭
onCancel: () => controller.close(),
```

---

## 14.7 Isolate

### 为什么需要 Isolate

Dart 是单线程的，事件循环非常适合处理 I/O 密集型任务（网络请求、文件读取）。但对于 **CPU 密集型任务**（大量计算、图像处理、JSON 解析大数据），长时间占用主线程会导致 UI 卡顿。

**Isolate** 是 Dart 的并行计算方案——每个 Isolate 都有自己独立的**内存堆**和**事件循环**。

### Isolate 的特点

| 特性 | 说明 |
|------|------|
| 独立内存 | Isolate 之间**不共享内存**，避免了锁和数据竞争 |
| 消息传递 | 通过 SendPort / ReceivePort 通信 |
| 轻量级 | 比操作系统线程更轻量 |
| 安全 | 没有共享状态，不会出现并发 bug |

### Isolate.run（Dart 2.19+）

`Isolate.run` 是最简单的使用方式——在新 Isolate 中执行一个函数并返回结果：

```dart
import 'dart:isolate';

// CPU 密集任务
int heavyComputation(int n) {
  var sum = 0;
  for (var i = 0; i < n; i++) {
    sum += i;
  }
  return sum;
}

Future<void> main() async {
  // 在新 Isolate 中执行
  var result = await Isolate.run(() => heavyComputation(1000000000));
  print('结果: $result');
}
```

### 适用场景

| 场景 | 用 Isolate？ | 说明 |
|------|-------------|------|
| 网络请求 | ❌ | I/O 操作不阻塞主线程，用 async/await |
| JSON 解析（小） | ❌ | 数据量小时开销不值得 |
| JSON 解析（大） | ✅ | 大型 JSON 解析 CPU 密集 |
| 图像处理 | ✅ | 像素计算 CPU 密集 |
| 加密/哈希 | ✅ | 计算密集型操作 |
| 数学计算 | ✅ | 大量数值运算 |

### 通信模式

对于更复杂的场景（持续通信），需要使用 SendPort 和 ReceivePort：

```dart
import 'dart:isolate';

Future<void> main() async {
  // 创建接收端口
  var receivePort = ReceivePort();

  // 启动 Isolate，传入发送端口
  await Isolate.spawn(worker, receivePort.sendPort);

  // 接收消息
  await for (var message in receivePort) {
    if (message == 'done') {
      receivePort.close();
      break;
    }
    print('主 Isolate 收到: $message');
  }
}

void worker(SendPort sendPort) {
  for (var i = 0; i < 5; i++) {
    sendPort.send('消息 $i');
  }
  sendPort.send('done');
}
```

---

## 14.8 小结

本章涵盖了 Dart 异步编程的高级主题：

| 概念 | 说明 |
|------|------|
| Stream | 异步值的序列，可以被监听和转换 |
| 单订阅 vs 广播 | 单订阅只允许一个监听者，广播允许多个 |
| StreamController | 创建和控制自定义 Stream |
| async*/yield | 异步生成器，优雅地产出 Stream |
| Stream 转换 | map/where/take 等丰富的转换操作 |
| StreamTransformer | 自定义复杂转换逻辑 |
| Isolate | 独立内存的并行计算单元 |
| Isolate.run | 简单的一次性并行计算 API |

**核心心得：**
- I/O 密集 → `async/await` + `Future/Stream`
- CPU 密集 → `Isolate`
- 单值异步 → `Future`
- 多值异步 → `Stream`

下一章我们将学习 Dart 3 的重要新特性——Records、Patterns 和 sealed class。
