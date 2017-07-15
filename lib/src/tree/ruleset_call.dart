//source: less/tree/ruleset-call.js 2.6.1 20160202

part of tree.less;

///
class RulesetCall extends Node {
  @override final String  name = null;
  @override final String  type = 'RulesetCall';

  ///
  String variable;

  ///
  RulesetCall(String this.variable) {
    allowRoot = true;
  }

//2.6.1 20160202
// var RulesetCall = function (variable) {
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

//2.3.1
//  RulesetCall.prototype.eval = function (context) {
//      var detachedRuleset = new Variable(this.variable).eval(context);
//      return detachedRuleset.callEval(context);
//  };
  }

  @override
  String toString() => variable;
}
