// source: less/tree/ruleset.js 2.5.0

part of tree.less;

class Ruleset extends Node with VariableMixin implements GetIsReferencedNode, MakeImportantNode, MarkReferencedNode, MatchConditionNode {
  List<Selector> selectors;

  /// THE TREE
  List<Node> rules;
  bool strictImports;

  bool allowImports = false;
  bool extendOnEveryPath = false; // used in ExtendFinderVisitor
  bool firstRoot = false;
  bool keepBreaks = false; // for clean-css keep '\n'
  bool isReferenced = false;
  bool isRuleset = true;
  bool isRulesetLike() => true;
  bool multiMedia = false;
  Node originalRuleset;

  /// The paths are [[Selector]]
  List<List<Selector>> paths;

  bool root = false;

  final String type = 'Ruleset';

  Ruleset(this.selectors, this.rules, [this.strictImports = false]);

  ///
  void accept(Visitor visitor){
    if (paths != null) {
      visitor.visitArray(paths, true);
    } else if (selectors != null) {
      selectors = visitor.visitArray(selectors);
    }

    if (isNotEmpty(rules)) rules = visitor.visitArray(rules);

//2.3.1
//  Ruleset.prototype.accept = function (visitor) {
//      if (this.paths) {
//          visitor.visitArray(this.paths, true);
//      } else if (this.selectors) {
//          this.selectors = visitor.visitArray(this.selectors);
//      }
//      if (this.rules && this.rules.length) {
//          this.rules = visitor.visitArray(this.rules);
//      }
//  };
  }

