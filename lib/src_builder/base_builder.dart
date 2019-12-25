library builder.less;

import 'dart:async';
import 'package:build/build.dart';
import 'package:less_dart/less.dart';

part 'dot_html_builder.dart';
part 'dot_less_builder.dart';
part 'entry_points.dart';
part 'less_builder_options.dart';

///
class BaseBuilder {
  ///
  String errorMessage = '';

  /// files that are package
  List<String> filesInPackage = <String>[];

  /// less cli flags
  List<String> flags;

  /// less transformer imported paths (input file dependencies)
  List<String> imports = <String>[];

  ///
  String inputContent;

  /// process exit state
  bool isError = false;

  /// normal log info
  String message;

  ///
  String outputContent;

  ///
  void createFlags(LessBuilderOptions options, String filePath) {
    flags = <String>['--no-color'];

    if (options.cleancss != null) {
      flags.add('--clean-css="${options.cleancss}"');
    }

    if (options.compress) flags.add('--compress');

    var include = filePath;
    if (options.includePath.isNotEmpty) {
      include = '$include;${options.includePath}';
//      flags.add('--include-path=${options.includePath}');
    }
    flags.add('--include-path=$include');

    if (options.otherFlags != null) flags.addAll(options.otherFlags);

    message = 'lessc ${flags.join(' ')}';

    flags.add('-'); // input by stdin
  }

  ///
  /// Transform the less content to css
  ///
  Future<BaseBuilder> transform(Function modifyOptions) {
    final task = Completer<BaseBuilder>();
    isError = false;
    message = 'builder message';
    outputContent = '';
    // transform code here
    task.complete(this);

    return task.future;
  }
}

///
/// Less Id for runZoned
///
class GenId {
  ///
  static int k = 1;

  ///
  static int get next => k++;
}
