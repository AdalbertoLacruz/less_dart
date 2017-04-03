import 'dart:async';
import 'dart:io';

import '../lib/srcTransformer/base_transformer.dart';

import 'package:test/test.dart';

String pass(bool result) => result ? 'pass' : 'no pass';

String load(String path) => new File(path).readAsStringSync();

Future<Null> main () async {
  group('EntryPoints', () {
    test('default, not unique', () {
      final EntryPoints entryPoints = new EntryPoints();

      entryPoints.assureDefault(<String>['*.less', '*.html']);
      expect(entryPoints.check(r'/web/test.less'), isTrue);
      expect(entryPoints.isLessSingle, isFalse);
    });

    test('exclusion, unique', () {
      final EntryPoints entryPoints = new EntryPoints();
      entryPoints.addPaths(<String>['web/test.less', 'web/dir1/*/dir4/*.html', '!/dir3/dir4/*.html']);
      entryPoints.assureDefault(<String>['*.less', '*.html']);

      expect(entryPoints.check('web/dir1/dir2/dir4/test.html'), isTrue);
      expect(entryPoints.isLessSingle, isTrue);
      expect(entryPoints.check('web/dir1/dir2/dir3/dir4/test.html'), isFalse);
    });
  });

  test('HTML transformer', () async {
    final String content = load('test/transformer/index_source.html');
    HtmlTransformer htmlProcess = new HtmlTransformer(content, 'transformer/index.html', null);
    htmlProcess = await htmlProcess.transform(<String>['-no-color']);
    expect(htmlProcess.outputContent, equals(load('test/transformer/index_result.html')));
  });

  test('LESS transformer', () async {
    final String content = load('test/less/charsets.less');
    LessTransformer lessProcess = new LessTransformer(content, 'charsets.less', 'charsets.css', 'dart', null);
    lessProcess = await lessProcess.transform(<String>['--no-color', '--include-path=test/less']);
    expect(lessProcess.outputContent, equals(load('test/css/charsets.css')));
  });
}
