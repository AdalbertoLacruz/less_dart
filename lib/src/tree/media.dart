//source: less/tree/media.js 1.7.5

part of tree.less;

class Media extends Node with OutputRulesetMixin, VariableMixin implements EvalNode, MarkReferencedNode, ToCSSNode {
  Node features;
  int index;
  FileInfo currentFileInfo;

  bool isReferenced = false;
  List<Node> rules;

  final String type = 'Media';

  Media(value, List features, [int this.index, FileInfo this.currentFileInfo]) {
    List<Node> selectors = emptySelectors();

    this.features = new Value(features);
    this.rules = [new Ruleset(selectors, value)
                  ..allowImports = true];
  }

//tree.Media = function (value, features, index, currentFileInfo) {
//    this.index = index;
//    this.currentFileInfo = currentFileInfo;
//
//    var selectors = this.emptySelectors();
//
//    this.features = new(tree.Value)(features);
//    this.rules = [new(tree.Ruleset)(selectors, value)];
//    this.rules[0].allowImports = true;
//};

  ///
  void accept(Visitor visitor) {
    if (this.features != null) this.features = visitor.visit(this.features);
    if (this.rules != null) this.rules = visitor.visitArray(this.rules);
  }

  ///
  void genCSS(Contexts env, Output output) {
    output.add('@media ', this.currentFileInfo, this.index);
    this.features.genCSS(env, output);
    outputRuleset(env, output, this.rules);
  }

//    toCSS: tree.toCSS,

  ///
  eval(Contexts env) {
    if (env.mediaBlocks == null) {
      env.mediaBlocks = [];
      env.mediaPath = [];
    }

    Media media = new Media (null, [], this.index, this.currentFileInfo);
    if (this.debugInfo != null) {
      this.rules[0].debugInfo = this.debugInfo;
      media.debugInfo = this.debugInfo;
    }
    bool strictMathBypass = false;
    if (!env.strictMath) {
      strictMathBypass = true;
      env.strictMath = true; //??
    }

    try {
      media.features = this.features.eval(env);
    } finally {
      if (strictMathBypass) env.strictMath = false;
    }

    env.mediaPath.add(media);
    env.mediaBlocks.add(media);

    env.frames.insert(0, this.rules[0]);
    media.rules = [this.rules[0].eval(env)];
    env.frames.removeAt(0);

    env.mediaPath.removeLast();

    return env.mediaPath.isEmpty ? media.evalTop(env) : media.evalNested(env);

//    eval: function (env) {
//        if (!env.mediaBlocks) {
//            env.mediaBlocks = [];
//            env.mediaPath = [];
//        }
//
//        var media = new(tree.Media)(null, [], this.index, this.currentFileInfo);
//        if(this.debugInfo) {
//            this.rules[0].debugInfo = this.debugInfo;
//            media.debugInfo = this.debugInfo;
//        }
//        var strictMathBypass = false;
//        if (!env.strictMath) {
//            strictMathBypass = true;
//            env.strictMath = true;
//        }
//        try {
//            media.features = this.features.eval(env);
//        }
//        finally {
//            if (strictMathBypass) {
//                env.strictMath = false;
//            }
//        }
//
//        env.mediaPath.push(media);
//        env.mediaBlocks.push(media);
//
//        env.frames.unshift(this.rules[0]);
//        media.rules = [this.rules[0].eval(env)];
//        env.frames.shift();
//
//        env.mediaPath.pop();
//
//        return env.mediaPath.length === 0 ? media.evalTop(env) :
//                    media.evalNested(env);
//    },
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

  List<Selector> emptySelectors() {
    Element el = new Element('', '&', index, currentFileInfo);
    List<Selector> sels = [new Selector([el],null, null, index, currentFileInfo)
                              ..mediaEmpty = true];
    return sels;

//    emptySelectors: function() {
//        var el = new(tree.Element)('', '&', this.index, this.currentFileInfo),
//            sels = [new(tree.Selector)([el], null, null, this.index, this.currentFileInfo)];
//        sels[0].mediaEmpty = true;
//        return sels;
//    },
  }


  //--- MarkReferencedNode

  void markReferenced() {
    List<Node> rules = this.rules[0].rules;
    (this.rules[0] as MarkReferencedNode).markReferenced();
    this.isReferenced = true;
    for (int i = 0; i < rules.length; i++) {
      if (rules[i] is MarkReferencedNode) (rules[i] as MarkReferencedNode).markReferenced();
    }

//    markReferenced: function () {
//        var i, rules = this.rules[0].rules;
//        this.rules[0].markReferenced();
//        this.isReferenced = true;
//        for (i = 0; i < rules.length; i++) {
//            if (rules[i].markReferenced) {
//                rules[i].markReferenced();
//            }
//        }
//    },
  }

  /// returns Media or Ruleset
  Node evalTop(Contexts env) {
    Node result = this;

    // Render all dependent Media blocks.
    if (env.mediaBlocks.length > 1) {
      List<Selector> selectors = this.emptySelectors();
      result = new Ruleset(selectors, env.mediaBlocks)
                    ..multiMedia = true;
    }

    env.mediaBlocks = null;
    env.mediaPath = null;

    return result;

//    evalTop: function (env) {
//        var result = this;
//
//        // Render all dependent Media blocks.
//        if (env.mediaBlocks.length > 1) {
//            var selectors = this.emptySelectors();
//            result = new(tree.Ruleset)(selectors, env.mediaBlocks);
//            result.multiMedia = true;
//        }
//
//        delete env.mediaBlocks;
//        delete env.mediaPath;
//
//        return result;
//    },
  }

  Node evalNested(Contexts env) {
    var value; //Node or List
    List<Media> mediaPath = env.mediaPath.sublist(0)..add(this);
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
        return (fragment is ToCSSNode) ? fragment : new Anonymous(fragment);
      }).toList();

