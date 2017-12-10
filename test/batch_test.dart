//Less 2.6.1 20160315
// use:
// cmd> pub run test test/batch_test.dart
//

library batch.test.less;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import '../lib/less.dart';

part 'plugins/filemanager.dart';
part 'plugins/functions.dart';
part 'plugins/plugin_tree_node.dart';
part 'plugins/postprocess.dart';
part 'plugins/preprocess.dart';
part 'plugins/visitor.dart';

///
Map<int, Config> config;
///
String errorTests;

//List<Future> run = <Future>[];

///
int passCount = 0;
///
int testCount = 0;
///
Stopwatch timeInProcess;

// ------------- CONFIGURATION -------

/// test directory
String dirPath = 'test/';

/// runOnly = null; runs all test.
/// runOnly = <int>[1, 2]; only run test 1 and 2
List<int> runOnly;

/// Write to resultDart.css, resultNode.css and .txt the config[testNumResults].
/// example: int testNumResults = 16;
int testNumResults;

///
bool useExtendedTest = true;

void main() {
  config = configFill();

  group('simple', () {
    for (int id in config.keys) {
      if (!config[id].isExtendedText && (runOnly?.contains(id) ?? true))
          declareTest(id);
    }
  });

  group('extended', () {
    for (int id in config.keys) {
      if (config[id].isExtendedText && (runOnly?.contains(id) ?? true))
          declareTest(id);
    }
  });
}

