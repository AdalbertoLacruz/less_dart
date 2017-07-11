//source: less/tree/url.js 2.5.0

part of tree.less;

///
class URL extends Node {
  @override String          type = 'Url';
  @override covariant Node  value;

  ///
  int   index;
  ///
  bool  isEvald;

  ///
  URL(Node this.value,
      {int this.index, FileInfo currentFileInfo, bool this.isEvald = false})
      : super.init(currentFileInfo: currentFileInfo);

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    value = visitor.visit(value);

//2.3.1
//  URL.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('url(');
    value.genCSS(context, output);
    output.add(')');

//2.3.1
//  URL.prototype.genCSS = function (context, output) {
//      output.add("url(");
//      this.value.genCSS(context, output);
//      output.add(")");
//  };
  }

  ///
  @override
  URL eval(Contexts context) {
    final Node val = value.eval(context);
    String rootpath;

    if (!isEvald) {
      // Add the base path if the URL is relative
      rootpath = (currentFileInfo != null) ? currentFileInfo.rootpath : null;
      if (rootpath.isNotEmpty &&
          (val.value is String) &&
          context.isPathRelative(val.value)) {
        if (val is! Quoted) {
          rootpath = rootpath.replaceAllMapped(
              new RegExp(r'''[\(\)'"\s]'''), (Match match) => '\\${match[0]}');
        }
        // ignore: prefer_interpolation_to_compose_strings
        val.value = rootpath + val.value;
      }
      val.value = context.normalizePath(val.value);

      // Add url args if enabled
      if (isNotEmpty(context.urlArgs)) {
        final RegExp reData = new RegExp(r'^\s*data:');
        final Match match = reData.firstMatch(val.value);
        if (match == null) {
          final String delimiter =
              !(val.value as String).contains('?') ? '?' : '&';
          // ignore: prefer_interpolation_to_compose_strings
          final String urlArgs = delimiter + context.urlArgs;
          if ((val.value as String).contains('#')) {
            val.value = (val.value as String).replaceFirst('#', '$urlArgs#');
          } else {
            // ignore: prefer_interpolation_to_compose_strings
            val.value += urlArgs;
          }
        }
      }
    }
    return new URL(val,
        index: index,
        currentFileInfo: currentFileInfo,
        isEvald: true);

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

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
