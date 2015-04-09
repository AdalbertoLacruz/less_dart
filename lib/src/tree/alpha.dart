//source: less/tree/alpha.js 2.5.0

part of tree.less;

class Alpha extends Node {
  var value; // String, Variable, Dimension

  final String type = 'Alpha';

  Alpha(this.value);

  ///
  void accept(Visitor visitor) {
    value = visitor.visit(value);

//2.3.1
//  Alpha.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  Alpha eval(Contexts context) {
    if (value is Node) return new Alpha(value.eval(context));
    return this;

//2.3.1
//  Alpha.prototype.eval = function (context) {
//      if (this.value.eval) { return new Alpha(this.value.eval(context)); }
//      return this;
//  };
  }

  ///
  void genCSS(Contexts context, Output output) {
    output.add('alpha(opacity=');

    if (value is Node) {
      value.genCSS(context, output);
    } else {
      output.add(value);
    }

    output.add(')');

//2.3.1
//  Alpha.prototype.genCSS = function (context, output) {
//      output.add("alpha(opacity=");
//
//      if (this.value.genCSS) {
//          this.value.genCSS(context, output);
//      } else {
//          output.add(this.value);
//      }
//
//      output.add(")");
//  };
  }
}