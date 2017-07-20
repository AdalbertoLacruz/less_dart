// Not in original

part of tree.less;

///
/// @options "--flags" directive
/// @plugin (args) "plugin-name"
///
class Options extends Node {
  @override final String      name = null;
  @override final String      type = 'Options';
  @override covariant Quoted  value;

  /// args in  `@plugin (args) "lib"`;
  String              pluginArgs;
  ///
  List<FunctionBase>  functions;
  ///
  bool                isPlugin;

  ///
  Options(Quoted this.value, int index, FileInfo currentFileInfo,
      {bool this.isPlugin: false, String this.pluginArgs})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
        allowRoot = true;
      }

  ///
  /// Load the options and plugins
  ///
  void apply(Environment environment) {
    final LessOptions lessOptions = environment.options;
    final Logger logger = environment.logger;
    String line = value.value;
    if (isPlugin) {
      line = '--plugin=$line';
      if (pluginArgs != null)
          line = '$line=$pluginArgs';
    }


    logger.captureStart();
    final bool result = lessOptions.fromCommandLine(line);
    String capture = logger.captureStop();
    if (capture.isNotEmpty)
        capture = capture.split('\n').first;

    if (!result) {
      throw new LessExceptionError(new LessError(
          message: 'bad options ($capture)',
          index: index,
          filename: currentFileInfo.filename));
    }

    if (isPlugin) {
      if (lessOptions.pluginManager == null) {
        lessOptions.pluginLoader.start();
      } else {
        // we have added the last plugin, but it is not in pluginManager
        lessOptions.pluginManager.addPlugin(lessOptions.plugins.last);
      }
    }
  }

  ///
  /// Load the plugin functions
  ///
  @override
  Options eval(Contexts context) {
    if (context.frames.isNotEmpty) {
      (context.frames[0] as VariableMixin).functionRegistry.add(functions);
      functions = null; //only load once to avoid mixin propagation
    }
    return this;
  }
}
