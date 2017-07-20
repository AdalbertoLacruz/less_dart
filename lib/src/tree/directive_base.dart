//source: less/tree/atrule.js 3.0.0 20160714

part of tree.less;

///
/// Base class for AtRule/Directive and Media
///
class DirectiveBase extends Node
      with OutputRulesetMixin, VariableMixin {
  //
  @override FileInfo                currentFileInfo;
  @override DebugInfo               debugInfo;
  @override String                  name;
  @override covariant List<Ruleset> rules; //more restrictive type
  @override final String            type = 'DirectiveBase';

  ///
  bool  isRooted = false;

  ///
  DirectiveBase(
      {this.currentFileInfo,
      this.debugInfo,
      int index,
      this.isRooted,
      this.name,
      VisibilityInfo visibilityInfo}) {
        this.index = index;
        copyVisibilityInfo(visibilityInfo);
      }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name,
    'value': value,
    'rules': rules
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (rules != null)
        rules = visitor.visitArray(rules);
    if (value != null)
        value = visitor.visit(value);

//2.8.0 20160702
// AtRule.prototype.accept = function (visitor) {
//     var value = this.value, rules = this.rules;
//     if (rules) {
//         this.rules = visitor.visitArray(rules);
//     }
//     if (value) {
//         this.value = visitor.visit(value);
//     }
// };
  }

  ///
  @override
  bool isRulesetLike() => (rules != null) || !isCharset();

//2.8.0 20160702
// AtRule.prototype.isRulesetLike = function() {
//     return this.rules || !this.isCharset();
// };

  ///
  @override
  bool isCharset() => '@charset' == name;

//2.8.0 20160702
// AtRule.prototype.isCharset = function() {
//     return "@charset" === this.name;
// };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add(name, fileInfo: currentFileInfo, index: index);

    if (value != null) {
      output.add(' ');
      value.genCSS(context, output);
    }

    if (rules != null) {
      outputRuleset(context, output, rules);
    } else {
      output.add(';');
    }

//3.0.0 20160714
// AtRule.prototype.genCSS = function (context, output) {
//     var value = this.value, rules = this.rules;
//     output.add(this.name, this.fileInfo(), this.getIndex());
//     if (value) {
//         output.add(' ');
//         value.genCSS(context, output);
//     }
//     if (rules) {
//         this.outputRuleset(context, output, rules);
//     } else {
//         output.add(';');
//     }
// };
  }

  ///
  @virtual @override
  Node eval(Contexts context) {
    Node          value = this.value;
    List<Ruleset> rules = this.rules;

    // media stored inside other directive should not bubble over it
    // backpup media bubbling information
    final List<Media> mediaPathBackup = context.mediaPath;
    final List<Media> mediaBlocksBackup = context.mediaBlocks;

    // deleted media bubbling information
    context
        ..mediaPath = <Media>[]
        ..mediaBlocks = <Media>[];

    if (value != null)
        value = value.eval(context);
    if (rules != null) {
      // assuming that there is only one rule at this point - that is how parser constructs the rule
      rules = <Ruleset>[rules[0].eval(context)];
      rules[0].root = true;
    }
    // restore media bubbling information
    context
        ..mediaPath = mediaPathBackup
        ..mediaBlocks = mediaBlocksBackup;

    return new AtRule(name, value, rules, index, currentFileInfo, debugInfo,
        visibilityInfo: visibilityInfo(),
        //isReferenced: isReferenced,
        isRooted: isRooted);

//3.0.0 20160714
// AtRule.prototype.eval = function (context) {
//     var mediaPathBackup, mediaBlocksBackup, value = this.value, rules = this.rules;
//
//     //media stored inside other atrule should not bubble over it
//     //backpup media bubbling information
//     mediaPathBackup = context.mediaPath;
//     mediaBlocksBackup = context.mediaBlocks;
//     //deleted media bubbling information
//     context.mediaPath = [];
//     context.mediaBlocks = [];
//
//     if (value) {
//         value = value.eval(context);
//     }
//     if (rules) {
//         // assuming that there is only one rule at this point - that is how parser constructs the rule
//         rules = [rules[0].eval(context)];
//         rules[0].root = true;
//     }
//     //restore media bubbling information
//     context.mediaPath = mediaPathBackup;
//     context.mediaBlocks = mediaBlocksBackup;
//
//     return new AtRule(this.name, value, rules,
//         this.getIndex(), this.fileInfo(), this.debugInfo, this.isRooted, this.visibilityInfo());
// };
  }

// in VariableMixin - override

  ///
  //untested - no covered by tests
  @override
  Node variable(String name) {
    if (rules?.isNotEmpty ?? false)
        return rules[0].value(name);
    return null;

//2.8.0 20160702
// AtRule.prototype.variable = function (name) {
//     if (this.rules) {
//         // assuming that there is only one rule at this point - that is how parser constructs the rule
//         return Ruleset.prototype.variable.call(this.rules[0], name);
//     }
// };
  }

  ///
  //untested - no covered by tests
  // self type?
  @override
  List<MixinFound> find(Selector selector, [dynamic self, Function filter]) {
    if (rules?.isNotEmpty ?? false)
        // assuming that there is only one rule at this point - that is how parser constructs the rule
        return rules[0].find(selector, self, filter);
    return null;

//2.8.0 20160702
// AtRule.prototype.find = function () {
//     if (this.rules) {
//         // assuming that there is only one rule at this point - that is how parser constructs the rule
//         return Ruleset.prototype.find.apply(this.rules[0], arguments);
//     }
// };
  }

  ///
  //untested
  @override
  List<Node> rulesets() {
    if (rules?.isNotEmpty ?? false)
        // assuming that there is only one rule at this point - that is how parser constructs the rule
        return rules[0].rulesets();
    return null;

//2.8.0 20160702
// AtRule.prototype.rulesets = function () {
//     if (this.rules) {
//         // assuming that there is only one rule at this point - that is how parser constructs the rule
//         return Ruleset.prototype.rulesets.apply(this.rules[0]);
//     }
// };
  }

//2.8.0 20160702
// AtRule.prototype.outputRuleset = function (context, output, rules) {
//     var ruleCnt = rules.length, i;
//     context.tabLevel = (context.tabLevel | 0) + 1;
//
//     // Compressed
//     if (context.compress) {
//         output.add('{');
//         for (i = 0; i < ruleCnt; i++) {
//             rules[i].genCSS(context, output);
//         }
//         output.add('}');
//         context.tabLevel--;
//         return;
//     }
//
//     // Non-compressed
//     var tabSetStr = '\n' + Array(context.tabLevel).join("  "), tabRuleStr = tabSetStr + "  ";
//     if (!ruleCnt) {
//         output.add(" {" + tabSetStr + '}');
//     } else {
//         output.add(" {" + tabRuleStr);
//         rules[0].genCSS(context, output);
//         for (i = 1; i < ruleCnt; i++) {
//             output.add(tabRuleStr);
//             rules[i].genCSS(context, output);
//         }
//         output.add(tabSetStr + '}');
//     }
//
//     context.tabLevel--;
// };
}
