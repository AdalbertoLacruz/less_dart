part of transformer.less;

///
class TransformerOptions {
  /// entry_point: web/builder.less - main file to build or [file1.less, ...,fileN.less]
  final List<String>  entryPoints;

  /// include_path: /lib/lessIncludes - variable and mixims files
  final String        includePath;

  /// output: web/output.css - result file. If '' same as web/input.css
  final String        output;

  /// cleancss: "options" - compress output by using clean-css
  final String        cleancss;

  /// compress: true - compress output by removing some whitespaces
  final bool          compress;

  /// executable: lessc - command to execute lessc  - NOT USED
  final String        executable;

  /// build_mode: dart - io managed by lessc compiler (less) by (dart) or (mixed)
  final String        buildMode;

  /// other options in the command line
  final List<String>  otherFlags;     

  /// Only error messages in log
  final bool          silence;        //

  ///
  TransformerOptions(
      {this.entryPoints,
      this.includePath,
      this.output,
      this.cleancss,
      this.compress,
      this.executable,
      this.buildMode,
      this.otherFlags,
      this.silence});

  ///
  factory TransformerOptions.parse(Map<String, dynamic> configuration) {
    T config<T>(String key, T defaultValue) {
      final T value = configuration[key];
      return value ?? defaultValue;
    }

    List<String> readStringList(dynamic value) {
      if (value is List<String>)
          return value;
      if (value is String)
          return <String>[value];
      return null;
    }

    List<String> readEntryPoints(dynamic entryPoint, dynamic entryPoints) {
      final List<String> result = <String>[];
      List<String> value;

      value = readStringList(entryPoint);
      if (value != null)
          result.addAll(value);

      value = readStringList(entryPoints);
      if (value != null)
          result.addAll(value);

      //if (result.length < 1) print('$INFO_TEXT No entry_point supplied. Processing *.less and *.html.');
      return result;
    }

    String readBoolString(dynamic value) {
      if (value is bool && value)
          return '';
      if (value is String)
          return value;
      return null;
    }

    return new TransformerOptions(
        entryPoints: readEntryPoints(configuration['entry_point'], configuration['entry_points']),
        includePath: config('include_path', ''),
        output: config('output', ''),
        cleancss: readBoolString(configuration['cleancss']),
        compress: config('compress', false),
        executable: config('executable', 'lessc'),
        buildMode: config('build_mode', BUILD_MODE_DART),
        otherFlags: readStringList(configuration['other_flags']),
        silence: config('silence', false));
  }
}
