// source: less/parser.js less/index.js less/lessc_helper.js

library error.less;

import 'env.dart';
import 'less_debug_info.dart';

class LessError {
  /// error type
  String type;

  /// error description
  String message;

  /// path to file with error
  String filename;

  /// error character position
  int index;

  /// error line
  int line;

  int call;
  int callLine;

  String callExtract;

  StackTrace stack;

  /// error column
  int column;

  /// lines around the error
  List<String> extract;

  /// color in error messages
  bool color;

  bool isSimplyFormat = true;

  /// error object to be constructed outside
  //LessError.empty();

  // less/parser.js 1.7.5 lines 309-331
  LessError({int call, Env env, int index, String filename, String message, StackTrace stack, String type}) {
    this.call = call;
    this.index = index;
    this.filename = filename;
    this.message = message;
    this.stack = stack;
    this.type = type;

    if (env != null) addFileInformation(env);
  }

  ///
  /// Completes the error with line, col error in input
  ///
  addFileInformation(Env env) {
    if (this.filename == null) this.filename = (env.currentFileInfo != null) ? env.currentFileInfo.filename : null;
    if (this.type == null) this.type = 'Syntax';

    String input = getInput(this.filename, env);
    if (input != null && this.index != null) {
      LessErrorLocation loc = getLocation(this.index, input);
      int line = loc.line;
      int col = loc.column;
      int callLine = (this.call != null) ? getLocation(this.call, input).line : 0;
      List<String> lines = input.split('\n');

      this.line = (line is num)? line + 1 : null;
      this.callLine = callLine + 1;
      this.callExtract = lines[callLine];
      this.column = col;
      this.extract = [
        getLine(lines, line - 1),
        getLine(lines, line),
        getLine(lines, line + 1)
        ];
      this.color = env.color;
      this.isSimplyFormat = false;
    }
  }

  ///
  /// Transform un error [e] to LessError and completes some error information
  ///
  static transform(e, {int index, String filename, String message, String type, StackTrace stackTrace, Env env}) {
    LessError error;
    if (e is LessExceptionError) error = e.error;
    if (error == null) error = (e is LessError) ? e : new LessError();
    if (error.index == null) error.index = index;
    if (error.filename == null) error.filename = filename;
    if (error.message == null) {
      error.message = (e != null && e is! LessError) ? e.toString() : message;
    }
    if (error.type == null) error.type = type;
    //error.isSimplyFormat = true;
    if (error.stack == null) error.stack = stackTrace;
    if (env != null) error.addFileInformation(env);
    return error;
  }

  ///
  /// For a [e] error get the message, with default ''
  ///
  static String getMessage(e) {
    if (e is LessExceptionError) return e.error.message;
    if (e is LessError) return e.message;
    //return e.toString(); ??
    return '';
  }
  /**
   * return null if [line] is out of range in [lines]
   */
  String getLine(List<String> lines, int line) {
    if ((line >= 0) && (line <= lines.length -1)) return lines[line];
    return null;
  }

  /**
   * return the source code associated to the error
   * [filename] is the error source
   */
  // less/parser.js 1.7.5 lines 270-276
  String getInput(String filename, Env env) {
    if ((filename != null) && (env.currentFileInfo != null) && (env.currentFileInfo.filename != null) && (filename != env.currentFileInfo.filename)) {
      return env.imports.contents[filename];
    } else {
      return env.input;
    }
  }

  /**
   * return line and column corresponding to error
   * [index] is the error character position in [inputStream]
   */
  // less/parser.js 1.7.5 lines 278-295
  static LessErrorLocation getLocation(int index, String inputStream) {
    int n = index + 1;
    int line;
    int column = -1;
    RegExp regLine = new RegExp('\n');

    while ((--n >= 0) && (inputStream.codeUnitAt(n) != 10)) { //'\n'
      var char = inputStream.codeUnitAt(n);
      column++;
    }

    if (index is num) {
      line = regLine.allMatches(inputStream.substring(0, index)).length;
    }

    return new LessErrorLocation(
        line: line,
        column: column
        );
  }

  // less/parser.js 1.7.5 lines 297-307
  static LessDebugInfo getDebugInfo(int index, String inputStream, Env env) {
    String filename = env.currentFileInfo.filename;

    //if(less.mode !== 'browser' && less.mode !== 'rhino') {
    //  filename = require('path').resolve(filename);
    //}

    return new LessDebugInfo(
        lineNumber: getLocation(index, inputStream).line + 1,
        fileName: filename);
  }
}

/**
 * error coordinates in file
 * ex. new LessErrorLocation({line: 9, column: 30});
 */
class LessErrorLocation {
  int line;
  int column;

  LessErrorLocation({int this.line, int this.column});
}