  ///
  eval(Contexts context) {
    List<Selector> thisSelectors = this.selectors;
    List<Selector> selectors;
    int selCnt;
    Selector selector;
    int i;
    var ruleEvaluated; //Node or List

    DefaultFunc defaultFunc;
    if (context.defaultFunc == null) {
      context.defaultFunc = defaultFunc = new DefaultFunc();
    } else {
      defaultFunc = context.defaultFunc;
    }

    bool hasOnePassingSelector = false;

    // selector such as body, h1, ...
    if (thisSelectors != null && (selCnt = thisSelectors.length) > 0) {
      selectors = [];
      defaultFunc.error(new LessError(
        type: 'Syntax',
        message: 'it is currently only allowed in parametric mixin guards,',
        context: context
      ));
      for (i = 0; i < selCnt; i++) {
        selector = thisSelectors[i].eval(context);
        selectors.add(selector);
        if (selector.evaldCondition) hasOnePassingSelector = true;
      }
      defaultFunc.reset();
    } else {
      hasOnePassingSelector = true;
    }

    List<Node> rules = (this.rules != null)? this.rules.sublist(0) : null; //clone
    Ruleset ruleset = new Ruleset(selectors, rules, strictImports);
    Node rule;
    Node subRule;

    ruleset.originalRuleset = this;
    ruleset.id = id;
    ruleset.root = root;
    ruleset.firstRoot = firstRoot;
    ruleset.allowImports = allowImports;

    if (debugInfo != null) ruleset.debugInfo = debugInfo;
    if (!hasOnePassingSelector) rules.length = 0;

    // inherit a function registry from the frames stack when possible; (in js from the top)
    FunctionRegistry parentFR = FunctionRegistry.foundInherit(context.frames);
    ruleset.functionRegistry = new FunctionRegistry.inherit(parentFR);

    // push the current ruleset to the frames stack
    List ctxFrames = context.frames;
    ctxFrames.insert(0, ruleset);

    // currrent selectors
    List ctxSelectors = context.selectors;
    if (ctxSelectors == null) context.selectors = ctxSelectors = [];
    ctxSelectors.insert(0, this.selectors);

    // Evaluate imports
    if (ruleset.root || ruleset.allowImports || !isTrue(ruleset.strictImports)) ruleset.evalImports(context);

    // Store the frames around mixin definitions,
    // so they can be evaluated like closures when the time comes.
    List<Node> rsRules = ruleset.rules;
    int rsRuleCnt = rsRules != null ? rsRules.length : 0;
    for (i = 0; i < rsRuleCnt; i++) {
      if (rsRules[i].evalFirst) rsRules[i] = rsRules[i].eval(context);
    }

    int mediaBlockCount = context.mediaBlocks != null ? context.mediaBlocks.length : 0;

    // Evaluate mixin calls.
    for (i = 0; i < rsRuleCnt; i++) {
      if (rsRules[i] is MixinCall) {
        rules = (rsRules[i] as MixinCall).eval(context)..retainWhere((r){
          if (r is Rule && r.variable) {
            // do not pollute the scope if the variable is
            // already there. consider returning false here
            // but we need a way to "return" variable from mixins
            return (ruleset.variable(r.name) == null);
          }
          return true;
        });
        rsRules.replaceRange(i, i+1, rules);
        rsRuleCnt += rules.length - 1;
        i += rules.length -1;
        ruleset.resetCache();
      } else if (rsRules[i] is RulesetCall) {
        rules = (rsRules[i] as RulesetCall).eval(context).rules..retainWhere((r){
          if (r is Rule && r.variable) {
            // do not pollute the scope at all
            return false;
          }
          return true;
        });
        rsRules.replaceRange(i, i+1, rules);
        rsRuleCnt += rules.length - 1;
        i += rules.length - 1;
        ruleset.resetCache();
      }
    }

    // Evaluate everything else
    for (i = 0; i < rsRules.length; i++) {
      rule = rsRules[i];
      if (!rule.evalFirst) {
        ruleEvaluated = rule.eval(context);
        if (ruleEvaluated is! List) ruleEvaluated = [ruleEvaluated];
        rsRules.replaceRange(i, i+1, ruleEvaluated);
        i += ruleEvaluated.length -1;
      }
    }

    // Evaluate everything else
    for (i = 0; i < rsRules.length; i++) {
      rule = rsRules[i];
      // for rulesets, check if it is a css guard and can be removed
      if (rule is Ruleset && rule.selectors != null && rule.selectors.length == 1) {
        // check if it can be folded in (e.g. & where)
        if (rule.selectors[0].isJustParentSelector()) {
          rsRules.removeAt(i--);

          for (int j = 0; j < rule.rules.length; j++) {
            subRule = rule.rules[j];
            if (!(subRule is Rule) || !(subRule as Rule).variable) {
              rsRules.insert(++i, subRule);
            }
          }
        }
      }
    }

    // Pop the stack
    ctxFrames.removeAt(0);
    ctxSelectors.removeAt(0);

    if (context.mediaBlocks != null) {
      for (i = mediaBlockCount; i < context.mediaBlocks.length; i++) {
        context.mediaBlocks[i].bubbleSelectors(selectors);
      }
    }

    return ruleset;

//2.4.0 20150305
//  Ruleset.prototype.eval = function (context) {
//      var thisSelectors = this.selectors, selectors,
//          selCnt, selector, i, hasOnePassingSelector = false;
//
//      if (thisSelectors && (selCnt = thisSelectors.length)) {
//          selectors = [];
//          defaultFunc.error({
//              type: "Syntax",
//              message: "it is currently only allowed in parametric mixin guards,"
//          });
//          for (i = 0; i < selCnt; i++) {
//              selector = thisSelectors[i].eval(context);
//              selectors.push(selector);
//              if (selector.evaldCondition) {
//                  hasOnePassingSelector = true;
//              }
//          }
//          defaultFunc.reset();
//      } else {
//          hasOnePassingSelector = true;
//      }
//
//      var rules = this.rules ? this.rules.slice(0) : null,
//          ruleset = new Ruleset(selectors, rules, this.strictImports),
//          rule, subRule;
//
//      ruleset.originalRuleset = this;
//      ruleset.root = this.root;
//      ruleset.firstRoot = this.firstRoot;
//      ruleset.allowImports = this.allowImports;
//
//      if (this.debugInfo) {
//          ruleset.debugInfo = this.debugInfo;
//      }
//
//      if (!hasOnePassingSelector) {
//          rules.length = 0;
//      }
//
//      // inherit a function registry from the frames stack when possible;
//      // otherwise from the global registry
//      ruleset.functionRegistry = ((context.frames[0] && context.frames[0].functionRegistry) || globalFunctionRegistry).inherit();
//
//      // push the current ruleset to the frames stack
//      var ctxFrames = context.frames;
//      ctxFrames.unshift(ruleset);
//
//      // currrent selectors
//      var ctxSelectors = context.selectors;
//      if (!ctxSelectors) {
//          context.selectors = ctxSelectors = [];
//      }
//      ctxSelectors.unshift(this.selectors);
//
//      // Evaluate imports
//      if (ruleset.root || ruleset.allowImports || !ruleset.strictImports) {
//          ruleset.evalImports(context);
//      }
//
//      // Store the frames around mixin definitions,
//      // so they can be evaluated like closures when the time comes.
//      var rsRules = ruleset.rules, rsRuleCnt = rsRules ? rsRules.length : 0;
//      for (i = 0; i < rsRuleCnt; i++) {
//          if (rsRules[i].evalFirst) {
//              rsRules[i] = rsRules[i].eval(context);
//          }
//      }
//
//      var mediaBlockCount = (context.mediaBlocks && context.mediaBlocks.length) || 0;
//
//      // Evaluate mixin calls.
//      for (i = 0; i < rsRuleCnt; i++) {
//          if (rsRules[i].type === "MixinCall") {
//              /*jshint loopfunc:true */
//              rules = rsRules[i].eval(context).filter(function(r) {
//                  if ((r instanceof Rule) && r.variable) {
//                      // do not pollute the scope if the variable is
//                      // already there. consider returning false here
//                      // but we need a way to "return" variable from mixins
//                      return !(ruleset.variable(r.name));
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              rsRuleCnt += rules.length - 1;
//              i += rules.length - 1;
//              ruleset.resetCache();
//          } else if (rsRules[i].type === "RulesetCall") {
//              /*jshint loopfunc:true */
//              rules = rsRules[i].eval(context).rules.filter(function(r) {
//                  if ((r instanceof Rule) && r.variable) {
//                      // do not pollute the scope at all
//                      return false;
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              rsRuleCnt += rules.length - 1;
//              i += rules.length - 1;
//              ruleset.resetCache();
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; i < rsRules.length; i++) {
//          rule = rsRules[i];
//          if (!rule.evalFirst) {
//              rsRules[i] = rule = rule.eval ? rule.eval(context) : rule;
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; i < rsRules.length; i++) {
//          rule = rsRules[i];
//          // for rulesets, check if it is a css guard and can be removed
//          if (rule instanceof Ruleset && rule.selectors && rule.selectors.length === 1) {
//              // check if it can be folded in (e.g. & where)
//              if (rule.selectors[0].isJustParentSelector()) {
//                  rsRules.splice(i--, 1);
//
//                  for (var j = 0; j < rule.rules.length; j++) {
//                      subRule = rule.rules[j];
//                      if (!(subRule instanceof Rule) || !subRule.variable) {
//                          rsRules.splice(++i, 0, subRule);
//                      }
//                  }
//              }
//          }
//      }
//
//      // Pop the stack
//      ctxFrames.shift();
//      ctxSelectors.shift();
//
//      if (context.mediaBlocks) {
//          for (i = mediaBlockCount; i < context.mediaBlocks.length; i++) {
//              context.mediaBlocks[i].bubbleSelectors(selectors);
//          }
//      }
//
//      return ruleset;
//  };
  }

  ///
  /// Analyze the rules for @import, loading the new nodes
  ///
  void evalImports(Contexts context) {
    List<Node> rules = this.rules;
    List<Node> importRules;
    var evalImport;

    if (rules == null) return;

    for (int i = 0; i < rules.length; i++) {
      if (rules[i] is Import) {
        evalImport = rules[i].eval(context);
        importRules = (evalImport is List) ? evalImport : [evalImport];
        rules.replaceRange(i, i+1, importRules);
        i += importRules.length - 1;
        resetCache();
      }
    }

//2.3.1
//  Ruleset.prototype.evalImports = function(context) {
//      var rules = this.rules, i, importRules;
//      if (!rules) { return; }
//
//      for (i = 0; i < rules.length; i++) {
//          if (rules[i].type === "Import") {
//              importRules = rules[i].eval(context);
//              if (importRules && importRules.length) {
//                  rules.splice.apply(rules, [i, 1].concat(importRules));
//                  i+= importRules.length - 1;
//              } else {
//                  rules.splice(i, 1, importRules);
//              }
//              this.resetCache();
//          }
//      }
//  };
  }

