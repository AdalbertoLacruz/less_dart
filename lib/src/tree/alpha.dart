//source: less/tree/alpha.js 1.7.5

part of tree.less;

class Alpha extends Node implements EvalNode, ToCSSNode {
  var value; // String, Variable, Dimension

  final String type = 'Alpha';

  Alpha(this.value);

  ///
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);
  }

  ///
  Alpha eval(Env env) {
    if (this.value is EvalNode) return new Alpha(this.value.eval(env));
    return this;
  }

  ///
  void genCSS(Env env, Output output) {
    output.add('alpha(opacity=');

    if (this.value is ToCSSNode) {
      this.value.genCSS(env, output);
    } else {
      output.add(this.value);
    }

    output.add(')');
  }

//    toCSS: tree.toCSS

}