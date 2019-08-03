//source: less/tree/javascript.js 3.5.0.beta.6 2080704

part of tree.less;

///
class JavaScript extends Node with JsEvalNodeMixin {
  @override
  final String type = 'JavaScript';

  ///
  bool escaped;

  ///
  String expression;

  ///
  JavaScript(this.expression,
      {this.escaped, int index, FileInfo currentFileInfo}) {
    // ignore: prefer_initializing_formals
    this.index = index;
    // ignore: prefer_initializing_formals
    this.currentFileInfo = currentFileInfo;

//3.0.0 20160714
// var JavaScript = function (string, escaped, index, currentFileInfo) {
//     this.escaped = escaped;
//     this.expression = string;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
// };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'expression': expression};

  // Not supported javascript
  @override
  Anonymous eval(Contexts context) => Anonymous(expression);

// 3.5.0.beta.6 20180704
//  JavaScript.prototype.eval = function(context) {
//      var result = this.evaluateJavaScript(this.expression, context);
//      var type = typeof result;
//
//      if (type === 'number' && !isNaN(result)) {
//          return new Dimension(result);
//      } else if (type === 'string') {
//          return new Quoted('"' + result + '"', result, this.escaped, this._index);
//      } else if (Array.isArray(result)) {
//          return new Anonymous(result.join(', '));
//      } else {
//          return new Anonymous(result);
//      }
//  };

  //for genTree
  @override
  void genCSS(Contexts context, Output output) {
    final String escape = escaped ? '~' : '';
    output.add('$escape`$expression`');
  }

  @override
  String toString() {
    final String escape = escaped ? '~' : '';
    return '$escape`$expression`';
  }
}
