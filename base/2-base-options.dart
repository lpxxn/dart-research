void Main() {
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
}
