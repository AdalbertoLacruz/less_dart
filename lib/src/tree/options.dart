// Not in original

part of tree.less;

///
/// @options "--flags" directive
///
class Options extends Node {
  @override final String      name = null;
  @override final String      type = 'Options';
  @override covariant Quoted  value;

  List<FunctionBase>  functions;
  int                 index;
  bool                isPlugin;

  ///
  Options(Quoted this.value, this.index, FileInfo currentFileInfo,
      {bool this.isPlugin: false})
      : super.init(currentFileInfo: currentFileInfo);

  ///
  /// Load the options and plugins
  ///
  void apply(Environment environment) {
    final LessOptions lessOptions = environment.options;
    final Logger logger = environment.logger;
    String line = value.value;
    if (isPlugin)
        line = '--plugin=$line';

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

  /// load the plugin functions
  @override
  Options eval(Contexts context) {
    if (context.frames.isNotEmpty) {
      (context.frames[0] as VariableMixin).functionRegistry.add(functions);
      functions = null; //only load once to avoid mixin propagation
    }
    return this;
  }
}
