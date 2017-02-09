//source: less/tree/media.js 2.5.0

part of tree.less;

//2.3.1 extends from Directive
class Media extends DirectiveBase {
  Node features;

  bool isRulesetLike() => true;

  final String type = 'Media';

  ///
  Media(value, List<Node> features, [int index, FileInfo currentFileInfo]):super() {
    this.index = index;
    this.currentFileInfo = currentFileInfo;
    isReferenced = false;
    //List<Node> selectors = emptySelectors();
    List<Node> selectors = (new Selector([], null, null, this.index, this.currentFileInfo)).createEmptySelectors();

    this.features = new Value(features);
    this.rules = [new Ruleset(selectors, value)
                  ..allowImports = true];

//2.4.0+1
//  var Media = function (value, features, index, currentFileInfo) {
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//
//      var selectors = (new Selector([], null, null, this.index, this.currentFileInfo)).createEmptySelectors();
//
//      this.features = new Value(features);
//      this.rules = [new Ruleset(selectors, value)];
//      this.rules[0].allowImports = true;
//  };
  }

  ///
  void accept(Visitor visitor) {
    if (features != null) features = visitor.visit(features);
    if (rules != null) rules = visitor.visitArray(rules);

//2.3.1
//  Media.prototype.accept = function (visitor) {
//      if (this.features) {
//          this.features = visitor.visit(this.features);
//      }
//      if (this.rules) {
//          this.rules = visitor.visitArray(this.rules);
//      }
//  };
  }

  ///
  void genCSS(Contexts context, Output output) {
    output.add('@media ', currentFileInfo, index);
    features.genCSS(context, output);
    outputRuleset(context, output, rules);

//2.3.1
//  Media.prototype.genCSS = function (context, output) {
//      output.add('@media ', this.currentFileInfo, this.index);
//      this.features.genCSS(context, output);
//      this.outputRuleset(context, output, this.rules);
//  };
  }

  ///
  eval(Contexts context) {
    if (context.mediaBlocks == null) {
      context.mediaBlocks = [];
      context.mediaPath = [];
    }

    Media media = new Media (null, [], index, currentFileInfo);
    if (debugInfo != null) {
      rules[0].debugInfo = debugInfo;
      media.debugInfo = debugInfo;
    }
    bool strictMathBypass = false;
    if (!context.strictMath) {
      strictMathBypass = true;
      context.strictMath = true; //??
    }

    try {
      media.features = features.eval(context);
    } finally {
      if (strictMathBypass) context.strictMath = false;
    }

    context.mediaPath.add(media);
    context.mediaBlocks.add(media);

    this.rules[0].functionRegistry = new FunctionRegistry.inherit((context.frames[0]as VariableMixin).functionRegistry);
    context.frames.insert(0, rules[0]);
    media.rules = <Ruleset>[rules[0].eval(context)];
    context.frames.removeAt(0);

    context.mediaPath.removeLast();

    return context.mediaPath.isEmpty ? media.evalTop(context) : media.evalNested(context);

//2.4.0 20150320
//  Media.prototype.eval = function (context) {
//      if (!context.mediaBlocks) {
//          context.mediaBlocks = [];
//          context.mediaPath = [];
//      }
//
//      var media = new Media(null, [], this.index, this.currentFileInfo);
//      if (this.debugInfo) {
//          this.rules[0].debugInfo = this.debugInfo;
//          media.debugInfo = this.debugInfo;
//      }
//      var strictMathBypass = false;
//      if (!context.strictMath) {
//          strictMathBypass = true;
//          context.strictMath = true;
//      }
//      try {
//          media.features = this.features.eval(context);
//      }
//      finally {
//          if (strictMathBypass) {
//              context.strictMath = false;
//          }
//      }
//
//      context.mediaPath.push(media);
//      context.mediaBlocks.push(media);
//
//      this.rules[0].functionRegistry = context.frames[0].functionRegistry.inherit();
//      context.frames.unshift(this.rules[0]);
//      media.rules = [this.rules[0].eval(context)];
//      context.frames.shift();
//
//      context.mediaPath.pop();
//
//      return context.mediaPath.length === 0 ? media.evalTop(context) :
//                  media.evalNested(context);
//  };
  }

