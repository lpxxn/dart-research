class Television {
  void turnOn() {
    print('Turn on');
  }
}

class SmartTelevision extends Television {
  @override
  void turnOn() {
    super.turnOn();
    print('Welcome to Smart TV');
  }
}

void main(List<String> args) {
  var tv = SmartTelevision();
  tv.turnOn();
}