  ///
  Ruleset makeImportant(){
    Ruleset result = new Ruleset(selectors, rules.map((r){
      if (r is MakeImportantNode) {
        return r.makeImportant();
      } else {
        return r;
      }
    }).toList(), strictImports);

    return result;

//2.4.0
//  Ruleset.prototype.makeImportant = function() {
//      var result = new Ruleset(this.selectors, this.rules.map(function (r) {
//          if (r.makeImportant) {
//              return r.makeImportant();
//          } else {
//              return r;
//          }
//      }), this.strictImports);
//
//      return result;
//  };
  }

  ///
  bool matchArgs(List<MixinArgs> args, Contexts context) => (args == null || args.isEmpty);

//2.3.1
//  Ruleset.prototype.matchArgs = function (args) {
//      return !args || args.length === 0;
//  };

  //--- MatchConditionNode

  ///
  /// lets you call a css selector with a guard
  ///
  bool matchCondition(List<MixinArgs> args, Contexts context) {
    Selector lastSelector = selectors.last;
    if (!lastSelector.evaldCondition) return false;
    if (lastSelector.condition != null &&
        !lastSelector.condition.eval(new Contexts.eval(context, context.frames))) return false;

    return true;

//2.3.1
//  Ruleset.prototype.matchCondition = function (args, context) {
//      var lastSelector = this.selectors[this.selectors.length - 1];
//      if (!lastSelector.evaldCondition) {
//          return false;
//      }
//      if (lastSelector.condition &&
//          !lastSelector.condition.eval(
//              new contexts.Eval(context,
//                  context.frames))) {
//          return false;
//      }
//      return true;
//  };
  }


  ///
  /// Inserts the [rule] as the first elements of this.rules
  ///
  void prependRule(Node rule) {
    List<Node> rules = this.rules;
    if (rules != null) {
      rules.insert(0, rule);
    } else {
      this.rules = [ rule ];
    }

//2.3.1
//  Ruleset.prototype.prependRule = function (rule) {
//      var rules = this.rules;
//      if (rules) { rules.unshift(rule); } else { this.rules = [ rule ]; }
//  };
  }

  bool isCompress(Contexts context) => context.compress || cleanCss;

