// source: less/parser.js less/index.js less/lessc_helper.js

library error.less;

import 'contexts.dart';
import 'utils.dart';

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

  //bool silent = false;

  // less/parser.js 1.7.5 lines 309-331
  LessError({int call, Contexts context, int index, String filename, String message, StackTrace stack, String type}) {
    this.call = call;
    this.index = index;
    this.filename = filename;
    this.message = message;
    this.stack = stack;
    this.type = type;

    if (context != null) addFileInformation(context);
  }

  ///
  /// Completes the error with line, col in input
  ///
  void addFileInformation(Contexts context) {
    this.filename ??=  context.currentFileInfo?.filename;
    this.type ??= 'Syntax';

    final String input = getInput(this.filename, context);
    if (input != null && this.index != null) {
      final LocationPoint loc = Utils.getLocation(this.index, input);
      final int line = loc.line;
      final int col = loc.column;
      final int callLine = (this.call != null) ? Utils.getLocation(this.call, input).line : 0;
      final List<String> lines = input.split('\n');

      this.line = (line is num)? line + 1 : null;
      this.callLine = callLine + 1;
      this.callExtract = lines[callLine];
      this.column = col;
      this.extract = <String>[
        getLine(lines, line - 1),
        getLine(lines, line),
        getLine(lines, line + 1)
        ];
      this.color = context.color;
      this.isSimplyFormat = false;
    }
    //this.silent = context.silent;
  }

  ///
  /// Transforms un error [e] to LessError and completes some error information
  ///
  static LessError transform(Object e, {int index, String filename, String message, String type, StackTrace stackTrace, Contexts context}) {
    LessError error;
    if (e is LessExceptionError) error = e.error;
    error ??= (e is LessError) ? e : new LessError();
    error.index ??= index;
    error.filename ??= filename;
    error.message ??= (e != null && e is! LessError) ? e.toString() : message;
    error.type ??= type;
    error.stack ??= stackTrace;
    if (context != null) error.addFileInformation(context);
    return error;
  }

  ///
  /// For a [e] error get the message, with default ''
  ///
  static String getMessage(Object e) {
    if (e is LessExceptionError) return e.error.message;
    if (e is LessError) return e.message;
    return '';
  }

  ///
  /// Returns null if [line] is out of range in [lines]
  ///
  String getLine(List<String> lines, int line) {
    if ((line >= 0) && (line <= lines.length -1)) return lines[line];
    return null;
  }

  ///
  /// Returns the source code associated to the error
  /// [filename] is the error source
  ///
  // less/parser.js 1.7.5 lines 270-276
  String getInput(String filename, Contexts context) {
    if ( (filename != null)
      && (context.currentFileInfo != null)
      && (context.currentFileInfo.filename != null)
      && (filename != context.currentFileInfo.filename)) {

      return context.imports.contents[filename];
    } else {
      return context.input;
    }
  }
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
  /// compound information about the error and context
  final LessError error;
  bool _color;

  LessExceptionError(this.error){
    _color = this.error.color ?? false;
  }

  /// Returns only type and message error
  String simplyFormatError() {
    String result = '';
    if (error.type != null) result += '${error.type}Error: ';
    result += '${error.message}\n';
    if (error.stack != null) result += error.stack.toString();
    return result;
  }

  ///
  /// Returns the full message with information about error,
  /// file, line & column position and includes 3 lines from source
  ///
  // less/index.js 1.7.5 lines 44-92
  String formatError() {
    final List<String>  errorLines = <String>[];
    String              errorPosition; // '....^'
    String              errorTxt;
    final int           lineCounterWidth = (error.line + 1).toString().length;
    String              message = '';

    error.type ??= 'Syntax';
    error.message ??= 'Error:';

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

  ///
  /// Stylizes a string
  ///
  /// [str] String to transform with [style]
  /// [style] is defined with a const as STYLE_RED ...
  ///
  // less/lessc_helper.js 1.7.5 lines 07-20
  String stylize(String str, int style) {
    if (!_color) return (str);

    final Map<int, List<int>> styles = <int, List<int>>{
      STYLE_RESET:      <int>[ 0,  0],
      STYLE_BOLD:       <int>[ 1, 22],
      STYLE_INVERSE:    <int>[ 7, 27],
      STYLE_UNDERLINE:  <int>[ 4, 24],
      STYLE_YELLOW:     <int>[33, 39],
      STYLE_GREEN:      <int>[32, 39],
      STYLE_RED:        <int>[31, 39],
      STYLE_GREY:       <int>[90, 39]
    };
    const String ESC = '\u001b[';

    return ('$ESC${styles[style][0]}m$str$ESC${styles[style][1]}m'); //TODO test in linux
  }

  @override
  String toString() {
    //if (error.silent) return '';
    error.message ??= '';
    if (error.line == null) error.isSimplyFormat = true;
    return error.isSimplyFormat ? simplyFormatError() : formatError();
  }
}
