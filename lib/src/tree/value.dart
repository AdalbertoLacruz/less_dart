//source: less/tree/value.js 3.0.0 20160719

part of tree.less;

/// -
class Value extends Node {
  @override final String          name = null;
  @override final String          type = 'Value';
  @override covariant List<Node>  value;

  ///
  /// value is List<Node> | Node => [value]
  ///
  Value(dynamic value, {
      int index
      }) : super.init(index: index) {
    //
    if (value == null) {
      throw new LessExceptionError(new LessError(
          message: 'Value requires an array argument'));
    }
    if (value is! List<Node>) {
      this.value = <Node>[value];
    } else {
      this.value = value;
    }

//3.0.0 20160719
// var Value = function (value) {
//     if (!value) {
//         throw new Error("Value requires an array argument");
//     }
//     if (!Array.isArray(value)) {
//         this.value = [ value ];
//     }
//     else {
//         this.value = value;
//     }
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (value != null) value = visitor.visitArray(value);

//2.3.1
//  Value.prototype.accept = function (visitor) {
//      if (this.value) {
//          this.value = visitor.visitArray(this.value);
//      }
//  };
  }

  ///
  @override
  Node eval(Contexts context) => (value.length == 1)
      ? value.first.eval(context)
      : new Value(value.map((Node v) => v.eval(context)).toList());

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

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (context != null && context.cleanCss) return genCleanCSS(context, output);

    for (int i = 0; i < value.length; i++) {
      value[i].genCSS(context, output);
      if (i + 1 < value.length) {
        output.add((context != null && context.compress) ? ',' : ', ');
      }
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
      if (i + 1 < value.length) output.add(',');
    }
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