  ///
  void genCSS(Contexts context, Output output) {
    int i;
    int j;
    List<Node> charsetRuleNodes = [];
    List<Node> ruleNodes = [];

    Node rule;
    List<Node> path;

    if (firstRoot) context.tabLevel = 0;
    if (!root) context.tabLevel++;
    String tabRuleStr = isCompress(context) ? '' : '  ' * (context.tabLevel);
    String tabSetStr = isCompress(context) ? '' : '  ' * (context.tabLevel - 1);
    String sep;

    bool isRulesetLikeNode(Node rule) {
      // if it has nested rules, then it should be treated like a ruleset
      // medias and comments do not have nested rules, but should be treated like rulesets anyway
      // some directives and anonymous nodes are ruleset like, others are not
      return rule.isRulesetLike();
    }

    int charsetNodeIndex = 0;
    int importNodeIndex = 0;
    for (i = 0; i < rules.length; i ++) {
      rule = rules[i];
      if (rule is Comment) {
        if (importNodeIndex == i) importNodeIndex++;
        ruleNodes.add(rule);
      } else if (rule.isCharset()) {
        ruleNodes.insert(charsetNodeIndex, rule);
        charsetNodeIndex++;
        importNodeIndex++;
      } else if (rule is Import) {
        ruleNodes.insert(importNodeIndex, rule);
        importNodeIndex++;
      } else {
        ruleNodes.add(rule);
      }
    }
    ruleNodes.insertAll(0, charsetRuleNodes);

    // If this is the root node, we don't render
    // a selector, or {}.
    if (!root) {
      if (debugInfo != null) {
        output.add(debugInfo.toOutput(context, tabSetStr));
        output.add(tabSetStr);
      }

      List paths = this.paths;
      int pathCnt = paths.length;
      int pathSubCnt;

      sep = isCompress(context) ? ',' : ',\n${tabSetStr}';

      for (i = 0; i < pathCnt; i++) {
        path = paths[i];
        if ((pathSubCnt = path.length) == 0) continue;
        if (i > 0) output.add(sep);

        context.firstSelector = true;
        path[0].genCSS(context, output);

        context.firstSelector = false;
        for (j = 1; j < pathSubCnt; j++) {
          path[j].genCSS(context, output);
        }
      }

      output.add((isCompress(context) ? '{' : ' {\n') + tabRuleStr);
    }

    // Compile rules and rulesets
    for (i = 0; i < ruleNodes.length; i++) {
      rule = ruleNodes[i];

      if (i + 1 == ruleNodes.length) {
          context.lastRule = true;
      }

      bool currentLastRule = context.lastRule;
      if (isRulesetLikeNode(rule)) context.lastRule = false;

      if (rule is Node) {
        rule.genCSS(context, output);
      } else if (rule.value != null) {
        output.add(rule.value.toString());
      }

      context.lastRule = currentLastRule;
      if (!context.lastRule) {
        if(firstRoot && cleanCss && keepBreaks && output.last != '\n') {
          output.add('\n');
        } else {
          output.add(isCompress(context) ? '' : '\n$tabRuleStr');
        }
      } else {
        context.lastRule = false;
      }
    }

    if (!root) {
      if (cleanCss && keepBreaks) {
        output.add('}\n');
      } else {
        output.add(isCompress(context) ? '}' : '\n$tabSetStr}');
      }
      context.tabLevel--;
    }

    if (!output.isEmpty && !isCompress(context) && firstRoot) output.add('\n');

//2.4.0 20150321
//  Ruleset.prototype.genCSS = function (context, output) {
//      var i, j,
//          charsetRuleNodes = [],
//          ruleNodes = [],
//          debugInfo,     // Line number debugging
//          rule,
//          path;
//
//      context.tabLevel = (context.tabLevel || 0);
//
//      if (!this.root) {
//          context.tabLevel++;
//      }
//
//      var tabRuleStr = context.compress ? '' : Array(context.tabLevel + 1).join("  "),
//          tabSetStr = context.compress ? '' : Array(context.tabLevel).join("  "),
//          sep;
//
//      function isRulesetLikeNode(rule) {
//          // if it has nested rules, then it should be treated like a ruleset
//          // medias and comments do not have nested rules, but should be treated like rulesets anyway
//          // some directives and anonymous nodes are ruleset like, others are not
//          if (typeof rule.isRulesetLike === "boolean") {
//              return rule.isRulesetLike;
//          } else if (typeof rule.isRulesetLike === "function") {
//              return rule.isRulesetLike();
//          }
//
//          //anything else is assumed to be a rule
//          return false;
//      }
//
//      var charsetNodeIndex = 0;
//      var importNodeIndex = 0;
//      for (i = 0; i < this.rules.length; i++) {
//          rule = this.rules[i];
//          if (rule.type === "Comment") {
//              if (importNodeIndex === i) {
//                  importNodeIndex++;
//              }
//              ruleNodes.push(rule);
//          } else if (rule.isCharset && rule.isCharset()) {
//              ruleNodes.splice(charsetNodeIndex, 0, rule);
//              charsetNodeIndex++;
//              importNodeIndex++;
//          } else if (rule.type === "Import") {
//              ruleNodes.splice(importNodeIndex, 0, rule);
//              importNodeIndex++;
//          } else {
//              ruleNodes.push(rule);
//          }
//      }
//      ruleNodes = charsetRuleNodes.concat(ruleNodes);
//
//      // If this is the root node, we don't render
//      // a selector, or {}.
//      if (!this.root) {
//          debugInfo = getDebugInfo(context, this, tabSetStr);
//
//          if (debugInfo) {
//              output.add(debugInfo);
//              output.add(tabSetStr);
//          }
//
//          var paths = this.paths, pathCnt = paths.length,
//              pathSubCnt;
//
//          sep = context.compress ? ',' : (',\n' + tabSetStr);
//
//          for (i = 0; i < pathCnt; i++) {
//              path = paths[i];
//              if (!(pathSubCnt = path.length)) { continue; }
//              if (i > 0) { output.add(sep); }
//
//              context.firstSelector = true;
//              path[0].genCSS(context, output);
//
//              context.firstSelector = false;
//              for (j = 1; j < pathSubCnt; j++) {
//                  path[j].genCSS(context, output);
//              }
//          }
//
//          output.add((context.compress ? '{' : ' {\n') + tabRuleStr);
//      }
//
//      // Compile rules and rulesets
//      for (i = 0; i < ruleNodes.length; i++) {
//          rule = ruleNodes[i];
//
//          if (i + 1 === ruleNodes.length) {
//              context.lastRule = true;
//          }
//
//          var currentLastRule = context.lastRule;
//          if (isRulesetLikeNode(rule)) {
//              context.lastRule = false;
//          }
//
//          if (rule.genCSS) {
//              rule.genCSS(context, output);
//          } else if (rule.value) {
//              output.add(rule.value.toString());
//          }
//
//          context.lastRule = currentLastRule;
//
//          if (!context.lastRule) {
//              output.add(context.compress ? '' : ('\n' + tabRuleStr));
//          } else {
//              context.lastRule = false;
//          }
//      }
//
//      if (!this.root) {
//          output.add((context.compress ? '}' : '\n' + tabSetStr + '}'));
//          context.tabLevel--;
//      }
//
//      if (!output.isEmpty() && !context.compress && this.firstRoot) {
//          output.add('\n');
//      }
//  };
  }

  //--- MarkReferencedNode

  ///
  void markReferenced(){
    if (selectors != null) {
      for (int s = 0; s < selectors.length; s++) {
        selectors[s].markReferenced();
      }
    }

    if (rules != null) {
      for (int s = 0; s < rules.length; s++) {
        if (rules[s] is MarkReferencedNode) {
          (rules[s] as MarkReferencedNode).markReferenced();
        }
      }
    }

//2.3.1
//  Ruleset.prototype.markReferenced = function () {
//      var s;
//      if (this.selectors) {
//          for (s = 0; s < this.selectors.length; s++) {
//              this.selectors[s].markReferenced();
//          }
//      }
//
//      if (this.rules) {
//          for (s = 0; s < this.rules.length; s++) {
//              if (this.rules[s].markReferenced) {
//                  this.rules[s].markReferenced();
//              }
//          }
//      }
//  };
  }

  ///
  bool getIsReferenced() {
    List<Selector> path;
    Selector selector;

    if (paths != null) {
      for (int i = 0; i < paths.length; i++) {
        path = paths[i];
        for (int j = 0; j < path.length; j++) {
          if (path[j] is GetIsReferencedNode && path[j].getIsReferenced()) {
            return true;
          }
        }
      }
    }

    if (selectors != null) {
      for (int i = 0; i < selectors.length; i++) {
        selector = selectors[i];
        if (selector is GetIsReferencedNode && selector.getIsReferenced()) {
          return true;
        }
      }
    }

    return false;

//2.3.1
//  Ruleset.prototype.getIsReferenced = function() {
//      var i, j, path, selector;
//
//      if (this.paths) {
//          for (i = 0; i < this.paths.length; i++) {
//              path = this.paths[i];
//              for (j = 0; j < path.length; j++) {
//                  if (path[j].getIsReferenced && path[j].getIsReferenced()) {
//                      return true;
//                  }
//              }
//          }
//      }
//
//      if (this.selectors) {
//          for (i = 0; i < this.selectors.length; i++) {
//              selector = this.selectors[i];
//              if (selector.getIsReferenced && selector.getIsReferenced()) {
//                  return true;
//              }
//          }
//      }
//      return false;
//  };
  }

