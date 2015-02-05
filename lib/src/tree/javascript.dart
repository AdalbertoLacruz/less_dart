//source: less/tree/javascript.js 2.3.1

part of tree.less;

class JavaScript extends Node with JsEvalNodeMixin implements EvalNode {
  String expression;
  bool escaped;
  int index;
  FileInfo currentFileInfo;

  final String type = 'JavaScript';

  ///
  //2.3.1 ok
  JavaScript(String this.expression, bool this.escaped, int this.index, this.currentFileInfo);

  // Not supported javascript
  eval(context) {
    return new Anonymous(this.expression);

//2.3.1
//  JavaScript.prototype.eval = function(context) {
//      var result = this.evaluateJavaScript(this.expression, context);
//
//      if (typeof(result) === 'number') {
//          return new Dimension(result);
//      } else if (typeof(result) === 'string') {
//          return new Quoted('"' + result + '"', result, this.escaped, this.index);
//      } else if (Array.isArray(result)) {
//          return new Anonymous(result.join(', '));
//      } else {
//          return new Anonymous(result);
//      }
//  };
  }
}