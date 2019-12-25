//source: less/import-manager.js 3.9.0 20181130

library importmanager.less;

import 'dart:async';
import 'package:path/path.dart' as path_lib;

import 'contexts.dart';
import 'data/constants.dart';
import 'environment/environment.dart';
import 'file_info.dart';
import 'less_error.dart';
import 'logger.dart';
import 'parser/parser.dart';
import 'tree/tree.dart';

// FileInfo = {
//  'rewriteUrls' - option - whether to adjust URL's to be relative
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

  /// Log
  Logger logger;

  /// MIME type of .less files
  String mime;

  /// files that are packages
  List<String> filesInPackage = <String>[];

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
    environment = Environment();

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
  /// Build the return content and save it in files cache
  /// [root] = Node | String
  ///
  ImportedFile fileParsedFunc(
      String path, dynamic root, String fullPath, ImportOptions importOptions,
      {bool useCache = false}) {
    queue.remove(path);

    if (useCache) return files[fullPath];

    final importedFile = ImportedFile(
        root: root,
        importedPreviously: fullPath == rootFilename, // importedEqualsRoot
        fullPath: fullPath,
        options: importOptions);

    if (path.startsWith('package')) {
      MoreList.addUnique(
          filesInPackage, path_lib.joinAll(path_lib.split(path))); //normalize
    }

    // Inline imports aren't cached here.
    // If we start to cache them, please make sure they won't conflict with non-inline imports of the
    // same name as they used to do before this comment and the condition below have been added.
    //
    // in js only if (!importManager.files[fullPath] && !importOptions.inline).
    // But if we are here, don't like the cache
    if (fullPath != null && !(importOptions?.inline ?? false)) {
      files[fullPath] = importedFile;
    }

    return importedFile;
  }

