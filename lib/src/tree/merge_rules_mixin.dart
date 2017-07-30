//source: less/to-css-visitor.js 3.0.0 20160714

part of tree.less;

///
class MergeRulesMixin {
  ///
  void mergeRules(List<Node> rules) {
    if (rules == null)
        return;

    final Map<String, List<Declaration>> groups = <String, List<Declaration>>{};

    for (int i = 0; i < rules.length; i++) {
      final Node rule = rules[i];

      if (rule is Declaration && (rule.merge?.isNotEmpty ?? false)) {
        final String key = <String>[
          rule.name,
          isNotEmpty(rule.important) ? '!' : ''
        ].join(','); //important == '!' or ''

        if (!groups.containsKey(key)) {
          groups[key] = <Declaration>[];
        } else {
          rules.removeAt(i--); // ??
        }
        groups[key].add(rule);
      }
    }

    groups.forEach((String k, List<Declaration> parts) {
      Expression toExpression(List<Declaration> values) =>
          new Expression(values.map((Declaration p) => p.value).toList());

      Value toValue(List<Expression> values) =>
          new Value(values.map((Expression p) => p).toList());

      if (parts.length > 1) {
        List<Declaration> lastSpacedGroup = <Declaration>[];
        final Declaration rule = parts[0];
        final List<Expression> spacedGroups = <Expression>[];

        parts.forEach((Declaration p) {
          if (p.merge == '+') {
            if (lastSpacedGroup.isNotEmpty)
                spacedGroups.add(toExpression(lastSpacedGroup));
            lastSpacedGroup = <Declaration>[];
          }
          lastSpacedGroup.add(p);
        });
        spacedGroups.add(toExpression(lastSpacedGroup));
        rule.value = toValue(spacedGroups);
      }
    });

//2.8.0 20160702
// _mergeRules: function (rules) {
//     if (!rules) { return; }
//
//     var groups = {},
//         parts,
//         rule,
//         key;
//
//     for (var i = 0; i < rules.length; i++) {
//         rule = rules[i];
//
//         if ((rule instanceof tree.Declaration) && rule.merge) {
//             key = [rule.name,
//                 rule.important ? "!" : ""].join(",");
//
//             if (!groups[key]) {
//                 groups[key] = [];
//             } else {
//                 rules.splice(i--, 1);
//             }
//
//             groups[key].push(rule);
//         }
//     }
//
//     Object.keys(groups).map(function (k) {
//
//         function toExpression(values) {
//             return new (tree.Expression)(values.map(function (p) {
//                 return p.value;
//             }));
//         }
//
//         function toValue(values) {
//             return new (tree.Value)(values.map(function (p) {
//                 return p;
//             }));
//         }
//
//         parts = groups[k];
//
//         if (parts.length > 1) {
//             rule = parts[0];
//             var spacedGroups = [];
//             var lastSpacedGroup = [];
//             parts.map(function (p) {
//                 if (p.merge === "+") {
//                     if (lastSpacedGroup.length > 0) {
//                         spacedGroups.push(toExpression(lastSpacedGroup));
//                     }
//                     lastSpacedGroup = [];
//                 }
//                 lastSpacedGroup.push(p);
//             });
//             spacedGroups.push(toExpression(lastSpacedGroup));
//             rule.value = toValue(spacedGroups);
//         }
//     });
// },
  }
}
