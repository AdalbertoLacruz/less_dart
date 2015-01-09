// source: less/import-visitor.js 1.7.5

part of visitor.less;


class ImportVisitor extends VisitorBase {
  Imports         importer;
  ImportDetector  onceFileDetectionMap;
  ImportDetector  recursionDetector;

  Env     env;
  bool    isReplacing = true;
  Visitor _visitor;

  /// visitImport futures for await their completion
  List<Future> runners = [];

  ///
  /// Structure to search for @import in the tree.
  ///
  ImportVisitor(Imports this.importer, [Env evalEnv, ImportDetector onceFileDetectionMap,
      ImportDetector recursionDetector]){

    this._visitor = new Visitor(this);
    this.env = (evalEnv != null) ? evalEnv : new Env.evalEnv();

    this.onceFileDetectionMap = ImportDetector.own(onceFileDetectionMap);
    this.recursionDetector = ImportDetector.clone(recursionDetector);
  }

  ///
  /// Replaces @import nodes with the file content
  ///
  Future run(Node root) {
    return new Future.sync((){
      this._visitor.visit(root);
      return Future.wait(runners, eagerError: true);
    }).catchError((e){
      return new Future.error(e);
    });

//      run: function (root) {
//          var error;
//          try {
//              // process the contents
//              this._visitor.visit(root);
//          }
//          catch(e) {
//              error = e;
//          }
//
//          this.isFinished = true;
//
//          if (this.importCount === 0) {
//              this._finish(error);
//          }
//      },
  }

  ///
  /// @import node - recursively load file and parse
  ///
  visitImport(Import importNode, VisitArgs visitArgs) {
    ImportVisitor importVisitor = this;
    Import evaldImportNode;
    bool inlineCSS = isTrue(importNode.options.inline); //include the file, but not process
    Completer completer = new Completer();

    if (!importNode.css || inlineCSS) {
      try {
        //expand @variables in path value, ...
        evaldImportNode = importNode.evalForImport(this.env);
      } catch (e) {
        LessError error = LessError.transform(e,
            filename: importNode.currentFileInfo.filename,
            index: importNode.index);
        // attempt to eval properly and treat as css
        importNode.css = true;
        // if that fails, this error will be thrown
        importNode.errorImport = error;
      }

      if (evaldImportNode != null && (!evaldImportNode.css || inlineCSS)) {
        runners.add(completer.future);
        importNode = evaldImportNode;
        //this.importCount++;
        Env env = new Env.evalEnvClone(this.env, this.env.frames.sublist(0));
        if (isTrue(importNode.options.multiple)) env.importMultiple = true;

        this.importer.push(importNode.getPath(), importNode.currentFileInfo, importNode.options).then((ImportedFile importedFile){
          var root = importedFile.root;
          bool importedAtRoot = importedFile.importedPreviously;
          String fullPath = importedFile.fullPath;

          bool duplicateImport = importedAtRoot || importVisitor.recursionDetector.containsKey(fullPath);
          if (!isTrue(env.importMultiple)) {
            if (duplicateImport) {
              importNode.skip = true;
            } else {
              // define function
              importNode.skip = () {
                if (importVisitor.onceFileDetectionMap.containsKey(fullPath)) return true;
                importVisitor.onceFileDetectionMap[fullPath] = true;
                return false;
              };
            }
          }

          // recursion - analyze the new root
          if (root != null) {
            importNode.root = root;
            importNode.importedFilename = fullPath;

            if (!inlineCSS && (isTrue(env.importMultiple) || !duplicateImport)) {
              importVisitor.recursionDetector[fullPath] = true;
              new ImportVisitor(importVisitor.importer, env, importVisitor.onceFileDetectionMap, importVisitor.recursionDetector)
                .run(root).then((_){
                  completer.complete();
              }).catchError((e, s){
                LessError error = LessError.transform(e,
                  index: importNode.index,
                  filename: importNode.currentFileInfo.filename,
                  stackTrace: s);
                completer.completeError(error);
              });
            } else {
              completer.complete();
            }
          } else {
            completer.complete();
          }
        })
        .catchError((e, s){
          LessError error = LessError.transform(e,
              index: importNode.index,
              filename: importNode.currentFileInfo.filename,
              stackTrace: s);
          completer.completeError(error);
        });
      }
    }

    visitArgs.visitDeeper = false;
    return importNode;

//      visitImport: function (importNode, visitArgs) {
//          var importVisitor = this,
//              evaldImportNode,
//              inlineCSS = importNode.options.inline;
//
//          if (!importNode.css || inlineCSS) {
//
//              try {
//                  evaldImportNode = importNode.evalForImport(this.env);
//              } catch(e){
//                  if (!e.filename) { e.index = importNode.index; e.filename = importNode.currentFileInfo.filename; }
//                  // attempt to eval properly and treat as css
//                  importNode.css = true;
//                  // if that fails, this error will be thrown
//                  importNode.error = e;
//              }
//
//              if (evaldImportNode && (!evaldImportNode.css || inlineCSS)) {
//                  importNode = evaldImportNode;
//                  this.importCount++;
//                  var env = new tree.evalEnv(this.env, this.env.frames.slice(0));
//
//                  if (importNode.options.multiple) {
//                      env.importMultiple = true;
//                  }
//
//                  this._importer.push(importNode.getPath(), importNode.currentFileInfo, importNode.options, function (e, root, importedAtRoot, fullPath) {
//                      if (e && !e.filename) {
//                          e.index = importNode.index; e.filename = importNode.currentFileInfo.filename;
//                      }
//
//                      var duplicateImport = importedAtRoot || fullPath in importVisitor.recursionDetector;
//                      if (!env.importMultiple) {
//                          if (duplicateImport) {
//                              importNode.skip = true;
//                          } else {
//                              importNode.skip = function() {
//                                  if (fullPath in importVisitor.onceFileDetectionMap) {
//                                      return true;
//                                  }
//                                  importVisitor.onceFileDetectionMap[fullPath] = true;
//                                  return false;
//                              };
//                          }
//                      }
//
//                      var subFinish = function(e) {
//                          importVisitor.importCount--;
//
//                          if (importVisitor.importCount === 0 && importVisitor.isFinished) {
//                              importVisitor._finish(e);
//                          }
//                      };
//
//                      if (root) {
//                          importNode.root = root;
//                          importNode.importedFilename = fullPath;
//
//                          if (!inlineCSS && (env.importMultiple || !duplicateImport)) {
//                              importVisitor.recursionDetector[fullPath] = true;
//                              new(tree.importVisitor)(importVisitor._importer, subFinish, env, importVisitor.onceFileDetectionMap, importVisitor.recursionDetector)
//                                  .run(root);
//                              return;
//                          }
//                      }
//
//                      subFinish();
//                  });
//              }
//          }
//          visitArgs.visitDeeper = false;
//          return importNode;
//      },
  }

