//2.4.0 20150315

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
     3: def('comments2', options: ['--strict-math=on']),
     4: def('css'),
     5: def('css-3'),
     6: def('css-escapes'),
     7: def('css-guards'),
     8: def('detached-rulesets'),
     9: def('directives-bubling'),
    10: def('empty'),
    11: def('extend', options: ['--log-level=1']),
    12: def('extend-chaining', options: ['--log-level=1']),
    13: def('extend-clearfix'),
    14: def('extend-exact', options: ['--log-level=1']),
    15: def('extend-media'),
    16: def('extend-nest', options: ['--log-level=1']),
    17: def('extend-selector'),
    18: def('extract-and-length'),
    19: def('functions'),
    20: def('ie-filters'),
    21: def('import'),
    22: def('import-inline'),
    23: def('import-interpolation'),
    24: def('import-once'),
    25: def('import-reference', options: ['--log-level=1']),
    //26: def('javascript'),
    27: def('lazy-eval'),
    28: def('media'),
    29: def('merge'),
    30: def('mixins'),
    31: def('mixins-args', options: ['--strict-math=on']),
    32: def('mixins-closure'),
    33: def('mixins-guards'),
    34: def('mixins-guards-default-func'),
    35: def('mixins-important'),
    36: def('mixins-interpolated'),
    37: def('mixins-named-args'),
    38: def('mixins-nested'),
    39: def('mixins-pattern'),
    40: def('no-output'),
    41: def('operations'),
    42: def('parens', options: ['--strict-math=on']),
    43: def('plugin',
        modifyOptions: (LessOptions options) {
          options.definePlugin('plugin-global', new PluginGlobal());
          options.definePlugin('plugin-local', new PluginLocal());
          options.definePlugin('plugin-transitive', new PluginTransitive());
        }),
    46: def('property-name-interp'),
    47: def('rulesets'),
    48: def('scope'),
    49: def('selectors'),
    50: def('strings'),
    51: def('urls', options: ['--relative-urls', '--silent']),
    52: def('variables'),
    53: def('variables-in-at-rules'),
    54: def('whitespace'),
    55: def('strict-units/strict-units', options: ['--strict-math=on', '--strict-units=on']),

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

    74: def('filemanagerPlugin/filemanager',
        modifyOptions: (LessOptions options) {options.definePlugin('TestFileManagerPlugin', new TestFileManagerPlugin(), true, '');}),
    75: def('postProcessorPlugin/postProcessor',
        modifyOptions: (LessOptions options) {options.definePlugin('TestPostProcessorPlugin', new TestPostProcessorPlugin(), true, '');}),
    76: def('preProcessorPlugin/preProcessor',
        modifyOptions: (LessOptions options) {options.definePlugin('TestPreProcessorPlugin', new TestPreProcessorPlugin(), true, '');}),
    77: def('visitorPlugin/visitor',
        modifyOptions: (LessOptions options) {options.definePlugin('TestVisitorPlugin', new TestVisitorPlugin(), true, '');}),

    // static-urls
    79: def('static-urls/urls',
        options: ['--rootpath=folder (1)/']),

    //url-args
    80: def('url-args/urls',
        options: ['--url-args=424242']),

    //sourcemaps
    85: def('index', isExtendedTest: true,
        isSourcemapTest: true, cssName: 'index-expected',
        options: ['--source-map=webSourceMap/index.map', '--banner=webSourceMap/banner.txt']),
    86: def('index-less-inline', isExtendedTest: true,
        isSourcemapTest: true, cssName: 'index-less-inline-expected',
        options: ['--source-map=webSourceMap/index-less-inline.map', '--source-map-less-inline',
                  '--banner=webSourceMap/banner.txt']),
    87: def('index-map-inline', isExtendedTest: true,
        isSourcemapTest: true, cssName: 'index-map-inline-expected',
        options: ['--source-map-map-inline', '--banner=webSourceMap/banner.txt']),
    88: def('sourcemaps-empty/empty', options: ['--source-map-map-inline']),

    //include-path
    90: def('include-path/include-path', options: ['--include-path=less/import:data']),
    91: def('include-path-string/include-path-string', options: ['--include-path=data']),

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
    141: def('errors/parse-error-media-no-block-1', isErrorTest: true),
    142: def('errors/parse-error-media-no-block-2', isErrorTest: true),
    143: def('errors/parse-error-media-no-block-3', isErrorTest: true),
    144: def('errors/parse-error-missing-bracket', isErrorTest: true),
    145: def('errors/parse-error-missing-parens', isErrorTest: true),
    146: def('errors/parse-error-with-import', isErrorTest: true),
    147: def('errors/percentage-missing-space', isErrorTest: true),
    148: def('errors/property-asterisk-only-name', isErrorTest: true),
    149: def('errors/property-ie5-hack', isErrorTest: true),
    150: def('errors/property-in-root', isErrorTest: true),
    151: def('errors/property-in-root2', isErrorTest: true),
    152: def('errors/property-in-root3', isErrorTest: true),
    153: def('errors/property-interp-not-defined', isErrorTest: true),
    154: def('errors/recursive-variable', isErrorTest: true),
    155: def('errors/single-character', isErrorTest: true),
    156: def('errors/svg-gradient1', isErrorTest: true),
    157: def('errors/svg-gradient2', isErrorTest: true),
    158: def('errors/svg-gradient3', isErrorTest: true),
    159: def('errors/svg-gradient4', isErrorTest: true),
    160: def('errors/svg-gradient5', isErrorTest: true),
    161: def('errors/svg-gradient6', isErrorTest: true),
    162: def('errors/unit-function', isErrorTest: true),
    //
    200: def('extendedTest/svg', isExtendedTest: true),
    201: def('extendedTest/url', isExtendedTest: true),
    202: def('extendedTest/image-size', isExtendedTest: true),
    //absolute path
    210: def('import-absolute-path', isExtendedTest: true, isReplaceSource: true,
        replace: [{'from': '{pathabs}', 'to': absPath('less')}]),
    //sync import
    211: def('charsets', isExtendedTest: true, modifyOptions: (LessOptions options){options.syncImport = true;}),
    //options.variables
    212: def('globalVars/simple', isExtendedTest: true,
              options: ['--banner=banner.txt'],
              modifyOptions: (LessOptions options){options.variables = { 'my-color': new Color.fromKeyword('red') };}),
    213: def('extendedTest/plugin-advanced-color', isExtendedTest: true,
              options: ['--plugin=less-plugin-advanced-color-functions']),
    //@options and @plugin directives
    220: def('extendedTest/options-strict-math', isExtendedTest: true),
    221: def('extendedTest/options-import', isExtendedTest: true),
    222: def('extendedTest/options-plugin', isExtendedTest: true)
  };
}

