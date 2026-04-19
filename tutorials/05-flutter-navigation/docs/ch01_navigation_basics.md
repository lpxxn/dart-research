# 第1章：导航基础

## 目录

1. [Navigator 的概念](#1-navigator-的概念)
2. [Navigator.push 和 Navigator.pop](#2-navigatorpush-和-navigatorpop)
3. [MaterialPageRoute 与 CupertinoPageRoute](#3-materialpageroute-与-cupertinopageroute)
4. [页面间传参](#4-页面间传参)
5. [PopScope 拦截返回](#5-popscope-拦截返回)
6. [完整示例说明](#6-完整示例说明)
7. [最佳实践](#7-最佳实践)

---

## 1. Navigator 的概念

### 路由栈（Route Stack）

Flutter 中的导航系统基于 **栈（Stack）** 数据结构。`Navigator` 是一个管理路由栈的 Widget，它维护着一组 `Route` 对象的有序列表。

```
┌─────────────┐
│  详情页 (top)│  ← 当前可见
├─────────────┤
│   首页      │  ← 被遮挡
└─────────────┘
```

**核心概念：**

- **Route**：一个抽象概念，表示应用中的一个"屏幕"或"页面"。
- **Navigator**：管理 Route 的 Widget，提供 `push`、`pop` 等方法来操作路由栈。
- **push**：将新的 Route 压入栈顶（进入新页面）。
- **pop**：将栈顶的 Route 弹出（返回上一页面）。

### Navigator 的工作原理

每个 `MaterialApp`（或 `CupertinoApp`）内部都自带一个 `Navigator`。当你调用 `Navigator.push()` 时，新页面被压入栈顶；调用 `Navigator.pop()` 时，当前页面从栈顶弹出，露出下面的页面。

```dart
// 获取最近的 Navigator
Navigator.of(context)

// 等价的静态方法
Navigator.push(context, route)
Navigator.pop(context)
```

---

## 2. Navigator.push 和 Navigator.pop

### push — 跳转到新页面

```dart
// 基本用法
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailPage(),
  ),
);

// 等价写法
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const DetailPage()),
);
```

### pop — 返回上一页面

```dart
// 基本返回
Navigator.pop(context);

// 带返回值的 pop
Navigator.pop(context, '这是返回的数据');
```

### push 的返回值

`Navigator.push()` 返回一个 `Future`，当被 push 的页面 pop 时，这个 Future 完成，并携带 pop 传递的值：

```dart
// 在首页等待详情页返回
final result = await Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (context) => const DetailPage()),
);
// result 就是详情页 pop 时传递的值
print('收到返回值: $result');
```

---

## 3. MaterialPageRoute 与 CupertinoPageRoute

### MaterialPageRoute

`MaterialPageRoute` 是 Android 风格的页面过渡动画——新页面从底部滑入：

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailPage(),
    // 可选：设置路由名称，方便调试
    settings: const RouteSettings(name: '/detail'),
  ),
);
```

**构造参数说明：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `builder` | `WidgetBuilder` | 构建页面 Widget 的函数 |
| `settings` | `RouteSettings?` | 路由配置（名称、参数等） |
| `maintainState` | `bool` | 是否在不可见时保持状态（默认 `true`） |
| `fullscreenDialog` | `bool` | 是否以全屏对话框形式展示（默认 `false`） |

### CupertinoPageRoute

`CupertinoPageRoute` 是 iOS 风格的页面过渡动画——新页面从右侧滑入，同时上一页面轻微向左移动：

```dart
import 'package:flutter/cupertino.dart';

Navigator.push(
  context,
  CupertinoPageRoute(
    builder: (context) => const DetailPage(),
  ),
);
```

### fullscreenDialog 模式

当 `fullscreenDialog: true` 时，页面以全屏对话框的形式从底部弹出，AppBar 左侧显示"关闭"按钮而不是返回箭头：

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EditPage(),
    fullscreenDialog: true, // 全屏对话框模式
  ),
);
```

---

## 4. 页面间传参

### 方式一：通过构造函数传参（推荐）

最直接、类型安全的方式——直接通过目标页面的构造函数传递数据：

```dart
// 定义详情页，接收参数
class DetailPage extends StatelessWidget {
  final String itemTitle;
  final int itemId;

  const DetailPage({
    super.key,
    required this.itemTitle,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(itemTitle)),
      body: Center(child: Text('Item ID: $itemId')),
    );
  }
}

// 跳转时传参
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailPage(
      itemTitle: 'Flutter 导航',
      itemId: 42,
    ),
  ),
);
```

### 方式二：通过 Navigator.pop 返回值

被推入的页面在 pop 时可以携带数据返回给上一页面：

```dart
// 详情页 — 返回数据
ElevatedButton(
  onPressed: () {
    Navigator.pop(context, '用户选择了选项 A');
  },
  child: const Text('选择选项 A'),
)

// 首页 — 接收返回数据
void _navigateToDetail() async {
  final result = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (context) => const DetailPage()),
  );
  if (result != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('收到: $result')),
    );
  }
}
```

### 方式三：通过 RouteSettings.arguments

适用于命名路由场景（下一章详细介绍）：

```dart
// 传递
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailPage(),
    settings: const RouteSettings(arguments: {'id': 42}),
  ),
);

// 接收
final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
```

---

## 5. PopScope 拦截返回

### 为什么需要拦截返回？

某些场景下需要在用户按下返回键时进行确认，比如：

- 表单页面有未保存的数据
- 购物流程中防止误操作返回
- 需要在返回前执行清理操作

### PopScope（Flutter 3.16+）

> ⚠️ `WillPopScope` 已在 Flutter 3.16 中被弃用，请使用 `PopScope` 替代。

```dart
PopScope(
  // canPop: false 表示不允许直接返回
  canPop: false,
  // 当用户尝试返回时触发
  onPopInvokedWithResult: (bool didPop, dynamic result) {
    if (didPop) return; // 如果已经 pop 了，不再处理
    // 显示确认对话框
    _showExitConfirmDialog(context);
  },
  child: Scaffold(
    appBar: AppBar(title: const Text('编辑页面')),
    body: const Center(child: Text('有未保存的内容')),
  ),
)
```

**PopScope 参数说明：**

| 参数 | 类型 | 说明 |
|------|------|------|
| `canPop` | `bool` | `true` 允许正常返回；`false` 拦截返回操作 |
| `onPopInvokedWithResult` | `Function?` | 用户尝试返回时的回调 |
| `child` | `Widget` | 子 Widget |

### 动态控制是否允许返回

```dart
class EditPage extends StatefulWidget {
  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges, // 有未保存内容时拦截返回
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmDialog();
      },
      child: Scaffold(/* ... */),
    );
  }
}
```

---

## 6. 完整示例说明

示例代码位于 `lib/ch01_navigation_basics.dart`，实现了以下功能：

1. **首页（HomePage）**：显示商品列表，点击可跳转到详情页
2. **详情页（DetailPage）**：接收商品信息，显示详情，可选择评分后返回
3. **编辑页（EditPage）**：演示 `PopScope` 拦截返回功能

### 运行示例

```bash
cd flutter-navigation
flutter run -t lib/ch01_navigation_basics.dart
```

### 操作流程

1. 启动后看到商品列表首页
2. 点击任意商品 → 跳转到详情页（通过构造函数传参）
3. 在详情页选择评分 → 点击"提交评分并返回" → 返回首页并显示评分结果
4. 点击首页的编辑按钮 → 进入编辑页
5. 在编辑页输入内容后按返回键 → 弹出确认对话框（PopScope 拦截）

---

## 7. 最佳实践

### ✅ 推荐做法

1. **优先使用构造函数传参**：类型安全，编译期检查，IDE 自动补全。
2. **使用 `async/await` 接收返回值**：代码清晰，避免回调嵌套。
3. **检查 `mounted`**：在异步操作后使用 `context` 前检查 Widget 是否还在树中。
4. **使用 `PopScope` 而非 `WillPopScope`**：后者已被弃用。

### ❌ 避免的做法

1. **不要滥用全局变量传参**：难以维护和追踪数据流。
2. **不要忽略返回值的 null 检查**：用户可能直接按返回键而不是通过按钮返回。
3. **不要在 `PopScope.onPopInvokedWithResult` 中再次调用 `Navigator.pop`（当 `didPop` 为 true 时）**：会导致重复 pop。

### 性能提示

- 设置 `maintainState: false` 可以在页面不可见时释放资源，但会丢失页面状态。
- 大量数据传递建议使用状态管理方案（如 Provider、Riverpod），而不是通过导航参数传递。

---

## 延伸阅读

- [Flutter 官方文档 - Navigation](https://docs.flutter.dev/ui/navigation)
- [Navigator class API](https://api.flutter.dev/flutter/widgets/Navigator-class.html)
- [PopScope class API](https://api.flutter.dev/flutter/widgets/PopScope-class.html)
