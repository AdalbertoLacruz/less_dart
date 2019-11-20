// Copyright (c) 2018, adalberto.lacruz@gmail.com

import 'dart:async';
import 'package:path/path.dart' as path_lib;
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
  final PackageResolverProvider _packageResolverProvider = PackageResolverProvider();

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
    final String inputPath = await _filePathFor(inputId);

    if (extension.toLowerCase() == '.less') {
      final DotLessBuilder transformer = DotLessBuilder()
        ..createFlags(options, path_lib.dirname(inputPath))
        ..inputContent = await buildStep.readAsString(inputId);

      final AssetId outputId = inputId.changeExtension(DOT_LESS_TO);
      log.fine(
          '  -- Building ${transformer.message} ${inputId.path} > ${outputId.path}');

      await transformer.transform(customOptions);
      if (transformer.isError) {
        log.severe('LESS ${transformer.errorMessage}');
      }

      await buildStep.writeAsString(outputId, transformer.outputContent);

      // dependents - force AssetGraph inclusion, we are called on change
      transformer.imports.forEach((String path) async {
        // packages are absolute
        if (path_lib.isRelative(path)) {
          await buildStep.canRead(AssetId(package, path));
        }
      });

      // dependents that are in a package
      transformer.filesInPackage.forEach((String path) async {
        try {
          final List<String> pathData = path_lib.split(path);
          if (pathData.length > 1) {
            final String packageName = pathData[1];
            String pathInPackage =
                path_lib.joinAll(pathData.getRange(2, pathData.length));
            pathInPackage = 'lib/$pathInPackage';
            await buildStep.canRead(AssetId(packageName, pathInPackage));
          }
        } catch (_) {}
      });
    } else if (extension.toLowerCase() == '.html') {
      final DotHtmlBuilder transformer = DotHtmlBuilder()
        ..createFlags(options, path_lib.dirname(inputPath))
        ..inputContent = await buildStep.readAsString(inputId);

      final String outputPath = inputId.path.replaceAll('.less.html', '.html');
      final AssetId outputId = AssetId(package, outputPath);
      log.fine(
          '  -- Building ${transformer.message} ${inputId.path} > ${outputId.path}');

      await transformer.transform(customOptions);
      if (transformer.isError) {
        log.severe('LESS ${transformer.errorMessage}');
      }

      await buildStep.writeAsString(outputId, transformer.outputContent);

      // dependents - force AssetGraph inclusion, we are called on change
      transformer.imports.forEach((String path) async {
        // packages are absolute and html in package not used
        if (path_lib.isRelative(path)) {
          await buildStep.canRead(AssetId(package, path));
        }
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

  Future<String> _filePathFor(AssetId id) async {
    final PackageResolver resolver = await _packageResolverProvider.getPackageResolver();

    final String packagePath = await resolver.packagePath(id.package);

    if (packagePath == null) {
      throw PackageNotFoundException(id.package);
    }
    return path_lib.join(packagePath, id.path);
  }
}
