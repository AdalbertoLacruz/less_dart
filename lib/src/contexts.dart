// source: less/contexts.js 3.0.4 20180625

library contexts.less;

import 'file_info.dart';
import 'functions/functions.dart';
import 'import_manager.dart';
import 'less_options.dart';
import 'plugins/plugins.dart';
import 'tree/tree.dart';
import 'utils.dart';

///
class Contexts {
  // ***** From options
  ///
  bool avoidDartOptimization; //Dart prune some code apparently not used

  ///
  /// option - whether to chunk input. more performant (?) but causes parse issues.
  ///
  bool chunkInput;

  /// options.cleancss
  bool cleanCss = false;

  /// options.color
  bool color = false;

  ///
  /// option - whether to compress
  ///
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

  ///
  /// option - whether to dump line numbers
  ///
  String dumpLineNumbers;

  /// What extension try append to import file ('.less')
  String ext;

  /// List of files that have been imported, used for import-once
  Map<String, Node> files = <String, Node>{};

  /// Ruleset
  bool firstSelector = false;

  /// Ruleset/MixinDefinition/Directive = VariableMixin
  List<Node> frames = <Node>[];

  ///
  String input; // for LessError

  ///
  /// option - whether Inline JavaScript is enabled.
  /// if undefined, defaults to false
  ///
  bool javascriptEnabled = true;

  ///
  /// whether to enforce IE compatibility (IE8 data-uri)
  ///
  bool ieCompat = true;

  ///
  /// used to bubble up !important statements
  /// 
  List<ImportantRule> importantScope = <ImportantRule>[];

  ///
  /// whether we are currently importing multiple copies
  ///
  bool importMultiple = false;

  /// for LessError
  ImportManager imports;

  ///
  /// option - whether to allow imports from insecure ssl hosts
  ///
  bool insecure = false;

  /// Ruleset
  bool lastRule = false;

  /// To let turn off math for calc()
  bool mathOn = true;

  /// Ruleset
  List<Media> mediaBlocks;

  ///
  List<Media> mediaPath;

  ///
  /// browser only - mime type for sheet import
  ///
  String mime;

  /// options.numPrecision
  int numPrecision; //functions frunt

  /// Stack for evaluating expression in parenthesis flag
  List<bool> parensStack;

  ///
  /// option - unmodified - paths to search for imports on (additional include paths)
  ///
  List<String> paths;

  ///
  /// Used as the plugin manager for the session
  ///
  PluginManager pluginManager;

  ///
  /// option & context - whether to process imports. if false then imports will not be imported.
  /// Used by the import manager to stop multiple import visitors being created.
  ///
  bool processImports;

  ///
  /// Used in FileManager.loadFileSync to read the file asBytes.
  /// Return the contents in FileLoaded.codeUnits
  ///
  bool rawBuffer = false;

  ///
  /// option - whether to adjust URL's to be relative
  ///
  bool relativeUrls = false;

  ///
  /// option - rootpath to append to URL's
  ///
  String rootpath;

  /// used in Ruleset
  List<List<Selector>> selectors;

  // options.silent
  //bool silent;

  ///
  /// whether to output a source map
  ///
  bool sourceMap;

  /// options.strictImports
  bool strictImports = false;

  ///
  /// whether math has to be within parenthesis
  ///
  String strictMath = 'false'; // TODO

  ///
  /// whether units need to evaluate correctly
  ///
  bool strictUnits = false;

  ///
  /// option - whether to import synchronously
  ///
  bool syncImport = false;

  ///
  /// for identation in Ruleset CSS generation
  ///
  int tabLevel = 0;

  ///
  /// whether to add args into url tokens
  ///
  String urlArgs;

  ///
  /// browser only - whether to use the per file session cache
  ///
  bool useFileCache;

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
    if (options == null) return;

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
  /// clone this, non deep
  ///
  Contexts clone() => Utils.clone(this, new Contexts());

  ///
  /// Copy properties for parse
  ///
  /// Some are common to options and contexts
  ///
  void parseCopyProperties(dynamic options) {
    if (options is! LessOptions && options is! Contexts) return;

    final List<String> properties = <String>[
      'paths',          // from options
      'relativeUrls',
      'rootpath',
      'strictImports',
      'insecure',
      'dumpLineNumbers',
      'compress',
      'syncImport',
      'chunkInput',
      'mime',
      'useFileCache',
      'processImports',
      'numPrecision',
      'color',
      'pluginManager',
      'cleanCss',
      'files',          // from contexts
      'contents',
      'contentsIgnoredChars',
      'currentFileInfo'
    ];

    Utils.copyFrom(options, this, properties); // from -> to (this)
  }

  ///
  /// Copy properties for eval
  /// [options] is LessOptions or Context
  ///
  static void evalCopyProperties(Contexts newctx, dynamic options) {
    if (options == null) return;

    final List<String> properties = <String>[
      'compress',       // from options
      'ieCompat',
      'strictMath',
      'strictUnits',
      'numPrecision',
      'sourceMap',
      'importMultiple',
      'urlArgs',
      'javascriptEnabled',
      'dumpLineNumbers',
      'pluginManager',
      'paths',
      'cleanCss',
      'defaultFunc',     // from Contexts
      'importantScope'
    ];

    Utils.copyFrom(options, newctx, properties);
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
  bool isMathOn([String op]) {
    if (!mathOn) return false;
    if (op == '/' && (strictMath != 'false') && (parensStack?.isEmpty ?? true)) return false; // TODO
    if (strictMath == 'true') return parensStack?.isNotEmpty ?? false; // TODO
    return true;

//3.0.4 20180625
//  contexts.Eval.prototype.mathOn = true;
//  contexts.Eval.prototype.isMathOn = function (op) {
//    if (!this.mathOn) {
//        return false;
//    }
//    if (op === '/' && this.strictMath && (!this.parensStack || !this.parensStack.length)) {
//        return false;
//    }
//    if (this.strictMath === true) {
//        return this.parensStack && this.parensStack.length;
//    }
//    return true;
//  };
  }

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
