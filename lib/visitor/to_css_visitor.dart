//source: less/to-css-visitor.js 1.7.5

part of visitor.less;

class ToCSSVisitor extends VisitorBase{
  Env _env;

  bool charset = false;
  bool isReplacing = true;
  Visitor _visitor;

  ToCSSVisitor(Env env) {
    this._visitor = new Visitor(this);
    this._env = env;
  }

  ///
  Node run (Ruleset root) => this._visitor.visit(root);

  /// Eliminates for output @variable
  visitRule (Rule ruleNode, VisitArgs visitArgs) {
    if (ruleNode.variable) return [];
    return ruleNode;
  }

  ///
  /// mixin definitions do not get eval'd - this means they keep state
  /// so we have to clear that state here so it isn't used if toCSS is called twice
  ///
  List visitMixinDefinition (MixinDefinition mixinNode, VisitArgs visitArgs) {
    mixinNode.frames = [];
    return [];
  }

  ///
  List visitExtend (Extend extendNode, VisitArgs visitArgs) => [];

  /// #
  visitComment (Comment commentNode, VisitArgs visitArgs) {
    if (commentNode.isSilent(this._env)) return [];
    return commentNode;
  }

  ///
  visitMedia (Media mediaNode, VisitArgs visitArgs) {
    mediaNode.accept(this._visitor);
    visitArgs.visitDeeper = false;

    if (mediaNode.rules.isEmpty) return [];
    return mediaNode;
  }

  ///
  visitDirective (Directive directiveNode, VisitArgs visitArgs) {
    if (isTrue(directiveNode.currentFileInfo.reference) && !directiveNode.isReferenced) {
      return [];
    }
    if (directiveNode.name == '@charset') {
      // Only output the debug info together with subsequent @charset definitions
      // a comment (or @media statement) before the actual @charset directive would
      // be considered illegal css as it has to be on the first line
      if (this.charset) {
        if (directiveNode.debugInfo != null) {
          Comment comment = new Comment('/* ' + directiveNode.toCSS(this._env).replaceAll(r'\n', '') + ' */\n');
          comment.debugInfo = directiveNode.debugInfo;
          return this._visitor.visit(comment);
        }
        return [];
      }
      this.charset = true;
    }
    if (directiveNode.rules != null && directiveNode.rules.rules != null) {
      this._mergeRules(directiveNode.rules.rules);
    }
    return directiveNode;

//        visitDirective: function(directiveNode, visitArgs) {
//            if (directiveNode.currentFileInfo.reference && !directiveNode.isReferenced) {
//                return [];
//            }
//            if (directiveNode.name === "@charset") {
//                // Only output the debug info together with subsequent @charset definitions
//                // a comment (or @media statement) before the actual @charset directive would
//                // be considered illegal css as it has to be on the first line
//                if (this.charset) {
//                    if (directiveNode.debugInfo) {
//                        var comment = new tree.Comment("/* " + directiveNode.toCSS(this._env).replace(/\n/g, "")+" */\n");
//                        comment.debugInfo = directiveNode.debugInfo;
//                        return this._visitor.visit(comment);
//                    }
//                    return [];
//                }
//                this.charset = true;
//            }
//            if (directiveNode.rules && directiveNode.rules.rules) {
//                this._mergeRules(directiveNode.rules.rules);
//            }
//            return directiveNode;
//        },
  }

  /// check for errors in Rules with variables (for firstRoot). #
  void checkPropertiesInRoot (List<Node> rules) {
    Node ruleNode;

    for (int i = 0; i < rules.length; i++) {
      ruleNode = rules[i];
      if (ruleNode is Rule && !(ruleNode as Rule).variable) {
        error(message: 'properties must be inside selector blocks, they cannot be in the root.',
            index: (ruleNode as Rule).index,
            filename: (ruleNode as Rule).currentFileInfo != null ? (ruleNode as Rule).currentFileInfo.filename : null);
      }
    }

//        checkPropertiesInRoot: function(rules) {
//            var ruleNode;
//            for(var i = 0; i < rules.length; i++) {
//                ruleNode = rules[i];
//                if (ruleNode instanceof tree.Rule && !ruleNode.variable) {
//                    throw { message: "properties must be inside selector blocks, they cannot be in the root.",
//                        index: ruleNode.index, filename: ruleNode.currentFileInfo ? ruleNode.currentFileInfo.filename : null};
//                }
//            }
//        },
  }

