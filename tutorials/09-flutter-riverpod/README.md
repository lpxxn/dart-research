# Flutter Riverpod 系统教程

从零到精通的 Riverpod 完整学习路线，共 **12 章**，涵盖基础概念、异步处理、代码生成、测试、最佳实践到完整实战项目。

## 📚 章节目录

| 章节 | 标题 | 文档 | 代码 | 难度 |
|:---:|------|:---:|:---:|:---:|
| 01 | Riverpod 简介与环境搭建 | [文档](docs/ch01_introduction.md) | [代码](lib/ch01_introduction.dart) | ⭐ |
| 02 | Provider 基础类型 | [文档](docs/ch02_basic_providers.md) | [代码](lib/ch02_basic_providers.dart) | ⭐ |
| 03 | Notifier 与 NotifierProvider | [文档](docs/ch03_notifier.md) | [代码](lib/ch03_notifier.dart) | ⭐⭐ |
| 04 | ref 详解 | [文档](docs/ch04_ref_deep_dive.md) | [代码](lib/ch04_ref_deep_dive.dart) | ⭐⭐ |
| 05 | 异步 Provider | [文档](docs/ch05_async_providers.md) | [代码](lib/ch05_async_providers.dart) | ⭐⭐ |
| 06 | 修饰符：autoDispose 与 family | [文档](docs/ch06_modifiers.md) | [代码](lib/ch06_modifiers.dart) | ⭐⭐⭐ |
| 07 | Riverpod Generator（代码生成） | [文档](docs/ch07_code_generation.md) | [代码](lib/ch07_code_generation.dart) | ⭐⭐⭐ |
| 08 | Provider 组合与依赖 | [文档](docs/ch08_composition.md) | [代码](lib/ch08_composition.dart) | ⭐⭐⭐ |
| 09 | 高级模式 | [文档](docs/ch09_advanced_patterns.md) | [代码](lib/ch09_advanced_patterns.dart) | ⭐⭐⭐ |
| 10 | 测试 | [文档](docs/ch10_testing.md) | [代码](lib/ch10_testing.dart) | ⭐⭐⭐ |
| 11 | 最佳实践与常见陷阱 | [文档](docs/ch11_best_practices.md) | [代码](lib/ch11_best_practices.dart) | ⭐⭐⭐⭐ |
| 12 | 实战项目：天气查询 App | [文档](docs/ch12_weather_app.md) | [代码](lib/ch12_weather_app.dart) | ⭐⭐⭐⭐ |

## 🚀 运行方式

```bash
# 运行导航首页
flutter run

# 运行单个章节示例
flutter run -t lib/ch01_introduction.dart
flutter run -t lib/ch02_basic_providers.dart
# ... 以此类推

# 运行测试
flutter test
```

## 🗺️ 学习路线图

```
 ┌────────────────────────────┐
 │ 01 简介与环境搭建 (入门)      │
 └─────────────┬──────────────┘
               │
 ┌─────────────▼──────────────┐
 │ 02 Provider 基础类型         │
 └─────────────┬──────────────┘
               │
 ┌─────────────▼──────────────┐
 │ 03 Notifier 与 NotifierProvider │
 └─────────────┬──────────────┘
               │
 ┌─────────────▼──────────────┐
 │ 04 ref 详解                  │
 └─────────────┬──────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
 ┌───────────┐   ┌───────────┐
 │ 05 异步    │   │ 06 修饰符  │
 └─────┬─────┘   └─────┬─────┘
       └───────┬───────┘
               │
 ┌─────────────▼──────────────┐
 │ 07 代码生成                  │
 └─────────────┬──────────────┘
               │
 ┌─────────────▼──────────────┐
 │ 08 组合与依赖                │
 └─────────────┬──────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
 ┌───────────┐   ┌───────────┐
 │ 09 高级模式 │   │ 10 测试    │
 └─────┬─────┘   └─────┬─────┘
       └───────┬───────┘
               │
 ┌─────────────▼──────────────┐
 │ 11 最佳实践与常见陷阱         │
 └─────────────┬──────────────┘
               │
 ┌─────────────▼──────────────┐
 │ 12 实战项目：天气查询 App     │
 └────────────────────────────┘
```

## 环境要求

- Flutter 3.x+
- Dart 3.x+
- flutter_riverpod ^2.5.0
