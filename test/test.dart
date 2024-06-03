import 'package:chinese_number/chinese_number.dart';
// import 'package:characters/characters.dart';

void main() {
  // final str = 'hello, 000.5万一千...33';
  // final iter = str.characters.iterator;
  // while (iter.moveNext()) {
  //   if (ChineseNumber.isPartOfChineseNumber(iter)) {
  //     print(iter.current);
  //   }
  // }
  final number1 = 133666;
  final result = number1.toSimplifiedChineseNumber();
  print(result);
}
