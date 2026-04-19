# 第 4 章：控制流

控制流是程序的"骨架"，决定了代码的执行路径和循环方式。Dart 提供了完整的条件判断、循环和分支语句，同时 Dart 3 引入了强大的 switch 表达式语法。

## 4.1 条件语句

### if / else if / else

最基础的条件判断语句，条件必须是 `bool` 类型：

```dart
var score = 85;

if (score >= 90) {
  print('优秀');
} else if (score >= 80) {
  print('良好');
} else if (score >= 60) {
  print('及格');
} else {
  print('不及格');
}
```

**注意**：Dart 不像 JavaScript 那样有"隐式真值"概念。条件表达式必须是 `bool`，不能使用 `if (1)` 或 `if ('')` 这样的写法。

### if-case 语句（Dart 3）

Dart 3 引入了 `if-case` 语法，将模式匹配与 if 语句结合：

```dart
var value = [1, 2, 3];

if (value case [int a, int b, int c]) {
  print('三个整数: $a, $b, $c');
}
```

### 条件表达式 `? :`

三目运算符是 if-else 的简洁写法，适合单行赋值场景：

```dart
var age = 20;
var status = age >= 18 ? '成年' : '未成年';
print(status);  // '成年'
```

## 4.2 循环

### for：经典 C 风格循环

标准的三段式 for 循环，适合需要索引的场景：

```dart
for (var i = 0; i < 5; i++) {
  print('第 $i 次');
}
```

### for-in：遍历 Iterable

`for-in` 用于遍历任何实现了 `Iterable` 接口的对象（List、Set 等）：

```dart
var fruits = ['苹果', '香蕉', '橘子'];
for (var fruit in fruits) {
  print(fruit);
}
```

`for-in` 比经典 for 循环更简洁，也更不容易出错（无需管理索引变量）。

### forEach：函数式遍历

`forEach` 是集合的方法，接受一个回调函数：

```dart
var numbers = [1, 2, 3, 4, 5];

// 使用匿名函数
numbers.forEach((n) {
  print(n * n);
});

// 使用箭头函数
numbers.forEach((n) => print(n * n));
```

**注意**：`forEach` 中不能使用 `break` 和 `continue`。如果需要提前退出，应使用 `for-in`。

### while 和 do-while

`while` 先判断条件再执行循环体，`do-while` 先执行一次循环体再判断条件：

```dart
// while：可能一次都不执行
var count = 5;
while (count > 0) {
  print('倒计时: $count');
  count--;
}

// do-while：至少执行一次
var input = '';
do {
  input = '模拟输入';
  print('处理: $input');
} while (input != '模拟输入');
```

### break 和 continue

- `break`：立即退出当前循环
- `continue`：跳过本次迭代，进入下一次

```dart
// break：找到目标后退出
for (var i = 0; i < 100; i++) {
  if (i == 5) {
    print('找到 5，退出循环');
    break;
  }
}

// continue：跳过偶数
for (var i = 0; i < 10; i++) {
  if (i.isEven) continue;
  print('奇数: $i');
}
```

### 标签（label）+ break/continue

当有多层嵌套循环时，可以使用标签来精确控制跳出哪一层：

```dart
outer:
for (var i = 0; i < 3; i++) {
  for (var j = 0; j < 3; j++) {
    if (i == 1 && j == 1) {
      print('在 ($i, $j) 跳出外层循环');
      break outer;  // 直接跳出外层循环
    }
    print('($i, $j)');
  }
}
```

`continue` 也可以配合标签使用：

```dart
outer:
for (var i = 0; i < 3; i++) {
  for (var j = 0; j < 3; j++) {
    if (j == 1) {
      continue outer;  // 跳到外层循环的下一次迭代
    }
    print('($i, $j)');
  }
}
// 输出: (0,0), (1,0), (2,0) —— 每行的 j=1 和 j=2 都被跳过了
```

## 4.3 switch

### 传统 switch 语句

