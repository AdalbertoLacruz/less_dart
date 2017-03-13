///
/// Example of custom functions definition inside a custom plugin
///
import 'dart:io';
import 'package:less_dart/less.dart';

import 'package:test/test.dart';

void main() {
  test('Transform test/less/functions.less with plugin', () async {
    final Less less = new Less();
    final int exitCode = await less.transform(<String>[
      '-no-color',
      'test/less/functions.less',
    ], modifyOptions: (LessOptions options) {
      options.definePlugin('myplugin', new MyPlugin(), true, '');
    });
    if (exitCode != 0) {
      stderr.write(less.stderr.toString());
      stdout.write(less.stdout.toString());
    }
    expect(exitCode, 0);
  });
}

class MyFunctions extends FunctionBase {
  Dimension add(Node a, Node b) {
    return new Dimension(a.value + b.value);
  }

  Dimension increment(Node a) {
    return new Dimension(a.value + 1);
  }

  @DefineMethod(name: '_color')
  Color color(Node str) {
    if (str.value == 'evil red') {
      return new Color('600');
    } else {
      return null;
    }
  }
}

class MyProcessor extends Processor {
  MyProcessor(PluginOptions options):super(options);

  @override
  String process(String input, Map<String, dynamic> options) {
      return '/* MyPlugin post processor */\n' + input;
  }
}

class MyPlugin extends Plugin {
  @override List<int> minVersion = <int>[2, 1, 0];

  MyPlugin(): super();

  @override
  void install(PluginManager pluginManager) {
    FunctionBase myFunctions = new MyFunctions();
    pluginManager.addCustomFunctions(myFunctions);

    Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}
