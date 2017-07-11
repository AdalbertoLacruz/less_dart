// source: less/contexts.js 2.5.3 20151120

library contexts.less;

import 'file_info.dart';
import 'functions/functions.dart';
import 'import_manager.dart';
import 'less_options.dart';
import 'plugins/plugins.dart';
import 'tree/tree.dart';

///
class Contexts {
  // ***** From options
  ///
  bool avoidDartOptimization; //Dart prune some code apparently not used

  /// options.chunkInput
  bool chunkInput;

  /// options.cleancss
  bool cleanCss = false;

  /// options.color
  bool color = false;

  /// options.compress
  bool compress = false;

  /// Map - filename to contents of all the files
  Map<String, String> contents = <String, String>{};

  /// map - filename to lines at the begining of each file to ignore
  Map<String, int> contentsIgnoredChars = <String, int>{};

  /// Information about the current file.
  /// For error reporting and importing and making urls relative etc.
  FileInfo currentFileInfo;

  /// for default() function evaluation
  FunctionBase defaultFunc;

  /// options.dumpLineNumbers
  String dumpLineNumbers;

  ///
  String input; // for LessError

  /// List of files that have been imported, used for import-once
  Map<String, Node> files = <String, Node>{};

  ///Ruleset
  bool firstSelector = false;

  ///Ruleset/MixinDefinition/Directive = VariableMixin
  List<Node> frames = <Node>[];

  /// options.javascriptEnabled
  bool javascriptEnabled = true;

  /// options.ieCompat
  bool ieCompat = true;

  /// used to bubble up !important statements
  List<ImportantRule> importantScope = <ImportantRule>[];

  /// options.importMultiple
  bool importMultiple = false;

  /// for LessError
  ImportManager imports;

  /// options.insecure
  bool insecure = false;

  /// Ruleset
  bool lastRule = false;

  /// Ruleset
  List<Media> mediaBlocks;

  ///
  List<Media> mediaPath;

  /// options.mime
  String mime; // browser only

  /// options.numPrecision
  int numPrecision; //functions frunt

  /// Stack for evaluating expression in parenthesis flag
  List<bool> parensStack;

  /// options.paths
  List<String> paths;

  /// options.pluginManager
  PluginManager pluginManager;

  /// options.processImports
  bool processImports;

  /// options.relativeUrls
  bool relativeUrls = false;

  /// option.rootpath
  String rootpath;

  /// used in Ruleset
  List<List<Selector>> selectors;

  // options.silent
  //bool silent;

  /// options.sourceMap
  bool sourceMap;

  /// options.strictImports
  bool strictImports = false;

  /// options.strictMath
  bool strictMath = false;

  /// options.strictUnits
  bool strictUnits = false;

  /// option.syncImport
  bool syncImport = false;

  /// Ruleset
  int tabLevel = 0;

  /// options.urlArgs
  String urlArgs;

  /// options.useFileCache
  bool useFileCache; // browser only

  /// options.verbose
  //bool verbose;

  /// options.yuicompress - deprecated
  bool yuicompress;

  ///
  Contexts();

  ///
  /// Build Context to render the tree
  /// [options] is LessOptions or Context
  ///
  //2.2.0 TODO
  factory Contexts.eval([dynamic options, List<Node> frames]) {
    final Contexts context = new Contexts();

    evalCopyProperties(context, options);
    context.frames = frames ?? <Node>[];

    return context;

//2.4.0 20150315
//  contexts.Eval = function(options, frames) {
//      copyFromOriginal(options, this, evalCopyProperties);
//
//      if (typeof this.paths === "string") { this.paths = [this.paths]; }
//
//      this.frames = frames || [];
//      this.importantScope = this.importantScope || [];
//  };
  }

  ///
  /// Copy from [options] LessOptions or Contexts
  ///
  /// parse is used whilst parsing
  ///
  //2.2.0 TODO
  Contexts.parse(dynamic options) {
    if (options == null)
        return;

    parseCopyProperties(options);

    contents ??= <String, String>{};
    contentsIgnoredChars ??= <String, int>{};
    files ??= <String, Node>{};

    if (currentFileInfo == null) {
      final String filename = (options.filename?.isNotEmpty ?? false)
          ? options.filename
          : 'input';
      final String entryPath = filename.replaceAll(new RegExp(r'[^\/\\]*$'), '');
      options.filename = null;

      currentFileInfo = new FileInfo()
            ..filename = filename
            ..relativeUrls = relativeUrls
            ..rootpath = options.rootpath ?? ''
            ..currentDirectory = entryPath
            ..entryPath = entryPath
            ..rootFilename = filename;
    }

//2.2.0
//  contexts.Parse = function(options) {
//      copyFromOriginal(options, this, parseCopyProperties);
//
//      if (typeof this.paths === "string") { this.paths = [this.paths]; }
//  };
  }

