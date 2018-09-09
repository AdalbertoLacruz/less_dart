// source: less/extend-visitor.js lines 13-89 3.0.0 20160714

part of visitor.less;

///
class ExtendFinderVisitor extends VisitorBase {
  ///
  List<List<Extend>>    allExtendsStack;
  ///
  List<List<Selector>>  contexts;
  ///
  bool                  foundExtends = false;
  ///
  Visitor               _visitor;

  ///
  ExtendFinderVisitor() {
    _visitor = new Visitor(this);
    contexts = <List<Selector>>[];
    allExtendsStack = <List<Extend>>[<Extend>[]];

//2.3.1
//  var ExtendFinderVisitor = function() {
//      this._visitor = new Visitor(this);
//      this.contexts = [];
//      this.allExtendsStack = [[]];
//  };
  }

  ///
  @override
  Ruleset run(Ruleset root) {
    final Ruleset _root = _visitor.visit(root)
        ..allExtends = allExtendsStack[0];
    return _root;

//2.3.1
//  run: function (root) {
//      root = this._visitor.visit(root);
//      root.allExtends = this.allExtendsStack[0];
//      return root;
//  },
  }

  ///
  void visitDeclaration(Declaration declNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;

//2.8.0 20160702
// visitDeclaration: function (declNode, visitArgs) {
//     visitArgs.visitDeeper = false;
// },
  }

  ///
  void visitMixinDefinition(
      MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;

//2.3.1
//  visitMixinDefinition: function (mixinDefinitionNode, visitArgs) {
//      visitArgs.visitDeeper = false;
//  },
  }

  ///
  void visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    if (rulesetNode.root) return;

    final List<Extend> allSelectorsExtendList = <Extend>[];

    // get &:extend(.a); rules which apply to all selectors in this ruleset
    final List<Node> rules = rulesetNode.rules;
    final int ruleCnt = rules?.length ?? 0;
    for (int i = 0; i < ruleCnt; i++) {
      if (rulesetNode.rules[i] is Extend) {
        allSelectorsExtendList.add(rules[i]);
        rulesetNode.extendOnEveryPath = true;
      }
    }

    // now find every selector and apply the extends that apply to all extends
    // and the ones which apply to an individual extend
    final List<List<Selector>> paths = rulesetNode.paths;
    for (int i = 0; i < paths.length; i++) {
      final List<Selector>  selectorPath = paths[i];
      final Selector        selector = selectorPath.last;
      final List<Extend>    selExtendList = selector.extendList;

      List<Extend> extendList = selExtendList != null
          ? (selExtendList.sublist(0)..addAll(allSelectorsExtendList))
          : allSelectorsExtendList;

      if (extendList != null) {
        extendList = extendList
            .map((Extend allSelectorsExtend) => allSelectorsExtend.clone())
            .toList();
      }

      for (int j = 0; j < extendList.length; j++) {
        foundExtends = true;
        final Extend extend = extendList[j]
            ..findSelfSelectors(selectorPath)
            ..ruleset = rulesetNode;
        if (j == 0) extend.firstExtendOnThisSelectorPath = true;
        allExtendsStack.last.add(extend);
      }
    }

    contexts.add(rulesetNode.selectors);

//3.0.0 20150714
// visitRuleset: function (rulesetNode, visitArgs) {
//     if (rulesetNode.root) {
//         return;
//     }
//
//     var i, j, extend, allSelectorsExtendList = [], extendList;
//
//     // get &:extend(.a); rules which apply to all selectors in this ruleset
//     var rules = rulesetNode.rules, ruleCnt = rules ? rules.length : 0;
//     for (i = 0; i < ruleCnt; i++) {
//         if (rulesetNode.rules[i] instanceof tree.Extend) {
//             allSelectorsExtendList.push(rules[i]);
//             rulesetNode.extendOnEveryPath = true;
//         }
//     }
//
//     // now find every selector and apply the extends that apply to all extends
//     // and the ones which apply to an individual extend
//     var paths = rulesetNode.paths;
//     for (i = 0; i < paths.length; i++) {
//         var selectorPath = paths[i],
//             selector = selectorPath[selectorPath.length - 1],
//             selExtendList = selector.extendList;
//
//         extendList = selExtendList ? utils.copyArray(selExtendList).concat(allSelectorsExtendList)
//                                    : allSelectorsExtendList;
//
//         if (extendList) {
//             extendList = extendList.map(function(allSelectorsExtend) {
//                 return allSelectorsExtend.clone();
//             });
//         }
//
//         for (j = 0; j < extendList.length; j++) {
//             this.foundExtends = true;
//             extend = extendList[j];
//             extend.findSelfSelectors(selectorPath);
//             extend.ruleset = rulesetNode;
//             if (j === 0) { extend.firstExtendOnThisSelectorPath = true; }
//             this.allExtendsStack[this.allExtendsStack.length - 1].push(extend);
//         }
//     }
//
//     this.contexts.push(rulesetNode.selectors);
// },
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    if (!rulesetNode.root) contexts.removeLast();

//2.3.1
//  visitRulesetOut: function (rulesetNode) {
//      if (!rulesetNode.root) {
//          this.contexts.length = this.contexts.length - 1;
//      }
//  },
  }

  ///
  void visitMedia(Media mediaNode, VisitArgs visitArgs) {
    mediaNode.allExtends = <Extend>[];
    allExtendsStack.add(mediaNode.allExtends);

//2.3.1
//  visitMedia: function (mediaNode, visitArgs) {
//      mediaNode.allExtends = [];
//      this.allExtendsStack.push(mediaNode.allExtends);
//  },
  }

  ///
  void visitMediaOut(Media mediaNode) {
    allExtendsStack.removeLast();

//2.3.1
//  visitMediaOut: function (mediaNode) {
//      this.allExtendsStack.length = this.allExtendsStack.length - 1;
//  },
  }

  ///
  void visitAtRule(AtRule atRuleNode, VisitArgs visitArgs) {
    atRuleNode.allExtends = <Extend>[];
    allExtendsStack.add(atRuleNode.allExtends);

//2.8.0 20160702
// visitAtRule: function (atRuleNode, visitArgs) {
//     atRuleNode.allExtends = [];
//     this.allExtendsStack.push(atRuleNode.allExtends);
// },
  }

  ///
  void visitAtRuleOut(AtRule atRuleNode) {
    allExtendsStack.removeLast();

//2.8.0 20160702
// visitAtRuleOut: function (atRuleNode) {
//     this.allExtendsStack.length = this.allExtendsStack.length - 1;
// }
  }

  /// func visitor.visit distribuitor
  @override
  Function visitFtn(Node node) {
    //before AtRule
    if (node is Media) return visitMedia;
    if (node is AtRule) return visitAtRule;
    //compatibility old node type
    if (node is Directive) return visitAtRule;
    if (node is MixinDefinition) return visitMixinDefinition;
    if (node is Declaration) return visitDeclaration;
    //compatibility old node type
    if (node is Rule) return visitDeclaration;
    if (node is Ruleset) return visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) {
    //before Directive
    if (node is Media) return visitMediaOut;
    if (node is AtRule) return visitAtRuleOut;
    //compatibility old node type
    if (node is Directive) return visitAtRuleOut;
    if (node is Ruleset) return visitRulesetOut;

    return null;
  }
}
