//source: less/tree/assignment.js 2.5.0

part of tree.less;

class Assignment extends Node {
  String key;
  Node value;

  final String type = 'Assignment';

  Assignment(String this.key, Node this.value);

  ///
  void accept(Visitor visitor) {
    value = visitor.visit(value);

//2.3.1
//  Assignment.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  Assignment eval(Contexts context) {
    if (value is Node) return new Assignment(key, value.eval(context));
    return this;

//2.3.1
//  Assignment.prototype.eval = function (context) {
//      if (this.value.eval) {
//          return new Assignment(this.key, this.value.eval(context));
//      }
//      return this;
//  };
  }

  ///
  void genCSS(Contexts context, Output output) {
    output.add(key + '=');
    if (value is Node) {
      value.genCSS(context, output);
    } else {
      output.add(value);
    }

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