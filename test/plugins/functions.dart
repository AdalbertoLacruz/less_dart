part of batch.test.less;

///
class PluginGlobalFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-shadow')
  Anonymous testShadow() => Anonymous('global');

  ///
  @DefineMethod(name: 'test-global')
  Anonymous testGlobal() => Anonymous('global');
}

///
class PluginLocalFunctions extends FunctionBase {
  ///
  PluginLocalFunctions();

  /// Supports plugin arguments in the function
  @DefineMethod(name: 'test-shadow')
   Anonymous testShadow() => Anonymous('local');

  ///
  @DefineMethod(name: 'test-local')
  Anonymous testLocal() => Anonymous('local');
}

///
class PluginTransitiveFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'test-transitive')
  Anonymous testTransitive() => Anonymous('transitive');
}

///
class PluginSimpleFunctions extends FunctionBase {
  ///
  @DefineMethod(name: 'pi-anon')
  double piAnon() => math.pi;
  ///
  @DefineMethod(name: 'pif')
  Dimension pif() => Dimension(math.pi);
}

///
class PluginScope1Functions extends FunctionBase {
  ///
  @DefineMethod(name: 'foo')
  String foo() => 'foo';
}

///
class PluginScope2Functions extends FunctionBase {
  ///
  @DefineMethod(name: 'foo')
  String foo() => 'bar';
}

///
class PluginCollectionFunctions extends FunctionBase {
  ///
  List<Node> collection = <Node>[];

  ///
  @DefineMethod(name: 'store')
  bool store(Node val){
    collection.add(val);
    return false;
  }
  ///
  @DefineMethod(name: 'list')
  Value list() => less.value(collection);
}

///
class PluginGlobal extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginGlobalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginLocal extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginLocalFunctions();
    pluginManager.addCustomFunctions(fun);
  }

  @override
  void setOptions(String cmdOptions) {
    // do nothing
  }
}

///
class PluginTransitive extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginTransitiveFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginSimple extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginSimpleFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginScope1 extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginScope1Functions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginScope2 extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginScope2Functions();
    pluginManager.addCustomFunctions(fun);
  }
}

///
class PluginCollection extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase fun = PluginCollectionFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}
