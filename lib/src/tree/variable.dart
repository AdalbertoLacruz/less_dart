//source: less/tree/variable.js 3.0.0 20160714

part of tree.less;

///
class Variable extends Node {
  @override String name;
  @override String type = 'Variable';

  ///
  bool  evaluating = false; // Recursivity control

  ///
  Variable(String this.name, [int index, FileInfo currentFileInfo])
    : super.init(currentFileInfo: currentFileInfo, index: index);

//3.0.0 20160714
// var Variable = function (name, index, currentFileInfo) {
//     this.name = name;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
// };

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name
  };

  ///
  @override
  Node eval(Contexts context) {
    String name = this.name;

    if (name.startsWith('@@')) {
      // ignore: prefer_interpolation_to_compose_strings
      name = '@' + new Variable(name.substring(1), index, currentFileInfo).eval(context).value;
    }

    if (evaluating) {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: 'Recursive variable definition for $name',
          filename: currentFileInfo.filename,
          index: index,
          context: context));
    }

    evaluating = true;

    final Node variable = find(context.frames, (VariableMixin frame) {
      final Declaration v = frame.variable(name);
      if (v != null) {
        if (v.important.isNotEmpty)
            context.importantScope.last.important = v.important;
        return v.value.eval(context);
      }
    });

    if (variable != null) {
      evaluating = false;
      return variable;
    } else {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: 'variable $name is undefined',
          filename: currentFileInfo.filename,
          index: index,
          context: context));
    }

//3.0.0 20160714
// Variable.prototype.eval = function (context) {
//     var variable, name = this.name;
//
//     if (name.indexOf('@@') === 0) {
//         name = '@' + new Variable(name.slice(1), this.getIndex(), this.fileInfo()).eval(context).value;
//     }
//
//     if (this.evaluating) {
//         throw { type: 'Name',
//                 message: "Recursive variable definition for " + name,
//                 filename: this.fileInfo().filename,
//                 index: this.getIndex() };
//     }
//
//     this.evaluating = true;
//
//     variable = this.find(context.frames, function (frame) {
//         var v = frame.variable(name);
//         if (v) {
//             if (v.important) {
//                 var importantScope = context.importantScope[context.importantScope.length - 1];
//                 importantScope.important = v.important;
//             }
//             return v.value.eval(context);
//         }
//     });
//     if (variable) {
//         this.evaluating = false;
//         return variable;
//     } else {
//         throw { type: 'Name',
//                 message: "variable " + name + " is undefined",
//                 filename: this.fileInfo().filename,
//                 index: this.getIndex() };
//     }
// };
  }

  ///
  Node find(List<Node> obj, Function fun) {
    for (int i = 0; i < obj.length; i++) {
      final Node r = fun(obj[i]);
      if (r != null)
          return r;
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

// Used by genTree
@override
void genCSS(Contexts context, Output output) {
  output.add(name);
}

@override
String toString() => name;
}
