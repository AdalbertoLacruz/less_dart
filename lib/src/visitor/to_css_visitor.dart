//source: less/to-css-visitor.js 3.0.0 20160718

part of visitor.less;

///
class ToCSSVisitor extends VisitorBase with MergeRulesMixin {
  ///
  bool            charset = false;

  Contexts        _context;

  ///
  CSSVisitorUtils utils;

  Visitor         _visitor;

  ///
  ToCSSVisitor(Contexts context) {
    isReplacing = true;
    _visitor = new Visitor(this);
    _context = context;
    utils = new CSSVisitorUtils(context);

//2.5.3 20151120
// var ToCSSVisitor = function(context) {
//     this._visitor = new Visitor(this);
//     this._context = context;
//     this.utils = new CSSVisitorUtils(context);
// };
  }

  ///
  @override
  Ruleset run(Ruleset root) => _visitor.visit(root);

//2.3.1
//  run: function (root) {
//      return this._visitor.visit(root);
//  },

  ///
  /// Eliminates for output: @variable && no visible nodes
  ///
  Declaration visitDeclaration(Declaration declNode, VisitArgs visitArgs) {
    if (declNode.blocksVisibility() || declNode.variable)
        return null;
    return declNode;

//2.8.0 20160702
// visitDeclaration: function (declNode, visitArgs) {
//     if (declNode.blocksVisibility() || declNode.variable) {
//         return;
//     }
//     return declNode;
// },
  }

  ///
  /// mixin definitions do not get eval'd - this means they keep state
  /// so we have to clear that state here so it isn't used if toCSS is called twice
  ///
  void visitMixinDefinition(MixinDefinition mixinNode, VisitArgs visitArgs) {
    mixinNode.frames = <Node>[];

//2.3.1
//  visitMixinDefinition: function (mixinNode, visitArgs) {
//      // mixin definitions do not get eval'd - this means they keep state
//      // so we have to clear that state here so it isn't used if toCSS is called twice
//      mixinNode.frames = [];
//  },
  }

  ///
  void visitExtend(Extend extendNode, VisitArgs visitArgs) {}

//2.3.1
//  visitExtend: function (extendNode, visitArgs) {
//  },

  ///
  Comment visitComment(Comment commentNode, VisitArgs visitArgs) {
    if (commentNode.blocksVisibility() || commentNode.isSilent(_context))
        return null;
    return commentNode;

//2.5.3 20151120
// visitComment: function (commentNode, visitArgs) {
//     if (commentNode.blocksVisibility() || commentNode.isSilent(this._context)) {
//         return;
//     }
//     return commentNode;
// },
  }

  ///
  Media visitMedia(Media mediaNode, VisitArgs visitArgs) {
    final List<Node> originalRules = mediaNode.rules[0].rules;
    mediaNode.accept(_visitor);
    visitArgs.visitDeeper = false;

    return utils.resolveVisibility(mediaNode, originalRules);

//2.5.3 20151120
// visitMedia: function(mediaNode, visitArgs) {
//     var originalRules = mediaNode.rules[0].rules;
//     mediaNode.accept(this._visitor);
//     visitArgs.visitDeeper = false;
//
//     return this.utils.resolveVisibility(mediaNode, originalRules);
// },
  }

  ///
  Import visitImport(Import importNode, VisitArgs visitArgs) {
    if (importNode.blocksVisibility())
        return null;
    return importNode;

//2.5.3 20151120
// visitImport: function (importNode, visitArgs) {
//     if (importNode.blocksVisibility()) {
//         return ;
//     }
//     return importNode;
// },
  }

  // remove
  ///
  Options visitOptions(Options optionsNode, VisitArgs visitArgs) => null;

    ///
  Node visitAtRule(AtRule atRuleNode, VisitArgs visitArgs) {
    if (atRuleNode.rules?.isNotEmpty ?? false) {
      return visitAtRuleWithBody(atRuleNode, visitArgs);
    } else {
      return visitAtRuleWithoutBody(atRuleNode, visitArgs);
    }

//2.8.0 20160702
// visitAtRule: function(atRuleNode, visitArgs) {
//     if (atRuleNode.rules && atRuleNode.rules.length) {
//         return this.visitAtRuleWithBody(atRuleNode, visitArgs);
//     } else {
//         return this.visitAtRuleWithoutBody(atRuleNode, visitArgs);
//     }
// },
}

