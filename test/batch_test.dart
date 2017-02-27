//Less 2.5.0
// use:
// cmd> pub run test test/batch_test.dart
//

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../lib/less.dart';


Map<int, Config> config;
String errorTests;
List<Future> run = [];
int passCount = 0;
int testCount = 0;
Stopwatch timeInProcess;

// ------------- CONFIGURATION -------

/// test directory
String dirPath = 'test/';

/// runOlny = null; runs all test.
/// runOnly = [1, 2]; only run test 1 and 2
List runOnly;

/// Write to resultDart.css, resultNode.css and .txt the config[testNumResults].
/// example: int testNumResults = 16;
int testNumResults;

bool useExtendedTest = true;

main() {
  config = configFill();

  group('simple', () {
    for (int id in config.keys) {
      if (!config[id].isExtendedText && (runOnly?.contains(id) ?? true)) {
        declareTest(id);
      }
    }
  });

  group('extended', () {
    for (int id in config.keys) {
      if (config[id].isExtendedText && (runOnly?.contains(id) ?? true)) {
        declareTest(id);
      }
    }
  });
}

declareTest(int id) {
  final Config c = config[id];
  String ref = "(#${id.toString()})";
  test(c.name + ref, () async {
    await runZoned(() async {
      await testRun(id);
    }, zoneValues: {#id: id});
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
        options: ['--global-var=my-color=red', '--banner='+dirPath+'banner.txt']),
    62: def('globalVars/extended',
        options: ['--global-var=the-border=1px', '--global-var=base-color=#111',
                  '--global-var=red=#842210', '--banner='+dirPath+'banner.txt']),

    // modifyVars
    63: def('modifyVars/extended',
        options: ['--modify-var=the-border=1px', '--modify-var=base-color=#111',
                  '--modify-var=red=#842210']),

    // debug line-numbers
    64: def('debug/linenumbers',
        options: ['--line-numbers=comments'],
        cssName: 'debug/linenumbers-comments',
        replace: [
          {'from': '{path}', 'to': absPath(dirPath + 'less/debug')},
          {'from': '{pathimport}', 'to': absPath(dirPath + 'less/debug/import')}
        ]),
    65: def('debug/linenumbers',
        options: ['--line-numbers=mediaquery'],
        cssName: 'debug/linenumbers-mediaquery',
        replace: [
          {'from': '{pathesc}', 'to': escFile(absPath(dirPath + 'less/debug'))},
          {'from': '{pathimportesc}', 'to': escFile(absPath(dirPath + 'less/debug/import'))}
        ]),
    66: def('debug/linenumbers',
        options: ['--line-numbers=all'],
        cssName: 'debug/linenumbers-all',
        replace: [
          {'from': '{path}', 'to': absPath(dirPath + 'less/debug')},
          {'from': '{pathimport}', 'to': absPath(dirPath + 'less/debug/import')},
          {'from': '{pathesc}', 'to': escFile(absPath(dirPath + 'less/debug'))},
          {'from': '{pathimportesc}', 'to': escFile(absPath(dirPath + 'less/debug/import'))}
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
        options: ['--source-map=' + dirPath + 'webSourceMap/index.map',
                  '--banner=' + dirPath + 'webSourceMap/banner.txt']),
    86: def('index-less-inline', isExtendedTest: true,
        isSourcemapTest: true, cssName: 'index-less-inline-expected',
        options: ['--source-map=' + dirPath + 'webSourceMap/index-less-inline.map',
                  '--source-map-less-inline',
                  '--banner=' + dirPath + 'webSourceMap/banner.txt']),
    87: def('index-map-inline', isExtendedTest: true,
        isSourcemapTest: true, cssName: 'index-map-inline-expected',
        options: ['--source-map-map-inline',
                  '--banner=' + dirPath + 'webSourceMap/banner.txt']),
    88: def('sourcemaps-empty/empty', options: ['--source-map-map-inline']),

    //include-path
    90: def('include-path/include-path',
        options: ['--include-path=' + dirPath + 'less/import:' + dirPath + 'data']),
    91: def('include-path-string/include-path-string',
        options: ['--include-path=' + dirPath + 'data']),

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
    203: def('extendedTest/function-rem', isExtendedTest: true),
    //absolute path
    210: def('import-absolute-path', isExtendedTest: true, isReplaceSource: true,
        replace: [{'from': '{pathabs}', 'to': absPath(dirPath + 'less')}]),
    //sync import
    211: def('charsets', isExtendedTest: true, modifyOptions: (LessOptions options){options.syncImport = true;}),
    //options.variables
    212: def('globalVars/simple', isExtendedTest: true,
              options: ['--banner=' + dirPath + 'banner.txt'],
              modifyOptions: (LessOptions options){options.variables = { 'my-color': new Color.fromKeyword('red') };}),
    213: def('extendedTest/plugin-advanced-color', isExtendedTest: true,
              options: ['--plugin=less-plugin-advanced-color-functions']),
    //@options and @plugin directives
    220: def('extendedTest/options-strict-math', isExtendedTest: true),
    221: def('extendedTest/options-import', isExtendedTest: true),
    222: def('extendedTest/options-plugin', isExtendedTest: true),
    //@apply
    230: def('extendedTest/apply', isExtendedTest: true),
    //clean-css
    300: def('cleancss/main', options: ['--clean-css="keep-line-breaks s1"'], isCleancssTest: true),
    301: def('cleancss/main-skip-advanced', options: ['--clean-css="skip-advanced"'], isCleancssTest: true),
    302: def('cleancss/colors-no', options: ['--clean-css="compatibility=*,-properties.colors"'], isCleancssTest: true),
    303: def('cleancss/main-ie7', options: ['--clean-css="compatibility=ie7"'], isCleancssTest: true),
    304: def('cleancss/main-ie8', options: ['--clean-css="compatibility=ie8"'], isCleancssTest: true),
    310: def('colors', isCleancssTest: true),
    311: def('css-3', isCleancssTest: true),
    312: def('css', isCleancssTest: true)
  };
}

Config def(name, {List<String> options, String cssName, List<Map> replace,
  bool isCleancssTest: false, bool isErrorTest: false, bool isExtendedTest: false, bool isReplaceSource: false,
  bool isSourcemapTest: false, Function modifyOptions}) {

  String baseLess = dirPath + 'less'; //base directory for less sources
  String baseCss  = dirPath + 'css';  //base directory for css comparation

  if (isSourcemapTest) {
    baseLess = dirPath + 'webSourceMap';
    baseCss  = dirPath + 'webSourceMap';
  } else if (isErrorTest) {
    if (options == null) options = ['--strict-math=on', '--strict-units=on'];
    if (replace == null) {
      replace = [
        {'from': '{path}', 'to': path.normalize(dirPath + 'less/errors') + path.separator},
        {'from': '{pathhref}', 'to': ''},
        {'from': '{404status}', 'to': ''}
      ];
    }
  } else if (isCleancssTest) {
    baseCss = dirPath + 'cleancss';
    isExtendedTest = true;
    if (options == null) options = ['--clean-css'];
  }
  String CSSName = cssName == null ? name : cssName;
  return new Config(name)
    ..lessFile = path.normalize('${baseLess}/${name}.less')
    ..cssFile = path.normalize('${baseCss}/${CSSName}.css')
    ..errorFile = path.normalize(dirPath + 'less/${name}.txt')
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

testRun(int c) async {
  List<String> args = [];
  String fileError = config[c].errorFile;
  String fileOutputName;
  String fileResult = config[c].cssFile;
  String fileToTest = config[c].lessFile;
  Less less = new Less();

  args.add('--no-color');
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
  final exitCode = await less.transform(args, modifyOptions: config[c].modifyOptions);
  config[c].stderr = less.stderr.toString();

  expect(exitCode, isNot(equals(3)));

  if (config[c].isSourcemapTest) {
    String expectedCss = new File(config[c].cssFile).readAsStringSync();
    String resultCss = new File(fileOutputName).readAsStringSync();
    expect(resultCss, equals(expectedCss));

    String mapFileName = path.withoutExtension(config[c].lessFile) + '.map';
    String expectedMapFileName = path.withoutExtension(config[c].cssFile) + '.map';
    if (new File(mapFileName).existsSync()) {
      String resultMap = new File(mapFileName).readAsStringSync();
      String expectedResultMap = new File(expectedMapFileName).readAsStringSync();
      expect(resultMap, equals(expectedResultMap));
    }
  } else if (config[c].isErrorTest) {
    final errorContent = await new File(fileError).readAsString();

    String errorContentReplaced = errorContent;
    if (config[c].replace != null ) {
      for (int i = 0; i < config[c].replace.length; i++) {
        errorContentReplaced = errorContentReplaced.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }

    expect(config[c].stderr, equals(errorContentReplaced));
  } else {
    final cssGood = await new File(fileResult).readAsString();

    String cssGoodReplaced = cssGood;
    if (config[c].replace != null ) {
      for (int i = 0; i < config[c].replace.length; i++) {
        cssGoodReplaced = cssGoodReplaced.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }

    expect(less.stdout.toString(), equals(cssGoodReplaced));
  }
}

void writeTestResult(int c, String content) {
  String name = dirPath + 'result/TestFile${c}.css';
  new File(name)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

class Config {
  final name;
  String cssFile;
  String errorFile;
  bool isErrorTest;
  bool isExtendedText;
  bool isReplaceSource;
  bool isSourcemapTest;
  String lessFile;
  Function modifyOptions; // (LessOptions options){}
  List<String> options;
  List<Map<String, String>> replace;
  String stderr;

  Config(this.name);
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
  List<int> minVersion = [2, 1, 0];

  @override
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
  List<int> minVersion = [2, 1, 0];
  install(PluginManager pluginManager) {
    FunctionBase fun = new PluginGlobalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

class PluginLocal extends Plugin {
  List<int> minVersion = [2, 1, 0];
  install(PluginManager pluginManager) {
    FunctionBase fun = new PluginLocalFunctions();
    pluginManager.addCustomFunctions(fun);
  }
}

class PluginTransitive extends Plugin {
  List<int> minVersion = [2, 1, 0];
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
  List<int> minVersion = [2, 1, 0];
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
  List<int> minVersion = [2, 1, 0];
  TestPreProcessorPlugin(): super();

  install(PluginManager pluginManager) {
    Processor processor = new TestPreProcessor(null);
    pluginManager.addPreProcessor(processor);
  }
}

// ---------------------------------------------- TestVisitorPlugin plugin
class RemoveProperty extends VisitorBase {
  Visitor _visitor;

  RemoveProperty() {
    isReplacing = true;
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
    if (node is Rule)       return visitRule;
    return null;
  }

  Function visitFtnOut(Node node) => null;
}

class TestVisitorPlugin extends Plugin {
  List<int> minVersion = [2, 1, 0];
  TestVisitorPlugin(): super();

  install(PluginManager pluginManager) {
    VisitorBase visitor = new RemoveProperty();
    pluginManager.addVisitor(visitor);
  }
}
