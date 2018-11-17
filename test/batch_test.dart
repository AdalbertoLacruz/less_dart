//Less 3.5.3 20180707
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
import '../lib/src/less_error.dart';

part 'plugins/filemanager.dart';
part 'plugins/functions.dart';
part 'plugins/plugin_preeval.dart';
part 'plugins/plugin_tree_node.dart';
part 'plugins/postprocess.dart';
part 'plugins/preprocess.dart';
part 'plugins/plugin_set_options.dart';
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

/// external tests import urls with http://...
bool runExternal = false;

/// runOnly = null; runs all test.
/// runOnly = <int>[1, 2]; only run test 1 and 2
List<int> runOnly;

/// Write to resultDart.css, resultNode.css and .txt the config[testNumResults].
/// example: int testNumResults = 16;
int testNumResults;

///
bool useExtendedTest = false;

void main() {
  config = configFill();

  group('simple', () {
    for (int id in config.keys) {
      if (!config[id].isExtendedText &&
          (runOnly?.contains(id) ?? true) &&
          (runExternal || !config[id].isExternal)) {
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
     0: def('calc'),
     1: def('charsets'), //@import
     2: def('colors'),
     3: def('comments'),
     4: def('comments2'),
     6: def('css-3'),
     7: def('css-escapes'),
     8: def('css-grid'),
     9: def('css-guards'),
    10: def('detached-rulesets'),
    11: def('directives-bubling'),
    12: def('empty'),
    20: def('extend', options: <String>['--log-level=1']),
    21: def('extend-chaining', options: <String>['--log-level=1']),
    22: def('extend-clearfix'),
    23: def('extend-exact', options: <String>['--log-level=1']),
    24: def('extend-media'),
    25: def('extend-nest', options: <String>['--log-level=1']),
    26: def('extend-selector'),
    30: def('extract-and-length'),
    31: def('functions'),
    32: def('functions-each'),
    33: def('ie-filters'),
    40: def('import'),
    41: def('import-inline'),
    42: def('import-interpolation'),
    43: def('import-once'),
    44: def('import-reference', options: <String>['--log-level=1']),
    45: def('import-reference-issues'),
    //xx: def('javascript'),
    50: def('lazy-eval'),
    51: def('media'),
    52: def('merge'),
    60: def('mixins'),
    61: def('mixins-closure'),
    62: def('mixins-guards'),
    63: def('mixins-guards-default-func'),
    64: def('mixins-important'),
    65: def('mixins-interpolated'),
    66: def('mixins-named-args'),
    67: def('mixins-nested'),
    68: def('mixins-pattern'),
    80: def('no-output'),
    81: def('operations'),
    82: def('parse-interpolation'),
    83: def('permissive-parse'),
    84: def('plugin',
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-global', new PluginGlobal())
              ..definePlugin('plugin-local', new PluginLocal())
              ..definePlugin('plugin-transitive', new PluginTransitive())
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode())
              ..definePlugin('plugin-set-options', new PluginSetOptions())
              ..definePlugin('plugin-simple', new PluginSimple())
              ..definePlugin('plugin-scope1', new PluginScope1())
              ..definePlugin('plugin-scope2', new PluginScope2())
              ..definePlugin('plugin-collection', new PluginCollection());
        }),
    85: def('plugin-preeval',
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-preeval', new PluginPreeval());
        }),
    86: def('property-name-interp'),
    87: def('property-accessors'),
    88: def('rulesets'),
    89: def('scope'),
    90: def('selectors'),
    91: def('strings'),
    92: def('urls', options: <String>['--relative-urls', '--silent', '--ie-compat']),
    93: def('variables'),
    94: def('variables-in-at-rules'),
    95: def('whitespace'),
   100: def('math/parens-division/media-math', options: <String>['--math=parens-division']),
   101: def('math/parens-division/mixins-args', options: <String>['--math=parens-division']),
   102: def('math/parens-division/new-division', options: <String>['--math=parens-division']),
   103: def('math/parens-division/parens', options: <String>['--math=parens-division']),
   105: def('math/strict/css', options: <String>['--math=parens']),
   106: def('math/strict/media-math', options: <String>['--math=parens']),
   107: def('math/strict/mixins-args', options: <String>['--math=parens']),
   108: def('math/strict/parens', options: <String>['--math=parens']),
   110: def('math/strict-legacy/css', options: <String>['--math=strict-legacy']),
   111: def('math/strict-legacy/media-math', options: <String>['--math=strict-legacy']),
   112: def('math/strict-legacy/mixins-args', options: <String>['--math=strict-legacy']),
   113: def('math/strict-legacy/parens', options: <String>['--math=strict-legacy']),
   114: def('rewrite-urls-all/rewrite-urls-all', options: <String>['-ru=all']),
   115: def('rewrite-urls-local/rewrite-urls-local', options: <String>['-ru=local']),
   116: def('rootpath-rewrite-urls-all/rootpath-rewrite-urls-all', options: <String>[
     '--rootpath=http://example.com/assets/css/',
     '-ru=all']
   ),
   117: def('rootpath-rewrite-urls-local/rootpath-rewrite-urls-local', options: <String>[
     '--rootpath=http://example.com/assets/css/',
     '-ru=local'
   ]),
   118: def('strict-units/strict-units', options: <String>['--math=strict-legacy', '--strict-units=on']),
   120: def('no-strict-math/no-sm-operations'),
   121: def('no-strict-math/mixins-guards'),
    // compression
   135: def('compression/compression', options: <String>['-x']),

    // globalVars
   140: def('globalVars/simple', options: <String>[
          '--global-var=my-color=red',
          '--banner=${dirPath}banner.txt'
        ]),
   141: def('globalVars/extended', options: <String>[
          '--global-var=the-border=1px',
          '--global-var=base-color=#111',
          '--global-var=red=#842210',
          '--banner=${dirPath}banner.txt'
        ]),

    // modifyVars
   142: def('modifyVars/extended', options: <String>[
          '--modify-var=the-border=1px',
          '--modify-var=base-color=#111',
          '--modify-var=red=#842210'
        ]),

    // debug line-numbers
   150: def('debug/linenumbers',
        options: <String>['--line-numbers=comments'],
        cssName: 'debug/linenumbers-comments',
        replace: <Map<String, String>>[
          <String, String>{'from': '{path}', 'to': absPath('${dirPath}less/debug')},
          <String, String>{'from': '{pathimport}', 'to': absPath('${dirPath}less/debug/import')}
        ]),
   151: def('debug/linenumbers',
        options: <String>['--line-numbers=mediaquery'],
        cssName: 'debug/linenumbers-mediaquery',
        replace: <Map<String, String>>[
          <String, String>{'from': '{pathesc}', 'to': escFile(absPath('${dirPath}less/debug'))},
          <String, String>{'from': '{pathimportesc}', 'to': escFile(absPath('${dirPath}less/debug/import'))}
        ]),
   152: def('debug/linenumbers',
        options: <String>['--line-numbers=all'],
        cssName: 'debug/linenumbers-all',
        replace: <Map<String, String>>[
          <String, String>{'from': '{path}', 'to': absPath('${dirPath}less/debug')},
          <String, String>{'from': '{pathimport}', 'to': absPath('${dirPath}less/debug/import')},
          <String, String>{'from': '{pathesc}', 'to': escFile(absPath('${dirPath}less/debug'))},
          <String, String>{'from': '{pathimportesc}', 'to': escFile(absPath('${dirPath}less/debug/import'))}
        ]),

   160: def('legacy/legacy', options: <String>['--strict-math=off']),
   161: def('namespacing/namespacing-1'),
   162: def('namespacing/namespacing-2'),
   163: def('namespacing/namespacing-3'),
   164: def('namespacing/namespacing-4'),
   165: def('namespacing/namespacing-5'),
   166: def('namespacing/namespacing-6'),
   167: def('namespacing/namespacing-7'),
   168: def('namespacing/namespacing-functions'),
   169: def('namespacing/namespacing-media'),
   170: def('namespacing/namespacing-operations'),

   175: def('filemanagerPlugin/filemanager',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestFileManagerPlugin', new TestFileManagerPlugin(),
              load: true, options: '');
        }),
   176: def('postProcessorPlugin/postProcessor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestPostProcessorPlugin', new TestPostProcessorPlugin(),
              load: true, options: '');
        }),
   177: def('preProcessorPlugin/preProcessor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestPreProcessorPlugin', new TestPreProcessorPlugin(),
              load: true, options: '');
        }),
   178: def('visitorPlugin/visitor',
        modifyOptions: (LessOptions options) {
          options.definePlugin('TestVisitorPlugin', new TestVisitorPlugin(),
              load: true, options: '');
        }),

    // static-urls
   180: def('static-urls/urls',
        options: <String>['--rootpath=folder (1)/']),

    //url-args
   181: def('url-args/urls',
        options: <String>['--url-args=424242']),

    //sourcemaps
   190: def('index',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-expected',
        options: <String>[
          '--source-map=${dirPath}webSourceMap/index.map',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
   191: def('index-less-inline',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-less-inline-expected',
        options: <String>[
          '--source-map=${dirPath}webSourceMap/index-less-inline.map',
          '--source-map-less-inline',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
   192: def('index-map-inline',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'index-map-inline-expected',
        options: <String>[
          '--source-map-map-inline',
          '--banner=${dirPath}webSourceMap/banner.txt'
        ]),
   193: def('sourcemaps-empty/empty', options: <String>['--source-map-map-inline']),
   194: def('custom-props',
        isExtendedTest: true,
        isSourcemapTest: true,
        cssName: 'custom-props-expected',
        options: <String>['--source-map']),
    //include-path
   195: def('include-path/include-path',
        options: <String>['--include-path=${dirPath}less/import:${dirPath}data']),
   196: def('include-path-string/include-path-string',
        options: <String>['--include-path=${dirPath}data']),

    //errors
    200: def('errors/add-mixed-units', isErrorTest: true),
    201: def('errors/add-mixed-units2', isErrorTest: true),
    202: def('errors/at-rules-undefined-var', isErrorTest: true),
    203: def('errors/at-rules-unmatching-block', isErrorTest: true),
    204: def('errors/bad-variable-declaration1', isErrorTest: true),
    205: def('errors/color-func-invalid-color', isErrorTest: true),
    //207: def('errors/comment-in-selector', isErrorTest: true),
    208: def('errors/css-guard-default-func', isErrorTest: true),
    209: def('errors/custom-property-unmatched-block-1', isErrorTest: true),
    210: def('errors/custom-property-unmatched-block-2', isErrorTest: true),
    211: def('errors/custom-property-unmatched-block-3', isErrorTest: true),
    212: def('errors/detached-ruleset-1', isErrorTest: true),
    213: def('errors/detached-ruleset-2', isErrorTest: true),
    214: def('errors/detached-ruleset-3', isErrorTest: true),
    // changed
    215: def('errors/detached-ruleset-5', isErrorTest: true),
    216: def('errors/detached-ruleset-6', isErrorTest: true),
    217: def('errors/divide-mixed-units', isErrorTest: true),
    218: def('errors/extend-no-selector', isErrorTest: true),
    219: def('errors/extend-not-at-end',  isErrorTest: true),
    220: def('errors/import-malformed', isErrorTest: true),
    221: def('errors/import-missing', isErrorTest: true),
    222: def('errors/import-no-semi', isErrorTest: true),
    223: def('errors/import-subfolder1', isErrorTest: true),
    224: def('errors/import-subfolder2', isErrorTest: true),
//      223: def('errors/javascript-error', isErrorTest: true),
//      224: def('errors/javascript-undefined-var', isErrorTest: true),
    225: def('errors/mixed-mixin-definition-args-1', isErrorTest: true),
    226: def('errors/mixed-mixin-definition-args-2', isErrorTest: true),
    227: def('errors/mixin-not-defined', isErrorTest: true),
    228: def('errors/mixin-not-defined-2', isErrorTest: true),
    229: def('errors/mixin-not-matched', isErrorTest: true),
    230: def('errors/mixin-not-matched2', isErrorTest: true),
    231: def('errors/mixin-not-visible-in-scope-1', isErrorTest: true),
    232: def('errors/mixins-guards-cond-expected', isErrorTest: true),
    233: def('errors/mixins-guards-default-func-1', isErrorTest: true),
    234: def('errors/mixins-guards-default-func-2', isErrorTest: true),
    235: def('errors/mixins-guards-default-func-3', isErrorTest: true),
    236: def('errors/multiple-guards-on-css-selectors', isErrorTest: true),
    237: def('errors/multiple-guards-on-css-selectors2', isErrorTest: true),
    238: def('errors/multiply-mixed-units', isErrorTest: true),
    239: def('errors/namespacing-2', isErrorTest: true),
    240: def('errors/namespacing-3', isErrorTest: true),
    241: def('errors/namespacing-4', isErrorTest: true),
    242: def('errors/parens-error-1', isErrorTest: true),
    243: def('errors/parens-error-2', isErrorTest: true),
    244: def('errors/parens-error-3', isErrorTest: true),
    245: def('errors/parse-error-curly-bracket', isErrorTest: true),
    246: def('errors/parse-error-media-no-block-1', isErrorTest: true),
    247: def('errors/parse-error-media-no-block-2', isErrorTest: true),
    248: def('errors/parse-error-media-no-block-3', isErrorTest: true),
    249: def('errors/parse-error-missing-bracket', isErrorTest: true),
    250: def('errors/parse-error-missing-parens', isErrorTest: true),
    251: def('errors/parse-error-with-import', isErrorTest: true),
    252: def('errors/percentage-missing-space', isErrorTest: true),
    253: def('errors/percentage-non-number-argument', isErrorTest: true),
    254: def('errors/property-asterisk-only-name', isErrorTest: true),
    255: def('errors/property-ie5-hack', isErrorTest: true),
    256: def('errors/property-in-root', isErrorTest: true),
    257: def('errors/property-in-root2', isErrorTest: true),
    258: def('errors/property-in-root3', isErrorTest: true),
    259: def('errors/property-interp-not-defined', isErrorTest: true),
    260: def('errors/recursive-variable', isErrorTest: true),
    261: def('errors/single-character', isErrorTest: true),
    262: def('errors/svg-gradient1', isErrorTest: true),
    263: def('errors/svg-gradient2', isErrorTest: true),
    264: def('errors/svg-gradient3', isErrorTest: true),
    265: def('errors/svg-gradient4', isErrorTest: true),
    266: def('errors/svg-gradient5', isErrorTest: true),
    267: def('errors/svg-gradient6', isErrorTest: true),
    268: def('errors/unit-function', isErrorTest: true),
    //
    270: def('errors/functions-1', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    272: def('errors/functions-3-assignment', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    273: def('errors/functions-4-call', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    274: def('errors/functions-5-color', isErrorTest: true,
          modifyOptions: (LessOptions options) {
            options
                ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
          }),
    275: def('errors/functions-5-color-2', isErrorTest: true),
    276: def('errors/functions-6-condition', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    277: def('errors/functions-7-dimension', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    278: def('errors/functions-8-element', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    279: def('errors/functions-9-expression', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    280: def('errors/functions-10-keyword', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    281: def('errors/functions-11-operation', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    282: def('errors/functions-12-quoted', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    283: def('errors/functions-13-selector', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    284: def('errors/functions-14-url', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    285: def('errors/functions-15-value', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    286: def('errors/root-func-undefined-1', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),
    287: def('errors/root-func-undefined-2', isErrorTest: true,
        modifyOptions: (LessOptions options) {
          options
              ..definePlugin('plugin-tree-nodes', new PluginTreeNode());
        }),

    //
    300: def('extendedTest/svg', isExtendedTest: true),
    301: def('extendedTest/url', isExtendedTest: true),
    302: def('extendedTest/image-size', isExtendedTest: true),
    303: def('extendedTest/function-rem', isExtendedTest: true),
    304: def('extendedTest/import-package', isExtendedTest: true),
    305: def('extendedTest/import-package-lib', isExtendedTest: true,
        options: <String>['--include-path=package_test://less_dart/less/import']),
    306: def('extendedTest/import-complex-path', isExtendedTest: true,
        options: <String>['--relative-urls']),
    307: def('extendedTest/colors', isExtendedTest: true),

    //absolute path
    310: def('import-absolute-path',
        isExtendedTest: true,
        isReplaceSource: true,
        replace: <Map<String, String>>[
          <String, String>{'from': '{pathabs}', 'to': absPath('${dirPath}less')}
        ]),
    //sync import
    311: def('charsets',
        isExtendedTest: true,
        modifyOptions: (LessOptions options) {
          options.syncImport = true;
        }),
    //options.variables
    312: def('globalVars/simple',
        isExtendedTest: true,
        options: <String>['--banner=${dirPath}banner.txt'],
        modifyOptions: (LessOptions options) {
          options.variables = <String, Node>{ 'my-color': new Color.fromKeyword('red') };
        }),
    313: def('extendedTest/plugin-advanced-color',
        isExtendedTest: true,
        options: <String>['--plugin=less-plugin-advanced-color-functions']),
    //@options and @plugin directives
    320: def('extendedTest/options-strict-math', isExtendedTest: true),
    321: def('extendedTest/options-import', isExtendedTest: true),
    322: def('extendedTest/options-plugin', isExtendedTest: true),
    //@apply
    330: def('extendedTest/apply', isExtendedTest: true),
    //clean-css
    400: def('cleancss/main',
        options: <String>['--clean-css="keep-line-breaks s1"'],
        isCleancssTest: true),
    401: def('cleancss/main-skip-advanced',
        options: <String>['--clean-css="skip-advanced"'],
        isCleancssTest: true),
    402: def('cleancss/colors-no',
        options: <String>['--clean-css="compatibility=*,-properties.colors"'],
        isCleancssTest: true),
    403: def('cleancss/main-ie7',
        options: <String>['--clean-css="compatibility=ie7"'],
        isCleancssTest: true),
    404: def('cleancss/main-ie8',
        options: <String>['--clean-css="compatibility=ie8"'],
        isCleancssTest: true),
    410: def('colors', isCleancssTest: true),
    411: def('css-3',
        isCleancssTest: true), // affected by parseUntil/permissiveValue quote
    412: def('css-clean',
        isCleancssTest: true),
    500: def('3rd-party/bootstrap', isExternal: true)
};

///
Config def(String name, {List<String> options, String cssName,
  List<Map<String, String>> replace, bool isCleancssTest: false,
  bool isErrorTest: false, bool isExtendedTest: false, bool isExternal: false,
  bool isReplaceSource: false, bool isSourcemapTest: false,
  Function modifyOptions}) {

  bool                      _isExtendedTest = isExtendedTest;
  List<String>              _options = options;
  List<Map<String, String>> _replace = replace;

  String baseLess = '${dirPath}less'; //base directory for less sources
  String baseCss  = '${dirPath}css';  //base directory for css comparison

  if (isSourcemapTest) {
    baseLess = '${dirPath}webSourceMap';
    baseCss  = '${dirPath}webSourceMap';
  } else if (isErrorTest) {
    _options ??= <String>['--math=strict-legacy', '--strict-units=on'];
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
      ..isExternal = isExternal
      ..isReplaceSource = isReplaceSource
      ..isSourcemapTest = isSourcemapTest
      ..modifyOptions = modifyOptions;
}

///
String escFile(String fileName) {
  final String file = fileName.replaceAllMapped(new RegExp(r'([.:\/\\])'), (Match m) {
    String a = m[1];
    if (a == '\\') a = '\/';
    // ignore: prefer_interpolation_to_compose_strings
    return '\\' + a;
  });
//    pathesc = p.replace(/[.:/\\]/g, function(a) { return '\\' + (a=='\\' ? '\/' : a); }),
  return file;
}

// c:\CWD\pathName\ or c:/CWD/pathName/
///
String absPath(String pathName) =>
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
  if (config[c].options != null) args.addAll(config[c].options);

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
  bool isExternal;
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
