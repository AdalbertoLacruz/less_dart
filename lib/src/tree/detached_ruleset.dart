//source: less/tree/anonymous.js 1.7.5

part of tree.less;

class DetachedRuleset extends Node implements EvalNode {
  Ruleset ruleset;
  List<Node> frames;

  final String type = 'DetachedRuleset';

  DetachedRuleset(this.ruleset, [this.frames]);

  ///
  void accept(Visitor visitor) {
    this.ruleset = visitor.visit(this.ruleset);
  }

  ///
  DetachedRuleset eval(Env env) {
    List<Node> frames = getValueOrDefault(this.frames, env.frames.sublist(0));
    return new DetachedRuleset(this.ruleset, frames);

//    eval: function (env) {
//        var frames = this.frames || env.frames.slice(0);
//        return new tree.DetachedRuleset(this.ruleset, frames);
//    },
  }

  ///
  Ruleset callEval(Env env) {
    Env ctx = (this.frames != null) ? new Env.evalEnv(env, this.frames.sublist(0)..addAll(env.frames)) : env;
    return this.ruleset.eval(ctx);

//    callEval: function (env) {
//        return this.ruleset.eval(this.frames ? new(tree.evalEnv)(env, this.frames.concat(env.frames)) : env);
//    }
  }
}