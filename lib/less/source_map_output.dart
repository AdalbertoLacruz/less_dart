// source: less/source-map-output.js 1.7.5

library sourcemapoutput.less;

import 'dart:convert';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';

import 'env.dart';
import 'file_info.dart';
import 'output.dart';
import '../nodejs/nodejs.dart';
import '../tree/tree.dart';

class SourceMapOutput extends Output{
  Map<String, int> contentsIgnoredCharsMap;
  Map<String, String> contentsMap;
  String outputFilename;
  bool outputSourceFiles;
  Ruleset rootNode;
  String sourceMapBasepath;
  String sourceMapFilename;
  SourceMapBuilder sourceMapGenerator; //class instance
  String sourceMapRootpath;
  String sourceMapURL;
  Function writeSourceMap;

  int column = 0;
  int indexGenerated = 0;
  int lineNumber = 0;
  Map<String, String> normalizeCache = {};

  SourceMapOutput({Map<String, int> this.contentsIgnoredCharsMap,
                   Function this.writeSourceMap,
                   Ruleset this.rootNode,
                   Map<String, String> this.contentsMap,
                   String this.sourceMapFilename,
                   String this.sourceMapURL,
                   String this.outputFilename,
                   String sourceMapBasepath, //abs?
                   String this.sourceMapRootpath,
                   bool this.outputSourceFiles,
                   this.sourceMapGenerator}) {
    if (sourceMapBasepath != null) {
      this.sourceMapBasepath = sourceMapBasepath.replaceAll('\\', '/');
    }
    if (this.sourceMapRootpath.isNotEmpty && !this.sourceMapRootpath.endsWith('/')) {
      this.sourceMapRootpath += '/';
    }
    if (this.sourceMapGenerator == null) {
      this.sourceMapGenerator = new SourceMapBuilder();
    }
  }

  ///
  String normalizeFilename (String file) {
    if (normalizeCache.containsKey(file)) return normalizeCache[file];

    String result;
    String filename = file.replaceAll('\\', '/');

    if (this.sourceMapBasepath != null && filename.startsWith(this.sourceMapBasepath)) {
      filename = filename.substring(this.sourceMapBasepath.length);
      if (filename.startsWith('\\') || filename.startsWith('/')) {
        filename = filename.substring(1);
      }
    }
    result = (this.sourceMapRootpath != null) ? this.sourceMapRootpath + filename : filename;
    normalizeCache[file] = result;
    return result;

//    tree.sourceMapOutput.prototype.normalizeFilename = function(filename) {
//        filename = filename.replace(/\\/g, '/');
//
//        if (this._sourceMapBasepath && filename.indexOf(this._sourceMapBasepath) === 0) {
//            filename = filename.substring(this._sourceMapBasepath.length);
//            if (filename.charAt(0) === '\\' || filename.charAt(0) === '/') {
//               filename = filename.substring(1);
//            }
//        }
//        return (this._sourceMapRootpath || "") + filename;
//    };
  }

