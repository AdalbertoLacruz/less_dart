//source: less/tree/detached-ruleset.js 2.3.1

part of tree.less;

class DetachedRuleset extends Node implements EvalNode {
  Ruleset ruleset;
  List<Node> frames;

  bool evalFirst = true;
  final String type = 'DetachedRuleset';

  DetachedRuleset(this.ruleset, [this.frames]);

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.ruleset = visitor.visit(this.ruleset);

//2.3.1
//  DetachedRuleset.prototype.accept = function (visitor) {
//      this.ruleset = visitor.visit(this.ruleset);
//  };
  }

  ///
  //2.3.1 ok
  DetachedRuleset eval(Contexts context) {
    List<Node> frames = getValueOrDefault(this.frames, context.frames.sublist(0));
    return new DetachedRuleset(this.ruleset, frames);

//2.3.1
//  DetachedRuleset.prototype.eval = function (context) {
//      var frames = this.frames || context.frames.slice(0);
//      return new DetachedRuleset(this.ruleset, frames);
//  };
  }

  ///
  //2.3.1 ok
  Ruleset callEval(Contexts context) {
    Contexts ctx = (this.frames != null) ? new Contexts.eval(context, this.frames.sublist(0)..addAll(context.frames)) : context;
    return this.ruleset.eval(ctx);

//2.3.1
//  DetachedRuleset.prototype.callEval = function (context) {
//      return this.ruleset.eval(this.frames ? new contexts.Eval(context, this.frames.concat(context.frames)) : context);
//  };
  }
}