  ///
  joinSelectors(List<List<Selector>> paths, List<List<Selector>> context, List<Node> selectors) {
    for (int s = 0; s < selectors.length; s++) {
      joinSelector(paths, context, selectors[s]);
    }

//2.3.1
//  Ruleset.prototype.joinSelectors = function (paths, context, selectors) {
//      for (var s = 0; s < selectors.length; s++) {
//          this.joinSelector(paths, context, selectors[s]);
//      }
//  };
  }

  ///
  joinSelector(List<List<Selector>> paths, List<List<Selector>>context, Selector selector) {
    List<List<Selector>> newPaths = [];
    bool hadParentSelector = replaceParentSelector(newPaths, context, selector);

    if (!hadParentSelector) {
      if (context.isNotEmpty) {
        newPaths = [];
        for (int i = 0; i < context.length; i++) {
          newPaths.add(context[i].sublist(0)..add(selector));
        }
      } else {
        newPaths = [[selector]];
      }
    }

    for (int i = 0; i < newPaths.length; i++) {
      paths.add(newPaths[i]);
    }

//2.3.1
//  Ruleset.prototype.joinSelector = function (paths, context, selector) {
//
//      // joinSelector code follows
//      var i, newPaths, hadParentSelector;
//
//      newPaths = [];
//      hadParentSelector = replaceParentSelector(newPaths, context, selector);
//
//      if (!hadParentSelector) {
//          if (context.length > 0) {
//              newPaths = [];
//              for (i = 0; i < context.length; i++) {
//                  newPaths.push(context[i].concat(selector));
//              }
//          }
//          else {
//              newPaths = [[selector]];
//          }
//      }
//
//      for (i = 0; i < newPaths.length; i++) {
//          paths.push(newPaths[i]);
//      }
//
//  };
  }

  ///
  Paren createParenthesis(List<Node> elementsToPak, Element originalElement) {
    Paren replacementParen;

    if (elementsToPak.length == 0) {
      replacementParen = new Paren(null);
    } else {
      List  insideParent = [];
      for (int j = 0; j < elementsToPak.length; j++) {
        insideParent.add(new Element(null, elementsToPak[j], originalElement.index, originalElement.currentFileInfo));
      }
      replacementParen = new Paren(new Selector(insideParent));
    }
    return replacementParen;

//2.3.1 inside joinSelector
//      function createParenthesis(elementsToPak, originalElement) {
//          var replacementParen, j;
//          if (elementsToPak.length === 0) {
//              replacementParen = new Paren(elementsToPak[0]);
//          } else {
//              var insideParent = [];
//              for (j = 0; j < elementsToPak.length; j++) {
//                  insideParent.push(new Element(null, elementsToPak[j], originalElement.index, originalElement.currentFileInfo));
//              }
//              replacementParen = new Paren(new Selector(insideParent));
//          }
//          return replacementParen;
//      }
  }

  ///
  Selector createSelector(Node containedElement, Element originalElement) {
    Element element = new Element(null, containedElement, originalElement.index, originalElement.currentFileInfo);
    Selector selector = new Selector([element]);
    return selector;

//2.3.1 inside joinSelector
//      function createSelector(containedElement, originalElement) {
//          var element, selector;
//          element = new Element(null, containedElement, originalElement.index, originalElement.currentFileInfo);
//          selector = new Selector([element]);
//          return selector;
//      }
  }

