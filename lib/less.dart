library less;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'src/less_error.dart';
import 'src/less_options.dart';
import 'src/nodejs/nodejs.dart';
import 'src/parser/parser.dart';
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

  NodeConsole console;
  LessOptions _options;

  Less(){
    console = new NodeConsole(stderr); // is important the order
    _options = new LessOptions();
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

    if(_options.input != '-') {
      // Default to .less
      String filename = _options.input;
      if (path.extension(filename).isEmpty) filename += '.less';

      File file = new File(filename);
      if (!file.existsSync()) {
        console.log('Error cannot open file ${_options.input}');
        currentErrorCode = 3;
        return new Future.value(currentErrorCode);
      }

      return file.readAsString()
      .then((String content){
        return parseLessFile(content);
      })
      .catchError((e){
        console.log('Error reading ${_options.input}');
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
    data = _options.globalVariables + data;
    if (_options.modifyVariables.isNotEmpty) data = data + '\n' + _options.modifyVariables;

    Parser parser = new Parser(_options);
    return parser.parse(data)
    .then((Ruleset tree){
      Function writeSourceMap = _options.writeSourceMap;
      String css;

      if (tree == null) return new Future.value(currentErrorCode);

      //debug
      if(_options.showTreeLevel == 0) {
        css = tree.toTree(_options).toString();
        stdout.write(css);
        return new Future.value(currentErrorCode);
      }

      if (_options.depends) {
        for (var file in parser.imports.files) stdout.write(file + ' ');
      } else {
        try {
          if (_options.lint) writeSourceMap = (String output){};
          css = tree.rootToCSS((_options.clone()
                              ..writeSourceMap = writeSourceMap), parser.context);
          if (!_options.lint) {
            if (_options.output.isNotEmpty) {
              //ensureDirectory(output);
              new File(_options.output)
                ..createSync(recursive: true)
                ..writeAsStringSync(css);
              if (_options.verbose) console.log('lessc: wrote ${_options.output}');
            } else {
              stdout.write(css);
            }
          }

        } on LessExceptionError catch (e) {
          console.log(e.toString());
          currentErrorCode = 2;
          return new Future.value(currentErrorCode);
        }
      }

      return new Future.value(currentErrorCode);
    })
    .catchError((e){
      console.log(e.toString());
      currentErrorCode = 1;
      return new Future.value(currentErrorCode);
    });
  }
}
