//source: less/tree/variable-call.js 3.0.0 20170601

part of tree.less;

///
class VariableCall extends Node {
  @override final String  name = null;
  @override final String  type = 'VariableCall';

  ///
  String variable;

  ///
  VariableCall(String this.variable) {
    allowRoot = true;
  }

//3.0.0 20170601
// var VariableCall = function (variable) {
//     this.variable = variable;
//     this.allowRoot = true;
// };

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'variable': variable
  };

  ///
  @override
  Ruleset eval(Contexts context) {
    final DetachedRuleset detachedRuleset = new Variable(variable).eval(context);
    return detachedRuleset.callEval(context);

//3.0.0 20170601
// VariableCall.prototype.eval = function (context) {
//     var detachedRuleset = new Variable(this.variable).eval(context);
//     return detachedRuleset.callEval(context);
// };
  }

  @override
  String toString() => variable;
}