  ///
  /// Replace all parent selectors inside `inSelector` by content of `context` array
  /// resulting selectors are returned inside `paths` array
  /// returns true if `inSelector` contained at least one parent selector
  ///
  bool replaceParentSelector(List<List<Selector>> paths, List<List<Selector>> context, Selector inSelector) {
    //
    // The paths are [[Selector]]
    // The first list is a list of comma separated selectors
    // The inner list is a list of inheritance separated selectors
    // e.g.
    // .a, .b {
    //   .c {
    //   }
    // }
    // == [[.a] [.c]] [[.b] [.c]]
    //

    List<Element> currentElements;
    List<List<Selector>> newSelectors;
    List<List<Selector>> selectorsMultiplied;
    List<Selector> sel;
    Element el;
    bool hadParentSelector = false;
    int length;
    Selector lastSelector;

    Selector findNestedSelector(Element element) {
      if (element.value is String) return null;
      if (element.value is! Paren) return null;

      var maybeSelector = element.value.value;
      if (maybeSelector is! Selector) return null;
      return maybeSelector;
    }

    // the elements from the current selector so far
    currentElements = [];

    // the current list of new selectors to add to the path.
    // We will build it up. We initiate it with one empty selector as we "multiply" the new selectors
    // by the parents
    newSelectors = [ [] ];

    for (int i = 0; i < inSelector.elements.length; i++) {
      el = inSelector.elements[i];
      // non parent reference elements just get added
      if (el.value != '&') {
        Selector nestedSelector = findNestedSelector(el);
        if (nestedSelector != null) {
          // merge the current list of non parent selector elements
          // on to the current list of selectors to add
          mergeElementsOnToSelectors(currentElements, newSelectors);

          List nestedPaths = [];
          bool replaced;
          List replacedNewSelectors = [];

          replaced = replaceParentSelector(nestedPaths, context, nestedSelector);
          hadParentSelector = hadParentSelector || replaced;

          // the nestedPaths array should have only one member - replaceParentSelector does not multiply selectors
          for (int k = 0; k < nestedPaths.length; k++) {
            Selector replacementSelector = createSelector(createParenthesis(nestedPaths[k], el), el);
            addAllReplacementsIntoPath(newSelectors, [replacementSelector], el, inSelector, replacedNewSelectors);
          }
          newSelectors = replacedNewSelectors;
          currentElements = [];
        } else {
          currentElements.add(el);
        }
      } else {
        hadParentSelector = true;

        // the new list of selectors to add
        selectorsMultiplied = [];

        // merge the current list of non parent selector elements
        // on to the current list of selectors to add
        mergeElementsOnToSelectors(currentElements, newSelectors);

        // loop through our current selectors
        for (int j = 0; j < newSelectors.length; j++) {
          sel = newSelectors[j];
          // if we don't have any parent paths, the & might be in a mixin so that it can be used
          // whether there are parents or not
          if (context.length == 0) {
            // the combinator used on el should now be applied to the next element instead so that
            // it is not lost
            if (sel.length > 0) {
              sel.first.elements.add(new Element(el.combinator, '', el.index, el.currentFileInfo));
            }
            selectorsMultiplied.add(sel);
          } else {
            // and the parent selectors
            for (int k = 0; k < context.length; k++) {
              // We need to put the current selectors
              // then join the last selector's elements on to the parents selectors
              var newSelectorPath = addReplacementIntoPath(sel, context[k], el, inSelector);
              // add that to our new set of selectors
              selectorsMultiplied.add(newSelectorPath);
            }
          }
        }

        //
        // our new selectors has been multiplied, so reset the state
        newSelectors = selectorsMultiplied;
        currentElements = [];
      }
    }

    // if we have any elements left over (e.g. .a& .b == .b)
    // add them on to all the current selectors
    mergeElementsOnToSelectors(currentElements, newSelectors);

    for (int i = 0; i < newSelectors.length; i++) {
      length = newSelectors[i].length;
      if (length > 0) {
        paths.add(newSelectors[i]);
        lastSelector = newSelectors[i].last;
        newSelectors[i][length - 1] = lastSelector.createDerived(lastSelector.elements, inSelector.extendList);
      }
    }

    return hadParentSelector;

//2.4.0
//  function replaceParentSelector(paths, context, inSelector) {
//      // The paths are [[Selector]]
//      // The first list is a list of comma separated selectors
//      // The inner list is a list of inheritance separated selectors
//      // e.g.
//      // .a, .b {
//      //   .c {
//      //   }
//      // }
//      // == [[.a] [.c]] [[.b] [.c]]
//      //
//      var i, j, k, currentElements, newSelectors, selectorsMultiplied, sel, el, hadParentSelector = false, length, lastSelector;
//      function findNestedSelector(element) {
//          var maybeSelector;
//          if (element.value.type !== 'Paren') {
//              return null;
//          }
//
//          maybeSelector = element.value.value;
//          if (maybeSelector.type !== 'Selector') {
//              return null;
//          }
//
//          return maybeSelector;
//      }
//
//      // the elements from the current selector so far
//      currentElements = [];
//      // the current list of new selectors to add to the path.
//      // We will build it up. We initiate it with one empty selector as we "multiply" the new selectors
//      // by the parents
//      newSelectors = [
//          []
//      ];
//
//      for (i = 0; i < inSelector.elements.length; i++) {
//          el = inSelector.elements[i];
//          // non parent reference elements just get added
//          if (el.value !== "&") {
//              var nestedSelector = findNestedSelector(el);
//              if (nestedSelector != null) {
//                  // merge the current list of non parent selector elements
//                  // on to the current list of selectors to add
//                  mergeElementsOnToSelectors(currentElements, newSelectors);
//
//                  var nestedPaths = [], replaced, replacedNewSelectors = [];
//                  replaced = replaceParentSelector(nestedPaths, context, nestedSelector);
//                  hadParentSelector = hadParentSelector || replaced;
//                  //the nestedPaths array should have only one member - replaceParentSelector does not multiply selectors
//                  for (k = 0; k < nestedPaths.length; k++) {
//                      var replacementSelector = createSelector(createParenthesis(nestedPaths[k], el), el);
//                      addAllReplacementsIntoPath(newSelectors, [replacementSelector], el, inSelector, replacedNewSelectors);
//                  }
//                  newSelectors = replacedNewSelectors;
//                  currentElements = [];
//
//              } else {
//                  currentElements.push(el);
//              }
//
//          } else {
//              hadParentSelector = true;
//              // the new list of selectors to add
//              selectorsMultiplied = [];
//
//              // merge the current list of non parent selector elements
//              // on to the current list of selectors to add
//              mergeElementsOnToSelectors(currentElements, newSelectors);
//
//              // loop through our current selectors
//              for (j = 0; j < newSelectors.length; j++) {
//                  sel = newSelectors[j];
//                  // if we don't have any parent paths, the & might be in a mixin so that it can be used
//                  // whether there are parents or not
//                  if (context.length === 0) {
//                      // the combinator used on el should now be applied to the next element instead so that
//                      // it is not lost
//                      if (sel.length > 0) {
//                          sel[0].elements.push(new Element(el.combinator, '', el.index, el.currentFileInfo));
//                      }
//                      selectorsMultiplied.push(sel);
//                  }
//                  else {
//                      // and the parent selectors
//                      for (k = 0; k < context.length; k++) {
//                          // We need to put the current selectors
//                          // then join the last selector's elements on to the parents selectors
//                          var newSelectorPath = addReplacementIntoPath(sel, context[k], el, inSelector);
//                          // add that to our new set of selectors
//                          selectorsMultiplied.push(newSelectorPath);
//                      }
//                  }
//              }
//
//              // our new selectors has been multiplied, so reset the state
//              newSelectors = selectorsMultiplied;
//              currentElements = [];
//          }
//      }
//
//      // if we have any elements left over (e.g. .a& .b == .b)
//      // add them on to all the current selectors
//      mergeElementsOnToSelectors(currentElements, newSelectors);
//
//      for (i = 0; i < newSelectors.length; i++) {
//          length = newSelectors[i].length;
//          if (length > 0) {
//              paths.push(newSelectors[i]);
//              lastSelector = newSelectors[i][length - 1];
//              newSelectors[i][length - 1] = lastSelector.createDerived(lastSelector.elements, inSelector.extendList);
//          }
//      }
//
//      return hadParentSelector;
//  }
  }

