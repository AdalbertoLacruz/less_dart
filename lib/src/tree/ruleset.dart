// source: less/tree/ruleset.js 3.5.0.beta.5 20180702

part of tree.less;

///
class Ruleset extends Node
    with VariableMixin
    implements
        MakeImportantNode,
        MatchConditionNode {

  @override final String type = 'Ruleset';

  ///
  bool                  allowImports = false;
  ///
  bool                  extendOnEveryPath = false; // used in ExtendFinderVisitor
  ///
  bool                  firstRoot = false;
  ///
  bool                  multiMedia = false;
  ///
  List<List<Selector>>  paths; // The paths are [[Selector]]
  ///
  bool                  root = false;
  ///
  bool                  strictImports;

  ///
  Ruleset(List<Selector> selectors, List<Node> rules,
      {VisibilityInfo visibilityInfo, this.strictImports = false}) {
    // ignore: prefer_initializing_formals
    this.selectors = selectors;
    // ignore: prefer_initializing_formals
    this.rules = rules;

    isRuleset = true;

    copyVisibilityInfo(visibilityInfo);
    allowRoot = true;
    setParent(this.selectors, this);
    setParent(this.rules, this);

//3.0.0 20160714
// var Ruleset = function (selectors, rules, strictImports, visibilityInfo) {
//     this.selectors = selectors;
//     this.rules = rules;
//     this._lookups = {};
//     this.strictImports = strictImports;
//     this.copyVisibilityInfo(visibilityInfo);
//     this.allowRoot = true;
//     this.setParent(this.selectors, this);
//     this.setParent(this.rules, this);
//
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'selectors': selectors,
    'rules': rules
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (paths != null) {
      paths = visitor.visitArray(paths, nonReplacing: true);
    } else if (selectors != null) {
      selectors = visitor.visitArray(selectors);
    }

    if (rules?.isNotEmpty ?? false) rules = visitor.visitArray(rules);

//2.5.3 20151120
// Ruleset.prototype.accept = function (visitor) {
//     if (this.paths) {
//         this.paths = visitor.visitArray(this.paths, true);
//     } else if (this.selectors) {
//         this.selectors = visitor.visitArray(this.selectors);
//     }
//     if (this.rules && this.rules.length) {
//         this.rules = visitor.visitArray(this.rules);
//     }
// };
  }

  ///
  @override
  Ruleset eval(Contexts context) {
    bool                  hasOnePassingSelector = false;
    bool                  hasVariable = false;
    List<Selector>        selectors;

    final DefaultFunc defaultFunc = context.defaultFunc ??= new DefaultFunc();

    // selector such as body, h1, ...
    if (this.selectors?.isNotEmpty ?? false) {
      selectors = <Selector>[];
      defaultFunc.error(new LessError(
          type: 'Syntax',
          message: 'it is currently only allowed in parametric mixin guards,',
          context: context));

      this.selectors.forEach((Selector sel) {
        final Selector selector = sel.eval(context);
        hasVariable = hasVariable || selector.elements.any((Element el) => el.isVariable);
        selectors.add(selector);
        if (selector.evaldCondition) hasOnePassingSelector = true;
      });

      if (hasVariable) {
        final List<String> toParseSelectors = selectors.map((Selector selector) =>
            selector.toCSS(context)
        ).toList();

        final List<Selector> result = new ParseNode(
            toParseSelectors.join(','),
            selectors.first.index,
            selectors.first.currentFileInfo).selectors();
        if (result != null) selectors = result; // selectors = utils.flattenArray(result);
      }

      defaultFunc.reset();
    } else {
      hasOnePassingSelector = true;
    }

    final Ruleset ruleset = new Ruleset(selectors,
        hasOnePassingSelector ? rules?.sublist(0) : <Node>[],  //rules
        strictImports: strictImports,
        visibilityInfo: visibilityInfo())
            ..originalRuleset = this
            ..id = id
            ..root = root
            ..firstRoot = firstRoot
            ..allowImports = allowImports
            ..debugInfo = debugInfo;

    // inherit a function registry from the frames stack when possible; (in js from the top)
    final FunctionRegistry parentFR = FunctionRegistry.foundInherit(context.frames);
    ruleset.functionRegistry = new FunctionRegistry.inherit(parentFR);

    // push the current ruleset to the frames stack
    final List<Node> ctxFrames = context.frames
        ..insert(0, ruleset);

    // current selectors
    final List<List<Selector>> ctxSelectors = (context.selectors ??= <List<Selector>>[])
        ..insert(0, this.selectors);

    // Evaluate imports
    if (ruleset.root ||
        ruleset.allowImports ||
        !(ruleset.strictImports ?? false)) ruleset.evalImports(context);

    // Store the frames around mixin definitions,
    // so they can be evaluated like closures when the time comes.
    ruleset.rules = ruleset.rules?.map((Node rule) =>
      (rule.evalFirst) ? rule.eval(context) : rule
    )?.toList();

    final int mediaBlockCount = context.mediaBlocks?.length ?? 0;

    // Evaluate mixin calls.
    int rsRuleCnt = ruleset.rules?.length ?? 0;
    for (int i = 0; i < rsRuleCnt; i++) {
      final Node rule = ruleset.rules[i];
      if (rule is MixinCall) {
        final List<Node> rules = rule.eval(context).rules..retainWhere((Node r) {
          if (r is Declaration && r.variable) {
            // do not pollute the scope if the variable is
            // already there. consider returning false here
            // but we need a way to "return" variable from mixins
            // Collateral effect. Variable() needs access to ruleset.rules updated
            return (ruleset.variable(r.name) == null);
          }
          return true;
        });
        ruleset.rules.replaceRange(i, i + 1, rules);
        rsRuleCnt += rules.length - 1;
        i += rules.length - 1;
        ruleset.resetCache();
      } else if (rule is VariableCall) {
        final List<Node> rules = rule.eval(context).rules..retainWhere((Node r) {
          if (r is Declaration && r.variable) {
            // do not pollute the scope at all
            return false;
          }
          return true;
        });
        ruleset.rules.replaceRange(i, i+1, rules);
        rsRuleCnt += rules.length - 1;
        i += rules.length - 1;
        ruleset.resetCache();
      }
    }

    // Evaluate everything else
    for (int i = 0; i < (ruleset.rules?.length ?? 0); i++) {
      final Node rule = ruleset.rules[i];
      if (!rule.evalFirst) {
        final Node ruleEval = rule.eval(context);
        final List<Node> ruleEvaluated = (ruleEval is Nodeset) ? ruleEval.rules : <Node>[ruleEval];
        ruleset.rules.replaceRange(i, i + 1, ruleEvaluated);
        i += ruleEvaluated.length - 1;
      }
    }

    // Evaluate everything else
    for (int i = 0; i < (ruleset.rules?.length ?? 0); i++) {
      final Node rule = ruleset.rules[i];
      // for rulesets, check if it is a css guard and can be removed
      if (rule is Ruleset && (rule.selectors?.length == 1 ?? false)) {
        // check if it can be folded in (e.g. & where)
        if (rule.selectors.isNotEmpty && rule.selectors.first.isJustParentSelector()) {
          ruleset
            .rules.removeAt(i--)
            .rules.forEach((Node subRule) {
              subRule.copyVisibilityInfo(rule.visibilityInfo());
              if (!(subRule is Declaration) || !(subRule as Declaration).variable) {
                ruleset.rules.insert(++i, subRule);
              }
            });
        }
      }
    }

    // Pop the stack
    ctxFrames.removeAt(0);
    ctxSelectors.removeAt(0);

    //for the new mediaBlocks that appears in the process
    for (int i = mediaBlockCount; i < (context.mediaBlocks?.length ?? 0); i++) {
      context.mediaBlocks[i].bubbleSelectors(selectors);
    }

    return ruleset;

// 3.5.0.beta 20180625
//  Ruleset.prototype.eval = function (context) {
//      var that = this, selectors, selCnt, selector, i, hasVariable, hasOnePassingSelector = false;
//
//      if (this.selectors && (selCnt = this.selectors.length)) {
//          selectors = new Array(selCnt);
//          defaultFunc.error({
//              type: 'Syntax',
//              message: 'it is currently only allowed in parametric mixin guards,'
//          });
//
//          for (i = 0; i < selCnt; i++) {
//              selector = this.selectors[i].eval(context);
//              for (var j = 0; j < selector.elements.length; j++) {
//                  if (selector.elements[j].isVariable) {
//                      hasVariable = true;
//                      break;
//                  }
//              }
//              selectors[i] = selector;
//              if (selector.evaldCondition) {
//                  hasOnePassingSelector = true;
//              }
//          }
//
//          if (hasVariable) {
//              var toParseSelectors = new Array(selCnt);
//              for (i = 0; i < selCnt; i++) {
//                  selector = selectors[i];
//                  toParseSelectors[i] = selector.toCSS(context);
//              }
//              this.parse.parseNode(
//                  toParseSelectors.join(','),
//                  ["selectors"],
//                  selectors[0].getIndex(),
//                  selectors[0].fileInfo(),
//                  function(err, result) {
//                      if (result) {
//                          selectors = utils.flattenArray(result);
//                      }
//                  });
//          }
//
//          defaultFunc.reset();
//      } else {
//          hasOnePassingSelector = true;
//      }
//
//      var rules = this.rules ? utils.copyArray(this.rules) : null,
//          ruleset = new Ruleset(selectors, rules, this.strictImports, this.visibilityInfo()),
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
//      ruleset.functionRegistry = (function (frames) {
//          var i = 0,
//              n = frames.length,
//              found;
//          for ( ; i !== n ; ++i ) {
//              found = frames[ i ].functionRegistry;
//              if ( found ) { return found; }
//          }
//          return globalFunctionRegistry;
//      }(context.frames)).inherit();
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
//      var rsRules = ruleset.rules;
//      for (i = 0; (rule = rsRules[i]); i++) {
//          if (rule.evalFirst) {
//              rsRules[i] = rule.eval(context);
//          }
//      }
//
//      var mediaBlockCount = (context.mediaBlocks && context.mediaBlocks.length) || 0;
//
//      // Evaluate mixin calls.
//      for (i = 0; (rule = rsRules[i]); i++) {
//          if (rule.type === 'MixinCall') {
//              /* jshint loopfunc:true */
//              rules = rule.eval(context).filter(function(r) {
//                  if ((r instanceof Declaration) && r.variable) {
//                      // do not pollute the scope if the variable is
//                      // already there. consider returning false here
//                      // but we need a way to "return" variable from mixins
//                      return !(ruleset.variable(r.name));
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              i += rules.length - 1;
//              ruleset.resetCache();
//          } else if (rule.type ===  'VariableCall') {
//              /* jshint loopfunc:true */
//              rules = rule.eval(context).rules.filter(function(r) {
//                  if ((r instanceof Declaration) && r.variable) {
//                      // do not pollute the scope at all
//                      return false;
//                  }
//                  return true;
//              });
//              rsRules.splice.apply(rsRules, [i, 1].concat(rules));
//              i += rules.length - 1;
//              ruleset.resetCache();
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; (rule = rsRules[i]); i++) {
//          if (!rule.evalFirst) {
//              rsRules[i] = rule = rule.eval ? rule.eval(context) : rule;
//          }
//      }
//
//      // Evaluate everything else
//      for (i = 0; (rule = rsRules[i]); i++) {
//          // for rulesets, check if it is a css guard and can be removed
//          if (rule instanceof Ruleset && rule.selectors && rule.selectors.length === 1) {
//              // check if it can be folded in (e.g. & where)
//              if (rule.selectors[0] && rule.selectors[0].isJustParentSelector()) {
//                  rsRules.splice(i--, 1);
//
//                  for (var j = 0; (subRule = rule.rules[j]); j++) {
//                      if (subRule instanceof Node) {
//                          subRule.copyVisibilityInfo(rule.visibilityInfo());
//                          if (!(subRule instanceof Declaration) || !subRule.variable) {
//                              rsRules.splice(++i, 0, subRule);
//                          }
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
    final List<Node> rules = this.rules;
    if (rules == null) return;

    for (int i = 0; i < rules.length; i++) {
      if (rules[i] is Import) {
        final Node evalImport = rules[i].eval(context);
        //importRules = (evalImport is List<Node>) ? evalImport : <Node>[evalImport];
        final List<Node> importRules = (evalImport is Nodeset)
            ? evalImport.rules
            : <Node>[evalImport];
        rules.replaceRange(i, i + 1, importRules);
        i += importRules.length - 1;
        resetCache();
      }
    }

//2.5.3 20151120
// Ruleset.prototype.evalImports = function(context) {
//     var rules = this.rules, i, importRules;
//     if (!rules) { return; }
//
//     for (i = 0; i < rules.length; i++) {
//         if (rules[i].type === "Import") {
//             importRules = rules[i].eval(context);
//             if (importRules && (importRules.length || importRules.length === 0)) {
//                 rules.splice.apply(rules, [i, 1].concat(importRules));
//                 i+= importRules.length - 1;
//             } else {
//                 rules.splice(i, 1, importRules);
//             }
//             this.resetCache();
//         }
//     }
// };
  }

  ///
  @override
  bool isRulesetLike() => true;

//3.0.0 20160716
// Ruleset.prototype.isRulesetLike = function() { return true; };

  ///
  @override
  Ruleset makeImportant() => new Ruleset(
      selectors,
      rules.map((Node r) => (r is MakeImportantNode)
            ? (r as MakeImportantNode).makeImportant()
            : r
      ).toList(),
      strictImports: strictImports,
      visibilityInfo: visibilityInfo());

//2.5.3 20151120
// Ruleset.prototype.makeImportant = function() {
//     var result = new Ruleset(this.selectors, this.rules.map(function (r) {
//         if (r.makeImportant) {
//             return r.makeImportant();
//         } else {
//             return r;
//         }
//     }), this.strictImports, this.visibilityInfo());
//
//     return result;
// };

  ///
  @override
  bool matchArgs(List<MixinArgs> args, Contexts context) =>
      (args == null || args.isEmpty);

//2.3.1
//  Ruleset.prototype.matchArgs = function (args) {
//      return !args || args.length === 0;
//  };

  //--- MatchConditionNode

  ///
  /// lets you call a css selector with a guard
  ///
  @override
  bool matchCondition(List<MixinArgs> args, Contexts context) {
    final Selector lastSelector = selectors.last;
    if (!lastSelector.evaldCondition) return false;
    if (lastSelector.condition != null &&
        !lastSelector.condition.eval(new Contexts.eval(context, context.frames)).evaluated) {
      return false;
    }
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
    if (rules != null) {
      rules.insert(0, rule);
    } else {
      rules = <Node>[rule];
    }
    setParent(rule, this);

//3.0.0 20160714
// Ruleset.prototype.prependRule = function (rule) {
//     var rules = this.rules;
//     if (rules) {
//         rules.unshift(rule);
//     } else {
//         this.rules = [ rule ];
//     }
//     this.setParent(rule, this);
// };
  }

  ///
  bool isCompress(Contexts context) => context.compress || cleanCss != null;

  ///
  @override
  void genCSS(Contexts context, Output output) {
    final List<Node>  charsetRuleNodes = <Node>[];
    Node              rule;
    final List<Node>  ruleNodes = <Node>[];
    List<Node>        path;

    if (firstRoot) context.tabLevel = 0;
    if (!root) context.tabLevel++;
    final String tabRuleStr =
        isCompress(context) ? '' : '  ' * (context.tabLevel);
    final String tabSetStr =
        isCompress(context) ? '' : '  ' * (context.tabLevel - 1);
    String sep;

    int charsetNodeIndex = 0;
    int importNodeIndex = 0;
    for (int i = 0; i < rules.length; i++) {
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
        output
            ..add(debugInfo.toOutput(context, tabSetStr))
            ..add(tabSetStr);
      }

      final List<List<Selector>> paths = this.paths;
      sep = isCompress(context) ? ',' : ',\n$tabSetStr';

      for (int i = 0; i < paths.length; i++) {
        path = paths[i];
        if (path.isEmpty) continue;
        if (i > 0) output.add(sep);

        context.firstSelector = true;
        path[0].genCSS(context, output);

        context.firstSelector = false;
        for (int j = 1; j < path.length; j++) {
          path[j].genCSS(context, output);
        }
      }
      // ignore: prefer_interpolation_to_compose_strings
      output.add((isCompress(context) ? '{' : ' {\n') + tabRuleStr);
    }

    // Compile rules and rulesets
    for (int i = 0; i < ruleNodes.length; i++) {
      rule = ruleNodes[i];

      if (i + 1 == ruleNodes.length) context.lastRule = true;

      final bool currentLastRule = context.lastRule;
      if (rule.isRulesetLike()) context.lastRule = false;

      if (rule is Node) {
        rule.genCSS(context, output);
      } else if (rule.value != null) {
        output.add(rule.value.toString());
      }

      context.lastRule = currentLastRule;
      if (!context.lastRule && (rule.isVisible() ?? true)) { //isVisible() null affect debug tests
        if (firstRoot && (cleanCss?.keepBreaks ?? false) && output.last != '\n') {
          output.add('\n');
        } else {
          output.add(isCompress(context) ? '' : '\n$tabRuleStr');
        }
      } else {
        context.lastRule = false;
      }
    }

    if (!root) {
      if (cleanCss != null && cleanCss.keepBreaks) {
        output.add('}\n');
      } else {
        output.add(isCompress(context) ? '}' : '\n$tabSetStr}');
      }
      context.tabLevel--;
    }

    if (!output.isEmpty && !isCompress(context) && firstRoot) output.add('\n');

//3.0.0 20160716
// Ruleset.prototype.genCSS = function (context, output) {
//     var i, j,
//         charsetRuleNodes = [],
//         ruleNodes = [],
//         debugInfo,     // Line number debugging
//         rule,
//         path;
//
//     context.tabLevel = (context.tabLevel || 0);
//
//     if (!this.root) {
//         context.tabLevel++;
//     }
//
//     var tabRuleStr = context.compress ? '' : Array(context.tabLevel + 1).join("  "),
//         tabSetStr = context.compress ? '' : Array(context.tabLevel).join("  "),
//         sep;
//
//     var charsetNodeIndex = 0;
//     var importNodeIndex = 0;
//     for (i = 0; (rule = this.rules[i]); i++) {
//         if (rule instanceof Comment) {
//             if (importNodeIndex === i) {
//                 importNodeIndex++;
//             }
//             ruleNodes.push(rule);
//         } else if (rule.isCharset && rule.isCharset()) {
//             ruleNodes.splice(charsetNodeIndex, 0, rule);
//             charsetNodeIndex++;
//             importNodeIndex++;
//         } else if (rule.type === "Import") {
//             ruleNodes.splice(importNodeIndex, 0, rule);
//             importNodeIndex++;
//         } else {
//             ruleNodes.push(rule);
//         }
//     }
//     ruleNodes = charsetRuleNodes.concat(ruleNodes);
//
//     // If this is the root node, we don't render
//     // a selector, or {}.
//     if (!this.root) {
//         debugInfo = getDebugInfo(context, this, tabSetStr);
//
//         if (debugInfo) {
//             output.add(debugInfo);
//             output.add(tabSetStr);
//         }
//
//         var paths = this.paths, pathCnt = paths.length,
//             pathSubCnt;
//
//         sep = context.compress ? ',' : (',\n' + tabSetStr);
//
//         for (i = 0; i < pathCnt; i++) {
//             path = paths[i];
//             if (!(pathSubCnt = path.length)) { continue; }
//             if (i > 0) { output.add(sep); }
//
//             context.firstSelector = true;
//             path[0].genCSS(context, output);
//
//             context.firstSelector = false;
//             for (j = 1; j < pathSubCnt; j++) {
//                 path[j].genCSS(context, output);
//             }
//         }
//
//         output.add((context.compress ? '{' : ' {\n') + tabRuleStr);
//     }
//
//     // Compile rules and rulesets
//     for (i = 0; (rule = ruleNodes[i]); i++) {
//
//         if (i + 1 === ruleNodes.length) {
//             context.lastRule = true;
//         }
//
//         var currentLastRule = context.lastRule;
//         if (rule.isRulesetLike(rule)) {
//             context.lastRule = false;
//         }
//
//         if (rule.genCSS) {
//             rule.genCSS(context, output);
//         } else if (rule.value) {
//             output.add(rule.value.toString());
//         }
//
//         context.lastRule = currentLastRule;
//
//         if (!context.lastRule && rule.isVisible()) {
//             output.add(context.compress ? '' : ('\n' + tabRuleStr));
//         } else {
//             context.lastRule = false;
//         }
//     }
//
//     if (!this.root) {
//         output.add((context.compress ? '}' : '\n' + tabSetStr + '}'));
//         context.tabLevel--;
//     }
//
//     if (!output.isEmpty() && !context.compress && this.firstRoot) {
//         output.add('\n');
//     }
// };
  }

  ///
  void joinSelectors(List<List<Selector>> paths, List<List<Selector>> context,
      List<Selector> selectors) {
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
  void joinSelector(List<List<Selector>> paths, List<List<Selector>>context,
      Selector selector) {
    List<List<Selector>> newPaths = <List<Selector>>[];
    final bool hadParentSelector =
        replaceParentSelector(newPaths, context, selector);

    if (!hadParentSelector) {
      if (context.isNotEmpty) {
        newPaths = <List<Selector>>[];
        for (int i = 0; i < context.length; i++) {
          final List<Selector> concatenated = context[i]
              .map((Selector sel) =>
                  deriveSelector(selector.visibilityInfo(), sel))
              .toList()
              ..add(selector);
          newPaths.add(concatenated);
        }
      } else {
        newPaths = <List<Selector>>[
          <Selector>[selector]
        ];
      }
    }

    for (int i = 0; i < newPaths.length; i++) {
      paths.add(newPaths[i]);
    }

//3.0.0 20160714
//  Ruleset.prototype.joinSelector = function (paths, context, selector) {
//   //joinSelector code follows
//   var i, newPaths, hadParentSelector;
//
//   newPaths = [];
//   hadParentSelector = replaceParentSelector(newPaths, context, selector);
//
//   if (!hadParentSelector) {
//       if (context.length > 0) {
//           newPaths = [];
//           for (i = 0; i < context.length; i++) {
//
//               var concatenated = context[i].map(deriveSelector.bind(this, selector.visibilityInfo()));
//
//               concatenated.push(selector);
//               newPaths.push(concatenated);
//           }
//       }
//       else {
//           newPaths = [[selector]];
//       }
//   }
//
//   for (i = 0; i < newPaths.length; i++) {
//       paths.push(newPaths[i]);
//   }
// };
  }

  ///
  Paren createParenthesis(List<Node> elementsToPak, Element originalElement) {
    Paren replacementParen;

    if (elementsToPak.isEmpty) {
      replacementParen = new Paren(null);
    } else {
      final List<Element> insideParent = <Element>[]; // TODO map?
      for (int j = 0; j < elementsToPak.length; j++) {
        insideParent.add(new Element(null, elementsToPak[j],
            isVariable: originalElement.isVariable,
            index: originalElement._index,
            currentFileInfo: originalElement._fileInfo));
      }
      replacementParen = new Paren(new Selector(insideParent));
    }
    return replacementParen;

//inside joinSelector
// 3.5.0.beta 20180625
//  function createParenthesis(elementsToPak, originalElement) {
//      var replacementParen, j;
//      if (elementsToPak.length === 0) {
//          replacementParen = new Paren(elementsToPak[0]);
//      } else {
//          var insideParent = new Array(elementsToPak.length);
//          for (j = 0; j < elementsToPak.length; j++) {
//              insideParent[j] = new Element(
//                  null,
//                  elementsToPak[j],
//                  originalElement.isVariable,
//                  originalElement._index,
//                  originalElement._fileInfo
//              );
//          }
//          replacementParen = new Paren(new Selector(insideParent));
//      }
//      return replacementParen;
//  }
  }

  ///
  Selector createSelector(Node containedElement, Element originalElement) {
    final Element element = new Element(null, containedElement,
        isVariable: originalElement.isVariable,
        index: originalElement._index,
        currentFileInfo: originalElement._fileInfo);
    return new Selector(<Element>[element]);

// inside joinSelector
// 3.5.0.beta 20180625
//  function createSelector(containedElement, originalElement) {
//      var element, selector;
//      element = new Element(null, containedElement, originalElement.isVariable, originalElement._index, originalElement._fileInfo);
//      selector = new Selector([element]);
//      return selector;
//  }
  }

  ///
  /// Replace all parent selectors inside `inSelector` by content of `context` array
  /// resulting selectors are returned inside `paths` array
  /// returns true if `inSelector` contained at least one parent selector
  ///
  ///
  /// The paths are [[Selector]]
  /// The first list is a list of comma separated selectors
  /// The inner list is a list of inheritance separated selectors
  /// e.g.
  /// .a, .b {
  ///   .c {
  ///   }
  /// }
  /// == [[.a] [.c]] [[.b] [.c]]
  ///
  bool replaceParentSelector(List<List<Selector>> paths,
      List<List<Selector>> context, Selector inSelector) {
    //
    bool hadParentSelector = false;

    Selector findNestedSelector(Element element) {
      if (element.value is String) return null;
      if (element.value is! Paren) return null;

      final Node maybeSelector = element.value.value;
      if (maybeSelector is! Selector) return null;
      return maybeSelector as Selector;
    }

    // the elements from the current selector so far
    List<Element> currentElements = <Element>[];

    // the current list of new selectors to add to the path.
    // We will build it up. We initiate it with one empty selector as we "multiply" the new selectors
    // by the parents
    List<List<Selector>> newSelectors = <List<Selector>>[<Selector>[]];

    for (int i = 0; i < inSelector.elements.length; i++) {
      final Element el = inSelector.elements[i];
      // non parent reference elements just get added
      if (el.value != '&') {
        final Selector nestedSelector = findNestedSelector(el);
        if (nestedSelector != null) {
          // merge the current list of non parent selector elements
          // on to the current list of selectors to add
          mergeElementsOnToSelectors(currentElements, newSelectors);

          final List<List<Selector>> nestedPaths = <List<Selector>>[];
          final List<List<Selector>> replacedNewSelectors = <List<Selector>>[];

          final bool replaced =
              replaceParentSelector(nestedPaths, context, nestedSelector);
          hadParentSelector = hadParentSelector || replaced;

          // the nestedPaths array should have only one member - replaceParentSelector does not multiply selectors
          for (int k = 0; k < nestedPaths.length; k++) {
            final Selector replacementSelector =
                createSelector(createParenthesis(nestedPaths[k], el), el);
            addAllReplacementsIntoPath(
                newSelectors,
                <Selector>[replacementSelector],
                el,
                inSelector,
                replacedNewSelectors);
          }
          newSelectors = replacedNewSelectors;
          currentElements = <Element>[];
        } else {
          currentElements.add(el);
        }
      } else {
        hadParentSelector = true;

        // the new list of selectors to add
        final List<List<Selector>> selectorsMultiplied = <List<Selector>>[];

        // merge the current list of non parent selector elements
        // on to the current list of selectors to add
        mergeElementsOnToSelectors(currentElements, newSelectors);

        // loop through our current selectors
        for (int j = 0; j < newSelectors.length; j++) {
          final List<Selector> sel = newSelectors[j];
          // if we don't have any parent paths, the & might be in a mixin so that it can be used
          // whether there are parents or not
          if (context.isEmpty) {
            // the combinator used on el should now be applied to the next element instead so that
            // it is not lost
            if (sel.isNotEmpty) {
              sel.first.elements.add(new Element(
                  el.combinator, '',
                  isVariable: el.isVariable,
                  index: el._index,
                  currentFileInfo: el._fileInfo));
            }
            selectorsMultiplied.add(sel);
          } else {
            // and the parent selectors
            for (int k = 0; k < context.length; k++) {
              // We need to put the current selectors
              // then join the last selector's elements on to the parents selectors
              final List<Selector> newSelectorPath =
                  addReplacementIntoPath(sel, context[k], el, inSelector);
              // add that to our new set of selectors
              selectorsMultiplied.add(newSelectorPath);
            }
          }
        }

        //
        // our new selectors has been multiplied, so reset the state
        newSelectors = selectorsMultiplied;
        currentElements = <Element>[];
      }
    }

    // if we have any elements left over (e.g. .a& .b == .b)
    // add them on to all the current selectors
    mergeElementsOnToSelectors(currentElements, newSelectors);

    for (int i = 0; i < newSelectors.length; i++) {
      final int length = newSelectors[i].length;
      if (length > 0) {
        paths.add(newSelectors[i]);
        final Selector lastSelector = newSelectors[i].last;
        newSelectors[i][length - 1] = lastSelector.createDerived(
            lastSelector.elements,
            extendList: inSelector.extendList);
      }
    }

    return hadParentSelector;

// 3.5.0.beta 20180625
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
//          if (!(element.value instanceof Paren)) {
//              return null;
//          }
//
//          maybeSelector = element.value.value;
//          if (!(maybeSelector instanceof Selector)) {
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
//      for (i = 0; (el = inSelector.elements[i]); i++) {
//          // non parent reference elements just get added
//          if (el.value !== '&') {
//              var nestedSelector = findNestedSelector(el);
//              if (nestedSelector != null) {
//                  // merge the current list of non parent selector elements
//                  // on to the current list of selectors to add
//                  mergeElementsOnToSelectors(currentElements, newSelectors);
//
//                  var nestedPaths = [], replaced, replacedNewSelectors = [];
//                  replaced = replaceParentSelector(nestedPaths, context, nestedSelector);
//                  hadParentSelector = hadParentSelector || replaced;
//                  // the nestedPaths array should have only one member - replaceParentSelector does not multiply selectors
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
//                          sel[0].elements.push(new Element(el.combinator, '', el.isVariable, el._index, el._fileInfo));
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
  List<Selector> addReplacementIntoPath(
      List<Selector>  beginningPath,
      List<Selector>  addPath,
      Element         replacedElement,
      Selector        originalSelector) {

    List<Selector>  newSelectorPath = <Selector>[];
    Selector        newJoinedSelector;

    // construct the joined selector - if & is the first thing this will be empty,
    // if not newJoinedSelector will be the last set of elements in the selector
    if (beginningPath.isNotEmpty) {
      newSelectorPath = beginningPath.sublist(0);
      final Selector lastSelector = newSelectorPath.removeLast();
      newJoinedSelector =
          originalSelector.createDerived(lastSelector.elements.sublist(0));
    } else {
      newJoinedSelector = originalSelector.createDerived(<Element>[]);
    }

    if (addPath.isNotEmpty) {
      // /deep/ is a CSS4 selector - (removed, so should deprecate)
      // that is valid without anything in front of it
      // so if the & does not have a combinator that is "" or " " then
      // and there is a combinator on the parent, then grab that.
      // this also allows + a { & .b { .a & { ... though not sure why you would want to do that
      Combinator combinator = replacedElement.combinator;
      final Element parentEl = addPath.first.elements.first;

      if ((combinator.emptyOrWhitespace ?? false) &&
          !(parentEl.combinator.emptyOrWhitespace ?? false)) {
        combinator = parentEl.combinator;
      }

      // join the elements so far with the first part of the parent
      newJoinedSelector.elements
          ..add(new Element(combinator, parentEl.value,
              isVariable: replacedElement.isVariable,
              index: replacedElement._index,
              currentFileInfo: replacedElement._fileInfo))
          ..addAll(addPath.first.elements.sublist(1));
    }

    // now add the joined selector - but only if it is not empty
    if (newJoinedSelector.elements.isNotEmpty) newSelectorPath.add(newJoinedSelector);

    // put together the parent selectors after the join (e.g. the rest of the parent)
    if (addPath.length > 1) {
      List<Selector> restOfPath = addPath.sublist(1);
      restOfPath = restOfPath.map((Selector selector) =>
          selector.createDerived(selector.elements, extendList: <Extend>[])
      ).toList();
      newSelectorPath.addAll(restOfPath);
    }

    return newSelectorPath;

// 3.5.0.beta 20180625
//  function addReplacementIntoPath(beginningPath, addPath, replacedElement, originalSelector) {
//      var newSelectorPath, lastSelector, newJoinedSelector;
//      // our new selector path
//      newSelectorPath = [];
//
//      // construct the joined selector - if & is the first thing this will be empty,
//      // if not newJoinedSelector will be the last set of elements in the selector
//      if (beginningPath.length > 0) {
//          newSelectorPath = utils.copyArray(beginningPath);
//          lastSelector = newSelectorPath.pop();
//          newJoinedSelector = originalSelector.createDerived(utils.copyArray(lastSelector.elements));
//      }
//      else {
//          newJoinedSelector = originalSelector.createDerived([]);
//      }
//
//      if (addPath.length > 0) {
//          // /deep/ is a CSS4 selector - (removed, so should deprecate)
//          // that is valid without anything in front of it
//          // so if the & does not have a combinator that is "" or " " then
//          // and there is a combinator on the parent, then grab that.
//          // this also allows + a { & .b { .a & { ... though not sure why you would want to do that
//          var combinator = replacedElement.combinator, parentEl = addPath[0].elements[0];
//          if (combinator.emptyOrWhitespace && !parentEl.combinator.emptyOrWhitespace) {
//              combinator = parentEl.combinator;
//          }
//          // join the elements so far with the first part of the parent
//          newJoinedSelector.elements.push(new Element(
//              combinator,
//              parentEl.value,
//              replacedElement.isVariable,
//              replacedElement._index,
//              replacedElement._fileInfo
//          ));
//          newJoinedSelector.elements = newJoinedSelector.elements.concat(addPath[0].elements.slice(1));
//      }
//
//      // now add the joined selector - but only if it is not empty
//      if (newJoinedSelector.elements.length !== 0) {
//          newSelectorPath.push(newJoinedSelector);
//      }
//
//      // put together the parent selectors after the join (e.g. the rest of the parent)
//      if (addPath.length > 1) {
//          var restOfPath = addPath.slice(1);
//          restOfPath = restOfPath.map(function (selector) {
//              return selector.createDerived(selector.elements, []);
//          });
//          newSelectorPath = newSelectorPath.concat(restOfPath);
//      }
//      return newSelectorPath;
//  }
  }

  ///
  /// joins selector path from `beginningPath` with every selector path in `addPaths` array
  /// `replacedElement` contains element that is being replaced by `addPath`
  /// returns array with all concatenated paths
  ///
  List<List<Selector>> addAllReplacementsIntoPath(
      List<List<Selector>>  beginningPath,
      List<Selector>        addPaths,
      Element               replacedElement,
      Selector              originalSelector,
      List<List<Selector>>  result) {

    for (int j = 0; j < beginningPath.length; j++) {
      final List<Selector> newSelectorPath = addReplacementIntoPath(
          beginningPath[j], addPaths, replacedElement, originalSelector);
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
    if (elements.isEmpty) return;

    if (selectors.isEmpty) {
      selectors.add(<Selector>[new Selector(elements)]);
      return;
    }

    selectors.forEach((List<Selector> sel) {
      // if the previous thing in sel is a parent this needs to join on to it
      if (sel.isNotEmpty) {
        sel[sel.length - 1] = sel[sel.length - 1] //last
            .createDerived(sel.last.elements.sublist(0)..addAll(elements));
      } else {
        sel.add(new Selector(elements));
      }
    });

//3.0.0 20160716
// function mergeElementsOnToSelectors(elements, selectors) {
//     var i, sel;
//
//     if (elements.length === 0) {
//         return ;
//     }
//     if (selectors.length === 0) {
//         selectors.push([ new Selector(elements) ]);
//         return;
//     }
//
//     for (i = 0; (sel = selectors[i]); i++) {
//         // if the previous thing in sel is a parent this needs to join on to it
//         if (sel.length > 0) {
//             sel[sel.length - 1] = sel[sel.length - 1].createDerived(sel[sel.length - 1].elements.concat(elements));
//         }
//         else {
//             sel.push(new Selector(elements));
//         }
//     }
// }
  }

  ///
  Selector deriveSelector(VisibilityInfo visibilityInfo, Selector deriveFrom) =>
      deriveFrom.createDerived(deriveFrom.elements,
          extendList: deriveFrom.extendList,
          evaldCondition: deriveFrom.evaldCondition)
          ..copyVisibilityInfo(visibilityInfo);

// inside joinSelector
//2.5.3 20151120
// function deriveSelector(visibilityInfo, deriveFrom) {
//     var newSelector = deriveFrom.createDerived(deriveFrom.elements, deriveFrom.extendList, deriveFrom.evaldCondition);
//     newSelector.copyVisibilityInfo(visibilityInfo);
//     return newSelector;
// }

  // used by genTree
  @override
  String toString() {
    if (selectors == null) return '';
    return selectors.fold(new StringBuffer(), (StringBuffer sb, Selector selector) {
      if (sb.isNotEmpty) sb.write(', ');
      return sb..write(selector.toString());
    }).toString();
  }

  // -----------------------------------------------------------------------

}

//-----------------------------------------------------------------------
// Ruleset and MixinDefinition shared code
//-----------------------------------------------------------------------

//2.4.0+
//FIXME: following three functions are done like inside media
/// -
abstract class VariableMixin implements Node {
  ///
  FunctionRegistry              functionRegistry;
  ///
  Map<String, List<MixinFound>> _lookups = <String, List<MixinFound>>{};
  ///
  Node                          paren;
  ///
  Map<String, List<Declaration>> _properties; // $properties

  //var                         _rulesets;

  ///
  Map<String, Node>             _variables; // List of Variable Nodes, by @name

  ///
  void resetCache() {
    if (functionRegistry != null) functionRegistry.resetCache();
    //_rulesets = null;
    _variables = null;
    _properties = null;
    _lookups = <String, List<MixinFound>>{};

//3.0.0 20160718
// Ruleset.prototype.resetCache = function () {
//     this._rulesets = null;
//     this._variables = null;
//     this._properties = null;
//     this._lookups = {};
// };
  }

  ///
  /// Returns the variables list if exist, else creates it.
  ///
  Map<String, Node> variables() => _variables ??= (rules == null)
      ? <String, Node>{}
      : rules.fold(<String, Node>{}, (Map<String, Node> hash, Node r) {
          if (r is Declaration && r.variable) hash[r.name] = r;

          // when evaluating variables in an import statement, imports have not been eval'd
          // so we need to go inside import statements.
          // guard against root being a string (in the case of inlined less)
          if (r is Import && r.root != null && r.root is VariableMixin) {
            final Map<String, Node> vars = r.root.variables();
            for (String name in vars.keys) {
              if (vars.containsKey(name)) hash[name] = r.root.variable(name);
            }
          }
          return hash;
        });

// 3.5.0.beta.5 20180702
//  Ruleset.prototype.variables = function () {
//      if (!this._variables) {
//          this._variables = !this.rules ? {} : this.rules.reduce(function (hash, r) {
//              if (r instanceof Declaration && r.variable === true) {
//                  hash[r.name] = r;
//              }
//              // when evaluating variables in an import statement, imports have not been eval'd
//              // so we need to go inside import statements.
//              // guard against root being a string (in the case of inlined less)
//              if (r.type === 'Import' && r.root && r.root.variables) {
//                  var vars = r.root.variables();
//                  for (var name in vars) {
//                      if (vars.hasOwnProperty(name)) {
//                          hash[name] = r.root.variable(name);
//                      }
//                  }
//              }
//              return hash;
//          }, {});
//      }
//      return this._variables;
//  };

///
Map<String, List<Declaration>> properties() => _properties ??= (rules == null)
    ? <String, List<Declaration>>{}
    : rules.fold(<String, List<Declaration>>{}, (Map<String, List<Declaration>> hash, Node r) {
        if (r is Declaration && !r.variable) {
          final String name = (r.name is String) ? r.name : r.name.first.value; // :keyword
          // Properties don't overwrite as they can merge
          if (!hash.containsKey('\$$name')) {
            hash['\$$name'] = <Declaration>[r];
          } else {
            hash['\$$name'].add(r);
          }
        }
        return hash;
      });

//3.0.0 20160718
// Ruleset.prototype.properties = function () {
//     if (!this._properties) {
//         this._properties = !this.rules ? {} : this.rules.reduce(function (hash, r) {
//             if (r instanceof Declaration && r.variable !== true) {
//                 var name = (r.name.length === 1) && (r.name[0] instanceof Keyword) ?
//                     r.name[0].value : r.name;
//                 // Properties don't overwrite as they can merge
//                 if (!hash['$' + name]) {
//                     hash['$' + name] = [ r ];
//                 }
//                 else {
//                     hash['$' + name].push(r);
//                 }
//             }
//             return hash;
//         }, {});
//     }
//     return this._properties;
// };
//

  ///
  /// Returns the Variable Node (@variable = value).
  ///
  Node variable(String name) {
    final Node decl = variables()[name];
    if (decl != null) return parseValue(decl);
    return null;

//3.0.0 20160718
// Ruleset.prototype.variable = function (name) {
//     var decl = this.variables()[name];
//     if (decl) {
//         return this.parseValue(decl);
//     }
// };
}

//2.3.1
//  Ruleset.prototype.variable = function (name) {
//      return this.variables()[name];
//  };

  ///
  List<Declaration> property(String name) {
    final List<Declaration> decl = properties()[name];
    if (decl != null) return parseValue(decl);
    return null;

//3.0.0 20160718
// Ruleset.prototype.property = function (name) {
//     var decl = this.properties()[name];
//     if (decl) {
//         return this.parseValue(decl);
//     }
// };
  }

  ///
  /// toParse = Declaration | List<Declaration>
  ///
  T parseValue<T>(T toParse) {
    if (toParse is Declaration) {
      return transformDeclaration(toParse) as T;
    }

    if (toParse is List<Declaration>) {
      final List<Declaration> nodes = <Declaration>[];
      toParse.forEach((Declaration n) {
        nodes.add(transformDeclaration(n));
      });
      return nodes as T;
    }

    return null;

//3.0.0 20160718
// Ruleset.prototype.parseValue = function(toParse) {
//     var self = this;
//     if (!Array.isArray(toParse)) {
//         return transformDeclaration.call(self, toParse);
//     }
//     else {
//         var nodes = [];
//         toParse.forEach(function(n) {
//             nodes.push(transformDeclaration.call(self, n));
//         });
//         return nodes;
//     }
// };
  }

  ///
  /// Parse all Declaration nodes (used for compression)
  ///
  void parseForCompression() {
    for (int i = 0; i < (rules?.length ?? 0); i++) {
      if (rules[i] is Declaration) {
        rules[i] = transformDeclaration(rules[i]);
      }
    }
  }

  ///
  /// Parse declaration.value
  ///
  /// if ignoreErrors = true, error result do not propagate
  ///
  Declaration transformDeclaration(Declaration decl) {
    if (decl.value is Anonymous && !decl.parsed) {
      if (!decl.value.parsed && decl.value.value is String) {
        final List<dynamic> result = new ParseNode(decl.value.value,
            decl.value.index, decl.currentFileInfo)
            .value();
        if (result != null) {
          decl
            ..value = result[0]
            ..important = result[1] ?? '';
        }
      }
      decl.parsed = true;
    }
    return decl;

//inside parseValue
//3.0.4 20180616
//function transformDeclaration(decl) {
//    if (decl.value instanceof Anonymous && !decl.parsed) {
//        if (typeof decl.value.value === "string") {
//            this.parse.parseNode(
//                decl.value.value,
//                ["value", "important"],
//                decl.value.getIndex(),
//                decl.fileInfo(),
//                function(err, result) {
//                    if (err) {
//                        decl.parsed = true;
//                    }
//                    if (result) {
//                        decl.value = result[0];
//                        decl.important = result[1] || '';
//                        decl.parsed = true;
//                    }
//                });
//        } else {
//            decl.parsed = true;
//        }
//
//        return decl;
//    }
//    else {
//        return decl;
//    }
//}
  }

  ///
  /// Returns a List of MixinDefinition or Ruleset contained in this.rules
  ///
  List<Node> rulesets() {
    if (rules == null) return <Node>[];

    return rules.fold(<Node>[], (List<Node> filtRules, Node rule) {
      if (rule.isRuleset) filtRules.add(rule);
      return filtRules;
    });

//3.0.0 20160716
// Ruleset.prototype.rulesets = function () {
//     if (!this.rules) { return []; }
//
//     var filtRules = [], rules = this.rules,
//         i, rule;
//
//     for (i = 0; (rule = rules[i]); i++) {
//         if (rule.isRuleset) {
//             filtRules.push(rule);
//         }
//     }
//
//     return filtRules;
// };
  }

  ///
  /// Returns the List of Rules that matchs [selector].
  /// The results are cached.
  ///
  /// Function: bool filter(rule)
  ///
  List<MixinFound> find (Selector selector, [VariableMixin self, Function filter]) {
    final String            key = selector.toCSS(null); // ' selector'
    final List<MixinFound>  rules = <MixinFound>[];
    final VariableMixin     _self = self ?? this;

    if (_lookups.containsKey(key)) return _lookups[key];

    rulesets().forEach((Node rule) {//List of MixinDefinition and Ruleset
      if (rule != _self) {
        for (int j = 0; j < rule.selectors.length; j++) {
          final int match = selector.match(rule.selectors[j]); // Selectors matchs number. 0 not match
          if (match > 0) {
            if (selector.elements.length > match) {
              if (filter == null || filter(rule)) {
                final List<MixinFound> foundMixins = (rule as VariableMixin)
                    .find(new Selector(selector.elements.sublist(match)), _self, filter);
                for (int i = 0; i < foundMixins.length; i++) {
                  foundMixins[i].path.add(rule); //2.3.1 MixinDefinition, Ruleset
                }
                rules.addAll(foundMixins);
              }
            } else {
              rules.add(new MixinFound(rule, <Node>[]));
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

///
class MixinFound {
  ///
  Node        rule;
  ///
  List<Node>  path;

  ///
  MixinFound(this.rule, this.path);
}
