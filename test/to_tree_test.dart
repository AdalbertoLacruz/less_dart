import 'dart:io';
import 'package:less_dart/less.dart';

// Test toTree, to show a less tree
// use: pub run test/to_tree_test.dart output.txt
void main(List<String> args) {
    final Less less = new Less();
    less.transform(<String>[
      '-no-color',
      '--strict-math=on',
      '--strict-units=on',
      '--show-tree-level=0',
      'test/less/tree.less'
    ]).then((int lessExitCode) {
      if (args.isEmpty) {
        stderr
            ..write(less.stderr.toString())
            ..writeln('\nstdout:')
            ..write(less.stdout.toString());
      } else {
        stderr.write(less.stderr.toString());
        new File(args[0])
            ..createSync(recursive: true)
            ..writeAsStringSync(less.stdout.toString());
      }
      exitCode = lessExitCode;
    });
}
