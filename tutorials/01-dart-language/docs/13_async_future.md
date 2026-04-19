# 第13章：异步编程 — Future 与 async/await

## 13.1 同步 vs 异步

### 同步编程

在同步编程模型中，代码逐行执行。如果某一行代码需要等待（比如网络请求、文件读取），整个程序会**阻塞**在那里，直到操作完成才继续执行下一行。

```dart
// 同步代码示例（伪代码）
var data = readFileSync('large_file.txt');  // 阻塞！等待文件读完
print(data);  // 必须等上一行完成
print('继续执行');  // 继续等待
```

这在处理耗时操作时会导致严重的性能问题——用户界面冻结、服务器无法响应新请求。

### 异步编程

异步编程允许我们提交一个耗时任务后**立即继续执行**后面的代码，当任务完成时通过回调或其他机制获取结果。

```dart
// 异步代码示例
readFileAsync('large_file.txt').then((data) {
  print(data);  // 文件读完后执行
});
print('继续执行');  // 不用等文件读完，立即执行
```

### Dart 的单线程模型

Dart 是**单线程**语言，所有代码在同一个线程（主 Isolate）上运行。但这并不意味着 Dart 无法处理异步操作——它通过**事件循环（Event Loop）**来实现异步。

事件循环的工作流程：

1. 执行 `main()` 函数中的同步代码
2. 同步代码执行完毕后，检查并处理**微任务队列（Microtask Queue）**
3. 微任务队列清空后，从**事件队列（Event Queue）**取出一个事件处理
4. 重复步骤 2-3，直到两个队列都为空

### 微任务队列 vs 事件队列

| 特性 | 微任务队列 | 事件队列 |
|------|-----------|---------|
| 优先级 | **高** | 低 |
| 用途 | 内部短操作 | I/O、定时器、UI 事件 |
| 创建方式 | `scheduleMicrotask()` / `Future.microtask()` | `Future()` / `Timer()` / I/O 回调 |
| 执行时机 | 每次事件循环迭代前**全部执行** | 每次迭代取**一个**执行 |

执行顺序永远是：**同步代码 → 微任务队列（全部） → 事件队列（一个） → 微任务队列 → 事件队列 → ...**

```dart
import 'dart:async';

void main() {
  print('1. 同步代码开始');

  Future(() => print('5. 事件队列'));

  Future.microtask(() => print('3. 微任务队列 1'));

  Future.microtask(() => print('4. 微任务队列 2'));

  print('2. 同步代码结束');
}
// 输出顺序：1 → 2 → 3 → 4 → 5
```

---

## 13.2 Future

### Future 是什么

`Future<T>` 代表一个**异步操作的最终结果**。它是一个"承诺"——承诺在未来某个时刻会给你一个 `T` 类型的值（或者一个错误）。

### Future 的三种状态

```
                    ┌─→ completed with value (成功)
uncompleted（未完成）──┤
                    └─→ completed with error (失败)
```

- **uncompleted**：异步操作尚未完成
- **completed with value**：操作成功，携带结果值
- **completed with error**：操作失败，携带错误信息

### 创建 Future

```dart
// 1. Future() — 在事件队列中异步执行
var f1 = Future(() => heavyComputation());

// 2. Future.value() — 立即完成的 Future（值在微任务中传递）
var f2 = Future.value(42);

// 3. Future.delayed() — 延迟指定时间后执行
var f3 = Future.delayed(Duration(seconds: 1), () => '延迟1秒');

// 4. Future.error() — 立即以错误完成
var f4 = Future.error('出错了');

// 5. Future.microtask() — 在微任务队列中执行
var f5 = Future.microtask(() => '微任务');
```

---

## 13.3 async / await

`async` 和 `await` 是 Dart 提供的语法糖，让异步代码看起来像同步代码一样清晰。

### 基本用法

```dart
// async 标记函数为异步函数，返回值自动包装为 Future
Future<String> fetchUserName() async {
  // await 暂停执行，等待 Future 完成，然后拿到结果值
  var response = await httpGet('/api/user');
  return response.body;
}
```

**规则：**
- `async` 函数的返回类型必须是 `Future<T>`（或 `void`）
- `await` 只能在 `async` 函数内使用
- `await` 会暂停**当前函数**的执行，但**不会阻塞**整个线程

### 异常处理

在 `async` 函数中，可以用标准的 `try/catch` 捕获异步异常：

```dart
Future<void> loadData() async {
  try {
    var data = await fetchFromServer();
    print('数据: $data');
  } catch (e) {
    print('请求失败: $e');
  } finally {
    print('清理资源');
  }
}
```

### 顺序 await vs 并行

```dart
// ❌ 顺序执行：总耗时 = t1 + t2 + t3
var a = await fetchA();  // 等待完成
var b = await fetchB();  // 再等待
var c = await fetchC();  // 再等待

// ✅ 并行执行：总耗时 = max(t1, t2, t3)
var results = await Future.wait([fetchA(), fetchB(), fetchC()]);
```

---

## 13.4 then / catchError / whenComplete

除了 `async/await`，还可以用链式调用风格处理 Future。

### then

```dart
fetchUser()
  .then((user) => fetchOrders(user.id))
  .then((orders) => print('订单数: ${orders.length}'));
```

