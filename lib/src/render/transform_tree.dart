//source: less/transform.tree.js 2.8.0 20160702

part of render.less;

///
class TransformTree {
  ///
  /// Transform [root] according the visitors
  ///
  Ruleset call(Ruleset root, LessOptions options) {
    Ruleset                 evaldRoot;
    final LessOptions       _options = options ?? new LessOptions();

    final Map<String, Node> variables = _options.variables;
    final Contexts          evalEnv = new Contexts.eval(_options);

    // Allows setting variables with a hash, so:
    //
    // variables = {'my-color': new Color('ff0000')}; will become:
    //
    //   new Declaration('@my-color',
    //     new Value([
    //       new Expression)([
    //         new Color('ff0000')
    //       ])
    //     ])
    //   )
    if (variables != null) {
      final List<Node> vars = <Node>[];

      variables.forEach((String k, Node value) {
        if (value is! Value) {
          if (value is! Expression)
              value = new Expression(<Node>[value]);
          value = new Value(<Node>[value]);
        }
        //vars.add(new Declaration('@' + k, value, null, null, 0));
        vars.add(new Declaration('@$k', value,
            index: 0));
      });
      evalEnv.frames = <Node>[new Ruleset(null, vars)];
    }

    final List<VisitorBase> preEvalVisitors = <VisitorBase>[];
    final List<VisitorBase> visitors = <VisitorBase>[
        new JoinSelectorVisitor(),
        new SetTreeVisibilityVisitor(visible: true), //MarkVisibleSelectorsVisitor(true),
        new ProcessExtendsVisitor(),
        new ToCSSVisitor(new Contexts()
            ..compress = _options.compress
            ..numPrecision = _options.numPrecision)
    ];

    if (_options.pluginManager != null) {
      _options.pluginManager.getVisitors().forEach((VisitorBase pluginVisitor) {
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

    evaldRoot = root.eval(evalEnv);

    for (int i = 0; i < visitors.length; i++) {
      visitors[i].run(evaldRoot);
    }

    return evaldRoot;
  }
}
