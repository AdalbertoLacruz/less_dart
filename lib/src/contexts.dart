// source: less/contexts.js 2.2.0

library contexts.less;

import 'file_info.dart';
import 'import_manager.dart';
import 'less_options.dart';
import 'functions/functions.dart';
import 'plugins/plugins.dart';
import 'tree/tree.dart';


class Contexts {
  // ***** From options

  bool avoidDartOptimization; //Dart prune some code apparently not used

  /// options.chunkInput
  bool chunkInput;

  /// options.cleancss
  //bool cleancss = false;

  /// options.color
  bool color = false;

  /// options.compress
  bool compress = false;

  /// Map - filename to contents of all the files
  Map<String, String> contents = {};

  /// map - filename to lines at the begining of each file to ignore
  Map<String, int> contentsIgnoredChars = {};

  /// Information about the current file.
  /// For error reporting and importing and making urls relative etc.
  FileInfo currentFileInfo;

  /// options.customFunctions
  FunctionBase customFunctions;

  /// for default() function evaluation
  FunctionBase defaultFunc;

  /// options.dumpLineNumbers
  String dumpLineNumbers;

  String input;   // for LessError

  /// List of files that have been imported, used for import-once
  Map<String, Node> files = {};

  bool firstSelector = false; //Ruleset

  List<Node> frames = []; //Ruleset/MixinDefinition/Directive

  /// options.javascriptEnabled
  bool javascriptEnabled = true;

  /// options.ieCompat
  bool ieCompat = true;

  /// used to bubble up !important statements
  List<ImportantRule> importantScope = [];

  /// options.importMultiple
  bool importMultiple = false;

  ImportManager imports; //for LessError

  /// options.insecure
  bool insecure = false;

  bool lastRule = false; // Ruleset

  List<Media> mediaBlocks; // Ruleset

  List<Media> mediaPath;

  /// options.mime
  String mime;  // browser only

  /// options.numPrecision
  int numPrecision; //functions frunt

  /// Stack for evaluating expression in parenthesis flag
  List<bool> parensStack;

  /// options.paths
  List paths;

  /// options.pluginManager
  PluginManager pluginManager;

  /// options.processImports
  bool processImports;

  /// options.relativeUrls
  bool relativeUrls = false;

  /// option.rootpath
  String rootpath;

  List selectors; // Ruleset

  /// options.silent
  bool silent;

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

  int tabLevel = 0; // Ruleset

  /// options.urlArgs
  String urlArgs;

  /// options.useFileCache
  bool useFileCache; // browser only

  /// options.verbose
  bool verbose;

  /// options.yuicompress - deprecated
  bool yuicompress;


  ///
  Contexts();

