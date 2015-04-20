library output.less;

import 'file_info.dart';

class Output {
  StringBuffer value = new StringBuffer();

  bool get isEmpty => value.isEmpty;
  String last = '';

  /// [s] is String or s.toString(). #
  void add(s, [FileInfo currentFileInfo, int index, mapLines]) {
    last = (s is String && s.isNotEmpty) ? s[s.length-1] : ''; //for cleanCss
    value.write(s);
  }

  String toString() => value.toString();
}