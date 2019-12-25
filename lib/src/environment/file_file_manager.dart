//source: lib/less-node/file-manager.js 3.0.4 20180624

part of environment.less;

/// File loader
class FileFileManager extends AbstractFileManager {
  /// packages prefix:
  ///     @import "packages/less_dart/test/import-charset-test";
  ///     @import "package://less_dart/test/import-charset-test";
  static const String PACKAGES_PREFIX = 'package';

  /// packages test:
  ///     @import "package_test://less_dart/less/import/import-charset-test";
  static const String PACKAGES_TEST = 'test';

  /// full path list of filenames used to find the file
  List<String> filenamesTried = <String>[];

  /// content cache for files yet loaded
  Map<String, String> contents = <String, String>{};

  final PackageResolverProvider _packageResolverProvider;

  ///
  FileFileManager(Environment environment, this._packageResolverProvider)
      : super(environment);

  ///
  @override
  bool supports(String filename, String currentDirectory, Contexts options,
          Environment environment) =>
      true;

  ///
  @override
  bool supportsSync(String filename, String currentDirectory, Contexts options,
          Environment environment) =>
      true;

  ///
  /// Build the directory list where to search the file
  ///
  List<String> createListPaths(
      String filename, String currentDirectory, Contexts options) {
    final isAbsoluteFilename = isPathAbsolute(filename);
    final paths = isAbsoluteFilename
        ? <String>['']
        : <String>[path_lib.normalize(currentDirectory)];
    MoreList.addAllUnique(paths, options.paths, map: path_lib.normalize);
    if (!isAbsoluteFilename) MoreList.addUnique(paths, '.');
    return paths;
  }

  ///
  /// Search asynchrously the [filename] in the [paths] directorys
  ///
  /// Returns a Future with the full path found or null
  ///
  Future<String> findFile(String filename, List<String> paths,
      [int index = 0]) {
    final task = Completer<String>();
    String fullFilename;

    if (index == 0) filenamesTried.clear(); //first call not recursive

    if (index < paths.length) {
      fullFilename = environment.pathJoin(paths[index], filename);
      filenamesTried.add(fullFilename);
      if (File(fullFilename).existsSync()) {
        task.complete(fullFilename);
      } else {
        findFile(filename, paths, index + 1).then(task.complete);
      }
    } else {
      task.complete(null);
    }
    return task.future;
  }

  ///
  /// Search the [filename] in the [paths] directories
  ///
  /// Returns the full path found or null
  ///
  String findFileSync(String filename, List<String> paths) {
    String fullFilename;

    filenamesTried.clear();
    for (var i = 0; i < paths.length; i++) {
      fullFilename = environment.pathJoin(paths[i], filename);
      filenamesTried.add(fullFilename);
      if (File(fullFilename).existsSync()) return fullFilename;
    }

    return null;
  }

