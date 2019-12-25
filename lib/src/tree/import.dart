//source: less/tree/import.js 3.7.1 20180718

part of tree.less;

/*
 * CSS @import node
 *
 * The general strategy here is that we don't want to wait
 * for the parsing to be completed, before we start importing
 * the file. That's because in the context of a browser,
 * most of the time will be spent waiting for the server to respond.
 *
 * On creation, we push the import path to our import queue, though
 * `import,push`, we also pass it a callback, which it'll call once
 * the file has been fetched, and parsed.
 *
 *
 * The actual import node doesn't return anything, when converted to CSS.
 * The reason is that it's used at the evaluation stage, so that the rules
 * it imports can be treated like any other rules.
 *
 * In `eval`, we make sure all Import nodes get evaluated, recursively, so
 * we end up with a flat structure, which can easily be imported in the parent
 * ruleset.
 */

///
class Import extends Node {
  @override
  final String name = null;

  @override
  final String type = 'Import';

  ///
  bool css = false;

  ///
  LessError errorImport;

  ///
  Node features;

  ///
  String importedFilename;

  ///
  ImportOptions options;

  ///
  dynamic root; // Ruleset or String

  ///
  dynamic skip; // bool or Function - initialized in import_visitor

  ///
  Node path;

  ///
  Import(this.path, this.features, this.options, int index,
      [FileInfo currentFileInfo, VisibilityInfo visibilityInfo])
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    allowRoot = true;
    final rPathValue = RegExp(r'[#\.\&\?]css([\?;].*)?$');

    if (options.less != null || (options.inline ?? false)) {
      css = !(options.less ?? false) || (options.inline ?? false);
    } else {
      final pathValue = getPath();
      if ((pathValue != null) && (rPathValue.hasMatch(pathValue))) css = true;
    }

    copyVisibilityInfo(visibilityInfo);
    setParent(features, this);
    setParent(path, this);

//3.0.0 20161222
// var Import = function (path, features, options, index, currentFileInfo, visibilityInfo) {
//     this.options = options;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.path = path;
//     this.features = features;
//     this.allowRoot = true;
//
//     if (this.options.less !== undefined || this.options.inline) {
//         this.css = !this.options.less || this.options.inline;
//     } else {
//         var pathValue = this.getPath();
//         if (pathValue && /[#\.\&\?]css([\?;].*)?$/.test(pathValue)) {
//             this.css = true;
//         }
//     }
//     this.copyVisibilityInfo(visibilityInfo);
//     this.setParent(this.features, this);
//     this.setParent(this.path, this);
// };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'path': path, 'features': features};

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (features != null) features = visitor.visit(features);

    path = visitor.visit(path);

    if (!(options.inline ?? false) && root != null) {
      root = visitor.visit(root);
    }

//2.4.0 20150320
//  Import.prototype.accept = function (visitor) {
//      if (this.features) {
//          this.features = visitor.visit(this.features);
//      }
//      this.path = visitor.visit(this.path);
//      if (!this.options.plugin && !this.options.inline && this.root) {
//          this.root = visitor.visit(this.root);
//      }
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (css && !path._fileInfo.reference) {
      output.add('@import ', fileInfo: _fileInfo, index: _index);
      path.genCSS(context, output);
      if (features != null) {
        output.add(' ');
        features.genCSS(context, output);
      }
      output.add(';');
    }

//3.0.0 20160714
// Import.prototype.genCSS = function (context, output) {
//     if (this.css && this.path._fileInfo.reference === undefined) {
//         output.add("@import ", this._fileInfo, this._index);
//         this.path.genCSS(context, output);
//         if (this.features) {
//             output.add(" ");
//             this.features.genCSS(context, output);
//         }
//         output.add(';');
//     }
// };
  }

  ///
  /// get the file path to import.
  ///
  String getPath() => (path is URL) ? path.value.value : path.value;

