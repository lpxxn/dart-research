void main(List<String> args) {
  const a = 'A', b = 'B';
  var obj = [a, b];
  // get obj type
  print(obj.runtimeType);
  switch (obj) {
    case [a, b]: // matches if obj[0] == a && obj[1] == b
      print('a: $a, b: $b'); // print result is a, b
      break;
    case [b, a]:
      print('b, a');
      break;
    default:
      print('default');
  }

  // 解构
  var list = [1, 2, 3];
  var [a1, b1, c1] = list;
  print('a1: $a1, b1: $b1 c1: $c1');

  switch (list) {
    case [
        1 || 2,
        var c2
      ]: // matches if list[0] == 1 or 2, and stores list[1] in c2, if list length > 2, will not match
      print('c2: $c2');
      break;
    case [
        1 || 2,
        var c2,
        var d2
      ]: // matches if list[0] == 1 or 2 if list length = 3, and stores list[1] in c2, list[2] in d2
      print('c2: $c2, d2: $d2');
      break;
  }

  var (a3, [b3, c3]) = ('str', [1, 2]);
  print('a: $a3, b: $b3, c: $c3');

  var json = {
    'user': ['Lily', 13]
  };
  var {'user': [name, age]} = json;
  print('name: $name, age: $age, age type: ${age.runtimeType}');

  if (json case {'user': [String name, int age]}) {
    print('name: $name, age: $age, age type: ${age.runtimeType}');
  }
  {
    // rest element
    // ...  rest element, which allows matching lists of arbitrary length.
    var list = [1, 2, 3, 4, 5];
    var [a, b, ...rest, d] = list;
    print('a: $a, b: $b, rest: $rest, d: $d');

    var [x, y, ..., z] = list;
    print('x: $x, y: $y, z: $z');
  }
}
//https://dart.cn/language/patterns