//3.0.4 20180616
//  var fileParsedFunc = function (e, root, fullPath) {
//      importManager.queue.splice(importManager.queue.indexOf(path), 1); // Remove the path from the queue
//
//      var importedEqualsRoot = fullPath === importManager.rootFilename;
//      if (importOptions.optional && e) {
//          callback(null, {rules:[]}, false, null);
//          logger.info("The file " + fullPath + " was skipped because it was not found and the import was marked optional.");
//      }
//      else {
//          // Inline imports aren't cached here.
//          // If we start to cache them, please make sure they won't conflict with non-inline imports of the
//          // same name as they used to do before this comment and the condition below have been added.
//          if (!importManager.files[fullPath] && !importOptions.inline) {
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
      String path, FileInfo currentFileInfo, ImportOptions importOptions,
      {bool tryAppendLessExtension = false}) async {
    final _context = context.clone();
    String resolvedFilename;

    queue.add(path);

    final newFileInfo = FileInfo.cloneForLoader(currentFileInfo, _context);

    final fileManager = environment.getFileManager(
        path, currentFileInfo.currentDirectory, _context, environment);
    if (fileManager == null) {
      throw LessError(message: 'Could not find a file-manager for $path');
    }

    if (tryAppendLessExtension) _context.ext = '.less';

    try {
      final loadedFile = await fileManager.loadFile(
          path, currentFileInfo.currentDirectory, _context, environment);

      resolvedFilename = loadedFile.filename;

      final contents = loadedFile.contents.replaceFirst(RegExp('^\uFEFF'), '');

      // Pass on an updated rootpath if path of imported file is relative and file
      // is in a (sub|sup) directory
      //
      // Examples:
      // - If path of imported file is 'module/nav/nav.less' and rootpath is 'less/',
      //   then rootpath should become 'less/module/nav/'
      // - If path of imported file is '../mixins.less' and rootpath is 'less/',
      //   then rootpath should become 'less/../'

      newFileInfo.currentDirectory = fileManager.getPath(resolvedFilename);
      if (newFileInfo.rewriteUrls > RewriteUrlsConstants.off) {
        var currentDirectory = newFileInfo.currentDirectory;
        if (!currentDirectory.endsWith(path_lib.separator)) {
          currentDirectory += path_lib.separator;
        }

        final entryPath =
            await fileManager.normalizeFilePath(newFileInfo.entryPath);

        final pathdiff = fileManager.pathDiff(currentDirectory, entryPath);

        newFileInfo.rootpath =
            fileManager.join(_context.rootpath ?? '', pathdiff);

        if (!fileManager.isPathAbsolute(newFileInfo.rootpath) &&
            fileManager.alwaysMakePathsAbsolute()) {
          newFileInfo.rootpath =
              fileManager.join(newFileInfo.entryPath, newFileInfo.rootpath);
        }
      }
      newFileInfo.filename = resolvedFilename;

      final newEnv = Contexts.parse(_context)
        ..processImports = false
        ..currentFileInfo = newFileInfo; // Not in original

      this.contents[resolvedFilename] = contents;

      if (currentFileInfo.reference || (importOptions?.reference ?? false)) {
        newFileInfo.reference = true;
      }

      // if (importOptions.isPlugin) ...
      if (importOptions?.inline ?? false) {
        return fileParsedFunc(path, contents, resolvedFilename, importOptions);

        // import (multiple) parse trees apparently get altered and can't be cached.
        // TODO: investigate why this is (js)
      } else if (files.containsKey(resolvedFilename) &&
          !(files[resolvedFilename].options?.multiple ?? false) &&
          !(importOptions?.multiple ?? false)) {
        return fileParsedFunc(path, null, resolvedFilename, importOptions,
            useCache: true);
      } else {
        final root = await Parser.fromImporter(newEnv, this, newFileInfo)
            .parse(contents);
        return fileParsedFunc(path, root, resolvedFilename, importOptions);
      }
    } catch (e) {
      //importOptions.optional: continue compiling when file is not found
      if (importOptions?.optional ?? false) {
        (logger ??= Logger()).info(
            'The file ${resolvedFilename ?? path} was skipped because it was not found and the import was marked optional.');
        return fileParsedFunc(
            path, Ruleset(<Selector>[], <Node>[]), null, importOptions);
      } else {
        rethrow;
      }
    }

// 3.9.0 20181130
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
//              logger.info('The file ' + fullPath + ' was skipped because it was not found and the import was marked optional.');
//          }
//          else {
//              // Inline imports aren't cached here.
//              // If we start to cache them, please make sure they won't conflict with non-inline imports of the
//              // same name as they used to do before this comment and the condition below have been added.
//              if (!importManager.files[fullPath] && !importOptions.inline) {
//                  importManager.files[fullPath] = { root: root, options: importOptions };
//              }
//              if (e && !importManager.error) { importManager.error = e; }
//              callback(e, root, importedEqualsRoot, fullPath);
//          }
//      };
//
//      var newFileInfo = {
//          rewriteUrls: this.context.rewriteUrls,
//          entryPath: currentFileInfo.entryPath,
//          rootpath: currentFileInfo.rootpath,
//          rootFilename: currentFileInfo.rootFilename
//      };
//
//      var fileManager = environment.getFileManager(path, currentFileInfo.currentDirectory, this.context, environment);
//
//      if (!fileManager) {
//          fileParsedFunc({ message: 'Could not find a file-manager for ' + path });
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
//          if (newFileInfo.rewriteUrls) {
//              newFileInfo.rootpath = fileManager.join(
//                  (importManager.context.rootpath || ''),
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
//          context.ext = importOptions.isPlugin ? '.js' : '.less';
//      }
//
//      if (importOptions.isPlugin) {
//          context.mime = 'application/javascript';
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
  bool importedPreviously;

  ///
  String fullPath;

  ///
  ImportOptions options;

  ///
  ImportedFile(
      {this.root, this.importedPreviously, this.fullPath, this.options});
}
