class ShoppingCart {
  List<double> _prices = [];

  // Add a "total" getter here:
  double get totle =>
      _prices.fold(0, (previousValue, element) => previousValue + element);

  // Add a "prices" setter here:
  set price(List<double> value) {
    if (value.any((element) => element < 0)) {
      // throw new ArgumentError('Negative prices are not allowed.');
      throw new InvalidPriceException();
    }
    _prices = value;
  }
}

class InvalidPriceException {}

/*
私有 = 以 _ 开头的标识符。
如果你使用 library 指令显式声明，或者通过 part of / part 合并多个文件，那多个文件可以属于同一个库。
私有成员只能在同一个库内部访问，其他库（即其他 .dart 文件，除非是 part）无法访问。
*/
