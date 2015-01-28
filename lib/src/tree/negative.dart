//source: less/tree/negative.js 1.7.5

part of tree.less;

class Negative extends Node implements EvalNode, ToCSSNode {
  Node value;

  final String type = 'Negative';

  Negative (Node this.value);

  ///
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);
  }

  /// ><
  void genCSS(Contexts env, Output output) {
    output.add('-');
    this.value.genCSS(env, output);
  }

//    toCSS: tree.toCSS,

  ///
  eval(Contexts env) {
    if (env.isMathOn()) {
      return (new Operation('*', [new Dimension(-1), this.value])).eval(env);
    }
    return new Negative(this.value.eval(env));

//    eval: function (env) {
//        if (env.isMathOn()) {
//            return (new(tree.Operation)('*', [new(tree.Dimension)(-1), this.value])).eval(env);
//        }
//        return new(tree.Negative)(this.value.eval(env));
//    }
  }
}