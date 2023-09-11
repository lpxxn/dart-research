// every class implicitly defines an interface containing all the instance members of the class
// and any interfaces it implements.
// interface can implement, but can't extend
// A Person. The implicit interface contains greet().
class Person {
  // In the interface, but visible only in this library.
  final String _name;

  // In the interface, visible in all libraries.
  int age;

  Person(this._name, this.age);

  String greet(String who) => 'Hello, $who. I am $_name, $age years old.';
}

class Impostor implements Person {
  @override
  int age = 10;

  @override
  String greet(String who) {
    return 'Hi $who. Do you know who I am?';
  }

  Impostor() {
    print('Impostor constructor');
  }

  @override
  String get _name => 'implementation of _name';
}

String greetBob(Person person) => person.greet('Bob');

void main(List<String> args) {
  print(greetBob(Person('Kathy', 10)));
  print(greetBob(Impostor()));
}

class Person2 {
  String firstName;
  Person2.fromJson(this.firstName) {
    print('in Person');
  }
}

class Employee extends Person2 {
  // Person does not have a default constructor;
  // you must call super.fromJson(data).
  Employee.fromJson(String data) : super.fromJson(data) {
    print('in Employee');
  }
}
