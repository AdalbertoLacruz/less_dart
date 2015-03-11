//source: less/tree/condition.js 2.4.0

part of tree.less;

class Condition extends Node {
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

//2.3.1
//  Condition.prototype.accept = function (visitor) {
//      this.lvalue = visitor.visit(this.lvalue);
//      this.rvalue = visitor.visit(this.rvalue);
//  };
  }

  ///
  /// Compare (lvalue op rvalue) returning true or false
  ///
  //2.3.1 ok
  bool eval(Contexts context) {
    bool comparation(String op, a, b) {
      switch (op) {
        case 'and': return a && b;
        case 'or':  return a || b;
        default:
          switch (Node.compareNodes(a, b)) {
            case -1:
              return (op == '<' || op == '=<' || op == '<=');
            case 0:
              return (op == '=' || op == '>=' || op == '=<' || op == '<=');
            case 1:
              return (op == '>' || op == '>=');
            default:
              return false;
          }
        }
    }
    bool result = comparation(this.op, this.lvalue.eval(context), this.rvalue.eval(context));
    return this.negate ? !result : result;

//2.3.1
//  Condition.prototype.eval = function (context) {
//      var result = (function (op, a, b) {
//          switch (op) {
//              case 'and': return a && b;
//              case 'or':  return a || b;
//              default:
//                  switch (Node.compare(a, b)) {
//                      case -1: return op === '<' || op === '=<' || op === '<=';
//                      case  0: return op === '=' || op === '>=' || op === '=<' || op === '<=';
//                      case  1: return op === '>' || op === '>=';
//                          default: return false;
//                  }
//          }
//      })(this.op, this.lvalue.eval(context), this.rvalue.eval(context));
//
//      return this.negate ? !result : result;
//  };
  }
}