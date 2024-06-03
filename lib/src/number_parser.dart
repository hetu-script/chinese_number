import 'package:characters/characters.dart';

final _kSingleArabicNumberRegex = RegExp(r'\d');

const _kPartOfChineseNumber = {
  '零',
  '〇',
  '壹',
  '一',
  '貳',
  '贰',
  '二',
  '两',
  '兩',
  '倆',
  '俩',
  '叁',
  '三',
  '仨',
  '肆',
  '四',
  '伍',
  '五',
  '陸',
  '陆',
  '六',
  '柒',
  '七',
  '捌',
  '八',
  '玖',
  '九',
  '拾',
  '十',
  '廿',
  '卅',
  '卌',
  '佰',
  '百',
  '仟',
  '千',
  '萬',
  '万',
  '億',
  '亿',
};

/// Chinese number digits and their Arabic equivalent.
const _kChineseNumberDigits = {
  '零': 0,
  '〇': 0,
  '壹': 1,
  '一': 1,
  '貳': 2,
  '贰': 2,
  '二': 2,
  '两': 2,
  '兩': 2,
  '倆': 2,
  '俩': 2,
  '叁': 3,
  '三': 3,
  '仨': 3,
  '肆': 4,
  '四': 4,
  '伍': 5,
  '五': 5,
  '陸': 6,
  '陆': 6,
  '六': 6,
  '柒': 7,
  '七': 7,
  '捌': 8,
  '八': 8,
  '玖': 9,
  '九': 9,
};

/// Chinese number postfix and their Arabic equivalent.
const _kChineseNumberPostfix = {
  '拾': 10,
  '十': 10,
  '廿': 20,
  '卅': 30,
  '卌': 40,
  '佰': 100,
  '百': 100,
  '仟': 1000,
  '千': 1000,
  '萬': 10000,
  '万': 10000,
  '億': 100000000,
  '亿': 100000000,
};

const _kGreaterThanWanPostfixCharacters = ['萬', '万', '億', '亿'];

/// Converter for Chinese numbers.
class ChineseNumber {
  static bool isPartOfChineseNumber(CharacterRange source) {
    if (source.current == '.') {
      if (source.charactersAfter.isNotEmpty) {
        if (_kSingleArabicNumberRegex.hasMatch(source.charactersAfter.first)) {
          return true;
        }
        return false;
      }
      return false;
    } else if (_kSingleArabicNumberRegex.hasMatch(source.current) ||
        _kPartOfChineseNumber.contains(source.current)) {
      return true;
    }
    return false;
  }

  /// Returns the result of the conversion of Chinese number into a Dart number.
  static num? tryParse(String source) {
    if (source.isEmpty) {
      return null;
    }
    // Just a plain Arabic number was provided. Don't do any complicated stuff.
    final numParseResult = num.tryParse(source);
    if (numParseResult != null) {
      return numParseResult;
    }
    // If the string does not contain Chinese numbers (like "345 abc"), we don't
    // have any business here:
    var hasAtLeastOneChineseNumber = false;
    for (final character in source.characters) {
      if (_kPartOfChineseNumber.contains(character)) {
        hasAtLeastOneChineseNumber = true;
        break;
      }
    }
    if (!hasAtLeastOneChineseNumber) {
      return numParseResult;
    }
    // Here we will try to parse the leading part before the 萬 in numbers like
    // 一百六十八萬, converting it into 168萬. The rest of the code will take care
    // of the subsequent conversion. This also work for numbers like 168萬5.
    final postfixAtTheEnd = _iteratorAtGreaterThanWanPostfixCharacter(source);
    num leadingNumber;
    if (postfixAtTheEnd != null) {
      // If the number begins with Arabic numerals, parse and remove them first.
      // Example: 83萬. This number will be multiplied by the remaining part at
      // the end of the function.
      // We're using parseFloat here instead of parseInt in order to have limited
      // support for decimals, e.g. "3.5萬"
      final stringBefore = postfixAtTheEnd.stringBefore;
      if (stringBefore.isNotEmpty) {
        leadingNumber = ChineseNumber.tryParse(stringBefore)!;
      } else {
        leadingNumber = 1; // for cases like 萬五
      }
      source = postfixAtTheEnd.current + postfixAtTheEnd.stringAfter;
    } else {
      leadingNumber = 0;
    }
    // Now parse the actual Chinese, character by character:
    num result = 0;
    var pairs = <List<num>>[];
    var currentPair = <num>[];
    for (final character in source.characters) {
      if (_kSingleArabicNumberRegex.hasMatch(character)) {
        // Just a normal arabic number. Add it to the pair.
        currentPair.add(int.tryParse(character)!);
      } else if (_kChineseNumberDigits.containsKey(character)) {
        final arabic = _kChineseNumberDigits[character]!; // e.g. for '三', get 3
        if (currentPair.isNotEmpty) {
          // E.g. case like 三〇〇三 instead of 三千...
          // In this case, just concatenate the string, e.g. "2" + "0" = "20"
          currentPair.first = int.parse('${currentPair.first}$arabic');
        } else {
          currentPair.add(arabic);
        }
      } else if (_kChineseNumberPostfix.containsKey(character)) {
        if (currentPair.length == 2) {
          pairs.add(currentPair);
          currentPair = [];
        }
        final arabic =
            _kChineseNumberPostfix[character]!; // e.g. for '萬', get 10000
        currentPair.add(arabic);
        if (pairs.isEmpty && currentPair.length == 1) {
          // This is a case like 2千萬", where the first character will be 千,
          // because "2" was cut off and stored in the leadingNumber:
          currentPair.add(1);
          pairs.add(currentPair);
          currentPair = [];
        }
        // accumulated two parts of a pair which will be multiplied, e.g. 二 + 十
        else {
          if (currentPair.length == 1) {
            if (_kGreaterThanWanPostfixCharacters.contains(character)) {
              // For cases like '萬' in '一千萬' - multiply everything we had
              // so far (like 一千) by the current digit (like 萬).
              num numbersSoFar = 0;
              for (final pair in pairs) {
                numbersSoFar += pair.first * pair.last;
              }
              // The leadingNumber is for cases like 1000萬.
              if (leadingNumber > 0) {
                numbersSoFar *= leadingNumber;
                leadingNumber = 0;
              }
              // Replace all previous pairs with the new one:
              pairs = [
                [numbersSoFar, arabic]
              ]; // e.g. [[1000, 10000]]
              currentPair = [];
            } else {
              // For cases like 十 in 十二:
              currentPair.add(1);
              pairs.add(currentPair);
              currentPair = [];
            }
          } else if (currentPair.length == 2) {
            pairs.add(currentPair);
            currentPair = [];
          }
        }
      }
    }
    // If number ends in 1-9, e.g. 二十二, we have one number left behind -
    // add it too and multiply by 1:
    if (currentPair.length == 1) {
      currentPair.add(1);
      pairs.add(currentPair);
    }
    if (pairs.isNotEmpty && leadingNumber > 0) {
      pairs.first.first *= leadingNumber; // e.g. 83萬 => 83 * [10000, 1]
    }
    // Multiply all pairs:
    for (final pair in pairs) {
      result += pair.first * pair.last;
    }
    return result;
  }
}

