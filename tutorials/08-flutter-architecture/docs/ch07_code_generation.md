# 第7章：代码生成

## 目录

1. [为什么需要代码生成](#1-为什么需要代码生成)
2. [build_runner 原理](#2-build_runner-原理)
3. [json_serializable](#3-json_serializable)
4. [freezed —— 不可变数据类](#4-freezed--不可变数据类)
5. [auto_route —— 类型安全路由](#5-auto_route--类型安全路由)
6. [其他代码生成工具](#6-其他代码生成工具)
7. [最佳实践](#7-最佳实践)

---

## 1. 为什么需要代码生成

Dart 不像 Kotlin 有 `data class`，也不像 Java 有 Lombok。编写模型类时需要大量样板代码：

```dart
// 😩 手写一个简单的 User 类需要这么多代码
class User {
  final String name;
  final int age;
  final String email;

  const User({required this.name, required this.age, required this.email});

  // JSON 序列化
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age, 'email': email};
  }

  // 相等性比较
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          name == other.name &&
          age == other.age &&
          email == other.email;

  @override
  int get hashCode => Object.hash(name, age, email);

  // toString
  @override
  String toString() => 'User(name: $name, age: $age, email: $email)';

  // copyWith
  User copyWith({String? name, int? age, String? email}) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }
}
```

**问题**：
- 样板代码多，容易出错
- 添加字段时需要修改多个方法
- `fromJson`/`toJson` 手写容易漏字段
- `==` 和 `hashCode` 容易不一致

**代码生成的优势**：
- 自动生成样板代码，减少人为错误
- 字段变更后重新生成即可，无需手动更新
- 编译期检查，类型安全

## 2. build_runner 原理

### 2.1 什么是 build_runner

`build_runner` 是 Dart 的构建系统，它扫描源代码中的注解（Annotation），然后通过对应的 **Builder** 生成代码。

### 2.2 工作流程

```
源代码 + 注解
    ↓
build_runner 扫描
    ↓
Builder 处理注解
    ↓
生成 .g.dart / .freezed.dart 文件
    ↓
编译时引入生成的代码
```

### 2.3 配置依赖

```yaml
dependencies:
  json_annotation: ^4.8.1     # JSON 注解
  freezed_annotation: ^2.4.1  # freezed 注解

dev_dependencies:
  build_runner: ^2.4.6        # 构建运行器
  json_serializable: ^6.7.1   # JSON 代码生成器
  freezed: ^2.4.5             # freezed 代码生成器
```

### 2.4 常用命令

```bash
# 一次性构建
dart run build_runner build

# 监听文件变化，自动重新构建
dart run build_runner watch

# 清理生成的文件后重新构建
dart run build_runner build --delete-conflicting-outputs
```

### 2.5 part 指令

生成的代码通过 `part` 指令与源文件关联：

```dart
// user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';  // 指向生成的文件

@JsonSerializable()
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  // 这些工厂方法的实现在 user.g.dart 中
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

生成的 `user.g.dart`：

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
      name: json['name'] as String,
      age: json['age'] as int,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'age': instance.age,
    };
```

## 3. json_serializable

### 3.1 基本用法

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String name;
  final int age;

  @JsonKey(name: 'email_address')  // 自定义 JSON 键名
  final String email;

  @JsonKey(defaultValue: false)     // 默认值
  final bool isActive;

  @JsonKey(includeIfNull: false)    // 为 null 时不包含在 JSON 中
  final String? avatar;

  User({
    required this.name,
    required this.age,
    required this.email,
    this.isActive = false,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### 3.2 嵌套对象

```dart
@JsonSerializable(explicitToJson: true)  // 嵌套对象也调用 toJson
class Order {
  final String id;
  final User customer;
  final List<OrderItem> items;

  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  // 自定义日期序列化
  static DateTime _dateFromJson(String date) => DateTime.parse(date);
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
```

### 3.3 枚举序列化

```dart
@JsonEnum(valueField: 'code')
enum Status {
  active('ACTIVE'),
  inactive('INACTIVE'),
  pending('PENDING');

  final String code;
  const Status(this.code);
}
```

### 3.4 泛型支持

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
```

## 4. freezed —— 不可变数据类

### 4.1 什么是 freezed

`freezed` 是一个强大的代码生成工具，自动生成：
- 不可变类
- `copyWith` 方法
- `==` 和 `hashCode`
- `toString`
- 模式匹配（联合类型 / Sealed Class）
- JSON 序列化（配合 `json_serializable`）

### 4.2 基本用法

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String name,
    required int age,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

使用：

```dart
final user = User(name: '张三', age: 25);

// copyWith - 创建修改后的副本
final updated = user.copyWith(age: 26);

// 相等性比较 - 自动基于所有字段
print(user == User(name: '张三', age: 25));  // true

// toString
print(user);  // User(name: 张三, age: 25, isActive: false)
```

### 4.3 联合类型（Sealed Class）

这是 freezed 最强大的特性之一：

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message) = Failure<T>;
  const factory Result.loading() = Loading<T>;
}
```

模式匹配使用：

```dart
final result = Result<User>.success(user);

// 使用 switch 表达式
final message = switch (result) {
  Success(:final data) => '成功: ${data.name}',
  Failure(:final message) => '失败: $message',
  Loading() => '加载中...',
};

// 或使用 when 方法
result.when(
  success: (data) => print('成功: ${data.name}'),
  failure: (message) => print('失败: $message'),
  loading: () => print('加载中...'),
);

// maybeWhen - 只处理部分情况
result.maybeWhen(
  success: (data) => print('成功'),
  orElse: () => print('其他状态'),
);
```

### 4.4 自定义方法和 getter

```dart
@freezed
class Temperature with _$Temperature {
  const Temperature._();  // 需要私有构造函数才能添加方法

  const factory Temperature.celsius(double value) = _Celsius;
  const factory Temperature.fahrenheit(double value) = _Fahrenheit;

  // 自定义 getter
  double get inCelsius => switch (this) {
    _Celsius(:final value) => value,
    _Fahrenheit(:final value) => (value - 32) * 5 / 9,
  };
}
```

## 5. auto_route —— 类型安全路由

### 5.1 问题：字符串路由不安全

```dart
// ❌ 传统路由 - 字符串容易写错，参数不安全
Navigator.pushNamed(context, '/user/detail', arguments: userId);
```

### 5.2 auto_route 配置

```yaml
dependencies:
  auto_route: ^7.8.4

dev_dependencies:
  auto_route_generator: ^7.3.2
  build_runner: ^2.4.6
```

### 5.3 定义路由

```dart
import 'package:auto_route/auto_route.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: UserDetailRoute.page),
    AutoRoute(page: SettingsRoute.page),
  ];
}

// 页面需要添加注解
@RoutePage()
class HomePage extends StatelessWidget {
  // ...
}

@RoutePage()
class UserDetailPage extends StatelessWidget {
  final int userId;  // 类型安全的参数

  const UserDetailPage({
    super.key,
    @PathParam('id') required this.userId,
  });
  // ...
}
```

### 5.4 使用生成的路由

```dart
// ✅ 类型安全，IDE 自动补全
context.router.push(UserDetailRoute(userId: 42));

// 替换当前页面
context.router.replace(const HomeRoute());

// 返回
context.router.pop();
```

## 6. 其他代码生成工具

| 工具 | 用途 | 注解 |
|------|------|------|
| `json_serializable` | JSON 序列化 | `@JsonSerializable` |
| `freezed` | 不可变数据类 | `@freezed` |
| `auto_route` | 类型安全路由 | `@AutoRouterConfig` |
| `injectable` | 依赖注入 | `@injectable` |
| `hive_generator` | Hive 数据库适配器 | `@HiveType` |
| `mockito` | Mock 生成 | `@GenerateMocks` |
| `retrofit` | API 客户端 | `@RestApi` |
| `envied` | 环境变量 | `@Envied` |

## 7. 最佳实践

### 7.1 项目组织

```
lib/
├── models/
│   ├── user.dart            # 源文件
│   ├── user.g.dart          # json_serializable 生成
│   └── user.freezed.dart    # freezed 生成
├── routes/
│   ├── app_router.dart
│   └── app_router.gr.dart   # auto_route 生成
```

### 7.2 .gitignore 策略

**推荐提交生成的代码**（生成文件加入版本控制）：

```gitignore
# 不要忽略 .g.dart 和 .freezed.dart
# 这样 CI/CD 不需要运行 build_runner
```

原因：
- CI/CD 构建更快
- 代码审查时可以看到生成代码的变化
- 不依赖 build_runner 版本一致性

### 7.3 build.yaml 配置

创建 `build.yaml` 自定义生成行为：

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          # 所有类默认使用 explicit_to_json
          explicit_to_json: true
          # 字段命名策略
          field_rename: snake
```

### 7.4 性能优化

```bash
# 只构建特定目录
dart run build_runner build \
  --build-filter="lib/models/**"

# 使用 watch 开发时自动重建
dart run build_runner watch --delete-conflicting-outputs
```

### 7.5 常见错误和解决方案

```
# 错误：Could not generate `fromJson` code for `X`
# 解决：确保嵌套类也有 @JsonSerializable 注解

# 错误：Conflicting outputs
# 解决：dart run build_runner build --delete-conflicting-outputs

# 错误：part 指令找不到文件
# 解决：先运行 build_runner 生成文件
```

---

## 总结

| 工具 | 解决的问题 | 生成的文件 |
|------|-----------|-----------|
| `json_serializable` | JSON 序列化样板代码 | `.g.dart` |
| `freezed` | 不可变类、联合类型 | `.freezed.dart` + `.g.dart` |
| `auto_route` | 类型安全路由 | `.gr.dart` |
| `build_runner` | 运行所有代码生成器 | - |

代码生成是 Flutter/Dart 生态中非常重要的一环，合理使用可以大幅减少样板代码，提高开发效率和代码质量。

**下一章**：[第8章：国际化](ch08_internationalization.md)
