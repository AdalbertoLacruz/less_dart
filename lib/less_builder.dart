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
  LessBuilder(this.options);

  ///
  @override
  Future<dynamic> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    final toProcess = options.entryPoints.check(inputId.path);
    if (!toProcess) return;

    final package = inputId.package;
    final extension = inputId.extension;

    if (extension.toLowerCase() == '.less') {
      final transformer = DotLessBuilder()
        ..createFlags(options, calculateIncludePath(inputId))
        ..inputContent = await buildStep.readAsString(inputId);

      final outputId = inputId.changeExtension(DOT_LESS_TO);
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
        } else if (path_lib.isAbsolute(path)) {
          final packagePath = guessPackage(path);
          if (packagePath != null) {
            MoreList.addUnique(transformer.filesInPackage, packagePath);
          }
        }
      });

      // dependents that are in a package
      transformer.filesInPackage.forEach((String path) async {
        try {
          final pathData = path_lib.split(path);
          if (pathData.length > 1) {
            final packageName = pathData[1];
            final pathInPackage = path_lib.joinAll(<String>[
              'lib',
              ...pathData.sublist(2),
            ]);
            await buildStep.canRead(AssetId(packageName, pathInPackage));
          }
        } catch (_) {}
      });
    } else if (extension.toLowerCase() == '.html') {
      final transformer = DotHtmlBuilder()
        ..createFlags(options, calculateIncludePath(inputId))
        ..inputContent = await buildStep.readAsString(inputId);

      final outputPath = inputId.path.replaceAll('.less.html', '.html');
      final outputId = AssetId(package, outputPath);
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
  /// calculate the --include-path=   less option
  ///
  /// As we use the stdin to pass the .less file, we must use --include-path to keep
  /// the relative imports.
  ///
  /// When the path starts with 'lib/' we use the package format to let builders in other packages
  /// as required by Angular.
  ///
  /// So, 'lib/sub/file.less' becomes 'packages/package_name/sub'
  ///
  String calculateIncludePath(AssetId inputId) {
    final len = inputId.pathSegments.length;
    if (len > 1 && inputId.pathSegments.first == 'lib') {
      return <String>[
        'packages',
        inputId.package,
        ...inputId.pathSegments.sublist(1, len - 1) // could be empty
      ].join('/');
    }
    return path_lib.dirname(inputId.path);
  }

  ///
  /// The builder needs the absolute path transformed to package format
  /// Ex.: 'c:\some\package\lib\other' -> 'packages\package\other'
  ///
  String guessPackage(String path) {
    String result;
    final segments = path_lib.split(path);
    final index = segments.indexWhere((String segment) => segment == 'lib');
    if (index > 0 && index < (segments.length - 1)) {
      result = path_lib.joinAll(<String>[
        'packages',
        segments[index - 1],
        ...segments.sublist(index + 1),
      ]);
    }
    return result;
  }

  ///
  /// Extending the builder let modify programmatically the less options.
  ///
  /// See test/custom_functions.dart and test/less_custom_builder.dart
  ///
  void customOptions(LessOptions options) {}
}
