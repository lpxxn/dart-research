# 第1章 — 基础自定义控件 (StatelessWidget)

> 本章将带你从零开始理解如何封装自定义控件。我们将深入学习 StatelessWidget 的设计模式，掌握参数设计、组合技巧，并通过一个完整的 GreetingCard 示例将理论付诸实践。

---

## 1.1 为什么要自定义控件

### 代码复用

在 Flutter 应用中，很多 UI 片段会在不同页面反复出现——比如用户头像卡片、状态标签、统一风格的按钮等。如果每次都从头写一遍，不仅浪费时间，还会导致代码分散、难以维护。自定义控件的第一个好处就是 **代码复用**：把重复的 UI 逻辑封装成一个 Widget，在需要的地方直接使用。

### UI 一致性

当团队多人协作开发时，如果每个人都自己写卡片样式，很快就会出现"同一个概念，三种长相"的问题。将 UI 封装成控件后，所有人使用同一个 `GreetingCard`，修改样式只需要改一处，整个应用保持一致。

### 关注点分离

自定义控件遵循单一职责原则。一个 `GreetingCard` 只关心"如何展示用户信息"，而不关心数据从哪里来、点击后做什么。这种分离让代码更容易测试、更容易理解。

### 什么时候该封装？

一个实用的经验法则：**当同一段 UI 代码重复出现 3 次以上时**，就应该考虑封装成自定义控件。当然，如果一段 UI 逻辑很复杂（超过 50 行），即使只用一次，也值得单独封装以提高可读性。

---

## 1.2 StatelessWidget 详解

### 类结构

一个最简单的自定义 StatelessWidget 只需要两步：

1. 继承 `StatelessWidget`
2. 重写 `build(BuildContext context)` 方法

```dart
class MyLabel extends StatelessWidget {
  final String text;

  const MyLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16));
  }
}
```

`build` 方法是控件的核心——它描述了"这个控件长什么样"。每次 Flutter 需要渲染这个控件时，都会调用 `build` 方法。因为 StatelessWidget 没有可变状态，所以同样的输入参数总是产生同样的 UI，这使得它非常可预测。

### 构造函数设计

构造函数是控件的"接口"——外部通过它传入配置参数：

```dart
class PriceTag extends StatelessWidget {
  final double price;
  final String currency;
  final bool showDecimal;

  const PriceTag({
    super.key,
    required this.price,      // 必要参数：用 required
    this.currency = '¥',      // 可选参数：提供默认值
    this.showDecimal = true,   // 可选参数：提供默认值
  }) : assert(price >= 0, '价格不能为负数'); // assert 约束参数

  @override
  Widget build(BuildContext context) {
    final display = showDecimal
        ? '$currency${price.toStringAsFixed(2)}'
        : '$currency${price.toInt()}';
    return Text(display);
  }
}
```

设计要点：
- **`required`** 标记必须传入的参数，编译期就能检查
- **默认值** 让常用配置不需要每次都写
- **`assert`** 在开发阶段捕获非法参数（Release 模式下会被移除，零性能开销）

### const 构造函数的优势

当构造函数标记为 `const` 时，如果所有参数都是编译期常量，Flutter 可以在编译期创建这个 Widget 实例，而不是在运行时。这带来两个好处：

1. **减少对象创建**：相同参数的 const Widget 在内存中只有一份
2. **跳过重建**：父 Widget 重建时，const 子 Widget 不需要重新创建，减少 `build` 开销

```dart
// ✅ 好：const 构造函数
const GreetingCard(name: '张三');

// ❌ 不好：变量参数无法使用 const
GreetingCard(name: userName); // 运行时才知道值，无法 const
```

规则很简单：**所有字段都是 `final`，就可以加 `const` 构造函数**。养成这个习惯，让 Flutter 帮你优化性能。

---

## 1.3 参数设计最佳实践

### 必要参数 vs 可选参数

