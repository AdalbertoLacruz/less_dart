//source: less/tree/condition.js 1.7.5

part of tree.less;

class Condition extends Node implements EvalNode {
  String op;
  Node lvalue;
  Node rvalue;
  int index;
  bool negate;

  final String type = 'Condition';

  Condition (String op, Node this.lvalue, Node this.rvalue, [int this.index, bool this.negate = false]) {
    this.op = op.trim();
  }

  ///
  void accept(Visitor visitor) {
    this.lvalue = visitor.visit(this.lvalue);
    this.rvalue = visitor.visit(this.rvalue);
  }

  ///
  /// Compare (lvalue op rvalue) returning true or false
  /// #
  bool eval(Env env) {
    var a = this.lvalue.eval(env);
    var b = this.rvalue.eval(env);

    int i = this.index;
    bool result;

    bool compare(String op) {
      int result;
      switch (op) {
        case 'and':
          return a && b;
        case 'or':
          return a || b;
        default:
          if (a is CompareNode) {
            result = a.compare(b);
          } else if (b is CompareNode) {
            result = b.compare(a);
          } else {
            throw new LessExceptionError(new LessError(
                type: 'Type',
                message: 'Unable to perform comparison',
                index: i));
          }
          switch (result) {
            case -1:
              return (op == '<' || op == '=<' || op == '<=');
            case 0:
              return (op == '=' || op == '>=' || op == '=<' || op == '<=');
            case 1:
            return (op == '>' || op == '>=');
          }
      }
      return false;
    }

    result = compare(this.op);
    return this.negate ? !result : result;

//    eval: function (env) {
//        var a = this.lvalue.eval(env),
//            b = this.rvalue.eval(env);
//
//        var i = this.index, result;
//
//        result = (function (op) {
//            switch (op) {
//                case 'and':
//                    return a && b;
//                case 'or':
//                    return a || b;
//                default:
//                    if (a.compare) {
//                        result = a.compare(b);
//                    } else if (b.compare) {
//                        result = b.compare(a);
//                    } else {
//                        throw { type: "Type",
//                                message: "Unable to perform comparison",
//                                index: i };
//                    }
//                    switch (result) {
//                        case -1: return op === '<' || op === '=<' || op === '<=';
//                        case  0: return op === '=' || op === '>=' || op === '=<' || op === '<=';
//                        case  1: return op === '>' || op === '>=';
//                    }
//            }
//        })(this.op);
//        return this.negate ? !result : result;
//    }
  }
}