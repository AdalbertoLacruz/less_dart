///
/// Example of custom functions definition inside a custom plugin
///
/// Usage: pub run test/custom_functions_test.dart
///
import 'dart:io';
import 'package:less_dart/less.dart';

void main() {
  final Less less = new Less();

  less.transform(<String>[
    '-no-color',
    'test/less/functions.less',
  ], modifyOptions: (LessOptions options){
    options.definePlugin('myplugin', new MyPlugin(), load: true, options: '');
  }).then((int exitCode){
    stderr
        ..write(less.stderr.toString())
        ..writeln('\nstdout:')
        ..write(less.stdout.toString());
  });
}

///
class MyFunctions extends FunctionBase {
  ///
  Dimension add(Node a, Node b) => new Dimension(a.value + b.value);
  ///
  Dimension increment(Node a) => new Dimension(a.value + 1);

  ///
  @DefineMethod(name: '_color')
  Color color(Node str) => (str.value == 'evil red') ? new Color('600') : null;
}

///
class MyProcessor extends Processor {
  ///
  MyProcessor(PluginOptions options):super(options);

  @override
  String process(String input, Map<String, dynamic> options) =>
      '/* MyPlugin post processor */\n$input';
}

///
class MyPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  ///
  MyPlugin(): super();

  @override
  void install(PluginManager pluginManager) {
    final FunctionBase myFunctions = new MyFunctions();
    pluginManager.addCustomFunctions(myFunctions);

    final Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
