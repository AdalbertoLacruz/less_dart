//source: less/import-manager.js 2.5.0

library importmanager.less;

import 'dart:async';
import 'package:path/path.dart' as pathLib;

import 'contexts.dart';
import 'file_info.dart';
import 'less_error.dart';
import 'environment/environment.dart';
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

class ImportManager {
  Contexts context;

  /// Map - filename to contents of all the imported files
  Map<String, String> contents = {};

  /// Map - filename to lines at the beginning of each file to ignore
  Map<String, int> contentsIgnoredChars = {};

  Environment environment;

  /// Error in parsing/evaluating an import
  LessError error;

  /// Holds the imported parse trees
  Map<String, Node> files = {}; // Deprecated?

  /// MIME type of .less files
  String mime;

  /// Directories where to search the file when importing
  List<String> paths = [];

  String rootFilename;

  /// Files which haven't been imported yet
  List<String> queue = []; // Deprecated?

  ///
  ImportManager(this.context, FileInfo rootFileInfo){
    rootFilename = rootFileInfo.filename;
    if (context.paths != null) paths = context.paths;
    mime = context.mime;
    environment = new Environment();

//2.3.1
//  var ImportManager = function(context, rootFileInfo) {
//      this.rootFilename = rootFileInfo.filename;
//      this.paths = context.paths || [];  // Search paths, when importing
//      this.contents = {};             // map - filename to contents of all the files
//      this.contentsIgnoredChars = {}; // map - filename to lines at the beginning of each file to ignore
//      this.mime = context.mime;
//      this.error = null;
//      this.context = context;
//      // Deprecated? Unused outside of here, could be useful.
//      this.queue = [];        // Files which haven't been imported yet
//      this.files = {};        // Holds the imported parse trees.
//  };
  }

  /// Build the return content
  ImportedFile fileParsedFunc(String path, root, String fullPath) {
    queue.remove(path);

    bool importedEqualsRoot = (fullPath == rootFilename);
    if (fullPath != null) files[fullPath] = root; // Store the root
    return new ImportedFile(root, importedEqualsRoot, fullPath);
  }

//2.3.1
//      var fileParsedFunc = function (e, root, fullPath) {
//          importManager.queue.splice(importManager.queue.indexOf(path), 1); // Remove the path from the queue *
//
//          var importedEqualsRoot = fullPath === importManager.rootFilename; *
//          if (importOptions.optional && e) {
//            callback(null, {rules:[]}, false, null);
//          }
//          else {
//            importManager.files[fullPath] = root; *
//            if (e && !importManager.error) { importManager.error = e; }
//            callback(e, root, importedEqualsRoot, fullPath); *
//          }
//      };

  ///
  /// Add an import to be imported
  ///
  /// Parameters:
  ///   [path] is the raw path
  ///   [tryAppendLessExtension] whether to try appending the less extension (if the path has no extension)
  ///   [currentFileInfo] the current file info (used for instance to work out relative paths)
  ///   [importOptions] import options
  ///
  Future push(String path, bool tryAppendLessExtension, FileInfo currentFileInfo, ImportOptions importOptions) {
    Completer task = new Completer();

    queue.add(path);
    FileInfo newFileInfo = new FileInfo.cloneForLoader(currentFileInfo, context);
    FileManager fileManager = environment.getFileManager(path, currentFileInfo.currentDirectory, context, environment);

    if (fileManager == null) {
      task.completeError(new LessError(message: 'Could not find a file-manager for ${path}'));
      return task.future;
    }

//(js)if (tryAppendLessExtension) path = fileManager.tryAppendExtension(path, importOptions.plugin ? ".js" : ".less");
    if (tryAppendLessExtension) path = fileManager.tryAppendLessExtension(path);

    fileManager.loadFile(path, currentFileInfo.currentDirectory, context, environment).then((FileLoaded loadedFile){
      String resolvedFilename = loadedFile.filename;
      String contents = loadedFile.contents.replaceFirst(new RegExp('^\uFEFF'), '');

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
        if (!currentDirectory.endsWith(pathLib.separator)) currentDirectory += pathLib.separator;
        String pathdiff = fileManager.pathDiff(currentDirectory, newFileInfo.entryPath);
        newFileInfo.rootpath = fileManager.join(getValueOrDefault(context.rootpath, ''), pathdiff);

        if (!fileManager.isPathAbsolute(newFileInfo.rootpath) && fileManager.alwaysMakePathsAbsolute()) {
          newFileInfo.rootpath = fileManager.join(newFileInfo.entryPath, newFileInfo.rootpath);
        }
      }
      newFileInfo.filename = resolvedFilename;

      Contexts newEnv = new Contexts.parse(this.context);
      newEnv.processImports = false;
      newEnv.currentFileInfo = newFileInfo; // Not in original
      this.contents[resolvedFilename] = contents;

      if (currentFileInfo.reference || isTrue(importOptions.reference)) {
        newFileInfo.reference = true;
      }

//(js)  if (importOptions.plugin) {
//          new FunctionImporter(newEnv, newFileInfo).eval(contents, function (e, root) {
//              fileParsedFunc(e, root, resolvedFilename);
//          });
//      } else if (importOptions.inline) {
      if (isTrue(importOptions.inline)) {
        task.complete(fileParsedFunc(path, contents, resolvedFilename));
      } else {
        new Parser.fromImporter(newEnv, this, newFileInfo).parse(contents).then((root){
          task.complete(fileParsedFunc(path, root, resolvedFilename));
        }).catchError((e) {
          task.completeError(e);
        });
      }
    }).catchError((e){
      //importOptions.optional: continue compiling when file is not found
      if (isTrue(importOptions.optional)) {
        Ruleset r = new Ruleset([], []);
        task.complete(fileParsedFunc(path, r, null));
      } else {
        task.completeError(e);
      }
    });

    return task.future;

//2.4.0 20150305
//  ImportManager.prototype.push = function (path, tryAppendLessExtension, currentFileInfo, importOptions, callback) {
//      var importManager = this;
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
//              importManager.files[fullPath] = root;
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
//      if (tryAppendLessExtension) {
//          path = fileManager.tryAppendExtension(path, importOptions.plugin ? ".js" : ".less");
//      }
//
//      var loadFileCallback = function(loadedFile) {
//          var resolvedFilename = loadedFile.filename,
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
//          if (importOptions.plugin) {
//              new FunctionImporter(newEnv, newFileInfo).eval(contents, function (e, root) {
//                  fileParsedFunc(e, root, resolvedFilename);
//              });
//          } else if (importOptions.inline) {
//              fileParsedFunc(null, contents, resolvedFilename);
//          } else {
//              new Parser(newEnv, importManager, newFileInfo).parse(contents, function (e, root) {
//                  fileParsedFunc(e, root, resolvedFilename);
//              });
//          }
//      };
//
//      var promise = fileManager.loadFile(path, currentFileInfo.currentDirectory, this.context, environment,
//          function(err, loadedFile) {
//          if (err) {
//              fileParsedFunc(err);
//          } else {
//              loadFileCallback(loadedFile);
//          }
//      });
//      if (promise) {
//          promise.then(loadFileCallback, fileParsedFunc);
//      }
//  };
  }
}

  class ImportedFile {
    var root; //String or Node - content
    bool importedPreviously;
    String fullPath;
    ImportedFile(this.root, this.importedPreviously, this.fullPath);
}