  ///
  /// genCSS call 'output.add'. This is 'output' for sourcemaps generation
  ///
  void add(String chunk, [FileInfo fileInfo, int index, mapLines = false]) {
    List<String> lines;
    List<String> sourceLines;
    String columns;
    String sourceColumns;

    SourceLocation original;
    SourceLocation generated;

    //ignore adding empty strings
    if (chunk.isEmpty) return;

    if (fileInfo != null) {
      String inputSource = this.contentsMap[fileInfo.filename];

      // remove vars/banner added to the top of the file
      if (this.contentsIgnoredCharsMap[fileInfo.filename] != null) {
        // adjust the index
        index -= this.contentsIgnoredCharsMap[fileInfo.filename];
        if (index < 0) index = 0;
        // adjust the source
        inputSource = inputSource.substring(this.contentsIgnoredCharsMap[fileInfo.filename]);
      }
      inputSource = inputSource.substring(0, index);
      sourceLines = inputSource.split('\n');
      sourceColumns = sourceLines.last;
    }

    lines = chunk.split('\n');
    columns = lines.last;

    if (fileInfo != null) {
      if (!mapLines) {
        SourcemapData data = new SourcemapData(
            originalIndex: index, originalLine: sourceLines.length - 1, originalColumn: sourceColumns.length, originalFile:normalizeFilename(fileInfo.filename),
            generatedIndex: indexGenerated, generatedLine: this.lineNumber, generatedColumn: this.column, generatedFile: normalizeFilename(this.outputFilename));
        if (data != null) this.sourceMapGenerator.addLocation(data.original, data.generated, null);
      } else { // @import (inline)
        for (int i = 0; i < lines.length; i++) {
          SourcemapData data = new SourcemapData(
          originalIndex: index, originalLine: sourceLines.length + i - 1,
            originalColumn: (i == 0) ? sourceColumns.length : 0, originalFile:normalizeFilename(fileInfo.filename),
          generatedIndex: indexGenerated, generatedLine: this.lineNumber + i,
            generatedColumn: (i == 0) ? this.column : 0, generatedFile: normalizeFilename(this.outputFilename));
          if (data != null) this.sourceMapGenerator.addLocation(data.original, data.generated, null);
        }
      }
    }

    if (lines.length == 1) {
      this.column += columns.length;
    } else {
      this.lineNumber += lines.length - 1;
      this.column = columns.length;
    }

    super.add(chunk);
    indexGenerated += chunk.length;

//    tree.sourceMapOutput.prototype.add = function(chunk, fileInfo, index, mapLines) {
//
//        //ignore adding empty strings
//        if (!chunk) {
//            return;
//        }
//
//        var lines,
//            sourceLines,
//            columns,
//            sourceColumns,
//            i;
//
//        if (fileInfo) {
//            var inputSource = this._contentsMap[fileInfo.filename];
//
//            // remove vars/banner added to the top of the file
//            if (this._contentsIgnoredCharsMap[fileInfo.filename]) {
//                // adjust the index
//                index -= this._contentsIgnoredCharsMap[fileInfo.filename];
//                if (index < 0) { index = 0; }
//                // adjust the source
//                inputSource = inputSource.slice(this._contentsIgnoredCharsMap[fileInfo.filename]);
//            }
//            inputSource = inputSource.substring(0, index);
//            sourceLines = inputSource.split("\n");
//            sourceColumns = sourceLines[sourceLines.length-1];
//        }
//
//        lines = chunk.split("\n");
//        columns = lines[lines.length-1];
//
//        if (fileInfo) {
//            if (!mapLines) {
//                this._sourceMapGenerator.addMapping({ generated: { line: this._lineNumber + 1, column: this._column},
//                    original: { line: sourceLines.length, column: sourceColumns.length},
//                    source: this.normalizeFilename(fileInfo.filename)});
//            } else {
//                for(i = 0; i < lines.length; i++) {
//                    this._sourceMapGenerator.addMapping({ generated: { line: this._lineNumber + i + 1, column: i === 0 ? this._column : 0},
//                        original: { line: sourceLines.length + i, column: i === 0 ? sourceColumns.length : 0},
//                        source: this.normalizeFilename(fileInfo.filename)});
//                }
//            }
//        }
//
//        if (lines.length === 1) {
//            this._column += columns.length;
//        } else {
//            this._lineNumber += lines.length - 1;
//            this._column = columns.length;
//        }
//
//        this._css.push(chunk);
//    };
  }

