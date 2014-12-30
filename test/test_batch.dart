import '../lib/less.dart';
import 'dart:async';
import 'dart:io';

Map<int, Config> config;
List<Future> run = [];
int passCount = 0;
int testCount = 0;
Stopwatch timeInProcess;

/// runOlny = null; runs all test.
/// runOnly = [1, 2]; only run test 1 and 2
List runOnly;

/// Write to resultDart.css, resultNode.css and .txt the config[testNumResults].
/// example: int testNumResults = 16;
int testNumResults;

main() {
  /// true runs the test one after one
  bool sync = true;

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
  timeInProcess.stop();
  stdout.writeln('\n${passCount} test pass of ${testCount} in time ${timeInProcess.elapsed}');
}

void runAsync() {
  for (int c in config.keys) {
    //console needs differentiate each run
    runZoned((){
      if (runOnly != null && !runOnly.contains(c)){

      } else {
        run.add(testRun(c));
      }
    },
    zoneValues: {#id: c});
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
  });
}

  Map<int, Config> configFill() {
    return {
       0: def('charsets'), //@import
       1: def('colors'),
       2: def('comments'),
       3: def('css-3'),
       4: def('css-escapes'),
       5: def('css-guards'),
       6: def('css'),
       7: def('detached-rulesets'),
       8: def('empty'),
       9: def('extend-chaining'),
      10: def('extend-clearfix'),
      11: def('extend-exact'),
      12: def('extend-media'),
      13: def('extend-nest'),
      14: def('extend-selector'),
      15: def('extend'),
      16: def('extract-and-length'),
      17: def('functions'),
      18: def('ie-filters'),
      19: def('import-inline'),
      20: def('import-interpolation'),
      21: def('import-once'),
      22: def('import-reference'),
      23: def('import'),
      //24: def('javascript'),
      25: def('lazy-eval'),
      26: def('media'),
      27: def('merge'),
      28: def('mixins-args'),
      29: def('mixins-closure'),
      30: def('mixins-guards-default-func'),
      31: def('mixins-guards'),
      32: def('mixins-important'),
      33: def('mixins-interpolated'),
      34: def('mixins-named-args'),
      35: def('mixins-nested'),
      36: def('mixins-pattern'),
      37: def('mixins'),
      38: def('no-output'),
      39: def('operations'),
      40: def('parens'),
      41: def('property-name-interp'),
      42: def('rulesets'),
      43: def('scope'),
      44: def('selectors'),
      45: def('strings'),
      46: def('urls'),
      47: def('variables-in-at-rules'),
      48: def('variables'),
      49: def('whitespace'),
      // compression
      50: def('compression/compression', options: ['-x']),
      // globalVars
      51: def('globalVars/simple',
          options: ['--global-var=my-color=red', '--banner=banner.txt']),
      52: def('globalVars/extended',
          options: ['--global-var=the-border=1px', '--global-var=base-color=#111',
                    '--global-var=red=#842210', '--banner=banner.txt']),
      // modifyVars
      53: def('modifyVars/extended',
          options: ['--modify-var=the-border=1px', '--modify-var=base-color=#111',
                    '--modify-var=red=#842210']),
      // debug line-numbers
      54: def('debug/linenumbers',
          options: ['--line-numbers=comments'],
          cssName: 'debug/linenumbers-comments',
          replace: [
            {'from': '{path}', 'to': Directory.current.path + r'\less\debug\'},
            {'from': '{pathimport}', 'to': Directory.current.path + r'\less\debug\import\'}
          ]),
      55: def('debug/linenumbers',
          options: ['--line-numbers=mediaquery'],
          cssName: 'debug/linenumbers-mediaquery',
          replace: [
            {'from': '{pathesc}', 'to': escFile(Directory.current.path + r'\less\debug\')},
            {'from': '{pathimportesc}', 'to': escFile(Directory.current.path + r'\less\debug\import\')}
          ]),
      56: def('debug/linenumbers',
          options: ['--line-numbers=all'],
          cssName: 'debug/linenumbers-all',
          replace: [
            {'from': '{path}', 'to': Directory.current.path + r'\less\debug\'},
            {'from': '{pathimport}', 'to': Directory.current.path + r'\less\debug\import\'},
            {'from': '{pathesc}', 'to': escFile(Directory.current.path + r'\less\debug\')},
            {'from': '{pathimportesc}', 'to': escFile(Directory.current.path + r'\less\debug\import\')}
          ]),
      57: def('legacy/legacy'),
      // static-urls
      58: def('static-urls/urls',
          options: ['--rootpath=folder (1)/']),
      //url-args
      59: def('url-args/urls',
          options: ['--url-args=424242']),
      //errors
      60: def('errors/add-mixed-units',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      61: def('errors/add-mixed-units2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      62: def('errors/at-rules-undefined-var',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      63: def('errors/bad-variable-declaration1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      64: def('errors/color-func-invalid-color',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      65: def('errors/color-invalid-hex-code',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      66: def('errors/color-invalid-hex-code2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      67: def('errors/comment-in-selector',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      68: def('errors/css-guard-default-func',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      69: def('errors/detached-ruleset-1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      70: def('errors/detached-ruleset-2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      71: def('errors/detached-ruleset-3',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      72: def('errors/detached-ruleset-4',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      73: def('errors/detached-ruleset-5',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      74: def('errors/detached-ruleset-6',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      75: def('errors/divide-mixed-units',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      76: def('errors/extend-no-selector',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      77: def('errors/extend-not-at-end',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      78: def('errors/import-malformed',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      79: def('errors/import-missing',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [
            {'from': '{path}', 'to': r'less/errors/'},
            {'from': '{pathhref}', 'to': ''},
            {'from': '{404status}', 'to': ''}
            ],
          isErrorTest: true),
      80: def('errors/import-no-semi',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      81: def('errors/import-subfolder1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less\errors\'}],
          isErrorTest: true),
      82: def('errors/import-subfolder2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less\errors\'}],
          isErrorTest: true),
//      83: def('errors/javascript-error',
//          options: ['--strict-math=on', '--strict-units=on'],
//          replace: [{'from': '{path}', 'to': r'less\errors\'}],
//          isErrorTest: true),
//      84: def('errors/javascript-undefined-var',
//          options: ['--strict-math=on', '--strict-units=on'],
//          replace: [{'from': '{path}', 'to': r'less\errors\'}],
//          isErrorTest: true),
      85: def('errors/mixed-mixin-definition-args-1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      86: def('errors/mixed-mixin-definition-args-2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      87: def('errors/mixin-not-defined',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      88: def('errors/mixin-not-matched',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      89: def('errors/mixin-not-matched2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      90: def('errors/mixin-not-visible-in-scope-1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      91: def('errors/mixins-guards-default-func-1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      92: def('errors/mixins-guards-default-func-2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      93: def('errors/mixins-guards-default-func-3',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      94: def('errors/multiple-guards-on-css-selectors',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      95: def('errors/multiple-guards-on-css-selectors2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      96: def('errors/multiply-mixed-units',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      97: def('errors/parens-error-1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      98: def('errors/parens-error-2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      99: def('errors/parens-error-3',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      100: def('errors/parse-error-curly-bracket',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      101: def('errors/parse-error-extra-parens',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      102: def('errors/parse-error-missing-bracket',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      103: def('errors/parse-error-missing-parens',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      104: def('errors/parse-error-with-import',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      105: def('errors/percentage-missing-space',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      106: def('errors/property-asterisk-only-name',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      107: def('errors/property-ie5-hack',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      108: def('errors/property-in-root',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      109: def('errors/property-in-root2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less\errors\'}],
          isErrorTest: true),
      110: def('errors/property-in-root3',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      111: def('errors/property-interp-not-defined',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      112: def('errors/recursive-variable',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      113: def('errors/svg-gradient1',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      114: def('errors/svg-gradient2',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      115: def('errors/svg-gradient3',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true),
      116: def('errors/unit-function',
          options: ['--strict-math=on', '--strict-units=on'],
          replace: [{'from': '{path}', 'to': r'less/errors/'}],
          isErrorTest: true)
    };
  }

  Config def(name, {List options, String cssName, List<Map> replace, bool isErrorTest: false}) {
    String CSSName = cssName == null ? name : cssName;
    return new Config()
      ..lessFile = 'less/${name}.less'
      ..cssFile = 'css/${CSSName}.css'
      ..errorFile = 'less/${name}.txt'
      ..options = options
      ..replace = replace
      ..isErrorTest = isErrorTest;
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

  Future testRun(int c) {
    Completer completer = new Completer();
    String fileToTest = config[c].lessFile;
    String fileResult = config[c].cssFile;
    String fileError = config[c].errorFile;
    List<String> args = [];
    Less less = new Less();

    args.add('-no-color');
    if (config[c].options != null) args.addAll(config[c].options);
    args.add(fileToTest);
    less.transform(args).then((exitCode){
      config[c].stderr = less.stderr.toString();

      if (exitCode == 3) { // input file error
        config[c].pass = false;
        config[c].isErrorTest = false; //force stderr output
        return completer.complete();
      }

      if (config[c].isErrorTest) {
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
            new File('resultNode.txt').writeAsStringSync(errorContentReplaced);
            new File('resultDart.txt').writeAsStringSync(config[c].stderr);
            new File('resultDart.css').writeAsStringSync(less.stdout.toString());
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
            new File('resultNode.css').writeAsStringSync(cssGoodReplaced);
            new File('resultDart.css').writeAsStringSync(less.stdout.toString());
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
    String name = 'TestFile${c}.css';
    new File(name).writeAsStringSync(content);
  }

  printResult(int c) {
    String passResult = config[c].pass ? 'pass' : '  NO pass';
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
    List<Map<String, String>> replace;
    String errorFile;
    bool isErrorTest;
    String lessFile;
    List<String> options;
    bool pass;
    String stderr;
  }