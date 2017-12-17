//source: lib/less/environment/abstract-file-manager.js 3.0.0 20171009

part of environment.less;

///
class AbstractFileManager {
  ///
  Environment environment;

  ///
  AbstractFileManager(this.environment);

  ///
  /// This FileManager can load async the filename
  ///
  bool supports (String filename, String currentDirectory, Contexts options,
      Environment environment) => false;

  ///
  /// Returns whether this file manager supports this file for syncronous file retrieval
  /// If true is returned, loadFileSync will then be called with the file.
  ///
  bool supportsSync(String filename, String currentDirectory, Contexts options,
      Environment environment) => false;

  ///
  /// Loads a file asynchronously. Expects a Future that either rejects with an error or fulfills with an
  /// object containing
  /// { filename: - full resolved path to file
  ///   contents: - the contents of the file, as a string }
  ///
  Future<FileLoaded> loadFile(String filename, String currentDirectory,
      Contexts options, Environment environment) => null;

  ///
  /// Loads a file synchronously. Expects an immediate return with an object containing
  ///   { error: - error object if an error occurs
  ///     filename: - full resolved path to file
  ///     contents: - the contents of the file, as a string or
  ///     codeunits: - the contents of the file, asBytes }
  ///
  FileLoaded loadFileSync(String filename, String currentDirectory,
      Contexts options, Environment environment) => null;

  ///
  /// Check if [filename] exists in the include paths
  ///
  FileLoaded existSync(String filename, String currentDirectory,
      Contexts options, Environment environment) => null;

  ///
  /// Given the full path to a file [filename], return the path component
  ///
  String getPath(String filename) => pathLib.dirname(filename);

  ///
  /// Normalizes file path (replaces package/ prefix to the absolute path)
  ///
  Future<String> normalizeFilePath(String filename) async => filename;

  //2.3.1
//abstractFileManager.prototype.getPath = function (filename) {
//    var j = filename.lastIndexOf('?');
//    if (j > 0) {
//        filename = filename.slice(0, j);
//    }
//    j = filename.lastIndexOf('/');
//    if (j < 0) {
//        j = filename.lastIndexOf('\\');
//    }
//    if (j < 0) {
//        return "";
//    }
//    return filename.slice(0, j + 1);
//};

  ///
  /// Append a [ext] extension to [path] if appropriate.
  ///
  String tryAppendExtension(String path, String ext) {
    final RegExp re = new RegExp(r'(\.[a-z]*$)|([\?;].*)$');
    return re.hasMatch(path) ? path : '$path$ext';

//2.4.0 20150226
//  abstractFileManager.prototype.tryAppendExtension = function(path, ext) {
//      return /(\.[a-z]*$)|([\?;].*)$/.test(path) ? path : path + ext;
//  };
  }

  ///
  /// Append a .less extension to [path] if appropriate.
  /// Only called if less thinks one could be added.
  ///
  String tryAppendLessExtension(String path) => tryAppendExtension(path, '.less');

//2.4.0 20150226
//  abstractFileManager.prototype.tryAppendLessExtension = function(path) {
//      return this.tryAppendExtension(path, '.less');
//  };

  ///
  /// Whether the rootpath should be converted to be absolute.
  /// Only for browser compatibility
  ///
  bool alwaysMakePathsAbsolute() => false;

  ///
  /// Returns whether a path is absolute
  ///
  bool isPathAbsolute(String path) => pathLib.isAbsolute(path);

//2.4.0
//  abstractFileManager.prototype.isPathAbsolute = function(filename) {
//      return (/^(?:[a-z-]+:|\/|\\|#)/i).test(filename);
//  };

  ///
  /// Joins together 2 paths
  ///
  String join(String basePath, String laterPath) => pathLib.join(basePath, laterPath);

//2.3.1
//abstractFileManager.prototype.join = function(basePath, laterPath) {
//    if (!basePath) {
//        return laterPath;
//    }
//    return basePath + laterPath;
//};

