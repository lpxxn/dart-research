void main(List<String> args) {
  print('start main');
  Future.delayed(Duration(seconds: 3), () {
    print('start Future.delayed');
    return 'aaaa';
  });
  Future(() {
    print('start Future.sync');

    return 'bbbb';
  }).then((value) {
    print('value: $value');
  });
  print('end main');
}

Future<String> getUserOrder() {
  return Future.delayed(Duration(seconds: 2), () => 'Large Latte');
}
