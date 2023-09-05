class ShoppingCart {
  List<double> _prices = [];

  // Add a "total" getter here:
  double get totle => _prices.fold(0, (previousValue, element) => previousValue + element)

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