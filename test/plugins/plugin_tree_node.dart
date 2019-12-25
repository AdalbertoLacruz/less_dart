// source: test/less/plugin/plugin-tree-node.js 3.0.0 20160719

part of batch.test.less;

///
class AddMultipleFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-comment')
  Combinator testComment() => less.combinator(' ');

  ///
  @DefineMethod(name: 'test-atrule')
  AtRule testAtrule(Node arg1, Node arg2) => less.atRule(arg1.value, arg2.value);

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
  Combinator testRulesetCall() => less.combinator(' ');

  // Functions must return something, even if it's false/true
  ///
  @DefineMethod(name: 'test-undefined')
  Node testUndefined() => null;

  ///
  @DefineMethod(name: 'test-collapse')
  bool testCollapse() => true;

  // These cause root errors

  ///
  @DefineMethod(name: 'test-assignment')
  Assignment testAssignment() => less.assignment('bird', 'robin');

  ///
  @DefineMethod(name: 'test-attribute')
  Attribute testAttribute() => less.attribute('foo', '=', 'bar');

  ///
  @DefineMethod(name: 'test-call')
  Call testCall() => less.call('foo');

  ///
  @DefineMethod(name: 'test-color')
  Color testColor() => less.color(<int>[50, 50, 50]);

  ///
  @DefineMethod(name: 'test-condition')
  Condition testCondition() => less.condition('<', less.value(0), less.value(1));

  ///
  @DefineMethod(name: 'test-detached-ruleset')
  DetachedRuleset testDetachedRuleset() {
    final decl = less.declaration('prop', 'value');
    return less.detachedRuleset(less.ruleset(null, <Node>[decl]));
  }

  ///
  @DefineMethod(name: 'test-dimension')
  Dimension testDimension() => less.dimension(1, 'px');

  ///
  @DefineMethod(name: 'test-element')
  Element testElement() => less.element('+', 'a');

  ///
  @DefineMethod(name: 'test-expression')
  Expression testExpression() => less.expression(<num>[1, 2, 3]);

  ///
  @DefineMethod(name: 'test-keyword')
  Keyword testKeyword() => less.keyword('foo');

  ///
  @DefineMethod(name: 'test-operation')
  Operation testOperation() => less.operation('+', <num>[1, 2]);

  ///
  @DefineMethod(name: 'test-quoted')
  Quoted testQuoted() => less.quoted('"', 'foo');

  ///
  @DefineMethod(name: 'test-selector')
  Selector testSelector() => less.selector('.a.b');

  ///
  @DefineMethod(name: 'test-url')
  URL testUrl() => less.url('http://google.com');

  ///
  @DefineMethod(name: 'test-value')
  Value testValue() => less.value(1);
}

///
class PluginTreeNode extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = AddMultipleFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}
