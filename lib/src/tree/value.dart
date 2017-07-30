//source: less/tree/value.js 2.5.0

part of tree.less;

/// -
class Value extends Node {
  @override final String          name = null;
  @override final String          type = 'Value';
  @override covariant List<Node>  value;

  ///
  Value(List<Node> this.value, {int index})
      : super.init(index: index) {
    if (value == null)
        throw new LessExceptionError(new LessError(
            message: 'Value requires an array argument'));
  }

//2.3.1
//  var Value = function (value) {
//      this.value = value;
//      if (!value) {
//          throw new Error("Value requires an array argument");
//      }
//  };

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (value != null)
        value = visitor.visitArray(value);

//2.3.1
//  Value.prototype.accept = function (visitor) {
//      if (this.value) {
//          this.value = visitor.visitArray(this.value);
//      }
//  };
  }

  ///
  @override
  Node eval(Contexts context) {
    if (value.length == 1) {
      return value.first.eval(context);
    } else {
      return new Value(value.map((Node v) => v.eval(context)).toList());
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
  @override
  void genCSS(Contexts context, Output output) {
    if (context != null && context.cleanCss)
        return genCleanCSS(context, output);

    for (int i = 0; i < value.length; i++) {
      value[i].genCSS(context, output);
      if (i + 1 < value.length)
          output.add((context != null && context.compress) ? ',' : ', ');
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

  ///
  void genCleanCSS(Contexts context, Output output) {
    for (int i = 0; i < value.length; i++) {
      value[i].genCSS(context, output);
      if (i + 1 < value.length)
          output.add(',');
    }
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
