// source: less/import-sequencer.js 2.3.1 TODO REMOVE

part of visitor.less;

class ImportSequencer {

  ///
  //2.3.1
  ImportSequencer(Function onSequencerEmpty) {

//2.3.1
//  function ImportSequencer(onSequencerEmpty) {
//      this.imports = [];
//      this.variableImports = [];
//      this._onSequencerEmpty = onSequencerEmpty;
//      this._currentDepth = 0;
//  }
  }

  ///
  //2.3.1
  addImport(Function callback) {

//2.3.1
//  ImportSequencer.prototype.addImport = function(callback) {
//      var importSequencer = this,
//          importItem = {
//              callback: callback,
//              args: null,
//              isReady: false
//          };
//      this.imports.push(importItem);
//      return function() {
//          importItem.args = Array.prototype.slice.call(arguments, 0);
//          importItem.isReady = true;
//          importSequencer.tryRun();
//      };
//  };
  }

  ///
  //2.3.1
  addVariableImport(Function callback) {

//2.3.1
//  ImportSequencer.prototype.addVariableImport = function(callback) {
//      this.variableImports.push(callback);
//  };
  }

  ///
  //2.3.1
  tryRun() {

//2.3.1
//  ImportSequencer.prototype.tryRun = function() {
//      this._currentDepth++;
//      try {
//          while(true) {
//              while(this.imports.length > 0) {
//                  var importItem = this.imports[0];
//                  if (!importItem.isReady) {
//                      return;
//                  }
//                  this.imports = this.imports.slice(1);
//                  importItem.callback.apply(null, importItem.args);
//              }
//              if (this.variableImports.length === 0) {
//                  break;
//              }
//              var variableImport = this.variableImports[0];
//              this.variableImports = this.variableImports.slice(1);
//              variableImport();
//          }
//      } finally {
//          this._currentDepth--;
//      }
//      if (this._currentDepth === 0 && this._onSequencerEmpty) {
//          this._onSequencerEmpty();
//      }
//  };
  }
}