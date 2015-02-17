
library lessOptions.less;

import 'dart:io';
import 'package:path/path.dart' as path;

import 'cleancss_options.dart';
import 'index.dart';
import 'lessc_helper.dart';
import 'functions/functions.dart';
import 'logger.dart';

class LessOptions {
  // ****************** CONFIGURATION *********************************

  /// Whether to chunk input. more performant but causes parse issues.
  bool chunkInput = false;  // Must be false in 2.2.0

  ///
  /// Extends Less functions as alternative to javascript
  ///
  /// Example(see test/custom_functions_test.dart):
  /// class MyFunctions extends FunctionBase {
  ///   Dimension myFunction(Node a) => New Dimension(a.value);
  /// }
  /// options.custonFunctions = new MyFunctions();
  ///
  FunctionBase customFunctions;

  /// whether we are currently importing multiple copies
  bool importMultiple = false;

  /// Browser only - mime type for sheet import
  String mime;

  /// Default Numeric precision
  int numPrecision = 8;

  /// Whether to process imports. if false then imports will not be imported
  bool processImports = true;

  /// Whether to import synchronously
  bool syncImport = false;

  /// Browser only - whether to use the per file session cache
  bool useFileCache;

// ****************** COMMAND LINE OPTIONS ****************************

  /// Filename for the banner text - Not official option
  String banner = '';

  /// Whether to compress with clean-css
  bool cleancss = false;

  /// Color in error messages
  bool color = true;

  /// Whether to compress
  bool compress = false;

  /// Outputs a makefile import dependency list to stdout
  bool depends =  false;

  /// Whether to dump line numbers: 'comments', 'mediaquery' or 'all'
  String dumpLineNumbers = '';

  /// Defines a variable that can be referenced by the file
  String globalVariables = '';

  /// Whether to enforce IE compatibility (IE8 data-uri)
  bool ieCompat = true;

  /// Input filename or '-' for stdin
  String input = '';

  /// Whether to allow imports from insecure ssl hosts
  bool insecure = false;

  /// whether JavaScript is enabled. Dart version don't evaluate JavaScript
  bool javascriptEnabled = true;

  bool   lint = false;

  int logLevel = logLevelWarn;

  /// max-line-len - deprecated
  get maxLineLen => _maxLineLen;
  set maxLineLen(int value) {
    _maxLineLen = (value < 0) ? -1 : value;
  }
  int    _maxLineLen = -1;  //original max_line_len

  /// Modifies a variable already declared in the file
  String modifyVariables = '';

  /// Optimization level (for the chunker) - deprecated
  int optimization = 1;

  /// Output filename
  String output = '';

  /// Puts the less files into the map instead of referencing them
  bool outputSourceFiles = false;

  /// Paths to search for imports on
  List paths = [];

  /// Whether to adjust URL's to be relative
  bool relativeUrls = false;

  /// Rootpath to append to URL's
  String rootpath = '';

  int showTreeLevel; // debug level - not official

  /// whether to swallow errors and warnings
  bool silent = false;

  /// whether to output a source map
  var sourceMap = false;

  /// Sets sourcemap base path, defaults to current working directory
  String sourceMapBasepath = '';

  /// Puts the map (and any less files) into the output css file
  bool sourceMapFileInline = false;

  /// Outputs a v3 sourcemap to the filename (or output filename.map)
  String sourceMapOutputFilename;

  /// Adds this path onto the sourcemap filename and less file paths
  String sourceMapRootpath = '';

  /// Sets a custom URL to map file, for sourceMappingURL comment in generated CSS file
  String sourceMapURL = '';

  /// Forces evaluation of imports
  bool strictImports = false;

  /// Whether math has to be within parenthesis
  bool get strictMath => _strictMath;
  set strictMath(bool value){
    _strictMath = (value == null) ? false : value;
  }
  bool _strictMath = false;

  /// Whether units need to evaluate correctly
  bool get strictUnits => _strictUnits;
  set strictUnits(bool value){
    _strictUnits = (value == null) ? false : value;
  }
  bool   _strictUnits = false;

  /// Whether to add args into url tokens
  String urlArgs = '';

  /// Whether to log more activity
  bool   verbose = false;

  /// Whether to compress with the outside tool yui compressor. OPTION HAS BEEN REMOVED
  bool yuicompress = false;



// ****************** Internal

