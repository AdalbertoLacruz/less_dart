//source: less/tree/condition.js 2.5.0

part of tree.less;

class Condition extends Node {
  @override final String type = 'Condition';

  int     index;
  Node    lvalue;
  bool    negate;
  String  op;
  Node    rvalue;

  Condition(String op, Node this.lvalue, Node this.rvalue,
      [int this.index, bool this.negate = false]) {
    this.op = op.trim();
  }

  ///
  @override
  void accept(covariant Visitor visitor) {
    lvalue = visitor.visit(lvalue);
    rvalue = visitor.visit(rvalue);

//2.3.1
//  Condition.prototype.accept = function (visitor) {
//      this.lvalue = visitor.visit(this.lvalue);
//      this.rvalue = visitor.visit(this.rvalue);
//  };
  }

  ///
  /// Compare (lvalue op rvalue) returning true or false (in this.evaluated)
  ///
  @override
  Node eval(Contexts context) {
    //
    bool comparation(String op, Node aNode, Node bNode) {
      final bool a = aNode is Condition ? aNode.evaluated : false;
      final bool b = bNode is Condition ? bNode.evaluated : false;

      switch (op) {
        case 'and':
          return a && b;
        case 'or':
          return a || b;
        default:
          switch (Node.compareNodes(aNode, bNode)) {
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

    evaluated = comparation(op, lvalue.eval(context), rvalue.eval(context));
    evaluated = negate ? !evaluated : evaluated;
    return this; //this.evaluated was the js return

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