  ///
  /// joins selector path from `beginningPath` with selector path in `addPath`
  /// `replacedElement` contains element that is being replaced by `addPath`
  /// returns concatenated path
  ///
  addReplacementIntoPath(List<Selector> beginningPath, List<Selector> addPath, Element replacedElement, Selector originalSelector) {
    List<Selector> newSelectorPath;
    Selector lastSelector;
    Selector newJoinedSelector;

    // our new selector path
    newSelectorPath = [];

    // construct the joined selector - if & is the first thing this will be empty,
    // if not newJoinedSelector will be the last set of elements in the selector
    if (beginningPath.isNotEmpty) {
      newSelectorPath = beginningPath.sublist(0);
      lastSelector = newSelectorPath.removeLast();
      newJoinedSelector = originalSelector.createDerived(lastSelector.elements.sublist(0));
    } else {
      newJoinedSelector = originalSelector.createDerived([]);
    }

    if (addPath.isNotEmpty) {
      // /deep/ is a combinator that is valid without anything in front of it
      // so if the & does not have a combinator that is "" or " " then
      // and there is a combinator on the parent, then grab that.
      // this also allows + a { & .b { .a & { ... though not sure why you would want to do that
      Combinator combinator = replacedElement.combinator;
      Element parentEl = addPath.first.elements.first;
      if (isTrue(combinator.emptyOrWhitespace) && !isTrue(parentEl.combinator.emptyOrWhitespace)) {
        combinator = parentEl.combinator;
      }
      // join the elements so far with the first part of the parent
      newJoinedSelector.elements.add(new Element(combinator, parentEl.value, replacedElement.index, replacedElement.currentFileInfo));
      newJoinedSelector.elements.addAll(addPath.first.elements.sublist(1));
    }

    // now add the joined selector - but only if it is not empty
    if (newJoinedSelector.elements.isNotEmpty) {
      newSelectorPath.add(newJoinedSelector);
    }

    // put together the parent selectors after the join (e.g. the rest of the parent)
    if (addPath.length > 1) {
      newSelectorPath.addAll(addPath.sublist(1));
    }

    return newSelectorPath;

//2.3.1 inside joinSelector
//      // joins selector path from `beginningPath` with selector path in `addPath`
//      // `replacedElement` contains element that is being replaced by `addPath`
//      // returns concatenated path
//      function addReplacementIntoPath(beginningPath, addPath, replacedElement, originalSelector) {
//          var newSelectorPath, lastSelector, newJoinedSelector;
//          // our new selector path
//          newSelectorPath = [];
//
//          //construct the joined selector - if & is the first thing this will be empty,
//          // if not newJoinedSelector will be the last set of elements in the selector
//          if (beginningPath.length > 0) {
//              newSelectorPath = beginningPath.slice(0);
//              lastSelector = newSelectorPath.pop();
//              newJoinedSelector = originalSelector.createDerived(lastSelector.elements.slice(0));
//          }
//          else {
//              newJoinedSelector = originalSelector.createDerived([]);
//          }
//
//          if (addPath.length > 0) {
//              // /deep/ is a combinator that is valid without anything in front of it
//              // so if the & does not have a combinator that is "" or " " then
//              // and there is a combinator on the parent, then grab that.
//              // this also allows + a { & .b { .a & { ... though not sure why you would want to do that
//              var combinator = replacedElement.combinator, parentEl = addPath[0].elements[0];
//              if (combinator.emptyOrWhitespace && !parentEl.combinator.emptyOrWhitespace) {
//                  combinator = parentEl.combinator;
//              }
//              // join the elements so far with the first part of the parent
//              newJoinedSelector.elements.push(new Element(combinator, parentEl.value, replacedElement.index, replacedElement.currentFileInfo));
//              newJoinedSelector.elements = newJoinedSelector.elements.concat(addPath[0].elements.slice(1));
//          }
//
//          // now add the joined selector - but only if it is not empty
//          if (newJoinedSelector.elements.length !== 0) {
//              newSelectorPath.push(newJoinedSelector);
//          }
//
//          //put together the parent selectors after the join (e.g. the rest of the parent)
//          if (addPath.length > 1) {
//              newSelectorPath = newSelectorPath.concat(addPath.slice(1));
//          }
//          return newSelectorPath;
//      }
  }

  ///
  /// joins selector path from `beginningPath` with every selector path in `addPaths` array
  /// `replacedElement` contains element that is being replaced by `addPath`
  /// returns array with all concatenated paths
  ///
  List addAllReplacementsIntoPath( List beginningPath, addPaths, replacedElement, originalSelector, List result) {
    for (int j = 0; j < beginningPath.length; j++) {
      List<Selector> newSelectorPath = addReplacementIntoPath(beginningPath[j], addPaths, replacedElement, originalSelector);
      result.add(newSelectorPath);
    }
    return result;

//2.3.1 inside joinSelector
//      // joins selector path from `beginningPath` with every selector path in `addPaths` array
//      // `replacedElement` contains element that is being replaced by `addPath`
//      // returns array with all concatenated paths
//      function addAllReplacementsIntoPath( beginningPath, addPaths, replacedElement, originalSelector, result) {
//          var j;
//          for (j = 0; j < beginningPath.length; j++) {
//              var newSelectorPath = addReplacementIntoPath(beginningPath[j], addPaths, replacedElement, originalSelector);
//              result.push(newSelectorPath);
//          }
//          return result;
//      }
  }

  ///
  void mergeElementsOnToSelectors(List<Element> elements, List<List<Selector>> selectors) {
    List<Selector> sel;

    if (elements.isEmpty) return;

    if (selectors.isEmpty) {
      selectors.add([new Selector(elements)]);
      return;
    }

    for (int i = 0; i < selectors.length; i++) {
      sel = selectors[i];

      // if the previous thing in sel is a parent this needs to join on to it
      if (sel.isNotEmpty) {
        sel[sel.length - 1] = sel.last.createDerived(sel.last.elements.sublist(0)..addAll(elements));
      } else {
        sel.add(new Selector(elements));
      }
    }

//2.3.1 inside joinSelector
//      function mergeElementsOnToSelectors(elements, selectors) {
//          var i, sel;
//
//          if (elements.length === 0) {
//              return ;
//          }
//          if (selectors.length === 0) {
//              selectors.push([ new Selector(elements) ]);
//              return;
//          }
//
//          for (i = 0; i < selectors.length; i++) {
//              sel = selectors[i];
//
//              // if the previous thing in sel is a parent this needs to join on to it
//              if (sel.length > 0) {
//                  sel[sel.length - 1] = sel[sel.length - 1].createDerived(sel[sel.length - 1].elements.concat(elements));
//              }
//              else {
//                  sel.push(new Selector(elements));
//              }
//          }
//      }
  }

