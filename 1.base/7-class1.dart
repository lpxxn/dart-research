// 在构造方法中使用 this
class MyColor {
  int red;
  int green;
  MyColor(this.red, this.green);
}

// 命名参数
class MyColor2 {
  int red;
  int green;
  MyColor2({required this.red, this.green = 0});
}

// 在构造函数之前初始化一些变量
class MyColor3 {
  int red;
  int green;
  MyColor3(int red, int green)
      : red = red,
        green = green;
  // 命名构造方法
  MyColor3.defaultValue()
      : red = 0,
        green = 0;
}
// final myColor = MyColor3.defaultValue();

// 工厂构造方法
// 使用 factory 创建工厂构造方法
class Square extends Shape {}

class Circle extends Shape {}

class Shape {
  Shape();

  factory Shape.fromTypeName(String typeName) {
    if (typeName == 'square') return Square();
    if (typeName == 'circle') return Circle();

    throw ArgumentError('Unknown typeName: $typeName');
  }
}

void main(List<String> args) {
  if (args.length > 0) {
    print('Hello ${args[0]}');
  }

  var myColor = MyColor(1, 2);
  print(myColor.red);

  var myColor3 = MyColor3.defaultValue();
  print(myColor3.red);

  var shape = Shape.fromTypeName('square');
  print(shape);
  // check shape is Square
  print(shape is Square);
}

// 重定向构造方法
// 重定向方法没有主体，它在冒号（:）之后调用另一个构造方法。
class MyColor4 {
  int red;
  int green;
  MyColor4(this.red, this.green);
  MyColor4.black() : this(1, 2);

  MyColor4.black2(this.red) : this.green = 2;

  MyColor4.black3() : this.black2(1);
}

/*
Const 构造方法
如果你的类生成的对象永远都不会更改，则可以让这些对象成为编译时常量。为此，请定义 const 构造方法并确保所有实例变量都是 final 的。
*/
class ImmutablePoint {
  static final ImmutablePoint origin = const ImmutablePoint(0, 0);
  final double x, y;
  const ImmutablePoint(this.x, this.y);
}
