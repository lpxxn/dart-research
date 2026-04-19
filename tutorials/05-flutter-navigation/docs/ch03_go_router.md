# 第3章：GoRouter

## 目录

1. [为什么使用声明式路由](#1-为什么使用声明式路由)
2. [GoRouter 基本配置](#2-gorouter-基本配置)
3. [路径参数和查询参数](#3-路径参数和查询参数)
4. [嵌套路由（Sub-routes）](#4-嵌套路由sub-routes)
5. [ShellRoute — 共享布局](#5-shellroute--共享布局)
6. [路由重定向（Redirect）](#6-路由重定向redirect)
7. [GoRouterState](#7-gorouterstate)
8. [完整示例说明](#8-完整示例说明)
9. [最佳实践](#9-最佳实践)

---

## 1. 为什么使用声明式路由

### Navigator 的痛点

Flutter 内置的 `Navigator` 是**命令式**的——你告诉它"push 这个页面"、"pop 回去"。随着应用复杂度增长，这种方式会遇到问题：

- **Deep Link 处理困难**：Web URL、系统通知点击后需要跳转到特定页面，命令式导航需要手动解析并执行一系列 push
- **嵌套导航复杂**：底部 Tab 导航 + 每个 Tab 内部的导航栈，需要多个 Navigator 协调
- **路由状态难以同步**：URL 和实际路由栈可能不一致
- **无法声明式地描述路由结构**：路由逻辑散落在各个页面的事件处理中

### GoRouter vs Navigator

| 特性 | Navigator | GoRouter |
|------|-----------|---------|
| 路由方式 | 命令式（push/pop） | 声明式（URL 驱动） |
| Deep Link | 需手动处理 | 内置支持 |
| URL 同步 | 不自动同步 | 自动同步（Web） |
| 嵌套导航 | 复杂 | ShellRoute 简化 |
| 路由守卫 | 手动实现 | redirect 内置 |
| 路径参数 | 需手动解析 | 内置支持 |
| 类型安全 | 一般 | 较好 |

### 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  go_router: ^14.0.0
```

然后运行：

```bash
flutter pub get
```

---

## 2. GoRouter 基本配置

### 最简配置

```dart
import 'package:go_router/go_router.dart';

// 定义路由配置
final GoRouter router = GoRouter(
  initialLocation: '/',  // 初始路径
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) => const DetailPage(),
    ),
  ],
);

// 在 MaterialApp 中使用
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,  // 使用 GoRouter 作为路由配置
    );
  }
}
```

> ⚠️ 注意使用 `MaterialApp.router` 而不是普通的 `MaterialApp`。

### 导航方法

GoRouter 提供了多种导航方式：

```dart
// 方式1：使用 context 扩展方法
context.go('/detail');           // 跳转（替换栈）
context.push('/detail');         // 入栈（保留返回）
context.pop();                   // 返回

// 方式2：使用 GoRouter 实例
GoRouter.of(context).go('/detail');
GoRouter.of(context).push('/detail');
GoRouter.of(context).pop();
```

### go vs push 的区别

这是 GoRouter 中最重要的概念之一：

- **`go(path)`**：根据路径声明式地导航，替换整个路由栈。适合主导航。
- **`push(path)`**：将新页面压入现有栈顶。适合需要返回的场景。

```
// 假设当前在 /home

context.go('/settings/profile');
// 路由栈变为：[/settings, /settings/profile]
// /home 不再在栈中

context.push('/settings/profile');
// 路由栈变为：[/home, /settings/profile]
// 可以 pop 回到 /home
```

---

## 3. 路径参数和查询参数

### 路径参数（Path Parameters）

使用 `:paramName` 语法定义路径参数：

```dart
GoRoute(
  path: '/user/:userId',
  builder: (context, state) {
    // 从路径中提取参数
    final userId = state.pathParameters['userId']!;
    return UserPage(userId: userId);
  },
),
```

```dart
// 导航
context.go('/user/42');        // userId = '42'
context.go('/user/alice');     // userId = 'alice'
```

### 查询参数（Query Parameters）

查询参数不需要在路由定义中声明，直接从 `state` 中获取：

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    // 从查询字符串中提取参数
    final query = state.uri.queryParameters['q'] ?? '';
    final page = int.tryParse(
      state.uri.queryParameters['page'] ?? '1',
    ) ?? 1;
    return SearchPage(query: query, page: page);
  },
),
```

```dart
// 导航
context.go('/search?q=flutter&page=2');
```

### 组合使用

```dart
GoRoute(
  path: '/category/:categoryId/products',
  builder: (context, state) {
    final categoryId = state.pathParameters['categoryId']!;
    final sort = state.uri.queryParameters['sort'] ?? 'name';
    return ProductListPage(categoryId: categoryId, sortBy: sort);
  },
),
```

```dart
context.go('/category/electronics/products?sort=price');
```

---

## 4. 嵌套路由（Sub-routes）

### 基本概念

嵌套路由表示页面的层级关系。子路由的路径会自动拼接父路由的路径：

```dart
GoRoute(
  path: '/shop',
  builder: (context, state) => const ShopPage(),
  routes: [
    // 完整路径: /shop/category
    GoRoute(
      path: 'category',
      builder: (context, state) => const CategoryPage(),
      routes: [
        // 完整路径: /shop/category/:id
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CategoryDetailPage(id: id);
          },
        ),
      ],
    ),
    // 完整路径: /shop/cart
    GoRoute(
      path: 'cart',
      builder: (context, state) => const CartPage(),
    ),
  ],
),
```

> ⚠️ 子路由的 `path` 不要以 `/` 开头，否则会被当作顶级路由。

### 嵌套路由与导航栈

使用 `go()` 导航到嵌套路由时，GoRouter 会自动构建完整的导航栈：

```dart
context.go('/shop/category/electronics');
// 导航栈：[ShopPage, CategoryPage, CategoryDetailPage]
// 用户可以依次返回
```

---

## 5. ShellRoute — 共享布局

### 什么是 ShellRoute

`ShellRoute` 用于在多个路由之间共享一个通用的 UI 布局（如底部导航栏、侧边栏）。子路由的页面内容会渲染在 ShellRoute 的布局内部。

```dart
ShellRoute(
  builder: (context, state, child) {
    // child 是当前活跃的子路由页面
    return ScaffoldWithNavBar(child: child);
  },
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeTab(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchTab(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileTab(),
    ),
  ],
),
```

### ScaffoldWithNavBar 实现

```dart
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,  // 子路由的页面内容
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/search');
      case 2: context.go('/profile');
    }
  }
}
```

### ShellRoute 的特点

- Tab 切换时不会重建整个 Scaffold（性能更好）
- 底部导航栏在所有子路由中保持可见
- 每个 Tab 可以有自己的导航栈

---

## 6. 路由重定向（Redirect）

### 全局重定向

`redirect` 是 GoRouter 的强大功能，用于在路由跳转前进行拦截和重定向。最常见的用途是**登录守卫**：

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';

    // 未登录且不是去登录页 → 重定向到登录页
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // 已登录且要去登录页 → 重定向到首页
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // 返回 null 表示不需要重定向
    return null;
  },
  routes: [/* ... */],
);
```

### 路由级重定向

也可以在单个路由上设置重定向：

```dart
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final isAdmin = AuthService.instance.isAdmin;
    if (!isAdmin) return '/home'; // 非管理员重定向到首页
    return null;
  },
  builder: (context, state) => const AdminPage(),
),
```

### 重定向执行顺序

1. 先执行全局 `redirect`
2. 再执行匹配路由的 `redirect`
3. 如果发生重定向，再次执行全局 `redirect`（防止重定向循环）

### 配合状态刷新

当登录状态改变时，需要通知 GoRouter 重新评估重定向：

```dart
final router = GoRouter(
  // 监听认证状态变化，自动刷新路由
  refreshListenable: authNotifier,
  redirect: (context, state) {
    // ...
  },
  routes: [/* ... */],
);
```

其中 `authNotifier` 是一个 `ChangeNotifier`，在登录/登出时调用 `notifyListeners()`。

---

## 7. GoRouterState

`GoRouterState` 包含当前路由的所有信息，在 `builder` 和 `redirect` 中都可以使用：

```dart
GoRoute(
  path: '/user/:id',
  builder: (context, state) {
    // 常用属性
    state.uri;                    // 完整 URI（包含查询参数）
    state.matchedLocation;        // 匹配的路径（如 '/user/42'）
    state.pathParameters;         // 路径参数 Map（如 {'id': '42'}）
    state.uri.queryParameters;    // 查询参数 Map
    state.extra;                  // 通过 extra 传递的额外数据
    state.pageKey;                // 页面的唯一 Key

    return UserPage(id: state.pathParameters['id']!);
  },
),
```

### 使用 extra 传递复杂对象

当需要传递非字符串数据时，可以使用 `extra`：

```dart
// 传递
context.go('/detail', extra: ProductInfo(id: 42, name: 'Widget'));

