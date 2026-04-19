/// 第11章 枚举与扩展 (Enum & Extension) 示例
///
/// 运行方式: dart run bin/ch11_enum_extension.dart
library;

// ============================================================
// 11.1 基础枚举
// ============================================================
enum Color { red, green, blue }

enum Direction { north, south, east, west }

// ============================================================
// 11.2 增强枚举：Planet（带字段、方法、实现 Comparable）
// ============================================================
enum Planet implements Comparable<Planet> {
  mercury(3.7, 2440, 0),
  venus(8.87, 6052, 0),
  earth(9.81, 6371, 1),
  mars(3.72, 3390, 2),
  jupiter(24.79, 69911, 95),
  saturn(10.44, 58232, 146);

  final double gravity; // 表面重力 (m/s²)
  final double radius; // 半径 (km)
  final int moons; // 卫星数量

  const Planet(this.gravity, this.radius, this.moons);

  /// 计算表面积（近似球形，单位：万 km²）
  double get surfaceArea => 4 * 3.14159 * radius * radius / 10000;

  /// 是否宜居
  bool get isHabitable => this == earth;

  /// 描述
  String describe() => '$name: 重力=${gravity}m/s², 半径=${radius}km, '
      '卫星=$moons颗${isHabitable ? " [宜居]" : ""}';

  @override
  int compareTo(Planet other) => gravity.compareTo(other.gravity);
}

// ============================================================
// 增强枚举：HttpStatus
// ============================================================
enum HttpStatus {
  ok(200, '成功'),
  created(201, '已创建'),
  badRequest(400, '错误请求'),
  unauthorized(401, '未授权'),
  notFound(404, '未找到'),
  serverError(500, '服务器错误');

  final int code;
  final String message;

  const HttpStatus(this.code, this.message);

  bool get isSuccess => code >= 200 && code < 300;
  bool get isClientError => code >= 400 && code < 500;
  bool get isServerError => code >= 500;

  @override
  String toString() => 'HTTP $code: $message';
}

// ============================================================
// 11.3 扩展方法：给 String 添加功能
// ============================================================
extension StringExtras on String {
  /// 判断是否是电子邮件格式（简单判断）
  bool get isEmail => contains('@') && contains('.');

  /// 首字母大写
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// 获取单词列表
  List<String> get words => trim().split(RegExp(r'\s+'));

  /// 截断到指定长度
  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;

  /// 重复 n 次并用分隔符连接
  String repeatJoin(int times, [String separator = '']) =>
      List.filled(times, this).join(separator);
}

// ============================================================
// 扩展方法：给 int 添加功能
// ============================================================
extension IntExtras on int {
  /// 执行回调 n 次
  void times(void Function(int index) callback) {
    for (var i = 0; i < this; i++) {
      callback(i);
    }
  }

  /// 转换为序数词 (1st, 2nd, 3rd...)
  String get ordinal {
    if (this % 100 >= 11 && this % 100 <= 13) return '${this}th';
    return switch (this % 10) {
      1 => '${this}st',
      2 => '${this}nd',
      3 => '${this}rd',
      _ => '${this}th',
    };
  }

  /// 是否在范围内
  bool isBetween(int low, int high) => this >= low && this <= high;

