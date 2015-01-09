//source: less/tree/expression.js 1.7.5

part of tree.less;

class Expression extends Node implements EvalNode, ToCSSNode {
  List<Node> value;
  bool parens = false;  // ()
  bool parensInOp = false;

  final String type = 'Expression';

  Expression(List<Node> this.value);

  ///
  accept(Visitor visitor){
    if (this.value != null) this.value = visitor.visitArray(this.value);
  }

  /// returns Node or List<Node>
  eval(Env env) {
    var returnValue;
    bool inParenthesis = this.parens && !this.parensInOp;
    bool doubleParen = false;

    if (inParenthesis) env.inParenthesis();

    if (this.value.length > 1) {
      returnValue = new Expression(this.value.map((e){
        return (e != null) ? e.eval(env) : null;
      }).toList());
    } else if (this.value.length == 1) {
      if (this.value.first.parens && !this.value.first.parensInOp) doubleParen = true;
      returnValue = this.value.first.eval(env);
    } else {
      returnValue = this;
    }
    if (inParenthesis) env.outOfParenthesis();

    if (this.parens && this.parensInOp && !(env.isMathOn()) && !doubleParen) {
      returnValue = new Paren(returnValue);
    }

    return returnValue;

//      eval: function (env) {
//          var returnValue,
//              inParenthesis = this.parens && !this.parensInOp,
//              doubleParen = false;
//          if (inParenthesis) {
//              env.inParenthesis();
//          }
//          if (this.value.length > 1) {
//              returnValue = new(tree.Expression)(this.value.map(function (e) {
//                  return e.eval(env);
//              }));
//          } else if (this.value.length === 1) {
//              if (this.value[0].parens && !this.value[0].parensInOp) {
//                  doubleParen = true;
//              }
//              returnValue = this.value[0].eval(env);
//          } else {
//              returnValue = this;
//          }
//          if (inParenthesis) {
//              env.outOfParenthesis();
//          }
//          if (this.parens && this.parensInOp && !(env.isMathOn()) && !doubleParen) {
//              returnValue = new(tree.Paren)(returnValue);
//          }
//          return returnValue;
//      },
  }

  ///
  void genCSS(Env env, Output output) {
    for (int i = 0; i < this.value.length; i++) {
      this.value[i].genCSS(env, output);
      if (i + 1 < this.value.length) output.add(' ');
    }
  }

//      toCSS: tree.toCSS,

  ///
  void throwAwayComments() {
    this.value.retainWhere((v) {
      return (v is! Comment);
    });

//      throwAwayComments: function () {
//          this.value = this.value.filter(function(v) {
//              return !(v instanceof tree.Comment);
//          });
//      }
//  };
  }
}