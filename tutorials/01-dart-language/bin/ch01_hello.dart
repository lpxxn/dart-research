void main() {
  // 1. Hello World
  print('Hello, Dart!');

  // 2. 字符串插值
  var name = 'Dart';
  var version = 3.10;
  print('Welcome to $name $version');
  print('1 + 2 = ${1 + 2}');

  // 3. 多行字符串
  var multiLine = '''
这是一个
多行字符串
''';
  print(multiLine);

  // 4. main 函数参数
  print('程序正常结束');
}
