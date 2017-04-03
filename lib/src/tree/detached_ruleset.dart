//source: less/tree/detached-ruleset.js 2.4.0

part of tree.less;

class DetachedRuleset extends Node {
  @override final String type = 'DetachedRuleset';

  List<Node>  frames;
  Ruleset     ruleset;

  DetachedRuleset(this.ruleset, [this.frames]){
    evalFirst = true;
  }

  ///
  @override
  void accept(covariant Visitor visitor) {
    ruleset = visitor.visit(ruleset);

//2.3.1
//  DetachedRuleset.prototype.accept = function (visitor) {
//      this.ruleset = visitor.visit(this.ruleset);
//  };
  }

  ///
  @override
  DetachedRuleset eval(Contexts context) {
    return new DetachedRuleset(ruleset, this.frames ?? context.frames.sublist(0));

//2.3.1
//  DetachedRuleset.prototype.eval = function (context) {
//      var frames = this.frames || context.frames.slice(0);
//      return new DetachedRuleset(this.ruleset, frames);
//  };
  }

  ///
  Ruleset callEval(Contexts context) {
    final Contexts ctx = (frames != null)
        ? new Contexts.eval(context, frames.sublist(0)..addAll(context.frames))
        : context;
    return ruleset.eval(ctx);

//2.3.1
//  DetachedRuleset.prototype.callEval = function (context) {
//      return this.ruleset.eval(this.frames ? new contexts.Eval(context, this.frames.concat(context.frames)) : context);
//  };
  }
}
