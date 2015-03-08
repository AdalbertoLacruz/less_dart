//source: lib/less/environment/abstract-file-manager.js 2.4.0

part of environment.less;

class FileManager {
  Environment environment;

  ///
  FileManager(this.environment);

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

  /// Loads a file asynchronously. Expects a Future that either rejects with an error or fulfills with an
  /// object containing
  /// { filename: - full resolved path to file
  ///   contents: - the contents of the file, as a string }
  ///
  //2.3.1
  Future loadFile(String filename, String currentDirectory, Contexts options, Environment environment) => null;

  ///
  /// Loads a file synchronously. Expects an immediate return with an object containing
  ///   { error: - error object if an error occurs
  ///     filename: - full resolved path to file
  ///     contents: - the contents of the file, as a string }
  ///
  //2.3.1
  FileLoaded loadFileSync(String filename, String currentDirectory, Contexts options, Environment environment) => null;

  ///
  /// Load a file syncrhonously with readAsBytesSync
  ///
  /// result in FileLoaded.codeUnits
  ///
  FileLoaded loadFileAsBytesSync(String filename, String currentDirectory, Contexts options, Environment environment) => null;

  ///
  /// Given the full path to a file [filename], return the path component
  ///
  //2.3.1 ok
  String getPath(String filename) {
    return pathLib.dirname(filename);

// valid dart implementation
//    int j = filename.lastIndexOf('?');
//    if (j > 0) filename = filename.substring(0, j);
//
//    j = filename.lastIndexOf('/');
//    if (j < 0) j = filename.lastIndexOf('\\');
//
//    if (j < 0) return '';
//
//    return filename.substring(0, j + 1);

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
  }

  ///
  /// Append a .less extension to [path] if appropriate.
  /// Only called if less thinks one could be added.
  ///
  //2.3.1 ok
  String tryAppendLessExtension(String path) {
    RegExp re = new RegExp(r'(\.[a-z]*$)|([\?;].*)$');
    return re.hasMatch(path) ? path : path + '.less';

//2.3.1
//abstractFileManager.prototype.tryAppendLessExtension = function(path) {
//    return /(\.[a-z]*$)|([\?;].*)$/.test(path) ? path : path + '.less';
//};
  }

  ///
  /// Whether the rootpath should be converted to be absolute.
  /// Only for browser compatibility
  ///
  //2.3.1 ok
  bool alwaysMakePathsAbsolute() => false;


  ///
  /// Returns whether a path is absolute
  ///
  bool isPathAbsolute(String path) {
    return pathLib.isAbsolute(path);

// valid dart implementation
//    RegExp re = new RegExp(r'^(?:[a-z-]+:|\/|\\|#)', caseSensitive: false);
//    return re.hasMatch(path);

//2.4.0
//  abstractFileManager.prototype.isPathAbsolute = function(filename) {
//      return (/^(?:[a-z-]+:|\/|\\|#)/i).test(filename);
//  };
  }

  ///
  /// Joins together 2 paths
  ///
  //2.3.1 untested.
  String join(String basePath, String laterPath) {
    return pathLib.join(basePath, laterPath);

//valid dart implementation
//    if (basePath == null) return laterPath;
//    return basePath + laterPath;

//2.3.1
//abstractFileManager.prototype.join = function(basePath, laterPath) {
//    if (!basePath) {
//        return laterPath;
//    }
//    return basePath + laterPath;
//};
  }