  ///
  visitRuleset (Ruleset rulesetNode, VisitArgs visitArgs) {
    Node rule;
    List<Node> rulesets = [];

    if (rulesetNode.firstRoot) this.checkPropertiesInRoot(rulesetNode.rules);

    if (!rulesetNode.root) {
      if (rulesetNode.paths != null) {
        rulesetNode.paths.retainWhere((p) {
          int i;
          if (p[0].elements[0].combinator.value == ' ') {
            p[0].elements[0].combinator = new Combinator('');
          }
          for (i = 0; i < p.length; i++) {
            if (p[i].getIsReferenced() && p[i].getIsOutput()) return true;
          }
          return false;
        });
      }

      // Compile rules and rulesets
      List<Node> nodeRules = rulesetNode.rules;
      int nodeRuleCnt = nodeRules != null ? nodeRules.length : 0;

      for (int i = 0; i < nodeRuleCnt; ) {
        rule = nodeRules[i];
        if (rule != null && rule.rules != null) {
          // visit because we are moving them out from being a child
          rulesets.add(this._visitor.visit(rule));
          nodeRules.removeAt(i);
          nodeRuleCnt--;
          continue;
        }
        i++;
      }

      // accept the visitor to remove rules and refactor itself
      // then we can decide now whether we want it or not
      if (nodeRuleCnt > 0) {
        rulesetNode.accept(this._visitor);
      } else {
        rulesetNode.rules = null;
      }
      visitArgs.visitDeeper = false;

      nodeRules = rulesetNode.rules;
      if (nodeRules != null) {
        this._mergeRules(nodeRules);
        nodeRules = rulesetNode.rules;
      }
      if (nodeRules != null) {
        this._removeDuplicateRules(nodeRules);
        nodeRules = rulesetNode.rules;
      }

      // now decide whether we keep the ruleset
      if (isNotEmpty(nodeRules) && rulesetNode.paths.isNotEmpty) {
        rulesets.insert(0, rulesetNode);
      }
    } else {
      rulesetNode.accept(this._visitor);
      visitArgs.visitDeeper = false;
      if (rulesetNode.firstRoot || isNotEmpty(rulesetNode.rules)) {
        rulesets.insert(0, rulesetNode);
      }
    }

    if (rulesets.length == 1) return rulesets.first;
    return rulesets;

//        visitRuleset: function (rulesetNode, visitArgs) {
//            var rule, rulesets = [];
//            if (rulesetNode.firstRoot) {
//                this.checkPropertiesInRoot(rulesetNode.rules);
//            }
//            if (! rulesetNode.root) {
//                if (rulesetNode.paths) {
//                    rulesetNode.paths = rulesetNode.paths
//                        .filter(function(p) {
//                            var i;
//                            if (p[0].elements[0].combinator.value === ' ') {
//                                p[0].elements[0].combinator = new(tree.Combinator)('');
//                            }
//                            for(i = 0; i < p.length; i++) {
//                                if (p[i].getIsReferenced() && p[i].getIsOutput()) {
//                                    return true;
//                                }
//                            }
//                            return false;
//                        });
//                }
//
//                // Compile rules and rulesets
//                var nodeRules = rulesetNode.rules, nodeRuleCnt = nodeRules ? nodeRules.length : 0;
//                for (var i = 0; i < nodeRuleCnt; ) {
//                    rule = nodeRules[i];
//                    if (rule && rule.rules) {
//                        // visit because we are moving them out from being a child
//                        rulesets.push(this._visitor.visit(rule));
//                        nodeRules.splice(i, 1);
//                        nodeRuleCnt--;
//                        continue;
//                    }
//                    i++;
//                }
//                // accept the visitor to remove rules and refactor itself
//                // then we can decide now whether we want it or not
//                if (nodeRuleCnt > 0) {
//                    rulesetNode.accept(this._visitor);
//                } else {
//                    rulesetNode.rules = null;
//                }
//                visitArgs.visitDeeper = false;
//
//                nodeRules = rulesetNode.rules;
//                if (nodeRules) {
//                    this._mergeRules(nodeRules);
//                    nodeRules = rulesetNode.rules;
//                }
//                if (nodeRules) {
//                    this._removeDuplicateRules(nodeRules);
//                    nodeRules = rulesetNode.rules;
//                }
//
//                // now decide whether we keep the ruleset
//                if (nodeRules && nodeRules.length > 0 && rulesetNode.paths.length > 0) {
//                    rulesets.splice(0, 0, rulesetNode);
//                }
//            } else {
//                rulesetNode.accept(this._visitor);
//                visitArgs.visitDeeper = false;
//                if (rulesetNode.firstRoot || (rulesetNode.rules && rulesetNode.rules.length > 0)) {
//                    rulesets.splice(0, 0, rulesetNode);
//                }
//            }
//            if (rulesets.length === 1) {
//                return rulesets[0];
//            }
//            return rulesets;
//        },
  }

