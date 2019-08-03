part of environment.less;

// https://gist.github.com/ahiipsa/4754533 20130211
// 20141114 String.codeUnits StringBuffer.write
///
class Base64String {
  static const List<String> _encodingTable = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    '/'
  ];

  /// [income] String or List<int>
  static String encode(dynamic income) {
    final List<String> characters = <String>[];
    final List<int> data = (income is String) ? income.codeUnits : income;
    int i;
    int index;

    for (i = 0; i + 3 <= data.length; i += 3) {
      int value = 0;
      value |= data[i + 2];
      value |= data[i + 1] << 8;
      value |= data[i] << 16;
      for (int j = 0; j < 4; j++) {
        index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
    }
    // Remainders.
    if (i + 2 == data.length) {
      int value = 0;
      value |= data[i + 1] << 8;
      value |= data[i] << 16;
      for (int j = 0; j < 3; j++) {
        index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
      characters.add('=');
    } else if (i + 1 == data.length) {
      int value = 0;
      value |= data[i] << 16;
      for (int j = 0; j < 2; j++) {
        index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
      characters..add('=')..add('=');
    }

    final StringBuffer output = StringBuffer();
    for (i = 0; i < characters.length; i++) {
//      if (i > 0 && i % 76 == 0) {
//        output.write("\r\n");
//      }
      output.write(characters[i]);
    }
    return output.toString();
  }

  ///
  static String decode(String data) {
    int char;
    int charCount = 0;
    int padCount = 0;
    final List<int> result = <int>[];
    int value = 0;

    for (int i = 0; i < data.length; i++) {
      char = data.codeUnitAt(i);
      if (65 <= char && char <= 90) { // "A" - "Z".
        value = (value << 6) | char - 65;
        charCount++;
      } else if (97 <= char && char <= 122) { // "a" - "z".
        value = (value << 6) | char - 97 + 26;
        charCount++;
      } else if (48 <= char && char <= 57) { // "0" - "9".
        value = (value << 6) | char - 48 + 52;
        charCount++;
      } else if (char == 43) { // "+".
        value = (value << 6) | 62;
        charCount++;
      } else if (char == 47) { // "/".
        value = (value << 6) | 63;
        charCount++;
      } else if (char == 61) { // "=".
        value = value << 6;
        charCount++;
        padCount++;
      }
      if (charCount == 4) {
        result.add((value & 0xFF0000) >> 16);
        if (padCount < 2) {
          result.add((value & 0xFF00) >> 8);
        }
        if (padCount == 0) {
          result.add(value & 0xFF);
        }
        charCount = 0;
        value = 0;
      }
    }

    return String.fromCharCodes(result);
  }
}
