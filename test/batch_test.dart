import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../lib/less.dart';

Map<int, Config> config;
String errorTests;
List<Future> run = [];
int passCount = 0;
int testCount = 0;
Stopwatch timeInProcess;

// ------------- CONFIGURATION -------

/// runOlny = null; runs all test.
/// runOnly = [1, 2]; only run test 1 and 2
List runOnly;

/// true runs the test one after one
bool sync = true;

/// Write to resultDart.css, resultNode.css and .txt the config[testNumResults].
/// example: int testNumResults = 16;
int testNumResults;

bool useExtendedTest = true;

main() {
  config = configFill();
  timeInProcess = new Stopwatch()..start();

  if (sync) {
    runSync();
  } else {
    runAsync();
  }
}

 runSync() async {
  for (int c in config.keys) {
    if (useExtendedTest || !config[c].isExtendedText) {
      //console needs differentiate each run
      await runZoned(() async {
            if (runOnly != null && !runOnly.contains(c)) {

            } else {
              await testRun(c).then((_){
                testCount++;
                printResult(c);
                if (config[c].pass) passCount++;
              });
            }
          },
          zoneValues: {#id: c});
    }
  }
  timeInProcess.stop();
  stdout.writeln('\n${passCount} test pass of ${testCount} in time ${timeInProcess.elapsed}');
  if (errorTests != null) stdout.writeln(errorTests);
}

void runAsync() {
  for (int c in config.keys) {
    if (useExtendedTest || !config[c].isExtendedText) {
      //console needs differentiate each run
      runZoned((){
        if (runOnly != null && !runOnly.contains(c)){

        } else {
          run.add(testRun(c));
        }
      },
      zoneValues: {#id: c});
    }
  }

  Future.wait(run).whenComplete((){
    stdout.writeln('TEST RESULTS');
    for (int c in config.keys) {
      if (config[c].pass == null)continue;
      testCount++;
      printResult(c);
      if (config[c].pass) passCount++;
    }
    timeInProcess.stop();
    stdout.writeln('\n${passCount} test pass of ${testCount} in time ${timeInProcess.elapsed}');
    if (errorTests != null) stdout.writeln(errorTests);
  });
}

  Map<int, Config> configFill() {
    return {
       0: def('charsets'), //@import
       1: def('colors'),
       2: def('comments'),
       //3: def('comments2'), //TODO pending upgrade 2.2.0 Ruleset.eval and parserInput.start()
       4: def('css-3'),
       5: def('css-escapes'),
       6: def('css-guards'),
       7: def('css'),
       8: def('detached-rulesets'),
       9: def('empty'),
      10: def('extend-chaining'),
      11: def('extend-clearfix'),
      12: def('extend-exact'),
      13: def('extend-media'),
      14: def('extend-nest'),
      15: def('extend-selector'),
      16: def('extend'),
      17: def('extract-and-length'),
      18: def('functions'),
      19: def('ie-filters'),
      20: def('import-inline'),
      21: def('import-interpolation'),
      22: def('import-once'),
      23: def('import-reference'),
      24: def('import'),
      //25: def('javascript'),
      30: def('lazy-eval'),
      31: def('media'),
      32: def('merge'),
      33: def('mixins-args'),
      34: def('mixins-closure'),
      35: def('mixins-guards-default-func'),
      36: def('mixins-guards'),
      37: def('mixins-important'),
      38: def('mixins-interpolated'),
      39: def('mixins-named-args'),
      40: def('mixins-nested'),
      41: def('mixins-pattern'),
      42: def('mixins'),
      43: def('no-output'),
      44: def('operations'),
      45: def('parens'),
      46: def('property-name-interp'),
      47: def('rulesets'),
      48: def('scope'),
      49: def('selectors'),
      50: def('strings'),
      51: def('urls', options: ['--silent']),
      52: def('variables-in-at-rules'),
      53: def('variables'),
      54: def('whitespace'),

      // compression
      60: def('compression/compression', options: ['-x']),

      // globalVars
      61: def('globalVars/simple',
          options: ['--global-var=my-color=red', '--banner=banner.txt']),
      62: def('globalVars/extended',
          options: ['--global-var=the-border=1px', '--global-var=base-color=#111',
                    '--global-var=red=#842210', '--banner=banner.txt']),

      // modifyVars
      63: def('modifyVars/extended',
          options: ['--modify-var=the-border=1px', '--modify-var=base-color=#111',
                    '--modify-var=red=#842210']),

      // debug line-numbers
      64: def('debug/linenumbers',
          options: ['--line-numbers=comments'],
          cssName: 'debug/linenumbers-comments',
          replace: [
            {'from': '{path}', 'to': absPath('less/debug')},
            {'from': '{pathimport}', 'to': absPath('less/debug/import')}
          ]),
      65: def('debug/linenumbers',
          options: ['--line-numbers=mediaquery'],
          cssName: 'debug/linenumbers-mediaquery',
          replace: [
            {'from': '{pathesc}', 'to': escFile(absPath('less/debug'))},
            {'from': '{pathimportesc}', 'to': escFile(absPath('less/debug/import'))}
          ]),
      66: def('debug/linenumbers',
          options: ['--line-numbers=all'],
          cssName: 'debug/linenumbers-all',
          replace: [
            {'from': '{path}', 'to': absPath('less/debug')},
            {'from': '{pathimport}', 'to': absPath('less/debug/import')},
            {'from': '{pathesc}', 'to': escFile(absPath('less/debug'))},
            {'from': '{pathimportesc}', 'to': escFile(absPath('less/debug/import'))}
          ]),

      67: def('legacy/legacy'),

      // static-urls
      68: def('static-urls/urls',
          options: ['--rootpath=folder (1)/']),

      //url-args
      69: def('url-args/urls',
          options: ['--url-args=424242']),

      //sourcemaps
      70: def('index', isExtendedTest: true,
          isSourcemapTest: true, cssName: 'index_expected',
          options: ['--source-map=webSourceMap/index.map', '--banner=webSourceMap/banner.txt']),

      //errors
      100: def('errors/add-mixed-units', isErrorTest: true),
      101: def('errors/add-mixed-units2', isErrorTest: true),
      102: def('errors/at-rules-undefined-var', isErrorTest: true),
      103: def('errors/bad-variable-declaration1', isErrorTest: true),
      104: def('errors/color-func-invalid-color', isErrorTest: true),
      105: def('errors/color-invalid-hex-code', isErrorTest: true),
      106: def('errors/color-invalid-hex-code2', isErrorTest: true),
      //107: def('errors/comment-in-selector', isErrorTest: true),
      108: def('errors/css-guard-default-func', isErrorTest: true),
      109: def('errors/detached-ruleset-1', isErrorTest: true),
      110: def('errors/detached-ruleset-2', isErrorTest: true),
      111: def('errors/detached-ruleset-3', isErrorTest: true),
      112: def('errors/detached-ruleset-4', isErrorTest: true),
      113: def('errors/detached-ruleset-5', isErrorTest: true),
      114: def('errors/detached-ruleset-6', isErrorTest: true),
      115: def('errors/divide-mixed-units', isErrorTest: true),
      116: def('errors/extend-no-selector', isErrorTest: true),
      117: def('errors/extend-not-at-end',  isErrorTest: true),
      118: def('errors/import-malformed', isErrorTest: true),
      119: def('errors/import-missing', isErrorTest: true),
      120: def('errors/import-no-semi', isErrorTest: true),
      121: def('errors/import-subfolder1', isErrorTest: true),
      122: def('errors/import-subfolder2', isErrorTest: true),
//      123: def('errors/javascript-error', isErrorTest: true),
//      124: def('errors/javascript-undefined-var', isErrorTest: true),
      125: def('errors/mixed-mixin-definition-args-1', isErrorTest: true),
      126: def('errors/mixed-mixin-definition-args-2', isErrorTest: true),
      127: def('errors/mixin-not-defined', isErrorTest: true),
      128: def('errors/mixin-not-matched', isErrorTest: true),
      129: def('errors/mixin-not-matched2', isErrorTest: true),
      130: def('errors/mixin-not-visible-in-scope-1', isErrorTest: true),
      131: def('errors/mixins-guards-default-func-1', isErrorTest: true),
      132: def('errors/mixins-guards-default-func-2', isErrorTest: true),
      133: def('errors/mixins-guards-default-func-3', isErrorTest: true),
      134: def('errors/multiple-guards-on-css-selectors', isErrorTest: true),
      135: def('errors/multiple-guards-on-css-selectors2', isErrorTest: true),
      136: def('errors/multiply-mixed-units', isErrorTest: true),
      137: def('errors/parens-error-1', isErrorTest: true),
      138: def('errors/parens-error-2', isErrorTest: true),
      139: def('errors/parens-error-3', isErrorTest: true),
      140: def('errors/parse-error-curly-bracket', isErrorTest: true),
      141: def('errors/parse-error-extra-parens', isErrorTest: true),
      142: def('errors/parse-error-missing-bracket', isErrorTest: true),
      143: def('errors/parse-error-missing-parens', isErrorTest: true),
      144: def('errors/parse-error-with-import', isErrorTest: true),
      145: def('errors/percentage-missing-space', isErrorTest: true),
      146: def('errors/property-asterisk-only-name', isErrorTest: true),
      147: def('errors/property-ie5-hack', isErrorTest: true),
      148: def('errors/property-in-root', isErrorTest: true),
      149: def('errors/property-in-root2', isErrorTest: true),
      150: def('errors/property-in-root3', isErrorTest: true),
      151: def('errors/property-interp-not-defined', isErrorTest: true),
      152: def('errors/recursive-variable', isErrorTest: true),
      153: def('errors/svg-gradient1', isErrorTest: true),
      154: def('errors/svg-gradient2', isErrorTest: true),
      155: def('errors/svg-gradient3', isErrorTest: true),
      156: def('errors/unit-function', isErrorTest: true),
      200: def('extendedTest/url', isExtendedTest: true)
    };
  }

  Config def(name, {List options, String cssName, List<Map> replace,
    bool isErrorTest: false, bool isExtendedTest: false, bool isSourcemapTest: false}) {

    String baseLess = 'less'; //base directory for less sources
    String baseCss = 'css';   //base directory for css comparation

    if (isSourcemapTest) {
      baseLess = 'webSourceMap';
      baseCss = 'webSourceMap';
    } else if (isErrorTest) {
      if (options == null) options = ['--strict-math=on', '--strict-units=on'];
      if (replace == null) {
        replace = [
          {'from': '{path}', 'to': path.normalize('less/errors') + path.separator},
          {'from': '{pathhref}', 'to': ''},
          {'from': '{404status}', 'to': ''}
        ];
      }
    }
    String CSSName = cssName == null ? name : cssName;
    return new Config()
      ..lessFile = path.normalize('${baseLess}/${name}.less')
      ..cssFile = path.normalize('${baseCss}/${CSSName}.css')
      ..errorFile = path.normalize('less/${name}.txt')
      ..options = options
      ..replace = replace
      ..isErrorTest = isErrorTest
      ..isExtendedText = isExtendedTest
      ..isSourcemapTest = isSourcemapTest;
  }

  String escFile(String fileName) {
    String file = fileName.replaceAllMapped(new RegExp(r'([.:\/\\])'), (Match m) {
          String a = m[1];
          if (a == '\\') a = '\/';
          return '\\' + a;
        });
//    pathesc = p.replace(/[.:/\\]/g, function(a) { return '\\' + (a=='\\' ? '\/' : a); }),
    return file;
  }

  // c:\CWD\pathName\ or c:/CWD/pathName/
  String absPath(String pathName) => path.normalize(path.absolute(pathName)) + path.separator;

  Future testRun(int c) {
    List<String> args = [];
    Completer completer = new Completer();
    String fileError = config[c].errorFile;
    String fileOutputName;
    String fileResult = config[c].cssFile;
    String fileToTest = config[c].lessFile;
    Less less = new Less();

    args.add('-no-color');
    if (config[c].options != null) args.addAll(config[c].options);
    args.add(fileToTest);
    if(config[c].isSourcemapTest){
      fileOutputName = path.withoutExtension(config[c].lessFile) + '.css';
      args.add(fileOutputName);
    }
    less.transform(args).then((exitCode){
      config[c].stderr = less.stderr.toString();

      if (exitCode == 3) { // input file error
        config[c].pass = false;
        config[c].isErrorTest = false; //force stderr output
        return completer.complete();
      }

      if (config[c].isSourcemapTest) {
        String expectedCss = new File(config[c].cssFile).readAsStringSync();
        String resultCss = new File(fileOutputName).readAsStringSync();

        if (resultCss == expectedCss) {
          config[c].pass = true;
        } else {
          config[c].pass = false;
        }
        String mapFileName = path.withoutExtension(config[c].lessFile) + '.map';
        String expectedMapFileName = path.withoutExtension(config[c].cssFile) + '.map';
        String resultMap = new File(mapFileName).readAsStringSync();
        new File(expectedMapFileName).readAsString().then((expectedMap){
          if (resultMap != expectedMap) config[c].pass = false;
          completer.complete();
        });
      } else if (config[c].isErrorTest) {
        new File(fileError).readAsString().then((errorContent){
          String errorContentReplaced = errorContent;
          if (config[c].replace != null ) {
            for (int i = 0; i < config[c].replace.length; i++) {
              errorContentReplaced = errorContentReplaced.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
            }
          }

          if (config[c].stderr == errorContentReplaced) {
            config[c].pass = true;
          } else {
            config[c].pass = false;
            writeTestResult(c, config[c].stderr);
          }

          if (c == testNumResults) {
            new File('result/expected.txt')
              ..createSync(recursive: true)
              ..writeAsStringSync(errorContentReplaced);
            new File('result/result.txt').writeAsStringSync(config[c].stderr);
            new File('result/result.css').writeAsStringSync(less.stdout.toString());
          }

          completer.complete();
        });
      } else {
        new File(fileResult).readAsString().then((cssGood){
          String cssGoodReplaced = cssGood;
          if (config[c].replace != null ) {
            for (int i = 0; i < config[c].replace.length; i++) {
              cssGoodReplaced = cssGoodReplaced.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
            }
          }

          if (c == testNumResults) {
            new File('result/expected.css')
              ..createSync(recursive: true)
              ..writeAsStringSync(cssGoodReplaced);
            new File('result/result.css').writeAsStringSync(less.stdout.toString());
          }

          if (less.stdout.toString() == cssGoodReplaced) {
            config[c].pass = true;
          } else {
            config[c].pass = false;
            writeTestResult(c, less.stdout.toString());
          }
          completer.complete();
        });
      }
    });
    return completer.future;
  }

  void writeTestResult(int c, String content) {
    String name = 'result/TestFile${c}.css';
    new File(name)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  printResult(int c) {
    String passResult = config[c].pass ? 'pass' : '  NO pass';
    if (!config[c].pass) {
      if (errorTests == null) errorTests = 'Errors in:';
      errorTests += ' ' + c.toString();
    }
    String result = '>${c.toString()} ${config[c].lessFile}: ${passResult}';
    stdout.writeln(result);
    if (config[c].stderr.isNotEmpty && !config[c].isErrorTest) {
      stdout.writeln('stderr:');
      stdout.writeln(config[c].stderr);
      stdout.writeln();
    }
  }

  class Config {
    String cssFile;
    String errorFile;
    bool isErrorTest;
    bool isExtendedText;
    bool isSourcemapTest;
    String lessFile;
    List<String> options;
    bool pass;
    List<Map<String, String>> replace;
    String stderr;
  }