//source: less/to-css-visitor.js 2.8.0 20170601

part of visitor.less;

///
class CSSVisitorUtils extends VisitorBase {

  Contexts  _context;

  Visitor   _visitor;

  ///
  CSSVisitorUtils(this._context) {
    _visitor = new Visitor(this);

//2.5.3 20151120
// var CSSVisitorUtils = function(context) {
//     this._visitor = new Visitor(this);
//     this._context = context;
// };
  }

  ///
  bool containsSilentNonBlockedChild(List<Node> bodyRules) {
    if (bodyRules == null) return false;

    for (int r = 0; r < bodyRules.length; r++) {
      final Node rule = bodyRules[r];
      if ((rule is SilentNode) && (rule as SilentNode).isSilent(_context) && !rule.blocksVisibility()) {
        //the atRule contains something that was referenced (likely by extend)
        //therefore it needs to be shown in output too
        return true;
      }
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
    if (owner?.rules != null ) {
      owner.rules.retainWhere((Node thing) => thing.isVisible());
    }

//3.0.0 20170601
// keepOnlyVisibleChilds: function(owner) {
//   if (owner && owner.rules) {
//     owner.rules = owner.rules.filter(function(thing) {
//     return thing.isVisible();
//     });
//   }
// },
  }

  ///
  /// if [owner] rules is empty returns true
  ///
  bool isEmpty(Node owner) => (owner?.rules != null)
      ? owner.rules.isEmpty
      : true;

//3.0.0 20170601
// isEmpty: function(owner) {
//   return (owner && owner.rules)
//       ? (owner.rules.length === 0) : true;
// },


  ///
  /// true if [rulesetNode] has paths
  ///
  bool hasVisibleSelector(Ruleset rulesetNode) => (rulesetNode?.paths != null)
      ? rulesetNode.paths.isNotEmpty
      : false;

//3.0.0 20170601
// hasVisibleSelector: function(rulesetNode) {
//   return (rulesetNode && rulesetNode.paths)
//       ? (rulesetNode.paths.length > 0) : false;
// },

  ///
  Node resolveVisibility(Node node, List<Node> originalRules) {
    if (!node.blocksVisibility()) {
      if (isEmpty(node) && !containsSilentNonBlockedChild(originalRules)) {
        return null;
      }
      return node;
    }

    //TODO
    // final Node compiledRulesBody = node.rules[0];
    final Node compiledRulesBody = (node.rules != null && node.rules.isNotEmpty)
        ? node.rules[0]
        : null;
    keepOnlyVisibleChilds(compiledRulesBody);

    if (isEmpty(compiledRulesBody)) return null;

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
    if (rulesetNode.firstRoot) return true;
    if (isEmpty(rulesetNode)) return false;
    if (!rulesetNode.root && !hasVisibleSelector(rulesetNode)) return false;

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
