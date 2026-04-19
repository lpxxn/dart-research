# 第4章：Hero 动画 (Hero Animations)

## 目录

1. [什么是 Hero 动画](#什么是-hero-动画)
2. [Hero 的工作原理](#hero-的工作原理)
3. [基本用法与 tag 匹配](#基本用法与-tag-匹配)
4. [flightShuttleBuilder](#flightshuttlebuilder)
5. [placeholderBuilder](#placeholderbuilder)
6. [图片画廊→放大效果](#图片画廊放大效果)
7. [Hero 动画的边界情况](#hero-动画的边界情况)
8. [最佳实践](#最佳实践)

---

## 什么是 Hero 动画

Hero 动画（也叫共享元素过渡）是一种**页面间的过渡动画**，让一个元素看起来从一个页面"飞"到另一个页面。

常见的应用场景：
- 图片列表 → 点击查看大图
- 产品缩略图 → 产品详情页
- 头像 → 用户资料页
- FAB → 新页面

### 视觉效果

```
页面A                        页面B
┌─────────────┐             ┌─────────────┐
│  ┌───┐      │   飞行中    │             │
│  │ 🖼 │      │  ─────→    │   ┌──────┐  │
│  └───┘      │             │   │      │  │
│             │             │   │  🖼   │  │
│             │             │   │      │  │
└─────────────┘             │   └──────┘  │
                            └─────────────┘
```

---

## Hero 的工作原理

Hero 动画的实现过程（自动完成，无需手动控制）：

### 1. 导航触发

当调用 `Navigator.push()` 或 `Navigator.pop()` 时，Flutter 开始查找匹配的 Hero。

### 2. 查找匹配

在起始页和目标页中查找**具有相同 tag 的 Hero Widget**。

### 3. 计算飞行路径

- 获取起始 Hero 在屏幕上的位置和大小
- 获取目标 Hero 在屏幕上的位置和大小
- 计算从起点到终点的飞行路径

### 4. 创建 Overlay

Flutter 在所有页面之上创建一个 **Overlay**（覆盖层），将 Hero 的子组件放在这个 Overlay 中执行动画。

### 5. 执行动画

在默认 300ms 的过渡时间内，Hero 的子组件在 Overlay 中从起始位置/大小平滑过渡到目标位置/大小。

### 6. 结束清理

动画完成后，Hero 的子组件从 Overlay 中移除，回到目标页面的正常 Widget 树中。

---

## 基本用法与 tag 匹配

### 最简单的 Hero 动画

```dart
// 页面 A（列表页）
Hero(
  tag: 'avatar-123',  // 唯一标识符
  child: CircleAvatar(
    radius: 30,
    backgroundImage: NetworkImage(user.avatarUrl),
  ),
)

// 页面 B（详情页）——tag 必须与页面 A 相同
Hero(
  tag: 'avatar-123',  // 同样的标识符
  child: CircleAvatar(
    radius: 80,
    backgroundImage: NetworkImage(user.avatarUrl),
  ),
)
```

### tag 的注意事项

1. **唯一性**：同一页面中，每个 Hero 的 tag 必须唯一
2. **匹配性**：起始页和目标页的 Hero tag 必须相同
3. **类型**：tag 是 `Object` 类型，通常用 String 或组合对象

```dart
// ✅ 使用有意义的唯一标识
Hero(tag: 'photo-${photo.id}', child: ...)

// ❌ 使用可能重复的标识
Hero(tag: 'photo', child: ...)

// ✅ 列表中使用索引或 ID 确保唯一
Hero(tag: 'item-$index', child: ...)
```

---

## flightShuttleBuilder

`flightShuttleBuilder` 让你自定义 Hero **在飞行过程中**的外观。

### 默认行为

默认情况下，Hero 在飞行中显示的是**目标页面的子组件**。但有时起始页和目标页的子组件差异很大，默认效果可能不理想。

### 自定义飞行组件

```dart
Hero(
  tag: 'profile-photo',
  flightShuttleBuilder: (
    BuildContext flightContext,
    Animation<double> animation,       // 飞行进度 0.0~1.0
    HeroFlightDirection flightDirection, // 前进还是返回
    BuildContext fromHeroContext,       // 起始 Hero 的 context
    BuildContext toHeroContext,         // 目标 Hero 的 context
  ) {
    // 在飞行中显示一个带圆角裁剪的图片
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            // 从圆形过渡到方形
            (1 - animation.value) * 100,
          ),
          child: Image.network(photoUrl, fit: BoxFit.cover),
        );
      },
    );
  },
  child: ClipOval(
    child: Image.network(photoUrl, width: 60, height: 60, fit: BoxFit.cover),
  ),
)
```

### 典型用例

- 从圆形头像过渡到方形大图
- 飞行过程中显示加载指示器
- 飞行中同时做旋转或其他变换

---

## placeholderBuilder

`placeholderBuilder` 定义了 Hero **飞走后**在原位置显示的占位组件。

```dart
Hero(
  tag: 'card-1',
  placeholderBuilder: (context, heroSize, child) {
    // Hero 飞走后，原位置显示一个灰色占位框
    return Container(
      width: heroSize.width,
      height: heroSize.height,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  },
  child: const Card(child: Text('点击查看详情')),
)
```

### 为什么需要 placeholderBuilder？

当 Hero 飞走时，原来的位置会变成空白，可能导致页面布局跳动。设置 `placeholderBuilder` 可以保持布局稳定。

---

## 图片画廊→放大效果

这是 Hero 动画最经典的应用场景：

### 画廊页面（Grid）

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
  ),
  itemCount: photos.length,
  itemBuilder: (context, index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PhotoDetailPage(
            photoIndex: index,
            photoColor: photos[index],
          ),
        ));
      },
      child: Hero(
        tag: 'photo-$index',
        child: Container(
          color: photos[index],
          child: Center(
            child: Text('${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
        ),
      ),
    );
  },
)
```

### 详情页面

```dart
class PhotoDetailPage extends StatelessWidget {
  final int photoIndex;
  final Color photoColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('照片 ${photoIndex + 1}')),
      body: Center(
        child: Hero(
          tag: 'photo-$photoIndex',
          child: Container(
            width: 300,
            height: 300,
            color: photoColor,
            child: Center(
              child: Text('${photoIndex + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 48)),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Hero 动画的边界情况

### 1. Hero 在 ListView 中被回收

如果起始 Hero 因为滚动被移出屏幕并回收，返回时动画可能不正常。解决方案：
- 使用 `PageStorageKey` 保持滚动位置
- 确保返回时列表项仍然可见

### 2. Hero 与 Material 组件的交互

在使用 Hero 包裹 Material 组件（如 Card、Chip）时，可能出现阴影或形状突变。可以用 `Material` Widget 包裹：

```dart
Hero(
  tag: 'card-1',
  child: Material(
    color: Colors.transparent,
    child: Card(child: ...),
  ),
)
```

### 3. 自定义页面过渡时间

Hero 动画的时长与页面过渡时长一致。要自定义时长：

```dart
Navigator.push(context, PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 500),
  reverseTransitionDuration: const Duration(milliseconds: 500),
  pageBuilder: (_, __, ___) => DetailPage(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(opacity: animation, child: child);
  },
));
```

---

## 最佳实践

### 1. 保持子组件类型一致

```dart
// ✅ 两个页面的 Hero 子组件类型相同
// 页面 A
Hero(tag: 'img', child: Image.network(url, fit: BoxFit.cover))
// 页面 B
Hero(tag: 'img', child: Image.network(url, fit: BoxFit.cover))

// ⚠️ 类型不同可能导致过渡不自然
// 页面 A
Hero(tag: 'item', child: Icon(Icons.star))
// 页面 B
Hero(tag: 'item', child: Text('Star'))
```

### 2. 使用 Material Widget 避免文字闪烁

当 Hero 包裹 Text 时，飞行过程中可能出现文字样式跳变：

```dart
Hero(
  tag: 'title',
  child: Material(
    color: Colors.transparent,
    child: Text('标题', style: TextStyle(fontSize: 18)),
  ),
)
```

### 3. 对大图片使用合适的 fit

```dart
Hero(
  tag: 'photo-$id',
  child: Image.network(
    url,
    fit: BoxFit.cover,  // 保持比例填充
    width: double.infinity,
    height: double.infinity,
  ),
)
```

### 4. 避免在同一页面使用重复的 tag

```dart
// ❌ 这会导致运行时错误
Hero(tag: 'my-hero', child: Widget1())
Hero(tag: 'my-hero', child: Widget2())  // 同一页面中 tag 重复！
```

### 5. 处理返回手势

iOS 上的边缘滑动返回手势会触发 Hero 的 reverse 动画，确保这个过程也是流畅的。

---

## 本章示例代码

查看 `lib/ch04_hero_animations.dart`，该示例展示了：
- 基本的 Hero 动画（颜色方块画廊 → 放大详情）
- flightShuttleBuilder 自定义飞行外观
- 完整的图片画廊交互

运行方式：
```bash
flutter run -t lib/ch04_hero_animations.dart
```
