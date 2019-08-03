part of tree.less;

///
class TreeApi {
  ///
  /// Assignments are argument entities for calls.
  /// They are present in ie filter properties as shown below.
  ///
  ///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
  ///
  Assignment assignment(String key, String value) => Assignment(key, value);

  ///
  AtRule atRule(String name, String value) => AtRule(name, value);

  ///
  Attribute attribute(String key, String op, String value) =>
      Attribute(key, op, value);

  ///
  // TODO args 'arg1, arg2, ...' => List<Node>
  Call call(String name, [String args]) => Call(name, null);

  ///
  Color color(List<num> rgb) => Color.fromList(rgb);

  ///
  Combinator combinator(String value) => Combinator(value);

  ///
  Condition condition(String condition, Node lValue, Node rValue) =>
      Condition(condition, lValue, rValue);

  ///
  Declaration declaration(String name, String value) =>
      Declaration(name, value);

  ///
  /// Creates a Ruleset with no css output
  ///
  DetachedRuleset detachedRuleset(Ruleset ruleset) => DetachedRuleset(ruleset);

  ///
  Dimension dimension(dynamic value, String unit) => Dimension(value, unit);

  ///
  Element element(String combinator, String value) =>
      Element(combinator, value);

  ///
  Expression expression(List<dynamic> value) => Expression(toListNode(value));

  ///
  Keyword keyword(String value) => Keyword(value);

  ///
  Operation operation(String op, List<dynamic> operands) =>
      Operation(op, toListNode(operands));

  ///
  Quoted quoted(String str, String content) => Quoted(str, content);

  ///
  /// ex.: ruleset('h1 div, h2 div', [declaration('prop', 'value')]);
  ///
  Ruleset ruleset(String selectors, List<Node> rules) {
    if (selectors?.isNotEmpty ?? false) {
      final String _selectors = '$selectors {}';
      final Ruleset result = ParseNode(_selectors, 0, null).ruleset();
      return Ruleset(result.selectors, rules);
    } else {
      return Ruleset(null, rules);
    }
  }

  ///
  Selector selector(String elements) => Selector(elements);

  ///
  URL url(dynamic value) => URL(toNode(value));

  ///
  /// Returns a Value node
  /// [value] is Node | num | String
  ///
  Value value(dynamic value) {
    List<Node> result = <Node>[];
    if (value is List) {
      result = toListNode(value);
    } else {
      result.add(toNode(value));
    }
    return Value(result);
  }

  ///
  /// Returns Node from Node | String | num
  ///
  Node toNode(dynamic value) => value is Node
      ? value
      : value is num ? Dimension(value) : Anonymous(value);

  ///
  /// returns List<Node> from a List with Node|String|num elements
  ///
  List<Node> toListNode(List<dynamic> value) {
    final List<Node> result = <Node>[];
    value.forEach((dynamic v) {
      result.add(toNode(v));
    });
    return result;
  }
}
