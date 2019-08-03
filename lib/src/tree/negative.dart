//source: less/tree/negative.js 2.5.0

part of tree.less;

///
class Negative extends Node {
  @override
  final String type = 'Negative';

  @override
  covariant Node value;

  ///
  Negative(this.value);

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField => <String, dynamic>{'value': value};

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
  Node eval(Contexts context) => context.isMathOn()
      ? Operation('*', <Node>[Dimension(-1), value]).eval(context)
      : Negative(value.eval(context));

//2.3.1
//  Negative.prototype.eval = function (context) {
//      if (context.isMathOn()) {
//          return (new Operation('*', [new Dimension(-1), this.value])).eval(context);
//      }
//      return new Negative(this.value.eval(context));
//  };

  @override
  String toString() {
    final Output output = Output();
    genCSS(null, output);
    return output.toString();
  }
}
