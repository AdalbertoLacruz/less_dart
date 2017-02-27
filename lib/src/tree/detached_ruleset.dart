//source: less/tree/detached-ruleset.js 2.4.0

part of tree.less;

class DetachedRuleset extends Node {
  Ruleset ruleset;
  List<Node> frames;

  final String type = 'DetachedRuleset';

  DetachedRuleset(this.ruleset, [this.frames]){
    evalFirst = true;
  }

  ///
  void accept(covariant Visitor visitor) {
    ruleset = visitor.visit(ruleset);

//2.3.1
//  DetachedRuleset.prototype.accept = function (visitor) {
//      this.ruleset = visitor.visit(this.ruleset);
//  };
  }

  ///
  DetachedRuleset eval(Contexts context) {
    List<Node> frames = getValueOrDefault(this.frames, context.frames.sublist(0));
    return new DetachedRuleset(ruleset, frames);

//2.3.1
//  DetachedRuleset.prototype.eval = function (context) {
//      var frames = this.frames || context.frames.slice(0);
//      return new DetachedRuleset(this.ruleset, frames);
//  };
  }

  ///
  Ruleset callEval(Contexts context) {
    Contexts ctx = (frames != null) ? new Contexts.eval(context, frames.sublist(0)..addAll(context.frames)) : context;
    return ruleset.eval(ctx);

//2.3.1
//  DetachedRuleset.prototype.callEval = function (context) {
//      return this.ruleset.eval(this.frames ? new contexts.Eval(context, this.frames.concat(context.frames)) : context);
//  };
  }
}
