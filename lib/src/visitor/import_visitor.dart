// source: less/import-visitor.js 3.0.0 20160714

part of visitor.less;

///
class ImportVisitor extends VisitorBase {
  ///
  Contexts context;

  ///
  ImportManager importer;

  ///
  LessError lessError;

  ///
  ImportDetector onceFileDetectionMap;

  ///
  ImportDetector recursionDetector;

  /// visitImport futures for await their completion
  List<Future<Null>> runners = <Future<Null>>[];

  ///
  List<VariableImport> variableImports = <VariableImport>[];

  ///
  Visitor _visitor;

  ///
  /// Structure to search for @import in the tree.
  ///
  ImportVisitor(this.importer,
      [Contexts context,
      ImportDetector onceFileDetectionMap,
      ImportDetector recursionDetector]) {
    isReplacing = false;
    _visitor = Visitor(this);
    this.context = context ?? Contexts.eval();

    this.onceFileDetectionMap = ImportDetector.own(onceFileDetectionMap);
    this.recursionDetector = ImportDetector.clone(recursionDetector); //own?

//2.3.1
//  var ImportVisitor = function(importer, finish) {
//      this._visitor = new Visitor(this);
//      this._importer = importer;
//      this._finish = finish;
//      this.context = new contexts.Eval();
//      this.importCount = 0;
//      this.onceFileDetectionMap = {};
//      this.recursionDetector = {};
//      this._sequencer = new ImportSequencer(this._onSequencerEmpty.bind(this));
//  };
  }

  ///
  /// Replaces @import nodes with the file content
  ///
//run version with Future
  Future<Null> runAsync(Ruleset root) {
    _visitor.visit(root);

//    return Future
//        .wait(runners, eagerError: true)
//        .catchError((e) {
//          return new Future.error(e);
//        });
    return tryRun();

//2.3.1
//  run: function (root) {
//      try {
//          // process the contents
//          this._visitor.visit(root);
//      }
//      catch(e) {
//          this.error = e;
//      }
//
//      this.isFinished = true;
//      this._sequencer.tryRun();
//  }
  }

  ///
  Future<Null> tryRun() {
    final Completer<Null> task = Completer<Null>();
    Future.wait(runners, eagerError: true).then((_) {
      if (variableImports.isNotEmpty) {
        final VariableImport variableImport = variableImports.removeAt(0);
        processImportNode(variableImport.importNode, variableImport.context,
            variableImport.importParent);
        tryRun().then((_) {
          task.complete();
        });
      } else {
        task.complete();
      }
    }).catchError(task.completeError);
    return task.future;
  }

////2.3.1
////  _onSequencerEmpty: function() {
////      if (!this.isFinished) {
////          return;
////      }
////      this._finish(this.error);
////  },
//  }

  ///
  /// @import node - recursively load file and parse
  ///
  void visitImport(Import importNode, VisitArgs visitArgs) {
    //include the file, but not process
    final bool inlineCSS = importNode.options.inline ?? false;

    if (!importNode.css || inlineCSS) {
      final Contexts context =
          Contexts.eval(this.context, this.context.frames.sublist(0));
      final Node importParent = context.frames[0];

      if (importNode.isVariableImport()) {
        //process this type of imports *last*
        variableImports.add(VariableImport(importNode, context, importParent));
      } else {
        processImportNode(importNode, context, importParent);
      }
    }

    visitArgs.visitDeeper = false;

//3.0.0 20160714
// visitImport: function (importNode, visitArgs) {
//     var inlineCSS = importNode.options.inline;
//
//     if (!importNode.css || inlineCSS) {
//
//         var context = new contexts.Eval(this.context, utils.copyArray(this.context.frames));
//         var importParent = context.frames[0];
//
//         this.importCount++;
//         if (importNode.isVariableImport()) {
//             this._sequencer.addVariableImport(this.processImportNode.bind(this, importNode, context, importParent));
//         } else {
//             this.processImportNode(importNode, context, importParent);
//         }
//     }
//     visitArgs.visitDeeper = false;
// },
  }

