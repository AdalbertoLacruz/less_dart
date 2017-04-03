//source: less/to-css-visitor.js 2.5.0

part of visitor.less;

class ToCSSVisitor extends VisitorBase{
  bool      charset = false;
  Contexts  _context;
  Visitor   _visitor;

  ///
  ToCSSVisitor(Contexts context) {
    isReplacing = true;
    _visitor = new Visitor(this);
    _context = context;

//2.3.1
//  var ToCSSVisitor = function(context) {
//      this._visitor = new Visitor(this);
//      this._context = context;
//  };
  }

  ///
  @override
  Ruleset run (Ruleset root) => _visitor.visit(root);

//2.3.1
//  run: function (root) {
//      return this._visitor.visit(root);
//  },

  /// Eliminates for output @variable
  Rule visitRule (Rule ruleNode, VisitArgs visitArgs) {
    if (ruleNode.variable) return null;
    return ruleNode;

//2.3.1
//  visitRule: function (ruleNode, visitArgs) {
//      if (ruleNode.variable) {
//          return;
//      }
//      return ruleNode;
//  },
  }

  ///
  /// mixin definitions do not get eval'd - this means they keep state
  /// so we have to clear that state here so it isn't used if toCSS is called twice
  ///
  void visitMixinDefinition (MixinDefinition mixinNode, VisitArgs visitArgs) {
    mixinNode.frames = <Node>[];

//2.3.1
//  visitMixinDefinition: function (mixinNode, visitArgs) {
//      // mixin definitions do not get eval'd - this means they keep state
//      // so we have to clear that state here so it isn't used if toCSS is called twice
//      mixinNode.frames = [];
//  },
  }

  ///
  void visitExtend (Extend extendNode, VisitArgs visitArgs) {}

//2.3.1
//  visitExtend: function (extendNode, visitArgs) {
//  },

  ///
  Comment visitComment (Comment commentNode, VisitArgs visitArgs) {
    if (commentNode.isSilent(this._context)) return null;
    return commentNode;

//2.3.1
//  visitComment: function (commentNode, visitArgs) {
//      if (commentNode.isSilent(this._context)) {
//          return;
//      }
//      return commentNode;
//  },
  }

  ///
  Media visitMedia (Media mediaNode, VisitArgs visitArgs) {
    mediaNode.accept(this._visitor);
    visitArgs.visitDeeper = false;

    if (mediaNode.rules.isEmpty) return null;
    return mediaNode;

//2.3.1
//  visitMedia: function(mediaNode, visitArgs) {
//      mediaNode.accept(this._visitor);
//      visitArgs.visitDeeper = false;
//
//      if (!mediaNode.rules.length) {
//          return;
//      }
//      return mediaNode;
//  },
  }

  ///
  Import visitImport(Import importNode, VisitArgs visitArgs) {
    if (importNode.path.currentFileInfo.reference && importNode.css) return null;
    return importNode;

//2.4.0+6
//  visitImport: function (importNode, visitArgs) {
//      if (importNode.path.currentFileInfo.reference !== undefined && importNode.css) {
//          return;
//      }
//      return importNode;
//  },
  }

  /// remove
  Options visitOptions(Options optionsNode, VisitArgs visitArgs) {
    return null;
  }

  ///
  bool hasVisibleChild(Directive directiveNode) {
    //prepare list of childs
    List<Ruleset> bodyRules = directiveNode.rules;
    Node          rule;

    // if there is only one nested ruleset and that one has no path, then it is
    // just fake ruleset that got not replaced and we need to look inside it to
    // get real childs
    if (bodyRules.length == 1
        && (bodyRules[0].paths == null || bodyRules[0].paths.isEmpty)) {
      bodyRules = bodyRules[0].rules;
    }

    for (int r = 0; r < bodyRules.length; r++) {
      rule = bodyRules[r];
      if (rule is GetIsReferencedNode && (rule as GetIsReferencedNode).getIsReferenced()) {
        // the directive contains something that was referenced (likely by extend)
        // therefore it needs to be shown in output too
        return true;
      }
    }
    return false;

//2.4.0+1 inside VisitDirective
//      function hasVisibleChild(directiveNode) {
//          //prepare list of childs
//          var rule, bodyRules = directiveNode.rules;
//          //if there is only one nested ruleset and that one has no path, then it is
//          //just fake ruleset that got not replaced and we need to look inside it to
//          //get real childs
//          if (bodyRules.length === 1 && (!bodyRules[0].paths || bodyRules[0].paths.length === 0)) {
//              bodyRules = bodyRules[0].rules;
//          }
//          for (var r = 0; r < bodyRules.length; r++) {
//              rule = bodyRules[r];
//              if (rule.getIsReferenced && rule.getIsReferenced()) {
//                  //the directive contains something that was referenced (likely by extend)
//                  //therefore it needs to be shown in output too
//                  return true;
//              }
//          }
//          return false;
//      }
  }

