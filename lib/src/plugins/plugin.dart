part of plugins.less;

///
/// Base clase for Plugin definition
///
abstract class Plugin {
  ///
  String        cmdOptions;
  ///
  Environment   environment;
  ///
  bool          isLoaded = false; //true after first load
  ///
  LessOptions   lessOptions;
  ///
  Logger        logger;
  /// Plugin name
  String        name;

  ///
  Plugin() {
    environment = new Environment();
    logger = environment.logger;
  }

  ///
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
  /// Removes " at the start/end
  ///
  String normalizeCommand(String cmdOptions) {
    if (cmdOptions == null) return null;

    final String command = cmdOptions.startsWith('"')
        ? cmdOptions.substring(1)
        : cmdOptions;

    return command.endsWith('"')
        ? command.substring(0, command.length - 1)
        : command;
  }

  ///
  void printUsage() {}

  ///
  void printOptions() {}

  ///
  /// To be override
  /// If the plugin receives options throw an error
  ///
  void setOptions(String cmdOptions) {
    if (cmdOptions != null) {
      throw new LessException('Options have been provided but the plugin $name does not support any options.');
    }
  }

  /// Called after setOptions
  void use() {}
}

///
/// Base class for cmd options
///
class PluginOptions {}
