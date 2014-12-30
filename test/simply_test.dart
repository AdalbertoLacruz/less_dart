import 'dart:io';
import 'package:less_dart/less.dart';

main() {
  List<String> args = [];
  Less less = new Less();

  args.add('-no-color');
  args.add('--strict-math=on');
  args.add('--strict-units=on');
  args.add('less/charsets.less');
  less.transform(args).then((exitCode){
    stderr.write(less.stderr.toString());
    stdout.writeln('\nstdout:');
    stdout.write(less.stdout.toString());
  });
}