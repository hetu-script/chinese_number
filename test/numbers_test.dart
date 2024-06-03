import 'package:test/test.dart';
import 'package:chinese_number/chinese_number.dart';

void main() {
  group('Chinese number to Dart number test:', () {
    test('simplified chinsese numbers', () {
      final number = ChineseNumber.tryParse('两百四十五');
      expect(number, 245);
    });
    test('triaditional Chinese numbers', () {
      final number = ChineseNumber.tryParse('拾壹万叁仟肆佰贰拾壹');
      expect(number, 113421);
    });
    test('triaditional Chinese numbers with no radix', () {
      final number = ChineseNumber.tryParse('二零零二');
      expect(number, 2002);
    });
    test('mixed Chinese numbers with arabic numbers', () {
      final number = ChineseNumber.tryParse('2.4万');
      expect(number, 24000);
    });
  });
  group('Dart number to Chinese numbers test:', () {
    test('integer to Simplified Chinese numbers', () {
      final result = 13.374.toSimplifiedChineseNumber();
      expect(result, '十三点三七四');
    });
    test('integer to Simplified Chinese numbers', () {
      final result = 100001.toSimplifiedChineseNumber();
      expect(result, '十万零一');
    });
    final number2 = 214323232003;
    test('integer to Simplified Chinese numbers', () {
      final result = number2.toSimplifiedChineseNumber();
      expect(result, '二千一百四十三亿二千三百二十三万二千零三');
    });
    // test('integer to Formal Simplified Chinese numbers', () {
    //   final result = number2.toFormalSimplifiedChineseNumber();
    //   expect(result, '贰仟壹佰肆拾叁亿贰仟叁佰贰拾叁万贰仟零叁');
    // });
    test('integer to Traditional Chinese numbers', () {
      final result = number2.toTraditionalChineseNumber();
      expect(result, '貳仟壹佰肆拾叁億貳仟叁佰貳拾叁萬貳仟零叁');
    });
    final float = 3.1415926;
    test('double to Simplified Chinese numbers', () {
      final result = float.toSimplifiedChineseNumber();
      expect(result, '三点一四一五九二六');
    });
    // test('double to Formal Simplified Chinese numbers', () {
    //   final result = float.toFormalSimplifiedChineseNumber();
    //   expect(result, '叁点壹肆壹伍玖贰陆');
    // });
    test('double to Traditional Chinese numbers', () {
      final result = float.toTraditionalChineseNumber();
      expect(result, '叁點壹肆壹伍玖貳陸');
    });
  });
}
