// Not in original

part of visitor.less;

///
/// Visitor to run after parse input file, before imports
///
class IgnitionVisitor extends VisitorBase {
  ///
  Contexts    context;
  ///
  Environment environment;
  ///
  LessOptions lessOptions;
  ///
  Visitor     _visitor;

  ///
  IgnitionVisitor() {
    isReplacing = true;
    _visitor = new Visitor(this);
    environment = new Environment();
    context = new Contexts.eval();
  }

  ///
  @override
  Ruleset run(Ruleset root) {
    lessOptions = environment.options;
    final PluginManager pluginManager = lessOptions.pluginManager;
    if (pluginManager != null) {
      FunctionRegistry.globalFunctions =
          pluginManager.getCustomFunction().sublist(0);
      pluginManager.resetCustomFunction();
    }

    return _visitor.visit(root);
  }

  ///
  /// Load options and remove directive
  /// Associate plugin functions with paren node
  ///
  Options visitOptions(Options optionsNode, VisitArgs visitArgs) {
    optionsNode.apply(environment);

    final PluginManager pluginManager = lessOptions.pluginManager; //could vary from pluginManager used in run
    if (pluginManager != null) {
      optionsNode.functions = pluginManager.getCustomFunction().sublist(0);
      pluginManager.resetCustomFunction();
      return optionsNode; //we need eval and load the functions
    }

    return null;
  }

  @override
  Function visitFtn(Node node) {
    if (node is Options)
        return visitOptions;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) => null;
}
