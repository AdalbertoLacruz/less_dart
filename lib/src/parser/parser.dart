// source: less/parser.js 1.7.5 index.js

library parser.less;

import 'dart:async';
import 'dart:io';

import '../contexts.dart';
import '../file_info.dart';
import '../import_manager.dart';
import '../less_error.dart';
import '../less_options.dart';
import '../utils.dart';
import '../nodejs/nodejs.dart';
import '../tree/tree.dart';
import '../visitor/visitor_base.dart';

part 'charcode.dart';
part 'chunker.dart';
part 'parser_input.dart';
part 'entities.dart';
part 'mixin.dart';
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
class Parser {
  String input;   // LeSS input string
  //var rootFilename = env && env.filename; --> inicializattion TODO

  ImportManager imports;
  Contexts context;
  FileInfo fileInfo;
  Parsers parsers;
  String preText = '';

  Parser(LessOptions options){
    context = new Contexts.parse(options);
    if (options.banner.isNotEmpty) {
      try {
        preText = new File(options.banner).readAsStringSync();
      } catch (e) {}
    }
  }

  Parser.fromImporter(Contexts this.context, ImportManager this.imports, FileInfo this.fileInfo) {
  }

  //  parse: function (str, callback, additionalData)

  ///
  /// Parse an input string into an abstract syntax tree.
  ///
  /// [str] A string containing 'less' markup
  ///
  /// NO @param [additionalData] An optional map which can contains vars - a map (key, value) of variables to apply
  ///
  //2.2.0 TODO upgrading
  Future parse(String str) {
    Ruleset root;
    Ruleset rulesetEvaluated;

//    var root, line, lines, error = null, globalVars, modifyVars, preText = "";

//    i = j = currentPos = furthest = 0;
//    globalVars = (additionalData && additionalData.globalVars) ? less.Parser.serializeVars(additionalData.globalVars) + '\n' : '';
//    modifyVars = (additionalData && additionalData.modifyVars) ? '\n' + less.Parser.serializeVars(additionalData.modifyVars) : '';
//
//    if (globalVars || (additionalData && additionalData.banner)) {
//        preText = ((additionalData && additionalData.banner) ? additionalData.banner : "") + globalVars;
//        parser.imports.contentsIgnoredChars[env.currentFileInfo.filename] = preText.length;
//    }

    if (fileInfo == null) fileInfo = context.currentFileInfo;
    if (imports == null) imports = new ImportManager(context, fileInfo);

    if (preText.isNotEmpty) {
      preText = preText.replaceAll('\r\n', '\n');
      str = preText + str;
      imports.contentsIgnoredChars[fileInfo.filename] = preText.length;
      preText = ''; // avoid banner in @import
    }

    str = str.replaceAll('\r\n', '\n');

    // Remove potential UTF Byte Order Mark
//  input = str = preText + str.replace(/^\uFEFF/, '') + modifyVars;
    input = str = str.replaceAll(new RegExp(r'^\uFEFF'), '');
    imports.contents[fileInfo.filename] = str;
    //imports.rootFilename = fileInfo.filename; NO

    context.imports = imports;
    context.input = str;

    // Start with the primary rule.
    // The whole syntax tree is held under a Ruleset node,
    // with the `root` property set to true, so no `{}` are
    // output. The callback is called when the input is parsed.

    try {
      parsers = new Parsers(str, context);
      root = new Ruleset(null, parsers.primary());
      root.root = true;
      root.firstRoot = true;
      parsers.isFinished();

      if (context.processImports) {
        return new ImportVisitor(this.imports).run(root).then((_){
            return new Future.value(root);
        }).catchError((e){
          LessError error = LessError.transform(e, type: 'Import', context: context);
          throw new LessExceptionError(error);
        });
      }
    } catch (e, s) {
      LessExceptionError error = new LessExceptionError(LessError.transform(e, stackTrace: s, context: context));
      return new Future.error(error);
    }

    return new Future.value(root);
  }
}