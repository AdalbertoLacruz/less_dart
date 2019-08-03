//source: less/tree/detached-ruleset.js 3.0.0 20160714

part of tree.less;

///
class DetachedRuleset extends Node {
  @override
  final String type = 'DetachedRuleset';

  ///
  List<Node> frames;

  ///
  Ruleset ruleset;

  ///
  DetachedRuleset(this.ruleset, [this.frames]) {
    evalFirst = true;
    setParent(ruleset, this);

//3.0.0 20160714
// var DetachedRuleset = function (ruleset, frames) {
//     this.ruleset = ruleset;
//     this.frames = frames;
//     this.setParent(this.ruleset, this);
// };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'ruleset': ruleset, 'frames': frames};

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    ruleset = visitor.visit(ruleset) as Ruleset;

//2.3.1
//  DetachedRuleset.prototype.accept = function (visitor) {
//      this.ruleset = visitor.visit(this.ruleset);
//  };
  }

  ///
  @override
  DetachedRuleset eval(Contexts context) =>
      DetachedRuleset(ruleset, frames ?? context.frames.sublist(0));

//3.0.0 20160714
// DetachedRuleset.prototype.eval = function (context) {
//     var frames = this.frames || utils.copyArray(context.frames);
//     return new DetachedRuleset(this.ruleset, frames);
// };

  ///
  Ruleset callEval(Contexts context) {
    final Contexts ctx = (frames != null)
        ? Contexts.eval(context, frames.sublist(0)..addAll(context.frames))
        : context;
    return ruleset.eval(ctx);

//2.3.1
//  DetachedRuleset.prototype.callEval = function (context) {
//      return this.ruleset.eval(this.frames ? new contexts.Eval(context, this.frames.concat(context.frames)) : context);
//  };
  }

  // for genTree
  @override
  void genCSS(Contexts context, Output output) {}

  @override
  String toString() => '';
}
