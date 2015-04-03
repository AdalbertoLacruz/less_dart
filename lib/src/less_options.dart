library lessOptions.less;

import 'dart:io';
import 'package:path/path.dart' as path;

import 'cleancss_options.dart';
import 'index.dart';
import 'lessc_helper.dart';
import 'logger.dart';
import 'functions/functions.dart';
import 'plugins/plugins.dart';
import 'tree/tree.dart';

class LessOptions {
  // ****************** CONFIGURATION *********************************

  /// Whether to chunk input. more performant but causes parse issues.
  bool chunkInput = false;  // Must be false in 2.2.0

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

  /// Allows setting variables with a hash. Example:
  /// variables = {'my-color': new Color.fromKeyword('red')};
  Map<String, Node> variables;

// ****************** COMMAND LINE OPTIONS ****************************

  /// Filename for the banner text - Not official option
  String banner = '';

  /// Whether to compress with clean-css
  //bool cleancss = false;

  /// Color in error messages
  bool color = true;

  /// Whether to compress
  bool compress = false;

  /// Outputs a makefile import dependency list to stdout
  bool depends =  false;

  /// Whether to dump line numbers: 'comments', 'mediaquery' or 'all'
  String dumpLineNumbers = '';

  /// Defines a variable list that can be referenced by the file
  List<VariableDefinition> globalVariables = [];

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

  /// Modifies a variable (list) already declared in the file
  List<VariableDefinition> modifyVariables = [];

  /// Output filename
  String output = '';

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
  bool sourceMap = false;

  /// All necessary information for source map
  SourceMapOptions sourceMapOptions = new SourceMapOptions();

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

// ****************** Internal

  CleancssOptions cleancssOptions = new CleancssOptions();

  String filename = ''; //same as input

  String inputBase = ''; //same as input

  Logger logger = new Logger();

  String outputBase = ''; // same as output

  bool parseError = false; // error detected in command line

  List<Plugin> plugins = [];

  PluginLoader pluginLoader;

  PluginManager pluginManager;

  RegExp pluginRe = new RegExp(r'^([^=]+)(=(.*))?'); //plugin arguments split

  //String warningMessages = '';

  ///
  LessOptions() {
    this.pluginLoader = new PluginLoader(this);
  }

