// source: tree.js

library tree.less;

import 'dart:math' as math;

import '../file_info.dart';
import '../env.dart';
import '../functions.dart';
import '../less_debug_info.dart';
import '../less_error.dart';
import '../less_options.dart';
import '../output.dart';
import '../source_map_output.dart';
import '../nodejs/nodejs.dart';
import '../visitor/visitor_base.dart';

part 'alpha.dart';
part 'anonymous.dart';
part 'assignment.dart';
part 'attribute.dart';
part 'call.dart';
part 'color.dart';
part 'colors.dart';
part 'condition.dart';
part 'combinator.dart';
part 'comment.dart';
part 'detached_ruleset.dart';
part 'dimension.dart';
part 'directive.dart';
part 'element.dart';
part 'extend.dart';
part 'expression.dart';
part 'javascript.dart';
part 'import.dart';
part 'keyword.dart';
part 'media.dart';
part 'mixin_call.dart';
part 'mixin_definition.dart';
part 'negative.dart';
part 'operation.dart';
part 'paren.dart';
part 'rule.dart';
part 'ruleset.dart';
part 'quoted.dart';
part 'ruleset_call.dart';
part 'selector.dart';
part 'unicode_descriptor.dart';
part 'unit.dart';
part 'unit_conversions.dart';
part 'url.dart';
part 'value.dart';
part 'variable.dart';

// TODO review properties/methods to eliminate

class Node {
  /// hashCode own or inherited for object compare
  int id;

  String type;
  var value;
  var name;

  bool allowImports;
  bool evaldCondition; //See selector
  bool parensInOp = false; //See parsers.operand
  bool parens = false; //Expression

  Node originalRuleset; //TODO remove. used in mixin_call

  LessDebugInfo debugInfo;
  var rules; //Ruleset
  var elements;
  var selectors;
  List<Extend> allExtends; //Ruleset
  var operands;

  /// Directive overrides it
  bool isCharset() => false;

  Node() {
    id = hashCode;
  }

  /// Default eval returns the node
  eval(Env env) => this; //TODO to Delete

  evalImports(Env env){}

  /// Generate CSS from this node.
  /// The default method does nothing.
  void genCSS(Env env, Output output){}

  throwAwayComments() { return null; }

  /// default - does nothing
  accept(VisitorBase visitor) { return null;}


  //StringBuffer toCSS(Env env) {
  String toCSS(Env env) {
     Output output = new Output();
     this.genCSS(env, output);
     //return output.value;
     return output.toString();

//    tree.toCSS = function (env) {
//        var strs = [];
//        this.genCSS(env, {
//            add: function(chunk, fileInfo, index) {
//                strs.push(chunk);
//            },
//            isEmpty: function () {
//                return strs.length === 0;
//            }
//        });
//        return strs.join('');
//    };

   }

  //debug print the node tree
  StringBuffer toTree(LessOptions options) {
    Env env = new Env.evalEnv(options);
     Output output = new Output();
     this.genTree(env, output);
     return output.value;
  }

  void genTree(Env env, Output output) {
    int i;
    Node rule;
    String tabStr = '  ' * env.tabLevel;
    List process = [];


    String nameNode = name is String ? name : null;
    if (nameNode == null) nameNode = value is String ? value : '';
    nameNode = nameNode.replaceAll('\n', '');

    output.add('${tabStr}$type ($nameNode)\n');
    env.tabLevel++;

    if (this.selectors is List) process.addAll(this.selectors);
    if (this.rules is List) process.addAll(this.rules);
    if (this.elements is List) process.addAll(this.elements);
    if (this.name is List) process.addAll(this.name);
    if (this.value is List) process.addAll(this.value);
    if (this.operands is List) process.addAll(this.operands);

    if (process.isNotEmpty) {
      for (i = 0; i < process.length; i++) {
        process[i].genTree(env, output);
      }
    }
    if(value is Node) {
      (value as Node).genTree(env, output);
    }
    env.tabLevel--;
  }
}

//-----------------------------------------------------------

abstract class CompareNode {
  /// Returns -1, 0 or +1
  int compare(Node x);
}
abstract class EvalNode {
  eval(Env env);
}
abstract class MakeImportantNode {
  Node makeImportant();
}

abstract class MarkReferencedNode {
  void markReferenced();
}

abstract class MatchConditionNode {
  List<Node> rules;
  bool matchCondition(List<MixinArgs> args, Env env);
  bool matchArgs(List<MixinArgs> args, Env env);
}

abstract class OperateNode {
  Node operate(Env env, String op, Node other);
}

abstract class ToCSSNode {
  void genCSS(Env env, Output output);
  String toCSS(Env env);
}

//-----------------------------------------------------------

// tree.js lines 65-95 for Directive & Media
class OutputRulesetMixin {
  void outputRuleset(Env env, Output output, List<Node> rules) {
    int ruleCnt = rules.length;

    if (env.tabLevel == null) env.tabLevel = 0;
    env.tabLevel++;

    // Compressed
    if (env.compress) {
      output.add('{');
      for (int i = 0; i < ruleCnt; i++) rules[i].genCSS(env, output);
      output.add('}');
      env.tabLevel--;
      return;
    }

    // Non-compressed
    String tabSetStr  = '\n' +  '  ' * (env.tabLevel - 1);
    String tabRuleStr = tabSetStr + '  ';
    if (ruleCnt == 0) {
      output.add(' {' + tabSetStr + '}');
    } else {
      output.add(' {' + tabRuleStr);
      rules[0].genCSS(env, output);
      for (int i = 1; i < ruleCnt; i++) {
        output.add(tabRuleStr);
        rules[i].genCSS(env, output);
      }
      output.add(tabSetStr + '}');
    }

    env.tabLevel--;

//tree.outputRuleset = function (env, output, rules) {
//    var ruleCnt = rules.length, i;
//    env.tabLevel = (env.tabLevel | 0) + 1;
//
//    // Compressed
//    if (env.compress) {
//        output.add('{');
//        for (i = 0; i < ruleCnt; i++) {
//            rules[i].genCSS(env, output);
//        }
//        output.add('}');
//        env.tabLevel--;
//        return;
//    }
//
//    // Non-compressed
//    var tabSetStr = '\n' + Array(env.tabLevel).join("  "), tabRuleStr = tabSetStr + "  ";
//    if (!ruleCnt) {
//        output.add(" {" + tabSetStr + '}');
//    } else {
//        output.add(" {" + tabRuleStr);
//        rules[0].genCSS(env, output);
//        for (i = 1; i < ruleCnt; i++) {
//            output.add(tabRuleStr);
//            rules[i].genCSS(env, output);
//        }
//        output.add(tabSetStr + '}');
//    }
//
//    env.tabLevel--;
//};
  }
}
