//source: less/tree/variable.js 1.7.5

part of tree.less;

class Variable extends Node implements EvalNode {
  String name;
  int index;
  FileInfo currentFileInfo;

  /// Recursivity control
  bool evaluating = false;

  var value;

  String type = "Variable";

  Variable(String this.name, [int this.index, FileInfo currentFileInfo]) {
    this.currentFileInfo = currentFileInfo != null ? currentFileInfo : new FileInfo();
  }

  ///
  Node eval(Env env) {
    Node variable;
    String name = this.name;

    if (name.startsWith('@@')) name = '@' + new Variable(name.substring(1)).eval(env).value;

    if (this.evaluating) {
      LessError error = new LessError(
          type: 'Name',
          message: 'Recursive variable definition for $name',
          filename: this.currentFileInfo.filename,
          index: this.index,
          env: env
      );
      throw new LessExceptionError(error);
    }

    this.evaluating = true;

    variable = Env.find(env.frames, (frame){
      var v = frame.variable(name);
      if (v != null) return v.value.eval(env);
    });

    if (variable != null) {
      this.evaluating = false;
      return variable;
    } else {
      LessError error = new LessError(
          type: 'Name',
          message: 'variable $name is undefined',
          filename: this.currentFileInfo.filename,
          index: this.index,
          env: env
      );
      throw new LessExceptionError(error);
    }

//    eval: function (env) {
//        var variable, name = this.name;
//
//        if (name.indexOf('@@') === 0) {
//            name = '@' + new(tree.Variable)(name.slice(1)).eval(env).value;
//        }
//
//        if (this.evaluating) {
//            throw { type: 'Name',
//                    message: "Recursive variable definition for " + name,
//                    filename: this.currentFileInfo.file,
//                    index: this.index };
//        }
//
//        this.evaluating = true;
//
//        variable = tree.find(env.frames, function (frame) {
//            var v = frame.variable(name);
//            if (v) {
//                return v.value.eval(env);
//            }
//        });
//        if (variable) {
//            this.evaluating = false;
//            return variable;
//        } else {
//            throw { type: 'Name',
//                    message: "variable " + name + " is undefined",
//                    filename: this.currentFileInfo.filename,
//                    index: this.index };
//        }
//    }
//};
  }
}