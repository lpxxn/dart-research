# 第一章：Riverpod 简介与环境搭建

> 本章将带你了解 Riverpod 是什么、为什么选择它，以及如何从零开始搭建环境并运行第一个 Riverpod 示例。

## 目录

1. [什么是 Riverpod](#1-什么是-riverpod)
2. [Riverpod vs Provider 对比](#2-riverpod-vs-provider-对比)
3. [Riverpod 的包选择](#3-riverpod-的包选择)
4. [安装与配置](#4-安装与配置)
5. [ProviderScope 是什么](#5-providerscope-是什么)
6. [第一个示例：计数器](#6-第一个示例计数器)
7. [核心概念总览](#7-核心概念总览)
8. [小结](#8-小结)

---

## 1. 什么是 Riverpod

Riverpod 是一个 **响应式状态管理 + 依赖注入** 框架，由 Provider 的作者 Remi Rousselet 开发。名字 "Riverpod" 其实是 "Provider" 的字母重新排列（anagram）。

### 1.1 核心特点

| 特点 | 说明 |
|------|------|
| **编译时安全** | Provider 是全局声明的变量，不会出现"找不到 Provider"的运行时错误 |
| **不依赖 BuildContext** | 通过 `ref` 对象访问状态，在任何地方都能使用 |
| **声明式** | Provider 之间可以自由组合，依赖关系自动追踪 |
| **可测试** | 内置 override 机制，轻松替换任何 Provider 进行测试 |
| **自动缓存与销毁** | 支持 `autoDispose` 自动管理生命周期 |

### 1.2 Riverpod 的发展

```
Provider (旧) ──→ Riverpod 1.x ──→ Riverpod 2.x (当前推荐)
                                      │
                                      ├── Notifier 替代 StateNotifier
                                      ├── AsyncNotifier 替代 FutureProvider + StateNotifier
                                      └── 支持代码生成 (@riverpod)
```

---

## 2. Riverpod vs Provider 对比

| 对比维度 | Provider | Riverpod |
|----------|----------|----------|
| 依赖 BuildContext | ✅ 必须 | ❌ 不需要 |
| 编译时安全 | ❌ 运行时才报错 | ✅ 编译时检查 |
| 同类型多实例 | ❌ 会冲突 | ✅ 每个 Provider 独立 |
| Provider 组合 | ⚠️ ProxyProvider | ✅ ref.watch 直接组合 |
| 测试 | ⚠️ 需要 Widget 树 | ✅ ProviderContainer 直接测试 |
| 自动销毁 | ❌ 手动管理 | ✅ autoDispose |
| 代码生成 | ❌ 无 | ✅ @riverpod |

### 为什么迁移？

```dart
// ❌ Provider：运行时可能崩溃
final counter = context.watch<CounterModel>();  // 如果上方没注册，直接崩溃

// ✅ Riverpod：编译时就安全
final counter = ref.watch(counterProvider);     // counterProvider 是全局变量，永远存在
```

---

## 3. Riverpod 的包选择

Riverpod 提供三个包，根据你的需求选择：

| 包名 | 适用场景 | 说明 |
|------|----------|------|
| `riverpod` | 纯 Dart 项目 | 不依赖 Flutter |
| `flutter_riverpod` | Flutter 项目（推荐） | 提供 ConsumerWidget 等 Flutter 集成 |
| `hooks_riverpod` | Flutter + flutter_hooks | 如果你同时使用 flutter_hooks |

> 💡 **本教程使用 `flutter_riverpod`**，这是最通用的选择。

---

## 4. 安装与配置

### 4.1 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
```

然后运行：

```bash
flutter pub get
```

### 4.2 可选：代码生成（后续章节会详细讲）

```yaml
dependencies:
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

---

## 5. ProviderScope 是什么

`ProviderScope` 是 Riverpod 的**根容器**，它存储所有 Provider 的状态。你必须在 `main()` 中用 `ProviderScope` 包裹整个 App：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(       // ← 必须包裹在最外层
      child: MyApp(),
    ),
  );
}
```

### 为什么需要 ProviderScope？

- 它内部创建了 `ProviderContainer`，用来存储和管理所有 Provider 的状态
- 没有 `ProviderScope`，`ref.watch` / `ref.read` 无法工作
- 通常只需要在 `main()` 中放一个，特殊场景可以嵌套（用于 override）

---

## 6. 第一个示例：计数器

### 6.1 声明 Provider

```dart
// 全局声明一个 StateProvider，用于管理一个 int 值
final counterProvider = StateProvider<int>((ref) => 0);
```

**关键点：**
- `StateProvider` 适合管理简单的可变状态
- `(ref) => 0` 是初始值工厂函数，返回初始状态 `0`
- `counterProvider` 是一个全局变量，在任何地方都能引用

### 6.2 使用 ConsumerWidget

```dart
class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch：响应式监听，值变化时自动重建
    final count = ref.watch(counterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod 计数器')),
      body: Center(
        child: Text('$count', style: const TextStyle(fontSize: 60)),
      ),
      floatingActionButton: FloatingActionButton(
        // ref.read：一次性读取，不监听变化（在回调中使用）
        onPressed: () => ref.read(counterProvider.notifier).state++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 6.3 ref.watch vs ref.read

| 方法 | 用途 | 使用场景 |
|------|------|----------|
| `ref.watch` | 监听 Provider，值变时重建 Widget | 在 `build` 方法中 |
| `ref.read` | 一次性读取，不监听 | 在回调（onPressed）中 |

```dart
// ✅ 正确：build 中用 watch
final count = ref.watch(counterProvider);

// ✅ 正确：回调中用 read
onPressed: () => ref.read(counterProvider.notifier).state++

// ❌ 错误：build 中用 read（不会自动刷新 UI）
final count = ref.read(counterProvider);  // 不要这样做！

// ❌ 错误：回调中用 watch（会导致不必要的监听）
onPressed: () => ref.watch(counterProvider.notifier).state++  // 不要这样做！
```

---

## 7. 核心概念总览

本教程后续章节将依次深入以下概念：

```
┌─────────────────────────────────────────────────┐
│                   Riverpod 核心                    │
├─────────────────────────────────────────────────┤
│                                                   │
│  Provider 类型          修饰符          消费方式     │
│  ┌──────────────┐  ┌────────────┐  ┌──────────┐ │
│  │ Provider      │  │ autoDispose│  │ ref.watch│ │
│  │ StateProvider │  │ family     │  │ ref.read │ │
│  │ FutureProvider│  │ keepAlive  │  │ ref.listen│ │
│  │ StreamProvider│  └────────────┘  │ select   │ │
│  │ NotifierProv. │                  └──────────┘ │
│  │ AsyncNotifier │  代码生成                       │
│  │   Provider    │  ┌────────────┐               │
│  └──────────────┘  │ @riverpod  │               │
│                     └────────────┘               │
│                                                   │
│  高级                                             │
│  ┌──────────────────────────────────────────┐    │
│  │ ProviderObserver · ProviderContainer      │    │
│  │ Scope override  · 测试                     │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

---

## 8. 小结

| 知识点 | 要点 |
|--------|------|
| Riverpod 是什么 | Provider 的进化版，编译时安全、不依赖 BuildContext |
| 安装 | `flutter_riverpod: ^2.5.0` |
| ProviderScope | 必须包裹在 App 最外层 |
| StateProvider | 管理简单可变状态 |
| ConsumerWidget | 替代 StatelessWidget，提供 `ref` 参数 |
| ref.watch | build 中使用，响应式监听 |
| ref.read | 回调中使用，一次性读取 |

> 📌 **下一章**我们将深入学习 Provider 和 StateProvider 的各种用法和区别。
