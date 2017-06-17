
part of less_plugin_clean_css.plugins.less;

///
/// cleanCSS optimizations
///
/// In the last phase marks node.cleanCss = true to avoid conflicts with eval().
///
class CleanCssVisitor extends VisitorBase {
  CleanCssContext cleancsscontext = new CleanCssContext();
  CleanCssOptions cleanCssOptions;
  bool            keepOneComment = false;
  bool            keepAllComments = false;
  LessOptions     lessOptions;
  Visitor         _visitor;

  CleanCssVisitor(this.cleanCssOptions) {
    isReplacing = true;
    lessOptions = new Environment().options;
    _visitor = new Visitor(this);

    if (cleanCssOptions.keepSpecialComments == '*')
        keepAllComments = true;
    if (cleanCssOptions.keepSpecialComments == '1')
        keepOneComment = true;

    cleancsscontext.compatibility = cleanCssOptions.compatibility;
    Output.separators[')'] = !cleancsscontext.compatibility.properties.spaceAfterClosingBrace;
  }

  ///
  @override
  Ruleset run(Ruleset root) => _visitor.visit(root);

  ///
  /// Optimize in call.genCSS
  /// Example: add(2, 3) => add(2,3)
  ///
  Call visitCall(Call callNode, VisitArgs visitArgs) {
    callNode.cleanCss = cleancsscontext;
    return callNode;
  }

  ///
  /// Optimize in color.toCSS
  ///
  /// Use color name if shorter, or #rgb if possible
  ///
  Color visitColor(Color colorNode, VisitArgs visitArgs) {
    colorNode.cleanCss = cleancsscontext;
    return colorNode;
  }

  ///
  /// Remove comments, except important '/*!'
  /// according to keepSpecialComments * - all, 1 - only keep first
  Comment visitComment(Comment commentNode, VisitArgs visitArgs) {
    if (commentNode.isImportant && (keepAllComments || keepOneComment)) {
      keepOneComment = false;
      return commentNode;
    }
    return null;
  }

  ///
  /// Remove units in 0
  ///
  Dimension visitDimension(Dimension dimensionNode, VisitArgs visitArgs) {
    dimensionNode.cleanCss = new CleanCssContext();
    if (dimensionNode.isUnit('px')) {
      dimensionNode.cleanCss.precision = cleanCssOptions.roundingPrecision;
    }

    return dimensionNode;
  }

  ///
  /// Remove empty block
  /// Remove value spaces. @supports ( box-shadow: 2px 2px 2px black ) or ( -moz-box-shadow: 2px 2px 2px black )
  ///
  Directive visitDirective(Directive directiveNode, VisitArgs visitArgs) {
    if (directiveNode.rules != null && directiveNode.rules.isEmpty)
        return null;

    if (directiveNode.value is Anonymous) {
      final Anonymous anonymous = directiveNode.value;
      if (anonymous.value is String)
          anonymous.value = removeSpaces(anonymous.value);
    }
    return directiveNode;
  }

  ///
  /// Remove spaces after ')' '/' url() 0 0 / content -> url()0 0 /content
  ///
  Expression visitExpression(Expression expressionNode, VisitArgs visitArgs) {
    expressionNode.cleanCss = cleancsscontext;
    return expressionNode;
  }

  ///
  /// Remove spaces around '!important'
  /// Change background: none; -> background 0 0;
  /// Change background: transparent; -> backaground 0 0;
  /// Change font-weight: normal -> font-weight:400
  /// Change font-weight: bold -> font-weight: 700
  /// Change outline: none -> outline: 0; (0px)
  ///
  Rule visitRule(Rule ruleNode, VisitArgs visitArgs) {
    Keyword keyword;
    Color color;

    ruleNode.cleanCss = cleancsscontext;

    // ' ! important'
    if (ruleNode.important.isNotEmpty)
        ruleNode.important = ruleNode.important.replaceAll(' ', '');

    if (ruleNode.name == 'background') {
      if (ruleNode.value is Keyword) {
        keyword = ruleNode.value;
        if (keyword.value == 'none')
            keyword.value = '0 0';
      }
      if (ruleNode.value is Color) {
        color = ruleNode.value;
        if (color.value != null && color.value == 'transparent')
            ruleNode.value = new Keyword('0 0');
      }
    }

    if (ruleNode.name == 'font') {
      if ((keyword = getFirstKeyword(ruleNode)) != null) {
        if (keyword.value == 'normal')
            keyword.value = '400';
        if (keyword.value == 'bold')
            keyword.value = '700';
      }
    }

    if (ruleNode.name == 'font-weight') {
      if (ruleNode.value is Keyword) {
        if (ruleNode.value.value == 'normal')
            ruleNode.value = new Dimension(400);
        if (ruleNode.value.value == 'bold')
            ruleNode.value = new Dimension(700);
      }
    }

    if (ruleNode.name == 'outline') {
      if (ruleNode.value is Keyword) {
        keyword = ruleNode.value;
        if (keyword.value == 'none')
            keyword.value = '0';
      }
    }

    return ruleNode;
  }

