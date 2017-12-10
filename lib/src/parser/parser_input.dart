// source: parser/parser-input.js 2.6.0 20160217

part of parser.less;

///
/// Input Management
///
class ParserInput {
  /// If true, skipWhiteSpace store the comments for further
  /// conversion to Comment node
  bool                  autoCommentAbsorb = true;

  /// Store for comments found with skipWhiteSpace,
  /// waiting to be converted to Comment node if possible
  List<CommentPointer>  commentStore = <CommentPointer>[];

  /// Environment variables
  Contexts              context;

  /// End of input reached in processing
  bool                  finished = false;

  /// Furthest index the parser has gone to
  int                   furthest = 0;

  /// If this is furthest we got to, this is the probably cause
  String                furthestPossibleErrorMessage;

  /// Current index in `input`
  int                   i = 0;

  /// Input string with Less code
  final String          input;

  /// Holds state for backtracking
  List<int>             saveStack = <int>[];

  ///
  /// Receives the `input` string and the environment information and reset pointers.
  ///
  ParserInput(String this.input, Contexts this.context) {
    i = furthest = 0;
    skipWhitespace(0);
  }

  /// The input pointer is not at end
  bool get isNotEmpty => i < input.length;

  /// The input pointer is at end
  bool get isEmpty => i >= input.length;

  ///
  /// Get the character in [pos]
  ///
  /// If we get null, the end of input has been reached
  ///
  String charAt(int pos) {
    if (pos >= input.length)
        return null;
    return input[pos];
  }

  ///
  /// Get the character in the actual position
  ///
  String currentChar() => charAt(i);

  ///
  /// Get the next character, from the actual position
  ///
  String nextChar() => charAt(i + 1);

  ///
  /// Get the character code in the [pos]
  ///
  int charCodeAt(int pos) {
    if (pos >= input.length)
        return null;
    return input.codeUnitAt(pos);
  }

  ///
  /// Get the character code in the actual position
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
    if (i > furthest ||
        ((i == furthest) && (possibleErrorMessage != null) &&
        (furthestPossibleErrorMessage == null))) {
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
    final int pos = i + offset;
    if (pos < 0 || pos >= input.length)
        return false;

    final int code = input.codeUnitAt(pos);
    return (code == Charcode.SPACE_32 ||
        code == Charcode.CR_13 ||
        code == Charcode.TAB_9 ||
        code == Charcode.LF_10);

//2.2.0
//    parserInput.isWhitespace = function (offset) {
//        var pos = parserInput.i + (offset || 0),
//            code = input.charCodeAt(pos);
//        return (code === CHARCODE_SPACE || code === CHARCODE_CR || code === CHARCODE_TAB || code === CHARCODE_LF);
//    };
  }

  ///
  /// is White Space Previous Position
  ///
  bool isWhitespacePrevPos() => isWhitespace(-1);

  ///
  /// is white space in the actual position
  ///
  bool isWhitespacePos() => isWhitespace();

  ///
  /// Specialization of $(tok).
  ///
  /// Parse from a [reg] RegExp and returns String or List<String> with the match.
  ///
  /// if [index] is supplied, if match returns `m[index]`
  ///
  dynamic $re(RegExp reg, [int index]) {
    if (isEmpty)
        return null;

    final Match m = reg.matchAsPrefix(input, i);
    if (m == null)
        return null;

    assert(m.end == (m[0].length + i));
    skipWhitespace(m.end);
    if (index != null && m.groupCount >= index)
        return m[index];
    if (m.groupCount == 0)
        return m[0];
    if (m.groupCount == 1)
        return m[1];

    final List<String> resultList = <String>[];
    for (int item = 0; item <= m.groupCount; item++) {
      resultList.add(m[item]);
    }
    return resultList;
  }

  ///
  /// Returns the raw match for [reg] Regular Expression
  ///
  Match $reMatch(RegExp reg) {
    final Match m = reg.matchAsPrefix(input, i);
    if (m == null)
        return null;

    assert(m.end == (m[0].length + i));
    skipWhitespace(m.end);
    return m;
  }

  ///
  /// Returns a String if [tok] character is found.
  ///
  /// [tok] is a String.
  ///
  String $char(String tok) {
    if (currentChar() != tok)
        return null;

    skipWhitespace(i + 1);
    return tok;
  }

