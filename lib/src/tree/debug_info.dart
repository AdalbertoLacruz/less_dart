// source: tree/debug-info.dart 2.5.0

part of tree.less;

///
/// Debug coordinates
/// Example: new LessDebugIngo({lineNumber: 30, fileName: 'file.less'});
///
class DebugInfo {
  ///
  String fileName;

  ///
  int lineNumber;

  ///
  DebugInfo({this.lineNumber, String fileName}) {
    // fileName must be != null
    this.fileName = (path_lib.isAbsolute(fileName))
        ? fileName
        : path_lib.normalize(path_lib.absolute(fileName));
  }

  ///
  /// Generates the String with the information
  ///
  String toOutput(Contexts context, [String lineSeparator = '']) {
    StringBuffer result;

    if (context.dumpLineNumbers != null && !context.compress) {
      switch (context.dumpLineNumbers) {
        case 'comments':
          result = asComment();
          break;
        case 'mediaquery':
          result = asMediaQuery();
          break;
        case 'all':
          result = asComment();
          result.write(lineSeparator);
          result.write(asMediaQuery());
      }
    }
    return result?.toString() ?? '';

//2.3.1
//  var debugInfo = function(context, ctx, lineSeparator) {
//      var result = "";
//      if (context.dumpLineNumbers && !context.compress) {
//          switch(context.dumpLineNumbers) {
//              case 'comments':
//                  result = debugInfo.asComment(ctx);
//                  break;
//              case 'mediaquery':
//                  result = debugInfo.asMediaQuery(ctx);
//                  break;
//              case 'all':
//                  result = debugInfo.asComment(ctx) + (lineSeparator || "") + debugInfo.asMediaQuery(ctx);
//                  break;
//          }
//      }
//      return result;
//  };
  }

  ///
  StringBuffer asComment() => StringBuffer('/* line ')
    ..write(lineNumber)
    ..write(', ')
    ..write(fileName)
    ..write(' */\n');

//2.3.1
//  debugInfo.asComment = function(ctx) {
//      return '/* line ' + ctx.debugInfo.lineNumber + ', ' + ctx.debugInfo.fileName + ' */\n';
//  };

  ///
  StringBuffer asMediaQuery() {
    var filenameWithProtocol = fileName;
    final reFileNameWithProtocol =
        RegExp(r'^[a-z]+:\/\/', caseSensitive: false);

    if (!reFileNameWithProtocol.hasMatch(filenameWithProtocol)) {
      filenameWithProtocol = 'file://$filenameWithProtocol';
    }

    final file =
        filenameWithProtocol.replaceAllMapped(RegExp(r'([.:\/\\])'), (Match m) {
      var a = m[1];
      if (a == '\\') a = '\/';
      return '\\$a';
    });

    return StringBuffer('@media -sass-debug-info{filename{font-family:')
      ..write(file)
      ..write('}line{font-family:\\00003')
      ..write(lineNumber)
      ..write('}}\n');

//2.3.1
//  debugInfo.asMediaQuery = function(ctx) {
//      var filenameWithProtocol = ctx.debugInfo.fileName;
//      if (!/^[a-z]+:\/\//i.test(filenameWithProtocol)) {
//          filenameWithProtocol = 'file://' + filenameWithProtocol;
//      }
//      return '@media -sass-debug-info{filename{font-family:' +
//          filenameWithProtocol.replace(/([.:\/\\])/g, function (a) {
//              if (a == '\\') {
//                  a = '\/';
//              }
//              return '\\' + a;
//          }) +
//          '}line{font-family:\\00003' + ctx.debugInfo.lineNumber + '}}\n';
//  };
  }
}
