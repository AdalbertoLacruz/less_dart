//source: less/tree/attribute.js 2.5.0

part of tree.less;

class Attribute extends Node {
  @override final String  name = null;
  @override final String  type = 'Attribute';

  dynamic key; // String or Node
  String  op; // '=', '^=', ...

  ///
  Attribute(this.key, this.op, dynamic value)
      : super.init(value: value);

  ///
  @override
  Attribute eval(Contexts context) => new Attribute(
      key is Node ? key.eval(context) : key,
      op,
      value is Node ? value.eval(context) : value);

//2.3.1
//  Attribute.prototype.eval = function (context) {
//      return new Attribute(this.key.eval ? this.key.eval(context) : this.key,
//          this.op, (this.value && this.value.eval) ? this.value.eval(context) : this.value);
//  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add(toCSS(context));

//2.3.1
//  Attribute.prototype.genCSS = function (context, output) {
//      output.add(this.toCSS(context));
//  };
  }

  ///
  @override
  String toCSS(Contexts context) {
    String value = (key is Node) ? key.toCSS(context) : key;

    if (op != null) {
      final String attr = (this.value is Node)
          ? this.value.toCSS(context)
          : this.value;
      value = '$value$op$attr';
    }

    return '[$value]';

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
