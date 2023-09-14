String creteOrderMessage() {
  var order = fetchUserOrder();
  print('order type: ${order.runtimeType}');
  order.whenComplete(() => print('complete'));
  order.then(
      (value) => print('~~~:order type: ${value.runtimeType} value: $value'));
  var b = await Future.wait<String>([order]);
  return 'Your order is: $order b: $b';
}

Future<String> fetchUserOrder() async {
  return await Future.delayed(Duration(seconds: 2), () => 'Large Latte');
}

void main(List<String> args) {
  print(creteOrderMessage());
  print('end main');
}
