import '1string_apis.dart';
import '2string_apis.dart' as string_apis2;

void main(List<String> args) {
  //print('42'.parseInt());
  print(NumberParsing('42').parseInt());
  print(string_apis2.NumberParsing('42').parseInt());
  print('42.42'.parseDouble());
  print('a'.padLeft(3));
}