  ///
  void processImportNode(
      Import importNode, Contexts context, Node importParent) {
    final Completer<Null> completer = Completer<Null>();
    runners.add(completer.future);

    Import evaldImportNode;
    final bool inlineCSS = importNode.options.inline ?? false;

    try {
      //expand @variables in path value, ...
      evaldImportNode = importNode.evalForImport(context);
    } catch (e) {
      final LessError error = LessError.transform(e,
          filename: importNode.currentFileInfo.filename,
          index: importNode.index);
      importNode
        // attempt to eval properly and treat as css
        ..css = true
        // if that fails, this error will be thrown
        ..errorImport = error;
    }

    if (evaldImportNode != null && (!evaldImportNode.css || inlineCSS)) {
      if (evaldImportNode.options.multiple ?? false) {
        context.importMultiple = true;
      }

      for (int i = 0; i < importParent.rules.length; i++) {
        if (importParent.rules[i] == importNode) {
          importParent.rules[i] = evaldImportNode;
          break;
        }
      }
      importer
          .push(evaldImportNode.getPath(), evaldImportNode.currentFileInfo,
              evaldImportNode.options,
              tryAppendLessExtension: !evaldImportNode.css)
          .then((ImportedFile importedFile) {
        onImported(evaldImportNode, context, importedFile.root,
                importedFile.fullPath,
                importedAtRoot: importedFile.importedPreviously)
            .then((_) {
          completer.complete();
        }).catchError(completer.completeError);
      }).catchError((Object e, StackTrace s) {
        final LessError error = LessError.transform(e,
            index: evaldImportNode.index,
            filename: evaldImportNode.currentFileInfo.filename,
            context: context,
            stackTrace: s);
        lessError = error;
        completer.completeError(error);
      });
    } else {
      completer.complete();
    }

//3.0.0 20160714
// processImportNode: function(importNode, context, importParent) {
//     var evaldImportNode,
//         inlineCSS = importNode.options.inline;
//
//     try {
//         evaldImportNode = importNode.evalForImport(context);
//     } catch(e) {
//         if (!e.filename) { e.index = importNode.getIndex(); e.filename = importNode.fileInfo().filename; }
//         // attempt to eval properly and treat as css
//         importNode.css = true;
//         // if that fails, this error will be thrown
//         importNode.error = e;
//     }
//
//     if (evaldImportNode && (!evaldImportNode.css || inlineCSS)) {
//
//         if (evaldImportNode.options.multiple) {
//             context.importMultiple = true;
//         }
//
//         // try appending if we haven't determined if it is css or not
//         var tryAppendLessExtension = evaldImportNode.css === undefined;
//
//         for (var i = 0; i < importParent.rules.length; i++) {
//             if (importParent.rules[i] === importNode) {
//                 importParent.rules[i] = evaldImportNode;
//                 break;
//             }
//         }
//
//         var onImported = this.onImported.bind(this, evaldImportNode, context),
//             sequencedOnImported = this._sequencer.addImport(onImported);
//
//         this._importer.push(evaldImportNode.getPath(), tryAppendLessExtension, evaldImportNode.fileInfo(),
//             evaldImportNode.options, sequencedOnImported);
//     } else {
//         this.importCount--;
//         if (this.isFinished) {
//             this._sequencer.tryRun();
//         }
//     }
// },
  }

  ///
  /// Recursively analyze the imported root for more imports
  /// [root] is String or Ruleset
  ///
  Future<Null> onImported(
      Import importNode, Contexts context, dynamic root, String fullPath,
      {bool importedAtRoot}) {
    final Completer<Null> completer = Completer<Null>();
    final ImportVisitor importVisitor = this;
    final bool inlineCSS = importNode.options.inline ?? false;
    final bool isOptional = importNode.options.optional ?? false;
    final bool duplicateImport =
        importedAtRoot || recursionDetector.containsKey(fullPath);

    if (!(context.importMultiple ?? false)) {
      if (duplicateImport) {
        importNode.skip = true;
      } else {
        // define function
        importNode.skip = () {
          if (importVisitor.onceFileDetectionMap.containsKey(fullPath)) {
            return true;
          }
          importVisitor.onceFileDetectionMap[fullPath] = true;
          return false;
        };
      }
    }

    if (!(fullPath?.isNotEmpty ?? false) && isOptional) {
      importNode.skip = true;
    }

    // recursion - analyze the new root
    if (root != null) {
      importNode
        ..root = root
        ..importedFilename = fullPath;

      if (!inlineCSS &&
          ((context.importMultiple ?? false) || !duplicateImport)) {
        recursionDetector[fullPath] = true;
        ImportVisitor(
                importer, context, onceFileDetectionMap, recursionDetector)
            .runAsync(root)
            .then((_) {
          completer.complete();
        }).catchError(completer.completeError);
      } else {
        completer.complete();
      }
    } else {
      completer.complete();
    }

    return completer.future;

//3.0.0 20160714
// onImported: function (importNode, context, e, root, importedAtRoot, fullPath) {
//     if (e) {
//         if (!e.filename) {
//             e.index = importNode.getIndex(); e.filename = importNode.fileInfo().filename;
//         }
//         this.error = e;
//     }
//
//     var importVisitor = this,
//         inlineCSS = importNode.options.inline,
//         isPlugin = importNode.options.isPlugin,
//         isOptional = importNode.options.optional,
//         duplicateImport = importedAtRoot || fullPath in importVisitor.recursionDetector;
//
//     if (!context.importMultiple) {
//         if (duplicateImport) {
//             importNode.skip = true;
//         } else {
//             importNode.skip = function() {
//                 if (fullPath in importVisitor.onceFileDetectionMap) {
//                     return true;
//                 }
//                 importVisitor.onceFileDetectionMap[fullPath] = true;
//                 return false;
//             };
//         }
//     }
//
//     if (!fullPath && isOptional) {
//         importNode.skip = true;
//     }
//
//     if (root) {
//         importNode.root = root;
//         importNode.importedFilename = fullPath;
//
//         if (!inlineCSS && !isPlugin && (context.importMultiple || !duplicateImport)) {
//             importVisitor.recursionDetector[fullPath] = true;
//
//             var oldContext = this.context;
//             this.context = context;
//             try {
//                 this._visitor.visit(root);
//             } catch (e) {
//                 this.error = e;
//             }
//             this.context = oldContext;
//         }
//     }
//
//     importVisitor.importCount--;
//
//     if (importVisitor.isFinished) {
//         importVisitor._sequencer.tryRun();
//     }
// },
  }

