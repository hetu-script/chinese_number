import 'package:chinese_number/chinese_number.dart';

void main() {
  final str = '拾壹万叁仟肆佰贰拾壹';
  print(ChineseNumber.tryParse(str));

  final n = 214323232003;
  print(n.toSimplifiedChineseNumber());

  final f = 3.1415926;
  print(f.toSimplifiedChineseNumber());
}