Config def(name, {List options, String cssName, List<Map> replace,
  bool isErrorTest: false, bool isExtendedTest: false, bool isReplaceSource: false,
  bool isSourcemapTest: false, Function modifyOptions}) {

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
    ..isReplaceSource = isReplaceSource
    ..isSourcemapTest = isSourcemapTest
    ..modifyOptions = modifyOptions;
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

  if (config[c].isReplaceSource) {
    String source = new File(fileToTest).readAsStringSync();
    if (config[c].replace != null ) {
      for (int i = 0; i < config[c].replace.length; i++) {
        source = source.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }
    less.stdin.write(source);
    args.add('-');
  } else {
    args.add(fileToTest);
  }

  if(config[c].isSourcemapTest){
    fileOutputName = path.withoutExtension(config[c].lessFile) + '.css';
    args.add(fileOutputName);
  }
  less.transform(args, modifyOptions: config[c].modifyOptions).then((exitCode){
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
      if (new File(mapFileName).existsSync()) {
        String resultMap = new File(mapFileName).readAsStringSync();
        new File(expectedMapFileName).readAsString().then((expectedMap){
          if (resultMap != expectedMap) config[c].pass = false;
          completer.complete();
        });
      } else {
        completer.complete();
      }
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
  bool isReplaceSource;
  bool isSourcemapTest;
  String lessFile;
  Function modifyOptions; // (LessOptions options){}
  List<String> options;
  bool pass;
  List<Map<String, String>> replace;
  String stderr;
}

 // ---------------------------------------------- TestFunctionsPlugin plugin
class TestFileManager extends FileManager {
  TestFileManager(Environment environment) : super(environment);

  bool supports (String filename, String currentDirectory, Contexts options,
                   Environment environment) => true;

  Future loadFile(String filename, String currentDirectory, Contexts options, Environment environment) {
    RegExp testRe = new RegExp(r'.*\.test$');
    if (testRe.hasMatch(filename)) {
      return environment.fileManagers[0].loadFile('colors.test', currentDirectory, options, environment);
    }
    return environment.fileManagers[0].loadFile(filename, currentDirectory, options, environment);
  }
}

class TestFileManagerPlugin extends Plugin {
  Environment environment = new Environment();

  install(PluginManager pluginManager) {
    FileManager fileManager = new TestFileManager(environment);
    pluginManager.addFileManager(fileManager);
  }
}

 // ---------------------------------------------- FunctionsPlugin plugin
class PluginGlobalFunctions extends FunctionBase {
  @defineMethod(name: 'test-shadow')
  Anonymous testShadow() => new Anonymous('global');

  @defineMethod(name: 'test-global')
  Anonymous testGlobal() => new Anonymous('global');
}

class PluginLocalFunctions extends FunctionBase {
  @defineMethod(name: 'test-shadow')
  Anonymous testShadow() => new Anonymous('local');

  @defineMethod(name: 'test-local')
  Anonymous testLocal() => new Anonymous('local');
}

class PluginTransitiveFunctions extends FunctionBase {
  @defineMethod(name: 'test-transitive')
  Anonymous testTransitive() => new Anonymous('transitive');
}

class PluginGlobal extends Plugin {
  install(PluginManager pluginManager) {
    FunctionBase fun = new PluginGlobalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

class PluginLocal extends Plugin {
  install(PluginManager pluginManager) {
    FunctionBase fun = new PluginLocalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

class PluginTransitive extends Plugin {
  install(PluginManager pluginManager) {
    FunctionBase fun = new PluginTransitiveFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}


// ---------------------------------------------- TestPostProcessorPlugin plugin
class TestPostProcessor extends Processor {
  TestPostProcessor(options):super(options);

  String process(String css, Map options) {
      return 'hr {height:50px;}\n' + css;
  }
}

class TestPostProcessorPlugin extends Plugin {
  TestPostProcessorPlugin(): super();

  install(PluginManager pluginManager) {
    Processor processor = new TestPostProcessor(null);
    pluginManager.addPostProcessor(processor);
  }
}


// ---------------------------------------------- TestPreProcessorPlugin plugin
class TestPreProcessor extends Processor {
  TestPreProcessor(options):super(options);

  String process(String src, Map options) {
    String injected = '@color: red;\n';
    Map<String, int> ignored = options['imports'].contentsIgnoredChars;
    FileInfo fileInfo = options['fileInfo'];
    if (ignored[fileInfo.filename] == null) ignored[fileInfo.filename] = 0;
    ignored[fileInfo.filename] += injected.length;

    return injected + src;
  }
}

class TestPreProcessorPlugin extends Plugin {
  TestPreProcessorPlugin(): super();

  install(PluginManager pluginManager) {
    Processor processor = new TestPreProcessor(null);
    pluginManager.addPreProcessor(processor);
  }
}

// ---------------------------------------------- TestVisitorPlugin plugin
class RemoveProperty extends VisitorBase {
  Visitor _visitor;
  bool isReplacing = true;

  RemoveProperty() {
    _visitor = new Visitor(this);
  }

  Ruleset run(Ruleset root) {
    return _visitor.visit(root);
  }

  visitRule(Rule ruleNode, VisitArgs visitArgs) {
    if (ruleNode.name != '-some-aribitrary-property') {
      return ruleNode;
    } else {
      return [];
    }
  }

  Function visitFtn(Node node) {
    if (node is Rule)       return this.visitRule;
    return null;
  }

  Function visitFtnOut(Node node) => null;
}

class TestVisitorPlugin extends Plugin {
  TestVisitorPlugin(): super();

  install(PluginManager pluginManager) {
    VisitorBase visitor = new RemoveProperty();
    pluginManager.addVisitor(visitor);
  }
}