  ///
  void visitDeclaration(Declaration declNode, VisitArgs visitArgs) {
    if (declNode is DetachedRuleset) {
      context.frames.insert(0, declNode);
    } else {
      visitArgs.visitDeeper = false;
    }

//2.8.0 20160702
// visitDeclaration: function (declNode, visitArgs) {
//     if (declNode.value.type === "DetachedRuleset") {
//         this.context.frames.unshift(declNode);
//     } else {
//         visitArgs.visitDeeper = false;
//     }
// },
  }

  ///
  void visitDeclarationOut(Declaration declNode) {
    if (declNode is DetachedRuleset) context.frames.removeAt(0);

//2.8.0 20160702
// visitDeclarationOut: function(declNode) {
//     if (declNode.value.type === "DetachedRuleset") {
//         this.context.frames.shift();
//     }
// },
  }

  ///
  void visitAtRule(AtRule atRuleNode, VisitArgs visitArgs) {
    context.frames.insert(0, atRuleNode);

//2.8.0 20160702
// visitAtRule: function (atRuleNode, visitArgs) {
//     this.context.frames.unshift(atRuleNode);
// },
  }

  ///
  void visitAtRuleOut(AtRule atRuleNode) {
    context.frames.removeAt(0);

//2.8.0 20160702
// visitAtRuleOut: function (atRuleNode) {
//     this.context.frames.shift();
// },
  }

  ///
  void visitMixinDefinition(
      MixinDefinition mixinDefinitionNode, VisitArgs visitArgs) {
    context.frames.insert(0, mixinDefinitionNode);

//2.3.1
//  visitMixinDefinition: function (mixinDefinitionNode, visitArgs) {
//      this.context.frames.unshift(mixinDefinitionNode);
//  },
  }

  ///
  void visitMixinDefinitionOut(MixinDefinition mixinDefinitionNode) {
    context.frames.removeAt(0);

//2.3.1
//  visitMixinDefinitionOut: function (mixinDefinitionNode) {
//      this.context.frames.shift();
//  },
  }

  ///
  void visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    context.frames.insert(0, rulesetNode);

//2.3.1
//  visitRuleset: function (rulesetNode, visitArgs) {
//      this.context.frames.unshift(rulesetNode);
//  },
  }

  ///
  void visitRulesetOut(Ruleset rulesetNode) {
    context.frames.removeAt(0);

//2.3.1
//  visitRulesetOut: function (rulesetNode) {
//      this.context.frames.shift();
//  },
  }

  ///
  void visitMedia(Media mediaNode, VisitArgs visitArgs) {
    context.frames.insert(0, mediaNode.rules[0]);

//2.3.1
//  visitMedia: function (mediaNode, visitArgs) {
//      this.context.frames.unshift(mediaNode.rules[0]);
//  },
  }

  ///
  void visitMediaOut(Media mediaNode) {
    context.frames.removeAt(0);

//2.3.1
//  visitMediaOut: function (mediaNode) {
//      this.context.frames.shift();
//  }
  }

  /// func visitor.visit distribuitor
  @override
  Function visitFtn(Node node) {
    if (node is Media) return visitMedia;
    if (node is AtRule) return visitAtRule;
    if (node is Import) return visitImport;
    if (node is MixinDefinition) return visitMixinDefinition;
    if (node is Declaration) return visitDeclaration;
    if (node is Ruleset) return visitRuleset;
    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) {
    if (node is Media) return visitMediaOut;
    if (node is AtRule) return visitAtRuleOut;
    if (node is MixinDefinition) return visitMixinDefinitionOut;
    if (node is Declaration) return visitDeclarationOut;
    if (node is Ruleset) return visitRulesetOut;
    return null;
  }
}

// **************************

///
/// Contents the importNode with variables in the name, for delayed processing
///
/// Example: @import "less/import/import-@{in}@{terpolation}.less";
///
class VariableImport {
  ///
  Import importNode;

  ///
  Contexts context;

  ///
  Node importParent;

  ///
  VariableImport(this.importNode, this.context, this.importParent);
}
