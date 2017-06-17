///
/// Custom Transformer example
///
/// Copy this file as \lib\transformer.dart and modified it as necessary
/// In pubspec.yaml:
///   transformers:
///   - <application name>
///
/// If you have other transformers:
///   copy this file as \lib\custom\custom_transformer.dart
///   and in pubspec.yaml:
///   transformers:
///   - <application name>\custom\custom_transformer
///
///   Replace <application name> by your application name
///

import 'package:barback/barback.dart';
import 'package:less_dart/transformer.dart';

class MyTransformer extends FileTransformer {

  MyTransformer(BarbackSettings settings):super(settings);

  MyTransformer.asPlugin(BarbackSettings settings): super(settings);

  @override
  void customOptions(LessOptions options) {
    options.definePlugin('myplugin', new MyPlugin()); //use @plugin "myplugin";  directive to load it
  }
}

class MyProcessor extends Processor {
  MyProcessor(PluginOptions options):super(options);

  @override
  String process(String input, Map<String, dynamic> options) =>
      '/* MyPlugin custom transformer post processor */\n$input';
}

class MyPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  MyPlugin(): super();

  @override
  void install(PluginManager pluginManager) {
    final Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