判断标准：
- **必要参数**：缺少它控件就没意义（如 `name`）
- **可选参数**：有合理的默认行为（如 `isOnline` 默认 `false`）

```dart
const GreetingCard({
  required this.name,        // 没有名字就不是问候卡片了
  this.greeting = '你好！',   // 有默认问候语
  this.avatarUrl,            // 可选，null 时用首字母
  this.isOnline = false,     // 默认离线
  this.onTap,                // 可选回调
});
```

### 用 typedef 定义回调类型

当回调签名比较复杂时，用 `typedef` 提高可读性：

```dart
/// 评分变化回调：新评分 + 旧评分
typedef RatingChangedCallback = void Function(int newRating, int oldRating);

class RatingBar extends StatelessWidget {
  final RatingChangedCallback? onRatingChanged;
  // ...
}
```

对于简单回调，Flutter 已经提供了内置类型定义：
- `VoidCallback` → `void Function()`
- `ValueChanged<T>` → `void Function(T value)`
- `ValueGetter<T>` → `T Function()`

### 用枚举控制变体

当控件有几种固定样式时，用枚举比布尔值更清晰：

```dart
/// 按钮尺寸
enum ButtonSize { small, medium, large }

class MyButton extends StatelessWidget {
  final ButtonSize size;
  final String label;

  const MyButton({
    super.key,
    this.size = ButtonSize.medium,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final padding = switch (size) {
      ButtonSize.small  => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ButtonSize.large  => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    };

    return ElevatedButton(
      style: ElevatedButton.styleFrom(padding: padding),
      onPressed: () {},
      child: Text(label),
    );
  }
}
```

比 `bool isSmall, bool isLarge` 好得多——枚举是互斥的，布尔值容易出现 `isSmall = true, isLarge = true` 这种矛盾。

---

## 1.4 示例：GreetingCard 控件

### 需求描述

我们要构建一个用户问候卡片，包含以下元素：
- **头像**：`CircleAvatar` 展示用户头像，没有图片时显示姓名首字母
- **在线状态**：头像右下角的小绿点
- **姓名**：加粗显示
- **问候语**：副标题样式
- **点击交互**：整张卡片可点击，带涟漪效果

### 完整代码

```dart
import 'package:flutter/material.dart';

/// 问候卡片控件
/// 展示用户头像、姓名、问候语和在线状态。
class GreetingCard extends StatelessWidget {
  /// 用户姓名（必填）
  final String name;

  /// 问候语，默认 "你好！"
  final String greeting;

  /// 头像网络地址，为 null 时显示姓名首字母
  final String? avatarUrl;

  /// 是否在线，在线时头像右下角显示小绿点
  final bool isOnline;

  /// 点击卡片的回调
  final VoidCallback? onTap;

  const GreetingCard({
    super.key,
    required this.name,       // 必要参数
    this.greeting = '你好！',  // 有默认值的可选参数
    this.avatarUrl,           // 可空的可选参数
    this.isOnline = false,    // 布尔可选参数
    this.onTap,               // 可空回调
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 取姓名首字符作为头像 fallback
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // InkWell 包裹整个卡片，提供点击涟漪效果
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ---- 头像区域 ----
              // 用 Stack 叠加在线状态小绿点到头像右下角
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!)
                        : null,
                    // 没有头像时显示首字母
                    child: avatarUrl == null
                        ? Text(
                            initial,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  // 在线状态指示器 —— 条件渲染
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // ---- 文字区域 ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ---- 右箭头 ----
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 逐行解析

| 关键点 | 说明 |
|-------|------|
| `const GreetingCard(...)` | const 构造函数，允许编译期常量优化 |
| `required this.name` | 必要参数，编译期检查 |
| `this.greeting = '你好！'` | 可选参数带默认值 |
| `Theme.of(context)` | 从上下文获取主题，保证风格一致 |
| `name.characters.first` | 正确处理 Unicode（emoji、中文等） |
| `Stack + Positioned` | 组合方式实现头像上的状态指示器 |
| `if (isOnline)` | Dart 集合中的条件元素语法 |
| `InkWell` | Material Design 涟漪效果 |
| `Expanded` | 让文字区域占满剩余空间 |

### 使用示例

```dart
// 基础用法
const GreetingCard(name: '李明')

