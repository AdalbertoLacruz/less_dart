// source: lib/less/functions/list.js 3.9.0 20190711

part of functions.less;

///
class ListFunctions extends FunctionBase {
  ///
  // handle non-array values as an array of length 1
  // return null if index is invalid
  @defineMethodSkip
  List<Node> getItemsFromNode(Node node) =>
      (node.value is List) ? node.value : <Node>[node];

// 3.5.0.beta.6 20180704
//  var getItemsFromNode = function(node) {
//      // handle non-array values as an array of length 1
//      // return 'undefined' if index is invalid
//      var items = Array.isArray(node.value) ?
//          node.value : Array(node);
//
//      return items;
//  };

  ///
  /// Used in calc to wrap vars in a function call to cascade evaluate args first
  ///
  @DefineMethod(name: 'self')
  Node self(Node n) => n;

// 3.5.0.beta.6 20180704
//  _SELF: function(n) {
//      return n;
//  },

  ///
  /// Returns the value at a specified position in a list.
  ///
  /// Parameters:
  ///
  ///     [values] - list, a comma or space separated list of values.
  ///     [index] - an integer that specifies a position of a list element to return.
  ///
  /// Returns: a value at the specified position in a list.
  ///
  /// Example:
  ///
  ///     extract(8px dotted red, 2);
  ///     Output: dotted
  ///
  Node extract(Node values, Node index) {
    final int iIndex = (index.value as num).toInt() - 1; // (1-based index)
    try {
      return getItemsFromNode(values).elementAt(iIndex);
    } catch (e) {
      return null;
    }

// 3.5.0.beta.6 20180704
//  extract: function(values, index) {
//      index = index.value - 1; // (1-based index)
//
//      return getItemsFromNode(values)[index];
//  },
  }

  ///
  /// Returns the number of elements in a value list.
  ///
  /// Parameters:
  ///   list - a comma or space separated list of values.
  ///   Returns: an integer number of elements in a list
  /// Example: length(1px solid #0080ff);
  ///   Output: 3
  ///
  Dimension length(Node values) => Dimension(getItemsFromNode(values).length);

// 3.5.0.beta.6 20180704
//  length: function(values) {
//      return new Dimension(getItemsFromNode(values).length);
//  },

  ///
  /// Creates a Less list of incremental values.
  /// Modeled after Lodash's range function, also exists natively in PHP
  ///
  /// Parameters
  ///   start - (optional) The start value e.g. 1 or 1px
  ///   end - The end value e.g. 5px
  ///   step - (optional) The amount to increment by
  ///
  /// Examples:
  ///   range(4) => 1 2 3 4
  ///   range(10px, 30px, 10) => 10px 20px 30px
  ///
  Expression range(Dimension start, [Dimension end, Dimension step]) {
    num from;
    Dimension to;
    num stepValue = 1;
    final List<Node> list = <Node>[];

    if (end != null) {
      to = end;
      from = start.value;
      if (step != null) stepValue = step.value;
    } else {
      from = 1;
      to = start;
    }

    for (num i = from; i <= to.value; i += stepValue) {
      list.add(Dimension(i, to.unit));
    }

    return Expression(list);

// 3.8.2 20181129
//  range: function(start, end, step) {
//      var from, to, stepValue = 1, list = [];
//      if (end) {
//          to = end;
//          from = start.value;
//          if (step) {
//              stepValue = step.value;
//          }
//      }
//      else {
//          from = 1;
//          to = start;
//      }
//
//      for (var i = from; i <= to.value; i += stepValue) {
//          list.push(new Dimension(i, to.unit));
//      }
//
//      return new Expression(list);
//  },
  }

