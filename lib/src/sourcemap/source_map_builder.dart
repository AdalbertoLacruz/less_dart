//source: lib/less/source-map-builder.js 3.0.0 20160804

part of sourcemap.less;

//conflict name with SourceMapBuilder dart package. Renamed to LessSourceMapBuilder
///
class LessSourceMapBuilder {
  ///
  SourceMapOptions  options;
  ///
  String            sourceMap;    //map contents
  ///
  String            sourceMapInputFilename;
  ///
  String            sourceMapURL; //map filename or base64 contents

  ///
  LessSourceMapBuilder(SourceMapOptions this.options);

  ///
  /// Generates the css & map contents
  ///
  String toCSS(Ruleset rootNode, Contexts context, ImportManager imports) {
    final SourceMapOutput sourceMapOutput = new SourceMapOutput(
        contentsIgnoredCharsMap: imports.contentsIgnoredChars,
        rootNode: rootNode,
        contentsMap: imports.contents,
        sourceMapFilename: options.sourceMapFilename,
        sourceMapURL: options.sourceMapURL,
        outputFilename: options.sourceMapOutputFilename,
        sourceMapBasepath: options.sourceMapBasepath,
        sourceMapRootpath: options.sourceMapRootpath,
        outputSourceFiles: options.outputSourceFiles,
        sourceMapFileInline: options.sourceMapFileInline
    );

    final String css = sourceMapOutput.toCSS(context).toString();
    sourceMap = sourceMapOutput.sourceMap;
    sourceMapURL = sourceMapOutput.sourceMapURL;
    if (options.sourceMapInputFilename.isNotEmpty) {
      sourceMapInputFilename =
          sourceMapOutput.normalizeFilename(options.sourceMapInputFilename);
    }
        
    if (options.sourceMapBasepath.isNotEmpty && (sourceMapURL?.isNotEmpty ?? false)) {
      sourceMapURL = sourceMapOutput.removeBasePath(sourceMapURL);
    }

    return '$css${getCSSAppendage()}';

//3.0.0 20160804
// SourceMapBuilder.prototype.toCSS = function(rootNode, options, imports) {
//     var sourceMapOutput = new SourceMapOutput(
//         {
//             contentsIgnoredCharsMap: imports.contentsIgnoredChars,
//             rootNode: rootNode,
//             contentsMap: imports.contents,
//             sourceMapFilename: this.options.sourceMapFilename,
//             sourceMapURL: this.options.sourceMapURL,
//             outputFilename: this.options.sourceMapOutputFilename,
//             sourceMapBasepath: this.options.sourceMapBasepath,
//             sourceMapRootpath: this.options.sourceMapRootpath,
//             outputSourceFiles: this.options.outputSourceFiles,
//             sourceMapGenerator: this.options.sourceMapGenerator,
//             sourceMapFileInline: this.options.sourceMapFileInline
//         });
//
//     var css = sourceMapOutput.toCSS(options);
//     this.sourceMap = sourceMapOutput.sourceMap;
//     this.sourceMapURL = sourceMapOutput.sourceMapURL;
//     if (this.options.sourceMapInputFilename) {
//         this.sourceMapInputFilename = sourceMapOutput.normalizeFilename(this.options.sourceMapInputFilename);
//     }
//     if (this.options.sourceMapBasepath !== undefined && this.sourceMapURL !== undefined) {
//         this.sourceMapURL = sourceMapOutput.removeBasepath(this.sourceMapURL);
//     }
//     return css + this.getCSSAppendage();
// };
  }

  ///
  String getCSSAppendage() {
    String sourceMapURL = this.sourceMapURL;

    if (options.sourceMapFileInline) {
      if (sourceMap == null) return '';
      sourceMapURL = 'data:application/json;base64,${Base64String.encode(sourceMap)}';
    }

    if (sourceMapURL.isNotEmpty) {
      return '/*# sourceMappingURL=$sourceMapURL */';
    }

    return '';

//2.4.0
//  SourceMapBuilder.prototype.getCSSAppendage = function() {
//
//      var sourceMapURL = this.sourceMapURL;
//      if (this.options.sourceMapFileInline) {
//          if (this.sourceMap === undefined) {
//              return "";
//          }
//          sourceMapURL = "data:application/json;base64," + environment.encodeBase64(this.sourceMap);
//      }
//
//      if (sourceMapURL) {
//          return "/*# sourceMappingURL=" + sourceMapURL + " */";
//      }
//      return "";
//  };
  }

  ///
  /// Get the map
  ///
  String getExternalSourceMap() => sourceMap;

//2.4.0
//  SourceMapBuilder.prototype.getExternalSourceMap = function() {
//      return this.sourceMap;
//  };

  ///
  void setExternalSourceMap(String sourceMap) {
    this.sourceMap = sourceMap;

//2.4.0
//  SourceMapBuilder.prototype.setExternalSourceMap = function(sourceMap) {
//      this.sourceMap = sourceMap;
//  };
  }

  ///
  bool isInline() => options.sourceMapFileInline;

//2.4.0
//  SourceMapBuilder.prototype.isInline = function() {
//      return this.options.sourceMapFileInline;
//  };

  ///
  String getSourceMapURL() => sourceMapURL;

//2.4.0
//  SourceMapBuilder.prototype.getSourceMapURL = function() {
//      return this.sourceMapURL;
//  };

  ///
  String getOutputFilename() => options.sourceMapOutputFilename;

//2.4.0
//  SourceMapBuilder.prototype.getOutputFilename = function() {
//      return this.options.sourceMapOutputFilename;
//  };

  ///
  String getInputFilename() => sourceMapInputFilename;

//2.4.0
//  SourceMapBuilder.prototype.getInputFilename = function() {
//      return this.sourceMapInputFilename;
//  };
}
