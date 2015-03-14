// source: less/utils.js 2.4.0

library utils.less;

class Utils {
  ///
  /// Returns line and column corresponding to index
  ///
  /// [index] is the character position in [inputStream]
  ///
  //2.2.0 ok
  static LocationPoint getLocation(int index, String inputStream) {
    int n = (index >= inputStream.length - 1) ? inputStream.length : index + 1;
    int line;
    int column = -1;

    while (--n >= 0 && inputStream[n] != '\n') column++;
    if (column < 0) column = 0;

    line = inputStream.substring(0, index).split('\n').length -1;

    return new LocationPoint(
        line: line,
        column: column
        );

//2.2.0
//getLocation: function(index, inputStream) {
//    var n = index + 1,
//        line = null,
//        column = -1;
//
//    while (--n >= 0 && inputStream.charAt(n) !== '\n') {
//        column++;
//    }
//
//    if (typeof index === 'number') {
//        line = (inputStream.slice(0, index).match(/\n/g) || "").length;
//    }
//
//    return {
//        line: line,
//        column: column
//    };
//}
  }
}

///
/// Coordinates [line], [column] in a file
///
/// Example: new LocationPoint({line: 9, column: 30});
///
class LocationPoint {
  int line;
  int column;

  LocationPoint({int this.line, int this.column});
}