  ///
  Node visitAtRuleWithBody(AtRule atRuleNode, VisitArgs visitArgs) {
    // if there is only one nested ruleset and that one has no path, then it is
    // just fake ruleset
    bool hasFakeRuleset(AtRule directiveNode) {
      final List<Ruleset> bodyRules = directiveNode.rules;
      return (bodyRules.length == 1)
          && (bodyRules.first.paths?.isEmpty ?? true);
    }

    List<Node> getBodyRules(AtRule directiveNode) {
      final List<Ruleset> nodeRules = directiveNode.rules;
      if (hasFakeRuleset(directiveNode))
          return nodeRules[0].rules;
      return nodeRules;
    }

    // it is still true that it is only one ruleset in array
    // this is last such moment
    // process childs
    final List<Node> originalRules = getBodyRules(atRuleNode);
    atRuleNode.accept(_visitor);
    visitArgs.visitDeeper = false;

    if (!utils.isEmpty(atRuleNode))
        mergeRules(atRuleNode.rules[0].rules);
    return utils.resolveVisibility(atRuleNode, originalRules);

//2.8.0 20160702
// visitAtRuleWithBody: function(atRuleNode, visitArgs) {
//     //if there is only one nested ruleset and that one has no path, then it is
//     //just fake ruleset
//     function hasFakeRuleset(atRuleNode) {
//         var bodyRules = atRuleNode.rules;
//         return bodyRules.length === 1 && (!bodyRules[0].paths || bodyRules[0].paths.length === 0);
//     }
//     function getBodyRules(atRuleNode) {
//         var nodeRules = atRuleNode.rules;
//         if (hasFakeRuleset(atRuleNode)) {
//             return nodeRules[0].rules;
//         }
//
//         return nodeRules;
//     }
//     //it is still true that it is only one ruleset in array
//     //this is last such moment
//     //process childs
//     var originalRules = getBodyRules(atRuleNode);
//     atRuleNode.accept(this._visitor);
//     visitArgs.visitDeeper = false;
//
//     if (!this.utils.isEmpty(atRuleNode)) {
//         this._mergeRules(atRuleNode.rules[0].rules);
//     }
//
//     return this.utils.resolveVisibility(atRuleNode, originalRules);
// },
  }

  ///
  Node visitAtRuleWithoutBody(AtRule atRuleNode, VisitArgs visitArgs) {
    if (atRuleNode.blocksVisibility())
        return null;

    if (atRuleNode.name == "@charset") {
      // Only output the debug info together with subsequent @charset definitions
      // a comment (or @media statement) before the actual @charset atRule would
      // be considered illegal css as it has to be on the first line
      if (charset) {
        if (atRuleNode.debugInfo != null) {
          final String directive =
              atRuleNode.toCSS(_context).replaceAll(r'\n', '');
          final Comment comment = new Comment('/* $directive */\n')
              ..debugInfo = atRuleNode.debugInfo;
          return _visitor.visit(comment);
        }
        return null;
      }
      charset = true;
    }
    return atRuleNode;

//2.8.0 20160702
// visitAtRuleWithoutBody: function(atRuleNode, visitArgs) {
//     if (atRuleNode.blocksVisibility()) {
//         return;
//     }
//
//     if (atRuleNode.name === "@charset") {
//         // Only output the debug info together with subsequent @charset definitions
//         // a comment (or @media statement) before the actual @charset atrule would
//         // be considered illegal css as it has to be on the first line
//         if (this.charset) {
//             if (atRuleNode.debugInfo) {
//                 var comment = new tree.Comment("/* " + atRuleNode.toCSS(this._context).replace(/\n/g, "") + " */\n");
//                 comment.debugInfo = atRuleNode.debugInfo;
//                 return this._visitor.visit(comment);
//             }
//             return;
//         }
//         this.charset = true;
//     }
//
//     return atRuleNode;
// },
  }

  ///
  /// Check for errors in root
  ///
  void checkValidNodes(List<Node> rules, {bool isRoot}) {
    if (rules == null)
      return;

    for (int i = 0; i < rules.length; i++) {
      final Node ruleNode = rules[i];
      if (isRoot && ruleNode is Declaration && !ruleNode.variable) {
        error(message: 'Properties must be inside selector blocks. They cannot be in the root',
            index: ruleNode.index,
            filename: ruleNode.currentFileInfo?.filename);
      }
      if (ruleNode is Call) {
        error(message: "Function '${ruleNode.name}' is undefined",
            index: ruleNode.index,
            filename: ruleNode.currentFileInfo?.filename);
      }
      if ((ruleNode.type != null) && !ruleNode.allowRoot) {
        error(message: '${ruleNode.type} node returned by a function is not valid here',
            index: ruleNode.index,
            filename: ruleNode.currentFileInfo?.filename);
      }
    }

//3.0.0 20160714
// checkValidNodes: function(rules, isRoot) {
//     if (!rules) {
//         return;
//     }
//
//     for (var i = 0; i < rules.length; i++) {
//         var ruleNode = rules[i];
//         if (isRoot && ruleNode instanceof tree.Declaration && !ruleNode.variable) {
//             throw { message: "Properties must be inside selector blocks. They cannot be in the root",
//                 index: ruleNode.getIndex(), filename: ruleNode.fileInfo() && ruleNode.fileInfo().filename};
//         }
//         if (ruleNode instanceof tree.Call) {
//             throw { message: "Function '" + ruleNode.name + "' is undefined",
//                 index: ruleNode.getIndex(), filename: ruleNode.fileInfo() && ruleNode.fileInfo().filename};
//         }
//         if (ruleNode.type && !ruleNode.allowRoot) {
//             throw { message: ruleNode.type + " node returned by a function is not valid here",
//                 index: ruleNode.getIndex(), filename: ruleNode.fileInfo() && ruleNode.fileInfo().filename};
//         }
//     }
// },
  }

