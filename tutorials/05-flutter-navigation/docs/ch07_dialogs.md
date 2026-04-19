# 第7章：对话框与底部弹窗

## 概述

对话框（Dialog）和底部弹窗（Bottom Sheet）是 App 中常用的交互模式，用于：
- 确认危险操作（删除、退出）
- 选择选项（单选、多选）
- 展示额外信息
- 收集用户输入
- 显示提示消息

Flutter 提供了丰富的内置对话框和弹窗组件。本章将逐一讲解它们的用法。

---

## 1. AlertDialog

### 1.1 基本用法

`AlertDialog` 是最常用的对话框，用于提示信息或确认操作。

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('确认删除'),
    content: const Text('删除后无法恢复，是否继续？'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('取消'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('删除'),
      ),
    ],
  ),
);
```

### 1.2 获取返回值

`showDialog` 返回 `Future<T?>`，可以获取用户的选择结果。

```dart
final confirmed = await showDialog<bool>(
  context: context,
  barrierDismissible: false, // 点击外部不关闭
  builder: (context) => AlertDialog(
    title: const Text('确认'),
    content: const Text('是否保存更改？'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('不保存'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('保存'),
      ),
    ],
  ),
);

if (confirmed == true) {
  // 执行保存
}
```

### 1.3 AlertDialog 关键属性

| 属性 | 说明 |
|------|------|
| `title` | 标题 Widget |
| `content` | 内容 Widget |
| `actions` | 操作按钮列表 |
| `icon` | 图标（Material 3） |
| `shape` | 形状 |
| `backgroundColor` | 背景色 |
| `elevation` | 阴影 |
| `contentPadding` | 内容内边距 |
| `actionsPadding` | 按钮区域内边距 |
| `actionsAlignment` | 按钮对齐方式 |

---

## 2. SimpleDialog

### 2.1 基本用法

`SimpleDialog` 用于提供一组选项供用户选择。

```dart
final result = await showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('选择语言'),
    children: [
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, 'zh'),
        child: const Text('中文'),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, 'en'),
        child: const Text('English'),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, 'ja'),
        child: const Text('日本語'),
      ),
    ],
  ),
);

debugPrint('选择了: $result');
```

### 2.2 自定义选项样式

```dart
SimpleDialogOption(
  onPressed: () => Navigator.pop(context, 'zh'),
  child: Row(
    children: [
      const Icon(Icons.language),
      const SizedBox(width: 16),
      const Text('中文'),
    ],
  ),
)
```

---

## 3. showDialog 与 showGeneralDialog

### 3.1 showDialog

`showDialog` 是显示 Material 风格对话框的便捷方法。

```dart
showDialog<T>(
  context: context,
  builder: (context) => dialog,      // 对话框 Widget
  barrierDismissible: true,           // 点击遮罩是否关闭
  barrierColor: Colors.black54,       // 遮罩颜色
  barrierLabel: 'Dismiss',            // 无障碍标签
  useSafeArea: true,                  // 是否在安全区域内
  useRootNavigator: true,             // 是否使用根 Navigator
);
```

### 3.2 showGeneralDialog

`showGeneralDialog` 提供更底层的控制，可以自定义进入/退出动画。

```dart
showGeneralDialog(
  context: context,
  // 遮罩颜色
  barrierColor: Colors.black.withValues(alpha: 0.5),
  barrierDismissible: true,
  barrierLabel: 'Dismiss',
  // 动画时长
  transitionDuration: const Duration(milliseconds: 300),
  // 自定义过渡动画
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: child,
    );
  },
  // 页面构建
  pageBuilder: (context, animation, secondaryAnimation) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('自定义对话框', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              const Text('这是一个带缩放动画的对话框'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
```

---

## 4. showModalBottomSheet 和 showBottomSheet

### 4.1 Modal Bottom Sheet（模态底部弹窗）

模态底部弹窗会显示一个遮罩层，用户必须与弹窗交互或关闭它才能继续操作。

```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera),
          title: const Text('拍照'),
          onTap: () => Navigator.pop(context, 'camera'),
        ),
        ListTile(
          leading: const Icon(Icons.photo),
          title: const Text('从相册选择'),
          onTap: () => Navigator.pop(context, 'gallery'),
        ),
      ],
    ),
  ),
);
```

### 4.2 关键属性

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,         // 允许弹窗占满屏幕
  isDismissible: true,              // 点击外部是否关闭
  enableDrag: true,                 // 是否允许拖拽关闭
  showDragHandle: true,             // 显示拖拽手柄
  backgroundColor: Colors.white,    // 背景色
  shape: const RoundedRectangleBorder(  // 形状
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  constraints: BoxConstraints(      // 约束
    maxHeight: MediaQuery.of(context).size.height * 0.9,
  ),
  builder: (context) => /* ... */,
);
```

### 4.3 全屏 Bottom Sheet

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true, // 关键：允许控制高度
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.9,  // 初始高度为屏幕的 90%
    minChildSize: 0.5,       // 最小高度为 50%
    maxChildSize: 0.95,      // 最大高度为 95%
    expand: false,
    builder: (context, scrollController) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView.builder(
          controller: scrollController, // 必须使用提供的 controller
          itemCount: 50,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      );
    },
  ),
);
```

### 4.4 Persistent Bottom Sheet（持久底部弹窗）

持久底部弹窗不会显示遮罩，用户可以继续与页面交互。

```dart
// 方式一：通过 ScaffoldState
Scaffold.of(context).showBottomSheet(
  (context) => Container(
    height: 200,
    color: Colors.amber,
    child: const Center(child: Text('持久底部弹窗')),
  ),
);