  ///
  /// Change selectors attribute from quoted
  /// - Example: `input[type="text"] -> input[type=text]``
  /// - Example: `([class*="lead"]) -> ([class*=lead])`
  ///
  Ruleset visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    Attribute       attribute;
    List<Element>   elements;
    Match           match;
    Quoted          quoted;
    List<Selector>  selectors;
    String          valueStr;

    //RegExp symbolRe = new RegExp(r'[^a-zA-Z0-9]');
    final RegExp attrRe = new RegExp(r'\[(.)*=\s*("[a-z0-9]+")\s*]',caseSensitive: false);

    rulesetNode.cleanCss = new CleanCssContext();
    rulesetNode.cleanCss.keepBreaks = cleanCssOptions.keepBreaks;

    if (!rulesetNode.root) {
      selectors = rulesetNode.selectors;
      if (selectors != null) {
        selectors.forEach((Selector selector) {
          elements = selector.elements;
          if (elements != null) {
            elements.forEach((Element element) {
              if (element.value is Attribute) {
                attribute = element.value;
                if (attribute.value is Quoted) {
                  quoted = attribute.value;
                  valueStr = quoted.value;
                  if (!hasSymbol(valueStr))
                      quoted.quote = ''; //remove for text/digits only: input[type="text"] -> input[type=text]
                }
              } else if (cleanCssOptions.advanced) {
                if (element.value is String) { // "([class*="lead"])"
                  valueStr = element.value;
                  if ((match = attrRe.firstMatch(valueStr)) != null)
                      element.value = removeQuotesAndSpace(match, valueStr, 2);
                }
              }
            });
          }
        });
      }
    }
    return rulesetNode;
  }

  ///
  /// Remove quotes in url function
  /// `url('...') -> url(...)`
  ///
  URL visitUrl(URL urlNode, VisitArgs visitArgs) {
    if (urlNode.value is Quoted)
        (urlNode.value as Quoted).quote = '';
    return urlNode;
  }

  ///
  /// Get the first Keyword in the tree after [node]
  ///
  Keyword getFirstKeyword(Node node) {
    if (node is Keyword)
        return node;
    if (node.value is List)
        return getFirstKeyword(node.value[0]);
    if (node.value is Node)
        return getFirstKeyword(node.value);
    return null;
  }

  ///
  /// Has ./$ ... characters
  ///
  bool hasSymbol(String value) {
    final RegExp symbolRe = new RegExp(r'[^a-zA-Z0-9]');

    return symbolRe.hasMatch(value);
  }

  ///
  /// Remove spaces and quotes. [indexQuoted] for quotes in the [match]
  /// [source] is the original string
  /// Example: "([class *= "lead"])" -> "([class*=lead])"
  ///
  String removeQuotesAndSpace(Match match, String source, int indexQuoted) {
    String quoted = match[indexQuoted];
    final int start = source.indexOf(quoted);

    final String prefix = source.substring(0, start).replaceAll(' ', '');
    final String suffix = source.substring(start + quoted.length).replaceAll(' ', '');

    final String newQuoted = quoted.substring(1, quoted.length-1); //remove quotes
    if (!hasSymbol(newQuoted))
        quoted = newQuoted;

    return '$prefix$quoted$suffix';
  }

  ///
  /// Remove ' ( ', ' ) ', ': ', \n '  '
  ///
  String removeSpaces(String value) {
    int     len;
    String  _value = value;

    do {
      len = _value.length;
      _value = _value.replaceAll('  ', ' ');
    } while (_value.length != len);

    _value = _value.replaceAll('\n', '');
    _value = _value.replaceAll(' (', '(');
    _value = _value.replaceAll('( ', '(');
    _value = _value.replaceAll(' )', ')');

    if (!cleancsscontext.compatibility.properties.spaceAfterClosingBrace)
        _value = _value.replaceAll(') ', ')');

    _value = _value.replaceAll(': ', ':');

    return _value;
  }

  @override
  Function visitFtn(Node node) {
    if (node is Call)
        return visitCall;
    if (node is Color)
        return visitColor;
    if (node is Comment)
        return visitComment;
    if (node is Dimension)
        return visitDimension;
    if (node is Directive)
        return visitDirective;
    if (node is Expression)
        return visitExpression;
    if (node is Rule)
        return visitRule;
    if (node is Ruleset)
        return visitRuleset;
    if (node is URL)
        return visitUrl;
    return null;
  }

  @override
  Function visitFtnOut(Node node) => null;
}
