//source: less/tree/call.js 1.7.5

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
  /// #
  eval(Env env) {
    List<Expression> args = this.args.map((a) => a.eval(env)).toList();
    String nameLC = this.name.toLowerCase();
    FunctionCall func = new FunctionCall(env, this.currentFileInfo);
    var result;

    try {
      if(env.defaultFunc != null && nameLC == 'default') {
        result = env.defaultFunc.eval();
        if (result != null) return result;
      }
      if (func.isMethod(nameLC)) {
        result = func.call(nameLC, args);
        if (result != null) return result;
      }
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

    return new Call(this.name, args, this.index, this.currentFileInfo);

// 1.7.5
//      eval: function (env) {
//          var args = this.args.map(function (a) { return a.eval(env); }),
//              nameLC = this.name.toLowerCase(),
//              result, func;
//
//          if (nameLC in tree.functions) { // 1.
//              try {
//                  func = new tree.functionCall(env, this.currentFileInfo);
//                  result = func[nameLC].apply(func, args);
//                  if (result != null) {
//                      return result;
//                  }
//              } catch (e) {
//                  throw { type: e.type || "Runtime",
//                          message: "error evaluating function `" + this.name + "`" +
//                                   (e.message ? ': ' + e.message : ''),
//                          index: this.index, filename: this.currentFileInfo.filename };
//              }
//          }
//
//          return new tree.Call(this.name, args, this.index, this.currentFileInfo);
//      },
  }

  ///
  // 2.2.0 ok
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