`then` 接收一个回调，在 Future 完成时调用。如果回调返回一个新的 Future，后续的 `then` 会等待这个新 Future。

### catchError

```dart
fetchUser()
  .then((user) => fetchOrders(user.id))
  .catchError((e) => print('出错: $e'));
```

`catchError` 捕获前面链中任何位置抛出的错误。**注意**：`then` 回调中抛出的异常会传播到下一个 `catchError`。

### whenComplete

```dart
fetchUser()
  .then((user) => print('用户: $user'))
  .catchError((e) => print('错误: $e'))
  .whenComplete(() => print('无论成功失败都执行'));
```

`whenComplete` 类似于 `try/catch/finally` 中的 `finally`，无论 Future 成功还是失败都会执行。

### 对比两种风格

| async/await | then 链式 |
|-------------|----------|
| 代码更像同步，易读 | 函数式风格，适合简单转换 |
| `try/catch` 捕获异常 | `catchError` 捕获异常 |
| 适合复杂逻辑 | 适合简单的链式转换 |

---

## 13.5 Future 并发

### Future.wait

等待多个 Future **全部完成**，返回结果列表：

```dart
var results = await Future.wait([
  fetchUser(),      // Future<User>
  fetchSettings(),  // Future<Settings>
  fetchMessages(),  // Future<List<Message>>
]);
// results 是 List，按传入顺序排列
```

如果任一 Future 出错，`Future.wait` 默认也会报错。可通过 `eagerError: false` 控制行为。

### Future.any

多个 Future **竞速**，返回最先完成的结果：

```dart
var fastest = await Future.any([
  fetchFromServer1(),  // 可能要 3 秒
  fetchFromServer2(),  // 可能要 1 秒
  fetchFromServer3(),  // 可能要 2 秒
]);
// fastest = server2 的结果（最快）
```

### Future.forEach

对列表中的每个元素**顺序**执行异步操作：

```dart
await Future.forEach<String>(
  ['url1', 'url2', 'url3'],
  (url) async {
    var data = await fetch(url);
    print('已下载: $url');
  },
);
```

### Future.doWhile

异步版的 `do-while` 循环：

```dart
int retryCount = 0;
await Future.doWhile(() async {
  retryCount++;
  var success = await tryConnect();
  if (success || retryCount >= 3) return false; // 停止循环
  print('重试第 $retryCount 次...');
  return true; // 继续循环
});
```

---

## 13.6 同步生成器 sync* / yield

生成器函数可以**惰性地**生成一系列值。同步生成器使用 `sync*` 标记，返回 `Iterable<T>`。

### 基本语法

```dart
Iterable<int> range(int start, int end) sync* {
  for (var i = start; i < end; i++) {
    yield i;  // 每次调用 moveNext() 时执行到下一个 yield
  }
}

void main() {
  for (var n in range(1, 5)) {
    print(n);  // 1, 2, 3, 4
  }
}
```

### yield vs yield*

- `yield value`：产出单个值
- `yield* iterable`：将另一个 Iterable 的所有值委托产出

```dart
Iterable<int> flatten(List<List<int>> lists) sync* {
  for (var list in lists) {
    yield* list;  // 委托产出 list 中的每个元素
  }
}
```

### 惰性求值的优势

生成器是惰性的——只在需要时才计算下一个值。对于大数据集或无限序列非常有用：

```dart
Iterable<int> naturals() sync* {
  int n = 0;
  while (true) {
    yield n++;  // 无限序列，但不会无限循环
  }
}

// 只取前 10 个
naturals().take(10).forEach(print);
```

---

## 13.7 实战：模拟 API 请求

### 场景

模拟三个 API 请求，对比**串行**和**并行**的性能差异。

### 模拟函数

```dart
Future<String> fetchApi(String name, int delayMs) async {
  await Future.delayed(Duration(milliseconds: delayMs));
  return '$name 的数据';
}
```

### 串行请求

```dart
Future<void> serialFetch() async {
  var sw = Stopwatch()..start();

  var user = await fetchApi('用户', 500);
  var orders = await fetchApi('订单', 300);
  var products = await fetchApi('商品', 200);

  sw.stop();
  print('串行总耗时: ${sw.elapsedMilliseconds}ms');
  // 约 1000ms (500 + 300 + 200)
}
```

### 并行请求

```dart
Future<void> parallelFetch() async {
  var sw = Stopwatch()..start();

  var results = await Future.wait([
    fetchApi('用户', 500),
    fetchApi('订单', 300),
    fetchApi('商品', 200),
  ]);

  sw.stop();
  print('并行总耗时: ${sw.elapsedMilliseconds}ms');
  // 约 500ms (取最长的)
}
```

**结论**：当多个异步操作之间没有依赖关系时，应该使用 `Future.wait` 并行执行，可以显著减少总耗时。

---

## 小结

| 概念 | 说明 |
|------|------|
| Future | 异步操作的最终结果，有三种状态 |
| async/await | 让异步代码看起来像同步代码 |
| then/catchError | 链式调用风格处理异步 |
| Future.wait | 并行等待多个 Future |
| Future.any | 取最先完成的 Future |
| sync*/yield | 同步生成器，惰性产出值序列 |
| 事件循环 | 同步代码 → 微任务 → 事件 |

下一章我们将学习 Stream —— 异步值的**序列**，以及 Isolate 多线程编程。
