# 第十章：测试

> 测试是 Riverpod 的一大优势。本章学习如何对 Provider、Notifier 进行单元测试，以及如何在 Widget 测试中 override Provider。

## 目录

1. [为什么 Riverpod 易于测试](#1-为什么-riverpod-易于测试)
2. [ProviderContainer 单元测试](#2-providercontainer-单元测试)
3. [测试 Notifier](#3-测试-notifier)
4. [使用 overrides 注入 Mock](#4-使用-overrides-注入-mock)
5. [测试异步 Provider](#5-测试异步-provider)
6. [Widget 测试](#6-widget-测试)
7. [测试最佳实践](#7-测试最佳实践)
8. [小结](#8-小结)

---

## 1. 为什么 Riverpod 易于测试

| 特性 | 说明 |
|------|------|
| 不依赖 Widget 树 | 用 ProviderContainer 直接测试 |
| 内置 override | 轻松替换依赖为 Mock |
| 编译时安全 | 不会漏掉 Provider 注册 |
| 独立实例 | 每个测试用独立 Container，互不干扰 |

---

## 2. ProviderContainer 单元测试

### 2.1 基本用法

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('counterProvider 初始值为 0', () {
    // 创建独立的容器
    final container = ProviderContainer();
    addTearDown(container.dispose);  // 测试结束后清理

    // 读取 Provider
    expect(container.read(counterProvider), 0);
  });

  test('counterProvider 可以递增', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 修改状态
    container.read(counterProvider.notifier).state++;
    expect(container.read(counterProvider), 1);

    container.read(counterProvider.notifier).state++;
    expect(container.read(counterProvider), 2);
  });
}
```

### 2.2 监听变化

```dart
test('监听 Provider 变化', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final values = <int>[];
  container.listen(counterProvider, (prev, next) {
    values.add(next);
  });

  container.read(counterProvider.notifier).state = 1;
  container.read(counterProvider.notifier).state = 2;
  container.read(counterProvider.notifier).state = 3;

  expect(values, [1, 2, 3]);
});
```

---

## 3. 测试 Notifier

```dart
test('CartNotifier 添加和删除', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(cartProvider.notifier);

  // 初始为空
  expect(container.read(cartProvider), isEmpty);

  // 添加商品
  notifier.addProduct(const Product(id: '1', name: 'Test'));
  expect(container.read(cartProvider).length, 1);

  // 再添加同一个商品，数量 +1
  notifier.addProduct(const Product(id: '1', name: 'Test'));
  expect(container.read(cartProvider).first.quantity, 2);

  // 删除
  notifier.removeProduct('1');
  expect(container.read(cartProvider), isEmpty);
});
```

---

## 4. 使用 overrides 注入 Mock

### 4.1 Override Provider

```dart
// 定义 Repository 接口
final todoRepoProvider = Provider<TodoRepository>((ref) {
  return ApiTodoRepository();
});

// 测试时 override 为 Mock
test('使用 Mock Repository', () {
  final mockRepo = MockTodoRepository();

  final container = ProviderContainer(
    overrides: [
      // ✅ 替换为 Mock
      todoRepoProvider.overrideWithValue(mockRepo),
    ],
  );
  addTearDown(container.dispose);

  // 此时读取 todoRepoProvider 返回的是 mockRepo
  expect(container.read(todoRepoProvider), mockRepo);
});
```

### 4.2 Override FutureProvider

```dart
test('override FutureProvider', () async {
  final container = ProviderContainer(
    overrides: [
      userProvider.overrideWith((ref) async {
        return const User(name: 'Test User');  // 固定返回测试数据
      }),
    ],
  );
  addTearDown(container.dispose);

  // 等待异步完成
  final user = await container.read(userProvider.future);
  expect(user.name, 'Test User');
});
```

---

## 5. 测试异步 Provider

### 5.1 FutureProvider

```dart
test('FutureProvider 测试', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // 读取 Future
  final future = container.read(myFutureProvider.future);
  final result = await future;

  expect(result, expectedValue);
});
```

### 5.2 AsyncNotifier

```dart
test('AsyncNotifier 初始加载', () async {
  final container = ProviderContainer(
    overrides: [
      todoRepoProvider.overrideWithValue(MockTodoRepository()),
    ],
  );
  addTearDown(container.dispose);

  // 等待初始加载完成
  final todos = await container.read(todoListProvider.future);
  expect(todos, isNotEmpty);
});

test('AsyncNotifier 添加操作', () async {
  final container = ProviderContainer(
    overrides: [
      todoRepoProvider.overrideWithValue(MockTodoRepository()),
    ],
  );
  addTearDown(container.dispose);

  // 等待初始化
  await container.read(todoListProvider.future);

  // 执行操作
  await container.read(todoListProvider.notifier).addTodo('New Todo');

  // 验证
  final todos = await container.read(todoListProvider.future);
  expect(todos.any((t) => t.title == 'New Todo'), isTrue);
});
```

---

## 6. Widget 测试

### 6.1 基本 Widget 测试

```dart
testWidgets('显示计数器值', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: CounterPage()),
    ),
  );

  // 验证初始值
  expect(find.text('0'), findsOneWidget);

  // 点击按钮
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // 验证更新
  expect(find.text('1'), findsOneWidget);
});
```

### 6.2 带 Override 的 Widget 测试

```dart
testWidgets('使用 Mock 数据', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepoProvider.overrideWithValue(MockTodoRepository()),
      ],
      child: const MaterialApp(home: TodoPage()),
    ),
  );

  await tester.pumpAndSettle();  // 等待异步
  expect(find.text('Mock Todo 1'), findsOneWidget);
});
```

---

## 7. 测试最佳实践

| 实践 | 说明 |
|------|------|
| 每个测试独立 Container | 避免测试间状态污染 |
| 使用 addTearDown | 确保 Container 被正确销毁 |
| Override 外部依赖 | Repository、API Client 等 |
| 测试状态变化序列 | 用 container.listen 收集变化 |
| 异步用 .future | 等待 FutureProvider/AsyncNotifier 完成 |

---

## 8. 小结

| 知识点 | 要点 |
|--------|------|
| ProviderContainer | 独立容器，不依赖 Widget 树 |
| container.read | 读取 Provider 值 |
| container.listen | 监听状态变化 |
| overrides | 替换 Provider 为 Mock |
| .future | 获取异步 Provider 的 Future |
| ProviderScope | Widget 测试中使用 |

> 📌 **下一章**将学习最佳实践与常见陷阱。
