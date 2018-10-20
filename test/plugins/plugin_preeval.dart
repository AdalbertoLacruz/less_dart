part of batch.test.less;

///
class VisitorReplace extends VisitorBase {
  Visitor native;

  ///
  VisitorReplace() {
    isReplacing = true;
    isPreEvalVisitor = true;
    native = new Visitor(this);
  }

  @override
  Ruleset run(Ruleset root) => native.visit(root);


  Node visitVariable(Variable node, VisitArgs visitArgs) {
    if (node.name == '@replace') {
      return new Quoted("'", 'bar', escaped: true);
    }
    return node;
  }


  @override
  Function visitFtn(Node node) {
    if (node is Variable) return visitVariable;
    return null;
  }

  @override
  Function visitFtnOut(Node node) => null;
}

///
class PluginPreeval extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  PluginPreeval() : super();

  @override
  void install(PluginManager pluginManager) {
    final VisitorBase visitor = new VisitorReplace();
    pluginManager.addVisitor(visitor);
  }
}