// 方式二：使用 Scaffold 的 bottomSheet 属性
Scaffold(
  bottomSheet: Container(
    height: 60,
    color: Colors.blue,
    child: const Center(child: Text('固定底部栏')),
  ),
)
```

---

## 5. DraggableScrollableSheet

### 5.1 作为独立组件使用

`DraggableScrollableSheet` 可以在页面中作为独立的可拖拽面板。

```dart
Stack(
  children: [
    // 底层内容
    GoogleMap(/* ... */),
    // 可拖拽面板
    DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          color: Colors.white,
          child: ListView.builder(
            controller: scrollController,
            itemCount: 25,
            itemBuilder: (context, index) {
              return ListTile(title: Text('地点 $index'));
            },
          ),
        );
      },
    ),
  ],
)
```

### 5.2 通过 Controller 控制

```dart
final controller = DraggableScrollableController();

// 动画滑动到指定位置
controller.animateTo(
  0.8,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
);

// 获取当前大小
debugPrint('当前大小: ${controller.size}');
```

---

## 6. SnackBar 和 MaterialBanner

### 6.1 SnackBar

`SnackBar` 是底部的临时提示消息。

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('文件已删除'),
    action: SnackBarAction(
      label: '撤销',
      onPressed: () {
        // 撤销删除
      },
    ),
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,  // 浮动样式
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.all(16),
  ),
);
```

### 6.2 SnackBar 关键属性

| 属性 | 说明 |
|------|------|
| `content` | 内容 Widget |
| `action` | 操作按钮 |
| `duration` | 显示时长 |
| `behavior` | `fixed`（固定在底部）或 `floating`（浮动） |
| `backgroundColor` | 背景色 |
| `shape` | 形状 |
| `margin` | 外边距（仅 floating 生效） |
| `dismissDirection` | 滑动关闭方向 |

### 6.3 MaterialBanner

`MaterialBanner` 是顶部的持久提示栏，需要用户主动关闭。

```dart
ScaffoldMessenger.of(context).showMaterialBanner(
  MaterialBanner(
    content: const Text('新版本可用'),
    leading: const Icon(Icons.info),
    actions: [
      TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        },
        child: const Text('忽略'),
      ),
      TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          // 执行更新
        },
        child: const Text('更新'),
      ),
    ],
  ),
);
```

> **注意：** MaterialBanner 不会自动消失，必须调用 `hideCurrentMaterialBanner()` 来关闭。

---

## 7. showDatePicker 和 showTimePicker

### 7.1 日期选择器

```dart
final date = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime(2030),
  helpText: '选择日期',
  cancelText: '取消',
  confirmText: '确定',
  locale: const Locale('zh', 'CN'), // 需要本地化支持
);

if (date != null) {
  debugPrint('选择日期: ${date.year}-${date.month}-${date.day}');
}
```

### 7.2 日期范围选择器

```dart
final dateRange = await showDateRangePicker(
  context: context,
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);

if (dateRange != null) {
  debugPrint('从 ${dateRange.start} 到 ${dateRange.end}');
}
```

### 7.3 时间选择器

```dart
final time = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  helpText: '选择时间',
  cancelText: '取消',
  confirmText: '确定',
);

if (time != null) {
  debugPrint('选择时间: ${time.hour}:${time.minute}');
}
```

---

## 8. 对话框本质：也是路由

### 8.1 对话框是 Route

在 Flutter 中，`showDialog`、`showModalBottomSheet` 等本质上都是向 Navigator 推入了一个新的 Route（`DialogRoute`、`ModalBottomSheetRoute`）。

这意味着：
- `Navigator.pop(context)` 可以关闭对话框
- 对话框也参与路由栈管理
- `PopScope` 可以拦截对话框的关闭

### 8.2 对话框中使用 Navigator

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('提示'),
    content: const Text('需要登录'),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context); // 先关闭对话框
          Navigator.pushNamed(context, '/login'); // 再跳转
        },
        child: const Text('去登录'),
      ),
    ],
  ),
);
```

---

## 9. 最佳实践

### 9.1 对话框使用原则

- **AlertDialog**：确认/取消的二元选择
- **SimpleDialog**：从列表中选择一项
- **ModalBottomSheet**：操作菜单、表单输入
- **SnackBar**：轻量级临时提示
- **MaterialBanner**：重要但非紧急的通知

### 9.2 避免滥用对话框

- 不要用对话框显示非必要信息
- 连续弹出多个对话框会让用户厌烦
- 考虑用 SnackBar 替代简单的提示对话框

### 9.3 无障碍

- 对话框的 `barrierLabel` 提供屏幕阅读器标签
- 确保对话框中的按钮有语义化的文字
- 使用 `Semantics` Widget 补充无障碍信息

---

## 10. 小结

| 组件 | 用途 | 模态 |
|------|------|------|
| `AlertDialog` | 确认操作 | 是 |
| `SimpleDialog` | 列表选择 | 是 |
| `showGeneralDialog` | 自定义对话框 | 是 |
| `showModalBottomSheet` | 底部操作菜单 | 是 |
| `showBottomSheet` | 持久底部面板 | 否 |
| `DraggableScrollableSheet` | 可拖拽面板 | 否 |
| `SnackBar` | 底部临时提示 | 否 |
| `MaterialBanner` | 顶部持久提示 | 否 |
| `showDatePicker` | 日期选择 | 是 |
| `showTimePicker` | 时间选择 | 是 |

下一章我们将综合运用前面学到的知识，构建一个完整的电商导航实战项目。
