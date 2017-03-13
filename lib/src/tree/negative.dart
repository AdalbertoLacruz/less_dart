//source: less/tree/negative.js 2.5.0

part of tree.less;

class Negative extends Node {
  @override final String    type = 'Negative';
  @override covariant Node  value;

  Negative (Node value){
    this.value = value;
  }

  ///
  @override
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
  @override
  Node eval(Contexts context) {
    if (context.isMathOn()) {
      return (new Operation('*', <Node>[new Dimension(-1), this.value])).eval(context);
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
