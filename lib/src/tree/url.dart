//source: less/tree/url.js 2.4.0

part of tree.less;

class URL extends Node {
  Node      value;
  int       index;
  FileInfo  currentFileInfo;
  bool      isEvald;

  String type = 'Url';

  ///
  URL(Node this.value, [int this.index, FileInfo this.currentFileInfo, bool this.isEvald = false]);

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);

//2.3.1
//  URL.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add('url(');
    this.value.genCSS(context, output);
    output.add(')');

//2.3.1
//  URL.prototype.genCSS = function (context, output) {
//      output.add("url(");
//      this.value.genCSS(context, output);
//      output.add(")");
//  };
  }

  ///
  //2.3.1 ok
  URL eval(Contexts context) {
    Node val = this.value.eval(context);
    String rootpath;

    if (!this.isEvald) {
      // Add the base path if the URL is relative
      rootpath = (this.currentFileInfo != null) ? this.currentFileInfo.rootpath : null;
      if ((rootpath.isNotEmpty) && (val.value is String) && context.isPathRelative(val.value)) {
        if (val is! Quoted) {
          rootpath = rootpath.replaceAllMapped(new RegExp(r'''[\(\)'"\s]'''), (match){
            return '\\' + match[0];
          });
        }
        val.value = rootpath + val.value;
      }
      val.value = context.normalizePath(val.value);

      // Add url args if enabled
      if (isNotEmpty(context.urlArgs)) {
        RegExp reData = new RegExp(r'^\s*data:');
        Match match = reData.firstMatch(val.value);
        if (match == null) {
          String delimiter = (val.value as String).indexOf('?') == -1 ? '?' : '&';
          String urlArgs = delimiter + context.urlArgs;
          if ((val.value as String).indexOf('#') != -1) {
            val.value = (val.value as String).replaceFirst('#', urlArgs + '#');
          } else {
            val.value += urlArgs;
          }
        }
      }
    }
    return new URL(val, this.index, this.currentFileInfo, true);

//2.3.1
//  URL.prototype.eval = function (context) {
//      var val = this.value.eval(context),
//          rootpath;
//
//      if (!this.isEvald) {
//          // Add the base path if the URL is relative
//          rootpath = this.currentFileInfo && this.currentFileInfo.rootpath;
//          if (rootpath &&
//              typeof val.value === "string" &&
//              context.isPathRelative(val.value)) {
//
//              if (!val.quote) {
//                  rootpath = rootpath.replace(/[\(\)'"\s]/g, function(match) { return "\\" + match; });
//              }
//              val.value = rootpath + val.value;
//          }
//
//          val.value = context.normalizePath(val.value);
//
//          // Add url args if enabled
//          if (context.urlArgs) {
//              if (!val.value.match(/^\s*data:/)) {
//                  var delimiter = val.value.indexOf('?') === -1 ? '?' : '&';
//                  var urlArgs = delimiter + context.urlArgs;
//                  if (val.value.indexOf('#') !== -1) {
//                      val.value = val.value.replace('#', urlArgs + '#');
//                  } else {
//                      val.value += urlArgs;
//                  }
//              }
//          }
//      }
//
//      return new URL(val, this.index, this.currentFileInfo, true);
//  };
  }
}