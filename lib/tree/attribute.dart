//source: less/tree/element.js 1.7.5 lines 45-90

part of tree.less;

class Attribute extends Node implements EvalNode, ToCSSNode {
  var key; // String or Node
  String op; // '=', '^=', ...
  var value; // String or Node

  final String type = 'Attribute';

  Attribute(this.key, this.op, this.value);

  ///
  Attribute eval(Env env) => new Attribute(
        this.key is EvalNode ? this.key.eval(env) : this.key,
        this.op,
        this.value is EvalNode ?  this.value.eval(env) : this.value);

  /// ><
  void genCSS(Env env, Output output) {
    output.add(this.toCSS(env));
  }

  ///
  String toCSS(Env env) {
    String value = (this.key is ToCSSNode) ? (this.key as ToCSSNode).toCSS(env) : this.key;

    if (this.op != null) {
      value += this.op;
      value += (this.value is ToCSSNode) ? (this.value as ToCSSNode).toCSS(env) : this.value;
    }

    return '[${value}]';

//      toCSS: function (env) {
//          var value = this.key.toCSS ? this.key.toCSS(env) : this.key;
//
//          if (this.op) {
//              value += this.op;
//              value += (this.value.toCSS ? this.value.toCSS(env) : this.value);
//          }
//
//          return '[' + value + ']';
//      }
  }
}