  ///
  /// Copy from [options] LessOptions or Contexts
  ///
  /// parse is used whilst parsing
  ///
  //2.2.0 TODO
  Contexts.parse(options){
    if (options == null) return;
    parseCopyProperties(options);

    if (this.contents == null) this.contents = {};
    if (this.contentsIgnoredChars == null) this.contentsIgnoredChars = {};
    if (this.files == null) this.files = {};
//      if (this.paths is "String") this.paths = [this.paths];

    if (this.currentFileInfo == null) {
      String filename = options.filename != '' ? options.filename : 'input';
      String entryPath = filename.replaceAll(new RegExp(r'[^\/\\]*$'), '');
      if (options != null) options.filename = null;
      currentFileInfo = new FileInfo()
            ..filename = filename
            ..relativeUrls = this.relativeUrls
            ..rootpath = (options != null && options.rootpath != null) ? options.rootpath : ''
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
  //1.7.5+ ok
  void parseCopyProperties(options) {
    if(options is! LessOptions && options is! Contexts) return;

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
    //javascriptEnabled   = options.javascriptEnabled; //removed 2.2.0
    //strictMath          = options.strictMath; //removed 2.2.0
    numPrecision        = options.numPrecision;
    color               = options.color;
    silent              = options.silent; //removed 2.2.0
    customFunctions     = options.customFunctions; //dart version
//    reference           = options.reference; // Used to indicate that the contents are imported by reference //TODO 2.2.0
    pluginManager       = options.pluginManager; // Used as the plugin manager for the session //TODO

    if (options is Contexts) {
      Contexts context  = options as Contexts;

      files                 = context.files;
      contents              = context.contents;
      contentsIgnoredChars  = context.contentsIgnoredChars;
      currentFileInfo       = context.currentFileInfo;
    }
  }

  ///
  /// Build Context to render the tree
  /// [options] is LessOptions or Context
  ///
  //2.2.0 TODO
  factory Contexts.eval([options, List frames]) {
    Contexts context = new Contexts();
    evalCopyProperties(context, options);

    context.frames          = (frames != null) ? frames : [];
    //this.importantScope = this.importantScope || [];

    return context;

//2.2.0
//  contexts.Eval = function(options, frames) {
//      copyFromOriginal(options, this, evalCopyProperties);
//
//      this.frames = frames || [];
//      this.importantScope = this.importantScope || [];
//  };
  }

  ///
  /// Copy properties for eval
  ///
  static void evalCopyProperties(Contexts newctx, options) {
    if (options == null) return;

    newctx.silent             = options.silent; //removed 2.2.0
    newctx.verbose            = options.verbose; //removed 2.2.0
    newctx.compress           = options.compress;
    newctx.ieCompat           = options.ieCompat;
    newctx.strictMath         = options.strictMath;
    newctx.strictUnits        = options.strictUnits;
    newctx.numPrecision       = options.numPrecision;
    //newctx.cleancss           = options.cleancss; //removed 2.2.0
    newctx.sourceMap          = options.sourceMap;
    newctx.importMultiple     = options.importMultiple;
    newctx.urlArgs            = options.urlArgs;
    newctx.javascriptEnabled  = options.javascriptEnabled;
    newctx.dumpLineNumbers    = options.dumpLineNumbers; //removed 2.2.0
    newctx.pluginManager      = options.pluginManager; // Used as the plugin manager for the session. TODO 2.2.0
//    newctx.importantScope     = options.importantScope; // Used to bubble up !important statements. TODO 2.2.0

    if (options is Contexts) {
      Contexts context  = options as Contexts;
      newctx.defaultFunc    = context.defaultFunc;
      newctx.importantScope = context.importantScope;
    }
  }

  ///
  /// parensStack push
  ///
  //2.2.0 ok
  void inParenthesis() {
    if (this.parensStack == null) this.parensStack = [];
    this.parensStack.add(true);

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
  //2.2.0 ok
  bool outOfParenthesis() => this.parensStack.removeLast();

//2.2.0
//  contexts.Eval.prototype.outOfParenthesis = function () {
//      this.parensStack.pop();
//  };

  ///
  //2.2.0 ok
  bool isMathOn() => this.strictMath ? (this.parensStack != null && this.parensStack.isNotEmpty) : true;

//2.2.0
//  contexts.Eval.prototype.isMathOn = function () {
//      return this.strictMath ? (this.parensStack && this.parensStack.length) : true;
//  };

  ///
  //2.2.0 ok
  bool isPathRelative(String path) {
    RegExp re =  new RegExp(r'^(?:[a-z-]+:|\/)', caseSensitive: false);
    return !re.hasMatch(path);

//2.2.0
//    contexts.Eval.prototype.isPathRelative = function (path) {
//        return !/^(?:[a-z-]+:|\/)/i.test(path);
//    };
  }

  ///
  /// Resolves '.' and '..' in the path
  ///
  //2.2.0 ok
  String normalizePath(String path) {
    List<String> segments = path.split('/').reversed.toList();
    String segment;
    List<String> pathList = [];

    while (segments.isNotEmpty) {
      segment = segments.removeLast();
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