import 'dart:io';
import 'package:less_dart/less.dart';

void main() {
    final Less less = new Less();
    less.transform(<String>[
      '-no-color',
      '--strict-math=on'
      '--strict-units=on',
      'test/less/detached-rulesets.less'
    ]).then((int lessExitCode) {
      stderr.write(less.stderr.toString());
      stdout.writeln('\nstdout:');
      stdout.write(less.stdout.toString());
      exitCode = lessExitCode;
    });
}
