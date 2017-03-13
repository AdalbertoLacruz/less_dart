//source: less/tree/javascript.js 2.5.0

part of tree.less;

class JavaScript extends Node with JsEvalNodeMixin {
  @override final String type = 'JavaScript';

  bool    escaped;
  String  expression;

  ///
  JavaScript(String this.expression, bool this.escaped, int index, FileInfo currentFileInfo){
    this.index = index;
    this.currentFileInfo = currentFileInfo;
  }

  // Not supported javascript
  @override
  Anonymous eval(Contexts context) {
    return new Anonymous(expression);

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
