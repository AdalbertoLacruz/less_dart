/*
 * Copyright (c) 2014-2015, adalberto.lacruz@gmail.com
 * Thanks to juha.komulainen@evident.fi for inspiration and some code
 * (Copyright (c) 2013 Evident Solutions Oy) from package http://pub.dartlang.org/packages/sass
 *
 * less_dart v 1.0.1  20170312 annotate types
 * less_dart v 0.3.1  20150423 cleancss options
 * less_dart v 0.2.1  20150321 .html, * ! in entry_points
 * less_dart v 0.2.1  20150317 https://github.com/luisvt - AggregateTransform
 * less_dart v 0.1.4  20150112 'build_mode: dart' as default
 * less_dart v 0.1.0  20141230
 * less_node v 0.2.1  20141212 niceDuration, other_flags argument
 * less_node v 0.2.0  20140905 entry_point(s) multifile
 * less_node v 0.1.3  20140903 build_mode, run_in_shell, options, time
 * less_node v 0.1.2  20140527 use stdout instead of '>'; beatgammit@gmail.com
 * less_node v 0.1.1  20140521 compatibility with barback (0.13.0) and lessc (1.7.0);
 * less_node v 0.1.0  20140218
 */
library less.transformer;

import 'dart:async';

import 'package:less_dart/less.dart';
import 'package:less_dart/srcTransformer/base_transformer.dart';

import 'package:barback/barback.dart';

export 'package:less_dart/less.dart';

///
/// Transformer used by 'pub build' & 'pub serve' to convert .less files to .css
/// Also works in .html files, converting <less> tags to <style>
/// entry_points has default values and support * in path, and exclusion paths (!).
/// See http://lesscss.org/ for more information
///
class FileTransformer extends AggregateTransformer {
  ///
  EntryPoints               entryPoints;
  ///
  final TransformerOptions  options;
  ///
  final BarbackSettings     settings;

  ///
  FileTransformer(BarbackSettings this.settings)
      : options = new TransformerOptions.parse(settings.configuration as Map<String, dynamic>) {

    entryPoints = new EntryPoints()
        ..addPaths(options.entryPoints)
        ..assureDefault(<String>['*.less', '*.html']);
  }

  ///
  FileTransformer.asPlugin(BarbackSettings settings)
      : this(settings);

  @override
  String classifyPrimary(AssetId id) {
    // Build one group with all .less files and only .html's in entryPoint
    // so a .less file change propagates to all affected
    final String extension = id.extension.toLowerCase();
    if (extension == '.less')
        return 'less';
    if (extension == '.html' || entryPoints.check(id.path))
        return 'less';
    return null;
  }

  @override
  Future<Null> apply(AggregateTransform transform) =>
    // ignore: prefer_expression_function_bodies
    transform.primaryInputs.toList().then((List<Asset> assets) {
      return Future.wait(assets.map((Asset asset) {
        // files excluded of entry_points are not processed
        // if user don't specify entry_points, the default value is all '*.less' and '*.html' files
        if (!entryPoints.check(asset.id.path))
            return new Future<Null>.value();

        return asset.readAsString().then((String content) {
          final List<String> flags = _createFlags();  //to build process arguments
          final AssetId id = asset.id;

          if (id.extension.toLowerCase() == '.html') {
            final HtmlTransformer htmlProcess = new HtmlTransformer(content,
                id.path, customOptions);

            return htmlProcess
              .transform(flags)
              .then((HtmlTransformer process){
                if (process.deliverToPipe) {
                  transform.addOutput(new Asset.fromString(new AssetId(id.package,
                      id.path), process.outputContent));
                  if (process.isError || !options.silence)
                      print(process.message);
                  if (process.isError)
                      print('**** ERROR ****  see build/${process.outputFile}\n${
                        process.errorMessage}');
                }
            });
          } else if (id.extension.toLowerCase() == '.less') {
            final LessTransformer lessProcess = new LessTransformer(content,
                id.path, getOutputFileName(id), options.buildMode, customOptions);

            return lessProcess
              .transform(flags)
              .then((LessTransformer process) {
                if (process.deliverToPipe) {
                  transform.addOutput(new Asset.fromString(new AssetId(id.package,
                      process.outputFile), process.outputContent));
                }
                if (process.isError || !options.silence)
                    print(process.message);
                if (process.isError) {
                  final String resultFile = process.deliverToPipe
                      ? ('build/${process.outputFile}')
                      : process.outputFile;
                  print('**** ERROR ****  see $resultFile\n${
                      process.errorMessage}');
                }
            });
          }
        });
      }));
    });

  List<String> _createFlags() {
    final List<String> flags = <String>[]
        ..add('--no-color');
    if (options.cleancss != null)
        flags.add('--clean-css="${options.cleancss}"');
    if (options.compress)
        flags.add('--compress');
    if (options.includePath != '')
        flags.add('--include-path=${options.includePath}');
    if (options.otherFlags != null)
        flags.addAll(options.otherFlags);

    return flags;
  }

  ///
  /// For .less files returns the outputFilename
  ///
  /// options.output only works if we process one .less file
  /// else the name is file.less -> file.css
  ///
  String getOutputFileName(AssetId id) {
    if (!entryPoints.isLessSingle || options.output == '')
        return id.changeExtension('.css').path;
    return options.output;
  }

  ///
  void customOptions(LessOptions options) {}
}

/* ************************************** */

///
/// Process error management
///
class LessException implements Exception {
  ///
  final String message;

  ///
  LessException(this.message);

  @override
  String toString() => '\n$message';
}