Dart 的传统 switch 语句与其他语言类似，但有一些特殊规则：

```dart
var command = 'open';

switch (command) {
  case 'open':
    print('打开文件');
  case 'close':
    print('关闭文件');
  case 'save':
    print('保存文件');
  default:
    print('未知命令');
}
```

**注意**：Dart 3 中不再需要 `break`，每个 `case` 执行完后自动终止（不会贯穿到下一个 case）。如果需要多个 case 执行相同逻辑，可以使用逗号分隔或空 case 体：

```dart
switch (command) {
  case 'open' || 'start':  // Dart 3 模式匹配语法
    print('启动');
  case 'close' || 'stop':
    print('停止');
}
```

### switch 表达式（Dart 3 新语法）

Dart 3 引入了 switch 表达式，可以直接返回值，语法更加简洁：

```dart
var status = 'active';
var message = switch (status) {
  'active' => '用户在线',
  'inactive' => '用户离线',
  'banned' => '用户被封禁',
  _ => '未知状态',  // _ 是默认分支
};
print(message);
```

### when 守卫子句

`when` 关键字为 case 添加额外的条件约束：

```dart
var score = 85;
var level = switch (score) {
  >= 90 => 'A',
  >= 80 when score < 90 => 'B',
  >= 60 when score < 80 => 'C',
  _ => 'D',
};
print('成绩等级: $level');
```

### 配合 enum 使用

switch 表达式与枚举配合使用时，Dart 会进行**穷尽检查**——如果没有覆盖所有枚举值，编译器会报错：

```dart
enum Season { spring, summer, autumn, winter }

var season = Season.spring;
var description = switch (season) {
  Season.spring => '春暖花开',
  Season.summer => '烈日炎炎',
  Season.autumn => '秋高气爽',
  Season.winter => '白雪皑皑',
  // 不需要 default，因为所有枚举值都已覆盖
};
print(description);
```

如果你遗漏了某个枚举值，编译器会给出警告，帮助你在编译期就发现潜在的 bug。

### switch 表达式 vs switch 语句

| 特性 | switch 表达式 | switch 语句 |
|------|--------------|-------------|
| 返回值 | 有（可赋值给变量） | 无 |
| 语法 | `=>` | `:` + 代码块 |
| 默认分支 | `_` | `default` |
| 穷尽检查 | 强制（必须覆盖所有可能） | 非强制 |
| 使用场景 | 根据条件返回值 | 根据条件执行不同操作 |

## 4.4 assert 断言

`assert` 用于在调试阶段验证条件，确保程序处于预期状态：

```dart
var age = 25;
assert(age >= 0, '年龄不能为负数');
assert(age < 200, '年龄不合理');
```

### 关键特性

1. **只在调试模式生效**：`assert` 仅在开发/调试模式下执行。在生产模式（`dart compile exe` 或 Flutter release build）中，所有 assert 语句都会被完全忽略，不会产生任何性能开销。

2. **断言失败抛出 AssertionError**：如果条件为 false，程序会终止并显示错误信息。

3. **可选的错误消息**：第二个参数是可选的错误描述字符串。

```dart
// 使用 assert 验证函数参数
void setVolume(int volume) {
  assert(volume >= 0 && volume <= 100, '音量必须在 0-100 之间');
  print('音量设置为: $volume');
}

// 使用 assert 验证列表不为空
void processItems(List<String> items) {
  assert(items.isNotEmpty, '列表不能为空');
  for (var item in items) {
    print('处理: $item');
  }
}
```

### assert vs 异常

| 场景 | 推荐使用 |
|------|----------|
| 开发阶段检查不变条件 | `assert` |
| 验证外部输入 | 抛异常（`throw`） |
| 检查不应该到达的代码路径 | `assert(false, '不应到达此处')` |
| 生产环境需要处理的错误 | try/catch |

`assert` 是你的开发阶段安全网——用它来捕获"这不应该发生"的情况。对于生产环境需要处理的错误，应使用异常机制。