  ///
  Node visitDirective (Directive directiveNode, VisitArgs visitArgs) {
    if (directiveNode.name == '@charset') {
      if (!directiveNode.getIsReferenced()) return null;

      // Only output the debug info together with subsequent @charset definitions
      // a comment (or @media statement) before the actual @charset directive would
      // be considered illegal css as it has to be on the first line
      if (charset) {
        if (directiveNode.debugInfo != null) {
          final Comment comment = new Comment('/* ' + directiveNode.toCSS(_context).replaceAll(r'\n', '') + ' */\n');
          comment.debugInfo = directiveNode.debugInfo;
          return _visitor.visit(comment);
        }
        return null;
      }
      charset = true;
    }
    if (directiveNode.rules != null && directiveNode.rules.isNotEmpty) {
      // it is still true that it is only one ruleset in array
      // this is last such moment
      _mergeRules(directiveNode.rules[0].rules);

      // process childs
      directiveNode.accept(_visitor);
      visitArgs.visitDeeper = false;

      // the directive was directly referenced and therefore needs to be shown in the output
      if (directiveNode.getIsReferenced()) return directiveNode;

      // if (directiveNode.rules == null || (directiveNode.rules is List) || directiveNode.rules.rules == null) return null;
      if (directiveNode.rules == null || directiveNode.rules.isEmpty) return null;

      // the directive was not directly referenced - we need to check whether some of its childs
      // was referenced
      if (hasVisibleChild(directiveNode)) {
        // marking as referenced in case the directive is stored inside another directive
        directiveNode.markReferenced();
        return directiveNode;
      }

      // The directive was not directly referenced and does not contain anything that
      // was referenced. Therefore it must not be shown in output.
      return null;
    } else {
      if (!directiveNode.getIsReferenced()) return null;
    }

    return directiveNode;

//2.4.0+1
//  visitDirective: function(directiveNode, visitArgs) {
//      if (directiveNode.name === "@charset") {
//          if (!directiveNode.getIsReferenced()) {
//              return;
//          }
//          // Only output the debug info together with subsequent @charset definitions
//          // a comment (or @media statement) before the actual @charset directive would
//          // be considered illegal css as it has to be on the first line
//          if (this.charset) {
//              if (directiveNode.debugInfo) {
//                  var comment = new tree.Comment("/* " + directiveNode.toCSS(this._context).replace(/\n/g, "") + " */\n");
//                  comment.debugInfo = directiveNode.debugInfo;
//                  return this._visitor.visit(comment);
//              }
//              return;
//          }
//          this.charset = true;
//      }
//      function hasVisibleChild(directiveNode) {
//          //prepare list of childs
//          var rule, bodyRules = directiveNode.rules;
//          //if there is only one nested ruleset and that one has no path, then it is
//          //just fake ruleset that got not replaced and we need to look inside it to
//          //get real childs
//          if (bodyRules.length === 1 && (!bodyRules[0].paths || bodyRules[0].paths.length === 0)) {
//              bodyRules = bodyRules[0].rules;
//          }
//          for (var r = 0; r < bodyRules.length; r++) {
//              rule = bodyRules[r];
//              if (rule.getIsReferenced && rule.getIsReferenced()) {
//                  //the directive contains something that was referenced (likely by extend)
//                  //therefore it needs to be shown in output too
//                  return true;
//              }
//          }
//          return false;
//      }
//
//      if (directiveNode.rules && directiveNode.rules.length) {
//          //it is still true that it is only one ruleset in array
//          //this is last such moment
//          this._mergeRules(directiveNode.rules[0].rules);
//          //process childs
//          directiveNode.accept(this._visitor);
//          visitArgs.visitDeeper = false;
//
//          // the directive was directly referenced and therefore needs to be shown in the output
//          if (directiveNode.getIsReferenced()) {
//              return directiveNode;
//          }
//
//          if (!directiveNode.rules || !directiveNode.rules.length) {
//              return ;
//          }
//
//          //the directive was not directly referenced - we need to check whether some of its childs
//          //was referenced
//          if (hasVisibleChild(directiveNode)) {
//              //marking as referenced in case the directive is stored inside another directive
//              directiveNode.markReferenced();
//              return directiveNode;
//          }
//
//          //The directive was not directly referenced and does not contain anything that
//          //was referenced. Therefore it must not be shown in output.
//          return ;
//      } else {
//          if (!directiveNode.getIsReferenced()) {
//              return;
//          }
//      }
//      return directiveNode;
//  },
  }

