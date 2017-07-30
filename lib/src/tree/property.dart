//source: less/tree/property.js 3.0.0 20160718

part of tree.less;

///
class Property extends Node with MergeRulesMixin {
  @override final String name;
  @override String       type = 'Property';

  /// recursivity control
  bool evaluating = false;

  ///
  Property(String this.name, int index, FileInfo currentFileInfo) {
    _fileInfo = currentFileInfo;
    _index = index;

//3.0.0 20160718
// var Property = function (name, index, currentFileInfo) {
//     this.name = name;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name
  };

  ///
  @override
  Node eval(Contexts context) {
    if (evaluating) {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: 'Recursive property reference for $name',
          filename: currentFileInfo.filename,
          index: index));
    }

    evaluating = true;

    final Node property = find(context.frames, (Node frame) {
      final Ruleset _frame = frame;
      final List<Declaration> vArr = _frame.property(name);
      Declaration v;
      if (vArr != null) {
        for (int i = 0; i < vArr.length; i++) {
          v = vArr[i];
          vArr[i] = v.clone();
        }
        mergeRules(vArr);

        v = vArr.last;
        if (v.important.isNotEmpty) {
          context.importantScope[context.importantScope.length - 1].important =
              v.important;
        }
        return v.value.eval(context);
      }
    });

    if (property != null) {
      evaluating = false;
      return property;
    } else {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: "Property '$name' is undefined",
          filename: currentFileInfo.filename,
          index: index));
    }

//3.0.0 20160718
// Property.prototype.eval = function (context) {
//     var property, name = this.name;
//     // TODO: shorten this reference
//     var mergeRules = context.pluginManager.less.visitors.ToCSSVisitor.prototype._mergeRules;
//
//     if (this.evaluating) {
//         throw { type: 'Name',
//                 message: "Recursive property reference for " + name,
//                 filename: this.fileInfo().filename,
//                 index: this.getIndex() };
//     }
//
//     this.evaluating = true;
//
//     property = this.find(context.frames, function (frame) {
//
//         var v, vArr = frame.property(name);
//         if (vArr) {
//             for (var i = 0; i < vArr.length; i++) {
//                 v = vArr[i];
//
//                 vArr[i] = new Declaration(v.name,
//                     v.value,
//                     v.important,
//                     v.merge,
//                     v.index,
//                     v.currentFileInfo,
//                     v.inline,
//                     v.variable
//                 );
//             }
//             mergeRules(vArr);
//
//             v = vArr[vArr.length - 1];
//             if (v.important) {
//                 var importantScope = context.importantScope[context.importantScope.length - 1];
//                 importantScope.important = v.important;
//             }
//             v = v.value.eval(context);
//             return v;
//         }
//     });
//     if (property) {
//         this.evaluating = false;
//         return property;
//     } else {
//         throw { type: 'Name',
//                 message: "Property '" + name + "' is undefined",
//                 filename: this.currentFileInfo.filename,
//                 index: this.index };
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

//3.0.0 20160718
// Property.prototype.find = function (obj, fun) {
//     for (var i = 0, r; i < obj.length; i++) {
//         r = fun.call(obj, obj[i]);
//         if (r) { return r; }
//     }
//     return null;
// };
  }

  // Used by genTree
  @override
  void genCSS(Contexts context, Output output) {
    output.add(name);
  }

  @override
  String toString() => name;
}
