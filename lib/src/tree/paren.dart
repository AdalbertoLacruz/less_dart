//source: less/tree/paren.js 2.4.0

part of tree.less;

class Paren extends Node {
  Node value;

  final String type = 'Paren';

  Paren(Node this.value);

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add('(');
    this.value.genCSS(context, output);
    output.add(')');

//2.3.1
//  Paren.prototype.genCSS = function (context, output) {
//      output.add('(');
//      this.value.genCSS(context, output);
//      output.add(')');
//  };
  }

  ///
  //2.3.1 ok
  Paren eval(Contexts context) => new Paren(this.value.eval(context));

//2.3.1
//  Paren.prototype.eval = function (context) {
//      return new Paren(this.value.eval(context));
//  };
}