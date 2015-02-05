//source: less/tree/attribute.js 2.3.1

part of tree.less;

class Attribute extends Node {
  var key; // String or Node
  String op; // '=', '^=', ...
  var value; // String or Node

  final String type = 'Attribute';

  Attribute(this.key, this.op, this.value);

  ///
  //2.3.1 ok
  Attribute eval(Contexts context) => new Attribute(
        this.key is Node ? this.key.eval(context) : this.key,
        this.op,
        this.value is Node ?  this.value.eval(context) : this.value);

//2.3.1
//  Attribute.prototype.eval = function (context) {
//      return new Attribute(this.key.eval ? this.key.eval(context) : this.key,
//          this.op, (this.value && this.value.eval) ? this.value.eval(context) : this.value);
//  };

  ///
  //No in tests
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add(this.toCSS(context));

//2.3.1
//  Attribute.prototype.genCSS = function (context, output) {
//      output.add(this.toCSS(context));
//  };
  }

  ///
  //2.3.1 ok
  String toCSS(Contexts context) {
    String value = (this.key is Node) ? this.key.toCSS(context) : this.key;

    if (this.op != null) {
      value += this.op;
      value += (this.value is Node) ? this.value.toCSS(context) : this.value;
    }

    return '[${value}]';

//2.3.1
//  Attribute.prototype.toCSS = function (context) {
//      var value = this.key.toCSS ? this.key.toCSS(context) : this.key;
//
//      if (this.op) {
//          value += this.op;
//          value += (this.value.toCSS ? this.value.toCSS(context) : this.value);
//      }
//
//      return '[' + value + ']';
//  };
  }
}