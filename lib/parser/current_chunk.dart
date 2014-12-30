//source: less/parser.js

part of parsers.dart;

// source: less/parser.js 1.7.5 lines 113-267
class CurrentChunk {
  Env env;
  String input;
  List<String> chunks;
  String current;      // chunk of input, where currentPos...

  int i = 0;           // current index in `input` -int?
  int j = 0;           // current chunk in chunks[j]
  List saveStack = []; // holds state for backtracking
  int currentPos = 0;  // index of current chunk, in `input`. current[0] == input[currentPos]
  int furthest = 0;    // furthest index the parser has gone to

  CurrentChunk(Env this.env, List<String> this.chunks) {
    input = env.input;
    current = (chunks.isEmpty) ? '' : chunks[0];
  }

  get noEmpty => current.length > 0;

  String charAt(int pos) => input[pos];

  String charAtPos() {
    if (i >= input.length) return null;
    return input[i];
  }

  String charAtNextPos() {
    if (i + 1 >= input.length) return null;
    return input[i+1];
  }

  int charCodeAt(int pos) => input.codeUnitAt(pos);
  int charCodeAtPos() => input.codeUnitAt(i);

  /**
   * save input pointers in stack
   */
  void save() {
    currentPos = i;
    saveStack.add(new StackItem(current, i, j));
  }

  /**
   * restore input pointers from stack
   */
  void restore() {
    StackItem state = saveStack.removeLast();
    current = state.current;
    currentPos = i = state.i;
    j = state.j;
  }

  /**
   * Remove input pointer from stack
   */
  void forget() {
    saveStack.removeLast();
  }

  void sync() {
    if (i > currentPos) {
      current = current.substring(i - currentPos);
      currentPos = i;
    }
  }

  /**
   * Char at pos is 32 (space), 10 (\n) or 9 (tab)
   */
  bool isWhitespace(String str, [int pos = 0]) {
    if (pos < 0) return false;
    int code = str.codeUnitAt(pos);
    return (code <= 32) && (code == 32 || code == 10 || code == 9);

//  function isWhitespace(str, pos) {
//      var code = str.charCodeAt(pos | 0);
//      return (code <= 32) && (code === 32 || code === 10 || code === 9);
//  }
  }

  /// is White Space Previous Position ?
  bool isWhitespacePrevPos() => isWhitespace(input, i - 1);

  /// is White Space in Position ?
  bool isWhitespacePos() => isWhitespace(input, i);

  /**
   * Parse from a token, regexp or string, and move forward if match
   * [tok] String or RegExp
   * return String or List
   */
  $(tok) {
    Match match;
    int length;
    List<String> resultList = [];

    // Either match a single character in the input,
    // or match a regexp in the current chunk (`current`).
    //
    if (tok is String) {
      if (charAtPos() != tok) return null;
      skipWhitespace(1);
      return tok;
    }

    //regexp
    sync();
    RegExp rtok = (tok as RegExp);
    match = rtok.firstMatch(current);
    if (match == null) return null;

    length = match[0].length;

    // The match is confirmed, add the match length to `i`,
    // and consume any extra white-space characters (' ' || '\n')
    // which come after that. The reason for this is that LeSS's
    // grammar is mostly white-space insensitive.
    //
    skipWhitespace(length);
    if (match.groupCount < 2) {
      return match[0];
    } else {
      for (var item = 0; item <= match.groupCount; item++) {
        resultList.add(match[item]);
      }
      return resultList;
    }

//  function $(tok) {
//      var tokType = typeof tok,
//          match, length;
//
//      // Either match a single character in the input,
//      // or match a regexp in the current chunk (`current`).
//      //
//      if (tokType === "string") {
//          if (input.charAt(i) !== tok) {
//              return null;
//          }
//          skipWhitespace(1);
//          return tok;
//      }
//
//      // regexp
//      sync ();
//      if (! (match = tok.exec(current))) {
//          return null;
//      }
//
//      length = match[0].length;
//
//      // The match is confirmed, add the match length to `i`,
//      // and consume any extra white-space characters (' ' || '\n')
//      // which come after that. The reason for this is that LeSS's
//      // grammar is mostly white-space insensitive.
//      //
//      skipWhitespace(length);
//
//      if(typeof(match) === 'string') {
//          return match;
//      } else {
//          return match.length === 1 ? match[0] : match;
//      }
//  }
  }