  ///
  /// Returns the difference between 2 paths to create a relative path
  ///
  /// Example:
  ///   url = 'a/'   baseUrl = 'a/b/' returns '../'
  ///   url = 'a/b/' baseUrl = 'a/'   returns 'b/'
  ///
  //2.3.1 untested. pathLib.relative?
  String pathDiff(String url, String baseUrl) {
    UrlParts urlParts = extractUrlParts(url);
    UrlParts baseUrlParts = extractUrlParts(baseUrl);
    List<String> urlDirectories;
    List<String> baseUrlDirectories;
    int i;
    String diff = '';

    if (urlParts.hostPart != baseUrlParts.hostPart) return '';

    int max = math.max(baseUrlParts.directories.length, urlParts.directories.length);

    for (i = 0; i < max; i++) {
      if (baseUrlParts.directories[i] != urlParts.directories[i]) break;
    }
    baseUrlDirectories = baseUrlParts.directories.sublist(i);
    urlDirectories = urlParts.directories.sublist(i);

    for (i = 0; i < baseUrlDirectories.length - 1; i++) {
      diff += '../';
    }
    for (i = 0; i < urlDirectories.length - 1; i++) {
      diff += urlDirectories[i] + '/';
    }

    return diff;

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
  //2.3.1 untested
  UrlParts extractUrlParts(String url, [String baseUrl]) {
    // urlParts[1] = protocol&hostname || /
    // urlParts[2] = / if path relative to host base
    // urlParts[3] = directories
    // urlParts[4] = filename
    // urlParts[5] = parameters

    RegExp urlPartsRegex = new RegExp(r'^((?:[a-z-]+:)?\/+?(?:[^\/\?#]*\/)|([\/\\]))?((?:[^\/\\\?#]*[\/\\])*)([^\/\\\?#]*)([#\?].*)?$', caseSensitive: false);
    List<String> urlParts = [];
    Iterable<Match> match = urlPartsRegex.allMatches(url);
    if (match != null) match.forEach((Match m) => urlParts.add(m[0]));

    UrlParts returner = new UrlParts();
    List<String> directories;
    String baseUrlParts;

    if (urlParts.isEmpty) {
      LessError error = new LessError(
                message: "Could not parse sheet href - '${url}'");
      throw new LessExceptionError(error);
    }

    // Stylesheets in IE don't always return the full path
    if (baseUrl != null && (urlParts[1] == null || urlParts[2] != null)) {
      match = urlPartsRegex.allMatches(baseUrl);
      List<String> baseUrlParts = [];
      if (match != null) match.forEach((Match m) => baseUrlParts.add(m[0]));
      if (baseUrlParts.isEmpty) {
        LessError error = new LessError(
                  message: "Could not parse page url - '${baseUrl}'");
        throw new LessExceptionError(error);
      }

      if (urlParts[1] == null) urlParts[1] = baseUrlParts[1];
      if (urlParts[1] == null) urlParts[1] = '';

      if (urlParts[2] == null) urlParts[3] = baseUrlParts[3] + urlParts[3];
    }

    if (urlParts[3] != null) {
      directories = urlParts[3].replaceAll('\\', '/').split('/');

      // extract out . before .. so .. doesn't absorb a non-directory
      directories.remove('.');

      for (int i = 0; i < directories.length; i++) {
        if (directories[i] == '..' && i > 0) {
          directories.removeRange(i-1, i+1);
          i -= 2;
        }
      }
    }

    for (int i = 0; i < urlParts.length; i ++) if (urlParts[i] == null) urlParts[i] = '';

    returner.hostPart = urlParts[1];
    returner.directories = directories;
    returner.path = urlParts[1]  + directories.join('/');
    returner.fileUrl = returner.path + urlParts[4];
    returner.url = returner.fileUrl + urlParts[5];

    return returner;

//2.3.1
//// helper function, not part of API
//abstractFileManager.prototype.extractUrlParts = function extractUrlParts(url, baseUrl) {
//    // urlParts[1] = protocol&hostname || /
//    // urlParts[2] = / if path relative to host base
//    // urlParts[3] = directories
//    // urlParts[4] = filename
//    // urlParts[5] = parameters
//
//    var urlPartsRegex = /^((?:[a-z-]+:)?\/+?(?:[^\/\?#]*\/)|([\/\\]))?((?:[^\/\\\?#]*[\/\\])*)([^\/\\\?#]*)([#\?].*)?$/i,
//        urlParts = url.match(urlPartsRegex),
//        returner = {}, directories = [], i, baseUrlParts;
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
//        directories = urlParts[3].replace(/\\/g, "/").split("/");
//
//        // extract out . before .. so .. doesn't absorb a non-directory
//        for(i = 0; i < directories.length; i++) {
//            if (directories[i] === ".") {
//                directories.splice(i, 1);
//                i -= 1;
//            }
//        }
//
//        for(i = 0; i < directories.length; i++) {
//            if (directories[i] === ".." && i > 0) {
//                directories.splice(i - 1, 2);
//                i -= 2;
//            }
//        }
//    }
//
//    returner.hostPart = urlParts[1];
//    returner.directories = directories;
//    returner.path = (urlParts[1] || "") + directories.join("/");
//    returner.fileUrl = returner.path + (urlParts[4] || "");
//    returner.url = returner.fileUrl + (urlParts[5] || "");
//    return returner;
//};
  }
}

// ---------------------------------------------------

/// return type for loadFile
class FileLoaded {
  String filename;
  String contents;
  LessError error;
  List<int> codeUnits;

  FileLoaded({this.filename, this.contents, this.error, this.codeUnits});
}

class UrlParts {
  String hostPart;
  List<String> directories;
  String path;
  String fileUrl;
  String url;
}
