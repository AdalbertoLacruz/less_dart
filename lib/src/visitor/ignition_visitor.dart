// Not in original

part of visitor.less;

///
/// Visitor to run after parse input file, before imports
///
class IgnitionVisitor extends VisitorBase {
  Environment environment;
  Visitor _visitor;

  Contexts context;
  LessOptions lessOptions;

  IgnitionVisitor() {
    isReplacing = true;
    _visitor = new Visitor(this);
    environment = new Environment();
    context = new Contexts.eval();
  }

  ///
  Ruleset run(Ruleset root) {
    lessOptions = environment.options;
    PluginManager pluginManager = lessOptions.pluginManager;
    if (pluginManager != null) {
      FunctionRegistry.globalFunctions = pluginManager.getCustomFunction().sublist(0);
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

    PluginManager pluginManager = lessOptions.pluginManager; //could vary from pluginManager used in run
    if (pluginManager != null) {
      optionsNode.functions = pluginManager.getCustomFunction().sublist(0);
      pluginManager.resetCustomFunction();
      return optionsNode; //we need eval and load the functions
    }

    return null;
  }

  Function visitFtn(Node node) {
    if (node is Options) return visitOptions;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) {
    return null;
  }
}
