import 'dart:io';
import 'package:less_dart/less.dart';

// Test toTree, to show a less tree
// use: pub run test/to_tree_test.dart output.txt
void main(List<String> args) {
    final less = Less();
    less.transform(<String>[
      '-no-color',
      '--math=always',
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
        File(args[0])
            ..createSync(recursive: true)
            ..writeAsStringSync(less.stdout.toString());
      }
      exitCode = lessExitCode;
    });
}
