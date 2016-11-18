import 'dart:io';

import '../lib/srcTransformer/base_transformer.dart';

import 'package:test/test.dart';

String pass(bool result) => result ? 'pass' : 'no pass';

load(path) => new File(path).readAsStringSync();

main () async {
  group('EntryPoints', () {
    test('default, not unique', () {
      EntryPoints entryPoints = new EntryPoints();

      entryPoints.assureDefault(['*.less', '*.html']);
      expect(entryPoints.check(r'/web/test.less'), isTrue);
      expect(entryPoints.isLessSingle, isFalse);
    });

    test('exclusion, unique', () {
      EntryPoints entryPoints = new EntryPoints();
      entryPoints.addPaths(['web/test.less', 'web/dir1/*/dir4/*.html', '!/dir3/dir4/*.html']);
      entryPoints.assureDefault(['*.less', '*.html']);

      expect(entryPoints.check('web/dir1/dir2/dir4/test.html'), isTrue);
      expect(entryPoints.isLessSingle, isTrue);
      expect(entryPoints.check('web/dir1/dir2/dir3/dir4/test.html'), isFalse);
    });
  });

  test('HTML transformer', () async {
    String content = load('test/transformer/index_source.html');
    HtmlTransformer htmlProcess = new HtmlTransformer(content, 'transformer/index.html', null);
    htmlProcess = await htmlProcess.transform(['-no-color']);
    expect(htmlProcess.outputContent, equals(load('test/transformer/index_result.html')));
  });

  test('LESS transformer', () async {
    String content = load('test/less/charsets.less');
    LessTransformer lessProcess = new LessTransformer(content, 'charsets.less', 'charsets.css', 'dart', null);
    lessProcess = await lessProcess.transform(['--no-color', '--include-path=test/less']);
    expect(lessProcess.outputContent, equals(load('test/css/charsets.css')));
  });
}