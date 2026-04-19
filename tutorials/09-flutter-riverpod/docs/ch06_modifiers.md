# 第六章：修饰符 — autoDispose 与 family

> 修饰符是 Riverpod 的强大特性，让你控制 Provider 的生命周期和参数化。本章深入学习 `autoDispose`、`family` 和 `keepAlive`。

## 目录

1. [autoDispose — 自动销毁](#1-autodispose--自动销毁)
2. [ref.keepAlive — 缓存控制](#2-refkeepalive--缓存控制)
3. [family — 参数化 Provider](#3-family--参数化-provider)
4. [autoDispose + family 组合](#4-autodispose--family-组合)
5. [ref.onDispose — 清理回调](#5-refondispose--清理回调)
6. [实战示例：用户详情页](#6-实战示例用户详情页)
7. [小结](#7-小结)

---

## 1. autoDispose — 自动销毁

### 1.1 问题：默认不销毁

默认情况下，Provider 一旦创建，就会**永远存在于内存中**，即使没有任何 Widget 在监听它：

```dart
// 即使离开页面，这个 Provider 的状态仍然保存在内存中
final counterProvider = StateProvider<int>((ref) => 0);
```

### 1.2 使用 autoDispose

加上 `.autoDispose` 修饰符后，当**没有任何 Widget 监听**这个 Provider 时，它会被自动销毁：

```dart
// 没有监听者时自动销毁，下次使用时重新创建
final counterProvider = StateProvider.autoDispose<int>((ref) => 0);

// 各种 Provider 类型都支持
final futureProvider = FutureProvider.autoDispose<String>((ref) async { ... });
final streamProvider = StreamProvider.autoDispose<int>((ref) { ... });
final notifierProvider = NotifierProvider.autoDispose<MyNotifier, MyState>(MyNotifier.new);
```

### 1.3 autoDispose 的行为

```
Widget A 监听 → Provider 创建（状态初始化）
Widget A 离开页面 → 没有监听者 → Provider 自动销毁（状态清除）
Widget B 重新监听 → Provider 重新创建（状态重新初始化）
```

### 1.4 什么时候用 autoDispose

| ✅ 使用 autoDispose | ❌ 不使用 |
|--------------------|----------|
| 页面级数据（离开就不需要了） | 全局状态（用户登录信息） |
| 搜索结果 | 应用配置 |
| 表单状态 | 购物车 |
| 详情页数据 | 导航状态 |

---

## 2. ref.keepAlive — 缓存控制

### 2.1 问题

autoDispose 会在无监听者时立即销毁，有时候太激进了。比如用户快速切换 Tab，我们想保留一段时间的缓存。

### 2.2 使用 keepAlive

```dart
final dataProvider = FutureProvider.autoDispose<String>((ref) async {
  // 获取 keepAlive 链接
  final link = ref.keepAlive();

  // 5 秒后如果仍然没有监听者，再销毁
  final timer = Timer(const Duration(seconds: 5), () {
    link.close(); // 关闭 keepAlive，允许销毁
  });

  // Provider 被销毁时取消定时器
  ref.onDispose(() => timer.cancel());

  return await fetchData();
});
```

### 2.3 永久保活

```dart
final importantProvider = FutureProvider.autoDispose<Data>((ref) async {
  ref.keepAlive(); // 不调用 close()，等同于不用 autoDispose
  return await fetchImportantData();
});
```

---

## 3. family — 参数化 Provider

### 3.1 问题

普通 Provider 只有一个实例。如果你需要根据不同参数创建不同实例怎么办？

```dart
// ❌ 只能获取一个用户
final userProvider = FutureProvider<User>((ref) async {
  return await fetchUser('固定ID');  // 写死了！
});
```

### 3.2 使用 family

```dart
// ✅ 根据 userId 参数获取不同用户
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await fetchUser(userId);
});

// 使用时传入参数
final user = ref.watch(userProvider('user_123'));
final anotherUser = ref.watch(userProvider('user_456'));
```

### 3.3 family 的行为

- 每个不同的参数值创建一个**独立的 Provider 实例**
- `userProvider('123')` 和 `userProvider('456')` 是**两个不同的实例**
- 相同参数返回**同一个实例**（缓存）

### 3.4 各种 Provider 类型的 family

```dart
// Provider.family
final greetingProvider = Provider.family<String, String>((ref, name) {
  return '你好，$name！';
});

// StateProvider.family
final counterProvider = StateProvider.family<int, String>((ref, pageId) => 0);

// FutureProvider.family
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await api.getUser(userId);
});

// NotifierProvider.family（需要使用 FamilyNotifier）
class UserDetailNotifier extends FamilyNotifier<User, String> {
  @override
  User build(String userId) {
    // userId 是 family 参数
    return User(id: userId, name: '加载中...');
  }
}
```

### 3.5 复杂参数

family 的参数必须能正确比较相等性。基础类型（String、int）没问题，但复杂对象需要重写 `==` 和 `hashCode`：

```dart
// 使用 Record（Dart 3）作为多参数
final searchProvider = FutureProvider.family<List<Item>, ({String query, int page})>(
  (ref, params) async {
    return await api.search(query: params.query, page: params.page);
  },
);

// 使用
final results = ref.watch(searchProvider((query: 'flutter', page: 1)));
```

---

## 4. autoDispose + family 组合

最常见的组合：每个参数化实例都能自动销毁：

```dart
// 用户详情：根据 userId 加载，离开页面时自动销毁
final userDetailProvider = FutureProvider.autoDispose.family<User, String>(
  (ref, userId) async {
    return await api.getUser(userId);
  },
);
```

---

## 5. ref.onDispose — 清理回调

当 Provider 被销毁时（autoDispose 触发、或手动 invalidate），`ref.onDispose` 中的回调会被执行：

```dart
final timerProvider = StreamProvider.autoDispose<int>((ref) {
  final controller = StreamController<int>();
  int count = 0;
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    controller.add(count++);
  });

  // ✅ 清理资源
  ref.onDispose(() {
    timer.cancel();
    controller.close();
    print('timerProvider 已销毁，资源已清理');
  });

  return controller.stream;
});
```

---

## 6. 实战示例：用户详情页

本章代码演示：
- `autoDispose`：页面级数据离开时自动清理
- `family`：根据用户 ID 加载不同用户详情
- `keepAlive` + Timer：缓存 5 秒后销毁
- `ref.onDispose`：清理日志

---

## 7. 小结

| 知识点 | 要点 |
|--------|------|
| autoDispose | 无监听者时自动销毁 Provider |
| ref.keepAlive() | 延迟销毁，实现缓存 |
| family | 参数化 Provider，不同参数不同实例 |
| autoDispose + family | 最常用的组合 |
| ref.onDispose | Provider 销毁时的清理回调 |
| Record 多参数 | 用 Dart 3 Record 作为 family 参数 |

> 📌 **下一章**将学习 Riverpod Generator 代码生成。
