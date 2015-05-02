
part of less_plugin_clean_css.plugins.less;

///
/// cleanCSS optimizations
///
/// In the last phase marks node.cleanCss = true to avoid conflicts with eval().
///
class CleanCssVisitor extends VisitorBase {
  CleanCssOptions cleanCssOptions;
  bool isReplacing = true;
  bool keepOneComment = false;
  bool keepAllComments = false;
  LessOptions lessOptions;
  Visitor _visitor;

  CleanCssVisitor(this.cleanCssOptions) {
    lessOptions = new Environment().options;
    _visitor = new Visitor(this);
    if (cleanCssOptions.keepSpecialComments == '*') keepAllComments = true;
    if (cleanCssOptions.keepSpecialComments == '1') keepOneComment = true;
  }

  ///
  Ruleset run(Ruleset root) {
    return _visitor.visit(root);
  }

  ///
  /// Optimize in call.genCSS
  /// Example: add(2, 3) => add(2,3)
  ///
  Call visitCall(Call callNode, VisitArgs visitArgs) {
    callNode.cleanCss = true;
    return callNode;
  }

  ///
  /// Optimize in color.toCSS
  ///
  /// Use color name if shorter, or #rgb if possible
  ///
  Color visitColor(Color colorNode, VisitArgs visitArgs) {
    colorNode.cleanCss = true;
    return colorNode;
  }

  ///
  /// Remove comments, except important '/*!'
  /// according to keepSpecialComments * - all, 1 - only keep first
  Comment visitComment(Comment commentNode, VisitArgs visitArgs) {
    if(commentNode.isImportant && (keepAllComments || keepOneComment)) {
      keepOneComment = false;
      return commentNode;
    }
    return null;
  }

  ///
  /// Remove units in 0
  ///
  Dimension visitDimension(Dimension dimensionNode, VisitArgs visitArgs) {
    dimensionNode.cleanCss = true;
    if (dimensionNode.isUnit('px')) {
      dimensionNode.precision = cleanCssOptions.roundingPrecision;
    }

    return dimensionNode;
  }

  ///
  /// Remove empty block
  /// Remove value spaces. @supports ( box-shadow: 2px 2px 2px black ) or ( -moz-box-shadow: 2px 2px 2px black )
  ///
  Directive visitDirective (Directive directiveNode, VisitArgs visitArgs) {
    if (directiveNode.rules != null && directiveNode.rules.isEmpty) return null;

    if (directiveNode.value is Anonymous) {
      Anonymous anonymous = directiveNode.value;
      if (anonymous.value is String) {
        anonymous.value = removeSpaces(anonymous.value);
      }
    }
    return directiveNode;
  }

  ///
  /// Remove spaces after ')' '/' url() 0 0 / content -> url()0 0 /content
  ///
  Expression visitExpression (Expression expressionNode, VisitArgs visitArgs) {
    expressionNode.cleanCss = true;
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

    ruleNode.cleanCss = true;

    // ' ! important'
    if (ruleNode.important.isNotEmpty) {
      ruleNode.important = ruleNode.important.replaceAll(' ', '');
    }

    if (ruleNode.name == 'background') {
      if (ruleNode.value is Keyword) {
        keyword = ruleNode.value;
        if (keyword.value == 'none') keyword.value = '0 0';
      }
      if (ruleNode.value is Color) {
        color = ruleNode.value;
        if (color.value != null && color.value == 'transparent') ruleNode.value = new Keyword('0 0');
      }
    }

    if (ruleNode.name == 'font') {
      if ((keyword = getFirstKeyword(ruleNode)) != null) {
        if (keyword.value == 'normal') keyword.value = '400';
        if (keyword.value == 'bold') keyword.value = '700';
      }
    }

    if (ruleNode.name == 'font-weight') {
      if (ruleNode.value is Keyword) {
        if (ruleNode.value.value == 'normal') ruleNode.value = new Dimension(400);
        if (ruleNode.value.value == 'bold') ruleNode.value = new Dimension(700);
      }
    }

    if (ruleNode.name == 'outline') {
      if (ruleNode.value is Keyword) {
        keyword = ruleNode.value;
        if (keyword.value == 'none') keyword.value = '0';
      }
    }

    return ruleNode;
  }