  /**
   * Specialization of $(tok).
   * Parse from a RegExp and returns String or List<String> with the match.
   *
   * [tok] is String to search.
   * [caseSensitive] true by default. false correspond to 'i'.
   * [index] if match returns m[index]
   */
  //lines 168-184
  $re(String tok, [bool caseSensitive = true, int index]) {
    List<String> resultList = [];
    RegExp reg = new RegExp(tok, caseSensitive: caseSensitive);

    if (i > currentPos) {
      current = current.substring(i - currentPos);
      currentPos = i;
    }

    Match m = reg.firstMatch(current);
    if (m == null) return null;

    skipWhitespace(m[0].length);
    if (index != null && m.groupCount >= index) return m[index];
    if (m.groupCount == 0) return m[0];
    if (m.groupCount == 1) return m[1];

    for (var item = 0; item <= m.groupCount; item++) {
      resultList.add(m[item]);
    }
    return resultList;
  }

//  function $re(tok) {
//          if (i > currentPos) {
//              current = current.slice(i - currentPos);
//              currentPos = i;
//          }
//          var m = tok.exec(current);
//          if (!m) {
//              return null;
//          }
//
//          skipWhitespace(m[0].length);
//          if(typeof m === "string") {
//              return m;
//          }
//
//          return m.length === 1 ? m[0] : m;
//      }

  /**
   * Same as $re, but returns first match.
   * Parse from a RegExp and returns Match.
   *
   * [tok] is String to search.
   * [caseSensitive] true by default. false correspond to 'i'.
   */
  Match $reMatch(String tok, [bool caseSensitive = true]) {
    RegExp reg = new RegExp(tok, caseSensitive: caseSensitive);

    if (i > currentPos) {
      current = current.substring(i - currentPos);
      currentPos = i;
    }

    Match m = reg.firstMatch(current);
    if (m == null) return null;

    skipWhitespace(m[0].length);
    return m;
  }

//
//  var _$re = $re;
//

  /**
   * Specialization of $(tok).
   * return a String if [tok] is found.
   *
   * [tok] is a String.
   */
  //lines 189-195
  String $char(String tok) {
    if (charAtPos() != tok) return null;
    skipWhitespace(1);
    return tok;
  }

  //lines 197-226
  bool skipWhitespace(int length) {
    int oldi = i;
    int oldj = j;
    int curr = i - currentPos;
    int endIndex = i + current.length - curr;
    int mem = (i += length);
    String inp = input;
    int c; //char

    for (; i < endIndex; i++) {
      c = inp.codeUnitAt(i);
      if (c > 32) break;
      if ((c != 32) && (c != 10) && (c != 9) && (c != 13)) break;
    }

    current = current.substring(length + i - mem + curr);
    currentPos = i;

    if (current.length == 0 && (j < chunks.length - 1)) {
      current = chunks[++j];
      skipWhitespace(0); // skip space at the beginning of a chunk
      return true; // things changed
    }

    return (oldi != i || oldj != j);

//  function skipWhitespace(length) {
//      var oldi = i, oldj = j,
//          curr = i - currentPos,
//          endIndex = i + current.length - curr,
//          mem = (i += length),
//          inp = input,
//          c;
//
//      for (; i < endIndex; i++) {
//          c = inp.charCodeAt(i);
//          if (c > 32) {
//              break;
//          }
//
//          if ((c !== 32) && (c !== 10) && (c !== 9) && (c !== 13)) {
//              break;
//          }
//       }
//
//      current = current.slice(length + i - mem + curr);
//      currentPos = i;
//
//      if (!current.length && (j < chunks.length - 1)) {
//          current = chunks[++j];
//          skipWhitespace(0); // skip space at the beginning of a chunk
//          return true; // things changed
//      }
//
//      return oldi !== i || oldj !== j;
//  }
  }

