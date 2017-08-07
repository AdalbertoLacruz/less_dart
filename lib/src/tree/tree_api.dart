part of tree.less;

///
class TreeApi {
  ///
  Alpha alpha(num value) => new Alpha(value);

  ///
  /// Assignments are argument entities for calls.
  /// They are present in ie filter properties as shown below.
  ///
  ///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
  ///
  Assignment assignment(String key, String value) => new Assignment(key, value);

  ///
  AtRule atRule(String name, String value) => new AtRule(name, value);

  ///
  Attribute attribute(String key, String op, String value) =>
      new Attribute(key, op, value);

  ///
  // TODO args 'arg1, arg2, ...' => List<Node>
  Call call(String name, [String args]) => new Call(name, null);

  ///
  Color color(List<num> rgb) => new Color(rgb);

  ///
  Combinator combinator(String value) => new Combinator(value);

  ///
  Condition condition(String condition, Node lValue, Node rValue) =>
      new Condition(condition, lValue, rValue);

  ///
  Declaration declaration(String name, String value) =>
      new Declaration(name, value);

  ///
  /// Creates a Ruleset with no css output
  ///
  DetachedRuleset detachedRuleset(Ruleset ruleset) => new DetachedRuleset(ruleset);

  ///
  Dimension dimension(dynamic value, String unit) => new Dimension(value, unit);

  ///
  Element element(String combinator, String value) => new Element(combinator, value);

  ///
  Expression expression(List<dynamic> value) => new Expression(toListNode(value));

  ///
  Keyword keyword(String value) => new Keyword(value);

  ///
  Operation operation(String op, List<dynamic> operands) => new Operation(op, toListNode(operands));

  ///
  Quoted quoted(String str, String content) => new Quoted(str, content);

  ///
  /// ex.: ruleset('h1 div, h2 div', [declaration('prop', 'value')]);
  ///
  Ruleset ruleset(String selectors, List<Node> rules ) {
    if (selectors?.isNotEmpty ?? false) {
      final String _selectors = '$selectors {}';
      final Ruleset result = new ParseNode(_selectors, 0, null).ruleset();
      return new Ruleset(result.selectors, rules);
    } else {
      return new Ruleset(null, rules);
    }
  }

  ///
  Selector selector(String elements) => new Selector(elements);

  ///
  URL url(dynamic value) => new URL(toNode(value));

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
    return new Value(result);
  }

  ///
  /// Returns Node from Node | String | num
  ///
  Node toNode(dynamic value) => value is Node
      ? value
      : value is num
          ? new Dimension(value)
          : new Anonymous(value);

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
