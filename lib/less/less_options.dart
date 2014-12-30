
library lessOptions.less;

import 'dart:io';

import 'cleancss_options.dart';
import 'index.dart';
import 'lessc_helper.dart';
import '../nodejs/nodejs.dart';

class LessOptions {
  bool   depends =  false;
  bool   compress = false;
  bool   cleancss = false;

  int    _maxLineLen = -1;  //original max_line_len
  set maxLineLen(int value) {
    _maxLineLen = (value < 0) ? -1 : value;
  }
  get maxLineLen => _maxLineLen;

  int    optimization = 1;
  bool   silent = false;
  bool   verbose = false;
  bool   lint = false;
  List   paths = [];
  /// color in error messages
  bool   color = true;
  bool   strictImports = false;
  bool   insecure = false;
  String rootpath = '';
  bool   relativeUrls = false;
  bool   ieCompat = true;

  bool   _strictMath = false;
  set strictMath(bool value){
    _strictMath = (value == null) ? false : value;
  }
  bool get strictMath => _strictMath;

  bool   _strictUnits = false;
  set strictUnits(bool value){
    _strictUnits = (value == null) ? false : value;
  }
  get strictUnits => _strictUnits;

  String globalVariables = '';
  String modifyVariables = '';
  String urlArgs = '';
  bool   javascriptEnabled = true;  // *** From here not in original ***
  String banner = '';
  String dumpLineNumbers = '';      //comments or mediaquery
  var    sourceMap = false;
  String sourceMapFilename = '';  // sourceMap to clone()
  String sourceMapRootpath = '';
  String sourceMapBasepath = '';
  bool   outputSourceFiles = false;
  String sourceMapURL = '';
  String sourceMapOutputFilename;
  String sourceMapFullFilename;

  /// whether to compress with the outside tool yui compressor. OPTION HAS BEEN REMOVED
  bool yuicompress = false;

  /// whether we are currently importing multiple copies
  bool importMultiple = false;

  Function writeSourceMap; //for clone()

  // I/O
  String input = '';
  String filename = ''; //same as input
  String inputBase = '';
  String output = '';
  String outputBase = '';

  NodeConsole console = new NodeConsole();
  CleancssOptions cleancssOptions = new CleancssOptions();
  bool sourceMapFileInline = false;
  bool parseError = false;

  //debug
  int showTreeLevel;

  LessOptions();

