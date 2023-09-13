enum Vehicle implements Comparable<Vehicle> {
  car(tires: 4, passengers: 5, carbonPerKilometer: 150),
  bus(tires: 6, passengers: 40, carbonPerKilometer: 100),
  bicycle(tires: 2, passengers: 1, carbonPerKilometer: 0);

  const Vehicle(
      {required this.tires,
      required this.passengers,
      required this.carbonPerKilometer});

  final int tires;
  final int passengers;
  final int carbonPerKilometer;

  @override
  int compareTo(Vehicle other) =>
      this.carbonPerKilometer - other.carbonPerKilometer;
}

void main(List<String> args) {
  print(Vehicle.car);
  print(Vehicle.bus);
  print(Vehicle.bicycle);
  print(Vehicle.car.compareTo(Vehicle.bus));
  print(Vehicle.car.compareTo(Vehicle.bicycle));
  print(Vehicle.bus.compareTo(Vehicle.bicycle));
}
