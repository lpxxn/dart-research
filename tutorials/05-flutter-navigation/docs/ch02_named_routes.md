# 第2章：命名路由

## 目录

1. [什么是命名路由](#1-什么是命名路由)
2. [MaterialApp 的 routes 表](#2-materialapp-的-routes-表)
3. [命名路由导航方法](#3-命名路由导航方法)
4. [onGenerateRoute — 动态路由生成](#4-ongenerateroute--动态路由生成)
5. [onUnknownRoute — 404 页面](#5-onunknownroute--404-页面)
6. [路由参数传递](#6-路由参数传递)
7. [完整示例说明](#7-完整示例说明)
8. [最佳实践](#8-最佳实践)

---

## 1. 什么是命名路由

在第1章中，我们使用 `MaterialPageRoute` 直接指定要跳转的 Widget。这种方式称为**匿名路由**。当应用页面增多后，散落在各处的路由代码难以维护。

**命名路由（Named Routes）** 通过给每个路由分配一个字符串名称（如 `'/home'`、`'/detail'`），将路由配置集中管理，类似于 Web 开发中的 URL 路由：

```
匿名路由：Navigator.push(context, MaterialPageRoute(builder: ...))
命名路由：Navigator.pushNamed(context, '/detail')
```

**优势：**
- 路由集中管理，便于维护
- 路由名称语义化，代码可读性更好
- 方便实现 Deep Link
- 便于路由拦截和权限控制

**局限：**
- 传参不够类型安全（依赖 `arguments`）
- 不支持复杂的路由匹配（如正则、路径参数）
- Flutter 官方推荐在大型项目中使用声明式路由（如 GoRouter）

---

## 2. MaterialApp 的 routes 表

### 基本配置

在 `MaterialApp` 中通过 `routes` 参数定义路由映射表：

```dart
MaterialApp(
  // 初始路由
  initialRoute: '/',

  // 路由映射表
  routes: {
    '/': (context) => const HomePage(),
    '/detail': (context) => const DetailPage(),
    '/settings': (context) => const SettingsPage(),
    '/profile': (context) => const ProfilePage(),
  },
)
```

> ⚠️ 使用 `initialRoute` 时不要同时设置 `home` 参数，否则 `home` 会覆盖 `initialRoute`。

### routes 表的局限

`routes` 表是一个简单的 `Map<String, WidgetBuilder>`，有以下限制：

1. **不支持路径参数**：无法定义 `/user/:id` 这样的动态路由
2. **不支持查询参数**：无法解析 `/search?q=flutter`
3. **无法动态生成路由**：所有路由必须预先注册

这些限制可以通过 `onGenerateRoute` 解决。

---

## 3. 命名路由导航方法

### pushNamed — 跳转到命名路由

```dart
// 基本跳转
Navigator.pushNamed(context, '/detail');

// 带参数跳转
Navigator.pushNamed(
  context,
  '/detail',
  arguments: {'id': 42, 'title': 'Flutter 导航'},
);

// 等待返回值
final result = await Navigator.pushNamed<String>(context, '/detail');
```

### pushReplacementNamed — 替换当前路由

将当前路由从栈中移除，并 push 新路由。常用于：
- 登录成功后跳转到首页（不允许返回登录页）
- 闪屏页跳转到主页

```dart
// 登录成功后替换为首页
Navigator.pushReplacementNamed(context, '/home');
```

```
跳转前：[splash, login]
跳转后：[splash, home]  ← login 被替换为 home
```

### pushNamedAndRemoveUntil — 跳转并清除路由栈

跳转到新路由，并移除栈中的路由直到满足条件。常用于：
- 登出后回到登录页（清空所有路由）
- 从深层页面直接回到首页

```dart
// 跳转到首页，并清除所有之前的路由
Navigator.pushNamedAndRemoveUntil(
  context,
  '/home',
  (route) => false, // 移除所有路由
);

// 跳转到首页，保留首页之前的路由
Navigator.pushNamedAndRemoveUntil(
  context,
  '/home',
  ModalRoute.withName('/'), // 保留到 '/' 为止
);
```

```
跳转前：[home, category, product, cart, checkout]
pushNamedAndRemoveUntil('/home', (route) => false)
跳转后：[home]  ← 之前所有路由全部清除
```

### popAndPushNamed — 弹出当前路由并 push 新路由

先 pop 当前路由，再 push 新路由。与 `pushReplacementNamed` 类似，但动画效果不同：

```dart
Navigator.popAndPushNamed(context, '/new-page');
```

---

## 4. onGenerateRoute — 动态路由生成

### 基本用法

当 `routes` 表中找不到匹配的路由时，Flutter 会调用 `onGenerateRoute`。这允许你动态生成路由，解析路径参数等：

```dart
MaterialApp(
  initialRoute: '/',
  routes: {
    '/': (context) => const HomePage(),
  },
  onGenerateRoute: (RouteSettings settings) {
    // settings.name 是路由名称，如 '/user/42'
    // settings.arguments 是传递的参数

    // 解析路径参数
    final uri = Uri.parse(settings.name ?? '');

    // 匹配 /user/:id
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'user') {
      final userId = int.tryParse(uri.pathSegments[1]);
      if (userId != null) {
        return MaterialPageRoute(
          builder: (context) => UserPage(userId: userId),
          settings: settings,
        );
      }
    }

    // 匹配 /search?q=xxx
    if (uri.path == '/search') {
      final query = uri.queryParameters['q'] ?? '';
      return MaterialPageRoute(
        builder: (context) => SearchPage(query: query),
        settings: settings,
      );
    }

    // 未匹配返回 null，会调用 onUnknownRoute
    return null;
  },
)
```

### RouteSettings 详解

```dart
class RouteSettings {
  final String? name;       // 路由名称
  final Object? arguments;  // 路由参数（任意类型）
}
```

**使用场景：**
- `name`：用于路由匹配和日志记录
- `arguments`：传递复杂数据对象

---

## 5. onUnknownRoute — 404 页面

当 `routes` 表和 `onGenerateRoute` 都无法处理某个路由时，`onUnknownRoute` 会被调用。通常用来展示 404 页面：

```dart
MaterialApp(
  // ...其他配置
  onUnknownRoute: (RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('页面未找到')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '404 - 页面 "${settings.name}" 不存在',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false,
                ),
                child: const Text('回到首页'),
              ),
            ],
          ),
        ),
      ),
    );
  },
)
```

---

## 6. 路由参数传递

### 传参方式

```dart
// 通过 arguments 传递参数
Navigator.pushNamed(
  context,
  '/detail',
  arguments: ProductInfo(id: 42, name: 'Flutter 入门'),
);
```

### 接收参数

```dart
class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 方式1：通过 ModalRoute.of 获取
    final args = ModalRoute.of(context)?.settings.arguments;

    // 方式2：在 onGenerateRoute 中解析后通过构造函数传递（推荐）
    // 这种方式类型安全

    return Scaffold(/* ... */);
  }
}
```

### 推荐模式：在 onGenerateRoute 中转换参数

```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/detail':
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => DetailPage(
          id: args['id'] as int,
          title: args['title'] as String,
        ),
      );
    default:
      return null;
  }
},
```

这种方式将"路由参数 → 页面构造函数"的映射集中在 `onGenerateRoute` 中，页面本身不需要知道参数是如何传递的。

---

## 7. 完整示例说明

示例代码位于 `lib/ch02_named_routes.dart`，实现了以下功能：

### 页面结构

1. **首页（HomePage）**：导航入口，提供多个跳转按钮
2. **详情页（DetailPage）**：通过 arguments 接收参数
3. **用户页（UserProfilePage）**：通过 `onGenerateRoute` 解析路径参数 `/user/:id`
4. **设置页（SettingsPage）**：演示 `pushReplacementNamed`
5. **404 页面**：处理未知路由

### 运行示例

```bash
cd flutter-navigation
flutter run -t lib/ch02_named_routes.dart
```

### 操作流程

1. 启动后看到首页，包含多个导航按钮
2. 点击"查看商品详情" → 通过 `pushNamed` + arguments 传参
3. 点击"查看用户主页" → 通过 `onGenerateRoute` 解析 `/user/42`
4. 点击"访问不存在页面" → 触发 `onUnknownRoute` 显示 404
5. 从设置页点击"退出登录" → 使用 `pushNamedAndRemoveUntil` 清空路由栈

---

## 8. 最佳实践

### ✅ 推荐做法

1. **路由名称使用常量定义**：避免拼写错误
   ```dart
   class AppRoutes {
     static const home = '/';
     static const detail = '/detail';
     static const profile = '/profile';
   }
   ```

2. **使用 onGenerateRoute 统一管理路由**：比 routes 表更灵活
   ```dart
   // 将路由逻辑集中在一个文件中
   // lib/router.dart
   Route<dynamic>? onGenerateRoute(RouteSettings settings) {
     switch (settings.name) {
       case AppRoutes.home:
         return MaterialPageRoute(builder: (_) => const HomePage());
       // ...
     }
   }
   ```

3. **为参数定义类型安全的数据类**：
   ```dart
   class DetailArgs {
     final int id;
     final String title;
     const DetailArgs({required this.id, required this.title});
   }
   ```

### ❌ 避免的做法

1. **不要在 routes 和 onGenerateRoute 中重复注册同一路由**：routes 优先级更高。
2. **不要忘记处理 arguments 为 null 的情况**：用户可能通过 Deep Link 直接访问页面。
3. **不要在大型项目中只使用命名路由**：考虑使用 GoRouter 等声明式路由方案（见第3章）。

### 命名路由 vs 匿名路由 对比

| 特性 | 匿名路由 | 命名路由 |
|------|----------|----------|
| 类型安全 | ✅ 构造函数传参 | ❌ 依赖 arguments |
| 集中管理 | ❌ 分散在各处 | ✅ routes/onGenerateRoute |
| Deep Link | ❌ 不支持 | ✅ 支持 |
| 动态路由 | ✅ 直接创建 | ✅ onGenerateRoute |
| 适用规模 | 小型应用 | 中型应用 |

---

## 延伸阅读

- [Flutter Cookbook - Named Routes](https://docs.flutter.dev/cookbook/navigation/named-routes)
- [Navigator.pushNamed API](https://api.flutter.dev/flutter/widgets/Navigator/pushNamed.html)
- [onGenerateRoute API](https://api.flutter.dev/flutter/material/MaterialApp/onGenerateRoute.html)
