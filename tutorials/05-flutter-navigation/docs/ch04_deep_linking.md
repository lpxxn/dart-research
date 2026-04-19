# 第4章：Deep Linking

## 目录

1. [什么是 Deep Linking](#1-什么是-deep-linking)
2. [Flutter Web 的 URL 策略](#2-flutter-web-的-url-策略)
3. [Android 配置](#3-android-配置)
4. [iOS 配置](#4-ios-配置)
5. [GoRouter 的 Deep Link 支持](#5-gorouter-的-deep-link-支持)
6. [完整示例说明](#6-完整示例说明)
7. [测试 Deep Link](#7-测试-deep-link)
8. [最佳实践](#8-最佳实践)

---

## 1. 什么是 Deep Linking

### 概念

**Deep Linking（深度链接）** 是指通过一个 URL 直接打开应用中的特定页面，而不是只能打开应用的首页。

```
传统链接：myapp:// → 打开应用首页
Deep Link：myapp://product/42 → 直接打开商品 42 的详情页
```

### 应用场景

- **分享链接**：用户分享一个商品链接，其他用户点击后直接进入商品详情
- **推送通知**：点击通知后跳转到对应的订单页面
- **营销活动**：广告链接直接跳转到活动页面
- **Web 导航**：Flutter Web 中浏览器地址栏直接输入 URL
- **跨应用跳转**：从其他应用跳转到指定页面

### Deep Link 的类型

| 类型 | 说明 | 示例 |
|------|------|------|
| **URI Scheme** | 自定义协议 | `myapp://product/42` |
| **App Links (Android)** | HTTPS 链接直接打开应用 | `https://myapp.com/product/42` |
| **Universal Links (iOS)** | HTTPS 链接直接打开应用 | `https://myapp.com/product/42` |

### Deep Link 的工作流程

```
用户点击链接
    ↓
系统检查是否有注册的应用处理该链接
    ↓
├── 有 → 打开应用，传递 URL
│       ↓
│   应用的路由系统解析 URL
│       ↓
│   跳转到对应页面
│
└── 没有 → 在浏览器中打开（HTTPS 链接）
           或提示无法打开（自定义协议）
```

---

## 2. Flutter Web 的 URL 策略

### Hash 策略 vs Path 策略

Flutter Web 支持两种 URL 策略：

| 策略 | URL 格式 | 示例 |
|------|----------|------|
| **Hash** | `/#/path` | `https://myapp.com/#/product/42` |
| **Path** | `/path` | `https://myapp.com/product/42` |

### 配置方式

在 `web/index.html` 中 Flutter 引擎初始化的时候可以进行配置（Flutter 3.x+）:

```html
<script>
  // 在 Flutter engine 初始化时设置 URL 策略
  // 在 flutter_bootstrap.js 加载前设置
</script>
```

在 Dart 代码中配置（推荐方式）：

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  // 使用 Path 策略（去掉 URL 中的 #）
  usePathUrlStrategy();
  runApp(const MyApp());
}
```

> ⚠️ 使用 Path 策略时，服务器需要配置 URL 重写，将所有路径都指向 `index.html`。

### Hash 策略

**优点：**
- 无需服务器配置
- 兼容所有静态文件服务器（如 GitHub Pages）

**缺点：**
- URL 不够美观（带 `#` 号）
- SEO 不友好

### Path 策略

**优点：**
- URL 美观、直观
- SEO 友好

**缺点：**
- 需要服务器端配置 URL 重写
- 刷新页面时需要服务器返回 `index.html`

### 服务器配置示例

**Nginx：**
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

**Apache (.htaccess)：**
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

---

## 3. Android 配置

### 自定义 URI Scheme

在 `android/app/src/main/AndroidManifest.xml` 的 `<activity>` 中添加 `<intent-filter>`：

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    ...>

    <!-- 默认的 Flutter intent-filter -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Deep Link: 自定义 URI Scheme -->
    <!-- 处理 myapp://product/42 这样的链接 -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <!-- scheme: myapp -->
        <data android:scheme="myapp"/>
    </intent-filter>

    <!-- Deep Link: App Links (HTTPS) -->
    <!-- 处理 https://myapp.com/product/42 这样的链接 -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https"
              android:host="myapp.com"/>
    </intent-filter>
</activity>
```

### intent-filter 参数说明

| 属性 | 说明 |
|------|------|
| `android:scheme` | URL 协议（如 `myapp`、`https`） |
| `android:host` | 域名（如 `myapp.com`） |
| `android:pathPrefix` | 路径前缀过滤（如 `/product`） |
| `android:autoVerify` | App Links 自动验证（需要在服务器放置验证文件） |

### App Links 验证

要使 App Links（HTTPS Deep Link）正常工作，需要在你的域名下放置一个验证文件：

```
https://myapp.com/.well-known/assetlinks.json
```

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.myapp",
    "sha256_cert_fingerprints": ["你的 SHA256 签名指纹"]
  }
}]
```

---

## 4. iOS 配置

### 自定义 URI Scheme

在 `ios/Runner/Info.plist` 中添加 URL Scheme 配置：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.example.myapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

这样配置后，`myapp://product/42` 就能打开你的应用。

### Universal Links

Universal Links 使用 HTTPS 链接直接打开应用，需要更多配置：

#### 1. 在 Xcode 中配置 Associated Domains

在 `ios/Runner/Runner.entitlements`（或通过 Xcode → Signing & Capabilities → Associated Domains）中添加：

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:myapp.com</string>
</array>
```

#### 2. 在服务器放置验证文件

在你的域名下放置 Apple App Site Association 文件：

```
https://myapp.com/.well-known/apple-app-site-association
```

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TEAM_ID.com.example.myapp"],
        "paths": ["/product/*", "/user/*"]
      }
    ]
  }
}
```

#### 3. FlutterDeepLinkingEnabled

在 `ios/Runner/Info.plist` 中启用 Flutter 的 Deep Linking 支持：

```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

### iOS vs Android 对比

| 特性 | Android | iOS |
|------|---------|-----|
| 自定义协议 | intent-filter + scheme | Info.plist + CFBundleURLSchemes |
| HTTPS 链接 | App Links | Universal Links |
| 验证文件 | assetlinks.json | apple-app-site-association |
| 验证位置 | `/.well-known/` | `/.well-known/` |

---

## 5. GoRouter 的 Deep Link 支持

### GoRouter 自动处理 Deep Link

GoRouter 最大的优势之一就是**自动支持 Deep Link**。你只需要定义好路由，GoRouter 就能自动解析传入的 URL 并导航到正确的页面：

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductPage(id: id);
      },
    ),
    GoRoute(
      path: '/user/:userId/orders',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return OrdersPage(userId: userId);
      },
    ),
  ],
);
```

当系统传入 `myapp://product/42` 时，GoRouter 自动：
1. 解析 URL → path = `/product/42`
2. 匹配路由 → `/product/:id`，id = `42`
3. 构建页面 → `ProductPage(id: '42')`

### 嵌套路由的 Deep Link

嵌套路由在 Deep Link 场景下特别有用——GoRouter 会自动构建完整的导航栈：

```dart
GoRoute(
  path: '/shop',
  builder: (context, state) => const ShopPage(),
  routes: [
    GoRoute(
      path: 'product/:id',
      builder: (context, state) => ProductPage(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

当 Deep Link 为 `myapp://shop/product/42` 时：
- 导航栈：`[ShopPage, ProductPage(42)]`
- 用户可以从 ProductPage 返回到 ShopPage

### 结合 redirect 处理 Deep Link

```dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authService.isLoggedIn;

    // 未登录时保存目标路径，登录后再跳转
    if (!isLoggedIn && state.matchedLocation != '/login') {
      // 将目标路径作为查询参数传递给登录页
      return '/login?redirect=${state.matchedLocation}';
    }

    // 登录页检查是否有待跳转的路径
    if (isLoggedIn && state.matchedLocation == '/login') {
      final redirect = state.uri.queryParameters['redirect'];
      return redirect ?? '/home';
    }

    return null;
  },
  routes: [/* ... */],
);
```

---

## 6. 完整示例说明

示例代码位于 `lib/ch04_deep_linking.dart`，演示了 Deep Link 路由解析。

### 功能特点

1. **多路径路由配置**：展示各种路径模式的 Deep Link 解析
2. **路径参数解析**：`/product/:id`、`/user/:userId/orders`
3. **查询参数解析**：`/search?q=xxx&category=yyy`
4. **嵌套路由**：自动构建导航栈
5. **404 处理**：未知路径友好提示
6. **模拟 Deep Link 测试**：通过按钮模拟各种 Deep Link 跳转

### 页面结构

```
/                          → 首页（Deep Link 测试入口）
/product/:id               → 商品详情页
/user/:userId              → 用户主页
/user/:userId/orders       → 用户订单页
/search?q=xxx              → 搜索页
/promo/:code               → 活动推广页
```

### 运行示例

```bash
cd flutter-navigation
flutter run -t lib/ch04_deep_linking.dart
```

### 在 Android 模拟器上测试 Deep Link

```bash
# 通过 adb 发送 Deep Link
adb shell am start -a android.intent.action.VIEW \
  -d "myapp://product/42" \
  com.example.flutter_navigation
```

### 在 iOS 模拟器上测试 Deep Link

```bash
# 通过 xcrun 发送 Deep Link
xcrun simctl openurl booted "myapp://product/42"
```

---

## 7. 测试 Deep Link

### 单元测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('Deep Link 路由匹配', () {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => Container()),
        GoRoute(path: '/product/:id', builder: (_, __) => Container()),
      ],
    );

    // 验证路由能正确匹配
    // GoRouter 的路由匹配在内部处理，
    // 通常通过 Widget 测试来验证
  });
}
```

### Widget 测试

```dart
testWidgets('Deep Link 导航到正确页面', (tester) async {
  final router = GoRouter(
    initialLocation: '/product/42',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Text('Home'),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => Text('Product ${state.pathParameters["id"]}'),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();

  expect(find.text('Product 42'), findsOneWidget);
});
```

### 集成测试

在真机或模拟器上通过 `adb` 或 `xcrun` 发送 Deep Link 命令验证。

### 调试技巧

1. **GoRouter 调试日志**：
   ```dart
   final router = GoRouter(
     debugLogDiagnostics: true, // 开启调试日志
     routes: [/* ... */],
   );
   ```

2. **观察路由变化**：
   ```dart
   router.routerDelegate.addListener(() {
     print('当前路径: ${router.routerDelegate.currentConfiguration}');
   });
   ```

---

## 8. 最佳实践

### ✅ 推荐做法

1. **所有页面都应该能通过 URL 访问**：
   这是 Deep Link 的核心原则。设计路由时确保每个页面都有唯一的 URL。

2. **使用路径参数而非 extra**：
   ```dart
   // ✅ Deep Link 友好
   GoRoute(
     path: '/product/:id',
     builder: (_, state) => ProductPage(id: state.pathParameters['id']!),
   )

   // ❌ Deep Link 不友好（extra 在 URL 中不可见）
   context.go('/product', extra: productObj);
   ```

3. **处理参数缺失的情况**：
   Deep Link 可能来自外部，参数可能不完整或格式错误：
   ```dart
   builder: (context, state) {
     final id = int.tryParse(state.pathParameters['id'] ?? '');
     if (id == null) return const ErrorPage(message: '无效的商品 ID');
     return ProductPage(id: id);
   }
   ```

4. **开启 GoRouter 调试日志**：
   开发阶段使用 `debugLogDiagnostics: true`，方便排查路由问题。

5. **同时配置 URI Scheme 和 App Links/Universal Links**：
   URI Scheme 适合应用间跳转，HTTPS 链接适合网页分享。

### ❌ 避免的做法

1. **不要假设用户一定从首页进入**：Deep Link 可以直接打开任何页面。
2. **不要忽略登录状态检查**：Deep Link 打开的页面可能需要登录才能访问。
3. **不要在 Deep Link 中传递敏感信息**：URL 可能被日志记录或泄露。

### 安全考虑

- **验证所有输入参数**：Deep Link 来自外部，不可信
- **不要在 URL 中包含 token、密码等敏感信息**
- **对 App Links/Universal Links 进行域名验证**：防止恶意应用劫持链接
- **限制可通过 Deep Link 访问的页面**：某些管理页面不应通过 Deep Link 直接打开

---

## 延伸阅读

- [Flutter 官方 Deep Linking 文档](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [GoRouter Deep Linking](https://pub.dev/packages/go_router#deep-linking)