/// Checks whether the last number in the source string is a [萬万億亿], or
/// another number. Ignores non-number characters at the end of the string
/// such as dots, letters etc.
CharacterRange? _iteratorAtGreaterThanWanPostfixCharacter(String value) {
  final charIter = value.characters.iteratorAtEnd;
  while (charIter.moveBack()) {
    if (_kGreaterThanWanPostfixCharacters.contains(charIter.current)) {
      // We found it - the string ends with a maan-like character:
      return charIter;
    }
  }
  // Fallback case:
  return null;
}

/// Simplified Chinese number digits.
const _kSimplifiedChineseNumberDigits = [
  '零',
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
];

const _kSimplifiedChineseNumberUnits = {
  1: '十',
  2: '百',
  3: '千',
};

const _kSimplifiedChineseNumberUnits2 = {
  4: '万',
  8: '亿',
  12: '万亿',
  16: '亿亿',
  20: '万亿亿',
  24: '亿亿亿',
  28: '万亿亿亿',
  32: '亿亿亿亿',
  36: '万亿亿亿亿',
  40: '亿亿亿亿亿',
  44: '万亿亿亿亿亿',
};

const _kSimplifiedChinesePointCharacter = '点';

/// Formal simplified Chinese number digits.
const _kFormalSimplifiedChineseNumberDigits = [
  '零',
  '壹',
  '贰',
  '叁',
  '肆',
  '伍',
  '陆',
  '柒',
  '捌',
  '玖',
];

const _kFromalSimplifiedChineseNumberUnits = {
  1: '拾',
  2: '佰',
  3: '仟',
};

const _kFromalSimplifiedChineseNumberUnits2 = {
  4: '万',
  8: '亿',
  12: '万亿',
  16: '亿亿',
  20: '万亿亿',
  24: '亿亿亿',
  28: '万亿亿亿',
  32: '亿亿亿亿',
  36: '万亿亿亿亿',
  40: '亿亿亿亿亿',
  44: '万亿亿亿亿亿',
};

const _kFormalSimplifiedChinesePointCharacter = '点';

/// Simplified Chinese number digits.
const _kTraditionalChineseNumberDigits = [
  '零',
  '壹',
  '貳',
  '叁',
  '肆',
  '伍',
  '陸',
  '柒',
  '捌',
  '玖',
];

const _kTraditionalChineseNumberUnits = {
  1: '拾',
  2: '佰',
  3: '仟',
};

const _kTraditionalChineseNumberUnits2 = {
  4: '萬',
  8: '億',
  12: '兆',
  16: '京',
  20: '垓',
  24: '秭',
  28: '穰',
  32: '溝',
  36: '澗',
  40: '正',
  44: '載',
};

const _kTraditionalChinesePointCharacter = '點';