  CleancssOptions cleancssOptions = new CleancssOptions();

  String filename = ''; //same as input

  String inputBase = ''; //same as input

  Logger logger = new Logger();

  String outputBase = ''; // same as output

  bool parseError = false; // error detected in command line

  List plugins = []; //TODO 2.2.0

  String sourceMapFilename = '';  // sourceMap to clone()

  String sourceMapFullFilename;

  var sourceMapGenerator; // class instance - default: new SourceMapBuilder();

  String warningMessages = '';

  Function writeSourceMap; //Function writeSourceMap(String content), to write the sourcemap file

  ///
  LessOptions();

  ///
  /// Update less options from arg
  ///
  /// Example: '-include-path=lib/lessIncludes;lib/otherIncludes'
  ///
  bool parse(arg) {
    if (arg == null) return setParseError('empty');
    String command = arg[1];
    bool result;

    switch (command) {
      case 'v':
      case 'version':
        logger.log('lessc ${LessIndex.version.join('.')} (Less Compiler) [Dart]');
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
        warningMessages += 'yui-compress option has been removed. ignoring.';
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
      case 'log-level':
        if (checkArgFunc(command, arg[2])) {
          try {
            logLevel = int.parse(arg[2]);
            logger.setLogLevel(logLevel);
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
    if(option != null) logger.log('unrecognised less option $option');
    parseError = true;
    return false;
  }

  bool checkArgFunc(String command, String option) {
    if(option == null) {
      logger.log('$command option requires a parameter');
      return false;
    }
    return true;
  }

  // return null if error
  bool checkBooleanArg(String arg) {
    RegExp onOff = new RegExp(r'^(on|t|true|y|yes)|(off|f|false|n|no)$', caseSensitive: false);
    Match match;
    if ((match = onOff.firstMatch(arg)) == null){
      logger.log(' unable to parse $arg as a boolean. use one of on/t/true/y/yes/off/f/false/n/no');
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
    if (input.isNotEmpty) {
      inputBase = input;
      filename  = input;
      if (input != '-') {
        //input = path.normalize(path.absolute(input)); //use absolute path
        String inputDirName = new File(input).parent.path;
        paths.insert(0, inputDirName);
        if (sourceMapBasepath.isEmpty) sourceMapBasepath = inputDirName;

      } else {
        if (sourceMapBasepath.isEmpty) sourceMapBasepath = path.current;
      }
    } else {
      logger.log('lessc: no input files\n');
      printUsage();
      parseError = true;
      return false;
    }

    if (output.isNotEmpty) {
      outputBase = output;
      sourceMapOutputFilename = output;
      //output = path.normalize(path.absolute(output)); //use absolute path
      if (warningMessages.isNotEmpty) logger.log(warningMessages);
    }

    if(sourceMap is bool && sourceMap == true){
      if((output == null) && !sourceMapFileInline){
        logger.log('the sourcemap option only has an optional filename if the css filename is given');
        parseError = true;
        return false;
      }
      sourceMapFullFilename = sourceMapOutputFilename + '.map';
      sourceMap = path.basename(sourceMapFullFilename);
    }

    if(cleancss && (sourceMap == true || sourceMap.isNotEmpty)) {
      logger.log('the cleancss option is not compatible with sourcemap support at the moment. See Issue #1656');
      parseError = true;
      return false;
    }

    if(depends) {
      if(outputBase.isEmpty) {
        logger.log('option --depends requires an output path to be specified');
        parseError = true;
        return false;
      }
      //stdout.write(outputbase + ": "); TODO
    }

    if (!sourceMapFileInline) {
      writeSourceMap = sourceMapWriter;
    }

    return true;
  }


  void sourceMapWriter(String output) {
    String filename = sourceMapFullFilename;
    if(filename == null || filename.isEmpty) filename = sourceMap;
    new File(filename)
      ..createSync(recursive: true)
      ..writeAsStringSync(output);
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
    op.writeSourceMap     = this.writeSourceMap;
    op.maxLineLen         = this.maxLineLen;
    op.strictMath         = this.strictMath;
    op.strictUnits        = this.strictUnits;
    op.numPrecision       = this.numPrecision;
    op.urlArgs            = this.urlArgs;

    op.showTreeLevel      = this.showTreeLevel; //debug
    op.customFunctions    = this.customFunctions;

    return op;
  }
}