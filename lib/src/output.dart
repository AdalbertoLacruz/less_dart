library output.less;

import 'file_info.dart';

///
class Output {
  ///
  StringBuffer value = StringBuffer();

  ///
  bool get isEmpty => value.isEmpty;

  ///
  String last = '';

  ///
  String separator;

  ///
  static Map<String, bool> separators = <String, bool>{
    '(': true,
    ')': true,
    '/': true,
    ':': true,
    ',': true,
    ' ': true,
    '{': true,
    '}': true
  };

  /// [s] String | Node. (Node.toString())
  void add(Object s, {FileInfo fileInfo, int index, bool mapLines}) {
    final Object _s = (separator != null) ? compose(s) : s;
    last =
        (_s is String && _s.isNotEmpty) ? _s[_s.length - 1] : ''; //for cleanCss
    value.write(_s);
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
  /// Prefix [s] with separator if adecuate.
  /// [s] = String | Node
  ///
  String compose(dynamic s) {
    final String source = s is String ? s : s.toString();
    final String separator = this.separator ?? '';
    this.separator = null;

    if (source.isEmpty) return source;
    if (separators.containsKey(last) && separators[last]) return source;
    if (separators.containsKey(source[0]) && separators[source[0]]) {
      return source;
    }
    return '$separator$s';
  }

  @override
  String toString() => value.toString();
}
