library transformer.less;

import 'dart:async';
//import 'dart:math';
import 'package:less_dart/less.dart';

part 'entry_points.dart';
part 'html_transformer.dart';
part 'less_transformer.dart';
part 'transformer_options.dart';

///
const String BUILD_MODE_LESS = 'less';

///
const String BUILD_MODE_DART = 'dart';

///
const String BUILD_MODE_MIXED = 'mixed';

///
class BaseTransformer {
  ///
  String        buildMode;

  /// deliver to barback
  bool          deliverToPipe = true;

  ///
  String        errorMessage = '';

  ///
  String        inputContent;

  ///
  String        inputFile;

  ///
  List<String>  flags;

  ///
  bool          isError = false;

  ///
  String        message;

  ///
  String        messExe = 'lessc ';

  ///
  String        messHead = '[Info from less-dart] ';

  ///
  Function      modifyOptions;

  ///
  String        outputContent;

  ///
  String        outputFile;

  ///
  static Map<String, RegisterItem> register = <String, RegisterItem>{};

  ///
  BaseTransformer(this.inputContent, this.inputFile, this.outputFile,
      this.buildMode, this.modifyOptions);

  /// input file, output file
  bool get isBuildModeLess => buildMode == BUILD_MODE_LESS;

  /// input stdin, output stdout
  bool get isBuildModeDart => buildMode == BUILD_MODE_DART;

  /// input file, output stdout
  bool get isBuildModeMixed => buildMode == BUILD_MODE_MIXED;

  ///
  Stopwatch timeInProcess = new Stopwatch();

  ///
  /// check if [inputFile] has changed or need process
  ///
  static bool changed(String inputFile, String inputContent) {
    if (register.containsKey(inputFile)) {
      final RegisterItem reg = register[inputFile];
      if (reg.imports.isNotEmpty)
          return true; //Has dependencies
      if (reg.contentHash == inputContent.hashCode)
          return false; //not inputContent changed
    }
    return true;
  }

  ///
  void timerStart() {
    timeInProcess.start();
  }

  ///
  void timerStop() {
    timeInProcess.stop();
  }

  ///
  /// Format the log message
  ///
  void getMessage() {
    final StringBuffer mess = new StringBuffer()
        ..write(messHead);
    if (isError)
        mess.write('ERROR ');
    mess
        ..write(messExe)
        ..write(flags.join(' '))
        ..write(' $inputFile > $outputFile took ')
        ..write(niceDuration(timeInProcess.elapsed));
    message = mess.toString();
  }

  ///
  /// Returns a human-friendly representation of [duration].
  ///
  //from barback - Copyright (c) 2013, the Dart project authors
  String niceDuration(Duration duration) {
    final String result = duration.inMinutes > 0 ? '${duration.inMinutes}:' : '';

    final int s = duration.inSeconds % 59;
    final int ms = (duration.inMilliseconds % 1000) ~/ 100;
    return '$result$s.${ms}s';
  }
}

///
/// Register for last run
///
class RegisterItem {
  /// asset.id.path
  String path;

  /// dependencies path
  List<String> imports;

  /// hash to know if content string has changed
  int contentHash;

  ///
  RegisterItem(this.path, this.imports, this.contentHash);
}

///
/// Less Id for runZoned
///
class GenId {
  ///
  static int k = 1;

  ///
  static int get next => k++;
}
