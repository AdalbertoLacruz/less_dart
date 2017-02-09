// source: parser/parser-input.js 2.5.0

part of parser.less;

class ParserInput {
  final String input;         // Less input string
  int i = 0;            // current index in `input`

  Contexts context;

  bool autoCommentAbsorb = true;
  List<CommentPointer> commentStore = [];
  bool finished = false;
  int furthest = 0;     // furthest index the parser has gone to
  String furthestPossibleErrorMessage; // if this is furthest we got to, this is the probably cause
  List<int> saveStack = <int>[];  // holds state for backtracking

  ParserInput(String this.input, Contexts this.context) {
    i = furthest = 0;
    skipWhitespace(0);
  }

  ///
  //Not used in 2.2.0
  bool get notEmpty => i < input.length;

  ///
  String charAt(int pos) {
    if (pos >= input.length) return null;
    return input[pos];
  }

  ///
  String currentChar() => charAt(i);

  ///
  String nextChar() => charAt(i + 1);

  ///
  int charCodeAt(int pos) {
    if (pos >= input.length) return null;
    return input.codeUnitAt(pos);
  }

  ///
  int charCodeAtPos() => charCodeAt(i);

  ///
  /// save input pointers in stack
  ///
  void save() {
    saveStack.add(i);
  }

  ///
  /// restore input pointers from stack
  ///
  void restore([String possibleErrorMessage]) {
    if (i > furthest
        || ((i == furthest) && (possibleErrorMessage != null)
            && (furthestPossibleErrorMessage == null))) {
      furthest = i;
      furthestPossibleErrorMessage = possibleErrorMessage;
    }

    i = saveStack.removeLast();
  }

  ///
  /// Remove input pointer from stack
  ///
  void forget() {
    saveStack.removeLast();
  }

  ///
  /// Char at pos + [offset] is 32 (space), 13 (CR), 9 (tab) or 10 (LF)
  ///
  bool isWhitespace([int offset = 0]) {
    int pos = i + offset;
    if (pos < 0 || pos >= input.length) return false;

    int code = input.codeUnitAt(pos);
    return (code == Charcode.SPACE_32 || code == Charcode.CR_13
         || code == Charcode.TAB_9 || code == Charcode.LF_10);

//2.2.0
//    parserInput.isWhitespace = function (offset) {
//        var pos = parserInput.i + (offset || 0),
//            code = input.charCodeAt(pos);
//        return (code === CHARCODE_SPACE || code === CHARCODE_CR || code === CHARCODE_TAB || code === CHARCODE_LF);
//    };
  }

  /// is White Space Previous Position
  bool isWhitespacePrevPos() => isWhitespace(-1);

  /// is White Space in Position
  bool isWhitespacePos() => isWhitespace();

  ///
  /// Specialization of $(tok).
  /// Parse from a RegExp and returns String or List<String> with the match.
  ///
  /// [tok] is String to search. Could be RegExp
  /// [caseSensitive] true by default. false correspond to 'i'.
  /// [index] if match returns m[index]
  ///
  $re(RegExp reg, [int index]) {
    if (i >= input.length) return null;

    Match m = reg.matchAsPrefix(input, i);
    if (m == null) return null;

    assert(m.end == (m[0].length + i));
    skipWhitespace(m.end);
    if (index != null && m.groupCount >= index) return m[index];
    if (m.groupCount == 0) return m[0];
    if (m.groupCount == 1) return m[1];

    List<String> resultList = [];
    for (var item = 0; item <= m.groupCount; item++) {
      resultList.add(m[item]);
    }
    return resultList;
  }

  $reMatch(RegExp reg) {
    final m = reg.matchAsPrefix(input, i);
    if (m == null) return null;
    assert(m.end == (m[0].length + i));
    skipWhitespace(m.end);
    return m;
  }

  ///
  /// return a String if [tok] character is found.
  ///
  /// [tok] is a String.
  ///
  String $char(String tok) {
    if (currentChar() != tok) return null;
    skipWhitespace(i + 1);
    return tok;
  }

