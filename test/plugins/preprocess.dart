part of batch.test.less;

///
class TestPreProcessor extends Processor {
  ///
  TestPreProcessor(PluginOptions options) : super(options);

  @override
  String process(String src, Map<String, dynamic> options) {
    final String injected = '@color: red;\n';
    final Map<String, int> ignored = options['imports'].contentsIgnoredChars;
    final FileInfo fileInfo = options['fileInfo'];
    if (ignored[fileInfo.filename] == null) ignored[fileInfo.filename] = 0;
    ignored[fileInfo.filename] += injected.length;

    return '$injected$src';
  }
}

///
class TestPreProcessorPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  ///
  TestPreProcessorPlugin() : super();

  @override
  void install(PluginManager pluginManager) {
    final Processor processor = TestPreProcessor(null);
    pluginManager.addPreProcessor(processor);
  }

  @override
  void setOptions(String cmdOptions) {}
}
