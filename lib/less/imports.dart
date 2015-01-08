// source: less/parser.js 1.7.5 lines 61-111

part of env.less;

class Imports {
  Env env;

  /// Holds the imported file contents
  Map<String, String> contents;

  /// lines inserted, not in the original less
  Map<String, int> contentsIgnoredChars;

  /// Error in parsing/evaluating an import
  LessError error;

  /// Holds the imported parse trees
  Map<String, Node> files;

  /// MIME type of .less files
  var mime;

  /// Search paths, when importing
  List<String> paths;

  /// Files which haven't been imported yet
  List<String> queue = [];

  String rootFilename; // Initialized by parser

  ///
  Imports(Env this.env) {
    paths = this.env.paths != null ? this.env.paths : [];
    files = this.env.files;
    contents = this.env.contents;
    contentsIgnoredChars = this.env.contentsIgnoredChars;
    mime = this.env.mime;
  }

  /// Build the return content
  ImportedFile fileParsedFunc(String path, root, String fullPath) {
    this.queue.remove(path);
    bool importedPreviously = (fullPath == rootFilename);
    this.files[fullPath] = root; // Store the root

    return new ImportedFile(root, importedPreviously, fullPath);
  }

  /**
   * callback (e, root, importedAtRoot, fullPath)
   */
  Future push(String path, FileInfo currentFileInfo, ImportOptions importOptions) {
    this.queue.add(path);
    Importer importer = new Importer(path, currentFileInfo, env);

    return new Future.sync((){
      return importer.fileLoader().then((String data){
        String fullPath = importer.pathname;
        FileInfo newFileInfo = importer.newFileInfo;
        String contents = data;

        Env newEnv = new Env.parseEnv(env)
            ..currentFileInfo = newFileInfo
            ..processImports = false
            ..contents[fullPath] = contents;

        if (currentFileInfo.reference || isTrue(importOptions.reference)) {
          newFileInfo.reference = true;
        }

        if (isTrue(importOptions.inline)) {
          return new Future.value(fileParsedFunc(path, contents, fullPath));
        } else {
          return new Parser.fromRecursive(newEnv).parse(contents).then((root) {
            return new Future.value(fileParsedFunc(path, root, fullPath));
          });
        }
      });
    }).catchError((e, s){
      LessError error = LessError.transform(e, stackTrace: s);
      if (this.error == null) this.error = error;
      return new Future.error(this.error);
    });
  }

//       push: function (path, currentFileInfo, importOptions, callback) {
//           var parserImports = this;
//           this.queue.push(path);
//
//           var fileParsedFunc = function (e, root, fullPath) {
//               parserImports.queue.splice(parserImports.queue.indexOf(path), 1); // Remove the path from the queue
//
//               var importedPreviously = fullPath === rootFilename;
//
//               parserImports.files[fullPath] = root;                        // Store the root
//
//               if (e && !parserImports.error) { parserImports.error = e; }
//
//               callback(e, root, importedPreviously, fullPath);
//           };
//
//           if (less.Parser.importer) {
//               less.Parser.importer(path, currentFileInfo, fileParsedFunc, env);
//           } else {
//               less.Parser.fileLoader(path, currentFileInfo, function(e, contents, fullPath, newFileInfo) {
//                   if (e) {fileParsedFunc(e); return;}
//
//                   var newEnv = new tree.parseEnv(env);
//
//                   newEnv.currentFileInfo = newFileInfo;
//                   newEnv.processImports = false;
//                   newEnv.contents[fullPath] = contents;
//
//                   if (currentFileInfo.reference || importOptions.reference) {
//                       newFileInfo.reference = true;
//                   }
//
//                   if (importOptions.inline) {
//                       fileParsedFunc(null, contents, fullPath);
//                   } else {
//                       new(less.Parser)(newEnv).parse(contents, function (e, root) {
//                           fileParsedFunc(e, root, fullPath);
//                       });
//                   }
//               }, env);
//           }
//       }
//   };
}

class ImportedFile {
  var root; //String or Node - content
  bool importedPreviously;
  String fullPath;

  ImportedFile(this.root, this.importedPreviously, this.fullPath);
}