  ///
  /// Bind the evaluation of a ruleset to each member of a list.
  ///
  /// Parameters:
  ///   list
  ///   rs
  ///   Returns:
  /// Example:
  /// @selectors: blue, green, red;
  ///
  /// each(@selectors, {
  ///   .sel-@{value} {
  ///     a: b;
  ///   }
  /// });
  ///
  /// Output:
  ///   .sel-blue {
  ///    a: b;
  ///  }
  ///  .sel-green {
  ///    a: b;
  ///  }
  ///  .sel-red {
  ///    a: b;
  ///  }
  ///
  Node each(Node list, Node rs) {
    List<Node> iterator;
    List<Node> newRules;
    Ruleset ruleset;
    final List<Node> rules = <Node>[];

    if (list is DetachedRuleset) {
      iterator = list.ruleset.rules;
    } else if (list is Nodeset || list is Ruleset) {
      iterator = list.rules;
    } else if (list is! Quoted && list.value is List<Node>) {
      iterator = list.value;
    } else if (list is! Quoted && list.value is Node) {
      iterator = <Node>[list.value]; // Nodeset??
    } else {
      iterator = <Node>[list];
    }

    String valueName = '@value';
    String keyName = '@key';
    String indexName = '@index';

    if (rs is MixinDefinition && rs.params != null) {
      final MixinDefinition md = rs;
      valueName = md.params.isNotEmpty ? md.params[0].name : null;
      keyName = md.params.length > 1 ? md.params[1].name : null;
      indexName = md.params.length > 2 ? md.params[2].name : null;
      ruleset = Ruleset(null, md.rules);
    } else if (rs is DetachedRuleset) {
      ruleset = rs.ruleset;
    } else {
      return null; // Something goes bad - function not processed
    }

    for (int i = 0; i < iterator.length; i++) {
      final Node item = iterator[i];
      Node key;
      Node value;

      if (item is Declaration) {
        key = item.name is String ? Anonymous(item.name) : item.name.first;
        value = item.value;
      } else {
        key = Dimension(i + 1);
        value = item;
      }

      if (item is Comment) continue;

      newRules = List<Node>.from(ruleset.rules); // clone
      if (valueName != null) {
        newRules.add(Declaration(valueName, value,
            important: '',
            merge: '',
            index: index,
            currentFileInfo: currentFileInfo));
      }
      if (indexName != null) {
        newRules.add(Declaration(indexName, Dimension(i + 1),
            important: '',
            merge: '',
            index: index,
            currentFileInfo: currentFileInfo));
      }
      if (keyName != null) {
        newRules.add(Declaration(keyName, key,
            important: '',
            merge: '',
            index: index,
            currentFileInfo: currentFileInfo));
      }
      rules.add(Ruleset(<Selector>[
        Selector(<Element>[Element('', '&')])
      ], newRules));
    }

    return Ruleset(<Selector>[
      Selector(<Element>[Element('', '&')])
    ], rules,
            strictImports: ruleset.strictImports,
            visibilityInfo: ruleset.visibilityInfo())
        .eval(context);

// 3.9.0 20190711
//  each: function(list, rs) {
//      var rules = [], newRules, iterator;
//
//      if (list.value && !(list instanceof Quote)) {
//          if (Array.isArray(list.value)) {
//              iterator = list.value;
//          } else {
//              iterator = [list.value];
//          }
//      } else if (list.ruleset) {
//          iterator = list.ruleset.rules;
//      } else if (list.rules) {
//          iterator = list.rules;
//      } else if (Array.isArray(list)) {
//          iterator = list;
//      } else {
//          iterator = [list];
//      }
//
//      var valueName = '@value',
//          keyName = '@key',
//          indexName = '@index';
//
//      if (rs.params) {
//          valueName = rs.params[0] && rs.params[0].name;
//          keyName = rs.params[1] && rs.params[1].name;
//          indexName = rs.params[2] && rs.params[2].name;
//          rs = rs.rules;
//      } else {
//          rs = rs.ruleset;
//      }
//
//      for (var i = 0; i < iterator.length; i++) {
//          var key, value, item = iterator[i];
//          if (item instanceof Declaration) {
//              key = typeof item.name === 'string' ? item.name : item.name[0].value;
//              value = item.value;
//          } else {
//              key = new Dimension(i + 1);
//              value = item;
//          }
//
//          if (item instanceof Comment) {
//              continue;
//          }
//
//          newRules = rs.rules.slice(0);
//          if (valueName) {
//              newRules.push(new Declaration(valueName,
//                  value,
//                  false, false, this.index, this.currentFileInfo));
//          }
//          if (indexName) {
//              newRules.push(new Declaration(indexName,
//                  new Dimension(i + 1),
//                  false, false, this.index, this.currentFileInfo));
//          }
//          if (keyName) {
//              newRules.push(new Declaration(keyName,
//                  key,
//                  false, false, this.index, this.currentFileInfo));
//          }
//
//          rules.push(new Ruleset([ new(Selector)([ new Element("", '&') ]) ],
//              newRules,
//              rs.strictImports,
//              rs.visibilityInfo()
//          ));
//      }
//
//      return new Ruleset([ new(Selector)([ new Element("", '&') ]) ],
//              rules,
//              rs.strictImports,
//              rs.visibilityInfo()
//          ).eval(this.context);
//
//  }
  }
}
