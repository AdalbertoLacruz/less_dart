import 'dart:io';
import 'package:less_dart/less.dart';

void main() {
  final Less less = Less();
  less.transform(<String>[
    '-no-color',
    '--strict-units=on',
    'test/less/colors.less'
  ]).then((int lessExitCode) {
    stderr
      ..write(less.stderr.toString())
      ..writeln('\nstdout:')
      ..write(less.stdout.toString());
    exitCode = lessExitCode;
  });
}
