/*
Dart has two kinds of function parameters: positional and named. 
*/
//With Dart, you can make these positional parameters optional by wrapping them in brackets:
int sumUpToFive(int a, [int? b, int? c]) {
  print('$a ${b ?? ''} ${c ?? ''}');
  return a + (b ?? 0) + (c ?? 0);
}

// optional positional parameters are always last in a function's parameter list.
// their default value is null unless you provide another default value.
int sumUpToFive2(int a, [int b = 2, int c = 3]) {
  return a + b + c;
}

// named parameters
// using a curly brace sync at the end of the parameter list, you can define parameters that  have names.
// named parameters are optional unless they're marked as required.
void printName(String firstName,
    {String? lastName, required String title, int age = 18}) {
  print('$title $firstName ${lastName ?? ''} $age');
}

void main() {
  print('sumUpToFive ${sumUpToFive(1)}');
  print('sumUpToFive ${sumUpToFive(1, 2, 3)}');

  print('sumUpToFive2 ${sumUpToFive2(1)}');

  printName('Jane', title: 'Ms.', age: 11);
  printName('Jane', title: 'Ms.', lastName: 'Doe');

  var obj = MyDataObject();
  print('obj: $obj');
  var obj2 = obj.copyWith(anInt: 2);
  print('obj2: $obj2');
}

class MyDataObject {
  final int anInt;
  final String aString;
  final double aDouble;

  MyDataObject({this.anInt = 1, this.aString = 'a', this.aDouble = 3.0});

  MyDataObject copyWith({int? anInt, String? aString, double? aDouble}) {
    return MyDataObject(
      anInt: anInt ?? this.anInt,
      aString: aString ?? this.aString,
      aDouble: aDouble ?? this.aDouble,
    );
  }

  @override
  String toString() {
    return 'MyDataObject{anInt: $anInt, aString: $aString, aDouble: $aDouble}';
  }
}
