/*
 * Copyright (c) 2014-2015, adalberto.lacruz@gmail.com
 * Thanks to juha.komulainen@evident.fi for inspiration and some code
 * (Copyright (c) 2013 Evident Solutions Oy) from package http://pub.dartlang.org/packages/sass
 *
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

import 'srcTransformer/base_transformer.dart';

import 'package:barback/barback.dart';

/*
 * Transformer used by 'pub build' & 'pub serve' to convert .less files to .css
 * Also works in .html files, converting <less> tags to <style>
 * entry_points has default values and support * in path, and exclusion paths (!).
 * See http://lesscss.org/ for more information
 */
class FileTransformer extends AggregateTransformer {
  final BarbackSettings settings;
  final TransformerOptions options;

  EntryPoints entryPoints;
  
  static AssetId assetId;
  static int executedTimes = 0;

  FileTransformer(BarbackSettings settings):
    settings = settings,
    options = new TransformerOptions.parse(settings.configuration) {

    entryPoints = new EntryPoints();
    entryPoints.addPaths(options.entry_points);
    entryPoints.assureDefault(['*.less', '*.html']);
  }

  FileTransformer.asPlugin(BarbackSettings settings):
    this(settings);

  @override
  classifyPrimary(AssetId id) {
    if (id.extension == '.less' || id.extension == '.html')
      return id.extension.toLowerCase();
    return null;
  }

  @override
  Future apply(AggregateTransform transform) {
    return transform.primaryInputs.toList().then((assets) {
      return Future.wait(assets.map((asset) {
        //If user doesn't specify entry_points process all less and html files,
        //else only process files specified on entry_points option.
        if(options.entry_points.isEmpty || entryPoints.check(asset.id.path)) {
          return asset.readAsString().then((content) {
            List<String> flags = _createFlags();  //to build process arguments
            print('asset.id: ${asset.id}');
            var id = asset.id;
            
            //Avoid the transformer being executed 2 times fore every *.less file edit
            if(assetId == asset.id && executedTimes == 0) {
              executedTimes++;
              assetId = id;
            } else {
              executedTimes = 0;
              assetId = null;
              return new Future.value();
            }
  
            if (id.extension.toLowerCase() == '.html') {
              HtmlTransformer htmlProcess = new HtmlTransformer(content, id.path);
              return htmlProcess.transform(flags).then((process){
                if (process.deliverToPipe) {
                  transform.addOutput(new Asset.fromString(new AssetId(id.package, id.path), process.outputContent));
                  if (process.isError || !options.silence) print (process.message);
                  if (process.isError) {
                    print('**** ERROR ****  see build/' + process.outputFile + '\n');
                    print(process.errorMessage);
                  }
                }
              });
            } else if (id.extension.toLowerCase() == '.less') {
              LessTransformer lessProcess = new LessTransformer(content, id.path,
                  getOutputFileName(id), options.build_mode);
              return lessProcess.transform(flags).then((process) {
                if (process.deliverToPipe) {
                  transform.addOutput(new Asset.fromString(new AssetId(id.package, process.outputFile), process.outputContent));
                }
                if (process.isError || !options.silence) print (process.message);
                if (process.isError) {
                  String resultFile = process.deliverToPipe ? ('build/' + process.outputFile) :process.outputFile;
                  print('**** ERROR ****  see ' + resultFile + '\n');
                  print(process.errorMessage);
                }
              });
            }
          });
        }

        return new Future.value();
      }));
    });
  }

  List<String> _createFlags(){
    List<String> flags = [];

    flags.add('--no-color');
    //if (options.cleancss) flags.add('--clean-css');
    if (options.compress) flags.add('--compress');
    if (options.include_path != '') flags.add('--include-path=${options.include_path}');
    if (options.other_flags != null) flags.addAll(options.other_flags);

    return flags;
  }

  ///
  /// For .less files returns the outputFilename
  ///
  /// options.output only works if we process one .less file
  /// else the name is file.less -> file.css
  ///
  String getOutputFileName(id) {
    if(!entryPoints.isLessSingle || options.output == '') {
      return id.changeExtension('.css').path;
    }
    return options.output;
  }
}

/* ************************************** */
/*
 * Process error management
 */
class LessException implements Exception {
  final String message;

  LessException(this.message);

  String toString() => '\n$message';
}