      for (int i = path.length - 1; i > 0; i--) {
        path.insert(i, new Anonymous('and'));
      }

      return new Expression(path);
    }).toList());

    // Fake a tree-node that doesn't output anything.
    return new Ruleset([], []);

//    evalNested: function (env) {
//        var i, value,
//            path = env.mediaPath.concat([this]); //TODO AL concat sublist(0)
//
//        // Extract the media-query conditions separated with `,` (OR).
//        for (i = 0; i < path.length; i++) {
//            value = path[i].features instanceof tree.Value ?
//                        path[i].features.value : path[i].features;
//            path[i] = Array.isArray(value) ? value : [value];
//        }
//
//        // Trace all permutations to generate the resulting media-query.
//        //
//        // (a, b and c) with nested (d, e) ->
//        //    a and d
//        //    a and e
//        //    b and c and d
//        //    b and c and e
//        this.features = new(tree.Value)(this.permute(path).map(function (path) {
//            path = path.map(function (fragment) {
//                return fragment.toCSS ? fragment : new(tree.Anonymous)(fragment);
//            });
//
//            for(i = path.length - 1; i > 0; i--) {
//                path.splice(i, 0, new(tree.Anonymous)("and"));
//            }
//
//            return new(tree.Expression)(path);
//        }));
//
//        // Fake a tree-node that doesn't output anything.
//        return new(tree.Ruleset)([], []);
//    },
  }

  ///
  /// Converts [[Node1], [Node2], [Node3]] to [[Node1, Node2, Node3]]
  /// permute List 3x1 to List 1x3
  /// #
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

//    permute: function (arr) {
//      if (arr.length === 0) {
//          return [];
//      } else if (arr.length === 1) {
//          return arr[0];
//      } else {
//          var result = [];
//          var rest = this.permute(arr.slice(1));
//          for (var i = 0; i < rest.length; i++) {
//              for (var j = 0; j < arr[0].length; j++) {
//                  result.push([arr[0][j]].concat(rest[i]));
//              }
//          }
//          return result;
//      }
//    },
  }

  ///
  void bubbleSelectors(List<Selector> selectors) {
    if (selectors == null) return;
    this.rules = [new Ruleset(selectors.sublist(0), [this.rules[0]])];

//    bubbleSelectors: function (selectors) {
//      if (!selectors)
//        return;
//      this.rules = [new(tree.Ruleset)(selectors.slice(0), [this.rules[0]])];
//    }
  }
}