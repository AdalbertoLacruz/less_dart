//source: less/tree/negative.js 2.5.0

part of tree.less;

class Negative extends Node<Node> {

  final String type = 'Negative';

  Negative (Node value){
    this.value = value;
  }

  ///
  void genCSS(Contexts context, Output output) {
    output.add('-');
    value.genCSS(context, output);

//2.3.1
//  Negative.prototype.genCSS = function (context, output) {
//      output.add('-');
//      this.value.genCSS(context, output);
//  };
  }

  ///
  eval(Contexts context) {
    if (context.isMathOn()) {
      return (new Operation('*', [new Dimension(-1), this.value])).eval(context);
    }
    return new Negative(value.eval(context));

//2.3.1
//  Negative.prototype.eval = function (context) {
//      if (context.isMathOn()) {
//          return (new Operation('*', [new Dimension(-1), this.value])).eval(context);
//      }
//      return new Negative(this.value.eval(context));
//  };
  }
}