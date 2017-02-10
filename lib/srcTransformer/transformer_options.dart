part of transformer.less;

class TransformerOptions {
  final List<String> entry_points;  // entry_point: web/builder.less - main file to build or [file1.less, ...,fileN.less]
  final String include_path; // include_path: /lib/lessIncludes - variable and mixims files
  final String output;       // output: web/output.css - result file. If '' same as web/input.css
  final String cleancss;     // cleancss: "options" - compress output by using clean-css
  final bool compress;       // compress: true - compress output by removing some whitespaces

  final String executable;   // executable: lessc - command to execute lessc  - NOT USED
  final String build_mode;   // build_mode: dart - io managed by lessc compiler (less) by (dart) or (mixed)
  final List<String> other_flags;    // other options in the command line
  final bool silence;        // Only error messages in log

  TransformerOptions({this.entry_points, this.include_path, this.output, this.cleancss, this.compress,
    this.executable, this.build_mode, this.other_flags, this.silence});

  factory TransformerOptions.parse(Map configuration){

    config(key, defaultValue) {
      var value = configuration[key];
      return value != null ? value : defaultValue;
    }

    List<String> readStringList(value) {
      if (value is List<String>) return value;
      if (value is String) return [value];
      return null;
    }

    List<String> readEntryPoints(entryPoint, entryPoints) {
      List<String> result = [];
      List<String> value;

      value = readStringList(entryPoint);
      if (value != null) result.addAll(value);

      value = readStringList(entryPoints);
      if (value != null) result.addAll(value);

      //if (result.length < 1) print('$INFO_TEXT No entry_point supplied. Processing *.less and *.html.');
      return result;
    }

    String readBoolString(value) {
      if (value is bool && value) return '';
      if (value is String) return value;
      return null;
    }

    return new TransformerOptions (
        entry_points: readEntryPoints(configuration['entry_point'], configuration['entry_points']),
        include_path: config('include_path', ''),
        output: config('output', ''),
        cleancss: readBoolString(configuration['cleancss']),
        compress: config('compress', false),

        executable: config('executable', 'lessc'),
        build_mode: config('build_mode', BUILD_MODE_DART),
        other_flags: readStringList(configuration['other_flags']),
        silence: config('silence', false)
    );
  }
}
