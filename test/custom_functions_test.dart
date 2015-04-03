///
/// Example of custom functions definition inside a custom plugin
///
import 'dart:io';
import 'package:less_dart/less.dart';

main() {
  List<String> args = [];
  Less less = new Less();

  args.add('-no-color');
  args.add('less/functions.less');
  less.transform(args, modifyOptions: (LessOptions options){
    options.definePlugin('myplugin', new MyPlugin(), true, '');
  }).then((exitCode){
    stderr.write(less.stderr.toString());
    stdout.writeln('\nstdout:');
    stdout.write(less.stdout.toString());
  });
}

class MyFunctions extends FunctionBase {
  Dimension add(Node a, Node b) {
    return new Dimension(a.value + b.value);
  }

  Dimension increment(Node a) {
    return new Dimension(a.value + 1);
  }

  @defineMethod(name: '_color')
  Color color(Node str) {
    if (str.value == 'evil red') {
      return new Color('600');
    } else {
      return null;
    }
  }
}

class MyProcessor extends Processor {
  MyProcessor(options):super(options);

  String process(String input, Map options) {
      return '/* MyPlugin post processor */\n' + input;
  }
}

class MyPlugin extends Plugin {
  MyPlugin(): super();

  install(PluginManager pluginManager) {
    FunctionBase myFunctions = new MyFunctions();
    pluginManager.addCustomFunctions(myFunctions);

    Processor myProcessor = new MyProcessor(null);
    pluginManager.addPostProcessor(myProcessor);
  }
}