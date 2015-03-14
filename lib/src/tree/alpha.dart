//source: less/tree/alpha.js 2.4.0

part of tree.less;

class Alpha extends Node {
  var value; // String, Variable, Dimension

  final String type = 'Alpha';

  Alpha(this.value);

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);

//2.3.1
//  Alpha.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  //2.3.1 ok
  Alpha eval(Contexts context) {
    if (this.value is Node) return new Alpha(this.value.eval(context));
    return this;

//2.3.1
//  Alpha.prototype.eval = function (context) {
//      if (this.value.eval) { return new Alpha(this.value.eval(context)); }
//      return this;
//  };
  }

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add('alpha(opacity=');

    if (this.value is Node) {
      this.value.genCSS(context, output);
    } else {
      output.add(this.value);
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