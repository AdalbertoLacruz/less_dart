//source: less/import-manager.js 3.0.0 20171009

library importmanager.less;

import 'dart:async';
import 'package:path/path.dart' as pathLib;

import 'contexts.dart';
import 'environment/environment.dart';
import 'file_info.dart';
import 'less_error.dart';
import 'parser/parser.dart';
import 'tree/tree.dart';

// FileInfo = {
//  'relativeUrls' - option - whether to adjust URL's to be relative
//  'filename' - full resolved filename of current file
//  'rootpath' - path to append to normal URLs for this node
//  'currentDirectory' - path to the current file, absolute
//  'rootFilename' - filename of the base file
//  'entryPath' - absolute path to the entry file
//  'reference' - whether the file should not be output and only output parts that are referenced

///
class ImportManager {
  /// Map - filename to contents of all the imported files
  Map<String, String> contents = <String, String>{};

  /// Map - filename to lines at the beginning of each file to ignore
  Map<String, int> contentsIgnoredChars = <String, int>{};

  ///
  Contexts context;

  ///
  Environment environment;

  /// Error in parsing/evaluating an import
  LessError error;

  /// Holds the imported parse trees
  Map<String, ImportedFile> files = <String, ImportedFile>{};

  /// MIME type of .less files
  String mime;

  /// Directories where to search the file when importing
  List<String> paths;

  ///
  String rootFilename;

  /// Files which haven't been imported yet
  List<String> queue = <String>[]; // Deprecated?

  ///
  ImportManager(this.context, FileInfo rootFileInfo) {
    rootFilename = rootFileInfo.filename;
    paths = context.paths ?? <String>[];
    mime = context.mime;
    environment = new Environment();

//3.0.0 20170608
//  var ImportManager = function(less, context, rootFileInfo) {
//    this.less = less;
//    this.rootFilename = rootFileInfo.filename;
//    this.paths = context.paths || [];  // Search paths, when importing
//    this.contents = {};             // map - filename to contents of all the files
//    this.contentsIgnoredChars = {}; // map - filename to lines at the beginning of each file to ignore
//    this.mime = context.mime;
//    this.error = null;
//    this.context = context;
//    // Deprecated? Unused outside of here, could be useful.
//    this.queue = [];        // Files which haven't been imported yet
//    this.files = {};        // Holds the imported parse trees.
//  };
  }

  ///
  /// Build the return content and save in files cache
  /// [root] = Node | String
  ///
  ImportedFile fileParsedFunc(String path, dynamic root, String fullPath,
      ImportOptions importOptions, {bool useCache = false}) {
    //
    queue.remove(path);

    if (useCache)
        return files[fullPath];

    final ImportedFile importedFile = new ImportedFile(
        root: root,
        importedPreviously: (fullPath == rootFilename), // importedEqualsRoot
        fullPath: fullPath,
        options: importOptions);

    // in js only if (!files.containsKey[fullPath]). But if we are here, don't like the cache
    if (fullPath != null)
        files[fullPath] = importedFile;

    return importedFile;
  }

//3.0.0 20170608
//  var fileParsedFunc = function (e, root, fullPath) {
//      importManager.queue.splice(importManager.queue.indexOf(path), 1); // Remove the path from the queue
//
//      var importedEqualsRoot = fullPath === importManager.rootFilename;
//      if (importOptions.optional && e) {
//          callback(null, {rules:[]}, false, null);
//      }
//      else {
//          if (!importManager.files[fullPath]) {
//              importManager.files[fullPath] = { root: root, options: importOptions };
//          }
//          if (e && !importManager.error) { importManager.error = e; }
//          callback(e, root, importedEqualsRoot, fullPath);
//      }
//  };

