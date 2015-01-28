import 'dart:io';
import 'package:less_dart/less.dart';

main() {
  List<String> args = [];
  Less less = new Less();

  args.add('-no-color');
  args.add('less/functions.less');
  less.transform(args, modifyOptions: (LessOptions options){
    options.customFunctions = new MyFunctions();
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