// 接收
GoRoute(
  path: '/detail',
  builder: (context, state) {
    final product = state.extra as ProductInfo;
    return DetailPage(product: product);
  },
),
```

> ⚠️ `extra` 在 Web 上刷新页面后会丢失。如果需要支持 Web 刷新和 Deep Link，建议使用路径参数和查询参数。

---

## 8. 完整示例说明

示例代码位于 `lib/ch03_go_router.dart`，实现了一个带认证守卫的多 Tab 应用。

### 功能特点

1. **登录守卫**：未登录用户自动跳转到登录页
2. **多 Tab 布局**：使用 ShellRoute 实现底部导航栏
3. **嵌套路由**：首页 Tab 内可跳转到详情页
4. **路径参数**：详情页通过 `/home/detail/:id` 接收参数
5. **重定向逻辑**：登录状态改变时自动跳转

### 页面结构

```
/login              → 登录页
/home               → 首页 Tab（ShellRoute 内）
/home/detail/:id    → 详情页（ShellRoute 外，全屏）
/explore            → 发现 Tab（ShellRoute 内）
/profile            → 个人中心 Tab（ShellRoute 内）
```

### 运行示例

```bash
cd flutter-navigation
flutter pub get   # 首次需要安装 go_router
flutter run -t lib/ch03_go_router.dart
```

### 操作流程

1. 启动后未登录，自动重定向到登录页
2. 点击"登录" → 跳转到首页（多 Tab 布局）
3. 底部导航栏切换 Tab
4. 在首页点击商品 → 跳转到详情页（带路径参数）
5. 在个人中心点击"退出登录" → 重定向回登录页

---

## 9. 最佳实践

### ✅ 推荐做法

1. **路由配置单独文件管理**：
   ```dart
   // lib/router.dart
   final GoRouter router = GoRouter(
     routes: [/* ... */],
     redirect: (context, state) {/* ... */},
   );
   ```

2. **使用路径参数而非 extra（特别是 Web 应用）**：
   ```dart
   // ✅ 好：支持刷新和 Deep Link
   context.go('/product/42');

   // ❌ 差：刷新后 extra 丢失
   context.go('/product', extra: Product(id: 42));
   ```

3. **路由名称使用常量**：
   ```dart
   class AppRoutes {
     static const login = '/login';
     static const home = '/home';
     static const detail = '/home/detail/:id';
   }
   ```

4. **使用 `StatefulShellRoute` 保持 Tab 状态**：
   当需要在 Tab 切换时保持各 Tab 的滚动位置等状态时使用。

### ❌ 避免的做法

1. **不要混用 go 和 push 导致路由栈混乱**：理解两者的区别后再使用。
2. **不要在 redirect 中执行异步操作**：redirect 是同步的，异步逻辑应在之前完成。
3. **不要忽略 redirect 的循环检测**：确保不会出现 A→B→A 的无限重定向。

---

## 延伸阅读

- [GoRouter 官方文档](https://pub.dev/packages/go_router)
- [GoRouter 迁移指南](https://docs.flutter.dev/ui/navigation)
- [Flutter 声明式导航](https://docs.flutter.dev/ui/navigation/declarative)