  /// Load Async the file
  @override
  Future<FileLoaded> loadFile(String filename, String currentDirectory,
      Contexts options, Environment environment) async {
    final _options = options ?? Contexts();
    final _filename = (_options.ext != null)
        ? tryAppendExtension(filename, _options.ext)
        : filename;

    if (_options.syncImport ?? false) {
      final fileLoaded =
          loadFileSync(_filename, currentDirectory, _options, environment);
      if (fileLoaded.error == null) {
        return fileLoaded;
      } else {
        throw fileLoaded.error;
      }
    }
    final normalizedFilename = await normalizeFilePath(_filename);
    final paths = await _normalizePaths(
        createListPaths(_filename, currentDirectory, _options));
    final fullFilename = await findFile(normalizedFilename, paths);
    if (fullFilename != null) {
      return getLoadedFile(fullFilename);
    } else {
      throw LessError(
          type: 'File',
          message:
              "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}");
    }
  }

//3.0.4 20180624
//FileManager.prototype.loadFile = function(filename, currentDirectory, options, environment, callback) {
//
//    var fullFilename,
//        isAbsoluteFilename = this.isPathAbsolute(filename),
//        filenamesTried = [],
//        self = this,
//        prefix = filename.slice(0, 1),
//        explicit = prefix === "." || prefix === "/",
//        result = null,
//        isNodeModule = false,
//        npmPrefix = 'npm://';
//
//    options = options || {};
//
//    var paths = isAbsoluteFilename ? [''] : [currentDirectory];
//
//    if (options.paths) { paths.push.apply(paths, options.paths); }
//
//    if (!isAbsoluteFilename && paths.indexOf('.') === -1) { paths.push('.'); }
//
//    var prefixes = options.prefixes || [''];
//    var fileParts = this.extractUrlParts(filename);
//
//    if (options.syncImport) {
//        getFileData(returnData, returnData);
//        if (callback) {
//            callback(result.error, result);
//        }
//        else {
//            return result;
//        }
//    }
//    else {
//        // promise is guaranteed to be asyncronous
//        // which helps as it allows the file handle
//        // to be closed before it continues with the next file
//        return new PromiseConstructor(getFileData);
//    }
//
//    function returnData(data) {
//        if (!data.filename) {
//            result = { error: data };
//        }
//        else {
//            result = data;
//        }
//    }
//
//    function getFileData(fulfill, reject) {
//        (function tryPathIndex(i) {
//            if (i < paths.length) {
//                (function tryPrefix(j) {
//                    if (j < prefixes.length) {
//                        isNodeModule = false;
//                        fullFilename = fileParts.rawPath + prefixes[j] + fileParts.filename;
//
//                        if (paths[i]) {
//                            fullFilename = path.join(paths[i], fullFilename);
//                        }
//
//                        if (!explicit && paths[i] === '.') {
//                            try {
//                                fullFilename = require.resolve(fullFilename);
//                                isNodeModule = true;
//                            }
//                            catch (e) {
//                                filenamesTried.push(npmPrefix + fullFilename);
//                                tryWithExtension();
//                            }
//                        }
//                        else {
//                            tryWithExtension();
//                        }
//
//                        function tryWithExtension() {
//                            var extFilename = options.ext ? self.tryAppendExtension(fullFilename, options.ext) : fullFilename;
//
//                            if (extFilename !== fullFilename && !explicit && paths[i] === '.') {
//                                try {
//                                    fullFilename = require.resolve(extFilename);
//                                    isNodeModule = true;
//                                }
//                                catch (e) {
//                                    filenamesTried.push(npmPrefix + extFilename);
//                                    fullFilename = extFilename;
//                                }
//                            }
//                            else {
//                                fullFilename = extFilename;
//                            }
//                        }
//
//                        var modified = false;
//
//                        if (self.contents[fullFilename]) {
//                            try {
//                                var stat = fs.statSync.apply(this, [fullFilename]);
//                                if (stat.mtime.getTime() === self.contents[fullFilename].mtime.getTime()) {
//                                    fulfill({ contents: self.contents[fullFilename].data, filename: fullFilename});
//                                }
//                                else {
//                                    modified = true;
//                                }
//                            }
//                            catch (e) {
//                                modified = true;
//                            }
//                        }
//                        if (modified || !self.contents[fullFilename]) {
//                            var readFileArgs = [fullFilename];
//                            if (!options.rawBuffer) {
//                                readFileArgs.push('utf-8');
//                            }
//                            if (options.syncImport) {
//                                try {
//                                    var data = fs.readFileSync.apply(this, readFileArgs);
//                                    var stat = fs.statSync.apply(this, [fullFilename]);
//                                    self.contents[fullFilename] = { data: data, mtime: stat.mtime };
//                                    fulfill({ contents: data, filename: fullFilename});
//                                }
//                                catch (e) {
//                                    filenamesTried.push(isNodeModule ? npmPrefix + fullFilename : fullFilename);
//                                    return tryPrefix(j + 1);
//                                }
//                            }
//                            else {
//                                readFileArgs.push(function(e, data) {
//                                    if (e) {
//                                        filenamesTried.push(isNodeModule ? npmPrefix + fullFilename : fullFilename);
//                                        return tryPrefix(j + 1);
//                                    }
//                                    var stat = fs.statSync.apply(this, [fullFilename]);
//                                    self.contents[fullFilename] = { data: data, mtime: stat.mtime };
//                                    fulfill({ contents: data, filename: fullFilename});
//                                });
//                                fs.readFile.apply(this, readFileArgs);
//                            }
//
//                        }
//
//                    }
//                    else {
//                        tryPathIndex(i + 1);
//                    }
//                })(0);
//            } else {
//                reject({ type: 'File', message: "'" + filename + "' wasn't found. Tried - " + filenamesTried.join(",") });
//            }
//        }(0));
//    }
//};

