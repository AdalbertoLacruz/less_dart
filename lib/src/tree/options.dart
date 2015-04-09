// Not in original

part of tree.less;

///
/// @options "--flags" directive
///
class Options extends Node {
  Quoted    value;
  int       index;
  FileInfo  currentFileInfo;
  bool      isPlugin;
  List<FunctionBase> functions;

  final String type = 'Options';

  Options(this.value, this.index, this.currentFileInfo, {bool this.isPlugin: false});

  /// Load the options and plugins
  void apply(Environment environment) {
    LessOptions lessOptions = environment.options;
    Logger logger = environment.logger;
    String line = value.value;
    if (isPlugin) line = '--plugin=' + line;

    logger.captureStart();
    bool result = lessOptions.fromCommandLine(line);
    String capture = logger.captureStop();
    if (capture.isNotEmpty) capture = capture.split('\n').first;

    if (!result) {
      LessError error = new LessError(
          message: 'bad options (${capture})',
          index: index,
          filename: currentFileInfo.filename);
       throw new LessExceptionError(error);
    }

    if (isPlugin) {
      if(lessOptions.pluginManager == null) {
        lessOptions.pluginLoader.start();
      } else {
        // we have added the last plugin, but it not in pluginManager
        lessOptions.pluginManager.addPlugin(lessOptions.plugins.last);
      }
    }
  }

  /// load the plugin functions
  @override
  Options eval(Contexts context){
    if (context.frames.isNotEmpty) {
      (context.frames[0] as VariableMixin).functionRegistry.add(functions);
      functions = null; //only load once to avoid mixin propagation
    }
    return this;
  }
}
