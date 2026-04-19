# Flutter 网络与数据 — 系统教程

本项目是 Flutter 网络请求与数据处理的系统学习教程，涵盖 HTTP 基础、Dio、JSON 序列化、本地存储、Repository 模式、WebSocket、GraphQL 以及综合实战。

## 📚 章节目录

| 章节 | 文件 | 主题 |
|------|------|------|
| 第 1 章 | `ch01_http_basics.dart` | HTTP 基础与 `http` 包 |
| 第 2 章 | `ch02_dio.dart` | Dio 网络库 |
| 第 3 章 | `ch03_json_serialization.dart` | JSON 序列化与反序列化 |
| 第 4 章 | `ch04_local_storage.dart` | 本地存储（SharedPreferences / SQLite） |
| 第 5 章 | `ch05_repository_pattern.dart` | Repository 模式 |
| 第 6 章 | `ch06_websocket.dart` | WebSocket 实时通信 |
| 第 7 章 | `ch07_graphql.dart` | GraphQL 客户端 |
| 第 8 章 | `ch08_weather_app.dart` | 天气应用综合实战 |

## 🚀 运行方式

### 运行导航首页

```bash
flutter run
```

### 运行单个章节示例

```bash
flutter run -t lib/ch01_http_basics.dart
flutter run -t lib/ch02_dio.dart
flutter run -t lib/ch03_json_serialization.dart
flutter run -t lib/ch04_local_storage.dart
flutter run -t lib/ch05_repository_pattern.dart
flutter run -t lib/ch06_websocket.dart
flutter run -t lib/ch07_graphql.dart
flutter run -t lib/ch08_weather_app.dart
```

## 📁 项目结构

```
lib/
├── main.dart                    # 导航首页
├── ch01_http_basics.dart        # HTTP 基础
├── ch02_dio.dart                # Dio 网络库
├── ch03_json_serialization.dart # JSON 序列化
├── ch04_local_storage.dart      # 本地存储
├── ch05_repository_pattern.dart # Repository 模式
├── ch06_websocket.dart          # WebSocket
├── ch07_graphql.dart            # GraphQL
└── ch08_weather_app.dart        # 天气应用实战
```

## 🔧 环境要求

- Flutter 3.x+
- Dart 3.x+
