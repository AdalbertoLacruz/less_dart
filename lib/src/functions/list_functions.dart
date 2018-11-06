// source: lib/less/functions/list.js 3.5.0.beta.6 20180704

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
    //return MoreList.elementAt(getItemsFromNode(values), iIndex); //cover out of range
    try {
      return getItemsFromNode(values).elementAt(iIndex);
    } catch (e) {
      // } on RangeError catch(_) { // Alternative
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
  Dimension length(Node values) =>
      new Dimension(getItemsFromNode(values).length);

// 3.5.0.beta.6 20180704
//  length: function(values) {
//      return new Dimension(getItemsFromNode(values).length);
//  },

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
    int              i = 0;
    List<Node>       iterator;
    List<Node>       newRules;
    Ruleset          ruleset;
    final List<Node> rules = <Node>[];

    if (list is DetachedRuleset) {
      iterator = list.ruleset.rules;
    } else if (list is Nodeset) {
      iterator = list.rules;
    } else if (list.value is List<Node>) {
      iterator = list.value;
    } else if (list.value is Node) {
      iterator = <Node>[list.value]; // ??
    } else {
      iterator = <Node>[list];
    }

    String valueName = '@value';
    String keyName = '@key';
    String indexName = '@index';

    if (rs is MixinDefinition && rs.params != null) { // todo debug
      final MixinDefinition md = rs;
      valueName = md.params.isNotEmpty ? md.params[0].name : null;
      keyName = md.params.length > 1 ? md.params[1].name : null;
      indexName = md.params.length > 2 ? md.params[2].name : null;
//      _rs = _rs.rules;
//      ruleset = rs;
      return null;  // todo ruleset = ...
    } else if (rs is DetachedRuleset) {
      ruleset = rs.ruleset;
    } else {
      return null; // Something goes bad
    }

    iterator.forEach((Node item) { // item is Node?
      i = i + 1;
      Node key;
      Node value;

      if (item is Declaration) {
        key = item.name is String ? new Anonymous(item.name) : item.name.first;
        value = item.value;
      } else {
        key = new Dimension(i);
        value = item;
      }

      newRules = new List<Node>.from(ruleset.rules); // clone
      if (valueName != null) {
        newRules.add(new Declaration(valueName, value,
          important: '', merge: '', index: index, currentFileInfo: currentFileInfo));
      }
      if (indexName != null) {
        newRules.add(new Declaration(indexName, new Dimension(i),
            important: '', merge: '', index: index, currentFileInfo: currentFileInfo));
      }
      if (keyName != null) {
        newRules.add(new Declaration(keyName, key,
            important: '', merge: '', index: index, currentFileInfo: currentFileInfo));
      }
      rules.add(new Ruleset(<Selector>[new Selector(<Element>[new Element('', '&')])],
          newRules));
    });

    return new Ruleset(<Selector>[new Selector(<Element>[new Element('', '&')])],
      rules, strictImports: ruleset.strictImports, visibilityInfo: ruleset.visibilityInfo())
      .eval(context);

// 20180708
//  each: function(list, rs) {
//      var i = 0, rules = [], newRules, iterator;
//
//      if (list.value) {
//          if (Array.isArray(list.value)) {
//              iterator = list.value;
//          } else {
//              iterator = [list.value];
//          }
//      } else if (list.ruleset) {
//          iterator = list.ruleset.rules;
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
//      iterator.forEach(function(item) {
//          i = i + 1;
//          var key, value;
//          if (item instanceof Declaration) {
//              key = typeof item.name === 'string' ? item.name : item.name[0].value;
//              value = item.value;
//          } else {
//              key = new Dimension(i);
//              value = item;
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
//                  new Dimension(i),
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
//      });
//
//      return new Ruleset([ new(Selector)([ new Element("", '&') ]) ],
//              rules,
//              rs.strictImports,
//              rs.visibilityInfo()
//          ).eval(this.context);
//
//  }

// 3.5.0.beta.6 20180704
//  each: function(list, ruleset) {
//      var i = 0, rules = [], rs, newRules;
//
//      rs = ruleset.ruleset;
//
//      list.value.forEach(function(item) {
//          i = i + 1;
//          newRules = rs.rules.slice(0);
//          newRules.push(new Rule(ruleset && vars.value[1] ? '@' + vars.value[1].value : '@item',
//              item,
//              false, false, this.index, this.currentFileInfo));
//          newRules.push(new Rule(ruleset && vars.value[0] ? '@' + vars.value[0].value : '@index',
//              new Dimension(i),
//              false, false, this.index, this.currentFileInfo));
//
//          rules.push(new Ruleset([ new(Selector)([ new Element("", '&') ]) ],
//              newRules,
//              rs.strictImports,
//              rs.visibilityInfo()
//          ));
//      });
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
