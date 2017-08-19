// source: less/parser.js 2.5.0 index.js

library parser.less;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import '../contexts.dart';
import '../environment/environment.dart';
import '../file_info.dart';
import '../import_manager.dart';
import '../less_error.dart';
import '../less_options.dart';
import '../plugins/plugins.dart';
import '../tree/tree.dart';
import '../utils.dart';
import '../visitor/visitor_base.dart';

part 'charcode.dart';
part 'chunker.dart';
part 'parser_input.dart';
part 'entities.dart';
part 'mixin.dart';
part 'parse_node.dart';
part 'parsers.dart';

/*
 *  A relatively straight-forward predictive parser.
 *  There is no tokenization/lexing stage, the input is parsed
 *  in one sweep.
 *
 *  To make the parser fast enough to run in the browser, several
 *  optimization had to be made:
 *
 *  - Matching and slicing on a huge input is often cause of slowdowns.
 *    The solution is to chunkify the input into smaller strings.
 *    The chunks are stored in the `chunks` var,
 *    `j` holds the current chunk index, and `currentPos` holds
 *    the index of the current chunk in relation to `input`.
 *    This gives us an almost 4x speed-up.
 *
 *  - In many cases, we don't need to match individual tokens;
 *    for example, if a value doesn't hold any variables, operations
 *    or dynamic references, the parser can effectively 'skip' it,
 *    treating it as a literal.
 *    An example would be '1px solid #000' - which evaluates to itself,
 *    we don't need to know what the individual components are.
 *    The drawback, of course is that you don't get the benefits of
 *    syntax-checking on the CSS. This gives us a 50% speed-up in the parser,
 *    and a smaller speed-up in the code-gen.
 *
 *
 *  Token matching is done with the `$` function, which either takes
 *  a terminal string or regexp, or a non-terminal function to call.
 *  It also takes care of moving all the indices forwards.
 *
 */
///
class Parser {
  ///
  String        banner = '';
  ///
  Contexts      context;
  ///
  FileInfo      fileInfo;
  ///
  String        globalVars = '';
  ///
  ImportManager imports;
  ///
  String        modifyVars = '';
  ///
  Parsers       parsers;
  ///
  String        preText = '';

  ///
  Parser(LessOptions options) {
    context = new Contexts.parse(options);

    if (options.banner.isNotEmpty) {
      try {
        banner = new File(options.banner).readAsStringSync();
      } catch (_) {}
    }

    globalVars = options.globalVariables.isNotEmpty
        ? '${serializeVars(options.globalVariables)}\n'
        : '';
    modifyVars = options.modifyVariables.isNotEmpty
        ? '\n${serializeVars(options.modifyVariables)}'
        : '';
  }

  ///
  Parser.fromImporter(Contexts this.context, ImportManager this.imports, FileInfo this.fileInfo);

  ///
  /// Parse an input string into an abstract syntax tree.
  ///
  /// [str] A string containing 'less' markup
  ///
  /// NO @param additionalData. An optional map which can contains vars - a map (key, value) of variables to apply
  ///
  Future<Ruleset> parse(String str) {
    Ruleset root;
    String  _str = str;

    fileInfo ??= context.currentFileInfo;
    imports ??= new ImportManager(context, fileInfo);
    final Map<String, dynamic> processOptions =  <String, dynamic>{
        'context': context,
        'imports': imports,
        'fileInfo': fileInfo};

    if (context.pluginManager != null) {
      context.pluginManager.getPreProcessors().forEach((Processor preProcessor) {
        _str = preProcessor.process(_str, processOptions);
      });
    }

    if (globalVars.isNotEmpty || banner.isNotEmpty) {
      preText = '$banner$globalVars'.replaceAll(new RegExp(r'\r\n?'), '\n');

      if (!imports.contentsIgnoredChars.containsKey(fileInfo.filename))
          imports.contentsIgnoredChars[fileInfo.filename] = 0;
      imports.contentsIgnoredChars[fileInfo.filename] += preText.length;
    }

    // Remove potential UTF Byte Order Mark
    _str = _str.replaceAll('\r\n', '\n').replaceAll(new RegExp(r'^\uFEFF'), '');
    _str = '$preText$_str$modifyVars';

    imports.contents[fileInfo.filename] = _str;

    context
      ..imports = imports
      ..input = _str;

    // Start with the primary rule.
    // The whole syntax tree is held under a Ruleset node,
    // with the `root` property set to true, so no `{}` are
    // output. The callback is called when the input is parsed.

    try {
      parsers = new Parsers(_str, context);
      root = new Ruleset(null, parsers.primary())
          ..root = true
          ..firstRoot = true;
      parsers.isFinished();

      new IgnitionVisitor().run(root); // @options directive process

      if (context.processImports) {
        return new ImportVisitor(imports)
            .runAsync(root)
            .then((_) => new Future<Ruleset>.value(root))
            .catchError((Object e) {
              throw new LessExceptionError(LessError.transform(e, type: 'Import', context: context));
            });
      }
    } catch (e, s) {
      return new Future<Ruleset>.error(
        new LessExceptionError(LessError.transform(e, stackTrace: s, context: context))
      );
    }

    return new Future<Ruleset>.value(root);
  }

  ///
  String serializeVars(List<VariableDefinition> vars) =>
      vars.fold(new StringBuffer(), (StringBuffer prev, VariableDefinition vardef) =>
        prev
            ..write(vardef.name.startsWith('@') ? '' : '@')
            ..write('${vardef.name}: ${vardef.value}')
            ..write(vardef.value.endsWith(';') ? '' : ';')
      ).toString();

//2.4.0
//  Parser.serializeVars = function(vars) {
//      var s = '';
//
//      for (var name in vars) {
//          if (Object.hasOwnProperty.call(vars, name)) {
//              var value = vars[name];
//              s += ((name[0] === '@') ? '' : '@') + name + ': ' + value +
//                  ((String(value).slice(-1) === ';') ? '' : ';');
//          }
//      }
//
//      return s;
//  };

}
