// source: less/tree/ruleset.js 1.7.5

part of tree.less;

class Ruleset extends Node with VariableMixin implements EvalNode, MakeImportantNode, MarkReferencedNode, MatchConditionNode, ToCSSNode {
  List<Selector> selectors;

  /// THE TREE
  List<Node> rules;
  bool strictImports;

  bool allowImports = false;
  bool extendOnEveryPath = false; // used in ExtendFinderVisitor
  bool firstRoot = false;
  bool isReferenced = false;
  bool multiMedia = false;
  Node originalRuleset;

  /// The paths are [[Selector]]
  List<List<Selector>> paths;

  bool root = false;

  final String type = 'Ruleset';

  Ruleset(this.selectors, this.rules, [this.strictImports = false]);

  ///
  void accept(Visitor visitor){
    if (this.paths != null) {
      visitor.visitArray(this.paths, true);
    } else if (this.selectors != null) {
      this.selectors = visitor.visitArray(this.selectors);
    }

    if (isNotEmpty(this.rules)) {
      this.rules = visitor.visitArray(this.rules);
    }
  }

  // ********************************* entry point ***********************************

  ///
  eval(Env env) {
    List<Selector> thisSelectors = this.selectors;
    List<Selector> selectors;
    int selCnt;
    Selector selector;
    int i;
    var ruleEvaluated; //Node or List

    DefaultFunc defaultFunc;
    if (env.defaultFunc == null) {
      env.defaultFunc = defaultFunc = new DefaultFunc();
    } else {
      defaultFunc = env.defaultFunc;
    }

    bool hasOnePassingSelector = false;

    // selector such as body, h1, ...
    if (thisSelectors != null && (selCnt = thisSelectors.length) > 0) {
      selectors = [];
      defaultFunc.error(new LessError(
        type: 'Syntax',
        message: 'it is currently only allowed in parametric mixin guards,',
        env: env
      ));
      for (i = 0; i < selCnt; i++) {
        selector = thisSelectors[i].eval(env);
        selectors.add(selector);
        if (selector.evaldCondition) hasOnePassingSelector = true;
      }
      defaultFunc.reset();
    } else {
      hasOnePassingSelector = true;
    }

    List<Node> rules = (this.rules != null)? this.rules.sublist(0) : null; //clone
    Ruleset ruleset = new Ruleset(selectors, rules, this.strictImports);
    Node rule;
    Node subRule;

    ruleset.originalRuleset = this;
    ruleset.id = this.id;
    ruleset.root = this.root;
    ruleset.firstRoot = this.firstRoot;
    ruleset.allowImports = this.allowImports;

    if (this.debugInfo != null) ruleset.debugInfo = this.debugInfo;
    if (!hasOnePassingSelector) rules.length = 0;

    // push the current ruleset to the frames stack
    List envFrames = env.frames;
    envFrames.insert(0, ruleset);

    // currrent selectors
    List envSelectors = env.selectors;
    if (envSelectors == null) env.selectors = envSelectors = [];
    envSelectors.insert(0, this.selectors);

    // Evaluate imports
    if (ruleset.root || ruleset.allowImports || !isTrue(ruleset.strictImports)) ruleset.evalImports(env);

    // Store the frames around mixin definitions,
    // so they can be evaluated like closures when the time comes.
    List<Node> rsRules = ruleset.rules;
    int rsRuleCnt = rsRules != null ? rsRules.length : 0;
    for (i = 0; i < rsRuleCnt; i++) {
      if (rsRules[i] is MixinDefinition || rsRules[i] is DetachedRuleset) rsRules[i] = rsRules[i].eval(env);
    }

    int mediaBlockCount = env.mediaBlocks != null ? env.mediaBlocks.length : 0;

    // Evaluate mixin calls.
    for (i = 0; i < rsRuleCnt; i++) {
      if (rsRules[i] is MixinCall) {
        rules = (rsRules[i] as MixinCall).eval(env)..retainWhere((r){
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
        rules = (rsRules[i] as RulesetCall).eval(env).rules..retainWhere((r){
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
      if (!(rule is MixinDefinition || rule is DetachedRuleset)) {
        ruleEvaluated = rule.eval(env);
        if (ruleEvaluated is! List) ruleEvaluated = [ruleEvaluated];
        rsRules.replaceRange(i, i+1, ruleEvaluated);
        i += ruleEvaluated.length -1;
      }
    }

    // Evaluate everything else
    for (i = 0; i < rsRules.length; i++) {
      rule = rsRules[i];
      // for rulesets, check if it is a css guard and can be removed
      if (rule is Ruleset && (rule as Ruleset).selectors != null && (rule as Ruleset).selectors.length == 1) {
        // check if it can be folded in (e.g. & where)
        if (rule.selectors[0].isJustParentSelector()) {
          rsRules.removeAt(i--);

          for (int j = 0; j < (rule as Ruleset).rules.length; j++) {
            subRule = (rule as Ruleset).rules[j];
            if (!(subRule is Rule) || !(subRule as Rule).variable) {
              rsRules.insert(++i, subRule);
            }
          }
        }
      }
    }

    // Pop the stack
    envFrames.removeAt(0);
    envSelectors.removeAt(0);

    if (env.mediaBlocks != null) {
      for (i = mediaBlockCount; i < env.mediaBlocks.length; i++) {
        env.mediaBlocks[i].bubbleSelectors(selectors);
      }
    }

    return ruleset;

//  eval: function (env) {
//      var thisSelectors = this.selectors, selectors,
//          selCnt, selector, i, defaultFunc = tree.defaultFunc, hasOnePassingSelector = false;
//
//      if (thisSelectors && (selCnt = thisSelectors.length)) {
//          selectors = [];
//          defaultFunc.error({
//              type: "Syntax",
//              message: "it is currently only allowed in parametric mixin guards,"
//          });
//          for (i = 0; i < selCnt; i++) {
//              selector = thisSelectors[i].eval(env);
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
//          ruleset = new(tree.Ruleset)(selectors, rules, this.strictImports),
//          rule, subRule;
//
//      ruleset.originalRuleset = this;
//      ruleset.root = this.root;
//      ruleset.firstRoot = this.firstRoot;
//      ruleset.allowImports = this.allowImports;
//
//      if(this.debugInfo) {
//          ruleset.debugInfo = this.debugInfo;
//      }
//
//      if (!hasOnePassingSelector) {
//          rules.length = 0;
//      }
//
//      // push the current ruleset to the frames stack
//      var envFrames = env.frames;
//      envFrames.unshift(ruleset);
//
//      // currrent selectors
//      var envSelectors = env.selectors;
//      if (!envSelectors) {
//          env.selectors = envSelectors = [];
//      }
//      envSelectors.unshift(this.selectors);
//
//      // Evaluate imports
//      if (ruleset.root || ruleset.allowImports || !ruleset.strictImports) {
//          ruleset.evalImports(env);
//      }
//
//      // Store the frames around mixin definitions,
//      // so they can be evaluated like closures when the time comes.
//      var rsRules = ruleset.rules, rsRuleCnt = rsRules ? rsRules.length : 0;
//      for (i = 0; i < rsRuleCnt; i++) {
//          if (rsRules[i] instanceof tree.mixin.Definition || rsRules[i] instanceof tree.DetachedRuleset) {
//              rsRules[i] = rsRules[i].eval(env);
//          }
//      }
//
//      var mediaBlockCount = (env.mediaBlocks && env.mediaBlocks.length) || 0;
//
//      // Evaluate mixin calls.
//      for (i = 0; i < rsRuleCnt; i++) {
//          if (rsRules[i] instanceof tree.mixin.Call) {
//              /*jshint loopfunc:true */
//              rules = rsRules[i].eval(env).filter(function(r) {
//                  if ((r instanceof tree.Rule) && r.variable) {
//                      // do not pollute the scope if the variable is
//                      // already there. consider returning false here
//                      // but we need a way to "return" variable from mixins
//                      return !(ruleset.variable(r.name));
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              rsRuleCnt += rules.length - 1;
//              i += rules.length-1;
//              ruleset.resetCache();
//          } else if (rsRules[i] instanceof tree.RulesetCall) {
//              /*jshint loopfunc:true */
//              rules = rsRules[i].eval(env).rules.filter(function(r) {
//                  if ((r instanceof tree.Rule) && r.variable) {
//                      // do not pollute the scope at all
//                      return false;
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              rsRuleCnt += rules.length - 1;
//              i += rules.length-1;
//              ruleset.resetCache();
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; i < rsRules.length; i++) {
//          rule = rsRules[i];
//          if (! (rule instanceof tree.mixin.Definition || rule instanceof tree.DetachedRuleset)) {
//              rsRules[i] = rule = rule.eval ? rule.eval(env) : rule;
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; i < rsRules.length; i++) {
//          rule = rsRules[i];
//          // for rulesets, check if it is a css guard and can be removed
//          if (rule instanceof tree.Ruleset && rule.selectors && rule.selectors.length === 1) {
//              // check if it can be folded in (e.g. & where)
//              if (rule.selectors[0].isJustParentSelector()) {
//                  rsRules.splice(i--, 1);
//
//                  for(var j = 0; j < rule.rules.length; j++) {
//                      subRule = rule.rules[j];
//                      if (!(subRule instanceof tree.Rule) || !subRule.variable) {
//                          rsRules.splice(++i, 0, subRule);
//                      }
//                  }
//              }
//          }
//      }
//
//      // Pop the stack
//      envFrames.shift();
//      envSelectors.shift();
//
//      if (env.mediaBlocks) {
//          for (i = mediaBlockCount; i < env.mediaBlocks.length; i++) {
//              env.mediaBlocks[i].bubbleSelectors(selectors);
//          }
//      }
//
//      return ruleset;
//  },
  }

  ///
  /// Analyze the rules for @import, loading the new nodes
  ///
  void evalImports(Env env) {
    List<Node> rules = this.rules;
    List<Node> importRules;
    var evalImport;

    if (rules == null) return;

    for (int i = 0; i < rules.length; i++) {
      if (rules[i] is Import) {
        evalImport = rules[i].eval(env);
        importRules = (evalImport is List) ? evalImport : [evalImport];
        rules.replaceRange(i, i+1, importRules);
        i += importRules.length - 1;
        this.resetCache();
      }
    }

//  evalImports: function(env) {
//      var rules = this.rules, i, importRules;
//      if (!rules) { return; }
//
//      for (i = 0; i < rules.length; i++) {
//          if (rules[i] instanceof tree.Import) {
//              importRules = rules[i].eval(env);
//              if (importRules && importRules.length) {
//                  rules.splice.apply(rules, [i, 1].concat(importRules));
//                  i+= importRules.length-1;
//              } else {
//                  rules.splice(i, 1, importRules);
//              }
//              this.resetCache();
//          }
//      }
//  },
  }

  ///
  Ruleset makeImportant(){
    List<Node> rules = this.rules.map((r){
      if (r is MakeImportantNode) {
        return r.makeImportant();
      } else {
        return r;
      }
    }).toList();
    return new Ruleset(this.selectors, rules, this.strictImports);

//  makeImportant: function() {
//      return new tree.Ruleset(this.selectors, this.rules.map(function (r) {
//                  if (r.makeImportant) {
//                      return r.makeImportant();
//                  } else {
//                      return r;
//                  }
//              }), this.strictImports);
//  },
  }

  ///
  bool matchArgs(List<MixinArgs> args, Env env) => (args == null || args.isEmpty);

//  matchArgs: function (args) {
//      return !args || args.length === 0;
//  },

  //--- MatchConditionNode

  ///
  /// lets you call a css selector with a guard
  ///
  bool matchCondition(List<MixinArgs>args, Env env) {
    Selector lastSelector = this.selectors.last;
    if (!lastSelector.evaldCondition) return false;
    if (lastSelector.condition != null &&
        !lastSelector.condition.eval(new Env.evalEnv(env, env.frames))) return false;

    return true;

//
//  matchCondition: function (args, env) {
//      var lastSelector = this.selectors[this.selectors.length-1];
//      if (!lastSelector.evaldCondition) {
//          return false;
//      }
//      if (lastSelector.condition &&
//          !lastSelector.condition.eval(
//              new(tree.evalEnv)(env,
//                  env.frames))) {
//          return false;
//      }
//      return true;
//  },
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

//  prependRule: function (rule) {
//      var rules = this.rules;
//      if (rules) { rules.unshift(rule); } else { this.rules = [ rule ]; }
//  },
  }


  void genCSS(Env env, Output output) {
    int i;
    int j;
    List<Node> charsetRuleNodes = [];
    List<Node> ruleNodes = [];
    List<Node> rulesetNodes = [];
    int rulesetNodeCnt;

    /// Line number debugging
    //LessDebugInfo debugInfo;

    Node rule;
    List path;

    if (this.firstRoot) env.tabLevel = 0;
    if (!this.root) env.tabLevel++;
    String tabRuleStr = env.compress ? '' : '  ' * (env.tabLevel);
    String tabSetStr = env.compress ? '' : '  ' * (env.tabLevel - 1);
    String sep;

    bool isRulesetLikeNode(Node rule, bool root) {
      // if it has nested rules, then it should be treated like a ruleset
      if (rule.rules != null) return true;

      // medias and comments do not have nested rules, but should be treated like rulesets anyway
      if ((rule is Media) || (root && rule is Comment)) return true;

      // some directives and anonymous nodes are ruleset like, others are not
      if (rule is Directive) return rule.isRulesetLike();
      if (rule is Anonymous) return rule.isRulesetLike();

      // anything else is assumed to be a rule
      return false;
    }

    for (i = 0; i < this.rules.length; i ++) {
      rule = this.rules[i];
      if (isRulesetLikeNode(rule, this.root)) {
        rulesetNodes.add(rule);
      } else {
        // charsets should float on top of everything
        if (rule.isCharset()) {
          charsetRuleNodes.add(rule);
        } else {
          ruleNodes.add(rule);
        }
      }
    }
    ruleNodes.insertAll(0, charsetRuleNodes);

    // If this is the root node, we don't render
    // a selector, or {}.
    if (!this.root) {
      if (debugInfo != null) {
        output.add(debugInfo.toOutput(env, tabSetStr));
        output.add(tabSetStr);
      }

      List paths = this.paths;
      int pathCnt = paths.length;
      int pathSubCnt;

      sep = env.compress ? ',' : ',\n${tabSetStr}';

      for (i = 0; i < pathCnt; i++) {
        path = paths[i];
        if ((pathSubCnt = path.length) == 0) continue;
        if (i > 0) output.add(sep);

        env.firstSelector = true;
        (path[0] as Node).genCSS(env, output);

        env.firstSelector = false;
        for (j = 1; j < pathSubCnt; j++) {
          (path[j] as Node).genCSS(env, output);
        }
      }

      output.add((env.compress ? '{' : ' {\n') + tabRuleStr);
    }

    // Compile rules and rulesets
    for (i = 0; i < ruleNodes.length; i++) {
      rule = ruleNodes[i];

      // @page{ directive ends up with root elements inside it, a mix of rules and rulesets
      // In this instance we do not know whether it is the last property
      if (i + 1 == ruleNodes.length && (!this.root || rulesetNodes.isEmpty || this.firstRoot)) {
        env.lastRule = true;
      }

      if (rule is ToCSSNode) {
        rule.genCSS(env, output);
      } else if (rule.value != null) {
        output.add(rule.value.toString());
      }

      if (!env.lastRule) {
        output.add(env.compress ? '' : '\n$tabRuleStr');
      } else {
        env.lastRule = false;
      }
    }

    if (!this.root) {
      output.add(env.compress ? '}' : '\n$tabSetStr}');
      env.tabLevel--;
    }

    sep = (env.compress ? '' : '\n') + (this.root ? tabRuleStr : tabSetStr);
    rulesetNodeCnt = rulesetNodes.length;
    if (rulesetNodeCnt > 0) {
      if (ruleNodes.length > 0 && sep.isNotEmpty) output.add(sep);
      rulesetNodes[0].genCSS(env, output);
      for (i = 1; i < rulesetNodeCnt; i++) {
        if (sep.isNotEmpty) output.add(sep);
        rulesetNodes[i].genCSS(env, output);
      }
    }

    if (!output.isEmpty && !env.compress && this.firstRoot) output.add('\n');

//  genCSS: function (env, output) {
//      var i, j,
//          charsetRuleNodes = [],
//          ruleNodes = [],
//          rulesetNodes = [],
//          rulesetNodeCnt,
//          debugInfo,     // Line number debugging
//          rule,
//          path;
//
//      env.tabLevel = (env.tabLevel || 0);
//
//      if (!this.root) {
//          env.tabLevel++;
//      }
//
//      var tabRuleStr = env.compress ? '' : Array(env.tabLevel + 1).join("  "),
//          tabSetStr = env.compress ? '' : Array(env.tabLevel).join("  "),
//          sep;
//
//      function isRulesetLikeNode(rule, root) {
//           // if it has nested rules, then it should be treated like a ruleset
//           if (rule.rules)
//               return true;
//
//           // medias and comments do not have nested rules, but should be treated like rulesets anyway
//           if ( (rule instanceof tree.Media) || (root && rule instanceof tree.Comment))
//               return true;
//
//           // some directives and anonumoust nodes are ruleset like, others are not
//           if ((rule instanceof tree.Directive) || (rule instanceof tree.Anonymous)) {
//               return rule.isRulesetLike();
//           }
//
//           //anything else is assumed to be a rule
//           return false;
//      }
//
//      for (i = 0; i < this.rules.length; i++) {
//          rule = this.rules[i];
//          if (isRulesetLikeNode(rule, this.root)) {
//              rulesetNodes.push(rule);
//          } else {
//              //charsets should float on top of everything
//              if (rule.isCharset && rule.isCharset()) {
//                  charsetRuleNodes.push(rule);
//              } else {
//                  ruleNodes.push(rule);
//              }
//          }
//      }
//      ruleNodes = charsetRuleNodes.concat(ruleNodes);
//
//      // If this is the root node, we don't render
//      // a selector, or {}.
//      if (!this.root) {
//          debugInfo = tree.debugInfo(env, this, tabSetStr);
//
//          if (debugInfo) {
//              output.add(debugInfo);
//              output.add(tabSetStr);
//          }
//
//          var paths = this.paths, pathCnt = paths.length,
//              pathSubCnt;
//
//          sep = env.compress ? ',' : (',\n' + tabSetStr);
//
//          for (i = 0; i < pathCnt; i++) {
//              path = paths[i];
//              if (!(pathSubCnt = path.length)) { continue; }
//              if (i > 0) { output.add(sep); }
//
//              env.firstSelector = true;
//              path[0].genCSS(env, output);
//
//              env.firstSelector = false;
//              for (j = 1; j < pathSubCnt; j++) {
//                  path[j].genCSS(env, output);
//              }
//          }
//
//          output.add((env.compress ? '{' : ' {\n') + tabRuleStr);
//      }
//
//      // Compile rules and rulesets
//      for (i = 0; i < ruleNodes.length; i++) {
//          rule = ruleNodes[i];
//
//          // @page{ directive ends up with root elements inside it, a mix of rules and rulesets
//          // In this instance we do not know whether it is the last property
//          if (i + 1 === ruleNodes.length && (!this.root || rulesetNodes.length === 0 || this.firstRoot)) {
//              env.lastRule = true;
//          }
//
//          if (rule.genCSS) {
//              rule.genCSS(env, output);
//          } else if (rule.value) {
//              output.add(rule.value.toString());
//          }
//
//          if (!env.lastRule) {
//              output.add(env.compress ? '' : ('\n' + tabRuleStr));
//          } else {
//              env.lastRule = false;
//          }
//      }
//
//      if (!this.root) {
//          output.add((env.compress ? '}' : '\n' + tabSetStr + '}'));
//          env.tabLevel--;
//      }
//
//      sep = (env.compress ? "" : "\n") + (this.root ? tabRuleStr : tabSetStr);
//      rulesetNodeCnt = rulesetNodes.length;
//      if (rulesetNodeCnt) {
//          if (ruleNodes.length && sep) { output.add(sep); }
//          rulesetNodes[0].genCSS(env, output);
//          for (i = 1; i < rulesetNodeCnt; i++) {
//              if (sep) { output.add(sep); }
//              rulesetNodes[i].genCSS(env, output);
//          }
//      }
//
//      if (!output.isEmpty() && !env.compress && this.firstRoot) {
//          output.add('\n');
//      }
//  },
//
  }

//  toCSS: tree.toCSS,
//


  //--- MarkReferencedNode

  ///
  void markReferenced(){
    if (this.selectors == null) return;

    for (int s = 0; s < this.selectors.length; s++) {
      this.selectors[s].markReferenced();
    }
  }

  ///
  joinSelectors(List paths, List context, List<Node> selectors) {
    for (int s = 0; s < selectors.length; s++) {
      joinSelector(paths, context, selectors[s]);
    }
  }

  ///
  void joinSelector(List paths, List<List> context, Selector selector){
    int i;
    int j;
    int k;
    bool hasParentSelector = false;
    List<List> newSelectors;
    Element el;
    List sel;
    List parentSel;
    List newSelectorPath;
    List afterParentJoin;
    Selector newJoinedSelector;
    bool newJoinedSelectorEmpty;
    Selector lastSelector;
    List currentElements;
    List selectorsMultiplied;

    for (i = 0; i < selector.elements.length; i++) {
      el = selector.elements[i];
      if (el.value == '&') hasParentSelector = true;
    }

    if (!hasParentSelector) {
      if (context.isNotEmpty) {
        for (i = 0; i < context.length; i++) {
          paths.add(context[i].sublist(0)..add(selector));
        }
      } else {
        paths.add([selector]);
      }
      return;
    }

    // The paths are [[Selector]]
    // The first list is a list of comma seperated selectors
    // The inner list is a list of inheritance seperated selectors
    // e.g.
    // .a, .b {
    //   .c {
    //   }
    // }
    // == [[.a] [.c]] [[.b] [.c]]
    //

    // the elements from the current selector so far
    currentElements = [];

    // the current list of new selectors to add to the path.
    // We will build it up. We initiate it with one empty selector as we
    // "multiply" the new selectors by the parents
    newSelectors = [[]];

    for (i = 0; i < selector.elements.length; i++) {
      el = selector.elements[i];
      // non parent reference elements just get added
      if (el.value != '&') {
        currentElements.add(el);
      } else {
        // the new list of selectors to add
        selectorsMultiplied = [];

        // merge the current list of non parent selector elements
        // on to the current list of selectors to add
        if (currentElements.isNotEmpty) {
          this.mergeElementsOnToSelectors(currentElements, newSelectors);
        }

        // loop through our current selectors
        for (j = 0; j < newSelectors.length; j++) {
          sel = newSelectors[j];
          // if we don't have any parent paths, the & might be in a mixin
          // so that it can be used whether there are parents or not
          if (context.isEmpty) {
            // the combinator used on el should now be applied to the next
            // element instead so that it is not lost
            if (sel.isNotEmpty) {
              sel[0].elements = sel[0].elements.sublist(0);
              Element ele = el;
              sel[0].elements.add(new Element(ele.combinator, '', ele.index,
                  ele.currentFileInfo));
            }
            selectorsMultiplied.add(sel);
          } else {
            // and the parent selectors
            for (k = 0; k < context.length; k++) {
              parentSel = context[k];
              // We need to put the current selectors
              // then join the last selector's elements on to the parents selectors

              // our new selector path
              newSelectorPath = [];
              // selectors from the parent after the join
              afterParentJoin = [];
              newJoinedSelectorEmpty = true;

              // construct the joined selector -
              // if & is the first thing this will be empty,
              // if not newJoinedSelector will be the last set of elements in the selector
              if (sel.isNotEmpty) {
                newSelectorPath = sel.sublist(0);
                lastSelector = newSelectorPath.removeLast();
                newJoinedSelector = selector.createDerived(lastSelector.elements.sublist(0));
                newJoinedSelectorEmpty = false;
              } else {
                newJoinedSelector = selector.createDerived([]);
              }

              // put together the parent selectors after the join
              if (parentSel.length > 1) afterParentJoin.addAll(parentSel.sublist(1));

              if (parentSel.isNotEmpty) {
                newJoinedSelectorEmpty = false;

                // join the elements so far with the first part of the parent
                newJoinedSelector.elements.add(new Element(
                    el.combinator, parentSel[0].elements[0].value, el.index, el.currentFileInfo));
                newJoinedSelector.elements.addAll(parentSel[0].elements.sublist(1));
              }

              if (!newJoinedSelectorEmpty) {
                // now add the joined selector
                newSelectorPath.add(newJoinedSelector);
              }

              // and the rest of the parent
              newSelectorPath.addAll(afterParentJoin);

              // add that to our new set of selectors
              selectorsMultiplied.add(newSelectorPath);

            }

          }
        }

        // our new selectors has been multiplied, so reset the state
        newSelectors = selectorsMultiplied;
        currentElements = [];
      }

    }

    // if we have any elements left over (e.g. .a& .b == .b)
    // add them on to all the current selectors
    if (currentElements.isNotEmpty) {
      this.mergeElementsOnToSelectors(currentElements, newSelectors);
    }

    for (i = 0; i < newSelectors.length; i++) {
      if (newSelectors[i].isNotEmpty) paths.add(newSelectors[i]);
    }

//  joinSelector: function (paths, context, selector) {
//
//      var i, j, k,
//          hasParentSelector, newSelectors, el, sel, parentSel,
//          newSelectorPath, afterParentJoin, newJoinedSelector,
//          newJoinedSelectorEmpty, lastSelector, currentElements,
//          selectorsMultiplied;
//
//      for (i = 0; i < selector.elements.length; i++) {
//          el = selector.elements[i];
//          if (el.value === '&') {
//              hasParentSelector = true;
//          }
//      }
//
//      if (!hasParentSelector) {
//          if (context.length > 0) {
//              for (i = 0; i < context.length; i++) {
//                  paths.push(context[i].concat(selector));
//              }
//          }
//          else {
//              paths.push([selector]);
//          }
//          return;
//      }
//
//      // The paths are [[Selector]]
//      // The first list is a list of comma seperated selectors
//      // The inner list is a list of inheritance seperated selectors
//      // e.g.
//      // .a, .b {
//      //   .c {
//      //   }
//      // }
//      // == [[.a] [.c]] [[.b] [.c]]
//      //
//
//      // the elements from the current selector so far
//      currentElements = [];
//      // the current list of new selectors to add to the path.
//      // We will build it up. We initiate it with one empty selector as we "multiply" the new selectors
//      // by the parents
//      newSelectors = [[]];
//
//      for (i = 0; i < selector.elements.length; i++) {
//          el = selector.elements[i];
//          // non parent reference elements just get added
//          if (el.value !== "&") {
//              currentElements.push(el);
//          } else {
//              // the new list of selectors to add
//              selectorsMultiplied = [];
//
//              // merge the current list of non parent selector elements
//              // on to the current list of selectors to add
//              if (currentElements.length > 0) {
//                  this.mergeElementsOnToSelectors(currentElements, newSelectors);
//              }
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
//                          sel[0].elements = sel[0].elements.slice(0);
//                          sel[0].elements.push(new(tree.Element)(el.combinator, '', el.index, el.currentFileInfo));
//                      }
//                      selectorsMultiplied.push(sel);
//                  }
//                  else {
//                      // and the parent selectors
//                      for (k = 0; k < context.length; k++) {
//                          parentSel = context[k];
//                          // We need to put the current selectors
//                          // then join the last selector's elements on to the parents selectors
//
//                          // our new selector path
//                          newSelectorPath = [];
//                          // selectors from the parent after the join
//                          afterParentJoin = [];
//                          newJoinedSelectorEmpty = true;
//
//                          //construct the joined selector - if & is the first thing this will be empty,
//                          // if not newJoinedSelector will be the last set of elements in the selector
//                          if (sel.length > 0) {
//                              newSelectorPath = sel.slice(0);
//                              lastSelector = newSelectorPath.pop();
//                              newJoinedSelector = selector.createDerived(lastSelector.elements.slice(0));
//                              newJoinedSelectorEmpty = false;
//                          }
//                          else {
//                              newJoinedSelector = selector.createDerived([]);
//                          }
//
//                          //put together the parent selectors after the join
//                          if (parentSel.length > 1) {
//                              afterParentJoin = afterParentJoin.concat(parentSel.slice(1));
//                          }
//
//                          if (parentSel.length > 0) {
//                              newJoinedSelectorEmpty = false;
//
//                              // join the elements so far with the first part of the parent
//                              newJoinedSelector.elements.push(new(tree.Element)(el.combinator, parentSel[0].elements[0].value, el.index, el.currentFileInfo));
//                              newJoinedSelector.elements = newJoinedSelector.elements.concat(parentSel[0].elements.slice(1));
//                          }
//
//                          if (!newJoinedSelectorEmpty) {
//                              // now add the joined selector
//                              newSelectorPath.push(newJoinedSelector);
//                          }
//
//                          // and the rest of the parent
//                          newSelectorPath = newSelectorPath.concat(afterParentJoin);
//
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
//      if (currentElements.length > 0) {
//          this.mergeElementsOnToSelectors(currentElements, newSelectors);
//      }
//
//      for (i = 0; i < newSelectors.length; i++) {
//          if (newSelectors[i].length > 0) {
//              paths.push(newSelectors[i]);
//          }
//      }
//  },
  }

  ///
  void mergeElementsOnToSelectors(List elements, List<List> selectors) {
    List<Selector> sel;

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

//  mergeElementsOnToSelectors: function(elements, selectors) {
//      var i, sel;
//
//      if (selectors.length === 0) {
//          selectors.push([ new(tree.Selector)(elements) ]);
//          return;
//      }
//
//      for (i = 0; i < selectors.length; i++) {
//          sel = selectors[i];
//
//          // if the previous thing in sel is a parent this needs to join on to it
//          if (sel.length > 0) {
//              sel[sel.length - 1] = sel[sel.length - 1].createDerived(sel[sel.length - 1].elements.concat(elements));
//          }
//          else {
//              sel.push(new(tree.Selector)(elements));
//          }
//      }
//  }
  }

  //parser.js 1.7.5 lines 514-627
  /// Main entry to convert the tree to CSS
  String rootToCSS(LessOptions options, Env env, [Map<String, Node> variables]) {
    String css;
    var evaldRoot; //Ruleset or source_map_output
    Node evaluate = this;
    int i;
    if (options == null) options = new LessOptions();

    Env evalEnv = new Env.evalEnv(options);

    // Allows setting variables with a hash, so:
    //
    // variables = {'my-color': new Color('ff0000')}; will become:
    //
    //   new Rule('@my-color',
    //     new Value([
    //       new Expression)([
    //         new Color('ff0000')
    //       ])
    //     ])
    //   )

    if (variables != null) {
      List<Node> vars = [];
      Node value;
      for (String k in variables.keys) {
        value = variables[k];
        if (value is! Value) {
          if (value is! Expression) value = new Expression([value]);
          value = new Value([value]);
        }
        vars.add(new Rule('@' + k, value, null, null, 0));
      }
      evalEnv.frames = [new Ruleset(null, vars)];
    }

    try {
      List<VisitorBase> preEvalVisitors = [];
      List<VisitorBase> visitors = [
                       new JoinSelectorVisitor(),
                       new ProcessExtendsVisitor(),
                       new ToCSSVisitor(new Env()
                                          ..compress = options.compress)
                       ];

      Ruleset root = this;

      // plugins must extend visitorBase
      if (options.plugins.isNotEmpty) {
        for (i = 0; i < options.plugins.length; i++) {
          if (options.plugins[i].isPreEvalVisitor) {
            preEvalVisitors.add(options.plugins[i]);
          } else {
            if (options.plugins[i].isPreVisitor) {
              visitors.insert(0, options.plugins[i]);
            } else {
              visitors.add(options.plugins[i]);
            }
          }
        }
      }

      for (i = 0; i < preEvalVisitors.length; i++) {
        preEvalVisitors[i].run(root);
      }

      evaldRoot =  root.eval(evalEnv);

      for (i = 0; i < visitors.length; i++) {
        visitors[i].run(evaldRoot);
      }

      if (options.sourceMap) {
        evaldRoot = new SourceMapOutput(
                contentsIgnoredCharsMap: env.imports.contentsIgnoredChars,
                writeSourceMap: options.writeSourceMap,
                rootNode: evaldRoot,
                contentsMap: env.imports.contents,
                sourceMapFilename: options.sourceMapFilename,
                sourceMapURL: options.sourceMapURL,
                outputFilename: options.sourceMapOutputFilename,
                sourceMapBasepath: options.sourceMapBasepath,
                sourceMapRootpath: options.sourceMapRootpath,
                outputSourceFiles: options.outputSourceFiles,
                sourceMapGenerator: options.sourceMapGenerator
            );
      }

      css = evaldRoot.toCSS(new Env()
              ..compress = options.compress
              ..dumpLineNumbers = options.dumpLineNumbers
              ..strictUnits = options.strictUnits
              ..numPrecision = 8
              ).toString();

    } catch (e, s) {
      LessError error = LessError.transform(e, env: env);
      throw new LessExceptionError(error);
    }

    if (options.cleancss) {
      return css;

//      var CleanCSS = require('clean-css'),
//          cleancssOptions = options.cleancssOptions || {};
//
//      if (cleancssOptions.keepSpecialComments === undefined) {
//          cleancssOptions.keepSpecialComments = "*";
//      }
//      cleancssOptions.processImport = false;
//      cleancssOptions.noRebase = true;
//      if (cleancssOptions.noAdvanced === undefined) {
//          cleancssOptions.noAdvanced = true;
//      }
//
//      return new CleanCSS(cleancssOptions).minify(css);
    } else if (options.compress) {
      return css;
//      return css.replace(/(^(\s)+)|((\s)+$)/g, ""); //sourcemap problems?
    } else {
      return css;
    }

//  root.toCSS = (function (evaluate) { //evaluate = this
//      return function (options, variables) {
//          options = options || {};
//          var evaldRoot,  <- lo que vamos a pasar a CSS
//              css,  //<- EL RESULTADO
//              evalEnv = new tree.evalEnv(options);
//
//          //
//          // Allows setting variables with a hash, so:
//          //
//          //   `{ color: new(tree.Color)('#f01') }` will become:
//          //
//          //   new(tree.Rule)('@color',
//          //     new(tree.Value)([
//          //       new(tree.Expression)([
//          //         new(tree.Color)('#f01')
//          //       ])
//          //     ])
//          //   )
//          //
//          if (typeof(variables) === 'object' && !Array.isArray(variables)) {
//              variables = Object.keys(variables).map(function (k) {
//                  var value = variables[k];
//
//                  if (! (value instanceof tree.Value)) {
//                      if (! (value instanceof tree.Expression)) {
//                          value = new(tree.Expression)([value]);
//                      }
//                      value = new(tree.Value)([value]);
//                  }
//                  return new(tree.Rule)('@' + k, value, false, null, 0);
//              });
//              evalEnv.frames = [new(tree.Ruleset)(null, variables)];
//          }
//
//          try {
//              var preEvalVisitors = [],
//                  visitors = [
//                      new(tree.joinSelectorVisitor)(),
//                      new(tree.processExtendsVisitor)(),
//                      new(tree.toCSSVisitor)({compress: Boolean(options.compress)})
//                  ], i, root = this;
//
//              if (options.plugins) {
//                  for(i =0; i < options.plugins.length; i++) {
//                      if (options.plugins[i].isPreEvalVisitor) {
//                          preEvalVisitors.push(options.plugins[i]);
//                      } else {
//                          if (options.plugins[i].isPreVisitor) {
//                              visitors.splice(0, 0, options.plugins[i]);
//                          } else {
//                              visitors.push(options.plugins[i]);
//                          }
//                      }
//                  }
//              }
//
//              for(i = 0; i < preEvalVisitors.length; i++) {
//                  preEvalVisitors[i].run(root);
//              }
//
//              evaldRoot = evaluate.call(root, evalEnv);
//
//              for(i = 0; i < visitors.length; i++) {
//                  visitors[i].run(evaldRoot);
//              }
//
//              if (options.sourceMap) {
//                  evaldRoot = new tree.sourceMapOutput(
//                      {
//                          contentsIgnoredCharsMap: parser.imports.contentsIgnoredChars,
//                          writeSourceMap: options.writeSourceMap,
//                          rootNode: evaldRoot,
//                          contentsMap: parser.imports.contents,
//                          sourceMapFilename: options.sourceMapFilename,
//                          sourceMapURL: options.sourceMapURL,
//                          outputFilename: options.sourceMapOutputFilename,
//                          sourceMapBasepath: options.sourceMapBasepath,
//                          sourceMapRootpath: options.sourceMapRootpath,
//                          outputSourceFiles: options.outputSourceFiles,
//                          sourceMapGenerator: options.sourceMapGenerator
//                      });
//              }
//
//              css = evaldRoot.toCSS({
//                      compress: Boolean(options.compress),
//                      dumpLineNumbers: env.dumpLineNumbers,
//                      strictUnits: Boolean(options.strictUnits),
//                      numPrecision: 8});
//          } catch (e) {
//              throw new(LessError)(e, env);
//          }
//
//          if (options.cleancss && less.mode === 'node') {
//              var CleanCSS = require('clean-css'),
//                  cleancssOptions = options.cleancssOptions || {};
//
//              if (cleancssOptions.keepSpecialComments === undefined) {
//                  cleancssOptions.keepSpecialComments = "*";
//              }
//              cleancssOptions.processImport = false;
//              cleancssOptions.noRebase = true;
//              if (cleancssOptions.noAdvanced === undefined) {
//                  cleancssOptions.noAdvanced = true;
//              }
//
//              return new CleanCSS(cleancssOptions).minify(css);
//          } else if (options.compress) {
//              return css.replace(/(^(\s)+)|((\s)+$)/g, "");
//          } else {
//              return css;
//          }
//      };
//  })(root.eval);
  }
}

//-----------------------------------------------------------------------
// Ruleset and MixinDefinition shared code
//-----------------------------------------------------------------------

class VariableMixin {
  List<Node> rules;

  Map _lookups = {};

  var _rulesets;

  /// List of Variable Nodes, by @name
  Map<String, Node> _variables;

  ///
  void resetCache(){
    this._rulesets = null;
    this._variables = null;
    this._lookups = {};
  }

  /// returns the variables list if exist, else creates it. #
  Map<String, Node> variables(){
    if (this._variables == null) {
      this._variables = (this.rules == null) ? {} : this.rules.fold({}, (hash, r){
        if (r is Rule && r.variable) {
          hash[r.name] = r;
        }
        return hash;
      });
    }
    return this._variables;

//  variables: function () {
//      if (!this._variables) {
//          this._variables = !this.rules ? {} : this.rules.reduce(function (hash, r) {
//              if (r instanceof tree.Rule && r.variable === true) {
//                  hash[r.name] = r;
//              }
//              return hash;
//          }, {});
//      }
//      return this._variables;
//  },
  }

  /// return the Variable Node (@variable = value). #
  Node variable(String name) => this.variables()[name];


  ///
  /// Returns a List of MixinDefinition or Ruleset contained in this.rules
  /// #
  List<Node> rulesets(){
    if (this.rules == null) return null;

    List<Node> filtRules = [];
    List<Node> rules = this.rules;
    Node rule;

    for (int i = 0; i < rules.length; i++) {
      rule = rules[i];
      if (rule is Ruleset || rule is MixinDefinition) filtRules.add(rule);
    }

    return filtRules;


//  rulesets: function () {
//      if (!this.rules) { return null; }
//
//      var _Ruleset = tree.Ruleset, _MixinDefinition = tree.mixin.Definition,
//          filtRules = [], rules = this.rules, cnt = rules.length,
//          i, rule;
//
//      for (i = 0; i < cnt; i++) {
//          rule = rules[i];
//          if ((rule instanceof _Ruleset) || (rule instanceof _MixinDefinition)) {
//              filtRules.push(rule);
//          }
//      }
//
//      return filtRules;
//  },
  }

  ///
  /// Return the List of Rules that matchs [selector].
  /// The results are cached.
  ///
  List<Node> find (Selector selector, [self]) {
    if (self == null) self = this;
    List<Node> rules = [];
    int match; // Selectors matchs number. 0 not match
    String key = selector.toCSS(null); // ' selector'

    if (this._lookups.containsKey(key)) return this._lookups[key];

    this.rulesets().forEach((Node rule) {//List of MixinDefinition and Ruleset
      if (rule != self) {
        for (int j = 0; j < rule.selectors.length; j++) {
          match = selector.match(rule.selectors[j]);
          if (match > 0) {
            if (selector.elements.length > match) {
              rules.addAll((rule as Ruleset).find(new Selector(selector.elements.sublist(match)), self));
            } else {
              rules.add(rule);
            }
            break;
          }
        }
      }
    });
    this._lookups[key] = rules;
    return rules;

//  find: function (selector, self) {
//      self = self || this;
//      var rules = [], match,
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
//                          Array.prototype.push.apply(rules, rule.find(
//                              new(tree.Selector)(selector.elements.slice(match)), self));
//                      } else {
//                          rules.push(rule);
//                      }
//                      break;
//                  }
//              }
//          }
//      });
//      this._lookups[key] = rules;
//      return rules;
//  },
  }
}