  /// 转换为人类可读的文件大小
  String get fileSize {
    if (this < 1024) return '$this B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ============================================================
// 扩展方法：给 List 添加功能
// ============================================================
extension ListExtras<T> on List<T> {
  /// 按指定键排序并返回新列表
  List<T> sortedBy<K extends Comparable<K>>(K Function(T) keyFn) {
    var copy = List<T>.from(this);
    copy.sort((a, b) => keyFn(a).compareTo(keyFn(b)));
    return copy;
  }

  /// 安全获取元素，越界返回 null
  T? safeGet(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  /// 分块
  List<List<T>> chunked(int size) {
    var chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      var end = i + size;
      chunks.add(sublist(i, end > length ? length : end));
    }
    return chunks;
  }
}

// ============================================================
// 11.4 扩展类型 (Extension Types)
// ============================================================
extension type UserId(int id) {
  bool get isValid => id > 0;
  String get display => 'UserId($id)';
}

extension type Email(String value) {
  bool get isValid => value.contains('@') && value.contains('.');
  String get domain => value.split('@').last;
  String get display => 'Email($value)';
}

// 透明扩展类型：暴露底层类型的接口
extension type Meters(double value) implements double {
  Meters operator +(Meters other) => Meters(value + other.value);
  String get display => '${value.toStringAsFixed(1)}m';
}

void main() {
  print('=' * 60);
  print('第11章 枚举与扩展 (Enum & Extension) 示例');
  print('=' * 60);

  // ----------------------------------------------------------
  // 11.1 基础枚举
  // ----------------------------------------------------------
  print('\n--- 11.1 基础枚举 ---');

  // index 和 name
  print('Color.red → index: ${Color.red.index}, name: ${Color.red.name}');
  print('Color.blue → index: ${Color.blue.index}, name: ${Color.blue.name}');

  // values 列表
  print('\n所有颜色:');
  for (var color in Color.values) {
    print('  ${color.name} (index: ${color.index})');
  }

  // switch 穷尽检查
  String describeColor(Color color) {
    return switch (color) {
      Color.red => '红色：热情奔放 🔴',
      Color.green => '绿色：生机盎然 🟢',
      Color.blue => '蓝色：沉静深邃 🔵',
    };
  }

  print('\nswitch 穷尽检查:');
  for (var color in Color.values) {
    print('  ${color.name} → ${describeColor(color)}');
  }

  // 方向枚举的 switch
  String getArrow(Direction dir) {
    return switch (dir) {
      Direction.north => '↑ 北',
      Direction.south => '↓ 南',
      Direction.east => '→ 东',
      Direction.west => '← 西',
    };
  }

  print('\n方向:');
  for (var dir in Direction.values) {
    print('  ${getArrow(dir)}');
  }

  // ----------------------------------------------------------
  // 11.2 增强枚举
  // ----------------------------------------------------------
  print('\n--- 11.2 增强枚举 ---');

  print('\n行星信息:');
  for (var planet in Planet.values) {
    print('  ${planet.describe()}');
  }

  // Comparable 排序
  var sorted = Planet.values.toList()..sort();
  print('\n按重力排序:');
  for (var planet in sorted) {
    print('  ${planet.name}: ${planet.gravity} m/s²');
  }

  // 表面积
  print('\n表面积最大的行星:');
  var largest = Planet.values.toList()
    ..sort((a, b) => b.surfaceArea.compareTo(a.surfaceArea));
  for (var planet in largest.take(3)) {
    print('  ${planet.name}: ${planet.surfaceArea.toStringAsFixed(0)} 万km²');
  }

  // HttpStatus 枚举
  print('\nHTTP 状态码:');
  for (var status in HttpStatus.values) {
    var category = status.isSuccess
        ? '✅ 成功'
        : status.isClientError
            ? '⚠️ 客户端错误'
            : '❌ 服务端错误';
    print('  $status [$category]');
  }

  // ----------------------------------------------------------
  // 11.3 扩展方法
  // ----------------------------------------------------------
  print('\n--- 11.3 扩展方法 ---');

  // String 扩展
  print('\nString 扩展方法:');
  print('  "hello@world.com".isEmail = ${"hello@world.com".isEmail}');
  print('  "not-email".isEmail = ${"not-email".isEmail}');
  print('  "hello".capitalize = ${"hello".capitalize}');
  print('  "dart is great".words = ${"dart is great".words}');
  print('  "Hello World Dart".truncate(10) = ${"Hello World Dart".truncate(10)}');
  print('  "ha".repeatJoin(3, "-") = ${"ha".repeatJoin(3, "-")}');

  // int 扩展
  print('\nint 扩展方法:');
  print('  1.ordinal = ${1.ordinal}');
  print('  2.ordinal = ${2.ordinal}');
  print('  3.ordinal = ${3.ordinal}');
  print('  11.ordinal = ${11.ordinal}');
  print('  21.ordinal = ${21.ordinal}');
  print('  5.isBetween(1, 10) = ${5.isBetween(1, 10)}');
  print('  15.isBetween(1, 10) = ${15.isBetween(1, 10)}');

  // times 回调
  print('\n  3.times 回调:');
  3.times((i) => print('    第 ${i + 1} 次执行'));

  // 文件大小
  print('\n  文件大小转换:');
  print('    512 → ${512.fileSize}');
  print('    1536 → ${1536.fileSize}');
  print('    2621440 → ${2621440.fileSize}');

  // List 扩展
  print('\nList 扩展方法:');

  var names = ['Charlie', 'Alice', 'Bob', 'David'];
  print('  原始列表: $names');
  print('  sortedBy(长度): ${names.sortedBy((s) => s.length)}');
  print('  sortedBy(字母): ${names.sortedBy((s) => s)}');

  var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  print('  safeGet(2): ${numbers.safeGet(2)}');
  print('  safeGet(99): ${numbers.safeGet(99)}');
  print('  chunked(3): ${numbers.chunked(3)}');
  print('  chunked(4): ${numbers.chunked(4)}');

  // ----------------------------------------------------------
  // 11.4 扩展类型
  // ----------------------------------------------------------
  print('\n--- 11.4 扩展类型 ---');

  // UserId
  var userId = UserId(42);
  print('userId = ${userId.display}');
  print('userId.id = ${userId.id}');
  print('userId.isValid = ${userId.isValid}');

  var invalidId = UserId(-1);
  print('invalidId.isValid = ${invalidId.isValid}');

  // Email
  var email = Email('dart@google.com');
  print('\nemail = ${email.display}');
  print('email.isValid = ${email.isValid}');
  print('email.domain = ${email.domain}');

  var badEmail = Email('not-an-email');
  print('badEmail.isValid = ${badEmail.isValid}');

  // Meters（透明扩展类型）
  var distance1 = Meters(100.0);
  var distance2 = Meters(50.5);
  var total = distance1 + distance2;
  print('\n距离: ${distance1.display} + ${distance2.display} = ${total.display}');

  // 透明性：可以赋值给 double
  double rawValue = distance1;
  print('透明性: Meters(100.0) 可赋值给 double → $rawValue');

  // ----------------------------------------------------------
  // 11.5 综合示例：枚举 + 扩展方法
  // ----------------------------------------------------------
  print('\n--- 11.5 综合示例 ---');

  // 用扩展方法处理行星名称
  print('\n行星名称处理:');
  for (var planet in Planet.values) {
    var desc = planet.name.capitalize;
    print('  $desc → ${desc.truncate(4)} '
        '(${planet.gravity}m/s², ${planet.moons}颗卫星)');
  }

  print('\n${'=' * 60}');
  print('第11章示例运行完毕！');
  print('=' * 60);
}
