# 第九章：高级模式

> 本章学习 Riverpod 的高级特性：ProviderObserver 全局日志、ProviderContainer 非 Widget 使用、Scope override 子树替换，以及从 StateNotifier 迁移到 Notifier。

## 目录

1. [ProviderObserver — 全局日志](#1-providerobserver--全局日志)
2. [ProviderContainer — 非 Widget 环境](#2-providercontainer--非-widget-环境)
3. [ProviderScope override — 子树替换](#3-providerscope-override--子树替换)
4. [从 StateNotifier 迁移到 Notifier](#4-从-statenotifier-迁移到-notifier)
5. [ref.invalidate 与 ref.refresh](#5-refinvalidate-与-refrefresh)
6. [实战示例](#6-实战示例)
7. [小结](#7-小结)

---

## 1. ProviderObserver — 全局日志

`ProviderObserver` 允许你监听所有 Provider 的生命周期事件，适合调试和日志记录。

### 1.1 创建 Observer

```dart
class MyObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    print('✅ 创建: ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    print('🔄 更新: ${provider.name ?? provider.runtimeType}: $previousValue → $newValue');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    print('🗑️ 销毁: ${provider.name ?? provider.runtimeType}');
  }

  @override
  void providerDidFail(ProviderBase provider, Object error, StackTrace stackTrace, ProviderContainer container) {
    print('❌ 错误: ${provider.name ?? provider.runtimeType}: $error');
  }
}
```

### 1.2 注册 Observer

```dart
void main() {
  runApp(
    ProviderScope(
      observers: [MyObserver()],  // 注册 Observer
      child: const MyApp(),
    ),
  );
}
```

### 1.3 常见用途

| 用途 | 说明 |
|------|------|
| 调试 | 打印所有状态变化 |
| 性能监控 | 追踪 Provider 创建/销毁频率 |
| 错误上报 | 统一收集 Provider 错误 |
| 分析 | 记录用户行为（状态变化 → 事件） |

---

## 2. ProviderContainer — 非 Widget 环境

`ProviderContainer` 是 Provider 状态的底层容器。在没有 Widget 树的环境中（如测试、后台服务），你可以直接使用它。

### 2.1 基本用法

```dart
// 创建容器
final container = ProviderContainer();

// 读取 Provider
final value = container.read(myProvider);

// 监听变化
container.listen(myProvider, (prev, next) {
  print('值变化：$prev → $next');
});

// 销毁容器
container.dispose();
```

### 2.2 在 main() 中使用

```dart
void main() {
  final container = ProviderContainer();

  // 在 App 启动前读取或初始化一些 Provider
  final config = container.read(configProvider);
  print('Config loaded: $config');

  runApp(
    UncontrolledProviderScope(
      container: container,  // 复用已有容器
      child: const MyApp(),
    ),
  );
}
```

---

## 3. ProviderScope override — 子树替换

你可以在 Widget 树的任意位置用 `ProviderScope` 替换某个 Provider 的值。

### 3.1 基本用法

```dart
// 全局定义
final themeColorProvider = Provider<Color>((ref) => Colors.blue);

// 在子树中 override
ProviderScope(
  overrides: [
    themeColorProvider.overrideWithValue(Colors.red),  // 子树中变为红色
  ],
  child: const ChildWidget(),
)
```

### 3.2 常见场景

| 场景 | 说明 |
|------|------|
| 列表项 | 每个列表项 override 一个"当前项" Provider |
| 测试 | override Repository 为 Mock 实现 |
| 多租户 | 不同区域使用不同的配置 |

### 3.3 列表项 override 模式

```dart
// 定义一个"当前 Todo" Provider（不需要初始值）
final currentTodoProvider = Provider<Todo>((ref) => throw UnimplementedError());

// 列表中每项 override
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) {
    return ProviderScope(
      overrides: [
        currentTodoProvider.overrideWithValue(todos[index]),
      ],
      child: const TodoTile(),  // TodoTile 中可以 ref.watch(currentTodoProvider)
    );
  },
)
```

---

## 4. 从 StateNotifier 迁移到 Notifier

Riverpod 2.x 推荐使用 `Notifier` 替代 `StateNotifier`：

### 4.1 对比

| 项目 | StateNotifier (旧) | Notifier (新) |
|------|-------------------|---------------|
| 初始状态 | 构造函数 `super(initialState)` | `build()` 方法返回 |
| ref 访问 | 需要通过构造函数传入 | 内置 `ref` 属性 |
| 依赖其他 Provider | 不方便 | `build()` 中 `ref.watch` |
| 生命周期 | 手动管理 | 自动管理 |

### 4.2 迁移示例

```dart
// ❌ 旧：StateNotifier
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}
final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);

// ✅ 新：Notifier
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;  // 初始状态
  void increment() => state++;
}
final counterProvider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);
```

---

## 5. ref.invalidate 与 ref.refresh

### 5.1 ref.invalidate

强制 Provider 重新执行 `build()`，丢弃当前状态：

```dart
// 重新加载数据
ref.invalidate(userListProvider);
```

### 5.2 ref.refresh

类似 `invalidate`，但同时返回新值：

```dart
// 刷新并获取新值
final newValue = ref.refresh(userListProvider);
```

---

## 6. 实战示例

本章代码演示：
- ProviderObserver：实时日志面板
- ProviderScope override：列表项 Provider
- ref.invalidate / ref.refresh

---

## 7. 小结

| 知识点 | 要点 |
|--------|------|
| ProviderObserver | 全局监听 Provider 生命周期（调试/日志） |
| ProviderContainer | 非 Widget 环境下使用 Provider |
| ProviderScope override | 子树中替换 Provider 值 |
| StateNotifier → Notifier | 推荐迁移，build() 替代构造函数 |
| ref.invalidate | 强制重新执行 build() |
| ref.refresh | invalidate + 立即返回新值 |

> 📌 **下一章**将学习如何测试 Riverpod Provider。
