//source: less/tree/variable.js 2.5.0

part of tree.less;

class Variable extends Node {
  String name;
  int index;
  FileInfo currentFileInfo;

  /// Recursivity control
  bool evaluating = false;

  var value;

  String type = "Variable";

  ///
  Variable(String this.name, [int this.index, FileInfo currentFileInfo]) {
    this.currentFileInfo = (currentFileInfo != null) ? currentFileInfo : new FileInfo();

//2.3.1
//  var Variable = function (name, index, currentFileInfo) {
//      this.name = name;
//      this.index = index;
//      this.currentFileInfo = currentFileInfo || {};
//  };
  }

  ///
  Node eval(Contexts context) {
    Node variable;
    String name = this.name;

    if (name.startsWith('@@')) {
      name = '@' + new Variable(name.substring(1), index, currentFileInfo).eval(context).value;
    }

    if (evaluating) {
      LessError error = new LessError(
          type: 'Name',
          message: 'Recursive variable definition for $name',
          filename: currentFileInfo.filename,
          index: index,
          context: context
      );
      throw new LessExceptionError(error);
    }

    evaluating = true;

    variable = find(context.frames, (frame){
      Rule v = frame.variable(name);
      if (v != null) {
        if (v.important.isNotEmpty) {
          ImportantRule importantScope = context.importantScope.last;
          importantScope.important = v.important;
        }
        return v.value.eval(context);
      }
    });

    if (variable != null) {
      evaluating = false;
      return variable;
    } else {
      LessError error = new LessError(
          type: 'Name',
          message: 'variable $name is undefined',
          filename: currentFileInfo.filename,
          index: index,
          context: context
      );
      throw new LessExceptionError(error);
    }

//2.3.1
//  Variable.prototype.eval = function (context) {
//      var variable, name = this.name;
//
//      if (name.indexOf('@@') === 0) {
//          name = '@' + new Variable(name.slice(1), this.index, this.currentFileInfo).eval(context).value;
//      }
//
//      if (this.evaluating) {
//          throw { type: 'Name',
//                  message: "Recursive variable definition for " + name,
//                  filename: this.currentFileInfo.filename,
//                  index: this.index };
//      }
//
//      this.evaluating = true;
//
//      variable = this.find(context.frames, function (frame) {
//          var v = frame.variable(name);
//          if (v) {
//              if (v.important) {
//                  var importantScope = context.importantScope[context.importantScope.length - 1];
//                  importantScope.important = v.important;
//              }
//              return v.value.eval(context);
//          }
//      });
//      if (variable) {
//          this.evaluating = false;
//          return variable;
//      } else {
//          throw { type: 'Name',
//                  message: "variable " + name + " is undefined",
//                  filename: this.currentFileInfo.filename,
//                  index: this.index };
//      }
//  };
  }

  ///
   find(List obj, Function fun) {
     var r;

     for (int i = 0; i < obj.length; i++) {
       r = fun(obj[i]);
       if (r != null) return r;
     }
     return null;
   }

//2.3.1
// Variable.prototype.find = function (obj, fun) {
//     for (var i = 0, r; i < obj.length; i++) {
//         r = fun.call(obj, obj[i]);
//         if (r) { return r; }
//     }
//     return null;
// };
}