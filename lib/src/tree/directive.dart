//source: less/tree/directive.js 2.6.1 20160202

part of tree.less;

///
class Directive extends DirectiveBase {
  @override final String    type = 'Directive';
  @override covariant Node  value;

  ///
  Directive(String name, Node this.value, dynamic rules, int index,
      FileInfo currentFileInfo, DebugInfo debugInfo,
      {VisibilityInfo visibilityInfo, bool isRooted = false})
      : super(
            name: name,
            index: index,
            currentFileInfo: currentFileInfo,
            debugInfo: debugInfo,
            isRooted: isRooted,
            visibilityInfo: visibilityInfo) {

    if (rules != null) {
      if (rules is List<Ruleset>) {
        this.rules = rules;
      } else {
        this.rules = <Ruleset>[rules as Ruleset];
        this.rules[0].selectors = new Selector(<Element>[],
            index: this.index,
            currentFileInfo: currentFileInfo)
            .createEmptySelectors();
      }
      this.rules.forEach((Ruleset rule) {
        rule.allowImports = true;
      });
    }

    allowRoot = true;

//2.6.1 20160202
// var Directive = function (name, value, rules, index, currentFileInfo, debugInfo, isRooted, visibilityInfo) {
//     var i;
//
//     this.name  = name;
//     this.value = value;
//     if (rules) {
//         if (Array.isArray(rules)) {
//             this.rules = rules;
//         } else {
//             this.rules = [rules];
//             this.rules[0].selectors = (new Selector([], null, null, this.index, currentFileInfo)).createEmptySelectors();
//         }
//         for (i = 0; i < this.rules.length; i++) {
//             this.rules[i].allowImports = true;
//         }
//     }
//     this.index = index;
//     this.currentFileInfo = currentFileInfo;
//     this.debugInfo = debugInfo;
//     this.isRooted = isRooted || false;
//     this.copyVisibilityInfo(visibilityInfo);
//     this.allowRoot = true;
// };
  }

  @override
  String toString() => name;
}

///
/// Base class for Directive and Media
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

//2.4.0+
//  Directive.prototype.accept = function (visitor) {
//      var value = this.value, rules = this.rules;
//      if (rules) {
//          this.rules = visitor.visitArray(rules);
//      }
//      if (value) {
//          this.value = visitor.visit(value);
//      }
//  };
  }

  ///
  @override
  bool isRulesetLike() => (rules != null) || !isCharset();

//2.3.1
//  Directive.prototype.isRulesetLike = function() {
//      return this.rules || !this.isCharset();
//  };

  ///
  @override
  bool isCharset() => '@charset' == name;

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

//2.4.0+1
//  Directive.prototype.genCSS = function (context, output) {
//      var value = this.value, rules = this.rules;
//      output.add(this.name, this.currentFileInfo, this.index);
//      if (value) {
//          output.add(' ');
//          value.genCSS(context, output);
//      }
//      if (rules) {
//          this.outputRuleset(context, output, rules);
//      } else {
//          output.add(';');
//      }
//  };
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

    return new Directive(name, value, rules, index, currentFileInfo, debugInfo,
        visibilityInfo: visibilityInfo(),
        //isReferenced: isReferenced,
        isRooted: isRooted);

//2.5.3 20151120
// Directive.prototype.eval = function (context) {
//     var mediaPathBackup, mediaBlocksBackup, value = this.value, rules = this.rules;
//
//     //media stored inside other directive should not bubble over it
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
//     return new Directive(this.name, value, rules,
//         this.index, this.currentFileInfo, this.debugInfo, this.isRooted, this.visibilityInfo());
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

//2.4.0+
//  Directive.prototype.variable = function (name) {
//      if (this.rules) {
//          // assuming that there is only one rule at this point - that is how parser constructs the rule
//          return Ruleset.prototype.variable.call(this.rules[0], name);
//      }
//  };
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

//2.4.0+
//  Directive.prototype.find = function () {
//      if (this.rules) {
//          // assuming that there is only one rule at this point - that is how parser constructs the rule
//          return Ruleset.prototype.find.apply(this.rules[0], arguments);
//      }
//  };
  }

  ///
  //untested
  @override
  List<Node> rulesets() {
    if (rules?.isNotEmpty ?? false)
        // assuming that there is only one rule at this point - that is how parser constructs the rule
        return rules[0].rulesets();
    return null;

//2.4.0+
//  Directive.prototype.rulesets = function () {
//      if (this.rules) {
//          // assuming that there is only one rule at this point - that is how parser constructs the rule
//          return Ruleset.prototype.rulesets.apply(this.rules[0]);
//      }
//  };
  }
}
