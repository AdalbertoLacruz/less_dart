// source: less/extend-visitors.js 1.7.5 lines 4-86

part of visitor.less;

class ExtendFinderVisitor extends VisitorBase {
  List<List> allExtendsStack;
  List<List<Selector>> contexts;
  Visitor _visitor;

  bool foundExtends = false;

  ExtendFinderVisitor() {
    this._visitor = new Visitor(this);
    this.contexts = [];
    this.allExtendsStack = [[]];
  }

  ///
  Ruleset run(Ruleset root) {
    root = this._visitor.visit(root);
    root.allExtends = this.allExtendsStack[0];
    return root;
  }

  ///
  void visitRule(Rule ruleNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;
  }

  ///
  void visitMixinDefinition(MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;
  }

  ///
  void visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    if (rulesetNode.root) return;

    int i;
    int j;
    Extend extend;
    List<Node> allSelectorsExtendList = [];
    List<Extend> extendList;

    // get &:extend(.a); rules which apply to all selectors in this ruleset
    List<Node> rules = rulesetNode.rules;
    int ruleCnt = rules != null ? rules.length : 0;
    for (i = 0; i < ruleCnt; i++) {
      if (rulesetNode.rules[i] is Extend) {
        allSelectorsExtendList.add(rules[i]);
        rulesetNode.extendOnEveryPath = true;
      }
    }

    // now find every selector and apply the extends that apply to all extends
    // and the ones which apply to an individual extend
    List<List<Selector>> paths = rulesetNode.paths;
    for (i = 0; i < paths.length; i++) {
      List<Selector> selectorPath = paths[i];
      Selector selector = selectorPath.last;
      List<Node> selExtendList = selector.extendList;

      extendList = selExtendList != null
          ? (selExtendList.sublist(0)..addAll(allSelectorsExtendList))
          : allSelectorsExtendList;

      if (extendList != null) {
        extendList = extendList.map((allSelectorsExtend) {
          return allSelectorsExtend.clone();
        }).toList();
      }

      for (j = 0; j < extendList.length; j++) {
        this.foundExtends = true;
        extend = extendList[j];
        extend.findSelfSelectors(selectorPath);
        extend.ruleset = rulesetNode;
        if (j == 0) extend.firstExtendOnThisSelectorPath = true;
        this.allExtendsStack.last.add(extend);
      }
    }

    this.contexts.add(rulesetNode.selectors);

//        visitRuleset: function (rulesetNode, visitArgs) {
//            if (rulesetNode.root) {
//                return;
//            }
//
//            var i, j, extend, allSelectorsExtendList = [], extendList;
//
//            // get &:extend(.a); rules which apply to all selectors in this ruleset
//            var rules = rulesetNode.rules, ruleCnt = rules ? rules.length : 0;
//            for(i = 0; i < ruleCnt; i++) {
//                if (rulesetNode.rules[i] instanceof tree.Extend) {
//                    allSelectorsExtendList.push(rules[i]);
//                    rulesetNode.extendOnEveryPath = true;
//                }
//            }
//
//            // now find every selector and apply the extends that apply to all extends
//            // and the ones which apply to an individual extend
//            var paths = rulesetNode.paths;
//            for(i = 0; i < paths.length; i++) {
//                var selectorPath = paths[i],
//                    selector = selectorPath[selectorPath.length - 1],
//                    selExtendList = selector.extendList;
//
//                extendList = selExtendList ? selExtendList.slice(0).concat(allSelectorsExtendList)
//                                           : allSelectorsExtendList;
//
//                if (extendList) {
//                    extendList = extendList.map(function(allSelectorsExtend) {
//                        return allSelectorsExtend.clone();
//                    });
//                }
//
//                for(j = 0; j < extendList.length; j++) {
//                    this.foundExtends = true;
//                    extend = extendList[j];
//                    extend.findSelfSelectors(selectorPath);
//                    extend.ruleset = rulesetNode;
//                    if (j === 0) { extend.firstExtendOnThisSelectorPath = true; }
//                    this.allExtendsStack[this.allExtendsStack.length-1].push(extend);
//                }
//            }
//
//            this.contexts.push(rulesetNode.selectors);
//        },
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    if (!rulesetNode.root) this.contexts.removeLast();
  }

  ///
  void visitMedia(Media mediaNode, VisitArgs visitArgs) {
    mediaNode.allExtends = [];
    this.allExtendsStack.add(mediaNode.allExtends);
  }

  ///
  void visitMediaOut(Media mediaNode) {
    this.allExtendsStack.removeLast();
  }

  ///
  void visitDirective(Directive directiveNode, VisitArgs visitArgs) {
    directiveNode.allExtends = [];
    this.allExtendsStack.add(directiveNode.allExtends);
  }

  ///
  void visitDirectiveOut(Directive directiveNode) {
    this.allExtendsStack.removeLast();
  }

  /// func visitor.visit distribuitor
  Function visitFtn(Node node) {
    if (node is Directive)  return this.visitDirective;
    if (node is Media)      return this.visitMedia;
    if (node is MixinDefinition) return this.visitMixinDefinition;
    if (node is Rule)       return this.visitRule;
    if (node is Ruleset)    return this.visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) {
    if (node is Directive)  return this.visitDirectiveOut;
    if (node is Media)      return this.visitMediaOut;
    if (node is Ruleset)    return this.visitRulesetOut;

    return null;
  }
}