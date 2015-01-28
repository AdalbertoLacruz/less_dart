//source: less/tree/operation.js 1.7.5

part of tree.less;

class Operation extends Node implements EvalNode, ToCSSNode {
  String op;
  List<Node> operands;
  bool isSpaced;

  final String type = 'Operation';

  Operation(String op, List this.operands, [bool this.isSpaced = false]) {
    this.op = op.trim();
  }

  ///
  void accept(Visitor visitor) {
    this.operands = visitor.visit(this.operands);
  }

  ///
  eval(Contexts env) {
    Node a = this.operands[0].eval(env);
    Node b = this.operands[1].eval(env);

    if (env.isMathOn()) {
      if (a is Dimension && b is Color) a = (a as Dimension).toColor();
      if (b is Dimension && a is Color) b = (b as Dimension).toColor();
      if (a is! OperateNode) {
        throw new LessExceptionError(new LessError(
            type: 'Operation',
            message: 'Operation on an invalid type'
        ));
      }
      return (a as OperateNode).operate(env, this.op, b);
    } else {
      return new Operation(this.op, [a, b], this.isSpaced);
    }

//    eval: function (env) {
//        var a = this.operands[0].eval(env),
//            b = this.operands[1].eval(env);
//
//        if (env.isMathOn()) {
//            if (a instanceof tree.Dimension && b instanceof tree.Color) {
//                a = a.toColor();
//            }
//            if (b instanceof tree.Dimension && a instanceof tree.Color) {
//                b = b.toColor();
//            }
//            if (!a.operate) {
//                throw { type: "Operation",
//                        message: "Operation on an invalid type" };
//            }
//
//            return a.operate(env, this.op, b);
//        } else {
//            return new(tree.Operation)(this.op, [a, b], this.isSpaced);
//        }
//    },
  }

  ///
  void genCSS(Contexts env, Output output) {
    this.operands[0].genCSS(env, output);
    if (this.isSpaced) output.add(' ');
    output.add(this.op);
    if (this.isSpaced) output.add(' ');
    this.operands[1].genCSS(env, output);
  }

//    toCSS: tree.toCSS

  ///
  //Original out of class (operate)
  static num operateExec(Contexts env, String op, num a, num b) {
    switch (op) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;
        case '/': return a / b;
    }
    return null;

//tree.operate = function (env, op, a, b) {
//    switch (op) {
//        case '+': return a + b;
//        case '-': return a - b;
//        case '*': return a * b;
//        case '/': return a / b;
//    }
//};
  }
}