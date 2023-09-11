// mixins are a way of reusing a class's code in multiple class hierarchies.
// mixins 是一种在多个类层次结构中重用类代码的方法。
// mixins can not declare a constructor.
// mixins can not extend a class or another mixin.
// like go, use composition more, use inheritance less.
mixin Walker {
  void walker() {
    print('I can walk');
  }
}

mixin Flyer {
  void flyer() {
    print('I can fly');
  }
}

// to use mixin, use the `with` keyword followed by one or more mixin name:
class Cat with Walker {
  void meow() {
    print('meow');
  }
}

class Bird with Walker, Flyer {
  void chirp() {
    print('chirp');
  }
}

void main(List<String> args) {
  var cat = Cat();
  cat.meow();
  cat.walker();

  var bird = Bird();
  bird.chirp();
  bird.walker();
  bird.flyer();
}
