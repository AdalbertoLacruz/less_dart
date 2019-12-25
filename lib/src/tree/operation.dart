//source: less/tree/operation.js 3.9.0 20190221

part of tree.less;

///
class Operation extends Node {
  @override
  final String type = 'Operation';

  ///
  bool isSpaced;

  ///
  String op;

  ///
  Operation(String op, List<Node> operands, {this.isSpaced = false})
      : super.init(operands: operands) {
    this.op = op.trim();

//2.3.1
//  var Operation = function (op, operands, isSpaced) {
//      this.op = op.trim();
//      this.operands = operands;
//      this.isSpaced = isSpaced;
//  };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'op': op, 'operands': operands};

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    operands = visitor.visitArray(operands);

//3.9.0 20190221
//  Operation.prototype.accept = function (visitor) {
//    this.operands = visitor.visitArray(this.operands);
//  };
  }

  ///
  @override
  Node eval(Contexts context) {
    var a = operands[0].eval(context);
    var b = operands[1].eval(context);
    String op;

    if (context.isMathOn(this.op)) {
      op = this.op == './' ? '/' : this.op;
      if (a is Dimension && b is Color) a = (a as Dimension).toColor();
      if (b is Dimension && a is Color) b = (b as Dimension).toColor();
      if (a is! OperateNode) {
        if (a is Operation &&
            a.op == '/' &&
            context.math == MathConstants.parensDivision) {
          return Operation(this.op, <Node>[a, b], isSpaced: isSpaced);
        }
        throw LessExceptionError(LessError(
            type: 'Operation', message: 'Operation on an invalid type'));
      }
      //Only for Dimension | Color
      return (b is Dimension)
          ? (a as OperateNode<Dimension>).operate(context, op, b)
          : (a as OperateNode<Color>).operate(context, op, b);
    } else {
      return Operation(this.op, <Node>[a, b], isSpaced: isSpaced);
    }

// 3.5.3 20180707
//  Operation.prototype.eval = function (context) {
//      var a = this.operands[0].eval(context),
//          b = this.operands[1].eval(context),
//          op;
//
//      if (context.isMathOn(this.op)) {
//          op = this.op === './' ? '/' : this.op;
//          if (a instanceof Dimension && b instanceof Color) {
//              a = a.toColor();
//          }
//          if (b instanceof Dimension && a instanceof Color) {
//              b = b.toColor();
//          }
//          if (!a.operate) {
//              if (a instanceof Operation && a.op === '/' && context.math === MATH.PARENS_DIVISION) {
//                  return new Operation(this.op, [a, b], this.isSpaced);
//              }
//              throw { type: 'Operation',
//                  message: 'Operation on an invalid type' };
//          }
//
//          return a.operate(context, op, b);
//      } else {
//          return new Operation(this.op, [a, b], this.isSpaced);
//      }
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    operands[0].genCSS(context, output);
    if (isSpaced) output.add(' ');
    output.add(op);
    if (isSpaced) output.add(' ');
    operands[1].genCSS(context, output);

//2.3.1
//  Operation.prototype.genCSS = function (context, output) {
//      this.operands[0].genCSS(context, output);
//      if (this.isSpaced) {
//          output.add(" ");
//      }
//      output.add(this.op);
//      if (this.isSpaced) {
//          output.add(" ");
//      }
//      this.operands[1].genCSS(context, output);
//  };
  }

  @override
  String toString() {
    final output = Output();
    genCSS(null, output);
    return output.toString();
  }
}
