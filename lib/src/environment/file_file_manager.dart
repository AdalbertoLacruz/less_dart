//source: lib/less-node/file-manager.js 2.5.0

part of environment.less;

/// File loader
class FileFileManager extends FileManager {
  /// full path list of filenames used to find the file
  List<String> filenamesTried = [];

  ///
  FileFileManager(Environment environment) : super(environment);

  ///
  bool supports (String filename, String currentDirectory, Contexts options,
                   Environment environment) => true;

  ///
  bool supportsSync(String filename, String currentDirectory, Contexts options,
                      Environment environment) => true;

  ///
  /// Build the directory list where to search the file
  ///
  List<String> createListPaths(String filename, String currentDirectory, Contexts options) {
    bool isAbsoluteFilename = this.isPathAbsolute(filename);

    List<String> paths = isAbsoluteFilename ? [''] : [pathLib.normalize(currentDirectory)];
    MoreList.addAllUnique(paths, options.paths, map: (item) =>  pathLib.normalize(item));
    if (!isAbsoluteFilename) MoreList.addUnique(paths, '.');

    return paths;
  }

  ///
  /// Search asynchrously the [filename] in the [paths] directorys
  ///
  /// Returns a Future with the full path found or null
  ///
  Future findFile(String filename, List<String> paths, [int index = 0]) {
    Completer task = new Completer();
    String fullFilename;
    if (index == 0) filenamesTried.clear(); //first call not recursive

    if (index < paths.length) {
      fullFilename = environment.pathJoin(paths[index], filename);
      filenamesTried.add(fullFilename);
      new File(fullFilename).exists().then((bool exist){
        if (exist) {
          task.complete(fullFilename);
        } else {
          findFile(filename, paths, ++index).then((String fullFilename){
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
      if (new File(fullFilename).existsSync()) return fullFilename;
    }

    return null;
  }

  /// Load Async the file
  Future loadFile(String filename, String currentDirectory, Contexts options, Environment environment) {
    Completer task = new Completer();

    if (options == null) options = new Contexts();

    if (isTrue(options.syncImport)) {
      FileLoaded fileLoaded = this.loadFileSync(filename, currentDirectory, options, environment);
      if (fileLoaded.error == null) {
        task.complete(fileLoaded);
      } else {
        task.completeError(fileLoaded.error);
      }
      return task.future;
    }

    List<String> paths = createListPaths(filename, currentDirectory, options);
    findFile(filename, paths).then((String fullFilename) {
      if (fullFilename != null) {
        new File(fullFilename).readAsString().then((String data){
          task.complete(new FileLoaded(filename: fullFilename, contents: data));
        });
      } else {
        LessError error = new LessError(
            type: 'File',
            message: "'${filename}' wasn't found. Tried - ${filenamesTried.join(', ')}"
         );
        task.completeError(error);
      }
    });

    return task.future;

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
  }

  /// Load sync the file
  FileLoaded loadFileSync(String filename, String currentDirectory, Contexts options, Environment environment) {
    FileLoaded fileLoaded = new FileLoaded();
    if (options == null) options = new Contexts();

    List<String> paths = createListPaths(filename, currentDirectory, options);
    String fullFilename = findFileSync(filename, paths);
    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;
      fileLoaded.contents = new File(fullFilename).readAsStringSync();
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'${filename}' wasn't found. Tried - ${filenamesTried.join(', ')}"
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
  FileLoaded loadFileAsBytesSync(String filename, String currentDirectory, Contexts options, Environment environment) {
    FileLoaded fileLoaded = new FileLoaded();
    if (options == null) options = new Contexts();

    List<String> paths = createListPaths(filename, currentDirectory, options);
    String fullFilename = findFileSync(filename, paths);
    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;
      fileLoaded.codeUnits = new File(fullFilename).readAsBytesSync();
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'${filename}' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }

    return fileLoaded;
  }

  ///
  /// Check if [filename] exists in the include paths
  ///
  FileLoaded existSync(String filename, String currentDirectory, Contexts options, Environment environment) {
    FileLoaded fileLoaded = new FileLoaded();
    if (options == null) options = new Contexts();

    List<String> paths = createListPaths(filename, currentDirectory, options);
    String fullFilename = findFileSync(filename, paths);
    if (fullFilename != null) {
      fileLoaded.filename = fullFilename;
    } else {
      fileLoaded.error = new LessError(
          type: 'File',
          message: "'${filename}' wasn't found. Tried - ${filenamesTried.join(', ')}"
      );
    }

    return fileLoaded;
  }
}