  /**
   * [arg] Function (?), RegExp or String
   * [index] ????
   * return String or List<String>
   */
  expect(arg, [String msg, int index]) {
    String message = msg;

    var result = (arg is Function) ? arg() : $(arg);
    if (result != null) return result;

    if (message == null) {
      message = (arg is String) ? "expected '$arg' got '${charAtPos()}'" : 'unexpected token';
    }
    error(message);

//  function expect(arg, msg, index) {
//      // some older browsers return typeof 'function' for RegExp
//      var result = (Object.prototype.toString.call(arg) === '[object Function]') ? arg.call(parsers) : $(arg);
//      if (result) {
//          return result;
//      }
//      error(msg || (typeof(arg) === 'string' ? "expected '" + arg + "' got '" + input.charAt(i) + "'"
//                                             : "unexpected token"));
//  }
  }

  /*
   * Specialization of expect()
   */
  String expectChar(String arg, [String msg]) {
    if (charAtPos() == arg) {
      skipWhitespace(1);
      return arg;
    }

    String message = msg != null ? msg : "expected '$arg' got '${charAtPos()}'";
    return error(message);

//  function expectChar(arg, msg) {
//      if (input.charAt(i) === arg) {
//          skipWhitespace(1);
//          return arg;
//      }
//      error(msg || "expected '" + arg + "' got '" + input.charAt(i) + "'");
//  }
  }

  error(String msg, [String type]) {
    LessError e = new LessError(
        index: i,
        type: type != null ? type :  'Syntax',
        message: msg,
        env: env);
    throw new LessExceptionError(e);

//  function error(msg, type) {
//      var e = new Error(msg);
//      e.index = i;
//      e.type = type || 'Syntax';
//      throw e;
//  }
  }

  /**
   * Same as $(), but don't change the state of the parser,
   * just return the match.
   * [tok] is String or RegExp
   */
  bool peek(tok) {
    if (tok is String) {
      return input[i] == tok;
    } else {
      RegExp r = (tok as RegExp);
      return r.hasMatch(current);
    }
//  function peek(tok) {
//      if (typeof(tok) === 'string') {
//          return input.charAt(i) === tok;
//      } else {
//          return tok.test(current);
//      }
//  }
  }

  /*
   * Specialization of peek()
   */
  bool peekChar(String tok) {
    if (i >= input.length) return false;
    return input[i] == tok;
  }

  /**
   * If `i` is smaller than the `input.length - 1`,
   * it means the parser wasn't able to parse the whole
   * string, so we've got a parsing error.
   *
   * We try to extract a \n delimited string,
   * showing the line where the parse error occured.
   * We split it up into two parts (the part which parsed,
   * and the part which didn't), so we can color them differently.
   */
  void isFinished() {
    String getLine(List<String> lines, int line) {
        if ((line >= 0) && (line <= lines.length -1)) return lines[line];
        return null;
      }

    if (i < input.length - 1) {
      i = furthest;
      LessErrorLocation loc = LessError.getLocation(i, input);
      List<String> lines = input.split('\n');
      if(lines.last.isEmpty) lines.removeLast();
      int line = loc.line + 1;

      LessError e = new LessError();
      e.type = 'Parse';
      e.message = 'Unrecognised input';
      e.index = i;
      e.filename = env.currentFileInfo.filename;
      e.line = line;
      e.column = loc.column;
//      e.extract = [
//            lines[line - 2],
//            lines[line - 1],
//            lines[line]
//      ];
      e.extract = [
        getLine(lines, line-2),
        getLine(lines, line - 1),
        getLine(lines, line)
        ];
      e.color = env.color;
      e.isSimplyFormat = false;

      throw new LessExceptionError(e);
    }

//    if (i < input.length - 1) {
//        i = furthest;
//        var loc = getLocation(i, input);
//        lines = input.split('\n');
//        line = loc.line + 1;
//
//        error = {
//            type: "Parse",
//            message: "Unrecognised input",
//            index: i,
//            filename: env.currentFileInfo.filename,
//            line: line,
//            column: loc.column,
//            extract: [
//                lines[line - 2],
//                lines[line - 1],
//                lines[line]
//            ]
//        };
//    }

  }
}

class StackItem {
  String current;
  int i;
  int j;

  StackItem(String this.current, int this.i, int this.j);
}
