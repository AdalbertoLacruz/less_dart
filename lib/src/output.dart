library output.less;

import 'file_info.dart';

class Output {
  StringBuffer value = new StringBuffer();

  bool get isEmpty => value.isEmpty;

  /// [s] is String or s.toString(). #
  void add(s, [FileInfo currentFileInfo, int index, mapLines]) {
    value.write(s);
  }

  String toString() => value.toString();
}