// source: tree/debug-info.dart 2.4.0

part of tree.less;

///
/// Debug coordinates
/// Example: new LessDebugIngo({lineNumber: 30, fileName: 'file.less'});
///
class DebugInfo {
  int lineNumber;
  String fileName;

  DebugInfo({int this.lineNumber, String fileName}){
    if (path.isAbsolute(fileName)) {
      this.fileName = fileName;
    } else {
      this.fileName = path.normalize(path.absolute(fileName));
    }
  }

  ///
  /// Generates the String with the information
  ///
  //2.3.1 ok
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
    return result != null ? result.toString() : '';

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
  //2.3.1 ok
  StringBuffer asComment() {
    StringBuffer result = new StringBuffer('/* line ')
                                ..write(lineNumber)
                                ..write(', ')
                                ..write(fileName)
                                ..write(' */\n');
    return result;

//2.3.1
//  debugInfo.asComment = function(ctx) {
//      return '/* line ' + ctx.debugInfo.lineNumber + ', ' + ctx.debugInfo.fileName + ' */\n';
//  };
  }

  ///
  //2.3.1 ok
  StringBuffer asMediaQuery() {
    RegExp reFileNameWithProtocol = new RegExp(r'^[a-z]+:\/\/', caseSensitive: false);
    String filenameWithProtocol = fileName;
    if (!reFileNameWithProtocol.hasMatch(filenameWithProtocol)) {
      filenameWithProtocol = 'file://' + filenameWithProtocol;
    }

    String file = filenameWithProtocol.replaceAllMapped(new RegExp(r'([.:\/\\])'), (Match m) {
      String a = m[1];
      if (a == '\\') a = '\/';
      return '\\' + a;
    });

    return new StringBuffer('@media -sass-debug-info{filename{font-family:')
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