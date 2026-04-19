# 第6章：集成测试

## 目录

1. [什么是集成测试](#1-什么是集成测试)
2. [集成测试 vs 单元测试 vs Widget 测试](#2-集成测试-vs-单元测试-vs-widget-测试)
3. [配置 integration_test](#3-配置-integration_test)
4. [编写集成测试](#4-编写集成测试)
5. [测试用户流程](#5-测试用户流程)
6. [截图测试](#6-截图测试)
7. [最佳实践](#7-最佳实践)

---

## 1. 什么是集成测试

集成测试（Integration Testing）是在**真实设备或模拟器**上运行的测试，它会启动完整的应用程序，模拟用户的实际操作流程。与单元测试和 Widget 测试不同，集成测试验证的是多个组件协同工作时的行为。

### 集成测试的价值

- **端到端验证**：确保整个用户流程从头到尾正常工作
- **真实环境**：在真实的渲染引擎和平台 API 上运行
- **回归防护**：防止代码修改破坏现有用户体验
- **自动化验收**：替代部分手工测试，提高效率

## 2. 集成测试 vs 单元测试 vs Widget 测试

| 特性 | 单元测试 | Widget 测试 | 集成测试 |
|------|---------|------------|---------|
| 运行环境 | Dart VM | 模拟框架 | 真实设备/模拟器 |
| 速度 | 极快（毫秒级） | 快（秒级） | 慢（分钟级） |
| 测试范围 | 单个函数/类 | 单个 Widget | 完整应用 |
| 依赖 | 无 | flutter_test | integration_test |
| 置信度 | 低 | 中 | 高 |
| 维护成本 | 低 | 中 | 高 |

### 测试金字塔

```
       /  集成测试  \        ← 少量，高价值
      /  Widget 测试  \      ← 适量，中等价值
     /    单元测试      \    ← 大量，基础保障
    ─────────────────────
```

推荐比例：**70% 单元测试 + 20% Widget 测试 + 10% 集成测试**

## 3. 配置 integration_test

### 3.1 添加依赖

在 `pubspec.yaml` 的 `dev_dependencies` 中添加：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### 3.2 创建目录结构

```
my_app/
├── integration_test/       # 集成测试目录
│   ├── app_test.dart       # 测试文件
│   └── robots/             # 可选：Page Object 模式
│       └── counter_robot.dart
├── lib/
│   └── main.dart
├── test/                   # 单元测试和 Widget 测试
└── test_driver/            # 可选：自定义测试驱动
    └── integration_test.dart
```

### 3.3 测试驱动文件（可选）

如果需要在 Web 上运行集成测试，创建 `test_driver/integration_test.dart`：

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

## 4. 编写集成测试

### 4.1 基本结构

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  // 初始化集成测试绑定 —— 这是集成测试的关键
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('计数器应用测试', () {
    testWidgets('点击加号按钮应增加计数', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 验证初始状态
      expect(find.text('0'), findsOneWidget);

      // 模拟用户操作
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 验证结果
      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

### 4.2 关键 API

```dart
// 等待所有动画和异步操作完成
await tester.pumpAndSettle();

// 等待指定时间
await tester.pump(const Duration(seconds: 2));

// 点击操作
await tester.tap(find.byKey(const Key('my_button')));

// 输入文本
await tester.enterText(find.byType(TextField), 'Hello');

// 滚动操作
await tester.drag(find.byType(ListView), const Offset(0, -300));

// 长按
await tester.longPress(find.byIcon(Icons.delete));

// 查找 Widget
find.text('Hello');              // 按文本查找
find.byType(ElevatedButton);    // 按类型查找
find.byKey(const Key('key'));    // 按 Key 查找
find.byIcon(Icons.add);         // 按图标查找
```

### 4.3 运行集成测试

```bash
# 在连接的设备上运行
flutter test integration_test/app_test.dart

# 指定设备
flutter test integration_test/app_test.dart -d chrome
flutter test integration_test/app_test.dart -d emulator-5554

# 运行所有集成测试
flutter test integration_test/
```

## 5. 测试用户流程

### 5.1 Page Object 模式

为了让集成测试更易维护，推荐使用 **Page Object** 模式，将页面操作封装成独立的类：

```dart
/// 计数器页面的 Robot（Page Object）
class CounterRobot {
  final WidgetTester tester;

  CounterRobot(this.tester);

  /// 验证计数器显示指定值
  Future<void> expectCount(int count) async {
    expect(find.text('$count'), findsOneWidget);
  }

  /// 点击增加按钮
  Future<void> increment() async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  /// 点击减少按钮
  Future<void> decrement() async {
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
  }

  /// 重置计数器
  Future<void> reset() async {
    await tester.tap(find.byKey(const Key('reset_button')));
    await tester.pumpAndSettle();
  }
}
```

使用 Robot：

```dart
testWidgets('完整计数流程', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  final robot = CounterRobot(tester);

  // 步骤清晰，易于阅读
  await robot.expectCount(0);
  await robot.increment();
  await robot.increment();
  await robot.expectCount(2);
  await robot.decrement();
  await robot.expectCount(1);
  await robot.reset();
  await robot.expectCount(0);
});
```

### 5.2 多页面流程测试

```dart
testWidgets('登录 → 首页 → 详情页流程', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 1. 登录页面
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'user@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'password123',
  );
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();

  // 2. 验证进入首页
  expect(find.text('Welcome'), findsOneWidget);

  // 3. 点击列表项进入详情
  await tester.tap(find.text('Item 1'));
  await tester.pumpAndSettle();

  // 4. 验证详情页
  expect(find.text('Item 1 Details'), findsOneWidget);

  // 5. 返回首页
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
  expect(find.text('Welcome'), findsOneWidget);
});
```

## 6. 截图测试

### 6.1 基本截图

集成测试支持在测试过程中截取屏幕截图，用于视觉回归测试：

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('截图测试示例', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 截取初始状态
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('home_initial');

    // 执行操作后截图
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('home_after_increment');
  });
}
```

### 6.2 在不同平台截图

```bash
# Android —— 截图保存在设备上
flutter test integration_test/screenshot_test.dart -d emulator

# iOS
flutter test integration_test/screenshot_test.dart -d simulator

# 使用自定义驱动保存截图到本地
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart
```

### 6.3 Golden 测试（黄金文件测试）

虽然严格来说 Golden 测试属于 Widget 测试，但概念类似：

```dart
testWidgets('Golden 测试', (tester) async {
  await tester.pumpWidget(const MyWidget());
  await tester.pumpAndSettle();

  // 将当前渲染与保存的"黄金"图片比较
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

```bash
# 更新黄金文件
flutter test --update-goldens test/golden_test.dart
```

## 7. 最佳实践

### 7.1 测试编写原则

1. **只测关键路径**：集成测试成本高，只测试核心用户流程
2. **使用 Key**：给需要交互的 Widget 添加 `Key`，避免脆弱的查找方式
3. **Page Object 模式**：封装页面操作，提高可维护性
4. **独立性**：每个测试应该独立，不依赖其他测试的结果
5. **等待充分**：使用 `pumpAndSettle()` 确保动画和异步操作完成

### 7.2 常见问题

```dart
// ❌ 错误：直接按文本查找，容易因 UI 变化而失败
await tester.tap(find.text('Submit'));

// ✅ 正确：使用 Key 查找，更加稳定
await tester.tap(find.byKey(const Key('submit_button')));
```

```dart
// ❌ 错误：忘记等待异步操作
await tester.tap(find.byIcon(Icons.add));
expect(find.text('1'), findsOneWidget);  // 可能失败！

// ✅ 正确：等待 UI 更新
await tester.tap(find.byIcon(Icons.add));
await tester.pumpAndSettle();  // 等待所有帧渲染完成
expect(find.text('1'), findsOneWidget);
```

### 7.3 CI/CD 中运行集成测试

```yaml
# GitHub Actions 示例
- name: Run integration tests
  run: |
    flutter test integration_test/ \
      --device-id=chrome \
      --dart-define=CI=true
```

### 7.4 性能分析集成

```dart
testWidgets('性能追踪', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 使用 Timeline 记录性能数据
  final timeline = await binding.traceAction(() async {
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
    }
  });

  // 生成性能摘要
  final summary = TimelineSummary.summarize(timeline);
  await summary.writeTimelineToFile(
    'counter_perf',
    pretty: true,
  );
});
```

---

## 总结

| 要点 | 说明 |
|------|------|
| 依赖包 | `integration_test`（SDK 自带） |
| 测试目录 | `integration_test/` |
| 初始化 | `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` |
| 运行命令 | `flutter test integration_test/` |
| 设计模式 | Page Object / Robot 模式 |
| 截图 | `binding.takeScreenshot()` |

集成测试是质量保障的最后一道防线，虽然编写和维护成本较高，但对于核心业务流程来说是不可或缺的。

**下一章**：[第7章：代码生成](ch07_code_generation.md)
