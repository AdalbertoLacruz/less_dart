//source: less/tree/value.js 1.7.5

part of tree.less;

class Value extends Node implements EvalNode, ToCSSNode {
  List<Node> value;

  final String type = 'Value';

  Value(List<Node> this.value);

  ///
  void accept(Visitor visitor) {
    if (this.value != null) this.value = visitor.visitArray(this.value);
  }

  ///
  Node eval(Env env) {
    if (this.value.length == 1) {
      return this.value.first.eval(env);
    } else {
      return new Value(this.value.map((v){
        return (v as Node).eval(env);
      }).toList());
    }

//    eval: function (env) {
//        if (this.value.length === 1) {
//            return this.value[0].eval(env);
//        } else {
//            return new(tree.Value)(this.value.map(function (v) {
//                return v.eval(env);
//            }));
//        }
//    },
  }

  ///
  void genCSS(Env env, Output output) {
    for (int i = 0; i < this.value.length; i++) {
      this.value[i].genCSS(env, output);
      if (i+1 < this.value.length) output.add((env != null && env.compress) ? ',' : ', ');
    }
  }

//    toCSS: tree.toCSS
}