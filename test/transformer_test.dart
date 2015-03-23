//import 'dart:async';
import 'dart:io';

import '../lib/srcTransformer/base_transformer.dart';

String pass(bool result) => result ? 'pass' : 'no pass';

main () async {
  bool result;
  List<String> flags = ['-no-color'];

  EntryPoints entryPoints = new EntryPoints();

  //check default, not unique
  entryPoints.assureDefault(['*.less', '*.html']);
  result = entryPoints.check(r'/web/test.less') && !entryPoints.isLessSingle;
  print('test entryPoints - default - ' + pass(result));

  //check exclusion, unique
  entryPoints = new EntryPoints();
  entryPoints.addPaths(['web/test.less', 'web/dir1/*/dir4/*.html', '!/dir3/dir4/*.html']);
  entryPoints.assureDefault(['*.less', '*.html']);
  result = entryPoints.check('web/dir1/dir2/dir4/test.html') && entryPoints.isLessSingle;
  print('test entryPoints - inclusion - ' + pass(result));

  result = !entryPoints.check('web/dir1/dir2/dir3/dir4/test.html');
  print('test entryPoints - exclusion - ' + pass(result));

  //html transformer
  String content = new File('test/transformer/index_source.html').readAsStringSync();
  HtmlTransformer htmlProcess = new HtmlTransformer(content, 'transformer/index.html');
  htmlProcess = await htmlProcess.transform(flags);
  print(htmlProcess.message);
  result = (htmlProcess.outputContent == new File('test/transformer/index_result.html').readAsStringSync());
  print('test html - ' + pass(result));

  //less transformer
  content = new File('test/less/charsets.less').readAsStringSync();
  LessTransformer lessProcess = new LessTransformer(content, 'charsets.less', 'charsets.css', 'dart');
  flags = ['-no-color', '--include-path=test/less'];
  lessProcess = await lessProcess.transform(flags);
  print(lessProcess.message);
  result = (lessProcess.outputContent == new File('test/css/charsets.css').readAsStringSync());
  print('test less - ' + pass(result));
}