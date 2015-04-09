// source: parser/parser-input.js 2.5.0

part of parser.less;

class ParserInput {
  String input;         // Less input string
  Contexts context;

  bool autoCommentAbsorb = true;
  List<String> chunks; // chunkified input
  List<CommentPointer> commentStore = [];
  String current;       // current chunk
  int currentPos = 0;   // index of current chunk, in `input`. current[0] == input[currentPos]
  int i = 0;            // current index in `input`
  bool finished = false;
  int furthest = 0;     // furthest index the parser has gone to
  String furthestPossibleErrorMessage; // if this is furthest we got to, this is the probably cause
  int j = 0;            // current chunk in chunks[j]
  List saveStack = [];  // holds state for backtracking

  ParserInput(String this.input, Contexts this.context) {
    start(this.input, context.chunkInput);
  }

  ///
  //Not used in 2.2.0
  bool get notEmpty => current.length > 0;

  String currentForward(int pos) {
    return (pos > current.length - 1) ? '' : current.substring(pos);
  }

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
    currentPos = i;
    saveStack.add(new StackItem(current, i, j));
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

    StackItem state = saveStack.removeLast();
    current = state.current;
    currentPos = i = state.i;
    j = state.j;

//2.2.0
//    parserInput.restore = function(possibleErrorMessage) {
//        if (parserInput.i > furthest || (parserInput.i === furthest && possibleErrorMessage && !furthestPossibleErrorMessage)) {
//            furthest = parserInput.i;
//            furthestPossibleErrorMessage = possibleErrorMessage;
//        }
//        var state = saveStack.pop();
//        current = state.current;
//        currentPos = parserInput.i = state.i;
//        j = state.j;
//    };
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
    if (pos < 0) return false;

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
  $re(tok, [bool caseSensitive = true, int index]) {
    List<String> resultList = [];
    RegExp reg;

    if (tok is String) {
      reg = new RegExp(tok, caseSensitive: caseSensitive);
    } else {
      reg = tok;
    }

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

  ///
  /// Same as $re, but returns first match.
  /// Parse from a RegExp and returns Match.
  ///
  /// [tok] is String to search.
  /// [caseSensitive] true by default. false correspond to 'i'.
  ///
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

  ///
  /// return a String if [tok] character is found.
  ///
  /// [tok] is a String.
  ///
  String $char(String tok) {
    if (currentChar() != tok) return null;
    skipWhitespace(1);
    return tok;
  }

  ///
  /// Returns tok if found at current position
  ///
  String $str(String tok) {
    int tokLength = tok.length;

    // https://jsperf.com/string-startswith/21
    if (!input.startsWith(tok, i)) return null;
    skipWhitespace(tokLength);
    return tok;

//2.4.0 20150315
//  parserInput.$str = function(tok) {
//      var tokLength = tok.length;
//
//      for (var i = 0; i < tokLength; i++) {
//          if (input.charAt(parserInput.i + i) !== tok.charAt(i)) {
//              return null;
//          }
//      }
//
//      skipWhitespace(tokLength);
//      return tok;
//  };
  }

  ///
  /// Returns a "..." or '...' string if found, else null
  ///
  String $quoted() {
    String nextChar;
    String str;

    String startChar = currentChar();
    if (startChar != "'" && startChar != '"') return null;

    int currentPosition = i;
    for (int i = 1; i + currentPosition < input.length; i++) {
      nextChar = charAt(i + currentPosition);
      switch (nextChar) {
        case '\\':
          i++;
          continue;
        case '\r':
        case '\n':
          break;
        case "'":
        case '"':
          if (nextChar == startChar) {
            str = input.substring(currentPosition, currentPosition + i + 1);
            skipWhitespace(i + 1);
            return str;
          }
          break;
        default:
      }
    }
    return null;

//2.4.0 20150315-1345
//  parserInput.$quoted = function() {
//
//      var startChar = input.charAt(parserInput.i);
//      if (startChar !== "'" && startChar !== '"') {
//          return;
//      }
//      var length = input.length,
//          currentPosition = parserInput.i;
//
//      for (var i = 1; i + currentPosition < length; i++) {
//          var nextChar = input.charAt(i + currentPosition);
//          switch(nextChar) {
//              case "\\":
//                  i++;
//                  continue;
//              case "\r":
//              case "\n":
//                  break;
//              case startChar:
//                  var str = input.substr(currentPosition, i + 1);
//                  skipWhitespace(i + 1);
//                  return str;
//              default:
//          }
//      }
//      return null;
//  };
  }

  ///
  bool skipWhitespace(int length) {
    int oldi = i;
    int oldj = j;
    int curr = i - currentPos;
    int endIndex = i + current.length - curr;
    int mem = (i += length);
    int c; //char
    String nextChar;
    CommentPointer comment;

    for (; i < endIndex; i++) {
      c = charCodeAt(i);
      if (autoCommentAbsorb && c == Charcode.SLASH_47) {
        nextChar = charAt(i + 1);
        if (nextChar == '/') {
          comment = new CommentPointer(index: i, isLineComment: true);
          int nextNewLine = input.indexOf('\n', i + 2);

          if (nextNewLine < 0) nextNewLine = endIndex;
          i = nextNewLine;
          comment.text = input.substring(comment.index, i);
          commentStore.add(comment);
          continue;
        } else if (nextChar == '*') {
          int nextStarSlash = input.indexOf('*/', i + 2);
          if (nextStarSlash >= 0) {
            comment = new CommentPointer(
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

    current = currentForward(length + i - mem + curr);
    currentPos = i;

    if (current.isEmpty) {
      if (j < chunks.length - 1) {
        current = chunks[++j];
        skipWhitespace(0); // skip space at the beginning of a chunk
        return true; // things changed
      }
      finished = true;
    }

    return (oldi != i || oldj != j);

//2.4.0 20150315 1345
//  var skipWhitespace = function(length) {
//      var oldi = parserInput.i, oldj = j,
//          curr = parserInput.i - currentPos,
//          endIndex = parserInput.i + current.length - curr,
//          mem = (parserInput.i += length),
//          inp = input,
//          c, nextChar, comment;
//
//      for (; parserInput.i < endIndex; parserInput.i++) {
//          c = inp.charCodeAt(parserInput.i);
//
//          if (parserInput.autoCommentAbsorb && c === CHARCODE_FORWARD_SLASH) {
//              nextChar = inp.charAt(parserInput.i + 1);
//              if (nextChar === '/') {
//                  comment = {index: parserInput.i, isLineComment: true};
//                  var nextNewLine = inp.indexOf("\n", parserInput.i + 2);
//                  if (nextNewLine < 0) {
//                      nextNewLine = endIndex;
//                  }
//                  parserInput.i = nextNewLine;
//                  comment.text = inp.substr(comment.i, parserInput.i - comment.i);
//                  parserInput.commentStore.push(comment);
//                  continue;
//              } else if (nextChar === '*') {
//                  var nextStarSlash = inp.indexOf("*/", parserInput.i + 2);
//                  if (nextStarSlash >= 0) {
//                      comment = {
//                          index: parserInput.i,
//                          text: inp.substr(parserInput.i, nextStarSlash + 2 - parserInput.i),
//                          isLineComment: false
//                      };
//                      parserInput.i += comment.text.length - 1;
//                      parserInput.commentStore.push(comment);
//                      continue;
//                  }
//              }
//              break;
//          }
//
//          if ((c !== CHARCODE_SPACE) && (c !== CHARCODE_LF) && (c !== CHARCODE_TAB) && (c !== CHARCODE_CR)) {
//              break;
//          }
//      }
//
//      current = current.slice(length + parserInput.i - mem + curr);
//      currentPos = parserInput.i;
//
//      if (!current.length) {
//          if (j < chunks.length - 1)
//          {
//              current = chunks[++j];
//              skipWhitespace(0); // skip space at the beginning of a chunk
//              return true; // things changed
//          }
//          parserInput.finished = true;
//      }
//
//      return oldi !== parserInput.i || oldj !== j;
//  };
//2.2.0
//    var skipWhitespace = function(length) {
//        var oldi = parserInput.i, oldj = j,
//            curr = parserInput.i - currentPos,
//            endIndex = parserInput.i + current.length - curr,
//            mem = (parserInput.i += length),
//            inp = input,
//            c, nextChar, comment;
//
//        for (; parserInput.i < endIndex; parserInput.i++) {
//            c = inp.charCodeAt(parserInput.i);
//
//            if (parserInput.autoCommentAbsorb && c === CHARCODE_FORWARD_SLASH) {
//                nextChar = inp.charAt(parserInput.i + 1);
//                if (nextChar === '/') {
//                    comment = {index: parserInput.i, isLineComment: true};
//                    var nextNewLine = inp.indexOf("\n", parserInput.i + 1);
//                    if (nextNewLine < 0) {
//                        nextNewLine = endIndex;
//                    }
//                    parserInput.i = nextNewLine;
//                    comment.text = inp.substr(comment.i, parserInput.i - comment.i);
//                    parserInput.commentStore.push(comment);
//                    continue;
//                } else if (nextChar === '*') {
//                    var haystack = inp.substr(parserInput.i);
//                    var comment_search_result = haystack.match(/^\/\*(?:[^*]|\*+[^\/*])*\*+\//);
//                    if (comment_search_result) {
//                        comment = {
//                            index: parserInput.i,
//                            text: comment_search_result[0],
//                            isLineComment: false
//                        };
//                        parserInput.i += comment.text.length - 1;
//                        parserInput.commentStore.push(comment);
//                        continue;
//                    }
//                }
//                break;
//            }
//
//            if ((c !== CHARCODE_SPACE) && (c !== CHARCODE_LF) && (c !== CHARCODE_TAB) && (c !== CHARCODE_CR)) {
//                break;
//            }
//        }
//
//        current = current.slice(length + parserInput.i - mem + curr);
//        currentPos = parserInput.i;
//
//        if (!current.length) {
//            if (j < chunks.length - 1)
//            {
//                current = chunks[++j];
//                skipWhitespace(0); // skip space at the beginning of a chunk
//                return true; // things changed
//            }
//            parserInput.finished = true;
//        }
//
//        return oldi !== parserInput.i || oldj !== j;
//    };
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

//2.4.0 20150315
//  function expect(arg, msg, index) {
//      // some older browsers return typeof 'function' for RegExp
//      var result = (Object.prototype.toString.call(arg) === '[object Function]') ? arg.call(parsers) : parserInput.$re(arg);
//      if (result) {
//          return result;
//      }
//      error(msg || (typeof arg === 'string' ? "expected '" + arg + "' got '" + parserInput.currentChar() + "'"
//                                             : "unexpected token"));
//  }
  }

  ///
  /// Specialization of expect()
  ///
  //parser.js 2.2.0 56-62
  String expectChar(String arg, [String msg]) {
    if ($char(arg) != null) return arg;

    String message = msg != null ? msg : "expected '$arg' got '${currentChar()}'";
    return error(message);

//2.2.0
//  function expectChar(arg, msg) {
//      if (parserInput.$char(arg)) {
//          return arg;
//      }
//      error(msg || "expected '" + arg + "' got '" + parserInput.currentChar() + "'");
//  }
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
      return r.hasMatch(current);
    }

//2.4.0 20150315-1729
//  parserInput.peek = function(tok) {
//      if (typeof tok === 'string') {
//          for (var i = 0; i < tok.length; i++) {
//              if (input.charAt(parserInput.i + i) !== tok.charAt(i)) {
//                  return false;
//              }
//          }
//          return true;
//      } else {
//          return tok.test(current);
//      }
//  };
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
  /// chunking apparantly makes things quicker (but my tests indicate
  /// it might actually make things slower in node at least)
  /// and it is a non-perfect parse - it can't recognise
  /// unquoted urls, meaning it can't distinguish comments
  /// meaning comments with quotes or {}() in them get 'counted'
  /// and then lead to parse errors.
  /// In addition if the chunking chunks in the wrong place we might
  /// not be able to parse a parser statement in one go
  /// this is officially deprecated but can be switched on via an option
  /// in the case it causes too much performance issues.
  ///
  void start(String str, bool chunkInput){
    i = j = currentPos = furthest = 0;

    if (chunkInput) {
      chunks = new Chunker(str, context).getChunks();
    } else {
      chunks = [str];
    }

    current = chunks[0];

    skipWhitespace(0);

//2.2.0
//    parserInput.start = function(str, chunkInput, failFunction) {
//        input = str;
//        parserInput.i = j = currentPos = furthest = 0;
//
//
//        if (chunkInput) {
//            chunks = chunker(str, failFunction);
//        } else {
//            chunks = [str];
//        }
//
//        current = chunks[0];
//
//        skipWhitespace(0);
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

class StackItem {
  String current;
  int i;
  int j;

  StackItem(String this.current, int this.i, int this.j);
}
