// source: bin/lessc.js less/default-options.js 3.7.1 20180718

library less_options.less;

import 'dart:io';
import 'package:path/path.dart' as path_lib;

import 'cleancss_options.dart';
import 'data/constants.dart';
import 'index.dart';
import 'lessc_helper.dart';
import 'logger.dart';
import 'plugins/plugins.dart';
import 'tree/tree.dart';

///
class LessOptions {
  ///
  LessOptions() {
    pluginLoader = PluginLoader(this);
  }

  // ****************** CONFIGURATION *********************************

  /// Whether to chunk input. more performant but causes parse issues.
  bool chunkInput = false; // Must be false in 2.2.0

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

  // Whether to compress with clean-css
  //bool cleancss = false;

  /// color output in the terminal, for error messages
  bool color = true;

  ///
  /// Compress using less built-in compression.
  /// This does an okay job but does not utilise all the tricks of
  /// dedicated css compression.
  ///
  bool compress = false;

  /// Outputs a makefile import dependency list to stdout
  bool depends = false;

  /// Whether to dump line numbers: 'comments', 'mediaquery' or 'all'
  String dumpLineNumbers = '';

  ///
  /// Effectively the declaration is put at the top of your base Less file,
  /// meaning it can be used but it also can be overridden if this variable
  /// is defined in the file.
  /// Defines a variable list that can be referenced by the file
  ///
  List<VariableDefinition> globalVariables = <VariableDefinition>[];

  /// Compatibility with IE8. Used for limiting data-uri length
  bool ieCompat = false; // true until 3.0

  /// Input filename or '-' for stdin
  String input = '';

  /// Allow Imports from Insecure HTTPS Hosts
  bool insecure = false;

  /// whether JavaScript is enabled. Dart version don't evaluate JavaScript
  bool javascriptEnabled = false;

  /// Runs the less parser and just reports errors without any output.
  bool lint = false;

  ///
  int logLevel = logLevelWarn;

  /// How to process math
  int math = MathConstants.always;

  /// max-line-len - deprecated
  int get maxLineLen => _maxLineLen;
  set maxLineLen(int value) {
    _maxLineLen = (value < 0) ? -1 : value;
  }

  int _maxLineLen = -1; //original max_line_len

  ///
  /// As opposed to the global variable option, this puts the declaration at the
  /// end of your base file, meaning it will override anything defined in your Less file.
  ///
  List<VariableDefinition> modifyVariables = <VariableDefinition>[];

  /// Output filename
  String output = '';

  ///
  /// Sets available include paths.
  /// If the file in an @import rule does not exist at that exact location,
  /// less will look for it at the location(s) passed to this option.
  /// You might use this for instance to specify a path to a library which
  /// you want to be referenced simply and relatively in the less files.
  ///
  List<String> paths = <String>[];

  ///
  /// By default URLs are kept as-is, so if you import a file in a sub-directory
  /// that references an image, exactly the same URL will be output in the css.
  /// This option allows you to re-write URL's in imported files so that the
  /// URL is always relative to the base imported file
  ///
  int rewriteUrls = RewriteUrlsConstants.off;

  ///
  /// Allows you to add a path to every generated import and url in your css.
  /// This does not affect less import statements that are processed, just ones
  /// that are left in the output css.
  ///
  String rootpath = '';

  ///
  int showTreeLevel; // debug level - not official

  /// whether to swallow errors and warnings
  bool silent = false;

  /// whether to output a source map
  bool sourceMap = false;

  /// All necessary information for source map
  SourceMapOptions sourceMapOptions = SourceMapOptions();

  ///
  /// The strictImports controls whether the compiler will allow an @import inside of either
  /// @media blocks or (a later addition) other selector blocks.
  /// See: https://github.com/less/less.js/issues/656
  /// Forces evaluation of imports
  ///
  bool strictImports = false;

  /// Without this option, less attempts to guess at the output unit when it does maths.
  bool get strictUnits => _strictUnits;
  set strictUnits(bool value) {
    _strictUnits = (value == null) ? false : value;
  }

  bool _strictUnits = false;

  /// This option allows you to specify a argument to go on to every URL.
  String urlArgs = '';

  /// Whether to log more activity
  bool verbose = false;

// ****************** Internal ******************************

