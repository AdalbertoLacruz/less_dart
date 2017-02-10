import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:convert';

export "package:test/test.dart";

final  String inputPath = _getInputPath();
_getInputPath(){
  var testRootPath = Platform.environment["TEST_ROOT_PATH"];
  if (testRootPath== null) {
    testRootPath = path.dirname(Platform.script.path);
    var prev = testRootPath;
    while (path.basename(testRootPath) != 'test') {
      testRootPath = path.dirname(testRootPath);
      if (prev == testRootPath){
        throw new Exception('Test root path not detected, Please use TEST_ROOT_PATH');
      }
      prev = testRootPath;
    }
  }
  Logger.root.info('Test root path: "${testRootPath}"');
  return testRootPath;
}
File getSampleFile(String name){
  name = path.join(inputPath,name).replaceAll(new RegExp('\\+'), '\\')..replaceAll(new RegExp('/+'), '/').replaceAll('/',Platform.pathSeparator);
  return new File(name);
}
String readSampleFile(String name){
  return getSampleFile(name).readAsStringSync();
}

Future<Object> loadSampleJSON(String name){
  name = name.replaceAll(new RegExp('\\+'), '\\')..replaceAll(new RegExp('/+'), '/').replaceAll('/',Platform.pathSeparator);
  if (name[0] == Platform.pathSeparator){
    name = name.substring(1);
  }
  return getSampleFile(name).readAsString().then(JSON.decode);
}

void initTestCommonSetting(){
  //useVMConfiguration();
  _initLog();
}

_initLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}';
    print(msg);
  });
}