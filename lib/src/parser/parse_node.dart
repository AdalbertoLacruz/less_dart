//source: less/parser/parser.js partial 3.0.0 20160719

part of parser.less;

///
/// Used after initial parsing to create nodes on the fly
///
class ParseNode {
  ///
  //static Map<int, ParseNode> cache = <int, ParseNode>{};

  ///
  bool ignoreErrors;
  ///
  int index;
  ///
  bool isError = false;
  ///
  FileInfo fileInfo;
  ///
  Parsers parsers;
  ///
  List<dynamic> result = <dynamic>[];

  ///
  /// [input] string to parse
  /// [index] start number to begin indexing
  /// [fileInfo] fileInfo to attach to created nodes
  ///
  /// Use:
  ///     new ParseNode(input, index, fileInfo).value();
  /// result[0] has the result if isError == false
  ///
  ParseNode(String input, int this.index, FileInfo this.fileInfo,
      {bool this.ignoreErrors: false}) {
    index ??= 0;
    fileInfo ??= new FileInfo();
    parsers = new Parsers(input, new Contexts());
}

  ///
  void parse(Function parseFunction) {
    try {
      final int i = parsers.parserInput.i;
      parseFunction();
      parsers.isFinished();
      if (result.isNotEmpty && result.first is Node) {
        result[0]
            ..index = i + index
            ..currentFileInfo = fileInfo;
      }
    } catch (e) {
      isError = true;
      if (ignoreErrors)
          return;

      if (e is LessExceptionError)
          e.error.index += index;
      throw new LessExceptionError(LessError.transform(e, filename: fileInfo.filename));
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
  /// search for Selector Nodes
  ///
  Node selector() {
    parse((){
      result.add(parsers.selector());
      parsers.isFinished();
    });
    return isError ? null : result.first;
  }

  ///
  Ruleset ruleset() {
    parse((){
      result.add(parsers.ruleset());
      parsers.isFinished();
    });
    return isError ? null : result.first;
  }

  ///
  /// search for Value nodes, with important property
  ///
  List<Node> value() {
    parse((){
      result
        ..add(parsers.value())
        ..add(parsers.important());
      parsers.isFinished();
    });
    return isError ? null : result;
  }
}
