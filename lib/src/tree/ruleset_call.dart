//source: less/tree/ruleset-call.js 2.4.0

part of tree.less;

class RulesetCall extends Node {
  String variable;

  final String type = 'RulesetCall';

  RulesetCall(String this.variable);

  ///
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