  ///
  /// Add space delimited options.
  ///
  /// Let process @options directives
  ///
  bool fromCommandLine(String line) {
    RegExp regOption = new RegExp(r'^--?([a-z][0-9a-z-]*)(?:=(.*))?$', caseSensitive:false);
    Match match;
    bool result = true;;

    List<String> args = line.split(' ');
    args.forEach((arg){
      if ((match = regOption.firstMatch(arg)) != null){
        result = result && parse(match);
      }
    });
    return result;
  }

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
        logger.verbose();
        break;
      case 's':
      case 'silent':
        silent = true;
        logger.silence();
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
      case 'line-numbers':
        if (checkArgFunc(command, arg[2])) {
          dumpLineNumbers = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map':
        sourceMap = true;
        if (arg[2] != null) sourceMapOptions.sourceMapFullFilename = arg[2];
        break;
      case 'source-map-rootpath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapRootpath = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map-basepath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapBasepath = arg[2];
        } else return setParseError(command);
        break;
      case 'source-map-map-inline':
        sourceMapOptions.sourceMapFileInline = true;
        sourceMap = true;
        break;
      case 'source-map-less-inline':
        sourceMapOptions.outputSourceFiles = true;
        break;
      case 'source-map-url':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapURL = arg[2];
        } else return setParseError(command);
        break;
      case 'rp':
      case 'rootpath':
        if (checkArgFunc(command, arg[2])) {
          rootpath = arg[2].replaceAll(r'\', '/'); //arg[2] must be raw (r'something')
        } else return setParseError(command);
        break;
      case 'ru':
      case 'relative-urls':
        relativeUrls = true;
        break;
      case 'sm':
      case 'strict-math':
        if (checkArgFunc(command, arg[2])) {
          if ((strictMath = checkBooleanArg(arg[2])) == null) return setParseError();
        } else return setParseError(command);
        break;
      case 'su':
      case 'strict-units':
        if (checkArgFunc(command, arg[2])) {
            if((strictUnits = checkBooleanArg(arg[2])) == null) return setParseError();
        } else return setParseError(command);
        break;
      case 'global-var':
        if (checkArgFunc(command, arg[2])) {
          parseVariableOption(arg[2], globalVariables);
        } else return setParseError(command);
        break;
      case 'modify-var':
        if (checkArgFunc(command, arg[2])) {
          parseVariableOption(arg[2], modifyVariables);
        } else return setParseError(command);
        break;
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
      case 'plugin':
        Match splitupArg = pluginRe.firstMatch(arg[2]);
        String name = splitupArg[1];
        String pluginOptions = splitupArg[3];
        Plugin plugin = pluginLoader.tryLoadPlugin(name, pluginOptions);

        if (plugin != null) {
          plugins.add(plugin);
        } else {
          logger.error('Unable to load plugin ${name} please make sure that it is installed\n');
          //printUsage();
          parseError = true;
          return false;
        }
        break;
      default:
        Plugin plugin = pluginLoader.tryLoadPlugin('less-plugin-' + command, arg[2]);
        if (plugin != null) {
          plugins.add(plugin);
        } else {
          logger.error('Unable to interpret argument ${command}\nif it is a plugin (less-plugin-${command}), make sure that it is installed under or at the same level as less\n');
          //printUsage();
          parseError = true;
          return false;
        }
    }
    return true;
  }

  bool setParseError([String option]) {
    if(option != null) logger.error('unrecognised less option $option');
    parseError = true;
    return false;
  }

  ///
  /// Check the command has a argument
  ///
  bool checkArgFunc(String command, String option) {
    if(option == null) {
      logger.error('$command option requires a parameter');
      return false;
    }
    return true;
  }

  ///
  /// Checks the argument is yes/no or equivalent, returning true/false
  /// if not boolean returns null
  ///
  bool checkBooleanArg(String arg) {
    RegExp onOff = new RegExp(r'^(on|t|true|y|yes)|(off|f|false|n|no)$', caseSensitive: false);
    Match match;
    if ((match = onOff.firstMatch(arg)) == null){
      logger.error(' unable to parse $arg as a boolean. use one of on/t/true/y/yes/off/f/false/n/no');
      return null;
    }
    if (match[1] != null) return true;
    if (match[2] != null) return false;
    return null;
  }

  ///
  parseVariableOption(String option, List<VariableDefinition> variables) {
    List<String> parts = option.split('=');
    variables.add(new VariableDefinition(parts[0], parts[1]));

//2.4.0
//  var parseVariableOption = function(option, variables) {
//      var parts = option.split('=', 2);
//      variables[parts[0]] = parts[1];
//  };
  }

  /// Show help
  void printUsage() {
    LesscHelper.printUsage();
    pluginLoader.printUsage(plugins);
  }

  ///
  /// Define a custom [plugin] named [name] and load it if [load] is true
  ///
  /// It is a helper for modifyOptions in less.transform
  ///
  /// Example1: definePlugin('myPlugin', new MyPlugin());
  /// Exmaple2: definePlugin('myPlugin', new MyPlugin(), true, '');
  ///
  void definePlugin(String name, Plugin plugin, [bool load = false, String options = '']) {
    pluginLoader.define(name, plugin);

    if(load) {
      Plugin pluginLoaded = pluginLoader.tryLoadPlugin(name, options);
      if (pluginLoaded != null) plugins.add(pluginLoaded);
    }
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
      }
    } else {
      logger.error('lessc: no input files\n');
      printUsage();
      parseError = true;
      return false;
    }

    if (output.isNotEmpty) {
      outputBase = output;
      //output = path.normalize(path.absolute(output)); //use absolute path
    }

    if(sourceMap) {
      sourceMapOptions.sourceMapInputFilename = input;
      if (sourceMapOptions.sourceMapFullFilename.isEmpty) {
        if (output.isEmpty && !sourceMapOptions.sourceMapFileInline) {
          logger.log('the sourcemap option only has an optional filename if the css filename is given');
          logger.log('consider adding --source-map-map-inline which embeds the sourcemap into the css');
          return false;
        }

        // its in the same directory, so always just the basename
        sourceMapOptions.sourceMapOutputFilename = path.basename(output);
        sourceMapOptions.sourceMapFullFilename = output + '.map';
        sourceMapOptions.sourceMapFilename = path.basename(sourceMapOptions.sourceMapFullFilename);

      } else if (!sourceMapOptions.sourceMapFileInline) {
        String mapFilename = path.absolute(sourceMapOptions.sourceMapFullFilename);
        String mapDir = path.dirname(mapFilename);
        String outputDir = path.dirname(output);

        // find the path from the map to the output file
        sourceMapOptions.sourceMapOutputFilename = path.normalize(path.join(
            path.relative(mapDir, from: outputDir), path.basename(output)));

        // make the sourcemap filename point to the sourcemap relative to the css file output directory
        sourceMapOptions.sourceMapFilename = path.normalize(path.join(
            path.relative(outputDir, from: mapDir),
            path.basename(sourceMapOptions.sourceMapFullFilename)));
      }
    }

    if (sourceMapOptions.sourceMapBasepath.isEmpty) {
      sourceMapOptions.sourceMapBasepath = input.isNotEmpty ? path.dirname(input) : path.current;
    }

    if (sourceMapOptions.sourceMapRootpath.isEmpty) {
      String pathToMap = path.dirname(sourceMapOptions.sourceMapFileInline
          ? output
          : sourceMapOptions.sourceMapFullFilename);
      String pathToInput = path.dirname(sourceMapOptions.sourceMapInputFilename);
      sourceMapOptions.sourceMapRootpath = path.relative(pathToMap, from: pathToInput);
    }

    if(depends) {
      if(outputBase.isEmpty) {
        logger.error('option --depends requires an output path to be specified');
        parseError = true;
        return false;
      }
    }

    return true;
  }

  LessOptions clone() {
    LessOptions op = new LessOptions();

    op.silent           = this.silent;
    op.verbose          = this.verbose;
    op.ieCompat         = this.ieCompat;
    op.compress         = this.compress;
    op.cleancssOptions  = this.cleancssOptions;
    op.dumpLineNumbers  = this.dumpLineNumbers;
    op.sourceMap        = (this.sourceMap is bool) ? this.sourceMap : (this.sourceMap as String).isNotEmpty;
    op.sourceMapOptions = this.sourceMapOptions;
    op.maxLineLen         = this.maxLineLen;
    op.pluginManager      = this.pluginManager;
    op.paths              = this.paths;
    op.strictMath         = this.strictMath;
    op.strictUnits        = this.strictUnits;
    op.numPrecision       = this.numPrecision;
    op.urlArgs            = this.urlArgs;
    op.variables          = this.variables;

    op.showTreeLevel      = this.showTreeLevel; //debug

    return op;
  }
}

// *********************************

class SourceMapOptions {
  /// Puts the less files into the map instead of referencing them
  bool outputSourceFiles = false;

  /// Sets sourcemap base path, defaults to current working directory
  String sourceMapBasepath = '';

  /// Puts the map (and any less files) into the output css file
  bool sourceMapFileInline = false;

  String sourceMapFilename = '';

  String sourceMapFullFilename = '';

  String sourceMapInputFilename = '';

  /// Outputs a v3 sourcemap to the filename (or output filename.map)
  String sourceMapOutputFilename = '';

  /// Adds this path onto the sourcemap filename and less file paths
  String sourceMapRootpath = '';

  /// Sets a custom URL to map file, for sourceMappingURL comment in generated CSS file
  String sourceMapURL = '';
}

/// GlobalVariables & ModifyVariables item definition
class VariableDefinition {
  String name;
  String value;
  VariableDefinition(this.name, this.value);
}