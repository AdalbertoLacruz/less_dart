//source: less/to-css-visitor.js 3.0.0 201670531

part of tree.less;

///
/// Implements the mergeRules method used to group rules in the same declaration
///
class MergeRulesMixin {
  ///
  /// Mix rules according:
  ///     transform+: rotate(90deg), skew(30deg) !important;
  ///     transform+: scale(2,4);
  /// to
  ///     transform: rotate(90deg), skew(30deg), scale(2,4) !important;
  ///
  /// rules is modified by mergeRules, with the merged result
  ///
  void mergeRules(List<Node> rules) {
    if (rules == null) return;

    final Map<String, List<Declaration>>   groups = <String, List<Declaration>>{};
    final List<List<Declaration>>          groupsArr = <List<Declaration>>[];

    for (int i = 0; i < rules.length; i++) {
      final Node rule = rules[i];

      // group rules and remove these to be merged
      // rule is not only Declaration
      if (rule is Declaration && (rule.merge?.isNotEmpty ?? false)) {
        final String key = rule.name;
        final List<Declaration> group = groups.putIfAbsent(key, () => <Declaration>[]);
        group.isNotEmpty ? rules.removeAt(i--) : groupsArr.add(group);
        group.add(rule);
      }
    }

    groupsArr.forEach((List<Declaration> group) {
      if (group.isNotEmpty) {
        final Declaration result = group.first;
        List<Node> space = <Node>[];
        final List<Expression> comma = <Expression>[new Expression(space)];
        group.forEach((Declaration rule) {
          if ((rule.merge == '+') && (space.isNotEmpty)) {
            space = <Node>[];
            comma.add(new Expression(space));
          }
          space.add(rule.value); //rule.value is any Node, so space is List<Node>
          result.important = result.important.isNotEmpty ? result.important : rule.important;
        });
        result.value = new Value(comma);
      }
    });

//3.0.0 20170531
// _mergeRules: function(rules) {
//     if (!rules) {
//         return;
//     }
//
//     var groups    = {},
//         groupsArr = [];
//
//     for (var i = 0; i < rules.length; i++) {
//         var rule = rules[i];
//         if (rule.merge) {
//             var key = rule.name;
//             groups[key] ? rules.splice(i--, 1) :
//                 groupsArr.push(groups[key] = []);
//             groups[key].push(rule);
//         }
//     }
//
//     groupsArr.forEach(function(group) {
//         if (group.length > 0) {
//             var result = group[0],
//                 space  = [],
//                 comma  = [new tree.Expression(space)];
//             group.forEach(function(rule) {
//                 if ((rule.merge === '+') && (space.length > 0)) {
//                     comma.push(new tree.Expression(space = []));
//                 }
//                 space.push(rule.value);
//                 result.important = result.important || rule.important;
//             });
//             result.value = new tree.Value(comma);
//         }
//     });
// },
  }
}
