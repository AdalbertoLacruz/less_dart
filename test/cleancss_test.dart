import 'dart:io';
import 'package:less_dart/less.dart';

import 'package:test/test.dart';

void main() {
  test('Transform test/less/cleancss/main-ie8.less with --clean-css', () async {
    final Less less = Less();
    final int exitCode = await less.transform(<String>[
      '--no-color',
      '--clean-css="compatibility=ie8"',
      'test/less/cleancss/main-ie8.less',
    ]);
    if (exitCode != 0) {
      stderr.write(less.stderr.toString());
      stdout.write(less.stdout.toString());
    }
    expect(exitCode, 0);
  });
}
