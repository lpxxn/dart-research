# 第 1 章：Hello Dart

## 1.1 Dart 简介

Dart 是由 Google 开发的一门客户端优化的编程语言，是 Flutter 框架的灵魂语言。自 2011 年首次发布以来，Dart 经历了多次重大演进，如今已成为构建高性能跨平台应用的首选语言之一。

### Dart 的核心特点

**AOT/JIT 双模编译**：Dart 同时支持 AOT（Ahead-of-Time，提前编译）和 JIT（Just-in-Time，即时编译）两种编译模式。在开发阶段，JIT 编译提供热重载（Hot Reload）能力，让你修改代码后立即看到效果；在发布阶段，AOT 编译将代码编译为高效的原生机器码，保证应用的启动速度和运行性能。

**强类型 + 类型推断**：Dart 是一门强类型语言，每个变量都有明确的类型。但你并不需要处处写类型声明——Dart 的类型推断系统足够智能，可以根据赋值自动推断变量类型。这在保证类型安全的同时，也让代码简洁易读。

**内置空安全（Sound Null Safety）**：从 Dart 2.12 开始，空安全成为语言的核心特性。默认情况下，所有变量都不可为 null，如果你需要一个可能为 null 的变量，必须显式声明为可空类型（如 `String?`）。这从根本上消除了空指针异常这一最常见的运行时错误。

**一等公民的异步支持**：Dart 原生支持 `async`/`await` 语法和 `Future`/`Stream` API，让异步编程像写同步代码一样自然。无论是网络请求、文件 I/O 还是定时任务，都能优雅地处理。

**单线程 + 事件循环**：Dart 采用单线程事件循环模型（类似 JavaScript），通过 Isolate 实现并发。这种模型避免了多线程编程中常见的锁竞争和数据竞态问题，同时通过事件循环高效地处理 I/O 密集型任务。

### 与其他语言的对比

| 特性 | Dart | Java | JavaScript | Kotlin | Swift |
|------|------|------|------------|--------|-------|
| 空安全 | 内置 Sound Null Safety | 需要注解 | 无 | 内置 | 内置 Optional |
| 编译方式 | AOT + JIT | JIT + AOT (GraalVM) | JIT | JIT + AOT | AOT |
| 异步模型 | async/await + Isolate | Thread + CompletableFuture | async/await + Worker | 协程 | async/await + Actor |
| 主要平台 | 移动/Web/桌面/服务端 | 服务端/Android | Web/服务端 | Android/服务端 | iOS/macOS |
| UI 框架 | Flutter | Android SDK | React/Vue | Jetpack Compose | SwiftUI |

Dart 的定位是一门**全平台通用语言**，通过 Flutter 实现"一套代码，多端运行"的愿景。

## 1.2 环境搭建

### 方式 1：安装 Dart SDK

在 macOS 上使用 Homebrew 安装：

```bash
brew tap dart-lang/dart
brew install dart
```

在 Linux 上：

```bash
sudo apt-get update
sudo apt-get install dart
```

在 Windows 上可以通过 [Chocolatey](https://chocolatey.org/) 安装：

```bash
choco install dart-sdk
```

### 方式 2：安装 Flutter SDK（推荐）

Flutter SDK 自带 Dart SDK，安装 Flutter 后即可直接使用 Dart。如果你计划学习 Flutter 开发，推荐这种方式：

```bash
# macOS
brew install flutter

# 或从官网下载：https://flutter.dev/docs/get-started/install
```

### 验证安装

安装完成后，在终端中运行以下命令验证：

```bash
dart --version
# 输出类似：Dart SDK version: 3.10.4 (stable)
```

## 1.3 第一个程序

### main() 函数是入口

每个 Dart 程序都从 `main()` 函数开始执行，这是程序的入口点：

```dart
void main() {
  print('Hello, Dart!');
}
```

- `void` 表示函数没有返回值
- `main` 是一个特殊的函数名，Dart 运行时会自动查找并调用它
- `print()` 是内置的输出函数，将内容打印到控制台

### 字符串插值

Dart 提供了方便的字符串插值语法，使用 `$` 引用变量，使用 `${}` 引用表达式：

```dart
var name = 'Dart';
var version = 3.10;

// 直接引用变量
print('Welcome to $name');

// 引用表达式
print('1 + 2 = ${1 + 2}');

// 调用方法
print('大写: ${name.toUpperCase()}');
```

### 分号是必须的

与 JavaScript 不同，Dart 中每条语句必须以分号 `;` 结尾，不能省略。这是一条强制规则，而非可选的风格偏好。

```dart
var x = 42;   // ✓ 正确
var y = 42    // ✗ 编译错误：缺少分号
```

## 1.4 项目结构

一个标准的 Dart 项目结构如下：

```
my_project/
├── pubspec.yaml       # 项目配置文件（名称、依赖、SDK 版本等）
├── pubspec.lock       # 锁定依赖版本（自动生成）
├── analysis_options.yaml  # 静态分析配置
├── bin/               # 可执行文件目录
│   └── main.dart      # 程序入口
├── lib/               # 库代码目录
│   └── src/           # 私有库代码
├── test/              # 测试文件目录
│   └── main_test.dart
└── .dart_tool/        # Dart 工具缓存（自动生成）
```

**pubspec.yaml** 是项目的核心配置文件，定义了项目名称、版本、SDK 约束和依赖：

```yaml
name: dart_tutorial
description: Dart 语言教程项目
version: 1.0.0

environment:
  sdk: ^3.10.4

dependencies:
  path: ^1.9.0

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

- **bin/** 目录存放可执行的 Dart 文件，每个文件都可以通过 `dart run` 独立运行
- **lib/** 目录存放库代码，可以被 bin/ 和 test/ 中的文件导入使用
- **test/** 目录存放单元测试文件

## 1.5 运行与编译

### 运行程序

使用 `dart run` 命令运行 bin/ 目录下的文件：

```bash
# 运行指定文件
dart run bin/ch01_hello.dart

# 如果 bin/ 下只有一个与包同名的文件，可以直接：
dart run
```

### 编译为原生可执行文件

Dart 可以将程序编译为独立的原生可执行文件，无需安装 Dart SDK 即可运行：

```bash
# 编译为原生可执行文件
dart compile exe bin/ch01_hello.dart -o hello

# 运行编译后的文件
./hello
```

### 静态分析

`dart analyze` 命令对代码进行静态分析，检查潜在的错误和代码风格问题：

```bash
dart analyze
# 如果一切正常，输出：No issues found!
```

静态分析的规则由 `analysis_options.yaml` 文件配置，推荐使用官方的 `package:lints/recommended.yaml` 规则集。