  ///
  /// Copy properties for parse
  ///
  /// Some are common to options and contexts
  ///
  void parseCopyProperties(dynamic options) {
    if(options is! LessOptions && options is! Contexts)
        return;

    paths               = options.paths;
    relativeUrls        = options.relativeUrls;
    rootpath            = options.rootpath;
    strictImports       = options.strictImports;
    insecure            = options.insecure;
    dumpLineNumbers     = options.dumpLineNumbers;
    compress            = options.compress;
    syncImport          = options.syncImport;
    chunkInput          = options.chunkInput;
    mime                = options.mime;
    useFileCache        = options.useFileCache;
    processImports      = options.processImports;
    numPrecision        = options.numPrecision;
    color               = options.color;
    pluginManager       = options.pluginManager;
    cleanCss            = options.cleanCss;

    if (options is Contexts) {
      final Contexts context = options;

      files                 = context.files;
      contents              = context.contents;
      contentsIgnoredChars  = context.contentsIgnoredChars;
      currentFileInfo       = context.currentFileInfo;
    }
  }

  ///
  /// Copy properties for eval
  /// [options] is LessOptions or Context
  ///
  static void evalCopyProperties(Contexts newctx, dynamic options) {
    if (options == null)
        return;

    newctx
        ..compress           = options.compress
        ..ieCompat           = options.ieCompat
        ..strictMath         = options.strictMath
        ..strictUnits        = options.strictUnits
        ..numPrecision       = options.numPrecision
        ..sourceMap          = options.sourceMap
        ..importMultiple     = options.importMultiple
        ..urlArgs            = options.urlArgs
        ..javascriptEnabled  = options.javascriptEnabled
        ..dumpLineNumbers    = options.dumpLineNumbers //removed 2.2.0
        ..pluginManager      = options.pluginManager
//      ..importantScope     = options.importantScope // Used to bubble up !important statements. TODO 2.2.0
        ..paths              = options.paths
        ..cleanCss           = options.cleanCss;

    if (options is Contexts) {
      final Contexts context  = options;

      newctx
          ..defaultFunc    = context.defaultFunc
          ..importantScope = context.importantScope;
    }
  }

  ///
  /// parensStack push
  ///
  void inParenthesis() {
    parensStack == null
        ? parensStack = <bool>[true]
        : parensStack.add(true);

//2.2.0
//  contexts.Eval.prototype.inParenthesis = function () {
//      if (!this.parensStack) {
//          this.parensStack = [];
//      }
//      this.parensStack.push(true);
//  };
  }

  ///
  /// parensStack pop. Always return true.
  ///
  bool outOfParenthesis() => parensStack.removeLast();

//2.2.0
//  contexts.Eval.prototype.outOfParenthesis = function () {
//      this.parensStack.pop();
//  };

  ///
  bool isMathOn() => strictMath
      ? (parensStack != null && parensStack.isNotEmpty)
      : true;

//2.2.0
//  contexts.Eval.prototype.isMathOn = function () {
//      return this.strictMath ? (this.parensStack && this.parensStack.length) : true;
//  };

  ///
  bool isPathRelative(String path) {
    final RegExp re =  new RegExp(r'^(?:[a-z-]+:|\/|#)', caseSensitive: false);
    return !re.hasMatch(path);

//2.4.0
//  contexts.Eval.prototype.isPathRelative = function (path) {
//      return !/^(?:[a-z-]+:|\/|#)/i.test(path);
//  };
  }

  ///
  /// Resolves '.' and '..' in the path
  ///
  String normalizePath(String path) {
    final List<String> pathList = <String>[];
    final List<String> segments = path.split('/').reversed.toList();

    while (segments.isNotEmpty) {
      final String segment = segments.removeLast();
      switch (segment) {
        case '.':
          break;
        case '..':
          if (pathList.isEmpty || pathList.last == '..') {
            pathList.add(segment);
          } else {
            pathList.removeLast();
          }
          break;
        default:
          pathList.add(segment);
          break;
      }
    }

    return pathList.join('/');

//2.2.0
//  contexts.Eval.prototype.normalizePath = function( path ) {
//      var
//        segments = path.split("/").reverse(),
//        segment;
//
//      path = [];
//      while (segments.length !== 0 ) {
//          segment = segments.pop();
//          switch( segment ) {
//              case ".":
//                  break;
//              case "..":
//                  if ((path.length === 0) || (path[path.length - 1] === "..")) {
//                      path.push( segment );
//                  } else {
//                      path.pop();
//                  }
//                  break;
//              default:
//                  path.push( segment );
//                  break;
//          }
//      }
//
//      return path.join("/");
//  };
  }
}
