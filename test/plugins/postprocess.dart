part of batch.test.less;

///
class TestPostProcessor extends Processor {
  ///
  TestPostProcessor(PluginOptions options) : super(options);

  @override
  String process(String css, Map<String, dynamic> options) =>
      'hr {height:50px;}\n$css';
}

///
class TestPostProcessorPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  ///
  TestPostProcessorPlugin() : super();

  @override
  void install(PluginManager pluginManager) {
    final Processor processor = new TestPostProcessor(null);
    pluginManager.addPostProcessor(processor);
  }
}
