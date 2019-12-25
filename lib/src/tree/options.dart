// Not in original

part of tree.less;

///
/// @options "--flags" directive
/// @plugin (args) "plugin-name"
///
class Options extends Node {
  @override
  final String name = null;

  @override
  final String type = 'Options';

  @override
  covariant Quoted value;

  /// args in  `@plugin (args) "lib"`;
  String pluginArgs;

  ///
  List<FunctionBase> functions;

  ///
  bool isPlugin;

  ///
  Options(this.value, int index, FileInfo currentFileInfo,
      {this.isPlugin = false, this.pluginArgs})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    allowRoot = true;
  }

  ///
  /// Load the options and plugins
  ///
  void apply(Environment environment) {
    final lessOptions = environment.options;
    final logger = environment.logger;
    var line = value.value;
    if (isPlugin) {
      line = '--plugin=$line';
      if (pluginArgs != null) line = '$line=$pluginArgs';
    }

    logger.captureStart();
    final result = lessOptions.fromCommandLine(line);
    var capture = logger.captureStop();
    if (capture.isNotEmpty) capture = capture.split('\n').first;

    if (!result) {
      throw LessExceptionError(LessError(
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