String _toChineseNumber(
  num value,
  List<String> digits,
  Map<int, String> units,
  Map<int, String> units2, {
  bool omitInitialOne = true,
}) {
  String result = '';
  List<String> reversedIntStr = value.toString().split('').reversed.toList();
  int zero = 0;
  String unit2 = '';
  for (int i = 0; i < reversedIntStr.length; i++) {
    int current = int.parse(reversedIntStr[i]);
    String? next;
    if ((i + 1) < reversedIntStr.length) {
      next = reversedIntStr[i + 1];
    }

    if (_kSimplifiedChineseNumberUnits2.containsKey(i)) {
      unit2 = units2[i]!;
    }

    if (current == 0) {
      zero = zero + 1;
      continue;
    }

    if (zero != 0 && result.isNotEmpty && !units2.containsValue(result)) {
      zero = 0;
      result = unit2 + digits[0] + result;
      unit2 = '';
    }

    final unit = i % 4;
    if (unit != 0) {
      if (omitInitialOne &&
          current == 1 &&
          unit == 1 &&
          (next == '0' || next == null)) {
        result = units[unit]! + result;
      } else {
        result = digits[current] + units[unit]! + result;
      }
    } else {
      result = digits[current] + unit2 + result;
      unit2 = '';
    }
  }
  return result;
}

String _toFloatChineseNumber(
  num value,
  List<String> digits,
  Map<int, String> units,
  Map<int, String> units2,
  String pointCharacter, {
  bool omitInitialOne = true,
}) {
  // 小數點分開
  List numStrList = value.toString().split('.');
  String result = _toChineseNumber(
      int.tryParse(numStrList.first)!, digits, units, units2,
      omitInitialOne: omitInitialOne);
  if (numStrList.length > 1) {
    String rawFloatStr = numStrList.last;
    final floatStr = _toChineseNumberWithOutRadix(rawFloatStr, digits);
    result += pointCharacter + floatStr;
  }
  return result;
}

String _toChineseNumberWithOutRadix(String source, List<String> digits) {
  String floatStr = '';
  List<String> rawFloatStrList = source.split('');
  for (int i = 0; i < rawFloatStrList.length; i++) {
    int c = int.parse(rawFloatStrList[i]);
    floatStr = floatStr + digits[c];
  }
  return floatStr;
}

extension ChineseNumberParser on num {
  /// convert to chinese numbers written in simplified characters.
  ///
  /// 转换为简体中文数字。默认情况下，数字最左边的“一十”会简写为“十”，例如“13”会转写为“十三”，而不是“一十三”。
  String toSimplifiedChineseNumber({bool omitInitialOne = true}) {
    if (this is int) {
      return _toChineseNumber(
        this,
        _kSimplifiedChineseNumberDigits,
        _kSimplifiedChineseNumberUnits,
        _kSimplifiedChineseNumberUnits2,
        omitInitialOne: omitInitialOne,
      );
    } else {
      return _toFloatChineseNumber(
        this,
        _kSimplifiedChineseNumberDigits,
        _kSimplifiedChineseNumberUnits,
        _kSimplifiedChineseNumberUnits2,
        _kSimplifiedChinesePointCharacter,
        omitInitialOne: omitInitialOne,
      );
    }
  }

  /// convert to chinese numbers written in traditional characters.
  ///
  /// 转换为繁体中文数字。默认情况下，数字最左边的“壹拾”会简写为“拾”，例如“13”会转写为“拾叁”，而不是“壹拾叁”。
  String toTraditionalChineseNumber({bool omitInitialOne = true}) {
    if (this is int) {
      return _toChineseNumber(
        this,
        _kTraditionalChineseNumberDigits,
        _kTraditionalChineseNumberUnits,
        _kTraditionalChineseNumberUnits2,
        omitInitialOne: omitInitialOne,
      );
    } else {
      return _toFloatChineseNumber(
        this,
        _kTraditionalChineseNumberDigits,
        _kTraditionalChineseNumberUnits,
        _kTraditionalChineseNumberUnits2,
        _kTraditionalChinesePointCharacter,
        omitInitialOne: omitInitialOne,
      );
    }
  }

  /// convert to formal numbers used in accounting or contracts.
  ///
  /// 转换为会计或合同场合所用的大写数字，注意这里不会处理“元整”和“角分厘”等。
  String toFormalSimplifiedChineseNumber() {
    if (this is int) {
      return _toChineseNumber(
        this,
        _kFormalSimplifiedChineseNumberDigits,
        _kFromalSimplifiedChineseNumberUnits,
        _kFromalSimplifiedChineseNumberUnits2,
        omitInitialOne: false,
      );
    } else {
      return _toFloatChineseNumber(
        this,
        _kFormalSimplifiedChineseNumberDigits,
        _kFromalSimplifiedChineseNumberUnits,
        _kFromalSimplifiedChineseNumberUnits2,
        _kFormalSimplifiedChinesePointCharacter,
        omitInitialOne: false,
      );
    }
  }
}
