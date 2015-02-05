//source: less/tree/value.js 2.3.1

part of tree.less;

class Value extends Node {
  List<Node> value;

  final String type = 'Value';

  ///
  //2.3.1 ok
  Value(List<Node> this.value) {
    if (this.value == null) throw new LessExceptionError(new LessError(
        message: 'Value requires an array argument'));
  }

//2.3.1
//  var Value = function (value) {
//      this.value = value;
//      if (!value) {
//          throw new Error("Value requires an array argument");
//      }
//  };

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    if (this.value != null) this.value = visitor.visitArray(this.value);

//2.3.1
//  Value.prototype.accept = function (visitor) {
//      if (this.value) {
//          this.value = visitor.visitArray(this.value);
//      }
//  };
  }

  ///
  //2.3.1 ok
  Node eval(Contexts context) {
    if (this.value.length == 1) {
      return this.value.first.eval(context);
    } else {
      return new Value(this.value.map((Node v){
        return v.eval(context);
      }).toList());
    }

//2.3.1
//  Value.prototype.eval = function (context) {
//      if (this.value.length === 1) {
//          return this.value[0].eval(context);
//      } else {
//          return new Value(this.value.map(function (v) {
//              return v.eval(context);
//          }));
//      }
//  };
  }

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    for (int i = 0; i < this.value.length; i++) {
      this.value[i].genCSS(context, output);
      if (i+1 < this.value.length) output.add((context != null && context.compress) ? ',' : ', ');
    }

//2.3.1
//  Value.prototype.genCSS = function (context, output) {
//      var i;
//      for(i = 0; i < this.value.length; i++) {
//          this.value[i].genCSS(context, output);
//          if (i + 1 < this.value.length) {
//              output.add((context && context.compress) ? ',' : ', ');
//          }
//      }
//  };
  }
}