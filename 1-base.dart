

void main() {
  var name = "hello word";
  // declare a string type value a variable
  String name1 = "hello word";
  // declare a int type value, and assign to 1234556677
  int age = 1234556677;

  print("print ${name}! age $age");

  example1();

  //record
  (String, int) record;
  record = ("hello", 123);
  print(record);
  print(record.$1);

  ({String a, int b}) record1;
  //record1 = ("hello", 123);
  record1 =(a: "hello", b: 123);
  print(record1);
  print(record1.a);

  (int a, int b) swap((int, int) record) {
    var (a, b) = record;
    return (b, a);
  }
  var a = swap((1, 2));
  print('a: $a b: ${a.$2}');
}

example1() {
  nested1(fn) {
    print(fn);
  }

  nested1(() => print("nested func")); // Closure: () => void
  nested1("an");
}