  ///
  /// Returns the difference between 2 paths to create a relative path
  ///
  /// Example:
  ///   url = 'a/'   baseUrl = 'a/b/' returns '../'
  ///   url = 'a/b/' baseUrl = 'a/'   returns 'b/'
  ///
  String pathDiff(String url, String baseUrl) {
    final UrlParts  baseUrlParts = extractUrlParts(baseUrl);
    int             i;
    final UrlParts  urlParts = extractUrlParts(url);

    if (urlParts.hostPart != baseUrlParts.hostPart)
        return '';

    final int max = math.max(baseUrlParts.directories.length, urlParts.directories.length);

    for (i = 0; i < max; i++) {
      if (baseUrlParts.directories[i] != urlParts.directories[i])
          break;
    }
    final List<String> baseUrlDirectories = baseUrlParts.directories.sublist(i);
    final List<String> urlDirectories = urlParts.directories.sublist(i);

    if (baseUrlDirectories.isEmpty && urlDirectories.isEmpty) {  //both directories are the same
      return './';
    }

    urlDirectories[urlDirectories.length - 1] = ''; //join must end with '/'
    return '${"../" * (baseUrlDirectories.length - 1)}${urlDirectories.join("/")}';

//2.3.1
//abstractFileManager.prototype.pathDiff = function pathDiff(url, baseUrl) {
//    // diff between two paths to create a relative path
//
//    var urlParts = this.extractUrlParts(url),
//        baseUrlParts = this.extractUrlParts(baseUrl),
//        i, max, urlDirectories, baseUrlDirectories, diff = "";
//    if (urlParts.hostPart !== baseUrlParts.hostPart) {
//        return "";
//    }
//    max = Math.max(baseUrlParts.directories.length, urlParts.directories.length);
//    for(i = 0; i < max; i++) {
//        if (baseUrlParts.directories[i] !== urlParts.directories[i]) { break; }
//    }
//    baseUrlDirectories = baseUrlParts.directories.slice(i);
//    urlDirectories = urlParts.directories.slice(i);
//    for(i = 0; i < baseUrlDirectories.length - 1; i++) {
//        diff += "../";
//    }
//    for(i = 0; i < urlDirectories.length - 1; i++) {
//        diff += urlDirectories[i] + "/";
//    }
//    return diff;
//};
  }

