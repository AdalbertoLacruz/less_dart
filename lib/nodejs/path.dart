part of nodejs.less;

// Copyright Joyent, Inc. and other Node contributors.
// https://github.com/dartist/node_shims/blob/master/lib/path.dart

class Path {

  /// Regex to split a windows path into three parts: [*, device, slash, tail] windows-only
  static RegExp splitDeviceRe =
       new RegExp(r"^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$");

  /// Regex to split the tail part of the above into [*, dir, basename, ext]
  static RegExp splitTailRe =
     new RegExp(r"^([\s\S]*?)((?:\.{1,2}|[^\\\/]+?|)(\.[^.\/\\]*|))(?:[\\\/]*)$");

  ///
  /// Function to split a filename into [root, dir, basename, ext]
  /// (windows version)
  ///
  static List splitPath(String filename) {
   // Separate device+slash from tail
   Match result = splitDeviceRe.firstMatch(filename);
   String device = getValueOrDefault(result[1], '') + getValueOrDefault(result[2], '');
   String tail = getValueOrDefault(result[3], '');

   // Split the tail into dir, basename and extension
   Match result2 = splitTailRe.firstMatch(tail);
   String dir = result2[1];
   String basename = result2[2];
   String ext = result2[3];

   return [device, dir, basename, ext];

  //   Separate device+slash from tail
  //   var result = exec(splitDeviceRe, filename);
  //   var device = or(result[1], '') + or(result[2], '');
  //   var tail = or(result[3], '');
  //   // Split the tail into dir, basename and extension
  //   var result2 = exec(splitTailRe, tail);
  //   var dir = result2[1];
  //   var basename = result2[2];
  //   var ext = result2[3];
  //   return [device, dir, basename, ext];

  }

  /**
   * path.basename(p, [ext])#
   * Return the last portion of a path. Similar to the Unix basename command.
   * path.basename('/foo/bar/baz/asdf/quux.html') returns 'quux.html'
   */
  static String basename(String filename){ //TODO windows - linux?
   Match result = splitDeviceRe.firstMatch(filename); //TODO use splitPath
   String tail = result[3];
   if (tail == null) tail = '';
   Match result2 = splitTailRe.firstMatch(tail);
   return result2[2];
  }

  ///
  static bool isAbsolute (String path) {
   Match result = splitDeviceRe.firstMatch(path);
   String device = result[1] !=null ? result[1] : '';
   bool isUnc = device != null && device.length > 1 && device[1] != ':';
   // UNC paths are always absolute
   return result[2] !=null || isUnc;
  }

  /**
   * path.join([path1], [path2], [...])
   * Join all arguments together and normalize the resulting path.
   * Arguments must be strings.
   *
   * ex.: path.join('/foo', 'bar', 'baz/asdf', 'quux', '..') returns '/foo/bar/baz/asdf'
   */
  //TODO windows/linux
  static String join(List<String> arguments) {  //TODO use (Invocation invocation)  invocation.positionedArguments to get arguments
   List<String> paths = arguments.where((x) => x is String).toList();
   String joined = paths.join('\\');

   // Make sure that the joined path doesn't start with two slashes, because
   // normalize() will mistake it for an UNC path then.
   //
   // This step is skipped when it is very clear that the user actually
   // intended to point at an UNC path. This is assumed when the first
   // non-empty string arguments starts with exactly two slashes followed by
   // at least one more non-slash character.
   //
   // Note that for normalize() to treat a path as an UNC path it needs to
   // have at least 2 components, so we don't filter for that here.
   // This means that the user can use join to construct UNC paths from
   // a server name and a share name; for example:
   //   path.join('//server', 'share') -> '\\\\server\\share\')
  if (!new RegExp(r"^[\\\/]{2}[^\\\/]").hasMatch(paths[0])) {
    joined = joined.replaceFirst(new RegExp(r"^[\\\/]{2,}"), '\\');
  }

  return normalize(joined);
  }

  /**
   * path.normalize(p)
   * Normalize a string path, taking care of '..' and '.' parts.
   *
   * When multiple slashes are found, they're replaced by a single one;
   * when the path contains a trailing slash, it is preserved. On Windows backslashes are used.
   *
   * path.normalize('/foo/bar//baz/asdf/quux/..') returns '/foo/bar/baz/asdf'
   */
  //TODO windows/linux
  static String normalize(String path) {
   Match result = splitDeviceRe.firstMatch(path);
   String device = result[1] != null ? result[1] : '';
   bool isUnc = device != null && device.length >1 && device[1] != ':';
   bool isAbsolute = Path.isAbsolute(path);
   String tail = result[3];
   bool trailingSlash = new RegExp(r"[\\\/]$").hasMatch(tail);

   // If device is a drive letter, we'll normalize to lower case.
   if (device != null && device.length > 1 && device.substring(1,1) == ':') {
     device = device[0].toLowerCase() + device.substring(1);
   }

   // Normalize the tail path
   tail = normalizeArray(tail.split(new RegExp(r"[\\\/]+")).where((p) {
                                      return p != null;
                                    }), !isAbsolute).join('\\');

   if (tail == null && !isAbsolute) {
     tail = '.';
   }
   if (tail != null && trailingSlash) {
     tail += '\\';
   }

   // Convert slashes to backslashes when `device` points to an UNC root.
   // Also squash multiple slashes into a single one where appropriate.
   if (isUnc) {
     device = normalizeUNCRoot(device);
   }

   return device + (isAbsolute ? '\\' : '') + tail;
  }

  ///
  static List normalizeArray(Iterable<String> paths, bool allowAboveRoot) {
   // if the path tries to go above the root, `up` ends up > 0
   List parts = paths.toList();
   int up = 0;
   for (int i = parts.length - 1; i >= 0; i--) {
     String last = parts[i];
     if (last == '.') {
       parts.removeAt(i);
     } else if (last == '..') {
       parts.removeAt(i);
       up++;
     } else if (up > 0) {
       parts.removeAt(i);
       up--;
     }
   }

   // if the path is allowed to go above the root, restore leading ..s
   if (allowAboveRoot) {
     for (; up > 0; up--) {
       parts.insert(0, '..');
     }
   }

   return parts;
  }

  ///
  static String normalizeUNCRoot(String device) {
   return '\\\\' + device
     .replaceFirst(new RegExp(r"^[\\\/]+"), '')
     .replaceAll(new RegExp(r"[\\\/]+"), '\\');
  }

  ///
  /// Returns the extension of the path, from the last '.' to end of string in
  /// the last portion of the path.
  ///
  static String extname(String path) => splitPath(path)[3];
}