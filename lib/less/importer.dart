// source less/index.jx 1.7.5 lines 132-252
library immporter.less;

import 'dart:async';
import 'dart:io';

import 'env.dart';
import 'file_info.dart';
import 'less_error.dart';
import '../nodejs/nodejs.dart';

///
/// FileImporter or UrlImporter associated with @imports...
///
/// Ex.: Importer importer = new Importer(file, currentFileInfo, env);
///
class Importer {
  /// file to import
  String file;

  FileInfo currentFileInfo;

  Env env;

  /// Content read from file
  String data;

  String dirname;

  /// We must use urlLoader
  bool isUrl;

  RegExp isUrlRe = new RegExp(r'^(?:https?:)?\/\/', caseSensitive: false);

  FileInfo newFileInfo;

  /// Full file address
  String pathname;

  /// directories where to search the file
  List<String> paths;

  ///
  /// Structure to load a file from a directory or url
  ///
  Importer(this.file, this.currentFileInfo, this.env) {
    newFileInfo = new FileInfo.cloneForLoader(currentFileInfo, env);
    isUrl = isUrlRe.hasMatch(file);
  }

  ///
  /// Load the file or url
  ///
  /// Example:
  ///   new Importer(file, currentFileInfo, env).fileLoader().then((data){
  ///     ...
  ///   })
  ///   .catchError((e) {
  ///     ...
  ///   });
  ///
  Future fileLoader() {
    if (isUrl || isUrlRe.hasMatch(currentFileInfo.currentDirectory)) {
      return urlLoader();
    } else {
      createListPaths();
      if (env.syncImport) {
        return fileSyncLoader();
      } else {
        return fileAsyncLoader();
      }
    }
  }

  ///
  /// create paths
  ///
  void createListPaths() {
    paths = [currentFileInfo.currentDirectory];
    if (env.paths != null) paths.addAll(env.paths);
    paths.remove(''); // next '.' is the standard for empty current directory
    if (paths.indexOf('.') == -1) paths.add('.');
  }

  //TODO
  Future urlLoader() {

    LessError error = new LessError(
              type: 'Application',
              message: "url loader not implemented yet",
              env: env);
    throw new LessExceptionError(error);

    return new Future(null);
  }

  ///
  /// Load the file syncronously
  ///
  Future fileSyncLoader() {
    bool exist = false;

    for (int i = 0; i < paths.length; i++) {
      pathname = Path.join([paths[i], file]);
      exist = new File(pathname).existsSync();
      if (exist) break;
    }

    if (exist) {
      data = new File(pathname).readAsStringSync();
      updateFileInfo();
      return new Future.value(data);
    } else {
      pathname = null;
      LessError error = new LessError(
          type: 'File',
          message: "'$file' wasn't found",
          env: env);
      throw new LessExceptionError(error);
    }
  }

  //TODO
  Future fileAsyncLoader() {
    return new Future(null);
  }

  ///
  /// Pass on an updated rootpath if path of imported file is relative and file
  /// is in a (sub|sup) directory
  ///
  /// Examples:
  /// - If path of imported file is 'module/nav/nav.less' and rootpath is 'less/',
  ///   then rootpath should become 'less/module/nav/'
  /// - If path of imported file is '../mixins.less' and rootpath is 'less/',
  ///   then rootpath should become 'less/../'
  ///
  void updateFileInfo() {
    int j = file.lastIndexOf('/');
    RegExp regFile = new RegExp(r'^(?:[a-z-]+:|\/)');

    if (newFileInfo.relativeUrls && !regFile.hasMatch(file) && j != -1) {
      String relativeSubdirectory = file.substring(0, j + 1);
      // append (sub|sup) directory path of imported file
      newFileInfo.rootpath = newFileInfo.rootpath + relativeSubdirectory;
    }
    newFileInfo.currentDirectory = pathname.replaceAll(new RegExp(r'[^\\\/]*$'), '');
    newFileInfo.filename = pathname;
  }
}

