//source: tree/directive.js 2.5.0 lines 92-122

part of tree.less;

// Used in Directive & Media -
///
class OutputRulesetMixin {
  ///
  void outputRuleset(Contexts context, Output output, List<Node> rules) {
    if (context.cleanCss) return outputCleanRuleset(context, output, rules);

    final int ruleCnt = rules.length;

    context.tabLevel ??= 0;
    context.tabLevel++;

    // Compressed
    if (context.compress) {
      output.add('{');
      for (int i = 0; i < ruleCnt; i++) {
        rules[i].genCSS(context, output);
      }
      output.add('}');
      context.tabLevel--;
      return null;
    }

    // Non-compressed
    // ignore: prefer_interpolation_to_compose_strings
    final String tabSetStr = '\n' + '  ' * (context.tabLevel - 1);
    final String tabRuleStr = '$tabSetStr  ';
    if (ruleCnt == 0) {
      output.add(' {$tabSetStr}');
    } else {
      output.add(' {$tabRuleStr');
      rules[0].genCSS(context, output);
      for (int i = 1; i < ruleCnt; i++) {
        output.add(tabRuleStr);
        rules[i].genCSS(context, output);
      }
      output.add('$tabSetStr}');
    }

    context.tabLevel--;

//2.3.1
//  Directive.prototype.outputRuleset = function (context, output, rules) {
//      var ruleCnt = rules.length, i;
//      context.tabLevel = (context.tabLevel | 0) + 1;
//
//      // Compressed
//      if (context.compress) {
//          output.add('{');
//          for (i = 0; i < ruleCnt; i++) {
//              rules[i].genCSS(context, output);
//          }
//          output.add('}');
//          context.tabLevel--;
//          return;
//      }
//
//      // Non-compressed
//      var tabSetStr = '\n' + Array(context.tabLevel).join("  "), tabRuleStr = tabSetStr + "  ";
//      if (!ruleCnt) {
//          output.add(" {" + tabSetStr + '}');
//      } else {
//          output.add(" {" + tabRuleStr);
//          rules[0].genCSS(context, output);
//          for (i = 1; i < ruleCnt; i++) {
//              output.add(tabRuleStr);
//              rules[i].genCSS(context, output);
//          }
//          output.add(tabSetStr + '}');
//      }
//
//      context.tabLevel--;
//  };
  }

  ///
  void outputCleanRuleset(Contexts context, Output output, List<Node> rules) {
    final int ruleCnt = rules.length;

    context.tabLevel ??= 0;
    context.tabLevel++;

    output.add('{');
    for (int i = 0; i < ruleCnt; i++) {
      rules[i].genCSS(context, output);
    }
    output.add('}');

    context.tabLevel--;
  }
}