  /*
   * Update less options from arg
   * ej.: '-include-path=lib/lessIncludes;lib/otherIncludes'
   */
  bool parse(arg) {
    if (arg == null) return setParseError('empty');
    String command = arg[1];
    bool result;

    switch (command) {
      case 'v':
      case 'version':
        console.log('lessc ${LessIndex.version.join('.')} (Less Compiler) [Dart]');
        return false;
      case 'verbose':
        verbose = true;
        break;
      case 's':
      case 'silent':
        silent = true;
        break;
      case 'l':
      case 'lint':
        lint = true;
        break;
      case 'strict-imports':
        strictImports = true;
        break;
      case 'h':
      case 'help':
        printUsage();
        return false;
      case 'x':
      case 'compress':
        compress = true;
        break;
      case 'insecure':
        insecure = true;
        break;
      case 'M':
      case 'depends':
        depends = true;
        break;
      case 'yui-compress':
        console.log('yui-compress option has been removed. ignoring.');
        break;
      case 'clean-css':
        cleancss = true;
        break;
      case 'max-line-len':
        if (checkArgFunc(command, arg[2])) {
          try {
            maxLineLen = int.parse(arg[2]);
          } catch (e) {
            return setParseError('$command bad argument');
          }
        } else return setParseError(command);
        break;
      case 'no-color':
        color = false;
        break;
      case 'no-ie-compat':
        ieCompat = false;
        break;
      case 'no-js':
        javascriptEnabled = false;
        break;
      case 'include-path':
        if (checkArgFunc(command, arg[2])) {
          paths = arg[2].split(Platform.isWindows ? ';' : ':');

//            _options.paths = arg[2].split(os.type().match(/Windows/) ? ';' : ':')
//                .map(function(p) {
//                    if (p) {
//                        return path.resolve(process.cwd(), p);  //ABSOLUTE PATH TODO ?
//                    }
//                });
        } else return setParseError(command);
        break;
      case 'O0': optimization = 0; break;
      case 'O1': optimization = 1; break;
      case 'O2': optimization = 2; break;
      case 'line-numbers':
        if (checkArgFunc(command, arg[2])) {
          dumpLineNumbers = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map':
        if (arg[2] == null) {
          sourceMap = true;
        } else {
          sourceMap = arg[2];
        }
        break;
      case 'source-map-rootpath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapRootpath = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map-basepath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapBasepath = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map-map-inline':
        sourceMapFileInline = true;
        sourceMap = true;
        break;
      case 'source-map-less-inline':
        outputSourceFiles = true;
        break;
      case 'source-map-url':
        if (checkArgFunc(command, arg[2])) {
          sourceMapURL = arg[2];
        } else return setParseError(command);
        break;
      case 'rp':
      case 'rootpath':
        if (checkArgFunc(command, arg[2])) {
          rootpath = arg[2].replaceAll(r'\', '/'); //arg[2] must be raw (r'something')
        } else return setParseError(command);
        break;
      case "ru":
      case "relative-urls":
        relativeUrls = true;
        break;
      case "sm":
      case "strict-math":
        if (checkArgFunc(command, arg[2])) {
          if ((strictMath = checkBooleanArg(arg[2])) == null) return setParseError();
        } else return setParseError(command);
        break;
      case "su":
      case "strict-units":
        if (checkArgFunc(command, arg[2])) {
            if((strictUnits = checkBooleanArg(arg[2])) == null) return setParseError();
        } else return setParseError(command);
        break;
      case "global-var":
        if (checkArgFunc(command, arg[2])) {
          globalVariables += parseVariableOption(arg[2]);
        } else return setParseError(command);
        break;
      case "modify-var":
        if (checkArgFunc(command, arg[2])) {
          modifyVariables += parseVariableOption(arg[2]);
        } else return setParseError(command);
        break;
      case "clean-option":
        result = cleancssOptions.parse(arg[2]);
        if (cleancssOptions.parseError) parseError = true;
        return result;
      case 'url-args':
        if (checkArgFunc(command, arg[2])) {
            urlArgs = arg[2];
        } else return setParseError(command);
        break;
      case 'show-tree-level':
        if (checkArgFunc(command, arg[2])) {
          try {
            showTreeLevel = int.parse(arg[2]);
          } catch (e) {
            return setParseError('$command bad argument');
          }
        } else return setParseError(command);
        break;
      case 'banner':
        if (checkArgFunc(command, arg[2])) {
          banner = arg[2];
        } else return setParseError(command);
        break;

      default:
        printUsage();
        return setParseError(command);
    }
    return true;
  }

  bool setParseError([String option]) {
    if(option != null) console.log('unrecognised less option $option');
    parseError = true;
    return false;
  }

  bool checkArgFunc(String command, String option) {
    if(option == null) {
      console.log('$command option requires a parameter');
      return false;
    }
    return true;
  }

  // return null if error
  bool checkBooleanArg(String arg) {
    RegExp onOff = new RegExp(r'^(on|t|true|y|yes)|(off|f|false|n|no)$', caseSensitive: false);
    Match match;
    if ((match = onOff.firstMatch(arg)) == null){
      console.log(' unable to parse $arg as a boolean. use one of on/t/true/y/yes/off/f/false/n/no');
      return null;
    }
    if (match[1] != null) return true;
    if (match[2] != null) return false;
    return null;
  }

  String parseVariableOption(String option) {
    var parts = option.split('=');
    return '@${parts[0]}:${parts[1]};\n';
  }

  /*
   * check options combinations
   */
  bool validate() {
    if (input != null) {
      inputBase = input;
      filename  = input;
      if (input != '-') {
        String inputDirName = new File(input).parent.path;
        paths.insert(0, inputDirName);
        if (sourceMapBasepath == '') sourceMapBasepath = inputDirName;
      }
    } else {
      console.log('lessc: no input files\n');
      printUsage();
      parseError = true;
      return false;
    }

    if (output != null) {
      outputBase = output;
      sourceMapOutputFilename = output;
    }

    if(sourceMap == true){
      if((output == null) && !sourceMapFileInline){
        console.log('the sourcemap option only has an optional filename if the css filename is given');
        parseError = true;
        return false;
      }
      sourceMapFullFilename = sourceMapOutputFilename + '.map';
      sourceMap = Path.basename(new File(sourceMapFullFilename).path);
    }

    if(cleancss && (sourceMap == true || sourceMap != '')) {
      console.log('the cleancss option is not compatible with sourcemap support at the moment. See Issue #1656');
      parseError = true;
      return false;
    }

    if(depends) {
      if(outputBase == null) {
        console.log('option --depends requires an output path to be specified');
        parseError = true;
        return false;
      }
      //stdout.write(outputbase + ": "); TODO
    }


    return true;
  }

  LessOptions clone() {
    LessOptions op = new LessOptions();

    op.silent           = this.silent;
    op.verbose          = this.verbose;
    op.ieCompat         = this.ieCompat;
    op.compress         = this.compress;
    op.cleancss         = this.cleancss;
    op.cleancssOptions  = this.cleancssOptions;
    op.dumpLineNumbers  = this.dumpLineNumbers;
    op.sourceMap        = (this.sourceMap is bool) ? this.sourceMap : (this.sourceMap as String).isNotEmpty;
    op.sourceMapFilename = (this.sourceMap is String) ? this.sourceMap : '';
    op.sourceMapURL     = this.sourceMapURL;
    op.sourceMapOutputFilename = this.sourceMapOutputFilename;
    op.sourceMapBasepath  = this.sourceMapBasepath;
    op.sourceMapRootpath  = this.sourceMapRootpath;
    op.outputSourceFiles  = this.outputSourceFiles;
    //writeSourceMap: writeSourceMap
    op.maxLineLen         = this.maxLineLen;
    op.strictMath         = this.strictMath;
    op.strictUnits        = this.strictUnits;
    op.urlArgs            = this.urlArgs;

    op.showTreeLevel      = this.showTreeLevel; //debug

    return op;

  }
}