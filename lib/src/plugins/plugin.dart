part of plugins.less;

///
/// Base clase for Plugin definition
///
abstract class Plugin {
  String        cmdOptions;

  Environment   environment;

  bool          isLoaded = false; //true after first load

  LessOptions   lessOptions;

  Logger        logger;

  Plugin() {
    environment = new Environment();
    logger = environment.logger;
  }

  void init(LessOptions options) {
    lessOptions = options;
  }

  ///
  void install(PluginManager pluginManager) {}

  ///
  /// Less required minimal version
  ///
  List<int> get minVersion;

  ///
  ///Removes " at the start/end
  ///
  String normalizeCommand(String cmdOptions) {
    String command = cmdOptions.startsWith('"')
        ? cmdOptions.substring(1)
        : cmdOptions;
    command = command.endsWith('"')
        ? command.substring(0, command.length - 1)
        : command;
    return command;
  }

  ///
  void printUsage() {}

  ///
  void printOptions() {}

  ///
  void setOptions(String cmdOptions) {}
}

///
/// Base class for cmd options
///
class PluginOptions {}