  ///
  /// Returns tok if found at current position
  ///
  String $str(String tok) {
    if (i >= input.length || !input.startsWith(tok, i)) return null;
    skipWhitespace(i + tok.length);
    return tok;
  }

  ///
  /// Returns a "..." or '...' string if found, else null
  ///
  String $quoted() {
    final String startChar = currentChar();
    if (startChar != "'" && startChar != '"') return null;

    final start = i;
    for (int end = (i + 1); end < input.length; end++) {
      final String nextChar = charAt(end);
      switch (nextChar) {
        case '\\':
          end++;
          continue;

        case '\r':
        case '\n':
          break;

        case "'":
        case '"':
          if (nextChar == startChar) {
            final String str =
                input.substring(start, end + 1);
            skipWhitespace(end + 1);
            return str;
          }
          break;
        default:
      }
    }
    return null;
  }

  ///
  void skipWhitespace(int newi) {
    final int endIndex = input.length;

    i = newi;

    for (; i < endIndex; i++) {
      int c = charCodeAt(i);
      if (autoCommentAbsorb && c == Charcode.SLASH_47) {
        String nextChar = charAt(i + 1);
        if (nextChar == '/') {
          CommentPointer comment = new CommentPointer(index: i, isLineComment: true);
          int nextNewLine = input.indexOf('\n', i + 2);

          if (nextNewLine < 0) nextNewLine = endIndex;
          i = nextNewLine;
          comment.text = input.substring(comment.index, i);
          commentStore.add(comment);
          continue;
        } else if (nextChar == '*') {
          int nextStarSlash = input.indexOf('*/', i + 2);
          if (nextStarSlash >= 0) {
            CommentPointer comment = new CommentPointer(
                index: i,
                text: input.substring(i, nextStarSlash + 2),
                isLineComment: false);
            i += comment.text.length - 1;
            commentStore.add(comment);
            continue;
          }
        }
        break;
      }
      if ((c != Charcode.SPACE_32) && (c != Charcode.LF_10)
          && (c != Charcode.TAB_9) && (c != Charcode.CR_13)) break;
    }

    if (i == endIndex) {
      finished = true;
    }
  }

  ///
  /// [arg] Function (?), RegExp or String
  /// [index] ????
  /// return String or List<String>
  ///
  // parser.js 2.4.0 40-52
  expect(arg, [String msg, int index]) {
    String message = msg;

    var result = (arg is Function) ? arg() : $re(arg);
    if (result != null) return result;

    if (message == null) {
      message = (arg is String) ? "expected '$arg' got '${currentChar()}'" : 'unexpected token';
    }
    error(message);
  }

  ///
  /// Specialization of expect()
  ///
  //parser.js 2.2.0 56-62
  String expectChar(String arg, [String msg]) {
    if ($char(arg) != null) return arg;

    String message = msg != null ? msg : "expected '$arg' got '${currentChar()}'";
    return error(message);
  }

  ///
  //parser.js 2.2.0 lines 64-74
  error(String msg, [String type]) {
    LessError e = new LessError(
        index: i,
        type: type != null ? type :  'Syntax',
        message: msg,
        context: context);
    throw new LessExceptionError(e);

//2.2.0
//  function error(msg, type) {
//      throw new LessError(
//          {
//              index: parserInput.i,
//              filename: fileInfo.filename,
//              type: type || 'Syntax',
//              message: msg
//          },
//          imports
//      );
//  }
  }

  ///
  /// Same as $(), but don't change the state of the parser,
  /// just return the match.
  /// [tok] is String or RegExp
  ///
  bool peek(tok) {
    if (tok is String) {
      // https://jsperf.com/string-startswith/21
      return input.startsWith(tok, i);
    } else {
      RegExp r = (tok as RegExp);
      return r.matchAsPrefix(input, i) != null;
    }
  }

  ///
  /// Specialization of peek()
  ///
  bool peekChar(String tok) {
    if (i >= input.length) return false;
    return input[i] == tok;
  }

