//source: less/parse-tree.js 2.5.0

part of render.less;

///
class ParseTree {
  ///
  ImportManager imports;
  ///
  Environment   environment;
  ///
  Ruleset       root;

  ///
  ParseTree(this.root, this.imports) {
    environment = new Environment();
  }

  ///
  /// The root becomes in the result
  ///
  RenderResult toCSS(LessOptions options, Contexts context) { //context for errors
    Ruleset               evaldRoot;
    final RenderResult    result = new RenderResult();
    LessSourceMapBuilder  sourceMapBuilder;
    Contexts              toCSSOptions;

    try {
      evaldRoot = new TransformTree().call(root, options);

//      if (options.compress) {
//        //environment.logger.warn("The compress option has been deprecated. We recommend you use a dedicated css minifier, for instance see less-plugin-clean-css.");
//      }

      toCSSOptions = new Contexts()
          ..compress = options.compress
          ..cleanCss = options.cleanCss
          ..dumpLineNumbers = options.dumpLineNumbers
          ..strictUnits = options.strictUnits
          ..numPrecision = 8;

      if (options.sourceMap) {
        sourceMapBuilder = new LessSourceMapBuilder(options.sourceMapOptions);
        result.css = sourceMapBuilder.toCSS(evaldRoot, toCSSOptions, imports);
      } else {
        result.css = evaldRoot.toCSS(toCSSOptions).toString();
      }
    } catch (e) {
      throw new LessExceptionError(LessError.transform(e, context: context));
    }

    if (options.pluginManager != null) {
      options.pluginManager
          .getPostProcessors()
          .forEach((Processor postProcessor) {
            result.css = postProcessor.process(result.css, <String, dynamic>{
                'sourceMap': sourceMapBuilder,
                'options': options,
                'imports': imports
            });
          });
    }

    if (options.sourceMap) {
      result.map = sourceMapBuilder.getExternalSourceMap();
    }

    result.imports = <String>[];
    imports.files.forEach((String file, dynamic node) { //node is Ruleset
      if (file != imports.rootFilename) result.imports.add(file);
    });

    return result;

//2.4.0
//    ParseTree.prototype.toCSS = function(options) {
//        var evaldRoot, result = {}, sourceMapBuilder;
//        try {
//            evaldRoot = transformTree(this.root, options);
//        } catch (e) {
//            throw new LessError(e, this.imports);
//        }
//
//        try {
//            var compress = Boolean(options.compress);
//            if (compress) {
//                logger.warn("The compress option has been deprecated. We recommend you use a dedicated css minifier, for instance see less-plugin-clean-css.");
//            }
//
//            var toCSSOptions = {
//                compress: compress,
//                dumpLineNumbers: options.dumpLineNumbers,
//                strictUnits: Boolean(options.strictUnits),
//                numPrecision: 8};
//
//            if (options.sourceMap) {
//                sourceMapBuilder = new SourceMapBuilder(options.sourceMap);
//                result.css = sourceMapBuilder.toCSS(evaldRoot, toCSSOptions, this.imports);
//            } else {
//                result.css = evaldRoot.toCSS(toCSSOptions);
//            }
//        } catch (e) {
//            throw new LessError(e, this.imports);
//        }
//
//        if (options.pluginManager) {
//            var postProcessors = options.pluginManager.getPostProcessors();
//            for (var i = 0; i < postProcessors.length; i++) {
//                result.css = postProcessors[i].process(result.css, { sourceMap: sourceMapBuilder, options: options, imports: this.imports });
//            }
//        }
//        if (options.sourceMap) {
//            result.map = sourceMapBuilder.getExternalSourceMap();
//        }
//
//        result.imports = [];
//        for (var file in this.imports.files) {
//            if (this.imports.files.hasOwnProperty(file) && file !== this.imports.rootFilename) {
//                result.imports.push(file);
//            }
//        }
//        return result;
//    };
  }
}

// ******************************************************

/// Result type for ParseTree
class RenderResult {
  ///
  String        css;
  ///
  List<String>  imports; //filename
  ///
  String        map;

  ///
  RenderResult();
}
