//source: less/tree/assignment.js 1.7.5

part of tree.less;

class Assignment extends Node implements ToCSSNode {
  String key;
  Node value;

  final String type = 'Assignment';

  Assignment(String this.key, Node this.value);

  ///
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);
  }

  ///
  Assignment eval(Env env) {
    if (this.value is EvalNode) return new Assignment(this.key, this.value.eval(env));
    return this;
  }

  ///
  void genCSS(Env env, Output output) {
    output.add(this.key + '=');
    if (this.value is EvalNode) {
      this.value.genCSS(env, output);
    } else {
      output.add(this.value);
    }
  }

//    toCSS: tree.toCSS

}