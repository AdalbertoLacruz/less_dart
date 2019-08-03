//source: less/parser/parser.js partial 3.0.0 20160719

part of parser.less;

///
/// Used after initial parsing to create nodes on the fly
///
class ParseNode {
  //
  //static Map<int, ParseNode> cache = <int, ParseNode>{};

  /// Parser errors are ignored, so we could return null
  bool ignoreErrors;

  /// We parse a input string, that start at [index] in the original file
  int index;

  /// Parser result
  bool isError = false;

  /// Original input string file information
  FileInfo fileInfo;

  /// The parser
  Parsers parsers;

  /// Output
  List<dynamic> result = <dynamic>[];

  ///
  /// Constructor to partial parse, where [input] is the string to parse,
  /// [index] start number to begin indexing and [fileInfo] the file Info
  /// to attach to created nodes. We could [ignoreErrors].
  ///
  /// Usage example:
  ///
  ///     new ParseNode(input, index, fileInfo).value();
  ///
  /// `result[0]` has the result if isError == false
  ///
  ParseNode(String input, this.index, this.fileInfo) {
    index ??= 0;
    fileInfo ??= FileInfo();
    parsers = Parsers(input, Contexts());
  }

  ///
  /// Wrapper function, called with the specialized [parseFunction]
  ///
  void parse(Function parseFunction) {
    try {
      final int i = parsers.parserInput.i;
      parseFunction();
      if (!parsers.parserInput.end().isFinished) isError = true;
      if (result.isNotEmpty && result.first is Node) {
        result[0]
          ..index = i + index
          ..currentFileInfo = fileInfo;
      }
    } catch (e) {
      isError = true;
      if (e is LessExceptionError) e.error.index += index;
      throw LessExceptionError(
          LessError.transform(e, filename: fileInfo.filename));
    }
  }

//3.0.0 20160719
// function parseNode(str, parseList, currentIndex, fileInfo, callback) {
//     var result, returnNodes = [];
//     var parser = parserInput;
//
//     try {
//         parser.start(str, false, function fail(msg, index) {
//             callback({
//                 message: msg,
//                 index: index + currentIndex
//             });
//         });
//         for(var x = 0, p, i; (p = parseList[x]); x++) {
//             i = parser.i;
//             result = parsers[p]();
//             if (result) {
//                 result._index = i + currentIndex;
//                 result._fileInfo = fileInfo;
//                 returnNodes.push(result);
//             }
//             else {
//                 returnNodes.push(null);
//             }
//         }
//
//         var endInfo = parser.end();
//         if (endInfo.isFinished) {
//             callback(null, returnNodes);
//         }
//         else {
//             callback(true, null);
//         }
//     } catch (e) {
//         throw new LessError({
//             index: e.index + currentIndex,
//             message: e.message
//         }, imports, fileInfo.filename);
//     }
// }

  ///
  /// search for a Ruleset Node
  ///
  Ruleset ruleset() {
    parse(() {
      result.add(parsers.ruleset());
    });
    return isError ? null : result.first;
  }

  ///
  /// search for a Selector Node
  ///
  Selector selector() {
    parse(() {
      result.add(parsers.selector());
    });
    return isError ? null : result.first;
  }

  ///
  /// Search for List<Selector>
  ///
  List<Selector> selectors() {
    parse(() {
      result.add(parsers.selectors());
    });
    return isError ? null : result.first;
  }

  ///
  /// search for Value nodes, with important property
  ///
  List<dynamic> value() {
    parse(() {
      result..add(parsers.value())..add(parsers.important());
    });
    return isError ? null : result;
  }
}