//Style for LessExceptionError.stylize
const int STYLE_RESET       = 0;
const int STYLE_BOLD        = 1;
const int STYLE_INVERSE     = 2;
const int STYLE_UNDERLINE   = 3;
const int STYLE_YELLOW      = 4;
const int STYLE_GREEN       = 5;
const int STYLE_RED         = 6;
const int STYLE_GREY        = 7;

class LessExceptionError implements Exception {
  /// compound information about the error and environment
  final LessError error;
  bool _color;

  LessExceptionError(this.error){
    _color = this.error.color;
    if (_color == null) _color = false;
  }

  /// return only type and message error
  String simplyFormatError() {
    String result = '';
    if (error.type != null) result += '${error.type}Error: ';
    result += '${error.message}\n';
    if (error.stack != null) result += error.stack.toString();
    return result;
  }

  /**
   * return the full message with information about error,
   * file, line & column position e including 3 lines from source
   */
  // less/index.js 1.7.5 lines 44-92
  String formatError() {
    if (error.type == null) error.type = 'Syntax';
    if (error.message == null) error.message = 'Error:';
    String message = '';
    List<String> errorLines = [];
    String errorTxt;
    String errorPosition; // '....^'
    int lineCounterWidth = (error.line + 1).toString().length;

    if(error.extract[0] != null) {
      errorTxt = stGrey('${formatLineCounter((error.line - 1),lineCounterWidth)} ${error.extract[0]}');
      errorTxt = errorTxt.trimRight();
      errorLines.add(errorTxt);
    }
    if(error.extract[1] != null) {
      error.extract[1] += ' '; //assure (error.column + 1) exist
      errorTxt = '${formatLineCounter((error.line),lineCounterWidth)} ${error.extract[1].substring(0, error.column)}';
      errorPosition = ''.padRight(errorTxt.length,'.') + '^';
      errorTxt += stInverse(stRed(stBold(error.extract[1][error.column]) + error.extract[1].substring(error.column+1)));
      errorTxt = errorTxt.trimRight();
      errorLines.add(errorTxt);
      errorLines.add(errorPosition);
    }
    if(error.extract[2] != null) {
      errorTxt = stGrey('${formatLineCounter((error.line + 1),lineCounterWidth)} ${error.extract[2]}');
      errorTxt = errorTxt.trimRight();
      errorLines.add(errorTxt);
    }

    message += stRed('${error.type}Error: ${error.message}');
    if (error.filename != null && error.filename != '') {
      message += stRed(' in ') + error.filename + stGrey(' on line ${error.line}, column ${error.column + 1}:');
    }
    message += '\n' + errorLines.join('\n') + stReset('') + '\n';
//    if (ctx.callLine) {
//        message += stylize('from ', STYLE_RED) + (error.filename || '') + '/n';
//        message += stylize(error.callLine, STYLE_GREY) + ' ' + error.callExtract + '/n';
//    }
    return message;
  }

  /// Format the [line] number to the [width] with 0's. ex. line = 9, width = 2 => return '09'
  String formatLineCounter(int line, int width) => line.toString().padLeft(width,'0');

  /// Stylize [str] in bold
  String stBold(String str) => stylize(str, STYLE_BOLD);
  /// Stylize [str] in grey
  String stGrey(String str) => stylize(str, STYLE_GREY);
  /// Stylize [str] in inverse
  String stInverse(String str) => stylize(str, STYLE_INVERSE);
  /// Stylize [str] in red
  String stRed(String str) => stylize(str, STYLE_RED);
  /// Stylize [str] in reset
  String stReset(String str) => stylize(str, STYLE_RESET);

  /**
   * Stylize a string
   * [str] String to transform with [style]
   * [style] is defined with a const as STYLE_RED ...
   */
  // less/lessc_helper.js 1.7.5 lines 07-20
  String stylize(String str, int style) {
    if (!_color) return (str);
    Map<int, List<int>> styles = {
      STYLE_RESET:      [0,0],
      STYLE_BOLD:       [1, 22],
      STYLE_INVERSE:    [7,  27],
      STYLE_UNDERLINE:  [4,  24],
      STYLE_YELLOW:     [33, 39],
      STYLE_GREEN:      [32, 39],
      STYLE_RED:        [31, 39],
      STYLE_GREY:       [90, 39]
    };
    String esc = '\u001b[';

    return ('${esc}${styles[style][0]}m${str}${esc}${styles[style][1]}m'); //TODO test in linux
    //return (str);
  }

  String toString() {
    if (error.message == null) error.message = '';
    if (error.line == null) error.isSimplyFormat = true;
    return error.isSimplyFormat ? simplyFormatError() : formatError();
  }
}