  ///
  /// Check for errors in Rules with variables (for firstRoot).
  ///
  void checkPropertiesInRoot (List<Node> rules) {
    Node ruleNode;

    for (int i = 0; i < rules.length; i++) {
      ruleNode = rules[i];
      if (ruleNode is Rule && !ruleNode.variable) {
        error(message: 'properties must be inside selector blocks, they cannot be in the root.',
            index: ruleNode.index,
            filename: ruleNode.currentFileInfo != null ? ruleNode.currentFileInfo.filename : null);
      }
    }

//2.3.1
//  checkPropertiesInRoot: function(rules) {
//      var ruleNode;
//      for(var i = 0; i < rules.length; i++) {
//          ruleNode = rules[i];
//          if (ruleNode instanceof tree.Rule && !ruleNode.variable) {
//              throw { message: "properties must be inside selector blocks, they cannot be in the root.",
//                  index: ruleNode.index, filename: ruleNode.currentFileInfo ? ruleNode.currentFileInfo.filename : null};
//          }
//      }
//  },
  }

  /// return Node | List<Node>
  dynamic visitRuleset (Ruleset rulesetNode, VisitArgs visitArgs) {
    final List<dynamic>  rulesets = <dynamic>[]; //Node || List<Node>

    if (rulesetNode.firstRoot) this.checkPropertiesInRoot(rulesetNode.rules);

    if (!rulesetNode.root) {
      if (rulesetNode.paths != null) {
        rulesetNode.paths.retainWhere((List<Selector> p) {
          if (p[0].elements[0].combinator.value == ' ') {
            p[0].elements[0].combinator = new Combinator('');
          }
          for (int i = 0; i < p.length; i++) {
            if (p[i].getIsReferenced() && p[i].getIsOutput()) return true;
          }
          return false;
        });
      }

      // Compile rules and rulesets
      List<Node>  nodeRules = rulesetNode.rules;
      int         nodeRuleCnt = nodeRules?.length ?? 0;
      Node        rule; // Rule | Ruleset

      for (int i = 0; i < nodeRuleCnt; ) {
        rule = nodeRules[i];
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
      if (nodeRuleCnt > 0) {
        rulesetNode.accept(_visitor);
      } else {
        rulesetNode.rules = null;
      }
      visitArgs.visitDeeper = false;

      nodeRules = rulesetNode.rules;
      if (nodeRules != null) {
        _mergeRules(nodeRules);
        nodeRules = rulesetNode.rules;
      }
      if (nodeRules != null) {
        _removeDuplicateRules(nodeRules);
        nodeRules = rulesetNode.rules;
      }

      // now decide whether we keep the ruleset
      if (isNotEmpty(nodeRules) && isNotEmpty(rulesetNode.paths)) {
        rulesets.insert(0, rulesetNode);
      }
    } else {
      rulesetNode.accept(_visitor);
      visitArgs.visitDeeper = false;
      if (rulesetNode.firstRoot || isNotEmpty(rulesetNode.rules)) {
        rulesets.insert(0, rulesetNode);
      }
    }

    if (rulesets.length == 1) return rulesets.first;
    return rulesets;

//2.3.1
//  visitRuleset: function (rulesetNode, visitArgs) {
//      var rule, rulesets = [];
//      if (rulesetNode.firstRoot) {
//          this.checkPropertiesInRoot(rulesetNode.rules);
//      }
//      if (! rulesetNode.root) {
//          if (rulesetNode.paths) {
//              rulesetNode.paths = rulesetNode.paths
//                  .filter(function(p) {
//                      var i;
//                      if (p[0].elements[0].combinator.value === ' ') {
//                          p[0].elements[0].combinator = new(tree.Combinator)('');
//                      }
//                      for(i = 0; i < p.length; i++) {
//                          if (p[i].getIsReferenced() && p[i].getIsOutput()) {
//                              return true;
//                          }
//                      }
//                      return false;
//                  });
//          }
//
//          // Compile rules and rulesets
//          var nodeRules = rulesetNode.rules, nodeRuleCnt = nodeRules ? nodeRules.length : 0;
//          for (var i = 0; i < nodeRuleCnt; ) {
//              rule = nodeRules[i];
//              if (rule && rule.rules) {
//                  // visit because we are moving them out from being a child
//                  rulesets.push(this._visitor.visit(rule));
//                  nodeRules.splice(i, 1);
//                  nodeRuleCnt--;
//                  continue;
//              }
//              i++;
//          }
//          // accept the visitor to remove rules and refactor itself
//          // then we can decide now whether we want it or not
//          if (nodeRuleCnt > 0) {
//              rulesetNode.accept(this._visitor);
//          } else {
//              rulesetNode.rules = null;
//          }
//          visitArgs.visitDeeper = false;
//
//          nodeRules = rulesetNode.rules;
//          if (nodeRules) {
//              this._mergeRules(nodeRules);
//              nodeRules = rulesetNode.rules;
//          }
//          if (nodeRules) {
//              this._removeDuplicateRules(nodeRules);
//              nodeRules = rulesetNode.rules;
//          }
//
//          // now decide whether we keep the ruleset
//          if (nodeRules && nodeRules.length > 0 && rulesetNode.paths.length > 0) {
//              rulesets.splice(0, 0, rulesetNode);
//          }
//      } else {
//          rulesetNode.accept(this._visitor);
//          visitArgs.visitDeeper = false;
//          if (rulesetNode.firstRoot || (rulesetNode.rules && rulesetNode.rules.length > 0)) {
//              rulesets.splice(0, 0, rulesetNode);
//          }
//      }
//      if (rulesets.length === 1) {
//          return rulesets[0];
//      }
//      return rulesets;
//  },
  }

  ///
  /// Remove duplicates
  ///
  void _removeDuplicateRules (List<Node> rules) {
    if (rules == null) return;

    Node                        rule;

    // If !Key Map[Rule1.name] = Rule1
    // If key Map[Rule1.name] = [Rule1.tocss] + [Rule2.tocss if different] + ...
    final Map<String, dynamic>  ruleCache = <String, dynamic>{}; //<String, Rule || List<String>>

    String                      ruleCSS;
    List<String>                ruleList;

    for (int i = rules.length - 1; i >= 0; i--) {
      rule = rules[i];
      if (rule is Rule) {
        if (!ruleCache.containsKey(rule.name)) {
          ruleCache[rule.name] = rule;
        } else {
          ruleList = ruleCache[rule.name] = (ruleCache[rule.name] is Rule)
            ? <String>[ruleCache[rule.name].toCSS(_context)]
            : ruleCache[rule.name];

          ruleCSS = rule.toCSS(_context);

          if (ruleList.contains(ruleCSS)) {
            rules.removeAt(i);
          } else {
            ruleList.add(ruleCSS);
          }
        }
      }
    }

//2.3.1
//  _removeDuplicateRules: function(rules) {
//      if (!rules) { return; }
//
//      // remove duplicates
//      var ruleCache = {},
//          ruleList, rule, i;
//
//      for(i = rules.length - 1; i >= 0 ; i--) {
//          rule = rules[i];
//          if (rule instanceof tree.Rule) {
//              if (!ruleCache[rule.name]) {
//                  ruleCache[rule.name] = rule;
//              } else {
//                  ruleList = ruleCache[rule.name];
//                  if (ruleList instanceof tree.Rule) {
//                      ruleList = ruleCache[rule.name] = [ruleCache[rule.name].toCSS(this._context)];
//                  }
//                  var ruleCSS = rule.toCSS(this._context);
//                  if (ruleList.indexOf(ruleCSS) !== -1) {
//                      rules.splice(i, 1);
//                  } else {
//                      ruleList.push(ruleCSS);
//                  }
//              }
//          }
//      }
//  },
  }

  ///
  void _mergeRules (List<Node> rules) {
    if (rules == null) return;

    final Map<String, List<Rule>> groups = <String, List<Rule>>{};

    for (int i = 0; i < rules.length; i++) {
      final Node rule = rules[i];

      if (rule is Rule && rule.merge.isNotEmpty) {
        final String key = <String>[rule.name,
            isNotEmpty(rule.important) ? '!' : ''].join(','); //important == '!' or ''
        if (!groups.containsKey(key)) {
          groups[key] = <Rule>[];
        } else {
          rules.removeAt(i--); // ??
        }
        groups[key].add(rule);
      }
    }

    groups.forEach((String k, List<Rule> parts) {
      Expression toExpression(List<Rule> values) =>
          new Expression(values.map((Rule p) => p.value).toList());

      Value toValue(List<Expression> values) =>
          new Value(values.map((Expression p) => p).toList());

      if (parts.length > 1) {
        List<Rule>              lastSpacedGroup = <Rule>[];
        final Rule              rule = parts[0];
        final List<Expression>  spacedGroups = <Expression>[];

        parts.forEach((Rule p) {
          if (p.merge == '+') {
            if (lastSpacedGroup.isNotEmpty) {
              spacedGroups.add(toExpression(lastSpacedGroup));
            }
            lastSpacedGroup = <Rule>[];
          }
          lastSpacedGroup.add(p);
        });
        spacedGroups.add(toExpression(lastSpacedGroup));
        rule.value = toValue(spacedGroups);
      }
    });

//2.3.1
//  _mergeRules: function (rules) {
//      if (!rules) { return; }
//
//      var groups = {},
//          parts,
//          rule,
//          key;
//
//      for (var i = 0; i < rules.length; i++) {
//          rule = rules[i];
//
//          if ((rule instanceof tree.Rule) && rule.merge) {
//              key = [rule.name,
//                  rule.important ? "!" : ""].join(",");
//
//              if (!groups[key]) {
//                  groups[key] = [];
//              } else {
//                  rules.splice(i--, 1);
//              }
//
//              groups[key].push(rule);
//          }
//      }
//
//      Object.keys(groups).map(function (k) {
//
//          function toExpression(values) {
//              return new (tree.Expression)(values.map(function (p) {
//                  return p.value;
//              }));
//          }
//
//          function toValue(values) {
//              return new (tree.Value)(values.map(function (p) {
//                  return p;
//              }));
//          }
//
//          parts = groups[k];
//
//          if (parts.length > 1) {
//              rule = parts[0];
//              var spacedGroups = [];
//              var lastSpacedGroup = [];
//              parts.map(function (p) {
//              if (p.merge === "+") {
//                  if (lastSpacedGroup.length > 0) {
//                          spacedGroups.push(toExpression(lastSpacedGroup));
//                      }
//                      lastSpacedGroup = [];
//                  }
//                  lastSpacedGroup.push(p);
//              });
//              spacedGroups.push(toExpression(lastSpacedGroup));
//              rule.value = toValue(spacedGroups);
//          }
//      });
//  }
  }

  /// func visitor.visit distribuitor
  @override
  Function visitFtn(Node node) {
    if (node is Comment)    return visitComment;
    if (node is Media)      return visitMedia;
    if (node is Directive)  return visitDirective;
    if (node is Extend)     return visitExtend;
    if (node is Import)     return visitImport;
    if (node is MixinDefinition) return visitMixinDefinition;
    if (node is Options)    return visitOptions;
    if (node is Rule)       return visitRule;
    if (node is Ruleset)    return visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  @override
  Function visitFtnOut(Node node) => null;
}