//2.4.0 20150321
//  Import.prototype.getPath = function () {
//      return (this.path instanceof URL) ?
//          this.path.value.value : this.path.value;
//  };

  ///
  bool isVariableImport() {
    var path = this.path;
    if (path is URL) path = path.value;
    if (path is Quoted) return path.containsVariables();
    return true;

//2.3.1
//  Import.prototype.isVariableImport = function () {
//      var path = this.path;
//      if (path instanceof URL) {
//          path = path.value;
//      }
//      if (path instanceof Quoted) {
//          return path.containsVariables();
//      }
//
//      return true;
//  };
  }

  ///
  /// Resolves @var in the path
  ///
  Import evalForImport(Contexts context) {
    var path = this.path;
    if (path is URL) path = path.value;

    return Import(path.eval(context), features, options, _index, _fileInfo,
        visibilityInfo());

//3.0.0 20160714
// Import.prototype.evalForImport = function (context) {
//     var path = this.path;
//
//     if (path instanceof URL) {
//         path = path.value;
//     }
//
//     return new Import(path.eval(context), this.features, this.options, this._index, this._fileInfo, this.visibilityInfo());
// };
  }

  ///
  Node evalPath(Contexts context) {
    final path = this.path.eval(context);

    if (path is! URL) {
      // Add the rootpath if the URL requires a rewrite
      final String pathValue = path.value;
      if (_fileInfo != null &&
          pathValue != null &&
          context.pathRequiresRewrite(pathValue)) {
        path.value = context.rewritePath(pathValue, _fileInfo.rootpath);
      } else {
        path.value = context.normalizePath(path.value);
      }
    }
    return path;

// 3.7.1 20180718
//  Import.prototype.evalPath = function (context) {
//      var path = this.path.eval(context);
//      var fileInfo = this._fileInfo;
//
//      if (!(path instanceof URL)) {
//          // Add the rootpath if the URL requires a rewrite
//          var pathValue = path.value;
//          if (fileInfo &&
//              pathValue &&
//              context.pathRequiresRewrite(pathValue)) {
//              path.value = context.rewritePath(pathValue, fileInfo.rootpath);
//          } else {
//              path.value = context.normalizePath(path.value);
//          }
//      }
//
//      return path;
//  };
  }

  ///
  /// Replaces the @import rule with the imported ruleset
  /// Returns Node (or List<Node> as Nodeset)
  ///
  // In js returns Node or List<Node>
  @override
  Node eval(Contexts context) {
    final result = doEval(context);
    if ((options.reference ?? false) || blocksVisibility()) {
      result.addVisibilityBlock();
    }
    return result;

//2.5.3 20151120
// Import.prototype.eval = function (context) {
//   var result = this.doEval(context);
//   if (this.options.reference || this.blocksVisibility()) {
//       if (result.length || result.length === 0) {
//           result.forEach(function (node) {
//                   node.addVisibilityBlock();
//               }
//           );
//       } else {
//           result.addVisibilityBlock();
//       }
//   }
//   return result;
// };
  }

  ///
  // In js returns Node or List<Node>
  Node doEval(Contexts context) {
    final features = this.features?.eval(context);

    if (skip != null) {
      if (skip is Function) skip = skip();
      //if (skip) return [];
      if (skip) return Nodeset(<Node>[]);
    }

    if (options.inline ?? false) {
      final contents = Anonymous(
        root,
        index: 0,
        currentFileInfo: FileInfo()
          ..filename = importedFilename
          ..reference = path._fileInfo?.reference ?? false,
        mapLines: true,
        rulesetLike: true,
      );

      return (this.features != null)
          ? Media(<Node>[contents], this.features.value)
          : Nodeset(<Node>[contents]);
    } else if (css ?? false) {
      final newImport = Import(evalPath(context), features, options, _index);
      if (!(newImport.css ?? false) && errorImport != null) {
        throw LessExceptionError(errorImport);
      }
      return newImport;
    } else {
      final ruleset = Ruleset(null, root.rules.sublist(0))
        ..evalImports(context);
      //return (this.features != null) ? new Media(ruleset.rules, this.features.value) : ruleset.rules;
      return (this.features != null)
          ? Media(ruleset.rules, this.features.value)
          : Nodeset(ruleset.rules);
    }

//3.0.0 20160714
// Import.prototype.doEval = function (context) {
//     var ruleset, registry,
//         features = this.features && this.features.eval(context);
//
//     if (this.options.isPlugin) {
//         if (this.root && this.root.eval) {
//             this.root.eval(context);
//         }
//         registry = context.frames[0] && context.frames[0].functionRegistry;
//         if ( registry && this.root && this.root.functions ) {
//             registry.addMultiple( this.root.functions );
//         }
//         return [];
//     }
//
//     if (this.skip) {
//         if (typeof this.skip === "function") {
//             this.skip = this.skip();
//         }
//         if (this.skip) {
//             return [];
//         }
//     }
//     if (this.options.inline) {
//         var contents = new Anonymous(this.root, 0,
//           {
//               filename: this.importedFilename,
//               reference: this.path._fileInfo && this.path._fileInfo.reference
//           }, true, true);
//
//         return this.features ? new Media([contents], this.features.value) : [contents];
//     } else if (this.css) {
//         var newImport = new Import(this.evalPath(context), features, this.options, this._index);
//         if (!newImport.css && this.error) {
//             throw this.error;
//         }
//         return newImport;
//     } else {
//         ruleset = new Ruleset(null, utils.copyArray(this.root.rules));
//         ruleset.evalImports(context);
//
//         return this.features ? new Media(ruleset.rules, this.features.value) : ruleset.rules;
//     }
// };
  }

  @override
  String toString() {
    final output = Output();
    path.genCSS(null, output);
    return output.toString();
  }
}

///
/// Manages the options in: @import (options) "...";
/// Example: options = new ImportOptions(); options['less'] = true;  options.less = true;
///
class ImportOptions {
  ///
  bool less;

  ///
  bool css;

  ///
  bool multiple;

  ///
  bool once;

  ///
  bool inline;

  //bool plugin;  //Here @plugin directive is based in @options, not on import

  ///
  bool reference;

  ///
  bool optional;

  ///
  // ignore: avoid_positional_boolean_parameters
  void operator []=(String optionName, bool value) {
    switch (optionName) {
      case 'less':
        less = value;
        break;
      case 'css':
        css = value;
        break;
      case 'multiple':
        multiple = value;
        break;
      case 'once':
        once = value;
        break;
      case 'inline':
        inline = value;
        break;
//      case 'plugin':
//        plugin = value;
//        break;
      case 'reference':
        reference = value;
        break;
      case 'optional':
        optional = value;
    }
  }
}
