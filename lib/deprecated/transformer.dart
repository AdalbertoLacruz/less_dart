/*
 * Copyright (c) 2014-2015, adalberto.lacruz@gmail.com
 * Thanks to juha.komulainen@evident.fi for inspiration and some code
 * (Copyright (c) 2013 Evident Solutions Oy) from package http://pub.dartlang.org/packages/sass
 *
 * less_dart v 0.1.4  20150112 'build_mode: dart' as default
 * less_dart v 0.1.0  20141230
 * less_node v 0.2.1  20141212 niceDuration, other_flags argument
 * less_node v 0.2.0  20140905 entry_point(s) multifile
 * less_node v 0.1.3  20140903 build_mode, run_in_shell, options, time
 * less_node v 0.1.2  20140527 use stdout instead of '>'; beatgammit@gmail.com
 * less_node v 0.1.1  20140521 compatibility with barback (0.13.0) and lessc (1.7.0);
 * less_node v 0.1.0  20140218
 */
//library less.transformer;

import 'dart:async';
import 'dart:math';
import 'dart:io';
import '../less.dart';
import 'package:barback/barback.dart';

const String INFO_TEXT = '[Info from deprecated/less-dart]';
const String BUILD_MODE_LESS = 'less';
const String BUILD_MODE_DART = 'dart';
const String BUILD_MODE_MIXED = 'mixed';

/*
 * Transformer used by 'pub build' & 'pub serve' to convert .less files to .css
 * Based on lessc over nodejs executing a process like
 * CMD> lessc --flags input.less output.css
 * It use one or various files as entry point and produces the css files
 * To mix several .less files in one, the input contents could be "@import 'filexx.less'; ..." directives
 * See http://lesscss.org/ for more information
 */
class LessTransformer extends Transformer {
  final BarbackSettings settings;
  final TransformerOptions options;

  bool get isBuildModeLess => options.buildMode == BUILD_MODE_LESS;   //input file, output file
  bool get isBuildModeDart => options.buildMode == BUILD_MODE_DART;   //input stdin, output stdout
  bool get isBuildModeMixed => options.buildMode == BUILD_MODE_MIXED; //input file, output stdout

  LessTransformer(BarbackSettings settings):
    settings = settings,
    options = new TransformerOptions.parse(settings.configuration);

  LessTransformer.asPlugin(BarbackSettings settings):
    this(settings);

  @override
  Future<bool> isPrimary (AssetId id) {
    return new Future<bool>.value(_isEntryPoint(id));
  }

  @override
  Future<Null> apply(Transform transform) {
    final List<String> flags = _createFlags();  //to build process arguments
    final AssetId id = transform.primaryInput.id;
    final String inputFile = id.path;
    final String outputFile = getOutputFileName(id);

    switch (options.buildMode) {
      case BUILD_MODE_DART:
        flags.add('-');
        break;
      case BUILD_MODE_MIXED:
        flags.add(inputFile);
        break;
      case BUILD_MODE_LESS:
      default:
        flags.add(inputFile);
        flags.add(outputFile);
    }

    final ProcessInfo processInfo = new ProcessInfo(options.executable, flags);
    if (isBuildModeDart) processInfo.inputFile = inputFile;
    if (isBuildModeMixed || isBuildModeDart) processInfo.outputFile = outputFile;

    return transform.primaryInput.readAsString().then((String content){
      transform.consumePrimary();
      return executeProcess(options.executable, flags, content, processInfo).then((String output) {

        if (isBuildModeMixed || isBuildModeDart){
          transform.addOutput(new Asset.fromString(new AssetId(id.package, outputFile), output));
        }
      });
    });
  }

  /*
   * Only returns true in entry_point(s) file
   */
  bool _isEntryPoint(AssetId id) {
    if (id.extension != '.less') return false;
    return (options.entryPoints.contains(id.path));
  }

  List<String> _createFlags(){
    final List<String> flags = <String>[];

    flags.add('--no-color');
    if (options.cleancss) flags.add('--clean-css');
    if (options.compress) flags.add('--compress');
    if (options.includePath != '') flags.add('--include-path=${options.includePath}');
    if (options.otherFlags != null) flags.addAll(options.otherFlags);

    return flags;
  }