  ///
  UrlParts extractUrlParts(String url, [String baseUrl]) {
    // urlParts[1] = protocol://hostname/ OR /
    // urlParts[2] = / if path relative to host base
    // urlParts[3] = directories
    // urlParts[4] = filename
    // urlParts[5] = parameters

    final RegExp urlPartsRegex = new RegExp(r'^((?:[a-z-]+:)?\/{2}(?:[^\/\?#]*\/)|([\/\\]))?((?:[^\/\\\?#]*[\/\\])*)([^\/\\\?#]*)([#\?].*)?$', caseSensitive: false);
    final List<String> urlParts = <String>[];

    Match match = urlPartsRegex.firstMatch(url);
    if (match != null)
        for (int i = 0; i < match.groupCount; i++) {
          urlParts.add(match[i]);
        }

    final UrlParts returner = new UrlParts();

    if (urlParts.isEmpty) {
      final LessError error = new LessError(
          message: "Could not parse sheet href - '$url'");
      throw new LessExceptionError(error);
    }

    List<String> directories = <String>[];
    String rawPath = '';

    // Stylesheets in IE don't always return the full path
    if (baseUrl != null && (urlParts[1] == null || urlParts[2] != null)) {
      match = urlPartsRegex.firstMatch(baseUrl);
      final List<String> baseUrlParts = <String>[];
      if (match != null)
          for (int i = 0; i < match.groupCount; i++) {
            baseUrlParts.add(match[i]);
          }

      if (baseUrlParts.isEmpty) {
        final LessError error = new LessError(
            message: "Could not parse page url - '$baseUrl'");
        throw new LessExceptionError(error);
      }

      urlParts[1] ??= baseUrlParts[1] ?? '';
      urlParts[2] ??= '${baseUrlParts[3]}${urlParts[3]}';
    }

    if (urlParts[3] != null) {
      rawPath = urlParts[3].replaceAll('\\', '/');
      // collapse '..' and skip '.'
      directories = pathLib.split(pathLib.normalize(rawPath))..add('');
    }

    for (int i = 0; i < urlParts.length; i ++) {
      if (urlParts[i] == null)
          urlParts[i] = '';
    }

    for (int i = urlParts.length; i < 6; i++) {
      urlParts.add('');
    }

    returner
        ..hostPart = urlParts[1]
        ..directories = directories
        ..rawPath = '${urlParts[1]}$rawPath'
        ..path = '${urlParts[1]}${directories.join('/')}'
        ..filename = urlParts[4]
        ..fileUrl = '${returner.path}${urlParts[4]}'
        ..url = '${returner.fileUrl}${urlParts[5]}';
    return returner;

//3.0.0 20171009
// helper function, not part of API
//abstractFileManager.prototype.extractUrlParts = function extractUrlParts(url, baseUrl) {
//    // urlParts[1] = protocol://hostname/ OR /
//    // urlParts[2] = / if path relative to host base
//    // urlParts[3] = directories
//    // urlParts[4] = filename
//    // urlParts[5] = parameters
//
//    var urlPartsRegex = /^((?:[a-z-]+:)?\/{2}(?:[^\/\?#]*\/)|([\/\\]))?((?:[^\/\\\?#]*[\/\\])*)([^\/\\\?#]*)([#\?].*)?$/i,
//        urlParts = url.match(urlPartsRegex),
//        returner = {}, rawDirectories = [], directories = [], i, baseUrlParts;
//
//    if (!urlParts) {
//        throw new Error("Could not parse sheet href - '" + url + "'");
//    }
//
//    // Stylesheets in IE don't always return the full path
//    if (baseUrl && (!urlParts[1] || urlParts[2])) {
//        baseUrlParts = baseUrl.match(urlPartsRegex);
//        if (!baseUrlParts) {
//            throw new Error("Could not parse page url - '" + baseUrl + "'");
//        }
//        urlParts[1] = urlParts[1] || baseUrlParts[1] || "";
//        if (!urlParts[2]) {
//            urlParts[3] = baseUrlParts[3] + urlParts[3];
//        }
//    }
//
//    if (urlParts[3]) {
//        rawDirectories = urlParts[3].replace(/\\/g, "/").split("/");
//
//        // collapse '..' and skip '.'
//        for (i = 0; i < rawDirectories.length; i++) {
//
//            if (rawDirectories[i] === "..") {
//                directories.pop();
//            }
//            else if (rawDirectories[i] !== ".") {
//                directories.push(rawDirectories[i]);
//            }
//
//        }
//    }
//
//    returner.hostPart = urlParts[1];
//    returner.directories = directories;
//    returner.rawPath = (urlParts[1] || "") + rawDirectories.join("/");
//    returner.path = (urlParts[1] || "") + directories.join("/");
//    returner.filename = urlParts[4];
//    returner.fileUrl = returner.path + (urlParts[4] || "");
//    returner.url = returner.fileUrl + (urlParts[5] || "");
//    return returner;
//};
  }
}

// ---------------------------------------------------

/// return type for loadFile
class FileLoaded {
  ///
  String    filename;
  ///
  String    contents;
  ///
  LessError error;
  ///
  List<int> codeUnits;

  ///
  FileLoaded({this.filename, this.contents, this.error, this.codeUnits});
}

///
class UrlParts {
  ///
  List<String>  directories;
  ///
  String        hostPart;
  ///
  String        filename;
  ///
  String        fileUrl;
  ///
  String        path;
  ///
  String        rawPath;
  ///
  String        url;
}
