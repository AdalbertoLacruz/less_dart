//source: lib/less-node/file-manager.js 2.5.0

part of environment.less;

/// File loader
class FileFileManager extends FileManager {

  /// packages prefix:
  ///     @import "packages/less_dart/test/import-charset-test";
  ///     @import "package://less_dart/test/import-charset-test";
  static const String PACKAGES_PREFIX = 'package';

  /// packages test:
  ///     @import "package_test://less_dart/less/import/import-charset-test";
  static const String PACKAGES_TEST = 'test';

  /// full path list of filenames used to find the file
  List<String> filenamesTried = <String>[];

  final PackageResolverProvider _packageResolverProvider;

  ///
  FileFileManager(Environment environment, this._packageResolverProvider) : super(environment);

  ///
  @override
  bool supports (String filename, String currentDirectory, Contexts options,
      Environment environment) => true;

  ///
  @override
  bool supportsSync(String filename, String currentDirectory, Contexts options,
      Environment environment) => true;

  ///
  /// Build the directory list where to search the file
  ///
  List<String> createListPaths(String filename, String currentDirectory, Contexts options) {
    final bool isAbsoluteFilename = isPathAbsolute(filename);
    final List<String> paths = isAbsoluteFilename
        ? <String>['']
        : <String>[pathLib.normalize(currentDirectory)];
    MoreList.addAllUnique(
        paths,
        options.paths,
        map: (String item) =>  pathLib.normalize(item)
    );
    if (!isAbsoluteFilename)
        MoreList.addUnique(paths, '.');
    return paths;
  }

  ///
  /// Search asynchrously the [filename] in the [paths] directorys
  ///
  /// Returns a Future with the full path found or null
  ///
  Future<String> findFile(String filename, List<String> paths, [int index = 0]) {
    final Completer<String> task = new Completer<String>();
    String                  fullFilename;

    if (index == 0)
        filenamesTried.clear(); //first call not recursive

    if (index < paths.length) {
      fullFilename = environment.pathJoin(paths[index], filename);
      filenamesTried.add(fullFilename);
      new File(fullFilename).exists().then((bool exist) {
        if (exist) {
          task.complete(fullFilename);
        } else {
          findFile(filename, paths, index + 1).then((String fullFilename) {
            task.complete(fullFilename);
          });
        }
      });
    } else {
      task.complete(null);
    }
    return task.future;
  }

  ///
  /// Search the [filename] in the [paths] directorys
  ///
  /// Returns the full path found or null
  ///
  String findFileSync(String filename, List<String> paths) {
    String fullFilename;

    filenamesTried.clear();
    for (int i = 0; i < paths.length; i++) {
      fullFilename = environment.pathJoin(paths[i], filename);
      filenamesTried.add(fullFilename);
      if (new File(fullFilename).existsSync())
          return fullFilename;
    }

    return null;
  }

