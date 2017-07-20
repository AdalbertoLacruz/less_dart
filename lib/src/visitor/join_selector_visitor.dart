//source: less/join-selector-visitor.js 2.8.0 20160702

part of visitor.less;

///
class JoinSelectorVisitor extends VisitorBase{
  ///
  List<List<List<Selector>>>  contexts;
  ///
  Visitor                     _visitor;

  ///
  JoinSelectorVisitor() {
    contexts = <List<List<Selector>>>[<List<Selector>>[]];
    _visitor = new Visitor(this);

//2.3.1
//  var JoinSelectorVisitor = function() {
//      this.contexts = [[]];
//      this._visitor = new Visitor(this);
//  };
  }

  ///
  @override
  Ruleset run(Ruleset root) => _visitor.visit(root);

//2.3.1
//  run: function (root) {
//      return this._visitor.visit(root);
//  },

  ///
  void visitDeclaration(Declaration declNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;

//2.8.0 20160702
// visitDeclaration: function (declNode, visitArgs) {
//     visitArgs.visitDeeper = false;
// },
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
    final List<List<Selector>>  context = contexts.last;
    final List<List<Selector>>  paths = <List<Selector>>[];
    List<Selector>              selectors;

    contexts.add(paths);

    if (!rulesetNode.root) {
      selectors = rulesetNode.selectors;
      if (selectors != null) {
        selectors.retainWhere((Selector selector) => selector.getIsOutput());
        rulesetNode.selectors =
            selectors.isNotEmpty ? selectors : (selectors = null);
        if (selectors != null)
            rulesetNode.joinSelectors(paths, context, selectors);
      }
      if (selectors == null)
          rulesetNode.rules = null;
      rulesetNode.paths = paths;
    }

//2.3.1
//  visitRuleset: function (rulesetNode, visitArgs) {
//      var context = this.contexts[this.contexts.length - 1],
//          paths = [], selectors;
//
//      this.contexts.push(paths);
//
//      if (! rulesetNode.root) {
//          selectors = rulesetNode.selectors;
//          if (selectors) {
//              selectors = selectors.filter(function(selector) { return selector.getIsOutput(); });
//              rulesetNode.selectors = selectors.length ? selectors : (selectors = null);
//              if (selectors) { rulesetNode.joinSelectors(paths, context, selectors); }
//          }
//          if (!selectors) { rulesetNode.rules = null; }
//          rulesetNode.paths = paths;
//      }
//  },
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    contexts.removeLast();

//2.3.1
//  visitRulesetOut: function (rulesetNode) {
//      this.contexts.length = this.contexts.length - 1;
//  },
  }

  ///
  void visitMedia(Media mediaNode, VisitArgs visitArgs) {
    final List<List<Selector>> context = contexts.last;
    mediaNode.rules[0].root = (context.isEmpty ||
        (context[0] is Ruleset && (context[0] as Ruleset).multiMedia));

//2.3.1
//  visitMedia: function (mediaNode, visitArgs) {
//      var context = this.contexts[this.contexts.length - 1];
//      mediaNode.rules[0].root = (context.length === 0 || context[0].multiMedia);
//  }
  }

  ///
  void visitAtRule(AtRule atRuleNode, VisitArgs visitArgs) {
    final List<List<Selector>> context = contexts.last;
    if (atRuleNode.rules != null && atRuleNode.rules.isNotEmpty)
        atRuleNode.rules[0].root = (atRuleNode.isRooted || context.isEmpty);

//2.8.0 20160702
// visitAtRule: function (atRuleNode, visitArgs) {
//     var context = this.contexts[this.contexts.length - 1];
//     if (atRuleNode.rules && atRuleNode.rules.length) {
//         atRuleNode.rules[0].root = (atRuleNode.isRooted || context.length === 0 || null);
//     }
// }
  }

  /// func visitor.visit distribuitor
  @override
  Function visitFtn(Node node) {
    if (node is Media)
        return visitMedia;
    if (node is AtRule)
        return visitAtRule;
    if (node is Directive) //compatibility old node type
        return visitAtRule;
    if (node is MixinDefinition)
        return visitMixinDefinition;
    if (node is Declaration)
        return visitDeclaration;
    if (node is Rule) //compatibility old node type
        return visitDeclaration;
    if (node is Ruleset)
        return visitRuleset;
    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) {
    if (node is Ruleset)
        return visitRulesetOut;
    return null;
  }
}
