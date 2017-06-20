//source: less/tree/import.js 2.5.0

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
  @override final String  name = null;
  @override final String  type = 'Import';

  ///
  bool          css = false;
  ///
  LessError     errorImport;
  ///
  Node          features;
  ///
  String        importedFilename;
  ///
  int           index;
  ///
  ImportOptions options;
  ///
  dynamic       root; // Ruleset or String
  ///
  dynamic       skip; // bool or Function - initialized in import_visitor
  ///
  Node          path;

  ///
  Import(this.path, this.features, this.options, this.index,
      [FileInfo currentFileInfo])
      : super.init(currentFileInfo: currentFileInfo) {

    final RegExp rPathValue = new RegExp(r'[#\.\&\?\/]css([\?;].*)?$');

    if (options.less != null || (options.inline ?? false)) {
      css = !(options.less ?? false) || (options.inline ?? false);
    } else {
      final String pathValue = getPath();
      if ((pathValue != null) && (rPathValue.hasMatch(pathValue)))
          css = true;
    }

//2.3.1
//  var Import = function (path, features, options, index, currentFileInfo) {
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
//          if (pathValue && /[#\.\&\?\/]css([\?;].*)?$/.test(pathValue)) {
//              this.css = true;
//          }
//      }
//  };
  }

  ///
  @override
  void accept(covariant Visitor visitor) {
    if (features != null)
        features = visitor.visit(features);

    path = visitor.visit(path);

    if (!(options.inline ?? false) && root != null)
        root = visitor.visit(root);

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
    if (css && !path.currentFileInfo.reference) {
      output.add('@import ', fileInfo: currentFileInfo, index: index);
      path.genCSS(context, output);
      if (features != null) {
        output.add(' ');
        features.genCSS(context, output);
      }
      output.add(';');
    }

//2.4.0 20150310
//  Import.prototype.genCSS = function (context, output) {
//      if (this.css && this.path.currentFileInfo.reference === undefined) {
//          output.add("@import ", this.currentFileInfo, this.index);
//          this.path.genCSS(context, output);
//          if (this.features) {
//              output.add(" ");
//              this.features.genCSS(context, output);
//          }
//          output.add(';');
//      }
//  };
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
    Node path = this.path;
    if (path is URL)
        path = path.value;
    if (path is Quoted)
        return path.containsVariables();
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
    Node path = this.path;
    if (path is URL)
        path = path.value;
    return new Import(path.eval(context), features, options, index, currentFileInfo);

//2.3.1
//  Import.prototype.evalForImport = function (context) {
//      var path = this.path;
//      if (path instanceof URL) {
//          path = path.value;
//      }
//      return new Import(path.eval(context), this.features, this.options, this.index, this.currentFileInfo);
//  };
  }

  ///
  Node evalPath(Contexts context) {
    final Node    path = this.path.eval(context);
    final String  rootpath = currentFileInfo?.rootpath;

    if (path is! URL) {
      if (rootpath != null) {
        final String pathValue = path.value;
        // Add the base path if the import is relative
        if (pathValue != null && context.isPathRelative(pathValue))
            // ignore: prefer_interpolation_to_compose_strings
            path.value = rootpath + pathValue;
      }
      path.value = context.normalizePath(path.value);
    }
    return path;

//2.3.1
//  Import.prototype.evalPath = function (context) {
//      var path = this.path.eval(context);
//      var rootpath = this.currentFileInfo && this.currentFileInfo.rootpath;
//
//      if (!(path instanceof URL)) {
//          if (rootpath) {
//              var pathValue = path.value;
//              // Add the base path if the import is relative
//              if (pathValue && context.isPathRelative(pathValue)) {
//                  path.value = rootpath + pathValue;
//              }
//          }
//          path.value = context.normalizePath(path.value);
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
    final Node features = this.features?.eval(context);

    if (skip != null) {
      if (skip is Function)
          skip = skip();
      //if (skip) return [];
      if (skip)
          return new Nodeset(<Node>[]);
    }

    if (options.inline ?? false) {
      final Anonymous contents = new Anonymous(root,
          index: 0,
          currentFileInfo: new FileInfo()..filename = importedFilename,
          mapLines: true,
          rulesetLike: true);
      return (this.features != null)
          ? new Media(<Node>[contents], this.features.value)
          : new Nodeset(<Node>[contents]);
    } else if (css ?? false) {
      final Import newImport = new Import(evalPath(context), features, options, index);
      if (!(newImport.css ?? false) && errorImport != null)
          throw new LessExceptionError(errorImport);
      return newImport;
    } else {
      final Ruleset ruleset = new Ruleset(null, root.rules.sublist(0))
          ..evalImports(context);
      //return (this.features != null) ? new Media(ruleset.rules, this.features.value) : ruleset.rules;
      return (this.features != null)
          ? new Media(ruleset.rules, this.features.value)
          : new Nodeset(ruleset.rules);
    }

//2.4.0 20150320
//  Import.prototype.eval = function (context) {
//      var ruleset, registry,
//          features = this.features && this.features.eval(context);
//
//      if (this.options.plugin) {
//          registry = context.frames[0] && context.frames[0].functionRegistry;
//          if ( registry && this.root && this.root.functions ) {
//              registry.addMultiple( this.root.functions );
//          }
//          return [];
//      }
//
//      if (this.skip) {
//          if (typeof this.skip === "function") {
//              this.skip = this.skip();
//          }
//          if (this.skip) {
//              return [];
//          }
//      }
//
//      if (this.options.inline) {
//          var contents = new Anonymous(this.root, 0, {filename: this.importedFilename}, true, true);
//          return this.features ? new Media([contents], this.features.value) : [contents];
//      } else if (this.css) {
//          var newImport = new Import(this.evalPath(context), features, this.options, this.index);
//          if (!newImport.css && this.error) {
//              throw this.error;
//          }
//          return newImport;
//      } else {
//          ruleset = new Ruleset(null, this.root.rules.slice(0));
//
//          ruleset.evalImports(context);
//
//          return this.features ? new Media(ruleset.rules, this.features.value) : ruleset.rules;
//      }
//  };
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