  /// Load Async the file
  @override
  Future<FileLoaded> loadFile(String filename, String currentDirectory, Contexts options, Environment environment) async {
    final Contexts _options = options ?? new Contexts();
    if (_options.syncImport ?? false) {
      final FileLoaded fileLoaded = loadFileSync(filename, currentDirectory, _options, environment);
      if (fileLoaded.error == null) {
        return fileLoaded;
      }
      else {
        throw(fileLoaded.error);
      }
    }
    final String normalizedFilename = await _normalizeFilePath(filename);
    final List<String> paths = await _normalizePaths(createListPaths(filename, currentDirectory, _options));
    final String fullFilename = await findFile(normalizedFilename, paths);
    if (fullFilename != null) {
      return getLoadedFile(fullFilename);
    } else {
      throw new LessError(
          type: 'File',
          message: "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }
  }


//2.3.1
//FileManager.prototype.loadFile = function(filename, currentDirectory, options, environment, callback) {
//    var fullFilename,
//        data,
//        isAbsoluteFilename = this.isPathAbsolute(filename),
//        filenamesTried = [];
//
//    options = options || {};
//
//    if (options.syncImport) {
//        data = this.loadFileSync(filename, currentDirectory, options, environment, 'utf-8');
//        callback(data.error, data);
//        return;
//    }
//
//    var paths = isAbsoluteFilename ? [""] : [currentDirectory];
//    if (options.paths) { paths.push.apply(paths, options.paths); }
//    if (!isAbsoluteFilename && paths.indexOf('.') === -1) { paths.push('.'); }
//
//    // promise is guarenteed to be asyncronous
//    // which helps as it allows the file handle
//    // to be closed before it continues with the next file
//    return new PromiseConstructor(function(fulfill, reject) {
//        (function tryPathIndex(i) {
//            if (i < paths.length) {
//                fullFilename = filename;
//                if (paths[i]) {
//                    fullFilename = path.join(paths[i], fullFilename);
//                }
//                fs.stat(fullFilename, function (err) {
//                    if (err) {
//                        filenamesTried.push(fullFilename);
//                        tryPathIndex(i + 1);
//                    } else {
//                        fs.readFile(fullFilename, 'utf-8', function(e, data) {
//                            if (e) { reject(e); return; }
//
//                            fulfill({ contents: data, filename: fullFilename});
//                        });
//                    }
//                });
//            } else {
//                reject({ type: 'File', message: "'" + filename + "' wasn't found. Tried - " + filenamesTried.join(",") });
//            }
//        }(0));
//    });
//};

  /// Load sync the file
  @override
  FileLoaded loadFileSync(String filename, String currentDirectory,
        Contexts options, Environment environment) {

    final FileLoaded  fileLoaded = new FileLoaded();
    final Contexts    _options = options ?? new Contexts();

    final List<String> paths = createListPaths(filename, currentDirectory, _options);
    final String fullFilename = findFileSync(filename, paths);

    if (fullFilename != null) {
      fileLoaded
          ..filename = fullFilename
          ..contents = new File(fullFilename).readAsStringSync();
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }

    return fileLoaded;

//2.3.1
//FileManager.prototype.loadFileSync = function(filename, currentDirectory, options, environment, encoding) {
//    var fullFilename, paths, filenamesTried = [], isAbsoluteFilename = this.isPathAbsolute(filename) , data;
//    options = options || {};
//
//    paths = isAbsoluteFilename ? [""] : [currentDirectory];
//    if (options.paths) {
//        paths.push.apply(paths, options.paths);
//    }
//    if (!isAbsoluteFilename && paths.indexOf('.') === -1) {
//        paths.push('.');
//    }
//
//    var err, result;
//    for (var i = 0; i < paths.length; i++) {
//        try {
//            fullFilename = filename;
//            if (paths[i]) {
//              fullFilename = path.join(paths[i], fullFilename);
//            }
//            filenamesTried.push(fullFilename);
//            fs.statSync(fullFilename);
//            break;
//        } catch (e) {
//            fullFilename = null;
//        }
//    }
//
//    if (!fullFilename) {
//        err = { type: 'File', message: "'" + filename + "' wasn't found. Tried - " + filenamesTried.join(",") };
//        result = { error: err };
//    } else {
//        data = fs.readFileSync(fullFilename, encoding);
//        result = { contents: data, filename: fullFilename};
//     }
//
//    return result;
//};
  }

  ///
  /// Load a file syncrhonously with readAsBytesSync
  ///
  /// result in FileLoaded.codeUnits
  ///
  @override
  FileLoaded loadFileAsBytesSync(String filename, String currentDirectory,
        Contexts options, Environment environment) {

    final FileLoaded  fileLoaded = new FileLoaded();
    final Contexts    _options = options ?? new Contexts();

    final List<String> paths = createListPaths(filename, currentDirectory, _options);
    final String fullFilename = findFileSync(filename, paths);

    if (fullFilename != null) {
      fileLoaded
          ..filename = fullFilename
          ..codeUnits = new File(fullFilename).readAsBytesSync();
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }

    return fileLoaded;
  }

  ///
  /// Check if [filename] exists in the include paths
  ///
  @override
  FileLoaded existSync(String filename, String currentDirectory,
        Contexts options, Environment environment) {

    final FileLoaded  fileLoaded = new FileLoaded();
    final Contexts    _options = options ?? new Contexts();

    final List<String> paths = createListPaths(filename, currentDirectory, _options);
    final String fullFilename = findFileSync(filename, paths);

    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'$filename' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }

    return fileLoaded;
  }

  ///
  /// Loads file by its [fullPath]
  ///

  Future<FileLoaded> getLoadedFile(String fullPath) async {
    final String data = await new File(fullPath).readAsString();
    return new FileLoaded(filename: fullPath, contents: data);
  }

  Future<String> _normalizeFilePath(String filename) async {
    final List<String> pathData = pathLib.split(pathLib.normalize(filename));
    if (pathData.length > 1 && pathData.first.startsWith(PACKAGES_PREFIX)) {
      final String packageName = pathData[1];
      String pathInPackage = pathLib.joinAll(pathData.getRange(2, pathData.length));
      if (pathData.first.contains(PACKAGES_TEST)) {
        pathInPackage = '../test/$pathInPackage'; //change from lib/path to test/path
      }
      final AssetId asset = new AssetId(packageName, pathInPackage);
      final PackageResolver _resolver = await _packageResolverProvider.getPackageResolver();
      return (await _resolver.urlFor(asset.package, asset.path)).toFilePath();
    }
    return filename;
  }

  Future <List<String>> _normalizePaths(List<String> paths) async {
    final List<String> normalizedPaths = <String>[];
    for (String path in paths) {
      normalizedPaths.add(await _normalizeFilePath(path));
    }
    return normalizedPaths;
  }
}
