// Cascades
import 'dart:developer';

class BigObject {
  int anInt = 0;
  String aString = '';
  List<double> aList = [];
  bool _done = false;
  void allDone() {
    _done = true;
  }

  @override
  String toString() {
    return 'BigObject{anInt: $anInt, aString: $aString, aList: $aList, _done: $_done}';
  }
}

BigObject fillBigObject(BigObject obj) {
  return obj
    ..anInt = 1
    ..aString = 'String'
    ..aList.add(3.0)
    ..aList.add(4.0)
    ..allDone();
}

void main(List<String> args) {
  BigObject? b;
  b = BigObject();
  var aNullValue = fillBigObject(b);
  print('aNullValue: ${aNullValue}');
}

/*
myObject..someMethod()
Although it still invokes someMethod() on myObject, the result of the expression isn’t the return value—it’s a reference to myObject!

Using cascades, you can chain together operations that would otherwise require separate statements. For example, consider the following code, which uses the conditional member access operator (?.) to read properties of button if it isn’t null:

var button = querySelector('#confirm');
button?.text = 'Confirm';
button?.classes.add('important');
button?.onClick.listen((e) => window.alert('Confirmed!'));
button?.scrollIntoView();
To instead use cascades, you can start with the null-shorting cascade (?..), which guarantees that none of the cascade operations are attempted on a null object. Using cascades shortens the code and makes the button variable unnecessary:

querySelector('#confirm')
  ?..text = 'Confirm'
  ..classes.add('important')
  ..onClick.listen((e) => window.alert('Confirmed!'))
  ..scrollIntoView();
*/