# 第八章：Provider 组合与依赖

> Riverpod 最强大的特性之一是 Provider 间的自由组合。本章学习如何通过 `ref.watch` 构建依赖链、派生状态，以及依赖注入模式。

## 目录

1. [Provider 间依赖](#1-provider-间依赖)
2. [派生状态](#2-派生状态)
3. [依赖注入模式](#3-依赖注入模式)
4. [多层依赖链](#4-多层依赖链)
5. [循环依赖问题](#5-循环依赖问题)
6. [实战示例：Todo 应用架构](#6-实战示例todo-应用架构)
7. [小结](#7-小结)

---

## 1. Provider 间依赖

在 Riverpod 中，一个 Provider 可以通过 `ref.watch` 依赖另一个 Provider：

```dart
// 基础数据
final userNameProvider = StateProvider<String>((ref) => 'Alice');
final userAgeProvider = StateProvider<int>((ref) => 25);

// 组合 Provider：依赖上面两个 Provider
final userSummaryProvider = Provider<String>((ref) {
  final name = ref.watch(userNameProvider);
  final age = ref.watch(userAgeProvider);
  return '$name, $age 岁';
});
```

### 依赖关系图

```
userNameProvider ─┐
                  ├──→ userSummaryProvider
userAgeProvider ──┘
```

当 `userNameProvider` 或 `userAgeProvider` 变化时，`userSummaryProvider` 自动重新计算。

---

## 2. 派生状态

派生状态是从一个或多个 Provider 计算出来的只读值。

### 2.1 列表过滤

```dart
final todosProvider = NotifierProvider<TodoNotifier, List<Todo>>(TodoNotifier.new);
final filterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

// 派生：过滤后的 Todo 列表
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todosProvider);
  final filter = ref.watch(filterProvider);
  
  switch (filter) {
    case TodoFilter.all: return todos;
    case TodoFilter.active: return todos.where((t) => !t.done).toList();
    case TodoFilter.completed: return todos.where((t) => t.done).toList();
  }
});
```

### 2.2 聚合计算

```dart
// 派生：未完成数量
final activeTodoCountProvider = Provider<int>((ref) {
  return ref.watch(todosProvider).where((t) => !t.done).length;
});

// 派生：完成进度
final completionProgressProvider = Provider<double>((ref) {
  final todos = ref.watch(todosProvider);
  if (todos.isEmpty) return 0;
  return todos.where((t) => t.done).length / todos.length;
});
```

---

## 3. 依赖注入模式

Riverpod 天然支持依赖注入，通过 Provider 组织依赖关系：

### 3.1 Repository 模式

```dart
// 1. 抽象层
abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<void> add(Todo todo);
  Future<void> delete(String id);
}

// 2. 实现层
class ApiTodoRepository implements TodoRepository {
  final HttpClient client;
  ApiTodoRepository(this.client);
  
  @override
  Future<List<Todo>> getAll() async { ... }
  // ...
}

// 3. Provider 注册
final httpClientProvider = Provider<HttpClient>((ref) => HttpClient());

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return ApiTodoRepository(client);
});

// 4. Notifier 中使用
class TodoNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final repo = ref.watch(todoRepositoryProvider);
    return await repo.getAll();
  }
}
```

### 3.2 依赖关系图

```
httpClientProvider
       │
       ▼
todoRepositoryProvider
       │
       ▼
todoNotifierProvider → filteredTodosProvider → UI
       │
       ▼
activeTodoCountProvider → UI
```

---

## 4. 多层依赖链

```dart
// 第一层：配置
final apiBaseUrlProvider = Provider<String>((ref) => 'https://api.example.com');

// 第二层：HTTP 客户端
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

// 第三层：Repository
final userRepoProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserRepository(client);
});

// 第四层：ViewModel (Notifier)
class UserListNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final repo = ref.watch(userRepoProvider);
    return await repo.getAll();
  }
}
```

---

## 5. 循环依赖问题

Riverpod **不允许循环依赖**：

```dart
// ❌ A 依赖 B，B 依赖 A → 运行时 StackOverflow
final aProvider = Provider<int>((ref) {
  return ref.watch(bProvider) + 1;
});
final bProvider = Provider<int>((ref) {
  return ref.watch(aProvider) + 1;
});
```

### 解决方案

1. **重新设计依赖关系**：提取共同依赖为独立 Provider
2. **使用 ref.read 替代 ref.watch**：打破响应式链（谨慎使用）

---

## 6. 实战示例：Todo 应用架构

本章代码演示完整的分层架构：

```
┌─────────┐    ┌────────────┐    ┌──────────────┐    ┌─────────┐
│   UI    │ ←─ │ 派生 Provider│ ←─ │ TodoNotifier  │ ←─ │Repository│
│ (Widget)│    │ (过滤/统计)  │    │ (状态管理)     │    │ (数据源) │
└─────────┘    └────────────┘    └──────────────┘    └─────────┘
```

---

## 7. 小结

| 知识点 | 要点 |
|--------|------|
| ref.watch 依赖 | Provider A 中 watch Provider B，B 变化时 A 自动更新 |
| 派生状态 | 用 Provider 从其他 Provider 计算只读值 |
| 依赖注入 | 通过 Provider 注册和注入 Repository/Service |
| 多层依赖链 | 配置 → 客户端 → Repository → Notifier → UI |
| 循环依赖 | 不允许，需要重构依赖关系 |

> 📌 **下一章**将学习高级模式：ProviderObserver、ProviderContainer、Scope override。
