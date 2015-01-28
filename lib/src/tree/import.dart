//source: less/tree/import.js 1.7.5

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
 *  The actual import node doesn't return anything, when converted to CSS.
 * The reason is that it's used at the evaluation stage, so that the rules
 * it imports can be treated like any other rules.
 *
 * In `eval`, we make sure all Import nodes get evaluated, recursively, so
 * we end up with a flat structure, which can easily be imported in the parent
 * ruleset.
 */

class Import extends Node implements EvalNode, ToCSSNode {
  Node          path;
  Node          features;
  ImportOptions options;
  int           index;
  FileInfo      currentFileInfo;

  bool      css = false;
  LessError errorImport;
  String    importedFilename;
  var       root;
  // bool or Function - initialized in import_visitor
  var       skip;

  final String type = 'Import';

  Import(Node this.path, Node this.features, ImportOptions this.options, int this.index,
      [FileInfo this.currentFileInfo]) {
    RegExp rPathValue = new RegExp(r'css([\?;].*)?$');

    if (this.options.less != null || isTrue(this.options.inline)) {
      this.css = !isTrue(this.options.less) || isTrue(this.options.inline);
    } else {
      String pathValue = getPath();
      if ((pathValue != null) && (rPathValue.hasMatch(pathValue))) this.css = true;
    }
  }

//  tree.Import = function (path, features, options, index, currentFileInfo) {
//      this.options = options;
//      this.index = index;
//      this.path = path;
//      this.features = features;
//      this.currentFileInfo = currentFileInfo;
//
//      if (this.options.less !== undefined || this.options.inline) {
//          this.css = !this.options.less || this.options.inline;
//      } else {
//          var pathValue = this.getPath();
//          if (pathValue && /css([\?;].*)?$/.test(pathValue)) {
//              this.css = true;
//          }
//      }
//  };

  ///
  void accept(Visitor visitor) {
    if (this.features != null) this.features = visitor.visit(this.features);

    this.path = visitor.visit(this.path);

    if (!isTrue(this.options.inline) && this.root != null) this.root = visitor.visit(this.root);

//      accept: function (visitor) {
//          if (this.features) {
//              this.features = visitor.visit(this.features);
//          }
//          this.path = visitor.visit(this.path);
//          if (!this.options.inline && this.root) {
//              this.root = visitor.visit(this.root);
//          }
//      },
  }

  void genCSS(Contexts env, Output output) {
    if (this.css) {
      output.add('@import ', this.currentFileInfo, this.index);
      this.path.genCSS(env, output);
      if (this.features != null) {
        output.add(' ');
        this.features.genCSS(env, output);
      }
      output.add(';');
    }
  }

//      toCSS: tree.toCSS,

  ///
  /// get the file path to import.
  /// #
  String getPath() {
    RegExp rPath = new RegExp(r'(\.[a-z]*$)|([\?;].*)$');

    if (this.path is Quoted) {
      String path = this.path.value;
      return (this.css || rPath.hasMatch(path))? path : path + '.less';
    } else if (this.path is URL) {
      return this.path.value.value;
    }
    return null;

//      getPath: function () {
//          if (this.path instanceof tree.Quoted) {
//              var path = this.path.value;
//              return (this.css !== undefined || /(\.[a-z]*$)|([\?;].*)$/.test(path)) ? path : path + '.less';
//          } else if (this.path instanceof tree.URL) {
//              return this.path.value.value;
//          }
//          return null;
//      },
  }

  ///
  /// Resolves @var in the path
  /// #
  Import evalForImport(Contexts env) => new Import(this.path.eval(env), this.features,
      this.options, this.index, this.currentFileInfo);

  ///
  Node evalPath(Contexts env) {
    Node path = this.path.eval(env);
    String rootpath = (this.currentFileInfo != null) ? this.currentFileInfo.rootpath : null;

    if (path is! URL) {
      if (rootpath != null) {
        String pathValue = path.value;
        // Add the base path if the import is relative
        if (pathValue != null && env.isPathRelative(pathValue)) {
          path.value = rootpath + pathValue;
        }
      }
      path.value = env.normalizePath(path.value);
    }

    return path;

//      evalPath: function (env) {
//          var path = this.path.eval(env);
//          var rootpath = this.currentFileInfo && this.currentFileInfo.rootpath;
//
//          if (!(path instanceof tree.URL)) {
//              if (rootpath) {
//                  var pathValue = path.value;
//                  // Add the base path if the import is relative
//                  if (pathValue && env.isPathRelative(pathValue)) {
//                      path.value = rootpath +pathValue;
//                  }
//              }
//              path.value = env.normalizePath(path.value);
//          }
//
//          return path;
//      },
  }

  ///
  /// replaces the @import rule with the imported ruleset
  /// Returns Node or List<Node>
  ///
   eval(Contexts env) {
    Node features = (this.features != null) ? this.features.eval(env) : null;

    if (this.skip != null) {
      if (skip is Function) this.skip = this.skip();
      if (this.skip) return [];
    }

    if (isTrue(this.options.inline)) {
      // Todo needs to reference css file not import
      Anonymous contents = new Anonymous(this.root, 0, new FileInfo()..filename = this.importedFilename, true, true);
      return (this.features != null) ? new Media([contents], this.features.value) : [contents];

    } else if (isTrue(this.css)) {
      Import newImport = new Import(this.evalPath(env), features, this.options, this.index);
      if (!isTrue(newImport.css) && this.errorImport != null) throw new LessExceptionError(this.errorImport);
      return newImport;

    } else {
      Ruleset ruleset = new Ruleset(null, this.root.rules.sublist(0));
      ruleset.evalImports(env);
      return (this.features != null) ? new Media(ruleset.rules, this.features.value) : ruleset.rules;
    }

//      eval: function (env) {
//          var ruleset, features = this.features && this.features.eval(env);
//
//          if (this.skip) {
//              if (typeof this.skip === "function") {
//                  this.skip = this.skip();
//              }
//              if (this.skip) {
//                  return [];
//              }
//          }
//
//          if (this.options.inline) {
//              //todo needs to reference css file not import
//              var contents = new(tree.Anonymous)(this.root, 0, {filename: this.importedFilename}, true, true);
//              return this.features ? new(tree.Media)([contents], this.features.value) : [contents];
//          } else if (this.css) {
//              var newImport = new(tree.Import)(this.evalPath(env), features, this.options, this.index);
//              if (!newImport.css && this.error) {
//                  throw this.error;
//              }
//              return newImport;
//          } else {
//              ruleset = new(tree.Ruleset)(null, this.root.rules.slice(0));
//
//              ruleset.evalImports(env);
//
//              return this.features ? new(tree.Media)(ruleset.rules, this.features.value) : ruleset.rules;
//          }
//      }
  }
}

/// ex. options['less'] = true;  options.less = true;
class ImportOptions {
  bool less;
  bool css;
  bool multiple;
  bool once;
  bool inline;
  bool reference;

  void operator []= (String optionName, bool value) {
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
      case 'reference':
        reference = value;
    }
  }
}