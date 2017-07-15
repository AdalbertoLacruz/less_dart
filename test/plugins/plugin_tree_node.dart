// source: test/less/plugin/plugin-tree-node.js 2.6.1 20160305

part of batch.test.less;

///
class AddMultipleFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-comment')
  Combinator testComment() => new Combinator(' ');

  ///
  @DefineMethod(name: 'test-directive')
  Directive testDirective(Node arg1, Node arg2) =>
      new Directive(arg1.value, new Anonymous(arg2.value), null, null, null, null);

  ///
  @DefineMethod(name: 'test-extend')
  Extend testExtend() => null; //TODO

  ///
  @DefineMethod(name: 'test-import')
  Import testImport() => null; //TODO

  ///
  @DefineMethod(name: 'test-media')
  Media testMedia() => null; //TODO

  ///
  @DefineMethod(name: 'test-mixin-call')
  MixinCall testMixinCall() => null; //TODO

  ///
  @DefineMethod(name: 'test-mixin-definition')
  MixinDefinition testMixinDefinition() => null; //TODO

  ///
  @DefineMethod(name: 'test-ruleset-call')
  Combinator testRulesetCall() => new Combinator(' ');

  // Functions must return something. Must 'return true' if they produce no output.
  ///
  @DefineMethod(name: 'test-undefined')
  Node testUndefined() => null;

  // These cause root errors

  ///
  @DefineMethod(name: 'test-alpha')
  Alpha testAlpha() => new Alpha(30);

  ///
  @DefineMethod(name: 'test-assignment')
  Assignment testAssignment() => new Assignment('bird', new Keyword('robin'));

  ///
  @DefineMethod(name: 'test-attribute')
  Attribute testAttribute() => new Attribute('foo', '=', 'bar');

  ///
  @DefineMethod(name: 'test-call')
  Call testCall() => new Call('foo', <Node>[], null, null);

  ///
  @DefineMethod(name: 'test-color')
  Color testColor() => new Color(<int>[50, 50, 50]);

  ///
  @DefineMethod(name: 'test-condition')
  Condition testCondition() => new Condition(
      '<',
      new Value(<Node>[new Quoted('', '0')]),
      new Value(<Node>[new Quoted('', '1')]));

  ///
  @DefineMethod(name: 'test-detached-ruleset')
  DetachedRuleset testDetachedRuleset() {
    final Rule rule = new Rule('prop', new Anonymous('value'));
    return new DetachedRuleset(new Ruleset(null, <Node>[rule]));
  }

  ///
  @DefineMethod(name: 'test-dimension')
  Dimension testDimension() => new Dimension(1, 'px');

  ///
  @DefineMethod(name: 'test-element')
  Element testElement() => new Element('+', 'a', null, null);

  ///
  @DefineMethod(name: 'test-expression')
  Expression testExpression() => new Expression(<Node>[
      new Anonymous(1),
      new Anonymous(2),
      new Anonymous(3)
    ]);

  ///
  @DefineMethod(name: 'test-keyword')
  Keyword testKeyword() => new Keyword('foo');

  ///
  @DefineMethod(name: 'test-operation')
  Operation testOperation() => new Operation('+', <Node>[
      new Dimension(1),
      new Dimension(2)
    ]);

  ///
  @DefineMethod(name: 'test-quoted')
  Quoted testQuoted() => new Quoted('"', 'foo');

  ///
  @DefineMethod(name: 'test-selector')
  Selector testSelector() => new Selector(<Element>[
      new Element('', 'a', null, null)
    ]);

  ///
  @DefineMethod(name: 'test-url')
  URL testUrl() => new URL(new Quoted("'", 'http://google.com'));

  ///
  @DefineMethod(name: 'test-value')
  Value testValue() => new Value(<Node>[new Dimension(1)]);
}

///
class PluginTreeNode extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = new AddMultipleFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}