  ///
  String getInput() => input;

  ///
  bool peekNotNumeric() {
    int c = charCodeAtPos();
    //Is the first char of the dimension 0-9, '.', '+' or '-'
    return (c > Charcode.$9_57 || c < Charcode.PLUS_43)
        || c == Charcode.SLASH_47
        || c == Charcode.COMMA_44;

//    parserInput.peekNotNumeric = function() {
//        var c = input.charCodeAt(parserInput.i);
//        //Is the first char of the dimension 0-9, '.', '+' or '-'
//        return (c > CHARCODE_9 || c < CHARCODE_PLUS) || c === CHARCODE_FORWARD_SLASH || c === CHARCODE_COMMA;
//    };
  }

  ///
  ParserStatus end() {
    String message;
    bool isFinished = (i >= input.length);

    if (i < furthest) {
      message = furthestPossibleErrorMessage;
      i = furthest;
    }

    return new ParserStatus(
      isFinished: isFinished,
      furthest: i,
      furthestPossibleErrorMessage: message,
      furthestReachedEnd: (i >= input.length - 1),
      furthestChar : currentChar()
    );

//2.2.0
//    parserInput.end = function() {
//        var message,
//            isFinished = parserInput.i >= input.length;
//
//        if (parserInput.i < furthest) {
//            message = furthestPossibleErrorMessage;
//            parserInput.i = furthest;
//        }
//        return {
//            isFinished: isFinished,
//            furthest: parserInput.i,
//            furthestPossibleErrorMessage: message,
//            furthestReachedEnd: parserInput.i >= input.length - 1,
//            furthestChar: input[parserInput.i]
//        };
//    };
  }

  ///
  /// If `i` is smaller than the `input.length - 1`,
  /// it means the parser wasn't able to parse the whole
  /// string, so we've got a parsing error.
  ///
  /// We try to extract a \n delimited string,
  /// showing the line where the parse error occurred.
  /// We split it up into two parts (the part which parsed,
  /// and the part which didn't), so we can color them differently.
  ///
  void isFinished() {
    ParserStatus endInfo = end();
    if (!endInfo.isFinished) {
      String message = endInfo.furthestPossibleErrorMessage;

      if (message == null) {
        message = 'Unrecognised input';
        if (endInfo.furthestChar == '}') {
          message += ". Possibly missing opening '{'";
        } else if (endInfo.furthestChar == ')') {
          message += ". Possibly missing opening '('";
        } else if (endInfo.furthestReachedEnd) {
          message += ". Possibly missing something";
        }
      }

      LessError error = new LessError(
          type: 'Parse',
          message: message,
          index: endInfo.furthest,
          filename: context.currentFileInfo.filename,
          context: context);
      throw new LessExceptionError(error);
    }

//2.2.0
//  var endInfo = parserInput.end();
//  if (!endInfo.isFinished) {
//
//      var message = endInfo.furthestPossibleErrorMessage;
//
//      if (!message) {
//          message = "Unrecognised input";
//          if (endInfo.furthestChar === '}') {
//              message += ". Possibly missing opening '{'";
//          } else if (endInfo.furthestChar === ')') {
//              message += ". Possibly missing opening '('";
//          } else if (endInfo.furthestReachedEnd) {
//              message += ". Possibly missing something";
//          }
//      }
//
//      error = new LessError({
//          type: "Parse",
//          message: message,
//          index: endInfo.furthest,
//          filename: fileInfo.filename
//      }, imports);
//  }
  }
}

/*************************************************/

class CommentPointer {
  int index;
  bool isLineComment;
  String text;

  CommentPointer({this.index, this.isLineComment, this.text});
}

class ParserStatus {
  bool isFinished;
  int furthest;
  String furthestPossibleErrorMessage;
  bool furthestReachedEnd;
  String furthestChar;

  ParserStatus({this.isFinished, this.furthest, this.furthestPossibleErrorMessage,
    this.furthestReachedEnd, this.furthestChar});
}