  ///
  void _removeDuplicateRules (List<Node> rules) {
    if (rules == null) return;

    // remove duplicates
    Map ruleCache = {};
    var ruleList;
    Node rule;
    int i;

    for (i = rules.length - 1; i >= 0; i--) {
      rule = rules[i];
      if (rule is Rule) {
        Rule rrule = rule as Rule;
        if (!ruleCache.containsKey(rrule.name)) {
          ruleCache[rrule.name] = rule;
        } else {
          ruleList = ruleCache[rrule.name];
          if (ruleList is Rule) {
            ruleList = ruleCache[rrule.name] = [ruleCache[rrule.name].toCSS(this._env)];
          }
          String ruleCSS = rrule.toCSS(this._env);
          if ((ruleList as List).contains(ruleCSS)) {
            rules.removeAt(i);
          } else {
            (ruleList as List).add(ruleCSS);
          }
        }
      }
    }

//        _removeDuplicateRules: function(rules) {
//            if (!rules) { return; }
//
//            // remove duplicates
//            var ruleCache = {},
//                ruleList, rule, i;
//
//            for(i = rules.length - 1; i >= 0 ; i--) {
//                rule = rules[i];
//                if (rule instanceof tree.Rule) {
//                    if (!ruleCache[rule.name]) {
//                        ruleCache[rule.name] = rule;
//                    } else {
//                        ruleList = ruleCache[rule.name];
//                        if (ruleList instanceof tree.Rule) {
//                            ruleList = ruleCache[rule.name] = [ruleCache[rule.name].toCSS(this._env)];
//                        }
//                        var ruleCSS = rule.toCSS(this._env);
//                        if (ruleList.indexOf(ruleCSS) !== -1) {
//                            rules.splice(i, 1);
//                        } else {
//                            ruleList.push(ruleCSS);
//                        }
//                    }
//                }
//            }
//        },
  }

  ///
  void _mergeRules (List<Node> rules) {
    if (rules == null) return;

    Map<String, List<Rule>> groups = {};
    var parts;
    var rule;
    var key;

    for (int i = 0; i < rules.length; i++) {
      rule = rules[i];

      if (rule is Rule && rule.merge.isNotEmpty) {
        key = [rule.name,
               isNotEmpty(rule.important) ? '!' : ''].join(','); //important == '!' or ''
        if (!groups.containsKey(key)) {
          groups[key] = [];
        } else {
          rules.removeAt(i--); // ??
        }
        groups[key].add(rule);
      }
    }

    groups.forEach((k, parts) { //key as String, value as List

      toExpression(List<Rule> values) {
        return new Expression(values.map((p){
          return p.value;
        }).toList());
      }

      toValue(List<Rule> values) {
        return new Value(values.map((p){
          return p;
        }).toList());
      }

      if (parts.length > 1) {
        Rule rule = parts[0];
        List spacedGroups = [];
        List lastSpacedGroup = [];
        parts.forEach((p) {
          if (p.merge == '+') {
            if (lastSpacedGroup.isNotEmpty) {
              spacedGroups.add(toExpression(lastSpacedGroup));
            }
            lastSpacedGroup = [];
          }
          lastSpacedGroup.add(p);
        });
        spacedGroups.add(toExpression(lastSpacedGroup));
        rule.value = toValue(spacedGroups);
      }
    });

//        _mergeRules: function (rules) {
//            if (!rules) { return; }
//
//            var groups = {},
//                parts,
//                rule,
//                key;
//
//            for (var i = 0; i < rules.length; i++) {
//                rule = rules[i];
//
//                if ((rule instanceof tree.Rule) && rule.merge) {
//                    key = [rule.name,
//                        rule.important ? "!" : ""].join(",");
//
//                    if (!groups[key]) {
//                        groups[key] = [];
//                    } else {
//                        rules.splice(i--, 1);
//                    }
//
//                    groups[key].push(rule);
//                }
//            }
//
//            Object.keys(groups).map(function (k) {
//
//                function toExpression(values) {
//                    return new (tree.Expression)(values.map(function (p) {
//                        return p.value;
//                    }));
//                }
//
//                function toValue(values) {
//                    return new (tree.Value)(values.map(function (p) {
//                        return p;
//                    }));
//                }
//
//                parts = groups[k];
//
//                if (parts.length > 1) {
//                    rule = parts[0];
//                    var spacedGroups = [];
//                    var lastSpacedGroup = [];
//                    parts.map(function (p) {
//                    if (p.merge==="+") {
//                        if (lastSpacedGroup.length > 0) {
//                                spacedGroups.push(toExpression(lastSpacedGroup));
//                            }
//                            lastSpacedGroup = [];
//                        }
//                        lastSpacedGroup.push(p);
//                    });
//                    spacedGroups.push(toExpression(lastSpacedGroup));
//                    rule.value = toValue(spacedGroups);
//                }
//            });
//        }
  }


  /// func visitor.visit distribuitor
  Function visitFtn(Node node) {
    if (node is Comment)    return this.visitComment;
    if (node is Directive)  return this.visitDirective;
    if (node is Extend)     return this.visitExtend;
    if (node is Media)      return this.visitMedia;
    if (node is MixinDefinition) return this.visitMixinDefinition;
    if (node is Rule)       return this.visitRule;
    if (node is Ruleset)    return this.visitRuleset;

    return null;
  }

  /// funcOut visitor.visit distribuitor
  Function visitFtnOut(Node node) => null;
}