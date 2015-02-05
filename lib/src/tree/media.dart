//source: less/tree/media.js 2.3.1

part of tree.less;

//TODO 2.3.1 extends from Directive
class Media extends Node with OutputRulesetMixin, VariableMixin implements MarkReferencedNode {
  Node features;
  int index;
  FileInfo currentFileInfo;

  bool isReferenced = false;
  bool isRulesetLike(bool root) => true;
  List<Node> rules;

  final String type = 'Media';

  ///
  //2.3.1 ok
  Media(value, List features, [int this.index, FileInfo this.currentFileInfo]) {
    List<Node> selectors = emptySelectors();

    this.features = new Value(features);
    this.rules = [new Ruleset(selectors, value)
                  ..allowImports = true];

//2.3.1
//  var Media = function (value, features, index, currentFileInfo) {
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//
//      var selectors = this.emptySelectors();
//
//      this.features = new Value(features);
//      this.rules = [new Ruleset(selectors, value)];
//      this.rules[0].allowImports = true;
//  };
  }

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    if (this.features != null) this.features = visitor.visit(this.features);
    if (this.rules != null) this.rules = visitor.visitArray(this.rules);

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
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add('@media ', this.currentFileInfo, this.index);
    this.features.genCSS(context, output);
    outputRuleset(context, output, this.rules);

//2.3.1
//  Media.prototype.genCSS = function (context, output) {
//      output.add('@media ', this.currentFileInfo, this.index);
//      this.features.genCSS(context, output);
//      this.outputRuleset(context, output, this.rules);
//  };
  }

  ///
  //2.3.1 ok
  eval(Contexts context) {
    if (context.mediaBlocks == null) {
      context.mediaBlocks = [];
      context.mediaPath = [];
    }

    Media media = new Media (null, [], this.index, this.currentFileInfo);
    if (this.debugInfo != null) {
      this.rules[0].debugInfo = this.debugInfo;
      media.debugInfo = this.debugInfo;
    }
    bool strictMathBypass = false;
    if (!context.strictMath) {
      strictMathBypass = true;
      context.strictMath = true; //??
    }

    try {
      media.features = this.features.eval(context);
    } finally {
      if (strictMathBypass) context.strictMath = false;
    }

    context.mediaPath.add(media);
    context.mediaBlocks.add(media);

    context.frames.insert(0, this.rules[0]);
    media.rules = [this.rules[0].eval(context)];
    context.frames.removeAt(0);

    context.mediaPath.removeLast();

    return context.mediaPath.isEmpty ? media.evalTop(context) : media.evalNested(context);


//2.3.1
//  Media.prototype.eval = function (context) {
//      if (!context.mediaBlocks) {
//          context.mediaBlocks = [];
//          context.mediaPath = [];
//      }
//
//      var media = new Media(null, [], this.index, this.currentFileInfo);
//      if(this.debugInfo) {
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

//VariableMixin
//  variable(name) {
////    variable: function (name) { return tree.Ruleset.prototype.variable.call(this.rules[0], name); },
//  }
//
//  find() {
////    find: function () { return tree.Ruleset.prototype.find.apply(this.rules[0], arguments); },
//  }
//
//  rulesets() {
////    rulesets: function () { return tree.Ruleset.prototype.rulesets.apply(this.rules[0]); },
//  }

  ///
  //2.3.1 ok
  List<Selector> emptySelectors() {
    Element el = new Element('', '&', index, currentFileInfo);
    List<Selector> sels = [new Selector([el],null, null, index, currentFileInfo)
                              ..mediaEmpty = true];
    return sels;

//2.3.1
//  Media.prototype.emptySelectors = function() {
//      var el = new Element('', '&', this.index, this.currentFileInfo),
//          sels = [new Selector([el], null, null, this.index, this.currentFileInfo)];
//      sels[0].mediaEmpty = true;
//      return sels;
//  };
  }

  //--- MarkReferencedNode

  ///
  //2.3.1 ok
  void markReferenced() {
    List<Node> rules = this.rules[0].rules;
    (this.rules[0] as MarkReferencedNode).markReferenced();
    this.isReferenced = true;
    for (int i = 0; i < rules.length; i++) {
      if (rules[i] is MarkReferencedNode) (rules[i] as MarkReferencedNode).markReferenced();
    }

//2.3.1
//  Media.prototype.markReferenced = function () {
//      var i, rules = this.rules[0].rules;
//      this.rules[0].markReferenced();
//      this.isReferenced = true;
//      for (i = 0; i < rules.length; i++) {
//          if (rules[i].markReferenced) {
//              rules[i].markReferenced();
//          }
//      }
//  };
  }

  ///
  /// Returns Media or Ruleset
  ///
  //2.3.1 ok
  Node evalTop(Contexts context) {
    Node result = this;

    // Render all dependent Media blocks.
    if (context.mediaBlocks.length > 1) {
      List<Selector> selectors = this.emptySelectors();
      result = new Ruleset(selectors, context.mediaBlocks)
                    ..multiMedia = true;
    }

    context.mediaBlocks = null;
    context.mediaPath = null;

    return result;

//2.3.1
//  Media.prototype.evalTop = function (context) {
//      var result = this;
//
//      // Render all dependent Media blocks.
//      if (context.mediaBlocks.length > 1) {
//          var selectors = this.emptySelectors();
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
  //2.3.1 ok
  Node evalNested(Contexts context) {
    var value; //Node or List
    List<Media> mediaPath = context.mediaPath.sublist(0)..add(this);
    List<List<Node>> path = [];

    // Extract the media-query conditions separated with `,` (OR).
    for (int i = 0; i < mediaPath.length; i++) {
      value = (mediaPath[i].features is Value)
          ? mediaPath[i].features.value
          : mediaPath[i].features;
      path.add((value is List) ? value :  [value]);
    }

    // Trace all permutations to generate the resulting media-query.
    //
    // (a, b and c) with nested (d, e) ->
    //    a and d
    //    a and e
    //    b and c and d
    //    b and c and e

    this.features = new Value(this.permute(path).map((path) {
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
  //2.3.1 ok
  List<List> permute(List<List> arr) {
    if (arr.isEmpty) {
      return [];
    } else if (arr.length == 1) {
      return arr[0];
    } else {
      List result = [];
      List rest = this.permute(arr.sublist(1));
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
  //2.3.1 ok
  void bubbleSelectors(List<Selector> selectors) {
    if (selectors == null) return;
    this.rules = [new Ruleset(selectors.sublist(0), [this.rules[0]])];

//2.3.1
//  Media.prototype.bubbleSelectors = function (selectors) {
//    if (!selectors) {
//        return;
//    }
//    this.rules = [new Ruleset(selectors.slice(0), [this.rules[0]])];
//  };
  }
}