///
void declareTest(int id) {
  final Config c = config[id];
  final String ref = '(#${id.toString()})';
  // ignore: prefer_interpolation_to_compose_strings
  test(c.name + ref, () async {
    await runZoned(() async {
      await testRun(id);
    }, zoneValues: <Symbol, int>{#id: id});
  });
}

///
Map<int, Config> configFill() => <int, Config>{
     0: def('charsets'), //@import
     1: def('colors'),
     2: def('comments'),
     3: def('comments2', options: <String>['--strict-math=on']),
     4: def('css'),
     5: def('css-3'),
     6: def('css-escapes'),
     7: def('css-guards'),
     8: def('detached-rulesets'),
     9: def('directives-bubling'),
    10: def('empty'),
    11: def('extend', options: <String>['--log-level=1']),
    12: def('extend-chaining', options: <String>['--log-level=1']),
    13: def('extend-clearfix'),
    14: def('extend-exact', options: <String>['--log-level=1']),
    15: def('extend-media'),
    16: def('extend-nest', options: <String>['--log-level=1']),
    17: def('extend-selector'),
    18: def('extract-and-length'),
    19: def('functions'),
    20: def('ie-filters'),
    21: def('import'),
    22: def('import-inline'),
    23: def('import-interpolation'),
    24: def('import-once'),
    25: def('import-reference', options: <String>['--log-level=1']),
    26: def('import-reference-issues'),
    //26: def('javascript'),
    27: def('lazy-eval'),
    28: def('media', options: <String>['--strict-math=on']),
    29: def('merge'),
    30: def('mixins'),
    31: def('mixins-args', options: <String>['--strict-math=on']),
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
    42: def('parens', options: <String>['--strict-math=on']),
    43: def('plugin',
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-global', new PluginGlobal())
              ..definePlugin('plugin-local', new PluginLocal())
              ..definePlugin('plugin-transitive', new PluginTransitive())
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode())
              ..definePlugin('plugin-simple', new PluginSimple())
              ..definePlugin('plugin-scope1', new PluginScope1())
              ..definePlugin('plugin-scope2', new PluginScope2())
              ..definePlugin('plugin-collection', new PluginCollection());
        }),
    46: def('property-name-interp'),
    47: def('property-accessors'),
    48: def('rulesets'),
    49: def('scope'),
    50: def('selectors'),
    51: def('strings'),
    52: def('urls', options: <String>['--relative-urls', '--silent', '--ie-compat']),
    53: def('variables'),
    54: def('variables-in-at-rules'),
    55: def('whitespace'),
    56: def('strict-units/strict-units', options: <String>['--strict-math=on', '--strict-units=on']),
    57: def('no-strict-math/no-sm-operations'),
    58: def('no-strict-math/mixins-guards'),
    // compression
    60: def('compression/compression', options: <String>['-x']),

    // globalVars
    61: def('globalVars/simple', options: <String>[
          '--global-var=my-color=red',
          '--banner=${dirPath}banner.txt'
        ]),
    62: def('globalVars/extended', options: <String>[
          '--global-var=the-border=1px',
          '--global-var=base-color=#111',
          '--global-var=red=#842210',
          '--banner=${dirPath}banner.txt'
        ]),

    // modifyVars
    63: def('modifyVars/extended', options: <String>[
          '--modify-var=the-border=1px',
          '--modify-var=base-color=#111',
          '--modify-var=red=#842210'
        ]),

    // debug line-numbers
    64: def('debug/linenumbers',
        options: <String>['--line-numbers=comments'],
        cssName: 'debug/linenumbers-comments',
        replace: <Map<String, String>>[
          <String, String>{'from': '{path}', 'to': absPath('${dirPath}less/debug')},
          <String, String>{'from': '{pathimport}', 'to': absPath('${dirPath}less/debug/import')}
        ]),
    65: def('debug/linenumbers',
        options: <String>['--line-numbers=mediaquery'],
        cssName: 'debug/linenumbers-mediaquery',
        replace: <Map<String, String>>[
          <String, String>{'from': '{pathesc}', 'to': escFile(absPath('${dirPath}less/debug'))},
          <String, String>{'from': '{pathimportesc}', 'to': escFile(absPath('${dirPath}less/debug/import'))}
        ]),
    66: def('debug/linenumbers',
        options: <String>['--line-numbers=all'],
        cssName: 'debug/linenumbers-all',
        replace: <Map<String, String>>[
          <String, String>{'from': '{path}', 'to': absPath('${dirPath}less/debug')},
          <String, String>{'from': '{pathimport}', 'to': absPath('${dirPath}less/debug/import')},
          <String, String>{'from': '{pathesc}', 'to': escFile(absPath('${dirPath}less/debug'))},
          <String, String>{'from': '{pathimportesc}', 'to': escFile(absPath('${dirPath}less/debug/import'))}
        ]),

    67: def('legacy/legacy'),

    74: def('filemanagerPlugin/filemanager',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestFileManagerPlugin', new TestFileManagerPlugin(),
              load: true, options: '');
        }),
    75: def('postProcessorPlugin/postProcessor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestPostProcessorPlugin', new TestPostProcessorPlugin(),
              load: true, options: '');
        }),
    76: def('preProcessorPlugin/preProcessor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestPreProcessorPlugin', new TestPreProcessorPlugin(),
              load: true, options: '');
        }),
    77: def('visitorPlugin/visitor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestVisitorPlugin', new TestVisitorPlugin(),
              load: true, options: '');
        }),

    // static-urls
    79: def('static-urls/urls',
        options: <String>['--rootpath=folder (1)/']),

    //url-args
    80: def('url-args/urls',
        options: <String>['--url-args=424242']),

    //sourcemaps
    85: def('index',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-expected',
        options: <String>[
          '--source-map=${dirPath}webSourceMap/index.map',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
    86: def('index-less-inline',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-less-inline-expected',
        options: <String>[
          '--source-map=${dirPath}webSourceMap/index-less-inline.map',
          '--source-map-less-inline',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
    87: def('index-map-inline',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-map-inline-expected',
        options: <String>[
          '--source-map-map-inline',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
    88: def('sourcemaps-empty/empty', options: <String>['--source-map-map-inline']),

    //include-path
    90: def('include-path/include-path',
        options: <String>['--include-path=${dirPath}less/import:${dirPath}data']),
    91: def('include-path-string/include-path-string',
        options: <String>['--include-path=${dirPath}data']),

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
    148: def('errors/percentage-non-number-argument', isErrorTest: true),
    149: def('errors/property-asterisk-only-name', isErrorTest: true),
    150: def('errors/property-ie5-hack', isErrorTest: true),
    151: def('errors/property-in-root', isErrorTest: true),
    152: def('errors/property-in-root2', isErrorTest: true),
    153: def('errors/property-in-root3', isErrorTest: true),
    154: def('errors/property-interp-not-defined', isErrorTest: true),
    155: def('errors/recursive-variable', isErrorTest: true),
    156: def('errors/single-character', isErrorTest: true),
    157: def('errors/svg-gradient1', isErrorTest: true),
    158: def('errors/svg-gradient2', isErrorTest: true),
    159: def('errors/svg-gradient3', isErrorTest: true),
    160: def('errors/svg-gradient4', isErrorTest: true),
    161: def('errors/svg-gradient5', isErrorTest: true),
    162: def('errors/svg-gradient6', isErrorTest: true),
    163: def('errors/unit-function', isErrorTest: true),
    //
    170: def('errors/functions-1', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    172: def('errors/functions-3-assignment', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    173: def('errors/functions-4-call', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    174: def('errors/functions-5-color', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    175: def('errors/functions-5-color-2', isErrorTest: true),
    176: def('errors/functions-6-condition', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    177: def('errors/functions-7-dimension', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    178: def('errors/functions-8-element', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    179: def('errors/functions-9-expression', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    180: def('errors/functions-10-keyword', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    181: def('errors/functions-11-operation', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    182: def('errors/functions-12-quoted', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    183: def('errors/functions-13-selector', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    184: def('errors/functions-14-url', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    185: def('errors/functions-15-value', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    186: def('errors/root-func-undefined-1', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    187: def('errors/root-func-undefined-2', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),

    //
    200: def('extendedTest/svg', isExtendedTest: true),
    201: def('extendedTest/url', isExtendedTest: true),
    202: def('extendedTest/image-size', isExtendedTest: true),
    203: def('extendedTest/function-rem', isExtendedTest: true),
    204: def('extendedTest/import-package', isExtendedTest: true),
    205: def('extendedTest/import-package-lib', isExtendedTest: true,
        options: <String>['--include-path=package_test://less_dart/less/import']),
    206: def('extendedTest/import-complex-path', isExtendedTest: true,
        options: <String>['--relative-urls']),

    //absolute path
    210: def('import-absolute-path',
        isExtendedTest: true,
        isReplaceSource: true,
        replace: <Map<String, String>>[
          <String, String>{'from': '{pathabs}', 'to': absPath('${dirPath}less')}
        ]),
    //sync import
    211: def('charsets',
        isExtendedTest: true,
        modifyOptions: (LessOptions options) {
          options.syncImport = true;
        }),
    //options.variables
    212: def('globalVars/simple',
        isExtendedTest: true,
        options: <String>['--banner=${dirPath}banner.txt'],
        modifyOptions: (LessOptions options) {
          options.variables = <String, Node>{ 'my-color': new Color.fromKeyword('red') };
        }),
    213: def('extendedTest/plugin-advanced-color',
        isExtendedTest: true,
        options: <String>['--plugin=less-plugin-advanced-color-functions']),
    //@options and @plugin directives
    220: def('extendedTest/options-strict-math', isExtendedTest: true),
    221: def('extendedTest/options-import', isExtendedTest: true),
    222: def('extendedTest/options-plugin', isExtendedTest: true),
    //@apply
    230: def('extendedTest/apply', isExtendedTest: true),
    //clean-css
    300: def('cleancss/main',
        options: <String>['--clean-css="keep-line-breaks s1"'],
        isCleancssTest: true),
    301: def('cleancss/main-skip-advanced',
        options: <String>['--clean-css="skip-advanced"'],
        isCleancssTest: true),
    302: def('cleancss/colors-no',
        options: <String>['--clean-css="compatibility=*,-properties.colors"'],
        isCleancssTest: true),
    303: def('cleancss/main-ie7',
        options: <String>['--clean-css="compatibility=ie7"'],
        isCleancssTest: true),
    304: def('cleancss/main-ie8',
        options: <String>['--clean-css="compatibility=ie8"'],
        isCleancssTest: true),
    310: def('colors', isCleancssTest: true),
    311: def('css-3', isCleancssTest: true),
    312: def('css', isCleancssTest: true)
};

///
Config def(String name, {List<String> options, String cssName, List<Map<String, String>> replace,
  bool isCleancssTest: false, bool isErrorTest: false, bool isExtendedTest: false, bool isReplaceSource: false,
  bool isSourcemapTest: false, Function modifyOptions}) {

  bool                      _isExtendedTest = isExtendedTest;
  List<String>              _options = options;
  List<Map<String, String>> _replace = replace;

  String baseLess = '${dirPath}less'; //base directory for less sources
  String baseCss  = '${dirPath}css';  //base directory for css comparison

  if (isSourcemapTest) {
    baseLess = '${dirPath}webSourceMap';
    baseCss  = '${dirPath}webSourceMap';
  } else if (isErrorTest) {
    _options ??= <String>['--strict-math=on', '--strict-units=on'];
    _replace ??= <Map<String, String>>[
      // ignore: prefer_interpolation_to_compose_strings
      <String, String>{'from': '{path}', 'to': path.normalize(dirPath + 'less/errors') + path.separator},
      <String, String>{'from': '{pathhref}', 'to': ''},
      <String, String>{'from': '{404status}', 'to': ''}
    ];
  } else if (isCleancssTest) {
    baseCss = '${dirPath}cleancss';
    _isExtendedTest = true;
    _options ??= <String>['--clean-css'];
  }

  cssName ??= name;
  return new Config(name)
      ..lessFile = path.normalize('$baseLess/$name.less')
      ..cssFile = path.normalize('$baseCss/$cssName.css')
      ..errorFile = path.normalize('${dirPath}less/$name.txt')
      ..options = _options
      ..replace = _replace
      ..isErrorTest = isErrorTest
      ..isExtendedText = _isExtendedTest
      ..isReplaceSource = isReplaceSource
      ..isSourcemapTest = isSourcemapTest
      ..modifyOptions = modifyOptions;
}

///
String escFile(String fileName) {
  final String file = fileName.replaceAllMapped(new RegExp(r'([.:\/\\])'), (Match m) {
    String a = m[1];
    if (a == '\\')
        a = '\/';
    // ignore: prefer_interpolation_to_compose_strings
    return '\\' + a;
  });
//    pathesc = p.replace(/[.:/\\]/g, function(a) { return '\\' + (a=='\\' ? '\/' : a); }),
  return file;
}

// c:\CWD\pathName\ or c:/CWD/pathName/
///
String absPath(String pathName) =>
    // ignore: prefer_interpolation_to_compose_strings
    path.normalize(path.absolute(pathName)) + path.separator;

///
Future<Null> testRun(int c) async {
  final List<String> args = <String>[];
  final String fileError = config[c].errorFile;
  String fileOutputName;
  final String fileResult = config[c].cssFile;
  final String fileToTest = config[c].lessFile;
  final Less less = new Less();

  args.add('--no-color');
  if (config[c].options != null)
      args.addAll(config[c].options);

  if (config[c].isReplaceSource) {
    String source = new File(fileToTest).readAsStringSync();
    if (config[c].replace != null) {
      for (int i = 0; i < config[c].replace.length; i++) {
        source = source.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }
    less.stdin.write(source);
    args.add('-');
  } else {
    args.add(fileToTest);
  }

  if (config[c].isSourcemapTest) {
    fileOutputName = '${path.withoutExtension(config[c].lessFile)}.css';
    args.add(fileOutputName);
  }
  final int exitCode = await less.transform(args, modifyOptions: config[c].modifyOptions);
  config[c].stderr = less.stderr.toString();

  expect(exitCode, isNot(equals(3)));

  if (config[c].isSourcemapTest) {
    final String expectedCss = new File(config[c].cssFile).readAsStringSync();
    final String resultCss = new File(fileOutputName).readAsStringSync();
    expect(resultCss, equals(expectedCss));

    final String mapFileName = '${path.withoutExtension(config[c].lessFile)}.map';
    final String expectedMapFileName =  '${path.withoutExtension(config[c].cssFile)}.map';
    if (new File(mapFileName).existsSync()) {
      final String resultMap = new File(mapFileName).readAsStringSync();
      final String expectedResultMap = new File(expectedMapFileName).readAsStringSync();
      expect(resultMap, equals(expectedResultMap));
    }
  } else if (config[c].isErrorTest) {
    final String errorContent = await new File(fileError).readAsString();

    String errorContentReplaced = errorContent;
    if (config[c].replace != null) {
      for (int i = 0; i < config[c].replace.length; i++) {
        errorContentReplaced = errorContentReplaced.replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }

    if (c == testNumResults) {
      new File('${dirPath}result/expected.txt')
          ..createSync(recursive: true)
          ..writeAsStringSync(errorContentReplaced);
      new File('${dirPath}result/result.txt')
          .writeAsStringSync(config[c].stderr);
      new File('${dirPath}result/result.css')
          .writeAsStringSync(less.stdout.toString());
    }

    try {
      expect(config[c].stderr, equals(errorContentReplaced));
    } on TestFailure catch (e) {
      writeTestResult(c, 'css', less.stdout.toString());
      writeTestResult(c, 'txt', config[c].stderr);
      throw e;
    }
  } else {
    final String cssGood = await new File(fileResult).readAsString();

    String cssGoodReplaced = cssGood;
    if (config[c].replace != null) {
      for (int i = 0; i < config[c].replace.length; i++) {
        cssGoodReplaced = cssGoodReplaced
            .replaceAll(config[c].replace[i]['from'], config[c].replace[i]['to']);
      }
    }

    if (c == testNumResults) {
      new File('${dirPath}result/expected.css')
        ..createSync(recursive: true)
        ..writeAsStringSync(cssGoodReplaced);
      new File('${dirPath}result/result.css')
          .writeAsStringSync(less.stdout.toString());
    }

    try {
      expect(less.stdout.toString(), equals(cssGoodReplaced));
    } on TestFailure catch (e) {
      writeTestResult(c, 'css', less.stdout.toString());
      writeTestResult(c, 'txt', config[c].stderr);
      throw e;
    }
  }
}

///
void writeTestResult(int c, String fileType, String content) {
  final String name = '${dirPath}result/TestFile$c.$fileType';
  new File(name)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
}

///
class Config {
  ///
  final String name;
  ///
  String cssFile;
  ///
  String errorFile;
  ///
  bool isErrorTest;
  ///
  bool isExtendedText;
  ///
  bool isReplaceSource;
  ///
  bool isSourcemapTest;
  ///
  String lessFile;
  ///
  Function modifyOptions; // (LessOptions options){}
  ///
  List<String> options;
  ///
  List<Map<String, String>> replace;
  ///
  String stderr;

  ///
  Config(this.name);
}
