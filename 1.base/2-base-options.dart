void main() {
// 可空类型
// ??= 赋值运算符，如果变量为null，则赋值
  String? name = 'Jane';
  String? address = null;
  int? a; // = null
  print(1 ?? 3); // <-- Prints 1.
  print(null ?? 12); // <-- Prints 12.

  a ??= 5;
  print(a); // <-- Still prints 3.

  /*
  Conditional property access
  To guard access to a property or method of an object that might be null, put a question mark (?) before the dot (.):

  myObject?.someProperty
  The preceding code is equivalent to the following:

  (myObject != null) ? myObject.someProperty : null
  You can chain multiple uses of ?. together in a single expression:

  myObject?.someProperty?.someMethod()
  The preceding code returns null (and never calls someMethod()) if either myObject or myObject.someProperty is null.
  */

  // set
  final aListOfInts = <int>[
    1,
    23,
  ];
  print('aListOfInts: $aListOfInts');
  final aSetOfInts = <int>{1, 2, 1};
  print('aSetOfInts: $aSetOfInts');
  final aMapOfIntToDouble = <int, double>{1: 2.0, 3: 4.0};
  print('aMapOfIntToDouble: $aMapOfIntToDouble');
  final aListOfStrings = ['one', 'two'];
  print('aListOfStrings: $aListOfStrings');
  bool hasEmpty = aListOfStrings.any((element) => element.isEmpty);
  print('hasEmpty: $hasEmpty');
  List<String>? aListOfStrings2 = null;
  print(aListOfStrings2?.length);
}
