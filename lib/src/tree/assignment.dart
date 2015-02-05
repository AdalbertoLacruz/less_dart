//source: less/tree/assignment.js 2.3.1

part of tree.less;

class Assignment extends Node {
  String key;
  Node value;

  final String type = 'Assignment';

  Assignment(String this.key, Node this.value);

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);

//2.3.1
//  Assignment.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  //2.3.1 ok
  Assignment eval(Contexts context) {
    if (this.value is Node) return new Assignment(this.key, this.value.eval(context));
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
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add(this.key + '=');
    if (this.value is Node) {
      this.value.genCSS(context, output);
    } else {
      output.add(this.value);
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