part of batch.test.less;

///
class PluginGlobalFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-shadow')
  Anonymous testShadow() => new Anonymous('global');

  ///
  @DefineMethod(name: 'test-global')
  Anonymous testGlobal() => new Anonymous('global');
}

///
class PluginLocalFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-shadow')
  Anonymous testShadow() => new Anonymous('local');

  ///
  @DefineMethod(name: 'test-local')
  Anonymous testLocal() => new Anonymous('local');
}

///
class PluginTransitiveFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-transitive')
  Anonymous testTransitive() => new Anonymous('transitive');
}

///
class PluginGlobal extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = new PluginGlobalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginLocal extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = new PluginLocalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginTransitive extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = new PluginTransitiveFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}