  ///
  /// Returns tok if found at current position
  ///
  String $str(String tok) {
    if (isEmpty || !input.startsWith(tok, i))
        return null;

    skipWhitespace(i + tok.length);
    return tok;
  }

  ///
  /// Returns a quoted `"..."` or `'...'` string if found, else null.
  ///
  String $quoted() {
    final String startChar = currentChar();
    if (startChar != "'" && startChar != '"')
        return null;

    final int start = i;
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
            final String str = input.substring(start, end + 1);
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
  /// Assure the input pointer is not a white space. Move forward if one is found.
  ///
  void skipWhitespace(int newi) {
    final int endIndex = input.length;

    i = newi;

    for (; i < endIndex; i++) {
      final int c = charCodeAt(i);
      if (autoCommentAbsorb && c == Charcode.SLASH_47) {
        final String nextChar = charAt(i + 1);
        if (nextChar == '/') {
          final CommentPointer comment = new CommentPointer(index: i, isLineComment: true);
          int nextNewLine = input.indexOf('\n', i + 2);

          if (nextNewLine < 0)
              nextNewLine = endIndex;
          i = nextNewLine;

          comment.text = input.substring(comment.index, i);
          commentStore.add(comment);
          continue;
        } else if (nextChar == '*') {
          final int nextStarSlash = input.indexOf('*/', i + 2);
          if (nextStarSlash >= 0) {
            final CommentPointer comment = new CommentPointer(
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
      if ((c != Charcode.SPACE_32) &&
          (c != Charcode.LF_10) &&
          (c != Charcode.TAB_9) &&
          (c != Charcode.CR_13))
          break;
    }

    if (i == endIndex) {
      finished = true;
    }

//2.6.1 20160401
// function skipWhitespace(length) {
//     var oldi = parserInput.i, oldj = j,
//         curr = parserInput.i - currentPos,
//         endIndex = parserInput.i + current.length - curr,
//         mem = (parserInput.i += length),
//         inp = input,
//         c, nextChar, comment;
//
//     for (; parserInput.i < endIndex; parserInput.i++) {
//         c = inp.charCodeAt(parserInput.i);
//
//         if (parserInput.autoCommentAbsorb && c === CHARCODE_FORWARD_SLASH) {
//             nextChar = inp.charAt(parserInput.i + 1);
//             if (nextChar === '/') {
//                 comment = {index: parserInput.i, isLineComment: true};
//                 var nextNewLine = inp.indexOf("\n", parserInput.i + 2);
//                 if (nextNewLine < 0) {
//                     nextNewLine = endIndex;
//                 }
//                 parserInput.i = nextNewLine;
//                 comment.text = inp.substr(comment.index, parserInput.i - comment.index);
//                 parserInput.commentStore.push(comment);
//                 continue;
//             } else if (nextChar === '*') {
//                 var nextStarSlash = inp.indexOf("*/", parserInput.i + 2);
//                 if (nextStarSlash >= 0) {
//                     comment = {
//                         index: parserInput.i,
//                         text: inp.substr(parserInput.i, nextStarSlash + 2 - parserInput.i),
//                         isLineComment: false
//                     };
//                     parserInput.i += comment.text.length - 1;
//                     parserInput.commentStore.push(comment);
//                     continue;
//                 }
//             }
//             break;
//         }
//
//         if ((c !== CHARCODE_SPACE) && (c !== CHARCODE_LF) && (c !== CHARCODE_TAB) && (c !== CHARCODE_CR)) {
//             break;
//         }
//     }
//
//     current = current.slice(length + parserInput.i - mem + curr);
//     currentPos = parserInput.i;
//
//     if (!current.length) {
//         if (j < chunks.length - 1) {
//             current = chunks[++j];
//             skipWhitespace(0); // skip space at the beginning of a chunk
//             return true; // things changed
//         }
//         parserInput.finished = true;
//     }
//
//     return oldi !== parserInput.i || oldj !== j;
// }
  }

  ///
  /// Thow a error message
  ///
  //parser.js 2.2.0 lines 64-74
  Null error(String msg, [String type]) {
    throw new LessExceptionError(new LessError(
        index: i,
        type: type != null ? type : 'Syntax',
        message: msg,
        context: context)
    );

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
  /// Search for something and throw error if not found
  ///
  ///
  /// [arg] Function, RegExp or String
  /// [index] ????
  /// return String or List<String>
  ///
  dynamic expect(dynamic arg, [String msg, int index]) {
    final dynamic result = (arg is Function) ? arg() : $re(arg);
    if (result != null)
        return result;

    final String message = msg ?? (arg is String)
        ? "expected '$arg' got '${currentChar()}'"
        : 'unexpected token';
    return error(message);

// inside parser.js
//2.6.0 20160217
// function expect(arg, msg, index) {
//     // some older browsers return typeof 'function' for RegExp
//     var result = (arg instanceof Function) ? arg.call(parsers) : parserInput.$re(arg);
//     if (result) {
//         return result;
//     }
//     error(msg || (typeof arg === 'string' ? "expected '" + arg + "' got '" + parserInput.currentChar() + "'"
//                                            : "unexpected token"));
// }
  }

  ///
  /// Search for [arg] and returns it if found. Else throw error with the [msg]
  ///
  //parser.js 2.2.0 56-62
  String expectChar(String arg, [String msg]) {
    if ($char(arg) != null)
        return arg;

    final String message = msg ?? "expected '$arg' got '${currentChar()}'";
    return error(message);
  }

  ///
  /// Same as $(), but don't change the state of the parser,
  /// just return the match.
  /// [tok] = String | RegExp
  ///
  bool peek(dynamic tok) {
    if (isEmpty)
        return false;
    if (tok is String) {
      return input.startsWith(tok, i);
    } else {
      final RegExp r = tok;
      return r.matchAsPrefix(input, i) != null;
    }
  }

  ///
  /// Specialization of peek(), searching for String [tok]
  ///
  bool peekChar(String tok) {
    if (isEmpty)
        return false;
    return input[i] == tok;
  }

  ///
  /// Returns the [input] String
  ///
  String getInput() => input;

  ///
  /// Test if current char is not a number
  ///
  bool peekNotNumeric() {
    if (isEmpty)
        return false;

    final int c = charCodeAtPos();
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
  /// Check if we are at the end of input. Returns the status.
  ///
  ParserStatus end() {
    String message;
    final bool isFinished = (i >= input.length);

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
    final ParserStatus endInfo = end();
    if (!endInfo.isFinished) {
      String message = endInfo.furthestPossibleErrorMessage;

      if (message == null) {
        message = 'Unrecognised input';
        if (endInfo.furthestChar == '}') {
          // ignore: prefer_interpolation_to_compose_strings
          message += ". Possibly missing opening '{'";
        } else if (endInfo.furthestChar == ')') {
          // ignore: prefer_interpolation_to_compose_strings
          message += ". Possibly missing opening '('";
        } else if (endInfo.furthestReachedEnd) {
          // ignore: prefer_interpolation_to_compose_strings
          message += '. Possibly missing something';
        }
      }

      throw new LessExceptionError(new LessError(
        type: 'Parse',
        message: message,
        index: endInfo.furthest,
        filename: context.currentFileInfo?.filename,
        context: context)
      );
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

  ///
  /// For debug, show the input around the currentChar +- [gap]
  ///
  String showAround([int gap = 20]) {
    final int start = math.max(i - gap, 0);
    final int stop = math.min(i + gap, input.length - 1);
    return input.substring(start, stop);
  }
}

// **********************************************

///
/// Data about the Comment found
///
class CommentPointer {
  /// Position in input
  int     index;

  /// false if the comment is inside a line
  bool    isLineComment;

  /// The comment itself
  String  text;

  ///
  CommentPointer({this.index, this.isLineComment, this.text});
}

///
/// What happend in the parser?
///
class ParserStatus {
  /// End reached
  bool    isFinished;

  /// Most advanced  input pointer
  int     furthest;

  /// If is error, why?
  String  furthestPossibleErrorMessage;

  /// We are at end of input?
  bool    furthestReachedEnd;

  /// Most advanced character
  String  furthestChar;

  ///
  ParserStatus(
      {this.isFinished,
      this.furthest,
      this.furthestPossibleErrorMessage,
      this.furthestReachedEnd,
      this.furthestChar});
}