  /// return Node | List<Node>
  dynamic visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    //at this point rulesets are nested into each other
    final List<dynamic> rulesets = <dynamic>[]; //Node || List<Node>

    // error test for rules at first level, not inside a ruleset ??
    if (rulesetNode.firstRoot)
        checkValidNodes(rulesetNode.rules, isRoot: rulesetNode.firstRoot);

    if (!rulesetNode.root) {
      //remove invisible paths
      _compileRulesetPaths(rulesetNode);

      // remove rulesets from this ruleset body and compile them separately
      final List<Node>  nodeRules = rulesetNode.rules;
      int nodeRuleCnt = nodeRules?.length ?? 0;

      for (int i = 0; i < nodeRuleCnt;) {
        final Node rule = nodeRules[i];
        if (rule?.rules != null) {
          // visit because we are moving them out from being a child
          rulesets.add(_visitor.visit(rule));
          nodeRules.removeAt(i);
          nodeRuleCnt--;
          continue;
        }
        i++;
      }

      // accept the visitor to remove rules and refactor itself
      // then we can decide now whether we want it or not
      // compile body
      if (nodeRuleCnt > 0) {
        rulesetNode.accept(_visitor);
      } else {
        rulesetNode.rules = null;
      }
      visitArgs.visitDeeper = false;
    } else { //if (! rulesetNode.root)
      rulesetNode.accept(_visitor);
      visitArgs.visitDeeper = false;
    }

    if (rulesetNode.rules != null) {
      mergeRules(rulesetNode.rules);
      _removeDuplicateRules(rulesetNode.rules);
    }

    //now decide whether we keep the ruleset
    if (utils.isVisibleRuleset(rulesetNode)) {
      rulesetNode.ensureVisibility();
      rulesets.insert(0, rulesetNode);
    }

