//source: less/to-css-visitor.js 2.8.0 20160702

part of visitor.less;

///
class CSSVisitorUtils extends VisitorBase {

  Contexts  _context;

  Visitor   _visitor;

  ///
  CSSVisitorUtils(Contexts this._context) {
    _visitor = new Visitor(this);

//2.5.3 20151120
// var CSSVisitorUtils = function(context) {
//     this._visitor = new Visitor(this);
//     this._context = context;
// };
  }

  ///
  bool containsSilentNonBlockedChild(List<Node> bodyRules) {
    if (bodyRules == null)
        return false;

    for (int r = 0; r < bodyRules.length; r++) {
      final Node rule = bodyRules[r];
      if ((rule is SilentNode) && (rule as SilentNode).isSilent(_context) && !rule.blocksVisibility())
          //the atRule contains something that was referenced (likely by extend)
          //therefore it needs to be shown in output too
          return true;
    }

    return false;

//2.8.0 20160702
// containsSilentNonBlockedChild: function(bodyRules) {
//     var rule;
//     if (bodyRules == null) {
//         return false;
//     }
//     for (var r = 0; r < bodyRules.length; r++) {
//         rule = bodyRules[r];
//         if (rule.isSilent && rule.isSilent(this._context) && !rule.blocksVisibility()) {
//             //the atrule contains something that was referenced (likely by extend)
//             //therefore it needs to be shown in output too
//             return true;
//         }
//     }
//     return false;
// },
  }

  ///
  void keepOnlyVisibleChilds(Node owner) {
    if (owner?.rules == null )
        return;
    owner.rules.retainWhere((Node thing) => thing.isVisible());

//2.5.3 20151120
// keepOnlyVisibleChilds: function(owner) {
//     if (owner == null || owner.rules == null) {
//         return ;
//     }
//
//     owner.rules = owner.rules.filter(function(thing) {
//             return thing.isVisible();
//         }
//     );
// },
  }

  ///
  /// if [owner] rules is empty returns true
  ///
  bool isEmpty(Node owner) {
    if (owner?.rules == null)
        return true;
    return owner.rules.isEmpty;

//2.5.3 20151120
// isEmpty: function(owner) {
//     if (owner == null || owner.rules == null) {
//         return true;
//     }
//     return owner.rules.length === 0;
// },
  }

  ///
  /// true if [rulesetNode] has paths
  ///
  bool hasVisibleSelector(Ruleset rulesetNode) {
    if (rulesetNode?.paths == null)
        return false;
    return rulesetNode.paths.isNotEmpty;

//2.5.3 20151120
// hasVisibleSelector: function(rulesetNode) {
//     if (rulesetNode == null || rulesetNode.paths == null) {
//         return false;
//     }
//     return rulesetNode.paths.length > 0;
// },
  }

  ///
  Node resolveVisibility(Node node, List<Node> originalRules) {
    if (!node.blocksVisibility()) {
      if (isEmpty(node) && !containsSilentNonBlockedChild(originalRules))
          return null;
      return node;
    }

    //TODO
    // final Node compiledRulesBody = node.rules[0];
    final Node compiledRulesBody = (node.rules != null && node.rules.isNotEmpty)
        ? node.rules[0]
        : null;
    keepOnlyVisibleChilds(compiledRulesBody);

    if (isEmpty(compiledRulesBody))
        return null;

    return node
      ..ensureVisibility()
      ..removeVisibilityBlock();

//2.5.3 20151120
// resolveVisibility: function (node, originalRules) {
//     if (!node.blocksVisibility()) {
//         if (this.isEmpty(node) && !this.containsSilentNonBlockedChild(originalRules)) {
//             return ;
//         }
//
//         return node;
//     }
//
//     var compiledRulesBody = node.rules[0];
//     this.keepOnlyVisibleChilds(compiledRulesBody);
//
//     if (this.isEmpty(compiledRulesBody)) {
//         return ;
//     }
//
//     node.ensureVisibility();
//     node.removeVisibilityBlock();
//
//     return node;
// },
  }

  ///
  bool isVisibleRuleset(Ruleset rulesetNode) {
    if (rulesetNode.firstRoot)
        return true;
    if (isEmpty(rulesetNode))
        return false;
    if (!rulesetNode.root && !hasVisibleSelector(rulesetNode))
        return false;

    return true;

//2.5.3 20151120
// isVisibleRuleset: function(rulesetNode) {
//     if (rulesetNode.firstRoot) {
//         return true;
//     }
//
//     if (this.isEmpty(rulesetNode)) {
//         return false;
//     }
//
//     if (!rulesetNode.root && !this.hasVisibleSelector(rulesetNode)) {
//         return false;
//     }
//
//     return true;
// }
  }
}