  ///
  bool cleanCss = false; //clean-css optimizations
  ///
  CleancssOptions cleancssOptions = CleancssOptions();

  ///
  String filename = ''; //same as input

  ///
  String inputBase = ''; //same as input

  ///
  Logger logger = Logger();

  ///
  String outputBase = ''; // same as output

  ///
  bool parseError = false; // error detected in command line

  ///
  List<Plugin> plugins = <Plugin>[];

  ///
  PluginLoader pluginLoader;

  ///
  PluginManager pluginManager;

  ///
  RegExp pluginRe = RegExp(r'^([^=]+)(=(.*))?'); //plugin arguments split

  //String warningMessages = '';

  ///
  /// Add space delimited options.
  ///
  /// Let process @options directives
  ///
  bool fromCommandLine(String line) {
    Match match;
    final RegExp regOption =
        RegExp(r'^--?([a-z][0-9a-z-]*)(?:=(.*))?$', caseSensitive: false);
    bool result = true;

    line.split(' ').forEach((String arg) {
      if ((match = regOption.firstMatch(arg)) != null) {
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
  bool parse(Match arg) {
    if (arg == null) return setParseError('empty');
    final String command = arg[1];

    switch (command) {
      case 'v':
      case 'version':
        logger
            .log('lessc ${LessIndex.version.join('.')} (Less Compiler) [Dart]');
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
      case 'js':
        // js is not supported
        javascriptEnabled = true;
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
        } else {
          return setParseError(command);
        }
        break;
      case 'no-color':
        color = false;
        break;
      case 'ie-compat':
        ieCompat = true;
        break;
      case 'no-js':
        return setParseError(
            'The "--no-js" argument is deprecated, as inline JavaScript is disabled by default and not supported.');
        break;
      case 'include-path':
        if (checkArgFunc(command, arg[2])) {
          // ; supported on windows.
          // : supported on windows and linux, excluding a drive letter like C:\ so C:\file:D:\file parses to 2
          if (arg[2].startsWith('package')) {
            paths = <String>[arg[2]];
          } else {
            paths =
                arg[2].split(Platform.isWindows ? RegExp(r':(?!\\)|;') : ':');
          }

//            options.paths = match[2]
//                .split(os.type().match(/Windows/) ? /:(?!\\)|;/ : ':')
//                .map(function(p) {
//                    if (p) {
//                        return path.resolve(process.cwd(), p);  //ABSOLUTE PATH -TODO ?
//                    }
//                });
        } else {
          return setParseError(command);
        }
        break;
      case 'line-numbers':
        if (checkArgFunc(command, arg[2])) {
          dumpLineNumbers = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'source-map':
        sourceMap = true;
        if (arg[2] != null) sourceMapOptions.sourceMapFullFilename = arg[2];
        break;
      case 'source-map-rootpath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapRootpath = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'source-map-basepath':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapBasepath = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'source-map-inline':
      case 'source-map-map-inline':
        sourceMapOptions.sourceMapFileInline = true;
        sourceMap = true;
        break;
      case 'source-map-include-source':
      case 'source-map-less-inline':
        sourceMapOptions.outputSourceFiles = true;
        break;
      case 'source-map-url':
        if (checkArgFunc(command, arg[2])) {
          sourceMapOptions.sourceMapURL = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'rp':
      case 'rootpath':
        if (checkArgFunc(command, arg[2])) {
          rootpath =
              arg[2].replaceAll(r'\', '/'); //arg[2] must be raw (r'something')
        } else {
          return setParseError(command);
        }
        break;
      case 'relative-urls':
        logger.warn(
            'The --relative-urls option has been deprecated. Use --rewrite-urls=all.');
        rewriteUrls = RewriteUrlsConstants.all;
        break;
      case 'ru':
      case 'rewrite-urls':
        if (arg[2] != null) {
          switch (arg[2].toLowerCase()) {
            case 'local':
              rewriteUrls = RewriteUrlsConstants.local;
              break;
            case 'off':
              rewriteUrls = RewriteUrlsConstants.off;
              break;
            case 'all':
              rewriteUrls = RewriteUrlsConstants.all;
              break;
            default:
              return exitError('Unknown rewrite-urls argument ${arg[2]}');
          }
        } else {
          rewriteUrls = RewriteUrlsConstants.all;
        }
        break;
      case 'sm':
      case 'strict-math':
        logger.warn(
            'The --strict-math option has been deprecated. Use --math=strict');
        if (checkArgFunc(command, arg[2])) {
          if (checkBooleanArg(arg[2])) math = MathConstants.strictLegacy;
        }
        break;
      case 'm':
      case 'math':
        if (checkArgFunc(command, arg[2])) {
          switch (arg[2].toLowerCase()) {
            case 'always':
              math = MathConstants.always;
              break;
            case 'parens-division':
              math = MathConstants.parensDivision;
              break;
            case 'strict':
            case 'parens':
              math = MathConstants.parens;
              break;
            case 'strict-legacy':
              math = MathConstants.strictLegacy;
              break;
            default:
              return setParseError();
          }
        } else {
          return setParseError();
        }
        break;
      case 'su':
      case 'strict-units':
        if (checkArgFunc(command, arg[2])) {
          if ((strictUnits = checkBooleanArg(arg[2])) == null) {
            return setParseError();
          }
        } else {
          return setParseError(command);
        }
        break;
      case 'global-var':
        if (checkArgFunc(command, arg[2])) {
          parseVariableOption(arg[2], globalVariables);
        } else {
          return setParseError(command);
        }
        break;
      case 'modify-var':
        if (checkArgFunc(command, arg[2])) {
          parseVariableOption(arg[2], modifyVariables);
        } else {
          return setParseError(command);
        }
        break;
      case 'url-args':
        if (checkArgFunc(command, arg[2])) {
          urlArgs = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'show-tree-level':
        if (checkArgFunc(command, arg[2])) {
          try {
            showTreeLevel = int.parse(arg[2]);
          } catch (e) {
            return setParseError('$command bad argument');
          }
        } else {
          return setParseError(command);
        }
        break;
      case 'log-level':
        if (checkArgFunc(command, arg[2])) {
          try {
            logLevel = int.parse(arg[2]);
            logger.setLogLevel(logLevel);
          } catch (e) {
            return setParseError('$command bad argument');
          }
        } else {
          return setParseError(command);
        }
        break;
      case 'banner':
        if (checkArgFunc(command, arg[2])) {
          banner = arg[2];
        } else {
          return setParseError(command);
        }
        break;
      case 'plugin':
        final Match splitupArg = pluginRe.firstMatch(arg[2]);
        final String name = splitupArg[1];
        final String pluginOptions = splitupArg[3];
        final Plugin plugin = pluginLoader.tryLoadPlugin(name, pluginOptions);

        if (plugin != null) {
          plugins.add(plugin);
        } else {
          return exitError(
              'Unable to load plugin $name please make sure that it is installed\n');
        }
        break;
      default:
        final Plugin plugin =
            pluginLoader.tryLoadPlugin('less-plugin-$command', arg[2]);
        if (plugin != null) {
          plugins.add(plugin);
        } else {
          return exitError(
              'Unable to interpret argument $command\nif it is a plugin (less-plugin-$command), make sure that it is installed\n');
        }
    }
    return true;
  }

  ///
  bool setParseError([String option]) {
    if (option != null) logger.error('unrecognised less option $option');
    parseError = true; // exitCode = 1
    return false;
  }

  ///
  /// exit with error message
  ///
  bool exitError(String message) {
    logger.error(message);
    parseError = true; // exitCode = 1
    return false;
  }

  ///
  /// Check the command has a argument
  ///
  bool checkArgFunc(String command, String option) {
    if (option == null) {
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
    Match match;
    final RegExp onOff =
        RegExp(r'^(on|t|true|y|yes)|(off|f|false|n|no)$', caseSensitive: false);

    if ((match = onOff.firstMatch(arg)) == null) {
      logger.error(
          ' unable to parse $arg as a boolean. Use one of on/t/true/y/yes/off/f/false/n/no');
      return null;
    }
    if (match[1] != null) return true;
    if (match[2] != null) return false;
    return null;
  }

  ///
  void parseVariableOption(String option, List<VariableDefinition> variables) {
    final List<String> parts = option.split('=');
    variables.add(VariableDefinition(parts[0], parts[1]));

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
  void definePlugin(String name, Plugin plugin,
      {bool load = false, String options = ''}) {
    pluginLoader.define(name, plugin);

    if (load) {
      final Plugin pluginLoaded = pluginLoader.tryLoadPlugin(name, options);
      if (pluginLoaded != null) plugins.add(pluginLoaded);
    }
  }

  ///
  /// check options combinations
  ///
  bool validate() {
    if (input.isNotEmpty) {
      inputBase = input;
      filename = input;
      if (input != '-') {
        //input = path.normalize(path.absolute(input)); //use absolute path
        paths.insert(0, File(input).parent.path);
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

    if (sourceMap) {
      sourceMapOptions.sourceMapInputFilename = input;
      if (sourceMapOptions.sourceMapFullFilename.isEmpty) {
        if (output.isEmpty && !sourceMapOptions.sourceMapFileInline) {
          logger
            ..error(
                'the sourcemap option only has an optional filename if the css filename is given')
            ..error(
                'consider adding --source-map-map-inline which embeds the sourcemap into the css');
          parseError = true;
          return false;
        }

        // its in the same directory, so always just the basename
        sourceMapOptions
          ..sourceMapOutputFilename = path_lib.basename(output)
          ..sourceMapFullFilename = '$output.map'
          ..sourceMapFilename =
              path_lib.basename(sourceMapOptions.sourceMapFullFilename);
      } else if (!sourceMapOptions.sourceMapFileInline) {
        final String mapFilename =
            path_lib.absolute(sourceMapOptions.sourceMapFullFilename);
        final String mapDir = path_lib.dirname(mapFilename);
        final String outputDir = path_lib.dirname(output);

        sourceMapOptions
          // find the path from the map to the output file
          ..sourceMapOutputFilename = path_lib.normalize(path_lib.join(
              path_lib.relative(mapDir, from: outputDir),
              path_lib.basename(output)))
          // make the sourcemap filename point to the sourcemap relative to the css file output directory
          ..sourceMapFilename = path_lib.normalize(path_lib.join(
              path_lib.relative(outputDir, from: mapDir),
              path_lib.basename(sourceMapOptions.sourceMapFullFilename)));
      }
    }

    if (sourceMapOptions.sourceMapBasepath.isEmpty) {
      sourceMapOptions.sourceMapBasepath =
          input.isNotEmpty ? path_lib.dirname(input) : path_lib.current;
    }

    if (sourceMapOptions.sourceMapRootpath.isEmpty) {
      final String pathToMap = path_lib.dirname(
          sourceMapOptions.sourceMapFileInline
              ? output
              : sourceMapOptions.sourceMapFullFilename);
      final String pathToInput =
          path_lib.dirname(sourceMapOptions.sourceMapInputFilename);
      sourceMapOptions.sourceMapRootpath =
          path_lib.relative(pathToMap, from: pathToInput);
    }

    if (depends) {
      if (outputBase.isEmpty) {
//        logger.error('option --depends requires an output path to be specified');
//        parseError = true;
//        return false;
        return exitError(
            'option --depends requires an output path to be specified');
      }
    }

    return true;
  }

  ///
  LessOptions clone() {
    final LessOptions op = LessOptions()
      ..silent = silent
      ..verbose = verbose
      ..ieCompat = ieCompat
      ..compress = compress
      ..cleancssOptions = cleancssOptions
      ..dumpLineNumbers = dumpLineNumbers
      ..math = math
      ..sourceMap =
          (sourceMap is bool) ? sourceMap : (sourceMap as String).isNotEmpty
      ..sourceMapOptions = sourceMapOptions
      ..maxLineLen = maxLineLen
      ..pluginManager = pluginManager
      ..paths = paths
      ..rewriteUrls = rewriteUrls
      ..strictUnits = strictUnits
      ..numPrecision = numPrecision
      ..urlArgs = urlArgs
      ..variables = variables
      ..showTreeLevel = showTreeLevel //debug
      ..cleanCss = cleanCss;
    return op;
  }
}

// *********************************

///
class SourceMapOptions {
  /// Puts the less files into the map instead of referencing them
  bool outputSourceFiles = false;

  /// Sets sourcemap base path, defaults to current working directory
  String sourceMapBasepath = '';

  /// Puts the map (and any less files) into the output css file
  bool sourceMapFileInline = false;

  ///
  String sourceMapFilename = '';

  ///
  String sourceMapFullFilename = '';

  ///
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
  ///
  String name;

  ///
  String value;

  ///
  VariableDefinition(this.name, this.value);
}
