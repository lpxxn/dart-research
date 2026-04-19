# 第二章：Provider 基础类型

> 本章深入学习 Riverpod 中最基础的两种 Provider 类型：`Provider`（只读）和 `StateProvider`（可变），理解它们的使用场景和区别。

## 目录

1. [Provider：只读 Provider](#1-provider只读-provider)
2. [StateProvider：简单可变状态](#2-stateprovider简单可变状态)
3. [Provider vs StateProvider 对比](#3-provider-vs-stateprovider-对比)
4. [实战示例：主题切换与筛选](#4-实战示例主题切换与筛选)
5. [小结](#5-小结)

---

## 1. Provider：只读 Provider

`Provider` 是最基础的 Provider 类型，它提供一个**只读**的值。这个值只在创建时计算一次，或者当它依赖的其他 Provider 变化时重新计算。

### 1.1 基本用法

```dart
// 提供一个常量配置
final appNameProvider = Provider<String>((ref) => 'My Riverpod App');

// 提供一个工具类实例
final dateFormatterProvider = Provider<DateFormat>((ref) {
  return DateFormat('yyyy-MM-dd HH:mm');
});

// 提供一个 Repository 实例（依赖注入）
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient);
});
```

### 1.2 使用场景

| 场景 | 示例 |
|------|------|
| 常量/配置 | API base URL、App 名称 |
| 工具类实例 | DateFormat、NumberFormat |
| Repository/Service | UserRepository、AuthService |
| 计算派生值 | 从其他 Provider 派生的只读数据 |

### 1.3 派生值：Provider 依赖其他 Provider

`Provider` 最强大的特性之一是可以依赖其他 Provider：

```dart
// 原始数据
final todosProvider = StateProvider<List<String>>((ref) => ['买菜', '写代码', '跑步']);

// 过滤条件
final searchProvider = StateProvider<String>((ref) => '');

// ✅ 派生 Provider：根据搜索条件过滤 todo
final filteredTodosProvider = Provider<List<String>>((ref) {
  final todos = ref.watch(todosProvider);      // 监听 todos
  final search = ref.watch(searchProvider);    // 监听搜索词
  
  if (search.isEmpty) return todos;
  return todos.where((t) => t.contains(search)).toList();
});
```

当 `todosProvider` 或 `searchProvider` 的值变化时，`filteredTodosProvider` 会自动重新计算。

---

## 2. StateProvider：简单可变状态

`StateProvider` 用于管理**简单的可变状态**。它暴露一个 `.notifier` 来读写 `.state`。

### 2.1 基本用法

```dart
// 管理一个 int
final counterProvider = StateProvider<int>((ref) => 0);

// 管理一个 bool
final isDarkProvider = StateProvider<bool>((ref) => false);

// 管理一个枚举
enum SortType { name, date, price }
final sortTypeProvider = StateProvider<SortType>((ref) => SortType.name);

// 管理一个可空值
final selectedIdProvider = StateProvider<String?>((ref) => null);
```

### 2.2 修改状态

```dart
// 方式一：直接赋值
ref.read(counterProvider.notifier).state = 10;

// 方式二：基于当前值修改
ref.read(counterProvider.notifier).update((current) => current + 1);
```

### 2.3 适用场景

StateProvider 适合管理以下类型的简单状态：

| 类型 | 示例 |
|------|------|
| 数字 | 计数器、页码、数量 |
| 布尔值 | 开关、暗黑模式、是否展开 |
| 字符串 | 搜索关键词、用户输入 |
| 枚举 | 排序方式、筛选条件、Tab 选择 |
| 可空值 | 当前选中项 |

### 2.4 什么时候不该用 StateProvider？

当你的状态满足以下任一条件时，应该使用 `Notifier` + `NotifierProvider`（第三章讲解）：

- 状态是一个**复杂对象**（如包含多个字段的 Model）
- 需要**自定义逻辑**来验证状态变更
- 状态修改涉及**副作用**（如 API 调用）

```dart
// ❌ 不推荐：复杂状态用 StateProvider
final userProvider = StateProvider<User>((ref) => User(name: '', age: 0));

// ✅ 推荐：复杂状态用 NotifierProvider（第三章讲）
final userProvider = NotifierProvider<UserNotifier, User>(() => UserNotifier());
```

---

## 3. Provider vs StateProvider 对比

| 对比 | Provider | StateProvider |
|------|----------|---------------|
| 可变性 | ❌ 只读 | ✅ 可读可写 |
| 典型用途 | 配置、工具类、派生值 | 简单的 UI 状态 |
| 修改方式 | 不能直接修改 | `.notifier.state = xxx` |
| 依赖其他 Provider | ✅ 可以 | ✅ 可以 |
| 响应式更新 | ✅ 依赖变化时重算 | ✅ state 变化时通知 |

### 决策流程

```
需要一个 Provider？
│
├─ 值是只读的、计算出来的、或者是依赖注入？
│  └─ ✅ 使用 Provider
│
├─ 值是简单类型（int/bool/String/enum）且需要修改？
│  └─ ✅ 使用 StateProvider
│
└─ 值是复杂对象，或修改逻辑复杂？
   └─ ✅ 使用 NotifierProvider（下一章）
```

---

## 4. 实战示例：主题切换与筛选

本章示例代码演示了以下功能：

1. **Provider** 提供只读的产品列表
2. **StateProvider** 管理排序方式和搜索关键词
3. **Provider** 作为派生值，组合产品列表 + 排序 + 搜索

```
用户操作
  │
  ├── 输入搜索词 → searchProvider (StateProvider) ─┐
  │                                                │
  ├── 选择排序方式 → sortTypeProvider (StateProvider)─┤
  │                                                │
  │   productsProvider (Provider) ─────────────────┤
  │                                                │
  └── 显示结果 ← filteredProductsProvider (Provider) ◄┘
```

---

## 5. 小结

| 知识点 | 要点 |
|--------|------|
| Provider | 只读值，适合配置、工具类、派生计算 |
| StateProvider | 简单可变状态，适合 int/bool/String/enum |
| 派生 Provider | Provider 内用 `ref.watch` 依赖其他 Provider，自动重算 |
| .notifier.state | 修改 StateProvider 值的方式 |
| .update() | 基于当前值计算新值 |

> 📌 **下一章**将学习 `Notifier` 和 `NotifierProvider`，处理更复杂的状态逻辑。
