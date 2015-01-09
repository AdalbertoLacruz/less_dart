// source: less/env.js 1.7.5

library env.less;

import 'dart:async';

import 'file_info.dart';
import 'importer.dart';
import 'less_error.dart';
import 'less_options.dart';
import 'nodejs/nodejs.dart';
import 'parser/parser.dart';
import 'tree/tree.dart';

part 'imports.dart';

class Env {
  /// option - unmodified - paths to search for imports on
  List paths;

  /// option - optimization level (for the chunker)
  int optimization;

  /// list of files that have been imported, used for import-once
  var files = {};

  /// map - filename to contents of all the files
  Map<String, String> contents = {};

  /// map - filename to lines at the begining of each file to ignore
  var contentsIgnoredChars = {};

  /// option - whether to adjust URL's to be relative
  bool relativeUrls;

  /// option - rootpath to append to URL's
  String rootpath;

  /// option -
  bool strictImports;

  /// option - whether to allow imports from insecure ssl hosts
  bool insecure;

  /// option - whether to dump line numbers
  String dumpLineNumbers;

  /// option - whether to compress. EvalEnv.
  bool compress;

  /// option - whether to process imports. if false then imports will not be imported
  var processImports = true;

  /// option - whether to import synchronously
  bool syncImport = false;

  /// option - whether JavaScript is enabled. if undefined, defaults to true
  bool javascriptEnabled;

  /// browser only - mime type for sheet import
  var mime;

  /// browser only - whether to use the per file session cache
  var useFileCache;

  /// information about the current file.
  /// For error reporting and importing and making urls relative etc.
  FileInfo currentFileInfo;

  // not in js


  bool color;
  bool firstSelector; //Ruleset
  List<Node> frames = []; //Ruleset/MixinDefinition/Directive
  List selectors; //Ruleset
  List<Media> mediaBlocks; //Ruleset
  List<Media> mediaPath;
  int tabLevel = 0; //Ruleset
  bool lastRule = false; //Ruleset
  int numPrecision = null; //functions frunt

  /// Stack for evaluating expression in parenthesis flag
  List<bool> parensStack;

  Imports imports; //for LessError
  String input;   //for LessError

  // for default() function evaluation in Ruleset and MixinCall
  var defaultFunc;

  /* ****************    evalEnv properties   *************************  */ //TODO: Some types need revision

  /// whether to swallow errors and warnings
  bool silent;

  /// whether to log more activity
  bool verbose;

  /// whether to compress with the outside tool yui compressor
  bool yuicompress;

  /// whether to enforce IE compatibility (IE8 data-uri)
  bool ieCompat;

  /// whether math has to be within parenthesis
  bool strictMath;

  /// whether units need to evaluate correctly
  bool strictUnits;

  /// whether to compress with clean-css
  bool cleancss;

  /// whether to output a source map
  bool sourceMap;

  /// whether we are currently importing multiple copies
  bool importMultiple;

  /// whether to add args into url tokens
  String urlArgs;

  Env();

  ///
  /// copy from [options] LessOptions or Env
  ///
  Env.parseEnv(options){
    if (options == null) return;
    if (options is LessOptions || options is Env) _parseCopyProperties(options);
    if (options is Env)_parseCopyPropertiesEnv(options);

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
  }

  ///
  /// copy properties common to options and env
  ///
  void _parseCopyProperties(options) {
    paths               = options.paths;
    optimization        = options.optimization;
    relativeUrls        = options.relativeUrls;
    rootpath            = options.rootpath;
    strictImports       = options.strictImports;
    insecure            = options.insecure;
    dumpLineNumbers     = options.dumpLineNumbers;
    compress            = options.compress;
    javascriptEnabled   = options.javascriptEnabled;
    strictMath          = options.strictMath;
    color               = options.color;
    silent              = options.silent;
  }

  ///
  /// copy properties only from env class
  ///
  void _parseCopyPropertiesEnv(Env env) {
    files                 = env.files;
    contents              = env.contents;
    contentsIgnoredChars  = env.contentsIgnoredChars;
    processImports        = env.processImports;
    syncImport            = env.syncImport;
    mime                  = env.mime;
    useFileCache          = env.useFileCache;
    currentFileInfo       = env.currentFileInfo;
  }