  // -----------------------------------------------------------------------

}

//-----------------------------------------------------------------------
// Ruleset and MixinDefinition shared code
//-----------------------------------------------------------------------

//2.4.0+
//FIXME: following three functions are done like inside media
class VariableMixin {
  List<Node> rules;

  FunctionRegistry functionRegistry;

  Map _lookups = {};
  Node paren;
  var _rulesets;

  /// List of Variable Nodes, by @name
  Map<String, Node> _variables;

  ///
  void resetCache(){
    if (functionRegistry != null) functionRegistry.resetCache();
    _rulesets = null;
    _variables = null;
    _lookups = {};

//2.4.0 20150306
//  Ruleset.prototype.resetCache = function () {
//      this._rulesets = null;
//      this._variables = null;
//      this._lookups = {};
//  };
  }

  ///
  /// Returns the variables list if exist, else creates it.
  ///
  Map<String, Node> variables(){
    if (_variables == null) {
      _variables = (rules == null) ? {} : rules.fold({}, (hash, r){
        if (r is Rule && r.variable) {
          hash[r.name] = r;
        }

        // when evaluating variables in an import statement, imports have not been eval'd
        // so we need to go inside import statements.
        // guard against root being a string (in the case of inlined less)
        if (r is Import && r.root != null && r.root is VariableMixin) {
          Map<String, Node> vars = r.root.variables();
          for (String name in vars.keys) {
            if (vars.containsKey(name)) hash[name] = vars[name];
          }
        }

        return hash;
      });
    }
    return _variables;

//2.3.1
//Ruleset.prototype.variables = function () {
//  if (!this._variables) {
//      this._variables = !this.rules ? {} : this.rules.reduce(function (hash, r) {
//          if (r instanceof Rule && r.variable === true) {
//              hash[r.name] = r;
//          }
//          // when evaluating variables in an import statement, imports have not been eval'd
//          // so we need to go inside import statements.
//          // guard against root being a string (in the case of inlined less)
//          if (r.type === "Import" && r.root && r.root.variables) {
//                var vars = r.root.variables();
//                for(var name in vars) {
//                    if (vars.hasOwnProperty(name)) {
//                        hash[name] = vars[name];
//                    }
//                }
//            }
//            return hash;
//        }, {});
//    }
//    return this._variables;
//};
  }

  ///
  /// Returns the Variable Node (@variable = value).
  ///
  Node variable(String name) => variables()[name];

//2.3.1
//  Ruleset.prototype.variable = function (name) {
//      return this.variables()[name];
//  };

  ///
  /// Returns a List of MixinDefinition or Ruleset contained in this.rules
  ///
  List<Node> rulesets(){
    if (this.rules == null) return null;

    List<Node> filtRules = [];
    List<Node> rules = this.rules;
    Node rule;

    for (int i = 0; i < rules.length; i++) {
      rule = rules[i];
      if (rule.isRuleset) filtRules.add(rule);
    }

    return filtRules;

//2.3.1
//  Ruleset.prototype.rulesets = function () {
//      if (!this.rules) { return null; }
//
//      var filtRules = [], rules = this.rules, cnt = rules.length,
//          i, rule;
//
//      for (i = 0; i < cnt; i++) {
//          rule = rules[i];
//          if (rule.isRuleset) {
//              filtRules.push(rule);
//          }
//      }
//
//      return filtRules;
//  };
  }

  ///
  /// Returns the List of Rules that matchs [selector].
  /// The results are cached.
  ///
  /// Function: bool filter(rule)
  ///
  List<MixinFound> find (Selector selector, [self, Function filter]) {
    if (self == null) self = this;
    List<MixinFound> rules = [];
    int match; // Selectors matchs number. 0 not match
    List<MixinFound> foundMixins;
    String key = selector.toCSS(null); // ' selector'

    if (_lookups.containsKey(key)) return _lookups[key];

    this.rulesets().forEach((Node rule) {//List of MixinDefinition and Ruleset
      if (rule != self) {
        for (int j = 0; j < rule.selectors.length; j++) {
          match = selector.match(rule.selectors[j]);
          if (match > 0) {
            if (selector.elements.length > match) {
              if (filter == null || filter(rule)) {
                foundMixins = (rule as VariableMixin).find(new Selector(selector.elements.sublist(match)), self, filter);
                for (int i = 0; i < foundMixins.length; i++) {
                  foundMixins[i].path.add(rule); //2.3.1 MixinDefinition, Ruleset
                }
                rules.addAll(foundMixins);
              }
            } else {
              rules.add(new MixinFound(rule, []));
            }
            break;
          }
        }
      }
    });
    _lookups[key] = rules;
    return rules;

//2.3.1
//  Ruleset.prototype.find = function (selector, self, filter) {
//      self = self || this;
//      var rules = [], match, foundMixins,
//          key = selector.toCSS();
//
//      if (key in this._lookups) { return this._lookups[key]; }
//
//      this.rulesets().forEach(function (rule) {
//          if (rule !== self) {
//              for (var j = 0; j < rule.selectors.length; j++) {
//                  match = selector.match(rule.selectors[j]);
//                  if (match) {
//                      if (selector.elements.length > match) {
//                        if (!filter || filter(rule)) {
//                          foundMixins = rule.find(new Selector(selector.elements.slice(match)), self, filter);
//                          for (var i = 0; i < foundMixins.length; ++i) {
//                            foundMixins[i].path.push(rule);
//                          }
//                          Array.prototype.push.apply(rules, foundMixins);
//                        }
//                      } else {
//                          rules.push({ rule: rule, path: []});
//                      }
//                      break;
//                  }
//              }
//          }
//      });
//      this._lookups[key] = rules;
//      return rules;
//  };
  }
}

//-----------------------------------------

class MixinFound {
  Node rule;
  List<Node> path;

  MixinFound(this.rule, this.path);
}