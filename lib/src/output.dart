library output.less;

import 'file_info.dart';

class Output {
  StringBuffer value = new StringBuffer();

  bool get isEmpty => value.isEmpty;
  String last = '';
  String separator;

  Map<String, bool> separators = {
    '(': true,
    ')': true,
    '/': true,
    ':': true,
    ',': true,
    ' ': true,
    '{': true,
    '}': true
  };

  /// [s] is String or s.toString(). #
  void add(s, [FileInfo currentFileInfo, int index, mapLines]) {
    if (separator != null) s = compose(s);
    last = (s is String && s.isNotEmpty) ? s[s.length-1] : ''; //for cleanCss
    value.write(s);
  }

  ///
  /// writes the [separator] if not near a separators item
  /// Normally [separator] is ' '
  ///
  /// Example: ') ' -> ')'
  ///
  void conditional(String separator) {
    this.separator = separator;
  }

  ///
  /// Prefix s with separator if adecuate
  ///
  String compose(s) {
    String result;
    String source = s is String ? s : s.toString();
    String separator = this.separator != null ? this.separator : '';
    this.separator = null;

    if (source.isEmpty) return source;
    if (separators.containsKey(last)) return source;
    if (separators.containsKey(source[0])) return source;

    result = separator + s;
    return result;
  }

  String toString() => value.toString();
}