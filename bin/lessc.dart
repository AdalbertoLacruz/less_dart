import 'dart:async';
import 'dart:io';
import 'package:less_dart/less.dart';

Future<Null> main(List<String> args) {
  final Less less = new Less();

  //TODO stdin

  return less.transform(args).then((int lessExitCode){
    stderr.write(less.stderr);
    stdout.write(less.stdout);
    exitCode = lessExitCode;
    });
}
