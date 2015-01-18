//source: less/tree/call.js 2.2.0

part of tree.less;

/*
 * A function call node.
 */
class Call extends Node implements EvalNode, ToCSSNode {
  String name;
  List<Expression> args;
  int index;
  FileInfo currentFileInfo;

  final String type = 'Call';

  Call(this.name, this.args, this.index, this.currentFileInfo);

  ///
  void accept(Visitor visitor) {
    if (this.args != null) this.args = visitor.visitArray(this.args);
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
  eval(Env context) {
    List<Expression> args = this.args.map((a) => a.eval(context)).toList();
    FunctionCaller funcCaller = new FunctionCaller(this.name, context, this.index, this.currentFileInfo);
    var result;

    if (funcCaller.isValid()) {
      try {
        result = funcCaller.call(args);
        if (result != null) return result;
      } catch (e) {
        String message = LessError.getMessage(e);
        message = (message.isEmpty) ? '' : ': ' + message;
        LessError error = LessError.transform(e,
            type: 'Runtime',
            index: this.index,
            filename: this.currentFileInfo.filename
        );
        error.message = 'error evaluating function `${this.name}`${message}';
        throw new LessExceptionError(error);
      }
    }
    return new Call(this.name, args, this.index, this.currentFileInfo);

//2.2.0
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
  void genCSS(Env context, Output output) {
    output.add(this.name + '(', this.currentFileInfo, this.index);

    for (int i = 0; i < this.args.length; i++){
      this.args[i].genCSS(context, output);
      if (i + 1 < this.args.length) output.add(', ');
    }

    output.add(')');
  }

//      toCSS: tree.toCSS
}