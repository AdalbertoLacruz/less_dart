//source: less/tree/alpha.js 2.5.0

part of tree.less;

class Alpha extends Node {
  @override final String type = 'Alpha';

  ///
  Alpha(dynamic value) : super.init(value: value); //value = Varaible | Dimension?

  ///
  @override
  void accept(covariant Visitor visitor) {
    value = visitor.visit(value);

//2.3.1
//  Alpha.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  @override
  Alpha eval(Contexts context) =>
      (value is Node) ? new Alpha(value.eval(context)) : this;

//2.3.1
//  Alpha.prototype.eval = function (context) {
//      if (this.value.eval) { return new Alpha(this.value.eval(context)); }
//      return this;
//  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('alpha(opacity=');
    (value is Node) ? value.genCSS(context, output) : output.add(value);
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