  ///
  Rule visitRule(Rule ruleNode, VisitArgs visitArgs) {
    visitArgs.visitDeeper = false;
    return ruleNode;
  }

  ///
  Directive visitDirective(Directive directiveNode, VisitArgs visitArgs) {
    this.env.frames.insert(0, directiveNode);
    return directiveNode;
  }

  ///
  void visitDirectiveOut(Directive directiveNode) {
    this.env.frames.removeAt(0);
  }

  ///
  MixinDefinition visitMixinDefinition(MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    this.env.frames.insert(0, mixinDefinitionNode);
    return mixinDefinitionNode;
  }

  ///
  void visitMixinDefinitionOut(MixinDefinition mixinDefinitionNode) {
    this.env.frames.removeAt(0);
  }

  ///
  Ruleset visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    this.env.frames.insert(0, rulesetNode);
    return rulesetNode;
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    this.env.frames.removeAt(0);
  }

  ///
  Media visitMedia(Media mediaNode, VisitArgs visitArgs) {
    this.env.frames.insert(0, mediaNode.rules[0]);
    return mediaNode;
  }

  void visitMediaOut(Media mediaNode) {
    this.env.frames.removeAt(0);
  }


  /// func visitor.visit distribuitor
  Function visitFtn(Node node) {
    if (node is Directive)  return this.visitDirective;
    if (node is Import)     return this.visitImport;
    if (node is Media)      return this.visitMedia;
    if (node is MixinDefinition) return this.visitMixinDefinition;
    if (node is Rule)       return this.visitRule;
    if (node is Ruleset)    return this.visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) {
    if (node is Directive)  return this.visitDirectiveOut;
    if (node is Media)      return this.visitMediaOut;
    if (node is MixinDefinition) return this.visitMixinDefinitionOut;
    if (node is Ruleset)    return this.visitRulesetOut;

    return null;
  }
}

//------------------------------------------------------------------------------

///
/// Map<String, bool> used for recursionDetector and onceFileDetectionMap
///
class ImportDetector {
  Map<String, bool> _item = {};

  /// Copy the [source] importDetector
  void addAll(ImportDetector source) => _item.addAll(source._item);

  bool containsKey(String key) => _item.containsKey(key);

  Iterable<String> get keys => _item.keys;

  void operator []=(String key, bool value) {
    _item[key] = value;
  }

  //--- static ----

  ///
  /// Returns a new ImportDector copy of [source]
  ///
  static ImportDetector clone(ImportDetector source) {
    ImportDetector result = new ImportDetector();
    return (source != null) ? (result..addAll(source)) : result;
  }

  ///
  /// Returns a not null [detector]
  ///
  static ImportDetector own(ImportDetector detector) {
    return (detector != null) ? detector : new ImportDetector();
  }
}