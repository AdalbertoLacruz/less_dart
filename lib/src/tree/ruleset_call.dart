//source: less/tree/ruleset-call.js 2.3.1

part of tree.less;

class RulesetCall extends Node implements EvalNode {
  String variable;

  final String type = 'RulesetCall';

  RulesetCall(String this.variable);

  ///
  //2.3.1 TODO remove
  void accept(Visitor visitor) {}

  ///
  //2.3.1
  Ruleset eval(Contexts context) {
    DetachedRuleset detachedRuleset = new Variable(this.variable).eval(context);
    return detachedRuleset.callEval(context);

//2.3.1
//  RulesetCall.prototype.eval = function (context) {
//      var detachedRuleset = new Variable(this.variable).eval(context);
//      return detachedRuleset.callEval(context);
//  };
  }
}