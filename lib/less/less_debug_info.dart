// source: less/tree.js 1.7.5 lines 3-34

library debugInfo.less;

import 'package:path/path.dart' as path;

import 'env.dart';

///
/// Debug coordinates
/// ex. new LessDebugIngo({lineNumber: 30, fileName: 'file.less'});
///
class LessDebugInfo {
  int lineNumber;
  String fileName;

  LessDebugInfo({int this.lineNumber, String fileName}){
    if (path.isAbsolute(fileName)) {
      this.fileName = fileName;
    } else {
      this.fileName = path.normalize(path.absolute(fileName));
    }
  }

  ///
  String toOutput(Env env, [String lineSeparator = '']) {
    StringBuffer result;

    if (env.dumpLineNumbers != null && !env.compress) {
      switch (env.dumpLineNumbers) {
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
  }

  ///
  StringBuffer asComment() {
    StringBuffer result = new StringBuffer('/* line ')
                                ..write(lineNumber)
                                ..write(', ')
                                ..write(fileName)
                                ..write(' */\n');
    return result;
  }

  ///
  StringBuffer asMediaQuery() {
    String file = ('file://' + fileName).replaceAllMapped(new RegExp(r'([.:\/\\])'), (Match m) {
      String a = m[1];
      if (a == '\\') a = '\/';
      return '\\' + a;
    });
    StringBuffer result = new StringBuffer('@media -sass-debug-info{filename{font-family:')
            //..write('file://')
            ..write(file)
            ..write('}line{font-family:\\00003')
            ..write(lineNumber)
            ..write('}}\n');


    return result;
  }

//  tree.debugInfo.asMediaQuery = function(ctx) {
//    return '@media -sass-debug-info{filename{font-family:' +
//        ('file://' + ctx.debugInfo.fileName).replace(/([.:\/\\])/g, function (a) {
//            if (a == '\\') {
//                a = '\/';
//            }
//            return '\\' + a;
//        }) +
//        '}line{font-family:\\00003' + ctx.debugInfo.lineNumber + '}}\n';
//};

//tree.debugInfo = function(env, ctx, lineSeperator) {
//    var result="";
//    if (env.dumpLineNumbers && !env.compress) {
//        switch(env.dumpLineNumbers) {
//            case 'comments':
//                result = tree.debugInfo.asComment(ctx);
//                break;
//            case 'mediaquery':
//                result = tree.debugInfo.asMediaQuery(ctx);
//                break;
//            case 'all':
//                result = tree.debugInfo.asComment(ctx) + (lineSeperator || "") + tree.debugInfo.asMediaQuery(ctx);
//                break;
//        }
//    }
//    return result;
//};

//
//tree.debugInfo.asComment = function(ctx) {
//    return '/* line ' + ctx.debugInfo.lineNumber + ', ' + ctx.debugInfo.fileName + ' */\n';
//};
//
//tree.debugInfo.asMediaQuery = function(ctx) {
//    return '@media -sass-debug-info{filename{font-family:' +
//        ('file://' + ctx.debugInfo.fileName).replace(/([.:\/\\])/g, function (a) {
//            if (a == '\\') {
//                a = '\/';
//            }
//            return '\\' + a;
//        }) +
//        '}line{font-family:\\00003' + ctx.debugInfo.lineNumber + '}}\n';
//};

}