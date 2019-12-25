///
/// Example of custom functions definition inside a custom plugin
///
/// Usage: pub run example/custom_functions_example.dart
///
import 'dart:io';
import 'package:less_dart/less.dart';

void main() {
  final less = Less();

  less.transform(<String>[
    '-no-color',
    'test/less/functions.less',
  ], modifyOptions: (LessOptions options) {
    options.definePlugin('myplugin', MyPlugin(), load: true, options: '');
  }).then((int exitCode) {
    stderr
      ..write(less.stderr.toString())
      ..writeln('\nstdout:')
      ..write(less.stdout.toString());
  });
}

///
class MyFunctions extends FunctionBase {
  ///
  Dimension add(Node a, Node b) => Dimension(a.value + b.value);

  ///
  Dimension increment(Node a) => Dimension(a.value + 1);

  ///
  @DefineMethod(name: '_color')
  Color color(Node str) => (str.value == 'evil red') ? Color('600') : null;
}

///
class MyProcessor extends Processor {
  ///
  MyProcessor(PluginOptions options) : super(options);

  @override
  String process(String input, Map<String, dynamic> options) =>
      '/* MyPlugin post processor */\n$input';
}

///
class MyPlugin extends Plugin {
  @override
  List<int> minVersion = <int>[2, 1, 0];

  ///
  MyPlugin() : super();

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase myFunctions = MyFunctions();
    pluginManager.addCustomFunctions(myFunctions);

    final Processor myProcessor = MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
