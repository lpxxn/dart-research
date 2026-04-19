// 定义枚举，供 switch 表达式使用
enum Season { spring, summer, autumn, winter }

enum HttpStatus { ok, notFound, serverError, unauthorized }

void main() {
  // ========================================
  // 4.1 条件语句
  // ========================================
  print('===== 4.1 条件语句 =====');

  // --- if / else if / else ---
  var score = 85;
  print('成绩: $score');
  if (score >= 90) {
    print('  评级: 优秀');
  } else if (score >= 80) {
    print('  评级: 良好');
  } else if (score >= 60) {
    print('  评级: 及格');
  } else {
    print('  评级: 不及格');
  }

  // --- 条件表达式 ? : ---
  var age = 20;
  var status = age >= 18 ? '成年' : '未成年';
  print('年龄 $age → $status');

  // --- if-case 模式匹配（Dart 3）---
  var point = (3, 4);
  if (point case (int x, int y)) {
    print('坐标: x=$x, y=$y');
  }

  // ========================================
  // 4.2 循环
  // ========================================
  print('\n===== 4.2 循环 =====');

  // --- 经典 for 循环 ---
  print('--- 经典 for ---');
  for (var i = 1; i <= 5; i++) {
    print('  第 $i 次');
  }

  // --- for-in 遍历集合 ---
  print('\n--- for-in 遍历 ---');
  var fruits = ['苹果', '香蕉', '橘子', '葡萄'];
  for (var fruit in fruits) {
    print('  水果: $fruit');
  }

  // for-in 遍历 Set
  var colors = {'红', '绿', '蓝'};
  print('颜色集合:');
  for (var color in colors) {
    print('  $color');
  }

  // for-in 遍历 Map 的 entries
  var capitals = {'中国': '北京', '日本': '东京', '韩国': '首尔'};
  print('国家首都:');
  for (var entry in capitals.entries) {
    print('  ${entry.key} → ${entry.value}');
  }

  // --- forEach ---
  print('\n--- forEach ---');
  var numbers = [1, 2, 3, 4, 5];
  print('平方:');
  for (var n in numbers) {
    print('  $n² = ${n * n}');
  }

  // --- while ---
  print('\n--- while ---');
  var countdown = 5;
  while (countdown > 0) {
    print('  倒计时: $countdown');
    countdown--;
  }

  // --- do-while ---
  print('\n--- do-while ---');
  var attempts = 0;
  do {
    attempts++;
    print('  尝试第 $attempts 次');
  } while (attempts < 3);

  // --- break：找到目标后退出 ---
  print('\n--- break ---');
  var items = ['A', 'B', 'C', 'D', 'E'];
  for (var item in items) {
    if (item == 'C') {
      print('  找到 $item，退出循环');
      break;
    }
    print('  检查: $item');
  }

  // --- continue：跳过偶数 ---
  print('\n--- continue（跳过偶数）---');
  for (var i = 0; i < 10; i++) {
    if (i.isEven) continue;
    print('  奇数: $i');
  }

  // --- 标签 + break 跳出嵌套循环 ---
  print('\n--- 标签 break 跳出嵌套循环 ---');
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (i == 1 && j == 1) {
        print('  在 ($i, $j) 处跳出外层循环');
        break outer;
      }
      print('  ($i, $j)');
    }
  }

  // --- 标签 + continue ---
  print('\n--- 标签 continue ---');
  outer:
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (j == 1) {
        continue outer; // 跳到外层下一次迭代
      }
      print('  ($i, $j)');
    }
  }
  print('  (每行只打印 j=0，j=1 时跳到外层下一轮)');

  // ========================================
  // 4.3 switch
  // ========================================
  print('\n===== 4.3 switch =====');

  // --- 传统 switch 语句 ---
  print('--- 传统 switch 语句 ---');
  var command = 'save';
  switch (command) {
    case 'open':
      print('  打开文件');
    case 'close':
      print('  关闭文件');
    case 'save':
      print('  保存文件');
    default:
      print('  未知命令');
  }

  // --- switch 表达式（Dart 3）---
  print('\n--- switch 表达式 ---');
  var userStatus = 'active';
  var message = switch (userStatus) {
    'active' => '用户在线',
    'inactive' => '用户离线',
    'banned' => '用户被封禁',
    _ => '未知状态',
  };
  print('  状态: $userStatus → $message');

  // --- switch 表达式配合 enum ---
  print('\n--- switch + enum ---');
  for (var season in Season.values) {
    var desc = switch (season) {
      Season.spring => '🌸 春暖花开',
      Season.summer => '☀️ 烈日炎炎',
      Season.autumn => '🍂 秋高气爽',
      Season.winter => '❄️ 白雪皑皑',
    };
    print('  ${season.name} → $desc');
  }

  // --- switch + when 守卫子句 ---
  print('\n--- switch + when 守卫 ---');
  var scores = [95, 87, 72, 55, 40];
  for (var s in scores) {
    var level = switch (s) {
      >= 90 => 'A (优秀)',
      >= 80 when s < 90 => 'B (良好)',
      >= 60 when s < 80 => 'C (及格)',
      _ => 'D (不及格)',
    };
    print('  成绩 $s → $level');
  }

  // --- switch 表达式处理更复杂的模式 ---
  print('\n--- switch 表达式与 HttpStatus ---');
  for (var httpStatus in HttpStatus.values) {
    var response = switch (httpStatus) {
      HttpStatus.ok => '200 请求成功',
      HttpStatus.notFound => '404 资源未找到',
      HttpStatus.serverError => '500 服务器错误',
      HttpStatus.unauthorized => '401 未授权',
    };
    print('  ${httpStatus.name} → $response');
  }

  // ========================================
  // 4.4 assert 断言
  // ========================================
  print('\n===== 4.4 assert 断言 =====');

  // assert 只在调试模式下生效
  var temperature = 36;
  assert(temperature > 0, '温度不能为负数');
  assert(temperature < 100, '温度不能超过100度');
  print('温度 $temperature°C 通过断言检查');

  // 验证函数参数
  void setVolume(int volume) {
    assert(volume >= 0 && volume <= 100, '音量必须在 0-100 之间，当前: $volume');
    print('  音量设置为: $volume');
  }

  setVolume(50);
  setVolume(0);
  setVolume(100);

  // 验证列表非空
  void processItems(List<String> items) {
    assert(items.isNotEmpty, '列表不能为空');
    for (var item in items) {
      print('  处理: $item');
    }
  }

  print('处理任务列表:');
  processItems(['编译', '测试', '部署']);

  print('\n程序正常结束');
}
