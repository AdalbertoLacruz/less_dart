part of batch.test.less;

///
class RemoveProperty extends VisitorBase {
  Visitor _visitor;

  ///
  RemoveProperty() {
    isReplacing = true;
    _visitor = new Visitor(this);
  }

  @override
  Ruleset run(Ruleset root) => _visitor.visit(root);

  ///returns Node | List<Node>
  dynamic visitRule(Rule ruleNode, VisitArgs visitArgs) {
    if (ruleNode.name != '-some-aribitrary-property') {
      return ruleNode;
    } else {
      return <Node>[];
    }
  }

  @override
  Function visitFtn(Node node) {
    if (node is Rule)
        return visitRule;
    return null;
  }

  @override
  Function visitFtnOut(Node node) => null;
}

///
class TestVisitorPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  ///
  TestVisitorPlugin() : super();

  @override
  void install(PluginManager pluginManager) {
    final VisitorBase visitor = new RemoveProperty();
    pluginManager.addVisitor(visitor);
  }
}
