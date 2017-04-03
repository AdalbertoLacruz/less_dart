//source: less/tree/expression.js 2.5.0

part of tree.less;

class Expression extends Node {
  @override final String          type = 'Expression';
  @override covariant List<Node>  value;

  ///
  Expression(List<Node> this.value) {
    parens = false;
    parensInOp = false;

    if (this.value == null) {
      throw new LessExceptionError(
          new LessError(message: 'Expression requires an array parameter'));
    }

//2.3.1
//  var Expression = function (value) {
//      this.value = value;
//      if (!value) {
//          throw new Error("Expression requires an array parameter");
//      }
//  };
  }

  ///
  @override
  void accept(covariant Visitor visitor){
    value = visitor.visitArray(value);

//2.3.1
//  Expression.prototype.accept = function (visitor) {
//      this.value = visitor.visitArray(this.value);
//  };
  }

  ///
  @override
  Node eval(Contexts context) {
    Node returnValue;
    final bool inParenthesis = parens && !parensInOp;
    bool doubleParen = false;

    if (inParenthesis) context.inParenthesis();

    if (value.length > 1) {
      returnValue = new Expression(value.map((Node e) => e?.eval(context)).toList());
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

//2.3.1
//  Expression.prototype.eval = function (context) {
//      var returnValue,
//          inParenthesis = this.parens && !this.parensInOp,
//          doubleParen = false;
//      if (inParenthesis) {
//          context.inParenthesis();
//      }
//      if (this.value.length > 1) {
//          returnValue = new Expression(this.value.map(function (e) {
//              return e.eval(context);
//          }));
//      } else if (this.value.length === 1) {
//          if (this.value[0].parens && !this.value[0].parensInOp) {
//              doubleParen = true;
//          }
//          returnValue = this.value[0].eval(context);
//      } else {
//          returnValue = this;
//      }
//      if (inParenthesis) {
//          context.outOfParenthesis();
//      }
//      if (this.parens && this.parensInOp && !(context.isMathOn()) && !doubleParen) {
//          returnValue = new Paren(returnValue);
//      }
//      return returnValue;
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null) return genCleanCSS(context, output);

    for (int i = 0; i < value.length; i++) {
      value[i].genCSS(context, output);
      if (i + 1 < value.length) output.add(' ');
    }

//2.3.1
//  Expression.prototype.genCSS = function (context, output) {
//      for(var i = 0; i < this.value.length; i++) {
//          this.value[i].genCSS(context, output);
//          if (i + 1 < this.value.length) {
//              output.add(" ");
//          }
//      }
//  };
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
    value.retainWhere((Node v) {
      return (v is! Comment);
    });

//2.3.1
//  Expression.prototype.throwAwayComments = function () {
//      this.value = this.value.filter(function(v) {
//          return !(v instanceof Comment);
//      });
//  };
  }
}
