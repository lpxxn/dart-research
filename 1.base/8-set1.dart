void main() {
  var list = [1, 2, 3];
  var list2 = [0, ...list];
  assert(list2.length == 4);
  print(list2);

  List<int>? listNull;
  var list3 = [0, ...?listNull];
  assert(list3.length == 1);
  print(list3);

  // control flow collections
  // 可以使用 if 和 for 语句来创建集合
  var nav = ['Home', 'Furniture', 'Plants', if (true) 'Outlet'];
  print(nav);
  var nav2 = [
    'Home',
    'Furniture',
    'Plants',
    if (list3.length == 1) 'list3 length 1',
    for (var i in list) 'Outlet $i'
  ];
  print(nav2);
}