  String getOutputFileName(AssetId id) {
    if(options.entryPoints.length > 1 || options.output == '') {
      return id.changeExtension('.css').path;
    }
    return options.output;
  }

  /*
   * lessc process wrapper
   */
  Future<String> executeProcess(String executable, List<String> flags, String content, ProcessInfo processInfo) {
    return runZoned((){
      final Stopwatch _timeInProcess = new Stopwatch();

      final Less less = new Less();
      less.stdin.write(content);

      _timeInProcess.start();
      return less.transform(flags)
        .then((int exiCode){
          _timeInProcess.stop();
          processInfo.nicePrint(_timeInProcess.elapsed);
          print(less.stderr.toString());
          if(exitCode == 0){
            return new Future<String>.value(less.stdout.toString());
          } else {
            throw new LessException(less.stderr.toString());
          }
        });
    },
    zoneValues: <Symbol, int>{#id: new Random().nextInt(10000)});
  }
}
/* ************************************** */
class TransformerOptions {
  final List<String> entryPoints;  // entry_point: web/builder.less - main file to build or [file1.less, ...,fileN.less]
  final String includePath; // include_path: /lib/lessIncludes - variable and mixims files
  final String output;       // output: web/output.css - result file. If '' same as web/input.css
  final bool cleancss;       // cleancss: true - compress output by using clean-css
  final bool compress;       // compress: true - compress output by removing some whitespaces

  final String executable;   // executable: lessc - command to execute lessc  - NOT USED
  final String buildMode;   // build_mode: dart - io managed by lessc compiler (less) by (dart) or (mixed)
  final List<String> otherFlags;    // other options in the command line

  TransformerOptions({List<String> this.entryPoints, String this.includePath, String this.output, bool this.cleancss, bool this.compress,
    String this.executable, String this.buildMode, this.otherFlags});

  factory TransformerOptions.parse(Map<dynamic, dynamic> configuration){

    //returns bool | String | List<String>
    dynamic config(String key, dynamic defaultValue) {
      final dynamic value = configuration[key];
      return value != null ? value : defaultValue;
    }

    List<String> readStringList(dynamic value) {
      if (value is List<String>) return value;
      if (value is String) return <String>[value];
      return null;
    }

    List<String> readEntryPoints(dynamic entryPoint, dynamic entryPoints) {
      final List<String> result = <String>[];
      List<String> value;

      value = readStringList(entryPoint);
      if (value != null) result.addAll(value);

      value = readStringList(entryPoints);
      if (value != null) result.addAll(value);

      if (result.length < 1) print('$INFO_TEXT No entry_point supplied!');
      return result;
    }

    return new TransformerOptions (
        entryPoints: readEntryPoints(configuration['entry_point'], configuration['entry_points']),
        includePath: config('include_path', ''),
        output: config('output', ''),
        cleancss: config('cleancss', false),
        compress: config('compress', false),

        executable: config('executable', 'lessc'),
        buildMode: config('build_mode', BUILD_MODE_DART),
        otherFlags: readStringList(configuration['other_flags'])
    );
  }
}

/* ************************************** */
class ProcessInfo {
  String        executable;
  List<String>  flags;
  String        inputFile = '';
  String        outputFile = '';

  ProcessInfo(this.executable, this.flags);

  void nicePrint(Duration elapsed){
    print('$INFO_TEXT command: $executable ${flags.join(' ')}');
    if (inputFile  != '') print('$INFO_TEXT input File: $inputFile');
    if (outputFile != '') print('$INFO_TEXT outputFile: $outputFile');
    print ('$INFO_TEXT $executable transformation completed in ${niceDuration(elapsed)}');
  }

  /// Returns a human-friendly representation of [duration].
  //from barback - Copyright (c) 2013, the Dart project authors
  String niceDuration(Duration duration) {
    final String result = duration.inMinutes > 0 ? "${duration.inMinutes}:" : "";

    final int s = duration.inSeconds % 59;
    final int ms = (duration.inMilliseconds % 1000) ~/ 100;
    return result + "$s.${ms}s";
  }
}

/* ************************************** */
/*
 * Process error management
 */
class LessException implements Exception {
  final String message;

  LessException(this.message);

  @override
  String toString() => '\n$message';
}
