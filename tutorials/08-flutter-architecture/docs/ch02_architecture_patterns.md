# 第二章：架构模式（Architecture Patterns）

> 本章深入探讨 Flutter 开发中常见的架构模式，从经典的 MVC 到现代的 Clean Architecture，
> 帮助你理解每种模式的核心思想、优缺点以及在 Flutter 中的实际应用。

---

## 目录

1. [架构模式概述](#架构模式概述)
2. [MVC 模式](#mvc-模式)
3. [MVP 模式](#mvp-模式)
4. [MVVM 模式](#mvvm-模式)
5. [Clean Architecture](#clean-architecture)
6. [架构演进路线](#架构演进路线)
7. [三层架构详解](#三层架构详解)
8. [Use Case 的概念和作用](#use-case-的概念和作用)
9. [Entity vs Model vs DTO](#entity-vs-model-vs-dto)
10. [Flutter 中实现 Clean Architecture 示例](#flutter-中实现-clean-architecture-示例)
11. [最佳实践](#最佳实践)

---

## 架构模式概述

在软件开发中，**架构模式**（Architecture Pattern）是对软件系统整体结构的一种高层次抽象描述。
良好的架构模式能带来以下好处：

- ✅ **可维护性**：代码结构清晰，易于修改和扩展
- ✅ **可测试性**：各层职责分离，便于单元测试
- ✅ **可复用性**：业务逻辑独立于框架，方便迁移
- ✅ **团队协作**：明确的分层让多人并行开发成为可能

---

## MVC 模式

### 概念

MVC（Model-View-Controller）是最经典的架构模式之一，将应用分为三个核心部分：

```
┌─────────────────────────────────────────┐
│              MVC 架构图                  │
│                                         │
│   ┌───────────┐    ┌──────────────┐     │
│   │           │───▶│              │     │
│   │   View    │    │  Controller  │     │
│   │  (视图)   │◀───│   (控制器)    │     │
│   └───────────┘    └──────┬───────┘     │
│         ▲                 │             │
│         │                 ▼             │
│         │          ┌──────────────┐     │
│         └──────────│    Model     │     │
│                    │   (模型)     │     │
│                    └──────────────┘     │
└─────────────────────────────────────────┘
```

- **Model（模型）**：负责数据和业务逻辑
- **View（视图）**：负责 UI 展示
- **Controller（控制器）**：处理用户输入，协调 Model 和 View

### 在 Flutter 中的应用

```dart
// Model - 数据模型
class User {
  final String name;
  final String email;
  User({required this.name, required this.email});
}

// Controller - 控制器
class UserController {
  List<User> users = [];

  void loadUsers() {
    users = [
      User(name: '张三', email: 'zhangsan@example.com'),
    ];
  }
}

// View - 视图（Flutter Widget）
class UserView extends StatelessWidget {
  final UserController controller;
  const UserView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: controller.users.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(controller.users[index].name));
      },
    );
  }
}
```

### 优缺点

| 方面 | 说明 |
|------|------|
| ✅ 简单直观 | 概念清晰，学习成本低 |
| ✅ 职责分离 | Model、View、Controller 各司其职 |
| ❌ Controller 膨胀 | 随着业务增长，Controller 代码量剧增 |
| ❌ View 和 Model 耦合 | View 可以直接访问 Model，导致耦合 |
| ❌ 测试困难 | Controller 依赖 View，不便于单元测试 |

---

## MVP 模式

### 概念

MVP（Model-View-Presenter）是 MVC 的改良版，核心区别在于 **Presenter 完全隔离了 View 和 Model**。

```
┌─────────────────────────────────────────┐
│              MVP 架构图                  │
│                                         │
│   ┌───────────┐    ┌──────────────┐     │
│   │           │───▶│              │     │
│   │   View    │    │  Presenter   │     │
│   │  (视图)   │◀───│  (表示器)    │     │
│   └───────────┘    └──────┬───────┘     │
│                           │             │
│                           ▼             │
│                    ┌──────────────┐     │
│                    │    Model     │     │
│                    │   (模型)     │     │
│                    └──────────────┘     │
└─────────────────────────────────────────┘
```

### 与 MVC 的关键区别

| 对比项 | MVC | MVP |
|--------|-----|-----|
| View 与 Model | View 可直接访问 Model | View 不知道 Model 的存在 |
| 中间层角色 | Controller 转发请求 | Presenter 持有 View 接口引用 |
| 通信方式 | 观察者模式 | 接口回调 |
| 可测试性 | 较差 | 较好（可 Mock View 接口） |

### Presenter 的角色

Presenter 是 MVP 的核心，它：

1. **接收 View 的用户事件**（如按钮点击）
2. **调用 Model 获取/处理数据**
3. **将处理结果通过接口回传给 View**

```dart
// View 接口 - 定义 View 需要实现的行为
abstract class UserListView {
  void showUsers(List<User> users);
  void showError(String message);
  void showLoading();
}

// Presenter - 处理业务逻辑
class UserListPresenter {
  final UserListView view;
  final UserRepository repository;

  UserListPresenter(this.view, this.repository);

  Future<void> loadUsers() async {
    view.showLoading();
    try {
      final users = await repository.getUsers();
      view.showUsers(users);
    } catch (e) {
      view.showError('加载失败：$e');
    }
  }
}
```

---

## MVVM 模式

### 概念

MVVM（Model-View-ViewModel）引入了 **数据绑定**（Data Binding）的概念，
View 和 ViewModel 之间通过数据绑定自动同步。

```
┌─────────────────────────────────────────────┐
│              MVVM 架构图                     │
│                                             │
│   ┌───────────┐  数据绑定  ┌─────────────┐  │
│   │           │◀═══════▶│             │  │
│   │   View    │          │  ViewModel  │  │
│   │  (视图)   │  Command │  (视图模型)  │  │
│   └───────────┘          └──────┬──────┘  │
│                                 │         │
│                                 ▼         │
│                          ┌──────────────┐ │
│                          │    Model     │ │
│                          │   (模型)     │ │
│                          └──────────────┘ │
└─────────────────────────────────────────────┘
```

### ViewModel 的职责

- 持有 View 所需的所有数据状态
- 提供数据转换逻辑（将 Model 数据转为 View 可展示的格式）
- 不持有 View 的引用（与 MVP 的 Presenter 不同）
- 通过**响应式机制**通知 View 更新

### 数据绑定在 Flutter 中的实现

Flutter 中可以通过 `ChangeNotifier` + `ListenableBuilder` 实现类似数据绑定的效果：

```dart
// ViewModel - 使用 ChangeNotifier 实现响应式
class UserViewModel extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners(); // 通知 View 更新

    _users = await repository.getUsers();
    _isLoading = false;
    notifyListeners(); // 再次通知 View
  }
}

// View - 监听 ViewModel 的变化
class UserListPage extends StatelessWidget {
  final UserViewModel viewModel;
  const UserListPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        if (viewModel.isLoading) {
          return const CircularProgressIndicator();
        }
        return ListView.builder(
          itemCount: viewModel.users.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(viewModel.users[i].name),
          ),
        );
      },
    );
  }
}
```

---

## Clean Architecture

### Robert C. Martin 的理念

Clean Architecture 由 Robert C. Martin（Uncle Bob）提出，核心理念是：

> **依赖规则（Dependency Rule）**：源代码的依赖关系只能从外层指向内层，内层不能知道外层的任何东西。

```
┌──────────────────────────────────────────────────────┐
│                Clean Architecture 同心圆              │
│                                                      │
│   ┌─── 外层 ──────────────────────────────────────┐  │
│   │  Frameworks & Drivers（框架和驱动）             │  │
│   │  ┌─── 第三层 ─────────────────────────────┐   │  │
│   │  │  Interface Adapters（接口适配器）        │   │  │
│   │  │  ┌─── 第二层 ──────────────────────┐   │   │  │
│   │  │  │  Application Business Rules     │   │   │  │
│   │  │  │  （应用业务规则 / Use Cases）     │   │   │  │
│   │  │  │  ┌─── 核心层 ──────────────┐    │   │   │  │
│   │  │  │  │  Enterprise Business    │    │   │   │  │
│   │  │  │  │  Rules（企业业务规则     │    │   │   │  │
│   │  │  │  │   / Entities）          │    │   │   │  │
│   │  │  │  └─────────────────────────┘    │   │   │  │
│   │  │  └─────────────────────────────────┘   │   │  │
│   │  └────────────────────────────────────────┘   │  │
│   └───────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘

依赖方向：外层 ──────▶ 内层（永远不能反向）
```

### 四层架构详解

| 层级 | 名称 | 职责 | Flutter 中的对应 |
|------|------|------|-----------------|
| 第一层（核心） | Entities | 企业级业务规则 | 纯 Dart 类 |
| 第二层 | Use Cases | 应用级业务规则 | 用例类 |
| 第三层 | Interface Adapters | 数据格式转换 | Repository 实现、Controller |
| 第四层（外层） | Frameworks & Drivers | 框架/工具 | Flutter Widget、HTTP 客户端 |

---

## 架构演进路线

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌──────────────────┐
│   MVC   │────▶│   MVP   │────▶│   MVVM   │────▶│ Clean Arch       │
│         │     │         │     │          │     │                  │
│ 简单直观 │     │ 接口隔离 │     │ 数据绑定  │     │ 完全解耦          │
│ 适合小型 │     │ 可测试性↑│     │ 响应式   │     │ 依赖规则          │
│ 耦合较高 │     │ 接口较多 │     │ 学习曲线↑│     │ 可测试性最佳      │
└─────────┘     └─────────┘     └──────────┘     └──────────────────┘

演进方向：简单 ───────────────────────────────────▶ 复杂但更健壮
```

### 各模式适用场景

| 模式 | 推荐场景 | 项目规模 |
|------|---------|---------|
| MVC | 原型开发、学习项目 | 小型 |
| MVP | 需要单元测试的项目 | 中小型 |
| MVVM | 需要响应式 UI 的项目 | 中型 |
| Clean Architecture | 企业级、长期维护项目 | 中大型 |

---

## 三层架构详解

在 Flutter 实践中，Clean Architecture 通常简化为**三层架构**：

```
┌─────────────────────────────────────────────────────┐
│                    Flutter 三层架构                   │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │         Presentation Layer（表示层）            │  │
│  │  ┌─────────┐  ┌────────────┐  ┌───────────┐  │  │
│  │  │  Pages  │  │  Widgets   │  │ ViewModel │  │  │
│  │  │  页面    │  │  组件      │  │ 视图模型   │  │  │
│  │  └─────────┘  └────────────┘  └───────────┘  │  │
│  └──────────────────────┬────────────────────────┘  │
│                         │ 依赖                       │
│                         ▼                           │
│  ┌───────────────────────────────────────────────┐  │
│  │           Domain Layer（领域层）                │  │
│  │  ┌──────────┐  ┌───────────┐  ┌───────────┐  │  │
│  │  │ Entities │  │ Use Cases │  │ Repo 接口  │  │  │
│  │  │  实体     │  │  用例      │  │ 仓库接口   │  │  │
│  │  └──────────┘  └───────────┘  └───────────┘  │  │
│  └──────────────────────┬────────────────────────┘  │
│                         │ 依赖                       │
│                         ▼                           │
│  ┌───────────────────────────────────────────────┐  │
│  │            Data Layer（数据层）                 │  │
│  │  ┌──────────┐  ┌───────────┐  ┌───────────┐  │  │
│  │  │  Models  │  │ Data Src  │  │ Repo 实现  │  │  │
│  │  │  数据模型 │  │  数据源    │  │ 仓库实现   │  │  │
│  │  └──────────┘  └───────────┘  └───────────┘  │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Presentation Layer（表示层）

**职责**：处理 UI 展示和用户交互

- **Pages/Screens**：页面级 Widget
- **Widgets**：可复用的 UI 组件
- **ViewModel/BLoC**：管理页面状态

**关键原则**：不包含任何业务逻辑，仅负责：
- 接收用户输入
- 调用 Use Case
- 根据状态渲染 UI

### Domain Layer（领域层）

**职责**：包含核心业务逻辑，是架构的**最内层**

- **Entities**：业务实体，纯数据类
- **Use Cases**：具体的业务操作（如"获取用户列表"）
- **Repository 接口**：定义数据操作的抽象接口

**关键原则**：
- 纯 Dart 代码，不依赖任何框架
- 不依赖外层（Data Layer、Presentation Layer）
- 通过**依赖倒置**让外层依赖内层的接口

### Data Layer（数据层）

**职责**：处理数据的获取和持久化

- **Models**：数据传输模型（含序列化逻辑）
- **Data Sources**：远程 API、本地数据库等
- **Repository 实现**：实现 Domain 层定义的接口

---

## Use Case 的概念和作用

### 什么是 Use Case？

Use Case（用例）代表一个**具体的业务操作**，是 Domain Layer 的核心组件。

每个 Use Case 遵循**单一职责原则**，只做一件事：

```dart
// 获取用户列表的用例
class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getUsers();
  }
}

// 创建用户的用例
class CreateUserUseCase {
  final UserRepository repository;

  CreateUserUseCase(this.repository);

  Future<void> call(UserEntity user) async {
    // 可以在这里添加业务验证逻辑
    if (user.name.isEmpty) {
      throw Exception('用户名不能为空');
    }
    await repository.createUser(user);
  }
}
```

### Use Case 的作用

1. **封装业务逻辑**：将业务规则集中在一个地方
2. **解耦层级**：Presentation 层不直接调用 Repository
3. **便于测试**：每个 Use Case 可以独立测试
4. **可组合**：复杂操作可以组合多个 Use Case

---

## Entity vs Model vs DTO

这三个概念经常被混淆，以下是它们的详细对比：

### 对比表格

| 对比维度 | Entity（实体） | Model（模型） | DTO（数据传输对象） |
|---------|---------------|--------------|-------------------|
| **所在层级** | Domain Layer | Data Layer | Data Layer / API 边界 |
| **核心职责** | 表示业务概念 | 数据持久化/序列化 | 跨层/跨系统数据传输 |
| **是否含业务逻辑** | ✅ 可以包含 | ❌ 通常不含 | ❌ 绝不含 |
| **序列化方法** | ❌ 无 | ✅ fromJson/toJson | ✅ fromJson/toJson |
| **依赖方向** | 不依赖外层 | 可依赖 Entity | 仅用于传输 |
| **生命周期** | 长期稳定 | 随存储格式变化 | 随 API 接口变化 |
| **例子** | `UserEntity` | `UserModel` | `UserDTO` |

### 代码示例

```dart
// ═══════════════════════════════════════
// Entity - 领域层，纯业务概念
// ═══════════════════════════════════════
class UserEntity {
  final int id;
  final String name;
  final String email;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
  });

  // Entity 可以包含业务逻辑
  bool get isValidEmail => email.contains('@');
}

// ═══════════════════════════════════════
// Model - 数据层，用于持久化
// ═══════════════════════════════════════
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  // 从 JSON 构造（反序列化）
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  // 转为 JSON（序列化）
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

// ═══════════════════════════════════════
// DTO - 数据传输对象，用于 API 通信
// ═══════════════════════════════════════
class UserDTO {
  final String userName;   // API 字段名可能不同
  final String userEmail;

  UserDTO({required this.userName, required this.userEmail});

  factory UserDTO.fromApiResponse(Map<String, dynamic> json) {
    return UserDTO(
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
    );
  }

  // 转换为 Entity
  UserEntity toEntity(int id) {
    return UserEntity(id: id, name: userName, email: userEmail);
  }
}
```

---

## Flutter 中实现 Clean Architecture 示例

完整的项目目录结构推荐如下：

```
lib/
├── main.dart
├── core/                          # 公共工具
│   ├── error/                     # 错误处理
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── usecases/                  # Use Case 基类
│       └── usecase.dart
├── features/                      # 按功能模块组织
│   └── user/
│       ├── domain/                # 领域层
│       │   ├── entities/
│       │   │   └── user_entity.dart
│       │   ├── repositories/
│       │   │   └── user_repository.dart
│       │   └── usecases/
│       │       ├── get_users.dart
│       │       └── create_user.dart
│       ├── data/                  # 数据层
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   ├── datasources/
│       │   │   ├── user_remote_datasource.dart
│       │   │   └── user_local_datasource.dart
│       │   └── repositories/
│       │       └── user_repository_impl.dart
│       └── presentation/         # 表示层
│           ├── pages/
│           │   └── user_list_page.dart
│           ├── widgets/
│           │   └── user_card.dart
│           └── viewmodels/
│               └── user_viewmodel.dart
└── injection_container.dart       # 依赖注入
```

> 💡 **提示**：完整的可运行示例请参考 `lib/ch02_architecture_patterns.dart` 文件。

---

## 最佳实践

### 1. 遵循依赖规则

```
Presentation ──依赖──▶ Domain ◀──依赖── Data
                        ▲
                    （核心层）
```

**永远不要让内层依赖外层**。Domain 层不应该 import 任何 Flutter 或第三方包。

### 2. 使用依赖注入

```dart
// ✅ 好的做法：通过构造函数注入依赖
class GetUsersUseCase {
  final UserRepository repository; // 依赖接口而非实现
  GetUsersUseCase(this.repository);
}

// ❌ 不好的做法：直接创建具体实现
class GetUsersUseCase {
  final repository = UserRepositoryImpl(); // 直接依赖实现
}
```

### 3. 保持 Use Case 单一职责

```dart
// ✅ 好的做法：每个 Use Case 只做一件事
class GetUsersUseCase { ... }
class CreateUserUseCase { ... }
class DeleteUserUseCase { ... }

// ❌ 不好的做法：一个 Use Case 做多件事
class UserUseCase {
  void getUsers() { ... }
  void createUser() { ... }
  void deleteUser() { ... }
}
```

### 4. Entity 保持纯粹

- Entity 是纯 Dart 类，不依赖任何框架
- Entity 可以包含业务验证逻辑
- Entity 不应有序列化/反序列化方法

### 5. 错误处理策略

推荐使用 `Either` 模式（来自 `dartz` 或 `fpdart` 包）处理错误：

```dart
// 定义失败类型
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Use Case 返回 Either 类型
// Left = 失败, Right = 成功
Future<Either<Failure, List<UserEntity>>> call() async {
  try {
    final users = await repository.getUsers();
    return Right(users);
  } catch (e) {
    return Left(ServerFailure('服务器错误：$e'));
  }
}
```

### 6. 命名规范

| 类型 | 命名规范 | 示例 |
|------|---------|------|
| Entity | `XxxEntity` | `UserEntity` |
| Model | `XxxModel` | `UserModel` |
| DTO | `XxxDTO` | `UserDTO` |
| Repository 接口 | `XxxRepository` | `UserRepository` |
| Repository 实现 | `XxxRepositoryImpl` | `UserRepositoryImpl` |
| Use Case | `动词+名词+UseCase` | `GetUsersUseCase` |
| ViewModel | `XxxViewModel` | `UserViewModel` |

### 7. 渐进式采用

不必一开始就使用完整的 Clean Architecture。建议：

1. **小项目**：从简单的 MVVM 开始
2. **中型项目**：引入 Repository 模式
3. **大型项目**：完整的 Clean Architecture + 依赖注入

---

## 总结

| 要点 | 说明 |
|------|------|
| 架构不是教条 | 根据项目规模和团队能力选择合适的架构 |
| 核心是解耦 | 所有架构模式的终极目标都是降低耦合 |
| 依赖方向 | 永远从外层指向内层 |
| 可测试性 | 好的架构让每一层都可以独立测试 |
| 渐进式演进 | 项目初期可以简单，随着复杂度增长再重构 |

> 📖 **下一章预告**：第三章将深入探讨 Flutter 中的状态管理方案（Provider、Riverpod、BLoC 等）。

---

*本文档为 Flutter 架构教程系列的第二章，完整代码示例请参考 `lib/ch02_architecture_patterns.dart`。*