  ///
  /// Returns Media or Ruleset
  ///
  Node evalTop(Contexts context) {
    Node result = this;

    // Render all dependent Media blocks.
    if (context.mediaBlocks.length > 1) {
      List<Selector> selectors = (new Selector([], null, null, index, currentFileInfo)).createEmptySelectors();
      result = new Ruleset(selectors, context.mediaBlocks)
                    ..multiMedia = true;
    }

    context.mediaBlocks = null;
    context.mediaPath = null;

    return result;

//2.4.0+1
//  Media.prototype.evalTop = function (context) {
//      var result = this;
//
//      // Render all dependent Media blocks.
//      if (context.mediaBlocks.length > 1) {
//          var selectors = (new Selector([], null, null, this.index, this.currentFileInfo)).createEmptySelectors();
//          result = new Ruleset(selectors, context.mediaBlocks);
//          result.multiMedia = true;
//      }
//
//      delete context.mediaBlocks;
//      delete context.mediaPath;
//
//      return result;
//  };
  }

  ///
  Node evalNested(Contexts context) {
    var value; //Node or List
    List<Media> mediaPath = context.mediaPath.sublist(0)..add(this);
    List<List<Node>> path = [];

    // Extract the media-query conditions separated with `,` (OR).
    for (int i = 0; i < mediaPath.length; i++) {
      value = (mediaPath[i].features is Value)
          ? mediaPath[i].features.value
          : mediaPath[i].features;
      path.add((value is List<Node>) ? value :  <Node>[value]);
    }

    // Trace all permutations to generate the resulting media-query.
    //
    // (a, b and c) with nested (d, e) ->
    //    a and d
    //    a and e
    //    b and c and d
    //    b and c and e

    features = new Value(permute(path).map((path) {
      path = path.map((fragment){
        return (fragment is Node) ? fragment : new Anonymous(fragment);
      }).toList();

      for (int i = path.length - 1; i > 0; i--) {
        path.insert(i, new Anonymous('and'));
      }

      return new Expression(path);
    }).toList());

    // Fake a tree-node that doesn't output anything.
    return new Ruleset([], []);

//2.3.1
//  Media.prototype.evalNested = function (context) {
//      var i, value,
//          path = context.mediaPath.concat([this]);
//
//      // Extract the media-query conditions separated with `,` (OR).
//      for (i = 0; i < path.length; i++) {
//          value = path[i].features instanceof Value ?
//                      path[i].features.value : path[i].features;
//          path[i] = Array.isArray(value) ? value : [value];
//      }
//
//      // Trace all permutations to generate the resulting media-query.
//      //
//      // (a, b and c) with nested (d, e) ->
//      //    a and d
//      //    a and e
//      //    b and c and d
//      //    b and c and e
//      this.features = new Value(this.permute(path).map(function (path) {
//          path = path.map(function (fragment) {
//              return fragment.toCSS ? fragment : new Anonymous(fragment);
//          });
//
//          for(i = path.length - 1; i > 0; i--) {
//              path.splice(i, 0, new Anonymous("and"));
//          }
//
//          return new Expression(path);
//      }));
//
//      // Fake a tree-node that doesn't output anything.
//      return new Ruleset([], []);
//  };
  }

  ///
  /// Converts [[Node1], [Node2], [Node3]] to [[Node1, Node2, Node3]]
  /// permute List 3x1 to List 1x3
  ///
  List<List> permute(List<List> arr) {
    if (arr.isEmpty) {
      return [];
    } else if (arr.length == 1) {
      return arr[0];
    } else {
      List<List> result = <List>[];
      List rest = permute(arr.sublist(1));
      for (int i = 0; i < rest.length; i++) {
        for (int j = 0; j < arr[0].length; j++) {
          if (rest[i] is! List) rest[i] = [rest[i]]; //avoid problems with addAll
          result.add([arr[0][j]]..addAll(rest[i]));
        }
      }
      return result;
    }

//2.3.1
//  Media.prototype.permute = function (arr) {
//    if (arr.length === 0) {
//        return [];
//    } else if (arr.length === 1) {
//        return arr[0];
//    } else {
//        var result = [];
//        var rest = this.permute(arr.slice(1));
//        for (var i = 0; i < rest.length; i++) {
//            for (var j = 0; j < arr[0].length; j++) {
//                result.push([arr[0][j]].concat(rest[i]));
//            }
//        }
//        return result;
//    }
//  };
  }

  ///
  void bubbleSelectors(List<Selector> selectors) {
    if (selectors == null) return;
    rules = [new Ruleset(selectors.sublist(0), <Node>[rules[0]])];

//2.3.1
//  Media.prototype.bubbleSelectors = function (selectors) {
//    if (!selectors) {
//        return;
//    }
//    this.rules = [new Ruleset(selectors.slice(0), [this.rules[0]])];
//  };
  }
}