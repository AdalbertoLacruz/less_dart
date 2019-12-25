//source: less/tree/media.js 3.0.0 20170608

part of tree.less;

///
class Media extends DirectiveBase {
  @override
  final String type = 'Media';

  ///
  Node features;

  ///
  Media(List<Node> value, List<Node> features,
      [int index, FileInfo currentFileInfo, VisibilityInfo visibilityInfo])
      : super(
            index: index,
            currentFileInfo: currentFileInfo,
            visibilityInfo: visibilityInfo) {
    final List<Node> selectors =
        Selector(<Element>[], index: _index, currentFileInfo: _fileInfo)
            .createEmptySelectors();

    this.features = Value(features);
    rules = <Ruleset>[Ruleset(selectors, value)..allowImports = true];
    allowRoot = true;
    setParent(selectors, this);
    setParent(this.features, this);
    setParent(rules, this);

//3.0.0 20160714
// var Media = function (value, features, index, currentFileInfo, visibilityInfo) {
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//
//     var selectors = (new Selector([], null, null, this._index, this._fileInfo)).createEmptySelectors();
//
//     this.features = new Value(features);
//     this.rules = [new Ruleset(selectors, value)];
//     this.rules[0].allowImports = true;
//     this.copyVisibilityInfo(visibilityInfo);
//     this.allowRoot = true;
//     this.setParent(selectors, this);
//     this.setParent(this.features, this);
//     this.setParent(this.rules, this);
// };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'features': features, 'rules': rules};

  ///
  @override
  void accept(VisitorBase visitor) {
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
  @override
  void genCSS(Contexts context, Output output) {
    output.add('@media ', fileInfo: _fileInfo, index: _index);
    features.genCSS(context, output);
    outputRuleset(context, output, rules);

//3.0.0 20160714
// Media.prototype.genCSS = function (context, output) {
//     output.add('@media ', this._fileInfo, this._index);
//     this.features.genCSS(context, output);
//     this.outputRuleset(context, output, this.rules);
// };
  }

  ///
  @override
  Node eval(Contexts context) {
    if (context.mediaBlocks == null) {
      context
        ..mediaBlocks = <Media>[]
        ..mediaPath = <Media>[];
    }

    final media = Media(null, <Node>[], _index, _fileInfo, visibilityInfo());

    if (debugInfo != null) {
      rules[0].debugInfo = debugInfo;
      media.debugInfo = debugInfo;
    }

    media.features = features.eval(context);

    context.mediaPath.add(media);
    context.mediaBlocks.add(media);

    (rules[0] as Ruleset).functionRegistry = FunctionRegistry.inherit(
        (context.frames[0] as VariableMixin).functionRegistry);

    context.frames.insert(0, rules[0]);
    media.rules = <Ruleset>[rules[0].eval(context)];
    context.frames.removeAt(0);

    context.mediaPath.removeLast();

    return context.mediaPath.isEmpty
        ? media.evalTop(context)
        : media.evalNested(context);

//3.0.0 20170608
// Media.prototype.eval = function (context) {
//     if (!context.mediaBlocks) {
//         context.mediaBlocks = [];
//         context.mediaPath = [];
//     }
//
//     var media = new Media(null, [], this._index, this._fileInfo, this.visibilityInfo());
//     if (this.debugInfo) {
//         this.rules[0].debugInfo = this.debugInfo;
//         media.debugInfo = this.debugInfo;
//     }
//
//     media.features = this.features.eval(context);
//
//     context.mediaPath.push(media);
//     context.mediaBlocks.push(media);
//
//     this.rules[0].functionRegistry = context.frames[0].functionRegistry.inherit();
//     context.frames.unshift(this.rules[0]);
//     media.rules = [this.rules[0].eval(context)];
//     context.frames.shift();
//
//     context.mediaPath.pop();
//
//     return context.mediaPath.length === 0 ? media.evalTop(context) :
//                 media.evalNested(context);
// }
  }

  ///
  /// Returns Media or Ruleset
  ///
  Node evalTop(Contexts context) {
    Node result = this;

    // Render all dependent Media blocks.
    if (context.mediaBlocks.length > 1) {
      final selectors =
          Selector(<Element>[], index: index, currentFileInfo: currentFileInfo)
              .createEmptySelectors();

      result = Ruleset(
          selectors, <Node>[...context.mediaBlocks]) //Must be List<Node>
        ..multiMedia = true
        ..copyVisibilityInfo(visibilityInfo());

      setParent(result, this);
    }

    context
      ..mediaBlocks = null
      ..mediaPath = null;

    return result;

//3.0.0 20160714
// Media.prototype.evalTop = function (context) {
//     var result = this;
//
//     // Render all dependent Media blocks.
//     if (context.mediaBlocks.length > 1) {
//         var selectors = (new Selector([], null, null, this.getIndex(), this.fileInfo())).createEmptySelectors();
//         result = new Ruleset(selectors, context.mediaBlocks);
//         result.multiMedia = true;
//         result.copyVisibilityInfo(this.visibilityInfo());
//         this.setParent(result, this);
//     }
//
//     delete context.mediaBlocks;
//     delete context.mediaPath;
//
//     return result;
// };
  }

  ///
  Ruleset evalNested(Contexts context) {
    final mediaPath = context.mediaPath.sublist(0)..add(this);
    final path = <List<Node>>[];
    dynamic value; //Node or List<Node>

    // Extract the media-query conditions separated with `,` (OR).
    for (var i = 0; i < mediaPath.length; i++) {
      value = (mediaPath[i].features is Value)
          ? mediaPath[i].features.value
          : mediaPath[i].features;
      path.add((value is Node) ? <Node>[value] : value);
    }

    // Trace all permutations to generate the resulting media-query.
    //
    // (a, b and c) with nested (d, e) ->
    //    a and d
    //    a and e
    //    b and c and d
    //    b and c and e

    features = Value(permute(path).map((List<Node> path) {
      path = path
          // All must be Node!!. This not necessary
          .map((Node fragment) =>
              (fragment is Node) ? fragment : Anonymous(fragment))
          .toList();

      for (var i = path.length - 1; i > 0; i--) {
        path.insert(i, Anonymous('and'));
      }
      return Expression(path);
    }).toList());
    setParent(features, this);

    // Fake a tree-node that doesn't output anything.
    return Ruleset(<Selector>[], <Node>[]);

//3.0.0 20160714
// Media.prototype.evalNested = function (context) {
//     var i, value,
//         path = context.mediaPath.concat([this]);
//
//     // Extract the media-query conditions separated with `,` (OR).
//     for (i = 0; i < path.length; i++) {
//         value = path[i].features instanceof Value ?
//                     path[i].features.value : path[i].features;
//         path[i] = Array.isArray(value) ? value : [value];
//     }
//
//     // Trace all permutations to generate the resulting media-query.
//     //
//     // (a, b and c) with nested (d, e) ->
//     //    a and d
//     //    a and e
//     //    b and c and d
//     //    b and c and e
//     this.features = new Value(this.permute(path).map(function (path) {
//         path = path.map(function (fragment) {
//             return fragment.toCSS ? fragment : new Anonymous(fragment);
//         });
//
//         for (i = path.length - 1; i > 0; i--) {
//             path.splice(i, 0, new Anonymous("and"));
//         }
//
//         return new Expression(path);
//     }));
//     this.setParent(this.features, this);
//
//     // Fake a tree-node that doesn't output anything.
//     return new Ruleset([], []);
// };
  }

  ///
  @override
  bool isRulesetLike() => true;

//3.0.0 20160716
// Media.prototype.isRulesetLike = function() { return true; };

  ///
  /// Converts
  ///
  /// `[[Node1], [Node2], [Node3]]` to `[[Node1, Node2, Node3]]`
  ///
  /// `[[Node1, Node2], [Node3, Node4]]` to `[[Node1, Node3], [Node2, Node3], [Node1, Node4], [Node2, Node4]]`
  ///
  List<List<Node>> permute(List<List<Node>> arr) {
    if (arr.length < 2) return arr;

    final result = <List<Node>>[];
    final List<dynamic> rest = (arr.length == 2)
        ? arr.last
        : permute(arr.sublist(1)); // List<Node> | List<List<Node>>

    for (var i = 0; i < rest.length; i++) {
      for (var j = 0; j < arr[0].length; j++) {
        result.add(<Node>[
          arr[0][j],
          ...rest[i] is! List ? <Node>[rest[i]] : rest[i]
        ]);
      }
    }
    return result;

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
    rules = <Ruleset>[
      Ruleset(selectors.sublist(0), <Node>[rules[0]])
    ];
    setParent(rules, this);

//3.0.0 20160714
// Media.prototype.bubbleSelectors = function (selectors) {
//     if (!selectors) {
//         return;
//     }
//     this.rules = [new Ruleset(utils.copyArray(selectors), [this.rules[0]])];
//     this.setParent(this.rules, this);
// };
  }

  @override
  String toString() {
    final output = Output()..add('@media ');
    features.genCSS(null, output);
    return output.toString();
  }
}