//var isUrlRe = /^(?:https?:)?\/\//i;
//
//less.Parser.fileLoader = function (file, currentFileInfo, callback, env) {
//    var pathname, dirname, data,
//        newFileInfo = {
//            relativeUrls: env.relativeUrls,
//            entryPath: currentFileInfo.entryPath,
//            rootpath: currentFileInfo.rootpath,
//            rootFilename: currentFileInfo.rootFilename
//        };
//
//    function handleDataAndCallCallback(data) {
//        var j = file.lastIndexOf('/');
//
//        // Pass on an updated rootpath if path of imported file is relative and file
//        // is in a (sub|sup) directory
//        //
//        // Examples:
//        // - If path of imported file is 'module/nav/nav.less' and rootpath is 'less/',
//        //   then rootpath should become 'less/module/nav/'
//        // - If path of imported file is '../mixins.less' and rootpath is 'less/',
//        //   then rootpath should become 'less/../'
//        if(newFileInfo.relativeUrls && !/^(?:[a-z-]+:|\/)/.test(file) && j != -1) {
//            var relativeSubDirectory = file.slice(0, j+1);
//            newFileInfo.rootpath = newFileInfo.rootpath + relativeSubDirectory; // append (sub|sup) directory path of imported file
//        }
//        newFileInfo.currentDirectory = pathname.replace(/[^\\\/]*$/, "");
//        newFileInfo.filename = pathname;
//
//        callback(null, data, pathname, newFileInfo);
//    }
//
//    var isUrl = isUrlRe.test( file );
//    if (isUrl || isUrlRe.test(currentFileInfo.currentDirectory)) {
//        if (request === undefined) {
//            try { request = require('request'); }
//            catch(e) { request = null; }
//        }
//        if (!request) {
//            callback({ type: 'File', message: "optional dependency 'request' required to import over http(s)\n" });
//            return;
//        }
//
//        var urlStr = isUrl ? file : url.resolve(currentFileInfo.currentDirectory, file),
//            urlObj = url.parse(urlStr);
//
//        if (!urlObj.protocol) {
//            urlObj.protocol = "http";
//            urlStr = urlObj.format();
//        }
//
//        request.get({uri: urlStr, strictSSL: !env.insecure }, function (error, res, body) {
//            if (error) {
//                callback({ type: 'File', message: "resource '" + urlStr + "' gave this Error:\n  "+ error +"\n" });
//                return;
//            }
//            if (res.statusCode === 404) {
//                callback({ type: 'File', message: "resource '" + urlStr + "' was not found\n" });
//                return;
//            }
//            if (!body) {
//                console.error( 'Warning: Empty body (HTTP '+ res.statusCode + ') returned by "' + urlStr +'"' );
//            }
//            pathname = urlStr;
//            dirname = urlObj.protocol +'//'+ urlObj.host + urlObj.pathname.replace(/[^\/]*$/, '');
//            handleDataAndCallCallback(body);
//        });
//    } else {
//
//        var paths = [currentFileInfo.currentDirectory];
//        if (env.paths) paths.push.apply(paths, env.paths);
//        if (paths.indexOf('.') === -1) paths.push('.');
//
//        if (env.syncImport) {
//            for (var i = 0; i < paths.length; i++) {
//                try {
//                    pathname = path.join(paths[i], file);
//                    fs.statSync(pathname);
//                    break;
//                } catch (e) {
//                    pathname = null;
//                }
//            }
//
//            if (!pathname) {
//                callback({ type: 'File', message: "'" + file + "' wasn't found" });
//                return;
//            }
//
//            try {
//                data = fs.readFileSync(pathname, 'utf-8');
//                handleDataAndCallCallback(data);
//            } catch (e) {
//                callback(e);
//            }
//        } else {
//            (function tryPathIndex(i) {
//                if (i < paths.length) {
//                    pathname = path.join(paths[i], file);
//                    fs.stat(pathname, function (err) {
//                        if (err) {
//                            tryPathIndex(i + 1);
//                        } else {
//                            fs.readFile(pathname, 'utf-8', function(e, data) {
//                                if (e) { callback(e); return; }
//
//                                // do processing in the next tick to allow
//                                // file handling to dispose
//                                process.nextTick(function() {
//                                    handleDataAndCallCallback(data);
//                                });
//                            });
//                        }
//                    });
//                } else {
//                    callback({ type: 'File', message: "'" + file + "' wasn't found" });
//                }
//            }(0));
//        }
//    }
//};
