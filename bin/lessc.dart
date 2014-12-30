import 'dart:io';
import 'package:less_dart/less.dart';

main(List<String> args) {
  Less less = new Less();
  
  //TODO stdin
  
  return less.transform(args).then((exitCode){
    stderr.write(less.stderr);
    stdout.write(less.stdout);
    return exitCode;
    });
}