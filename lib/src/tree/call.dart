//source: less/tree/call.js 2.5.0

part of tree.less;

///
/// A function call node.
///
class Call extends Node {
  @override String        name;
  @override final String  type = 'Call';

  ///
  List<Node>  args; // Expression | Dimension | Assignment
  ///
  int         index;

  ///
  Call(this.name, this.args, this.index, FileInfo currentFileInfo)
      : super.init(currentFileInfo: currentFileInfo);

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name,
    'args': args
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (args != null)
        args = visitor.visitArray(args);

//2.3.1
//  Call.prototype.accept = function (visitor) {
//      if (this.args) {
//          this.args = visitor.visitArray(this.args);
//      }
//  };
  }

  ///
  /// When evaluating a function call,
  /// we either find the function in `functions` [1],
  /// in which case we call it, passing the  evaluated arguments,
  /// if this returns null or we cannot find the function, we
  /// simply print it out as it appeared originally [2].
  ///
  /// The *functions.dart* file contains the built-in functions.
  ///
  /// The reason why we evaluate the arguments, is in the case where
  /// we try to pass a variable to a function, like: `saturate(@color)`.
  /// The function should receive the value, not the variable.
  ///
  @override
  Node eval(Contexts context) {
    final List<Expression> args = this.args.map((Node a) => a.eval(context)).toList();
    final FunctionCaller   funcCaller = new FunctionCaller(name, context, index, currentFileInfo);

    if (funcCaller.isValid()) {
      try {
        final Node result = funcCaller.call(args);
        if (result != null)
            return result;
      } catch (e) {
        String message = LessError.getMessage(e);
        message = (message.isEmpty) ? '' : ': $message';

        final LessError error = LessError.transform(e,
            type: 'Runtime',
            index: index,
            filename: currentFileInfo.filename)
        ..message = 'error evaluating function `$name`$message';

        throw new LessExceptionError(error);
      }
    }

    return new Call(name, args, index, currentFileInfo);

//2.3.1
//    Call.prototype.eval = function (context) {
//        var args = this.args.map(function (a) { return a.eval(context); }),
//            result, funcCaller = new FunctionCaller(this.name, context, this.index, this.currentFileInfo);
//
//        if (funcCaller.isValid()) { // 1.
//            try {
//                result = funcCaller.call(args);
//                if (result != null) {
//                    return result;
//                }
//            } catch (e) {
//                throw { type: e.type || "Runtime",
//                        message: "error evaluating function `" + this.name + "`" +
//                                 (e.message ? ': ' + e.message : ''),
//                        index: this.index, filename: this.currentFileInfo.filename };
//            }
//        }
//
//        return new Call(this.name, args, this.index, this.currentFileInfo);
//    };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null)
        return genCleanCSS(context, output);

    output.add('$name(', fileInfo: currentFileInfo, index: index);

    for (int i = 0; i < args.length; i++) {
      args[i].genCSS(context, output);
      if (i + 1 < args.length)
          output.add(', ');
    }

    output.add(')');

//2.3.1
//  Call.prototype.genCSS = function (context, output) {
//      output.add(this.name + "(", this.currentFileInfo, this.index);
//
//      for(var i = 0; i < this.args.length; i++) {
//          this.args[i].genCSS(context, output);
//          if (i + 1 < this.args.length) {
//              output.add(", ");
//          }
//      }
//
//      output.add(")");
//  };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    output.add('$name(', fileInfo: currentFileInfo, index: index);

    for (int i = 0; i < args.length; i++) {
      args[i].genCSS(context, output);
      if (i + 1 < args.length)
          output.add(',');
    }

    output.add(')');
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
