part of plugins.less;

/// Base clase for Plugin definition
class Plugin {
  Environment environment;
  Logger logger;
  String cmdOptions;
  LessOptions lessOptions;
  bool isLoaded = false; //true after first load

  // Less required minimal version
  List<int> minVersion = [2, 1, 0];

  Plugin(){
    this.environment = new Environment();
    this.logger = environment.logger;
  }

  void init(LessOptions options) {
    this.lessOptions = options;
  }

  ///
  install(PluginManager pluginManager) {}

  ///
  ///Removes " at the start/end
  ///
  String normalizeCommand(String cmdOptions) {
    String command = cmdOptions.startsWith('"') ? cmdOptions.substring(1) : cmdOptions;
    command = command.endsWith('"') ? command.substring(0, command.length - 1) : command;
    return command;
  }

  ///
  void printUsage(){}

  ///
  void printOptions() {}

  ///
  setOptions(cmdOptions) {}
}

// Base class for cmd options
class PluginOptions {

}