// 完整配置
GreetingCard(
  name: '王芳',
  greeting: '下午好！今天天气不错 ☀️',
  avatarUrl: 'https://example.com/avatar.jpg',
  isOnline: true,
  onTap: () => Navigator.pushNamed(context, '/profile'),
)
```

---

## 1.5 组合技巧

### 拆分方法 vs 拆分类

在 Flutter 中，有两种方式将大 `build` 方法拆小：

**方式一：私有方法（private method）**

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildBody(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(/* ... */);
  }

  Widget _buildBody(BuildContext context) {
    return Container(/* ... */);
  }
}
```

**方式二：私有 Widget 类（private Widget class）**

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileHeader(name: 'Flutter'),
        _ProfileBody(bio: '...'),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  const _ProfileHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(/* ... */);
  }
}
```

### 何时用哪种？

| 场景 | 推荐方式 | 原因 |
|------|---------|------|
| 逻辑简单，只是让 build 更清晰 | 私有方法 | 少写代码，简单直接 |
| 子部分有自己的状态 | 私有 Widget 类 | StatefulWidget 必须是类 |
| 子部分需要被 Flutter 独立优化 | 私有 Widget 类 | 独立的 Widget 有自己的 Element，可以独立重建 |
| 子部分可能被复用 | 私有 Widget 类 | 类更容易复用和测试 |
| 在 `AnimatedBuilder` / `ValueListenableBuilder` 等中使用 | 私有 Widget 类 | 可以用 const 避免不必要的重建 |

**重要区别**：私有方法返回的 Widget 没有自己的 Element，父 Widget 重建时它一定跟着重建。而独立的 Widget 类有自己的 Element，Flutter 可以通过对比决定是否需要重建。在性能敏感的场景（如列表项），优先使用 Widget 类。

### Builder 模式

有时你希望控件的某个部分可以被使用者自定义，可以用 builder 回调：

```dart
class InfoCard extends StatelessWidget {
  final String title;
  /// 允许外部自定义底部区域
  final WidgetBuilder? footerBuilder;

  const InfoCard({
    super.key,
    required this.title,
    this.footerBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(title),
          if (footerBuilder != null)
            footerBuilder!(context),
        ],
      ),
    );
  }
}

// 使用时可以自定义底部
InfoCard(
  title: '信息卡片',
  footerBuilder: (context) => ElevatedButton(
    onPressed: () {},
    child: const Text('自定义按钮'),
  ),
)
```

这种模式在 Flutter 源码中大量使用——`ListView.builder`、`AnimatedBuilder`、`LayoutBuilder` 都是 Builder 模式的典型应用。它让控件保持灵活，同时不需要预设所有可能的变体。

---

## 1.6 小结

本章我们学习了：

1. **为什么要自定义控件**：代码复用、UI 一致性、关注点分离。重复 3 次以上就该封装。

2. **StatelessWidget 的结构**：继承 + 重写 `build`。所有配置通过构造函数参数传入，Widget 本身不可变。

3. **参数设计**：`required` 标记必要参数，默认值简化使用，`assert` 守护约束，枚举代替布尔标志位。

4. **const 优化**：养成 const 构造函数的习惯，让 Flutter 帮你减少不必要的重建。

5. **组合技巧**：大控件拆小，私有方法快速拆分，私有 Widget 类获得更好的性能和复用性，Builder 模式提供灵活扩展点。

下一章，我们将进入 StatefulWidget 的世界，学习如何处理用户交互和管理状态。

> 📌 **练习**：尝试给 GreetingCard 添加一个 `badge` 参数（如 "VIP"、"新用户"），在姓名旁边显示一个小徽章。思考这个参数应该是 `String?` 还是枚举类型。
