//source: less/tree/paren.js 1.7.5

part of tree.less;

class Paren extends Node implements EvalNode, ToCSSNode {
  Node value;

  final String type = 'Paren';

  Paren(Node this.value);

  ///
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);
  }

  ///
  void genCSS(Contexts env, Output output) {
    output.add('(');
    this.value.genCSS(env, output);
    output.add(')');
  }

//    toCSS: tree.toCSS,

  ///
  Paren eval(Contexts env) => new Paren(this.value.eval(env));
}