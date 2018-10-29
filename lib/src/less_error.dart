// source: less/less-error.js less/lessc-helper.js less/index.js  less/parser.js 3.0.0 20170101

library error.less;

import 'contexts.dart';
import 'utils.dart';

///
/// This is a centralized class of any error that could be thrown internally (mostly by the parser).
/// Besides standard message it keeps some additional data like a path to the file where the error
/// occurred along with line and column numbers.
///
class LessError {
  ///
  int           call;

  ///
  int           callLine;

  ///
  String        callExtract;

  /// color in error messages
  bool          color;

  /// error column
  int           column;

  /// lines around the error
  List<String>  extract;

  /// path to file with error
  String        filename;

  /// error character position
  int           index;

  ///
  bool          isSimplyFormat = true;

  /// error line
  int           line;

  /// error description
  String        message;

  //bool silent = false;

  ///
  StackTrace    stack;

  /// error type
  String        type;

  // less/parser.js 1.7.5 lines 309-331
  ///
  LessError({
      int this.call,
      Contexts context,
      int this.index,
      String this.filename,
      String this.message,
      StackTrace this.stack,
      String this.type
      }) {

    if (context != null) addFileInformation(context);
  }

  ///
  /// Completes the error with line, col in input
  ///
  void addFileInformation(Contexts context) {
    filename ??= context.currentFileInfo?.filename;
    type ??= 'Syntax';

    final String input = getInput(filename, context);
    if (input != null && index != null) {
      final LocationPoint loc = Utils.getLocation(index, input);
      final int line = loc.line;
      final int col = loc.column;
      final int callLine = (call != null) ? Utils.getLocation(call, input).line : 0;
      final List<String> lines = input.split('\n');

      this.line = (line is num) ? line + 1 : null;
      this.callLine = callLine + 1;
      callExtract = lines[callLine];
      column = col;
      extract = <String>[
          getLine(lines, line - 1),
          getLine(lines, line),
          getLine(lines, line + 1)];
      color = context.color;
      isSimplyFormat = false;
    }
    //this.silent = context.silent;
  }

  ///
  /// Transforms un error [e] to LessError and completes some error information
  ///
  static LessError transform(Object e,
      {int index,
      String filename,
      String message,
      String type,
      int line,  //TODO
      int column, //TODO
      StackTrace stackTrace,
      Contexts context}) {

    LessError error;
    if (e is LessExceptionError) error = e.error;
    (error ??= (e is LessError) ? e : new LessError())
        ..index ??= index
        ..filename ??= filename
        ..message ??= (e != null && e is! LessError) ? e.toString() : message
        ..type ??= type
        ..stack ??= stackTrace;
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
  static int getErrorColumn(Object e) => e is LessError ? e.column : null;

  ///
  static int getErrorLine(Object e) => e is LessError ? e.line : null;

  ///
  /// For a [e] error get the type, with default ''
  ///
  static String getType(Object e) {
    if (e is LessExceptionError) return e.error.type;
    if (e is LessError) return e.type;
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
    if ((filename != null) &&
        (context.currentFileInfo != null) &&
        (context.currentFileInfo.filename != null) &&
        (filename != context.currentFileInfo.filename)) {
      return context.imports.contents[filename];
    } else {
      return context.input;
    }
  }
}

//Style for LessExceptionError.stylize
///
const int STYLE_RESET       = 0;
///
const int STYLE_BOLD        = 1;
///
const int STYLE_INVERSE     = 2;
///
const int STYLE_UNDERLINE   = 3;
///
const int STYLE_YELLOW      = 4;
///
const int STYLE_GREEN       = 5;
///
const int STYLE_RED         = 6;
///
const int STYLE_GREY        = 7;

///
class LessExceptionError implements Exception {
  bool _color;

  /// compound information about the error and context
  final LessError error;

  ///
  LessExceptionError(this.error) {
    _color = error.color ?? false;
  }

  /// Returns only type and message error
  String simplyFormatError() =>
      '${error.type ?? ""}Error: ${error.message}\n${error.stack?.toString() ?? ""}';

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
    final StringBuffer  message = new StringBuffer();

    error
        ..type ??= 'Syntax'
        ..message ??= 'Error:';

    if (error.extract[0] != null) {
      errorTxt = stGrey('${formatLineCounter((error.line - 1), lineCounterWidth)} ${error.extract[0]}');
      errorLines.add(errorTxt.trimRight());
    }
    if (error.extract[1] != null) {
      // ignore: prefer_interpolation_to_compose_strings
      error.extract[1] += ' '; //assure (error.column + 1) exist
      errorTxt = '${formatLineCounter((error.line), lineCounterWidth)} ${error.extract[1].substring(0, error.column)}';
      errorPosition = "${'.' * errorTxt.length}^";
      // ignore: prefer_interpolation_to_compose_strings
      errorTxt += stInverse(stRed(stBold(error.extract[1][error.column]) + error.extract[1].substring(error.column+1)));
      errorLines
          ..add(errorTxt.trimRight())
          ..add(errorPosition);
    }
    if (error.extract[2] != null) {
      errorTxt = stGrey('${formatLineCounter((error.line + 1),lineCounterWidth)} ${error.extract[2]}');
      errorLines.add(errorTxt.trimRight());
    }

    message.write(stRed('${error.type}Error: ${error.message}'));
    if (error.filename != null && error.filename != '') {
      message
        ..write(stRed(' in '))
        ..write(error.filename)
        ..write(stGrey(' on line ${error.line}, column ${error.column + 1}:'));
    }
    message
        ..write('\n')
        ..write(errorLines.join('\n'))
        ..write(stReset(''))
        ..write('\n');

//    if (ctx.callLine) {
//        message += stylize('from ', STYLE_RED) + (error.filename || '') + '/n';
//        message += stylize(error.callLine, STYLE_GREY) + ' ' + error.callExtract + '/n';
//    }
    return message.toString();
  }

  /// Format the [line] number to the [width] with 0's. ex. line = 9, width = 2 => return '09'
  String formatLineCounter(int line, int width) =>
      line.toString().padLeft(width,'0');

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

///
/// Generic LessException
///
class LessException implements Exception {
  ///
  String message;

  /// Constructor
  LessException(this.message);
}
