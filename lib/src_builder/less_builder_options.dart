part of builder.less;

///
/// Repository for builder options
///
class LessBuilderOptions {
  /// cleancss: "options" - compress output by using clean-css
  String cleancss;

  /// compress: true - compress output by removing some whitespaces
  bool compress;

  /// entry_point: web/builder.less - main file to build or [file1.less, ...,fileN.less]
  EntryPoints entryPoints;

  /// include_path: /lib/lessIncludes - variable and mixims files
  String includePath;

  /// other options in the command line
  List<String> otherFlags;

  ///
  /// Normalize options from Builder
  ///
  LessBuilderOptions(BuilderOptions builderOptions) {
    dynamic value;

    value = builderOptions.config['cleancss'];
    cleancss = value is String ? value : (value is bool && value) ? '' : null;

    compress = builderOptions.config['compress'] ?? false;

    // entry points
    value = builderOptions.config['entry_points'] ??
        builderOptions.config['entry_point'];

    final List<String> entry = value is String
        ? <String>[value]
        : value?.cast<String>(); // YamlList => List<String>

//      : value != null
//        ? value.cast<String>() // YamlList => List<String>
//        : null;
    entryPoints = EntryPoints(entry);

    includePath = builderOptions.config['include_path'] ?? '';

    // otherFlags
    value = builderOptions.config['other_flags']; // String || List<String>
    otherFlags = value is String ? <String>[value] : value?.cast<String>();
  }
}