  ///
  /// Load sync the file
  ///
  /// The content could be in:
  ///   FileLoaded.contents (cached) or
  ///   FileLoaded.codeUnits (if options.rawBuffer). Readed asBytes
  ///
  @override
  FileLoaded loadFileSync(String filename, String currentDirectory,
      Contexts options, Environment environment) {
    final fileLoaded = FileLoaded();
    final _options = options ?? Contexts();

    final paths = createListPaths(filename, currentDirectory, _options);
    final fullFilename = findFileSync(filename, paths);

    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;

      if (options.rawBuffer) {
        fileLoaded.codeUnits = File(fullFilename).readAsBytesSync();
      } else {
        if (!contents.containsKey(fullFilename)) {
          contents[fullFilename] = File(fullFilename).readAsStringSync();
        }
        fileLoaded.contents = contents[fullFilename];
      }
    } else {
      fileLoaded.error = LessError(
          type: 'File',
          message:
              "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}");
    }

    return fileLoaded;

//3.0.0 20171009
//FileManager.prototype.loadFileSync = function(filename, currentDirectory, options, environment) {
//    options.syncImport = true;
//    return this.loadFile(filename, currentDirectory, options, environment);
//};
  }

  ///
  /// Check if [filename] exists in the include paths
  ///
  @override
  FileLoaded existSync(String filename, String currentDirectory,
      Contexts options, Environment environment) {
    final fileLoaded = FileLoaded();
    final _options = options ?? Contexts();

    final paths = createListPaths(filename, currentDirectory, _options);
    final fullFilename = findFileSync(filename, paths);

    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;
    } else {
      fileLoaded.error = LessError(
          type: 'File',
          message:
              "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}");
    }

    return fileLoaded;
  }

  ///
  /// Loads file by its [fullPath]
  ///
  Future<FileLoaded> getLoadedFile(String fullPath) async {
    // in js check if file in cache has been modified. Here, by now, is not necessary
    if (contents.containsKey(fullPath)) {
      return FileLoaded(filename: fullPath, contents: contents[fullPath]);
    }
    final data = await File(fullPath).readAsString();
    contents[fullPath] = data;
    return FileLoaded(filename: fullPath, contents: data);
  }

  ///
  /// Normalizes file path (replaces package/ prefix to the absolute path)
  ///

  @override
  Future<String> normalizeFilePath(String filename) async {
    final pathData = path_lib.split(path_lib.normalize(filename));
    if (pathData.length > 1 && pathData.first.startsWith(PACKAGES_PREFIX)) {
      final packageName = pathData[1];
      var pathInPackage =
          path_lib.joinAll(pathData.getRange(2, pathData.length));
      if (pathData.first.contains(PACKAGES_TEST)) {
        //change from lib/path to test/path
        pathInPackage = '../test/$pathInPackage';
      }
      final _resolver = await _packageResolverProvider.getPackageResolver();
      var result =
          (await _resolver.urlFor(packageName, _normalizePath(pathInPackage)))
              .toFilePath();

      // urlFor.toFilePath() ignores trailing slash if path is a folder, but this slash is mandatory to ensure
      // that pathDiff in AbstractFileManager returns correct result
      if (filename.endsWith('/')) result = '$result/';
      return result;
    }
    return filename;
  }

  ///
  /// Manages "." and "..".
  /// Example:   'path/./to/..//file.text' -> 'path/file.txt'
  ///
  String _normalizePath(String path) {
    if (path_lib.isAbsolute(path)) {
      throw ArgumentError('Asset paths must be relative, but got "$path".');
    }

    // Collapse "." and "..".
    return path_lib.posix.normalize(path.replaceAll(r'\', '/'));
  }

  ///
  Future<List<String>> _normalizePaths(List<String> paths) async {
    final normalizedPaths = <String>[];
    for (final path in paths) {
      normalizedPaths.add(await normalizeFilePath(path));
    }
    return normalizedPaths;
  }
}
