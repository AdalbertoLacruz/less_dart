library less;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'src/less_error.dart';
import 'src/less_options.dart';
import 'src/logger.dart';
import 'src/environment/environment.dart';
import 'src/parser/parser.dart';
import 'src/render/render.dart';
import 'src/tree/tree.dart';

export 'src/functions/functions.dart' show FunctionBase, defineMethod;
export 'src/less_options.dart';
export 'src/tree/tree.dart';

class Less {
  StringBuffer stdin  = new StringBuffer();
  StringBuffer stdout = new StringBuffer();
  StringBuffer stderr = new StringBuffer();

  int currentErrorCode = 0;
  bool continueProcessing = true;

  Logger logger;
  LessOptions _options;

  Less(){
    logger = new Logger(stderr); // care the order
    _options = new LessOptions();
    Environment environment = new Environment()..options = _options;
  }

  ///
  /// Transform a less file to css file.
  ///
  /// [args] has the options and input/output file names.
  /// [modifyOptions] let programtically modify the options.
  ///
  /// Example:
  ///   new Less.transform(args, modifyOptions: (options){
  ///    options.plugins = ...
  ///   });
  ///
  Future transform(List<String> args, {Function modifyOptions}) {
    if (!argsFilter(args)) {
      currentErrorCode = _options.parseError ? 1 : 0;
      return new Future.value(currentErrorCode);
    }
    if(!_options.validate()){
      currentErrorCode = _options.parseError ? 1 : 0;
      return new Future.value(currentErrorCode);
    }

    if (modifyOptions != null) modifyOptions(this._options);
    this._options.pluginLoader.start();

    if(_options.input != '-') {
      // Default to .less
      String filename = _options.input;
      if (path.extension(filename).isEmpty) filename += '.less';

      File file = new File(filename);
      if (!file.existsSync()) {
        logger.error('Error cannot open file ${_options.input}');
        currentErrorCode = 3;
        return new Future.value(currentErrorCode);
      }

      return file.readAsString()
      .then((String content){
        return parseLessFile(content);
      })
      .catchError((e){
        logger.error('Error reading ${_options.input}');
        currentErrorCode = 3;
        return new Future.value(currentErrorCode);
      });
    } else {
      return parseLessFile(stdin.toString());
    }
  }

  /**
   * Process all arguments: -options and input/output
   */
  bool argsFilter(List<String> args){
    RegExp regOption = new RegExp(r'^--?([a-z][0-9a-z-]*)(?:=(.*))?$', caseSensitive:false);
    RegExp regPaths = new RegExp(r'^-I(.+)$', caseSensitive:true);
    Match match;
    bool continueProcessing = true;

    args.forEach((arg) {
      if ((match = regPaths.firstMatch(arg)) != null) { //I suppose same as include_path  "-I path/to/directory"
        _options.paths.add(match[1]);
        return;
      }

      if ((match = regOption.firstMatch(arg)) != null){
        if (continueProcessing) continueProcessing =   _options.parse(match);
        return;
      }

      if (_options.input == '') {
        _options.input = arg;
        return;
      }

      if (_options.output == '') {
        _options.output = arg;
      }
    });
    return continueProcessing;
  }

  Future parseLessFile(String data){
    Parser parser = new Parser(_options);
    return parser.parse(data).then((Ruleset tree){
      RenderResult result;

      if (tree == null) return new Future.value(currentErrorCode);

      //debug
      if(_options.showTreeLevel == 0) {
        String css = tree.toTree(_options).toString();
        stdout.write(css);
        return new Future.value(currentErrorCode);
      }

      try {
        result = new ParseTree(tree, parser.imports).toCSS(_options.clone(), parser.context);

        if (!_options.lint) {
          writeOutput(_options.output, result, _options);
        }

      } on LessExceptionError catch (e) {
        logger.error(e.toString());
        currentErrorCode = 2;
        return new Future.value(currentErrorCode);
      }

      return new Future.value(currentErrorCode);
    })
    .catchError((e){
      logger.error(e.toString());
      currentErrorCode = 1;
      return new Future.value(currentErrorCode);
    });
  }

  /// Writes css file, map file and dependencies
  writeOutput(String output, RenderResult result, LessOptions options) {
    //css
    if (output.isNotEmpty) {
      writeFile(output, result.css);
    } else {
      stdout.write(result.css);
    }

    //map
    if (options.sourceMap && !options.sourceMapOptions.sourceMapFileInline) {
      writeFile(options.sourceMapOptions.sourceMapFullFilename, result.map);
    }

    //dependencies
    if (options.depends) {
      String depends = options.outputBase + ': ';
      result.imports.forEach((item){ depends += item + ' ';});
      logger.log(depends);
    }
  }

  /// Creates the file [filename] with [content]
  void writeFile(String filename, String content) {
    try {
      new File(filename)
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
      logger.info('lessc: wrote ${filename}');
    } catch (e) {
      LessError error = new LessError(
          type: 'File',
          message: 'lessc: failed to create file ${filename}\n${e.toString()}');
      throw new LessExceptionError(error);
    }
  }
}