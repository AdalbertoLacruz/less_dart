// source: less/utils.js 3.0.0 20171009

library utils.less;

import 'dart:mirrors';


///
class Utils {
  ///
  /// Returns line and column corresponding to index
  ///
  /// [index] is the character position in [inputStream]
  ///
  static LocationPoint getLocation(int index, String inputStream) {
    int n = (index >= inputStream.length - 1) ? inputStream.length : index + 1;
    int line;
    int column = -1;

    while (--n >= 0 && inputStream[n] != '\n') {
      column++;
    }
    if (column < 0) column = 0;

    line = inputStream.substring(0, index).split('\n').length - 1;

    return new LocationPoint(
        line: line,
        column: column
    );

//2.2.0
//getLocation: function(index, inputStream) {
//    var n = index + 1,
//        line = null,
//        column = -1;
//
//    while (--n >= 0 && inputStream.charAt(n) !== '\n') {
//        column++;
//    }
//
//    if (typeof index === 'number') {
//        line = (inputStream.slice(0, index).match(/\n/g) || "").length;
//    }
//
//    return {
//        line: line,
//        column: column
//    };
//}
  }

  ///
  /// Non deep clone for same class instances. [to] must be a new instance.
  /// Example, clone a Contexts: result = Utils.clone(context, new Contexts());
  ///
  static dynamic clone(dynamic from, dynamic to) {
    final InstanceMirror fromInstanceMirror = reflect(from);
    final InstanceMirror toInstanceMirror = reflect(to);

    fromInstanceMirror.type.declarations.forEach((Symbol variableName, DeclarationMirror declaration) {
      if (declaration is VariableMirror) {
        final dynamic variableValue = fromInstanceMirror.getField(variableName).reflectee;
        toInstanceMirror.setField(variableName, variableValue);
      }
    });

    return to;

//3.0.0 20171009
//clone: function (obj) {
//    var cloned = {};
//    for (var prop in obj) {
//        if (obj.hasOwnProperty(prop)) {
//            cloned[prop] = obj[prop];
//        }
//    }
//    return cloned;
//},
  }

  ///
  /// Non deep copy from two instances that could be from different classes.
  /// [properties] contains the variable names to copy if possible. If null, copy all possible.
  ///
  static dynamic copyFrom(dynamic from, dynamic to, [List<String> properties]) {
    final InstanceMirror fromInstanceMirror = reflect(from);
    final InstanceMirror toInstanceMirror = reflect(to);

    bool tryCopy(String name) => (properties == null) ? true : properties.contains(name);

    final Map<Symbol, DeclarationMirror> fromDeclarations = fromInstanceMirror.type.declarations;

    toInstanceMirror.type.declarations.forEach((Symbol variableName, DeclarationMirror declaration) {
      final String name = MirrorSystem.getName(variableName);
      if (declaration is VariableMirror && tryCopy(name) && fromDeclarations.containsKey(variableName)) {
        final dynamic variableValue = fromInstanceMirror.getField(variableName).reflectee;
        toInstanceMirror.setField(variableName, variableValue);
      }
    });

    return to;
  }

//3.0.0 20171009
//defaults: function(obj1, obj2) {
//    if (!obj2._defaults || obj2._defaults !== obj1) {
//        for (var prop in obj1) {
//            if (obj1.hasOwnProperty(prop)) {
//                if (!obj2.hasOwnProperty(prop)) {
//                    obj2[prop] = obj1[prop];
//                }
//                else if (Array.isArray(obj1[prop])
//                    && Array.isArray(obj2[prop])) {
//
//                    obj1[prop].forEach(function(p) {
//                        if (obj2[prop].indexOf(p) === -1) {
//                            obj2[prop].push(p);
//                        }
//                    });
//                }
//            }
//        }
//    }
//    obj2._defaults = obj1;
//    return obj2;
//},

// 3.0.0 20171009
//merge: function(obj1, obj2) {
//    for (var prop in obj2) {
//        if (obj2.hasOwnProperty(prop)) {
//            obj1[prop] = obj2[prop];
//        }
//    }
//    return obj1;
//},

}

///
/// Coordinates [line], [column] in a file
///
/// Example: new LocationPoint({line: 9, column: 30});
///
class LocationPoint {
  ///
  int line;
  ///
  int column;

  ///
  LocationPoint({int this.line, int this.column});
}
