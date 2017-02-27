// source: less/extend-visitor.js 2.5.0 lines 13-89

part of visitor.less;

class ExtendFinderVisitor extends VisitorBase {
  List<List<Extend>> allExtendsStack;
  List<List<Selector>> contexts;
  Visitor _visitor;

  bool foundExtends = false;

  ///
  ExtendFinderVisitor() {
    _visitor = new Visitor(this);
    contexts = [];
    allExtendsStack = [[]];

//2.3.1
//  var ExtendFinderVisitor = function() {
//      this._visitor = new Visitor(this);
//      this.contexts = [];
//      this.allExtendsStack = [[]];
//  };
  }

  ///
  Ruleset run(Ruleset root) {
    root = _visitor.visit(root);
    root.allExtends = allExtendsStack[0];
    return root;

//2.3.1
//  run: function (root) {
//      root = this._visitor.visit(root);
//      root.allExtends = this.allExtendsStack[0];
//      return root;
//  },
  }

  ///
  void visitRule(Rule ruleNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;

//2.3.1
//  visitRule: function (ruleNode, visitArgs) {
//      visitArgs.visitDeeper = false;
//  },
  }

  ///
  void visitMixinDefinition(MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;

//2.3.1
//  visitMixinDefinition: function (mixinDefinitionNode, visitArgs) {
//      visitArgs.visitDeeper = false;
//  },
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
        foundExtends = true;
        extend = extendList[j];
        extend.findSelfSelectors(selectorPath);
        extend.ruleset = rulesetNode;
        if (j == 0) extend.firstExtendOnThisSelectorPath = true;
        allExtendsStack.last.add(extend);
      }
    }

    contexts.add(rulesetNode.selectors);

//2.3.1
//  visitRuleset: function (rulesetNode, visitArgs) {
//      if (rulesetNode.root) {
//          return;
//      }
//
//      var i, j, extend, allSelectorsExtendList = [], extendList;
//
//      // get &:extend(.a); rules which apply to all selectors in this ruleset
//      var rules = rulesetNode.rules, ruleCnt = rules ? rules.length : 0;
//      for(i = 0; i < ruleCnt; i++) {
//          if (rulesetNode.rules[i] instanceof tree.Extend) {
//              allSelectorsExtendList.push(rules[i]);
//              rulesetNode.extendOnEveryPath = true;
//          }
//      }
//
//      // now find every selector and apply the extends that apply to all extends
//      // and the ones which apply to an individual extend
//      var paths = rulesetNode.paths;
//      for(i = 0; i < paths.length; i++) {
//          var selectorPath = paths[i],
//              selector = selectorPath[selectorPath.length - 1],
//              selExtendList = selector.extendList;
//
//          extendList = selExtendList ? selExtendList.slice(0).concat(allSelectorsExtendList)
//                                     : allSelectorsExtendList;
//
//          if (extendList) {
//              extendList = extendList.map(function(allSelectorsExtend) {
//                  return allSelectorsExtend.clone();
//              });
//          }
//
//          for(j = 0; j < extendList.length; j++) {
//              this.foundExtends = true;
//              extend = extendList[j];
//              extend.findSelfSelectors(selectorPath);
//              extend.ruleset = rulesetNode;
//              if (j === 0) { extend.firstExtendOnThisSelectorPath = true; }
//              this.allExtendsStack[this.allExtendsStack.length - 1].push(extend);
//          }
//      }
//
//      this.contexts.push(rulesetNode.selectors);
//  },
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
    mediaNode.allExtends = [];
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
  void visitDirective(Directive directiveNode, VisitArgs visitArgs) {
    directiveNode.allExtends = [];
    allExtendsStack.add(directiveNode.allExtends);

//2.3.1
//  visitDirective: function (directiveNode, visitArgs) {
//      directiveNode.allExtends = [];
//      this.allExtendsStack.push(directiveNode.allExtends);
//  },
  }

  ///
  void visitDirectiveOut(Directive directiveNode) {
    allExtendsStack.removeLast();

//2.3.1
//  visitDirectiveOut: function (directiveNode) {
//      this.allExtendsStack.length = this.allExtendsStack.length - 1;
//  }
  }

  /// func visitor.visit distribuitor
  Function visitFtn(Node node) {
    if (node is Media)      return visitMedia; //before Directive
    if (node is Directive)  return visitDirective;
    if (node is MixinDefinition) return visitMixinDefinition;
    if (node is Rule)       return visitRule;
    if (node is Ruleset)    return visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) {
    if (node is Media)      return visitMediaOut; //before Directive
    if (node is Directive)  return visitDirectiveOut;
    if (node is Ruleset)    return visitRulesetOut;

    return null;
  }
}