  ///
  String toCSS(Env env) {
    String sourceMapContent;
    String sourceMapURL = '';
    Map<String, String> contents = {};
    Map json;

    if (this.outputSourceFiles) { //--source-map-less-inline
      for (var filename in this.contentsMap.keys) {
        String source = this.contentsMap[filename];
        if (this.contentsIgnoredCharsMap[filename] != null) {
          source = source.substring(this.contentsIgnoredCharsMap[filename]);
        }
        contents[normalizeFilename(filename)] = source;
      }
    }

    this.rootNode.genCSS(env, this);

    if (!super.isEmpty) {
      if (this.outputSourceFiles) {//--source-map-less-inline
        json = this.sourceMapGenerator.build(normalizeFilename(this.outputFilename));
        List<String> sourcesContent = [];
        for (var filename in json['sources']) {
          sourcesContent.add(contents[filename]);
        }
        json['sourcesContent'] = sourcesContent;
        sourceMapContent = JSON.encode(json);
      } else {
        sourceMapContent = this.sourceMapGenerator.toJson(normalizeFilename(this.outputFilename));
      }

      if (this.sourceMapURL.isNotEmpty) {
        sourceMapURL = this.sourceMapURL;
      } else if (this.sourceMapFilename.isNotEmpty){
        sourceMapURL = normalizeFilename(this.sourceMapFilename);
      }

      if (this.writeSourceMap != null) {
        this.writeSourceMap(sourceMapContent);
      } else { // --source-map-map-inline
        sourceMapURL = 'data:application/json;base64,' + Base64String.encode(sourceMapContent);      }

      if (sourceMapURL.isNotEmpty) {
        super.add('/*# sourceMappingURL=${sourceMapURL} */');
      }
    }

    return super.toString();

//    tree.sourceMapOutput.prototype.toCSS = function(env) {
//        this._sourceMapGenerator = new this._sourceMapGeneratorConstructor({ file: this._outputFilename, sourceRoot: null });
//
//        if (this._outputSourceFiles) {
//            for(var filename in this._contentsMap) {
//                if (this._contentsMap.hasOwnProperty(filename))
//                {
//                    var source = this._contentsMap[filename];
//                    if (this._contentsIgnoredCharsMap[filename]) {
//                        source = source.slice(this._contentsIgnoredCharsMap[filename]);
//                    }
//                    this._sourceMapGenerator.setSourceContent(this.normalizeFilename(filename), source);
//                }
//            }
//        }
//
//        this._rootNode.genCSS(env, this);
//
//        if (this._css.length > 0) {
//            var sourceMapURL,
//                sourceMapContent = JSON.stringify(this._sourceMapGenerator.toJSON());
//
//            if (this._sourceMapURL) {
//                sourceMapURL = this._sourceMapURL;
//            } else if (this._sourceMapFilename) {
//                sourceMapURL = this.normalizeFilename(this._sourceMapFilename);
//            }
//
//            if (this._writeSourceMap) {
//                this._writeSourceMap(sourceMapContent);
//            } else {
//                sourceMapURL = "data:application/json;base64," + require('./encoder.js').encodeBase64(sourceMapContent);
//            }
//
//            if (sourceMapURL) {
//                this._css.push("/*# sourceMappingURL=" + sourceMapURL + " */");
//            }
//        }
//
//        return this._css.join('');
//    };
  }
}

///
/// Build data to use in SourceMapBuilder.addLocation
///
class SourcemapData {
  SourceLocation original;
  int originalIndex;
  int originalLine;
  int originalColumn;
  String originalFile;

  SourceLocation generated;
  int generatedIndex;
  int generatedLine;
  int generatedColumn;
  String generatedFile;

  static SourcemapData last;

  SourcemapData.create(
      this.originalIndex, this.originalLine, this.originalColumn, this.originalFile,
      this.generatedIndex, this.generatedLine, this.generatedColumn, this.generatedFile);

  /// Compares with last call. If is same line, return null
  factory SourcemapData({
    int originalIndex, int originalLine, int originalColumn, String originalFile,
    int generatedIndex, int generatedLine, int generatedColumn, String generatedFile}){

    if (last != null) {
      if (   last.originalIndex == originalIndex
          && last.originalFile  == originalFile
          && last.generatedLine == generatedLine
          ) return null;
    }

    SourcemapData data = new SourcemapData.create(
        originalIndex, originalLine, originalColumn, originalFile,
        generatedIndex, generatedLine, generatedColumn, generatedFile);

    data.original = new SourceLocation(originalIndex, line: originalLine, column: originalColumn, sourceUrl: originalFile);
    data.generated = new SourceLocation(generatedIndex, line: generatedLine, column: generatedColumn, sourceUrl: generatedFile);
    last = data;
    return data;
  }
}