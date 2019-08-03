import 'dart:async';
import 'dart:io';

import 'package:less_dart/less.dart';
import 'package:less_dart/src_builder/base_builder.dart';
import 'package:test/test.dart';

///
String load(String path) => File(path).readAsStringSync();
///
void customOptions(LessOptions options) {}

Future<Null> main() async {
  group('EntryPoints', () {
    test('default', () {
      final EntryPoints entryPoints = EntryPoints(<String>['*.less', '*.html']);
      expect(entryPoints.check(r'/web/test.less'), isTrue);
    });

    test('exclusion', () {
      final EntryPoints entryPoints = EntryPoints(
            <String>['web/test.less', 'web/dir1/*/dir4/*.html', '!/dir3/dir4/*.html']
          )
          ..assureDefault(<String>['*.less', '*.html']);
      expect(entryPoints.check('web/dir1/dir2/dir4/test.html'), isTrue);
      expect(entryPoints.check('web/dir1/dir2/dir3/dir4/test.html'), isFalse);
    });

    test('HTML builder', () async {
      final DotHtmlBuilder htmlProcess = DotHtmlBuilder()
          ..flags = <String>['--no-color', '-']
          ..inputContent = load('test/transformer/index_source.html');
      await htmlProcess.transform(customOptions);
      expect(htmlProcess.outputContent, equals(load('test/transformer/index_result.html')));
    });

    test('LESS builder', () async {
      final DotLessBuilder lessProcess = DotLessBuilder()
        ..flags = <String>['--no-color', '--include-path=test/less', '-']
        ..inputContent = load('test/less/charsets.less');
      await lessProcess.transform(customOptions);
      expect(lessProcess.outputContent, equals(load('test/css/charsets.css')));
    });
  });
}
