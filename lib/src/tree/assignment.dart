//source: less/tree/assignment.js 2.5.0

part of tree.less;

class Assignment extends Node {
  @override final String    name = null;
  @override final String    type = 'Assignment';
  @override covariant Node  value;

  String key;

  ///
  Assignment(String this.key, Node this.value);

  ///
  @override
  void accept(covariant Visitor visitor) {
    value = visitor.visit(value);

//2.3.1
//  Assignment.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  @override
  Assignment eval(Contexts context) =>
      (value is Node) ? new Assignment(key, value.eval(context)) : this;

//2.3.1
//  Assignment.prototype.eval = function (context) {
//      if (this.value.eval) {
//          return new Assignment(this.key, this.value.eval(context));
//      }
//      return this;
//  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('$key=');
    (value is Node) ? value.genCSS(context, output) : output.add(value);

//2.3.1
//  Assignment.prototype.genCSS = function (context, output) {
//      output.add(this.key + '=');
//      if (this.value.genCSS) {
//          this.value.genCSS(context, output);
//      } else {
//          output.add(this.value);
//      }
//  };
  }
}
