//source: less/tree/ruleset-call.js 1.7.5

part of tree.less;

class RulesetCall extends Node implements EvalNode {
  String variable;

  final String type = 'RulesetCall';

  RulesetCall(String this.variable);

  ///
  void accept(Visitor visitor) {}

  Ruleset eval(Contexts env) {
    DetachedRuleset detachedRuleset = new Variable(this.variable).eval(env);
    return detachedRuleset.callEval(env);
  }
}