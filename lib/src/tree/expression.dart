//source: less/tree/expression.js 3.0.4 20180622

part of tree.less;

///
class Expression extends Node {
  @override final String          type = 'Expression';
  @override covariant List<Node>  value;

  ///
  bool noSpacing;

  ///
  Expression(List<Node> this.value, {bool this.noSpacing = false}) {
    parens = false;
    parensInOp = false;

    if (value == null) {
      throw new LessExceptionError(new LessError(
          message: 'Expression requires an array parameter'));
    }

//3.0.4 20180622
//var Expression = function (value, noSpacing) {
//    this.value = value;
//    this.noSpacing = noSpacing;
//    if (!value) {
//        throw new Error("Expression requires an array parameter");
//    }
//};
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    value = visitor.visitArray(value);

//2.3.1
//  Expression.prototype.accept = function (visitor) {
//      this.value = visitor.visitArray(this.value);
//  };
  }

  ///
  @override
  Node eval(Contexts context) {
    bool        doubleParen = false;
    final bool  inParenthesis = parens && !parensInOp;
    Node        returnValue;

    if (inParenthesis) context.inParenthesis();
    if (value.length > 1) {
      returnValue = new Expression(
          value.map((Node e) => e?.eval(context)).toList(),
          noSpacing: noSpacing
      );
    } else if (value.length == 1) {
      if (value.first.parens && !value.first.parensInOp) doubleParen = true;
      returnValue = value.first.eval(context);
    } else {
      returnValue = this;
    }
    if (inParenthesis) context.outOfParenthesis();
    if (parens && parensInOp && !(context.isMathOn()) && !doubleParen) {
      returnValue = new Paren(returnValue);
    }
    return returnValue;

//3.0.4 20180622
//Expression.prototype.eval = function (context) {
//    var returnValue,
//        inParenthesis = this.parens && !this.parensInOp,
//        doubleParen = false;
//    if (inParenthesis) {
//        context.inParenthesis();
//    }
//    if (this.value.length > 1) {
//        returnValue = new Expression(this.value.map(function (e) {
//            return e.eval(context);
//        }), this.noSpacing);
//    } else if (this.value.length === 1) {
//        if (this.value[0].parens && !this.value[0].parensInOp) {
//            doubleParen = true;
//        }
//        returnValue = this.value[0].eval(context);
//    } else {
//        returnValue = this;
//    }
//    if (inParenthesis) {
//        context.outOfParenthesis();
//    }
//    if (this.parens && this.parensInOp && !(context.isMathOn()) && !doubleParen) {
//        returnValue = new Paren(returnValue);
//    }
//    return returnValue;
//};
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null) return genCleanCSS(context, output);

    for (int i = 0; i < value.length; i++) {
      value[i].genCSS(context, output);
      if (!noSpacing && i + 1 < value.length) output.add(' ');
    }

//3.0.4 20180622
//Expression.prototype.genCSS = function (context, output) {
//    for (var i = 0; i < this.value.length; i++) {
//        this.value[i].genCSS(context, output);
//        if (!this.noSpacing && i + 1 < this.value.length) {
//            output.add(" ");
//        }
//    }
//};
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    for (int i = 0; i < value.length; i++) {
      output.conditional(' ');
      value[i].genCSS(context, output);
    }
  }

  ///
  @override
  void throwAwayComments() {
    value.retainWhere((Node v) => v is! Comment);

//2.3.1
//  Expression.prototype.throwAwayComments = function () {
//      this.value = this.value.filter(function(v) {
//          return !(v instanceof Comment);
//      });
//  };
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
