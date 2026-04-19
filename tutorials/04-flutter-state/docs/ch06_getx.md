# 第6章：GetX 状态管理

## 目录

1. [GetX 概述](#1-getx-概述)
2. [响应式状态管理：.obs 和 Obx](#2-响应式状态管理obs-和-obx)
3. [简单状态管理：GetBuilder](#3-简单状态管理getbuilder)
4. [GetxController 生命周期](#4-getxcontroller-生命周期)
5. [依赖注入](#5-依赖注入)
6. [路由管理](#6-路由管理)
7. [GetX 的争议与适用场景](#7-getx-的争议与适用场景)
8. [实战：计数器 + 购物车](#8-实战计数器--购物车)
9. [最佳实践](#9-最佳实践)

---

## 1. GetX 概述

### 什么是 GetX？

GetX 是一个 Flutter 的超轻量级框架，集成了三大核心功能：

| 功能 | 说明 | 对标 |
|------|------|------|
| **状态管理** | 响应式和简单状态管理 | Provider / BLoC |
| **路由管理** | 无需 context 的导航 | Navigator 2.0 |
| **依赖注入** | 智能的实例管理 | get_it |

### 核心特点

- **极简 API**：代码量少，上手快
- **无需 context**：不依赖 BuildContext，可以在任何地方调用
- **高性能**：只更新需要更新的 Widget
- **全功能**：一个包解决多个问题

### 安装

```yaml
dependencies:
  get: ^4.0.0
```

### 初始化

```dart
// 将 MaterialApp 替换为 GetMaterialApp
import 'package:get/get.dart';

void main() {
  runApp(GetMaterialApp(
    home: HomePage(),
  ));
}
```

---

## 2. 响应式状态管理：.obs 和 Obx

### 核心概念

GetX 的响应式状态管理通过 `.obs` 后缀将普通变量转为可观察对象（Observable），
使用 `Obx` Widget 自动监听变化并更新 UI。

### 基本用法

```dart
class CounterController extends GetxController {
  // 使用 .obs 创建响应式变量
  var count = 0.obs;              // RxInt
  var name = ''.obs;              // RxString
  var isLoading = false.obs;      // RxBool
  var items = <String>[].obs;     // RxList
  var user = User().obs;          // Rx<User>
  var price = 0.0.obs;            // RxDouble

  void increment() {
    count.value++;  // 注意：基本类型需要 .value
  }

  void addItem(String item) {
    items.add(item);  // List 直接操作即可
  }

  void updateName(String newName) {
    name.value = newName;
  }
}
```

### 在 UI 中使用 Obx

```dart
class CounterPage extends StatelessWidget {
  // 通过 Get.put 注入控制器
  final controller = Get.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Obx 自动监听内部使用的 .obs 变量
        Obx(() => Text('计数: ${controller.count}')),

        // 条件渲染也是响应式的
        Obx(() => controller.isLoading.value
            ? CircularProgressIndicator()
            : Text('加载完成')),

        // 列表也能响应式更新
        Obx(() => Column(
          children: controller.items
              .map((item) => Text(item))
              .toList(),
        )),

        ElevatedButton(
          onPressed: controller.increment,
          child: Text('增加'),
        ),
      ],
    );
  }
}
```

### .obs 的类型系统

```dart
// 基本类型
final count = 0.obs;           // RxInt
final name = 'hello'.obs;      // RxString
final flag = true.obs;         // RxBool
final price = 9.99.obs;        // RxDouble

// 集合类型
final list = <int>[].obs;      // RxList<int>
final map = <String, int>{}.obs; // RxMap<String, int>
final set = <int>{}.obs;       // RxSet<int>

// 自定义对象
final user = Rx<User?>(null);  // Rx<User?>（可空）
final user2 = User().obs;      // Rx<User>（非空）

// 访问值
print(count.value);  // 基本类型用 .value
print(list.length);  // 集合可直接使用
```

---

## 3. 简单状态管理：GetBuilder

### 什么是 GetBuilder？

`GetBuilder` 是 GetX 的简单状态管理方案，不使用 `.obs`，而是手动调用 `update()` 触发更新。
类似于 `setState` 但跨组件生效。

### 使用方式

```dart
class SimpleController extends GetxController {
  int count = 0;  // 普通变量，不用 .obs

  void increment() {
    count++;
    update();  // 手动通知 UI 更新
  }

  // 可以指定只更新特定 ID 的 GetBuilder
  void incrementSpecific() {
    count++;
    update(['counter_text']);  // 只更新 id 为 'counter_text' 的组件
  }
}

// UI 中使用
GetBuilder<SimpleController>(
  init: SimpleController(),  // 如果还没注入，可以在这里初始化
  id: 'counter_text',        // 可选 ID
  builder: (controller) {
    return Text('计数: ${controller.count}');
  },
)
```

### Obx vs GetBuilder 对比

| 特性 | Obx（响应式） | GetBuilder（简单） |
|------|------------|----------------|
| 变量声明 | `.obs` | 普通变量 |
| 更新方式 | 自动（改值即更新） | 手动（`update()`） |
| 内存占用 | 较高（每个变量一个 Stream） | 较低 |
| 适用场景 | 频繁变化的数据 | 不常变化的数据 |

---

## 4. GetxController 生命周期

### 生命周期方法

```dart
class MyController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // 控制器初始化时调用（类似 initState）
    // 适合：初始化数据、设置监听器
    print('控制器已初始化');
  }

  @override
  void onReady() {
    super.onReady();
    // 在 onInit 之后的下一帧调用
    // 适合：需要 context 的操作、弹窗、网络请求
    print('控制器已就绪');
  }

  @override
  void onClose() {
    super.onClose();
    // 控制器被销毁前调用（类似 dispose）
    // 适合：释放资源、取消订阅
    print('控制器已销毁');
  }
}
```

### Workers（响应式监听器）

GetX 提供了强大的响应式监听工具：

```dart
class MyController extends GetxController {
  var count = 0.obs;

  @override
  void onInit() {
    super.onInit();

    // ever：每次值变化时调用
    ever(count, (value) {
      print('count 变为: $value');
    });

    // once：只在第一次变化时调用
    once(count, (value) {
      print('count 第一次变化: $value');
    });

    // debounce：防抖（停止变化后 1 秒执行）
    debounce(count, (value) {
      print('搜索: $value');
    }, time: Duration(seconds: 1));

    // interval：节流（每 1 秒最多执行一次）
    interval(count, (value) {
      print('节流输出: $value');
    }, time: Duration(seconds: 1));
  }
}
```

---

## 5. 依赖注入

### Get.put — 立即注入

```dart
// 立即创建实例并注入
final controller = Get.put(MyController());

// 可以配置参数
Get.put(MyController(),
  permanent: true,   // 永不销毁
  tag: 'unique_tag', // 标签区分同类型的不同实例
);
```

### Get.lazyPut — 懒加载注入

```dart
// 只在第一次使用时才创建实例
Get.lazyPut(() => MyController());

// fenix 参数：被销毁后再次使用时会重新创建
Get.lazyPut(() => MyController(), fenix: true);
```

### Get.find — 查找已注入的实例

```dart
// 在任何地方获取已注入的实例
final controller = Get.find<MyController>();

// 带标签查找
final controller = Get.find<MyController>(tag: 'unique_tag');
```

### Get.delete — 删除实例

```dart
// 删除实例
Get.delete<MyController>();

// 强制删除（即使 permanent 为 true）
Get.delete<MyController>(force: true);
```

### 依赖注入完整流程

```dart
// 1. 在初始化时注入
void main() {
  // 注入全局服务
  Get.put(ApiService());
  Get.lazyPut(() => AuthController());

  runApp(GetMaterialApp(home: HomePage()));
}

// 2. 在任意位置使用
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 获取已注入的实例
    final api = Get.find<ApiService>();
    final auth = Get.find<AuthController>();

    return Text('已登录: ${auth.isLoggedIn}');
  }
}
```

---

## 6. 路由管理

### 基本导航（无需 context）

```dart
// 跳转到新页面
Get.to(() => DetailPage());

// 跳转并清除当前页面（替换）
Get.off(() => LoginPage());

// 清除所有页面并跳转
Get.offAll(() => HomePage());

// 返回上一页
Get.back();

// 带参数跳转
Get.to(() => DetailPage(), arguments: {'id': 123});
// 获取参数
final id = Get.arguments['id'];
```

### 命名路由

```dart
GetMaterialApp(
  initialRoute: '/home',
  getPages: [
    GetPage(name: '/home', page: () => HomePage()),
    GetPage(name: '/detail/:id', page: () => DetailPage()),
    GetPage(
      name: '/profile',
      page: () => ProfilePage(),
      binding: ProfileBinding(),  // 绑定依赖
    ),
  ],
)

// 使用命名路由
Get.toNamed('/detail/42');
// 获取路由参数
final id = Get.parameters['id'];
```

---

## 7. GetX 的争议与适用场景

### 争议点

| 争议 | 说明 |
|------|------|
| **过度封装** | 隐藏了 Flutter 原有机制，可能导致对底层理解不足 |
| **全局状态** | 大量使用全局注入可能导致状态管理混乱 |
| **维护风险** | 社区维护力度不确定，依赖单一开发者 |
| **测试困难** | 全局状态和隐式依赖增加了测试复杂度 |
| **魔法操作多** | 隐藏了很多实现细节，出问题时难以调试 |

### 适用场景

| 场景 | 推荐度 |
|------|--------|
| 快速原型开发 | ⭐⭐⭐⭐⭐ |
| 小型项目 | ⭐⭐⭐⭐ |
| 个人项目 | ⭐⭐⭐⭐ |
| 中型团队项目 | ⭐⭐⭐ |
| 大型企业项目 | ⭐⭐ |
| 学习 Flutter 阶段 | ⭐⭐（建议先学原生再学框架） |

### 与其他方案对比

| 特性 | GetX | Provider | BLoC | Riverpod |
|------|------|----------|------|----------|
| 学习成本 | 低 | 低 | 高 | 中 |
| 代码量 | 少 | 中 | 多 | 中 |
| 可测试性 | 一般 | 好 | 优秀 | 优秀 |
| 社区支持 | 活跃 | 官方 | 强大 | 成长中 |
| 功能范围 | 全能 | 状态管理 | 状态管理 | 状态管理 |

---

## 8. 实战：计数器 + 购物车

完整代码见 `lib/ch06_getx.dart`，实现了以下功能：

### 计数器模块
- 使用 `.obs` 和 `Obx` 实现响应式计数器
- 支持增加、减少、重置操作
- 演示 Worker（ever）监听计数变化

### 购物车模块
- 使用 `GetxController` 管理购物车状态
- 商品列表支持添加到购物车
- 购物车支持删除商品和修改数量
- 总价实时计算

### 整体架构
- 使用 `GetMaterialApp` 替代 `MaterialApp`
- 通过 `Get.put` 注入控制器
- Tab 切换展示两个模块

---

## 9. 最佳实践

### 9.1 控制器组织

```dart
// ✅ 一个功能模块一个控制器
class CartController extends GetxController { ... }
class AuthController extends GetxController { ... }

// ❌ 避免一个控制器管理太多状态
class EverythingController extends GetxController { ... }
```

### 9.2 适度使用响应式

```dart
// ✅ 频繁变化的用 .obs
var searchText = ''.obs;  // 输入框文字频繁变化

// ✅ 不常变化的用 GetBuilder
int selectedIndex = 0;  // 很少切换的选项
void select(int index) {
  selectedIndex = index;
  update();
}
```

### 9.3 避免全局滥用

```dart
// ✅ 局部使用 Get.put
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocalController());  // 页面级别
    return ...;
  }
}

// ❌ 避免在 main 里注入太多全局控制器
void main() {
  Get.put(Controller1());
  Get.put(Controller2());
  Get.put(Controller3());  // 太多全局状态
  ...
}
```

### 9.4 内存管理

```dart
// GetX 默认会在 Widget 销毁时自动回收控制器
// 如果需要持久化某个控制器
Get.put(AuthController(), permanent: true);

// 手动清理
@override
void onClose() {
  timer?.cancel();
  subscription?.cancel();
  super.onClose();
}
```

---

## 参考资源

- [GetX 官方文档](https://pub.dev/packages/get)
- [GetX GitHub](https://github.com/jonataslaw/getx)
- [GetX 模式指南](https://github.com/kauemurakami/getx_pattern)
