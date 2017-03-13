//source: less/transform.tree.js 2.5.0

part of render.less;

class TransformTree {
  ///
  /// Transform [root] according the visitors
  ///
  Ruleset call(Ruleset root, LessOptions options) {
    if (options == null) options = new LessOptions();

    Ruleset evaldRoot;
    Map<String, Node> variables = options.variables;
    Contexts evalEnv = new Contexts.eval(options);

    // Allows setting variables with a hash, so:
    //
    // variables = {'my-color': new Color('ff0000')}; will become:
    //
    //   new Rule('@my-color',
    //     new Value([
    //       new Expression)([
    //         new Color('ff0000')
    //       ])
    //     ])
    //   )
    if (variables != null) {
      List<Node> vars = <Node>[];

      variables.forEach((String k, Node value){
        if (value is! Value) {
          if (value is! Expression) value = new Expression(<Node>[value]);
          value = new Value(<Node>[value]);
        }
        vars.add(new Rule('@' + k, value, null, null, 0));
      });
      evalEnv.frames = <Node>[new Ruleset(null, vars)];
    }

    List<VisitorBase> preEvalVisitors = <VisitorBase>[];
    List<VisitorBase> visitors = <VisitorBase>[
                     new JoinSelectorVisitor(),
                     new ProcessExtendsVisitor(),
                     new ToCSSVisitor(new Contexts()
                                        ..compress = options.compress
                                        ..numPrecision = options.numPrecision)
                     ];

    if (options.pluginManager != null) {
      List<VisitorBase> pluginVisitors = options.pluginManager.getVisitors();
      pluginVisitors.forEach((VisitorBase pluginVisitor){
        if (pluginVisitor.isPreEvalVisitor) {
          preEvalVisitors.add(pluginVisitor);
        } else {
          if (pluginVisitor.isPreVisitor) {
            visitors.insert(0, pluginVisitor);
          } else {
            visitors.add(pluginVisitor);
          }
        }
      });
    }

    for (int i = 0; i < preEvalVisitors.length; i++) {
      preEvalVisitors[i].run(root);
    }

    evaldRoot =  root.eval(evalEnv);

    for (int i = 0; i < visitors.length; i++) {
      visitors[i].run(evaldRoot);
    }

    return evaldRoot;
  }
}
