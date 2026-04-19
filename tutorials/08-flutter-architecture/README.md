# Flutter 架构与工程化 — 系统教程

本项目是 Flutter 架构设计与工程化实践的系统学习教程，涵盖项目结构、架构模式、依赖注入、测试（单元 / Widget / 集成）、代码生成、国际化、性能优化与发布 CI/CD。

## 📚 章节目录

| 章节 | 文件 | 主题 |
|------|------|------|
| 第 1 章 | `ch01_project_structure.dart` | 项目结构组织 |
| 第 2 章 | `ch02_architecture_patterns.dart` | 架构模式（MVC / MVVM / Clean） |
| 第 3 章 | `ch03_dependency_injection.dart` | 依赖注入 |
| 第 4 章 | `ch04_unit_testing.dart` | 单元测试 |
| 第 5 章 | `ch05_widget_testing.dart` | Widget 测试 |
| 第 6 章 | `ch06_integration_testing.dart` | 集成测试 |
| 第 7 章 | `ch07_code_generation.dart` | 代码生成 |
| 第 8 章 | `ch08_internationalization.dart` | 国际化与本地化 |
| 第 9 章 | `ch09_performance.dart` | 性能优化 |
| 第 10 章 | `ch10_release_cicd.dart` | 发布与 CI/CD |

## 🚀 运行方式

### 运行导航首页

```bash
flutter run
```

### 运行单个章节示例

```bash
flutter run -t lib/ch01_project_structure.dart
flutter run -t lib/ch02_architecture_patterns.dart
flutter run -t lib/ch03_dependency_injection.dart
flutter run -t lib/ch04_unit_testing.dart
flutter run -t lib/ch05_widget_testing.dart
flutter run -t lib/ch06_integration_testing.dart
flutter run -t lib/ch07_code_generation.dart
flutter run -t lib/ch08_internationalization.dart
flutter run -t lib/ch09_performance.dart
flutter run -t lib/ch10_release_cicd.dart
```

### 运行测试

```bash
flutter test test/ch04_unit_test.dart
flutter test test/ch05_widget_test.dart
```

## 📁 项目结构

```
lib/
├── main.dart                        # 导航首页
├── ch01_project_structure.dart      # 项目结构
├── ch02_architecture_patterns.dart  # 架构模式
├── ch03_dependency_injection.dart   # 依赖注入
├── ch04_unit_testing.dart           # 单元测试
├── ch05_widget_testing.dart         # Widget 测试
├── ch06_integration_testing.dart    # 集成测试
├── ch07_code_generation.dart        # 代码生成
├── ch08_internationalization.dart   # 国际化
├── ch09_performance.dart            # 性能优化
└── ch10_release_cicd.dart           # 发布与 CI/CD
test/
├── ch04_unit_test.dart              # 单元测试用例
└── ch05_widget_test.dart            # Widget 测试用例
```

## 🔧 环境要求

- Flutter 3.x+
- Dart 3.x+
