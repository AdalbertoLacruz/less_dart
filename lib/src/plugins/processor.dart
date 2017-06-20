part of plugins.less;

///
/// Base class for plugin PreProcessors and PostProcessors
///
class Processor {
  ///
  PluginOptions pluginOptions;

  ///
  Processor(this.pluginOptions);

  ///
  /// Do the work
  /// [input] contents to process
  /// [options] Map
  ///
  String process(String input, Map<String, dynamic> options) => input;
}
