// Copyright (c) 2018, adalberto.lacruz@gmail.com

import 'dart:async';

import 'package:build/build.dart';
import 'package:less_dart/less.dart';
import 'package:less_dart/src_builder/base_builder.dart';

export 'package:build/build.dart';
export 'package:less_dart/less.dart';
export 'package:less_dart/src_builder/base_builder.dart';

/// Extension for .html files
const String DOT_HTML_TO = '.html';

/// Extension for .less files
const String DOT_LESS_TO = '.css';

///
Builder lessBuilder(BuilderOptions builderOptions) =>
    LessBuilder(LessBuilderOptions(builderOptions));

/// Remove input files
PostProcessBuilder lessSourceCleanup(BuilderOptions options) =>
    FileDeletingBuilder(<String>['.less', '.less.html'],
        isEnabled: (options.config['enabled'] as bool) ?? false);

///
/// build.yaml example file in project:
///
/// targets:
///  $default:
///    builders:
///      less_dart:
///        options:
///          entry_points: ['web/builder.less', 'web/other.less', '*.html']
///          include_path: 'lib/lessIncludes'
///      less_dart|less_source_cleanup:
///        options:
///          enabled: true
///
class LessBuilder implements Builder {
  ///
  final LessBuilderOptions options;

  ///
  LessBuilder(this.options);

  ///
  @override
  Future<dynamic> build(BuildStep buildStep) async {
    final AssetId inputId = buildStep.inputId;

    final bool toProcess = options.entryPoints.check(inputId.path);
    if (!toProcess) return;

    final String package = inputId.package;
    final String extension = inputId.extension;

    if (extension.toLowerCase() == '.less') {
      final DotLessBuilder transformer = DotLessBuilder()
        ..createFlags(options)
        ..inputContent = await buildStep.readAsString(inputId);

      final AssetId outputId = inputId.changeExtension(DOT_LESS_TO);
      log.info(
          '  -- Building ${transformer.message} ${inputId.path} > ${outputId.path}');

      await transformer.transform(customOptions);
      if (transformer.isError) {
        log.severe('LESS ${transformer.errorMessage}');
      }

      await buildStep.writeAsString(outputId, transformer.outputContent);

      // dependents - force AssetGraph inclusion, we are called on change
      transformer.imports.forEach((String path) async {
        await buildStep.canRead(AssetId(package, path));
      });
    } else if (extension.toLowerCase() == '.html') {
      final DotHtmlBuilder transformer = DotHtmlBuilder()
        ..createFlags(options)
        ..inputContent = await buildStep.readAsString(inputId);

      final String outputPath = inputId.path.replaceAll('.less.html', '.html');
      final AssetId outputId = AssetId(package, outputPath);
      log.info(
          '  -- Building ${transformer.message} ${inputId.path} > ${outputId.path}');

      await transformer.transform(customOptions);
      if (transformer.isError) {
        log.severe('LESS ${transformer.errorMessage}');
      }

      await buildStep.writeAsString(outputId, transformer.outputContent);

      // dependents - force AssetGraph inclusion, we are called on change
      transformer.imports.forEach((String path) async {
        await buildStep.canRead(AssetId(package, path));
      });
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => <String, List<String>>{
        '.less.html': <String>[DOT_HTML_TO],
        '.less': <String>[DOT_LESS_TO]
      };

  ///
  /// Extending the builder let modify programmatically the less options.
  ///
  /// See test/custom_functions.dart and test/less_custom_builder.dart
  ///
  void customOptions(LessOptions options) {}
}
