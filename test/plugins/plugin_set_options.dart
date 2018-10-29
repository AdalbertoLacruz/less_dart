part of batch.test.less;

///
class PluginSetOptions extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  /// first options must be not null
  String anyOptions;

  ///
  String error;

  ///
  int index = 0;

  ///
  String options;

  /// options call sequence, else throws error
  List<String> optionStack = <String>[
    'option1',
    null,
    'option2',
    null,
    'option3'
  ];

  @override
  void install(PluginManager pluginManager) {
    if (anyOptions == null) {
      error = 'setOptions() not called before install';
    }
  }

  @override
  void use() {
    final int index = (this.index++).clamp(0, optionStack.length - 1);
    if (options != optionStack[index]) {
      error = 'setOptions() not setting option $options correctly';
    }

    if (error != null) throw new LessException(error);
  }

  @override
  void setOptions(String cmdOptions) {
    options = cmdOptions;
    anyOptions ??= cmdOptions;
  }
}
