part of builder.less;

///
/// Manager to know which files to process
///
/// Suports inclusion/exclusion paths with wildcards (*).
/// Default values are '*.less'
///
class EntryPoints {
  ///
  List<RegExp> include = <RegExp>[];

  ///
  bool isLessSingle = false;

  ///
  List<RegExp> exclude = <RegExp>[];

  ///
  /// Constructor
  /// [paths] is the entry_points list.
  ///   Example: ['web/builder.less', 'web/test.less']
  ///
  EntryPoints(List<String> paths) {
    addPaths(paths);
    assureDefault(<String>['*.less']);
  }

  ///
  /// add [paths] as base comparation
  ///
  /// [paths] could have * and !exclusion.
  ///
  /// Example:
  ///   '/dir1/*/dir3/dir4/*.less'
  ///   '!dir2/dir3/dir4/*.less'  exclusion path
  ///
  void addPaths(List<String> paths) {
    if (paths == null) return;

    paths.forEach((String path) {
      final _path = path.trim();
      if (_path.isNotEmpty) {
        _path.startsWith('!')
            ? exclude.add(toRegExp(_path.substring(1)))
            : include.add(toRegExp(_path));
      }
    });
  }

  ///
  /// Load default values for check if nothing indicated
  ///
  void assureDefault(List<String> defaultValues) {
    if (include.isEmpty) addPaths(defaultValues);
    getLessSingle();
  }

  ///
  /// true if [path] is a valid entry_point
  ///
  bool check(String path) {
    var result = false;
    bool found;
    RegExp re;
    var candidate = path;
    candidate = candidate.replaceAll(r'\', r'/'); //normalize

    for (var i = 0; i < include.length; i++) {
      re = include[i];
      result = re.hasMatch(candidate);
      if (result) break;
    }

    if (result) {
      for (var i = 0; i < exclude.length; i++) {
        re = exclude[i];
        found = re.hasMatch(candidate);
        if (found) {
          result = false;
          break;
        }
      }
    }

    return result;
  }

  ///
  /// Update [isLessSingle] to true if only one less file is defined in the entry_point.
  /// [include] only must have one '.less' path, with not wildcards
  ///
  void getLessSingle() {
    var count = 0;
    String path;

    isLessSingle = true;
    for (var i = 0; i < include.length; i++) {
      path = include[i].pattern;
      if (path.endsWith('.less')) {
        count++;
        if (path.contains('*') || count > 1) {
          isLessSingle = false;
          break;
        }
      }
    }
  }

  ///
  /// Creates a RegExp from a path with wildcards and normalize
  ///
  RegExp toRegExp(String path) => RegExp(
      path
          .replaceAll(r'\', r'/')
          .replaceAll(r'/', r'\/')
          .replaceAll('*', r'(.)*'),
      caseSensitive: false);
}