  ///
  /// Add an import to be imported
  ///
  /// Parameters:
  ///   [path] is the raw path
  ///   [currentFileInfo] the current file info (used for instance to work out relative paths)
  ///   [importOptions] import options
  ///   [tryAppendLessExtension] whether to try appending the less extension (if the path has no extension)
  ///
  Future<ImportedFile> push(
      String path,
      FileInfo currentFileInfo,
      ImportOptions importOptions,
      {bool tryAppendLessExtension = false}) {

    final Contexts                  _context = context.clone();
    final Completer<ImportedFile>   task = new Completer<ImportedFile>();

    queue.add(path);

    final FileInfo newFileInfo = new FileInfo
        .cloneForLoader(currentFileInfo, _context);

    final AbstractFileManager fileManager = environment.getFileManager(
        path, currentFileInfo.currentDirectory, _context, environment);

    if (fileManager == null) {
      task.completeError(new LessError(
          message: 'Could not find a file-manager for $path'));
      return task.future;
    }

    if (tryAppendLessExtension)
        _context.ext = '.less';

    fileManager
        .loadFile(path, currentFileInfo.currentDirectory, _context, environment)
        .then((FileLoaded loadedFile) {
          final String resolvedFilename = loadedFile.filename;
          final String contents = loadedFile.contents.replaceFirst(new RegExp('^\uFEFF'), '');

          // Pass on an updated rootpath if path of imported file is relative and file
          // is in a (sub|sup) directory
          //
          // Examples:
          // - If path of imported file is 'module/nav/nav.less' and rootpath is 'less/',
          //   then rootpath should become 'less/module/nav/'
          // - If path of imported file is '../mixins.less' and rootpath is 'less/',
          //   then rootpath should become 'less/../'

          newFileInfo.currentDirectory = fileManager.getPath(resolvedFilename);
          if (newFileInfo.relativeUrls) {
            String currentDirectory = newFileInfo.currentDirectory;
            if (!currentDirectory.endsWith(pathLib.separator))
                // ignore: prefer_interpolation_to_compose_strings
                currentDirectory += pathLib.separator;

            final String pathdiff = fileManager.pathDiff(currentDirectory, newFileInfo.entryPath);
            newFileInfo.rootpath = fileManager.join((_context.rootpath ?? ''), pathdiff);

            if (!fileManager.isPathAbsolute(newFileInfo.rootpath) && fileManager.alwaysMakePathsAbsolute()) {
              newFileInfo.rootpath = fileManager.join(newFileInfo.entryPath, newFileInfo.rootpath);
            }
          }
          newFileInfo.filename = resolvedFilename;

          final Contexts newEnv = new Contexts.parse(_context)
              ..processImports = false
              ..currentFileInfo = newFileInfo; // Not in original

          this.contents[resolvedFilename] = contents;

          if (currentFileInfo.reference || (importOptions?.reference ?? false))
              newFileInfo.reference = true;

          // if (importOptions.isPlugin) ...
          if (importOptions?.inline ?? false) {
            task.complete(fileParsedFunc(path, contents, resolvedFilename, importOptions));

          // import (multiple) parse trees apparently get altered and can't be cached.
          // TODO: investigate why this is (js)
          } else if (files.containsKey(resolvedFilename)
            && !(files[resolvedFilename].options?.multiple ?? false)
            && !(importOptions?.multiple ?? false)) {
            task.complete(fileParsedFunc(path, null, resolvedFilename, importOptions, useCache: true));
          } else {
            new Parser.fromImporter(newEnv, this, newFileInfo)
                .parse(contents)
                .then((Ruleset root) {
                  task.complete(fileParsedFunc(path, root, resolvedFilename, importOptions));
                }).catchError((Object e) {
                  task.completeError(e);
                });
          }
        }).catchError((Object e) {
          //importOptions.optional: continue compiling when file is not found
          if (importOptions?.optional ?? false) {
            task.complete(fileParsedFunc(path, new Ruleset(<Selector>[], <Node>[]), null, importOptions));
          } else {
            task.completeError(e);
          }
        });

    return task.future;

//3.0.0 20171009
//  ImportManager.prototype.push = function (path, tryAppendExtension, currentFileInfo, importOptions, callback) {
//      var importManager = this,
//          pluginLoader = this.context.pluginManager.Loader;
//
//      this.queue.push(path);
//
//      var fileParsedFunc = function (e, root, fullPath) {
//          importManager.queue.splice(importManager.queue.indexOf(path), 1); // Remove the path from the queue
//
//          var importedEqualsRoot = fullPath === importManager.rootFilename;
//          if (importOptions.optional && e) {
//              callback(null, {rules:[]}, false, null);
//          }
//          else {
//              if (!importManager.files[fullPath]) {
//                  importManager.files[fullPath] = { root: root, options: importOptions };
//              }
//              if (e && !importManager.error) { importManager.error = e; }
//              callback(e, root, importedEqualsRoot, fullPath);
//          }
//      };
//
//      var newFileInfo = {
//          relativeUrls: this.context.relativeUrls,
//          entryPath: currentFileInfo.entryPath,
//          rootpath: currentFileInfo.rootpath,
//          rootFilename: currentFileInfo.rootFilename
//      };
//
//      var fileManager = environment.getFileManager(path, currentFileInfo.currentDirectory, this.context, environment);
//
//      if (!fileManager) {
//          fileParsedFunc({ message: "Could not find a file-manager for " + path });
//          return;
//      }
//
//      var loadFileCallback = function(loadedFile) {
//          var plugin,
//              resolvedFilename = loadedFile.filename,
//              contents = loadedFile.contents.replace(/^\uFEFF/, '');
//
//          // Pass on an updated rootpath if path of imported file is relative and file
//          // is in a (sub|sup) directory
//          //
//          // Examples:
//          // - If path of imported file is 'module/nav/nav.less' and rootpath is 'less/',
//          //   then rootpath should become 'less/module/nav/'
//          // - If path of imported file is '../mixins.less' and rootpath is 'less/',
//          //   then rootpath should become 'less/../'
//          newFileInfo.currentDirectory = fileManager.getPath(resolvedFilename);
//          if (newFileInfo.relativeUrls) {
//              newFileInfo.rootpath = fileManager.join(
//                  (importManager.context.rootpath || ""),
//                  fileManager.pathDiff(newFileInfo.currentDirectory, newFileInfo.entryPath));
//
//              if (!fileManager.isPathAbsolute(newFileInfo.rootpath) && fileManager.alwaysMakePathsAbsolute()) {
//                  newFileInfo.rootpath = fileManager.join(newFileInfo.entryPath, newFileInfo.rootpath);
//              }
//          }
//          newFileInfo.filename = resolvedFilename;
//
//          var newEnv = new contexts.Parse(importManager.context);
//
//          newEnv.processImports = false;
//          importManager.contents[resolvedFilename] = contents;
//
//          if (currentFileInfo.reference || importOptions.reference) {
//              newFileInfo.reference = true;
//          }
//
//          if (importOptions.isPlugin) {
//              plugin = pluginLoader.evalPlugin(contents, newEnv, importManager, importOptions.pluginArgs, newFileInfo);
//              if (plugin instanceof LessError) {
//                  fileParsedFunc(plugin, null, resolvedFilename);
//              }
//              else {
//                  fileParsedFunc(null, plugin, resolvedFilename);
//              }
//          } else if (importOptions.inline) {
//              fileParsedFunc(null, contents, resolvedFilename);
//          } else {
//
//              // import (multiple) parse trees apparently get altered and can't be cached.
//              // TODO: investigate why this is
//              if (importManager.files[resolvedFilename]
//                  && !importManager.files[resolvedFilename].options.multiple
//                  && !importOptions.multiple) {
//
//                  fileParsedFunc(null, importManager.files[resolvedFilename].root, resolvedFilename);
//              }
//              else {
//                  new Parser(newEnv, importManager, newFileInfo).parse(contents, function (e, root) {
//                      fileParsedFunc(e, root, resolvedFilename);
//                  });
//              }
//          }
//      };
//      var promise, context = utils.clone(this.context);
//
//      if (tryAppendExtension) {
//          context.ext = importOptions.isPlugin ? ".js" : ".less";
//      }
//
//      if (importOptions.isPlugin) {
//          promise = pluginLoader.loadPlugin(path, currentFileInfo.currentDirectory, context, environment, fileManager);
//      }
//      else {
//          promise = fileManager.loadFile(path, currentFileInfo.currentDirectory, context, environment,
//              function(err, loadedFile) {
//                  if (err) {
//                      fileParsedFunc(err);
//                  } else {
//                      loadFileCallback(loadedFile);
//                  }
//              });
//      }
//      if (promise) {
//          promise.then(loadFileCallback, fileParsedFunc);
//      }
//
//  };
  }
}

///
class ImportedFile {
  ///
  dynamic root; //String or Node - content
  ///
  bool    importedPreviously;
  ///
  String  fullPath;
  ///
  ImportOptions options;

  ///
  ImportedFile({this.root, this.importedPreviously, this.fullPath, this.options});
}
