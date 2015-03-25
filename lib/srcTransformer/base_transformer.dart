library transformer.less;

import 'dart:async';
import 'dart:math';
import 'package:less_dart/less.dart';

part 'entry_points.dart';
part 'html_transformer.dart';
part 'less_transformer.dart';
part 'transformer_options.dart';

const String BUILD_MODE_LESS = 'less';
const String BUILD_MODE_DART = 'dart';
const String BUILD_MODE_MIXED = 'mixed';

class BaseTransformer {
  String inputFile;
  String outputFile;
  String inputContent;
  String outputContent;

  List<String> flags;
  String buildMode;

  String messHead = '[Info from less-dart] ';
  String messExe = 'lessc ';
  String message;

  bool isError = false;
  String errorMessage = '';
  bool deliverToPipe = true; // deliver to barback
  static Map<String, RegisterItem> register = {};


  bool get isBuildModeLess => buildMode == BUILD_MODE_LESS;   //input file, output file
  bool get isBuildModeDart => buildMode == BUILD_MODE_DART;   //input stdin, output stdout
  bool get isBuildModeMixed => buildMode == BUILD_MODE_MIXED; //input file, output stdout

  Stopwatch timeInProcess = new Stopwatch();

  BaseTransformer(this.inputContent, this.inputFile, this.outputFile, this.buildMode);

  ///
  /// check if [inputFile] has changed or need process
  ///
  static bool changed(String inputFile, String inputContent) {
    if (register.containsKey(inputFile)) {
      RegisterItem reg = register[inputFile];
      if (reg.imports.isNotEmpty) return true; //Has dependencies
      if (reg.contentHash == inputContent.hashCode) return false; //not inputContent changed
    }
    return true;
  }

  void timerStart() {
    timeInProcess.start();
  }

  void timerStop() {
    timeInProcess.stop();
  }

  ///
  /// Format the log message
  ///
  getMessage(){
    message = messHead;
    if (isError) message += 'ERROR ';
    message += messExe;
    message += flags.join(' ') + ' ';
    message += inputFile + ' > ';
    message += outputFile + ' ';
    message += 'took ' + niceDuration(timeInProcess.elapsed);
  }

  ///
  /// Returns a human-friendly representation of [duration].
  ///
  //from barback - Copyright (c) 2013, the Dart project authors
  String niceDuration(Duration duration) {
  var result = duration.inMinutes > 0 ? "${duration.inMinutes}:" : "";

  var s = duration.inSeconds % 59;
  var ms = (duration.inMilliseconds % 1000) ~/ 100;
  return result + "$s.${ms}s";
  }
}

///
/// Register for last run
class RegisterItem {
  String path; // asset.id.path
  List<String> imports; // dependencies path
  int contentHash; //hash to know if content string has changed
  RegisterItem(this.path, this.imports, this.contentHash);
}