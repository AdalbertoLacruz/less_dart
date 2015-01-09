//source: less/join-selector-visitor.js 1.7.5

part of visitor.less;

class JoinSelectorVisitor extends VisitorBase{
  List contexts;
  Visitor _visitor;

  JoinSelectorVisitor() {
    this.contexts = [[]];
    this._visitor = new Visitor(this);
  }

  ///
  Node run(Node root) => this._visitor.visit(root);

  ///
  void visitRule(Rule ruleNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;
  }

  ///
  void visitMixinDefinition(MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;
  }

  void visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    List context = this.contexts.last;
    List paths = [];
    List<Node> selectors;

    this.contexts.add(paths);

    if (!rulesetNode.root) {
      selectors = rulesetNode.selectors;
      if (selectors != null) {
        selectors.retainWhere((selector) => selector.getIsOutput());
        rulesetNode.selectors = selectors.isNotEmpty ? selectors : (selectors = null); //TODO is necessary?
        if (selectors != null) rulesetNode.joinSelectors(paths, context, selectors);
      }
      if (selectors == null) rulesetNode.rules = null;
      rulesetNode.paths = paths;
    }

//       visitRuleset: function (rulesetNode, visitArgs) {
//           var context = this.contexts[this.contexts.length - 1],
//               paths = [], selectors;
//
//           this.contexts.push(paths);
//
//           if (! rulesetNode.root) {
//               selectors = rulesetNode.selectors;
//               if (selectors) {
//                   selectors = selectors.filter(function(selector) { return selector.getIsOutput(); });
//                   rulesetNode.selectors = selectors.length ? selectors : (selectors = null);
//                   if (selectors) { rulesetNode.joinSelectors(paths, context, selectors); }
//               }
//               if (!selectors) { rulesetNode.rules = null; }
//               rulesetNode.paths = paths;
//           }
//       },
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    this.contexts.removeLast();
  }

  ///
  void visitMedia(Media mediaNode, VisitArgs visitArgs) {
    List context = this.contexts.last;
    (mediaNode.rules[0] as Ruleset).root = (context.isEmpty || (context[0] is Ruleset && (context[0] as Ruleset).multiMedia));

//       visitMedia: function (mediaNode, visitArgs) {
//           var context = this.contexts[this.contexts.length - 1];
//           mediaNode.rules[0].root = (context.length === 0 || context[0].multiMedia);
//       }
  }

  /// func visitor.visit distribuitor
  Function visitFtn(Node node) {
    if (node is Media) return this.visitMedia;
    if (node is MixinDefinition) return this.visitMixinDefinition;
    if (node is Rule) return this.visitRule;
    if (node is Ruleset) return this.visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) {
    if (node is Ruleset) return this.visitRulesetOut;

    return null;
  }
}