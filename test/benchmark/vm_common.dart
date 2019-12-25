import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'package:path/path.dart' as path;

export 'package:test/test.dart';

///
final String inputPath = _getInputPath();

String _getInputPath() {
  var testRootPath = Platform.environment['TEST_ROOT_PATH'];
  if (testRootPath == null) {
    //testRootPath = path.dirname(Platform.script.path);
    testRootPath = path.dirname(Platform.script.toFilePath());
    var prev = testRootPath;
    while (path.basename(testRootPath) != 'test') {
      testRootPath = path.dirname(testRootPath);
      if (prev == testRootPath) {
        throw Exception(
            'Test root path not detected, Please use TEST_ROOT_PATH');
      }
      prev = testRootPath;
    }
  }
  Logger.root.info('Test root path: "$testRootPath"');
  return testRootPath;
}

///
File getSampleFile(String name) {
  final _name = path.join(inputPath, name).replaceAll(RegExp('\\+'), '\\')
    ..replaceAll(RegExp('/+'), '/').replaceAll('/', Platform.pathSeparator);
  return File(_name);
}

///
String readSampleFile(String name) => getSampleFile(name).readAsStringSync();

///
Future<Object> loadSampleJSON(String name) {
  var _name = name.replaceAll(RegExp('\\+'), '\\')
    ..replaceAll(RegExp('/+'), '/') //?
        .replaceAll('/', Platform.pathSeparator);
  if (_name[0] == Platform.pathSeparator) {
    _name = _name.substring(1);
  }
  return getSampleFile(_name).readAsString().then(json.decode);
}

///
void initTestCommonSetting() {
  //useVMConfiguration();
  _initLog();
}

void _initLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    final msg =
        '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}';
    print(msg);
  });
}