  ///
  /// Build Env to render the tree
  /// [options] is LessOptions or Env
  ///
  factory Env.evalEnv([options, List frames]) {
    Env env = new Env();

    if (options != null) {
      env.silent          = options.silent;
      env.verbose         = options.verbose;
      env.compress        = options.compress;
      env.yuicompress     = options.yuicompress;
      env.ieCompat        = options.ieCompat;
      env.strictMath      = options.strictMath;
      env.strictUnits     = options.strictUnits;
      env.cleancss        = options.cleancss;
      env.sourceMap       = options.sourceMap;
      env.importMultiple  = options.importMultiple;
      env.urlArgs         = options.urlArgs;
      env.dumpLineNumbers = options.dumpLineNumbers;
      env.defaultFunc     = (options is Env) ? options.defaultFunc : null;
    }
    env.frames          = (frames != null) ? frames : [];

    return env;
  }

  /// Clone Env
  factory Env.evalEnvClone(Env source, [List frames]) {
    Env env = new Env();

        if (source != null) {
          env.silent          = source.silent;
          env.verbose         = source.verbose;
          env.compress        = source.compress;
          env.yuicompress     = source.yuicompress;
          env.ieCompat        = source.ieCompat;
          env.strictMath      = source.strictMath;
          env.strictUnits     = source.strictUnits;
          env.cleancss        = source.cleancss;
          env.sourceMap       = source.sourceMap;
          env.dumpLineNumbers = source.dumpLineNumbers;
          env.importMultiple  = source.importMultiple;
          env.urlArgs         = source.urlArgs;
        }
        env.frames          = (frames != null) ? frames : [];

        return env;
  }

  /// parensStack push
  void inParenthesis() {
    if (this.parensStack == null) this.parensStack = [];
    this.parensStack.add(true);

//    tree.evalEnv.prototype.inParenthesis = function () {
//        if (!this.parensStack) {
//            this.parensStack = [];
//        }
//        this.parensStack.push(true);
//    };
  }

  /// parensStack pop. Always return true.
  bool outOfParenthesis() => this.parensStack.removeLast();

//    tree.evalEnv.prototype.outOfParenthesis = function () {
//        this.parensStack.pop();
//    };

  ///
  bool isMathOn() => this.strictMath ? (this.parensStack != null && this.parensStack.isNotEmpty) : true;

//    tree.evalEnv.prototype.isMathOn = function () {
//        return this.strictMath ? (this.parensStack && this.parensStack.length) : true;
//    };


  ///
  bool isPathRelative(String path) {
    RegExp re =  new RegExp(r'^(?:[a-z-]+:|\/)', caseSensitive: false);
    return !re.hasMatch(path);

//    tree.evalEnv.prototype.isPathRelative = function (path) {
//        return !/^(?:[a-z-]+:|\/)/.test(path);
//    };
  }

  ///
  /// Resolves '.' and '..' in the path
  /// #
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

//    tree.evalEnv.prototype.normalizePath = function( path ) {
//        var
//          segments = path.split("/").reverse(),
//          segment;
//
//        path = [];
//        while (segments.length !== 0 ) {
//            segment = segments.pop();
//            switch( segment ) {
//                case ".":
//                    break;
//                case "..":
//                    if ((path.length === 0) || (path[path.length - 1] === "..")) {
//                        path.push( segment );
//                    } else {
//                        path.pop();
//                    }
//                    break;
//                default:
//                    path.push( segment );
//                    break;
//            }
//        }
//
//        return path.join("/");
//    };
  }

  // less/tree.js 1.7.5 lines 36-42
   static find(List obj, Function fun) {
     int i;
     var r;

     for (i = 0; i < obj.length; i++) {
       r = fun(obj[i]);
       if (r != null) return r;
     }
     return null;
   }

//tree.find = function (obj, fun) {
//    for (var i = 0, r; i < obj.length; i++) {
//        r = fun.call(obj, obj[i]);
//        if (r) { return r; }
//    }
//    return null;
//};

}