  ///
  /// Change selectors attribute from quoted
  /// - Example: input[type="text"] -> input[type=text]
  /// - Example: ([class*="lead"]) -> ([class*=lead])
  ///
  Ruleset visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    List<Element> elements;
    Attribute attribute;
    Match match;
    List<Selector> selectors;
    //RegExp symbolRe = new RegExp(r'[^a-zA-Z0-9]');
    RegExp attrRe = new RegExp(r'\[(.)*=\s*("[a-z0-9]+")\s*]',caseSensitive: false);
    Quoted quoted;
    String valueStr;

    rulesetNode.cleanCss = true;
    rulesetNode.keepBreaks = cleanCssOptions.keepBreaks;

    if (!rulesetNode.root) {
      selectors = rulesetNode.selectors;
      if (selectors != null) {
        selectors.forEach((selector){
          elements = selector.elements;
          if (elements != null) {
            elements.forEach((element){
              if (element.value is Attribute) {
                attribute = element.value;
                if (attribute.value is Quoted) {
                  quoted = attribute.value;
                  valueStr = quoted.value;
                  if (!hasSymbol(valueStr)) {
                    quoted.quote = ''; //remove for text/digits only: input[type="text"] -> input[type=text]
                  }
                }
              } else if (cleanCssOptions.advanced) {
                if (element.value is String) { // "([class*="lead"])"
                  valueStr = element.value;
                  if ((match = attrRe.firstMatch(valueStr)) != null) {
                    element.value = removeQuotesAndSpace(match, valueStr, 2);
                  }
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
  /// url('...') -> url(...)
  ///
  URL visitUrl(URL urlNode, VisitArgs visitArgs) {
    if (urlNode.value is Quoted) {
      (urlNode.value as Quoted).quote = '';
    }
    return urlNode;
  }

  ///
  /// Get the first Keyword in the tree after [node]
  ///
  Keyword getFirstKeyword(Node node) {
    if (node is Keyword) return node;
    if (node.value is List) return getFirstKeyword(node.value[0]);
    if (node.value is Node) return getFirstKeyword(node.value);
    return null;
  }

  /// Has ./$ ... characters
  bool hasSymbol(String value) {
    RegExp symbolRe = new RegExp(r'[^a-zA-Z0-9]');
    return symbolRe.hasMatch(value);
  }

  ///
  /// Remove spaces and quotes. [indexQuoted] for quotes in the [match]
  /// [source] is the original string
  /// Example: "([class *= "lead"])" -> "([class*=lead])"
  ///
  String removeQuotesAndSpace(Match match, String source, int indexQuoted) {
    String quoted = match[indexQuoted];
    String newQuoted;
    int start = source.indexOf(quoted);
    String prefix = source.substring(0, start);
    String suffix = source.substring(start + quoted.length);

    newQuoted = quoted.substring(1, quoted.length-1); //remove quotes
    if (!hasSymbol(newQuoted)) {
      quoted = newQuoted;
    }
    prefix = prefix.replaceAll(' ', '');
    suffix = suffix.replaceAll(' ', '');
    return prefix + quoted + suffix;
  }

  ///
  /// Remove ' ( ', ' ) ', ': ', \n '  '
  ///
  String removeSpaces(String value) {
    int len;
    do {
      len = value.length;
      value = value.replaceAll('  ', ' ');
    } while (value.length != len);

    value = value.replaceAll('\n', '');
    value = value.replaceAll(' (', '(');
    value = value.replaceAll('( ', '(');
    value = value.replaceAll(' )', ')');
    value = value.replaceAll(') ', ')');
    value = value.replaceAll(': ', ':');
    return value;
  }

  Function visitFtn(Node node) {
    if (node is Call)        return visitCall;
    if (node is Color)       return visitColor;
    if (node is Comment)     return visitComment;
    if (node is Dimension)   return visitDimension;
    if (node is Directive)   return visitDirective;
    if (node is Expression)  return visitExpression;
    if (node is Rule)        return visitRule;
    if (node is Ruleset)     return visitRuleset;
    if (node is URL)         return visitUrl;
    return null;
  }

  Function visitFtnOut(Node node) => null;
}