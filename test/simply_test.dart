import 'dart:io';
import 'package:less_dart/less.dart';
import 'package:test/test.dart';

main() {
  test('Transform less/charsets.less', () async {
    final Less less = new Less();
    final exitCode = await less.transform([
      '-no-color',
      '--strict-math=on'
      '--strict-units=on',
      'test/less/charsets.less'
    ]);
    if (exitCode != 0) {
      stderr.write(less.stderr.toString());
      stdout.write(less.stdout.toString());
    }
    expect(exitCode, 0);
  });
}