    if (rulesets.length == 1)
        return rulesets.first;
    return rulesets;

//2.6.1 20160305
// visitRuleset: function (rulesetNode, visitArgs) {
//     //at this point rulesets are nested into each other
//     var rule, rulesets = [];
//
//     this.checkValidNodes(rulesetNode.rules, rulesetNode.firstRoot);
//
//     if (! rulesetNode.root) {
//         //remove invisible paths
//         this._compileRulesetPaths(rulesetNode);
//
//         // remove rulesets from this ruleset body and compile them separately
//         var nodeRules = rulesetNode.rules, nodeRuleCnt = nodeRules ? nodeRules.length : 0;
//         for (var i = 0; i < nodeRuleCnt; ) {
//             rule = nodeRules[i];
//             if (rule && rule.rules) {
//                 // visit because we are moving them out from being a child
//                 rulesets.push(this._visitor.visit(rule));
//                 nodeRules.splice(i, 1);
//                 nodeRuleCnt--;
//                 continue;
//             }
//             i++;
//         }
//         // accept the visitor to remove rules and refactor itself
//         // then we can decide nogw whether we want it or not
//         // compile body
//         if (nodeRuleCnt > 0) {
//             rulesetNode.accept(this._visitor);
//         } else {
//             rulesetNode.rules = null;
//         }
//         visitArgs.visitDeeper = false;
//
//     } else { //if (! rulesetNode.root) {
//         rulesetNode.accept(this._visitor);
//         visitArgs.visitDeeper = false;
//     }
//
//     if (rulesetNode.rules) {
//         this._mergeRules(rulesetNode.rules);
//         this._removeDuplicateRules(rulesetNode.rules);
//     }
//
//     //now decide whether we keep the ruleset
//     if (this.utils.isVisibleRuleset(rulesetNode)) {
//         rulesetNode.ensureVisibility();
//         rulesets.splice(0, 0, rulesetNode);
//     }
//
//     if (rulesets.length === 1) {
//         return rulesets[0];
//     }
//     return rulesets;
// },
  }

  void _compileRulesetPaths(Ruleset rulesetNode) {
    if (rulesetNode.paths != null) {
      rulesetNode.paths.retainWhere((List<Selector> p) {
        if (p[0].elements[0].combinator.value == ' ')
            p[0].elements[0].combinator = new Combinator('');
        for (int i = 0; i < p.length; i++) {
          if ((p[i].isVisible() ?? false) && p[i].getIsOutput())
              return true;
        }
        return false;
      });
    }

//2.5.3 20151120
// _compileRulesetPaths: function(rulesetNode) {
//   if (rulesetNode.paths) {
//       rulesetNode.paths = rulesetNode.paths
//           .filter(function(p) {
//               var i;
//               if (p[0].elements[0].combinator.value === ' ') {
//                   p[0].elements[0].combinator = new(tree.Combinator)('');
//               }
//               for (i = 0; i < p.length; i++) {
//                   if (p[i].isVisible() && p[i].getIsOutput()) {
//                       return true;
//                   }
//               }
//               return false;
//           });
//   }
// },
  }

  ///
  /// Remove duplicates
  ///
  void _removeDuplicateRules(List<Node> rules) {
    if (rules == null)
        return;

    // If !Key Map[Rule1.name] = Rule1
    // If key Map[Rule1.name] = [Rule1.tocss] + [Rule2.tocss if different] + ...
    final Map<String, dynamic>  ruleCache = <String, dynamic>{}; //<String, Declaration || List<String>>

    for (int i = rules.length - 1; i >= 0; i--) {
      final Node rule = rules[i];
      if (rule is Declaration) {
        if (!ruleCache.containsKey(rule.name)) {
          ruleCache[rule.name] = rule;
        } else {
          final List<String> ruleList = ruleCache[rule.name] =
              (ruleCache[rule.name] is Declaration)
                  ? <String>[ruleCache[rule.name].toCSS(_context)]
                  : ruleCache[rule.name];

          final String ruleCSS = rule.toCSS(_context);

          if (ruleList.contains(ruleCSS)) {
            rules.removeAt(i);
          } else {
            ruleList.add(ruleCSS);
          }
        }
      }
    }

//2.8.0 20160702
// _removeDuplicateRules: function(rules) {
//     if (!rules) { return; }
//
//     // remove duplicates
//     var ruleCache = {},
//         ruleList, rule, i;
//
//     for (i = rules.length - 1; i >= 0 ; i--) {
//         rule = rules[i];
//         if (rule instanceof tree.Declaration) {
//             if (!ruleCache[rule.name]) {
//                 ruleCache[rule.name] = rule;
//             } else {
//                 ruleList = ruleCache[rule.name];
//                 if (ruleList instanceof tree.Declaration) {
//                     ruleList = ruleCache[rule.name] = [ruleCache[rule.name].toCSS(this._context)];
//                 }
//                 var ruleCSS = rule.toCSS(this._context);
//                 if (ruleList.indexOf(ruleCSS) !== -1) {
//                     rules.splice(i, 1);
//                 } else {
//                     ruleList.push(ruleCSS);
//                 }
//             }
//         }
//     }
// },
  }

  // mergeRules is in tree/merge_rules_mixin.dart

  ///
  Anonymous visitAnonymous(Anonymous anonymousNode, VisitArgs visitArgs) {
    if (anonymousNode.blocksVisibility())
        return null;

    anonymousNode.accept(_visitor);
    return anonymousNode;

//2.5.3 20151120
// visitAnonymous: function(anonymousNode, visitArgs) {
//     if (anonymousNode.blocksVisibility()) {
//         return ;
//     }
//     anonymousNode.accept(this._visitor);
//     return anonymousNode;
// }
  }

  /// func visitor.visit distribuitor
  @override
  Function visitFtn(Node node) {
    if (node is Anonymous)
        return visitAnonymous;
    if (node is Comment)
        return visitComment;
    if (node is Media)
        return visitMedia;
    if (node is AtRule)
        return visitAtRule;
    if (node is Directive) //compatibility old node type
        return visitAtRule;
    if (node is Extend)
        return visitExtend;
    if (node is Import)
        return visitImport;
    if (node is MixinDefinition)
        return visitMixinDefinition;
    if (node is Options)
        return visitOptions;
    if (node is Declaration)
        return visitDeclaration;
    if (node is Rule) //compatibility old node type
        return visitDeclaration;
    if (node is Ruleset)
        return visitRuleset;
    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) => null;
}
