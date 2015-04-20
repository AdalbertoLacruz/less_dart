
part of less_plugin_clean_css.plugins.less;

///
/// cleanCSS optimizations
///
/// In the last phase marks node.cleanCss = true to avoid conflicts with eval().
///
class CleanCssVisitor extends VisitorBase {
  Visitor _visitor;
  bool isReplacing = true;
  CleanCssOptions cleanCssOptions;
  LessOptions lessOptions;

  CleanCssVisitor(this.cleanCssOptions) {
    lessOptions = new Environment().options;
    _visitor = new Visitor(this);
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
  /// Remove units in 0
  ///
  Dimension visitDimension(Dimension dimensionNode, VisitArgs visitArgs) {
    dimensionNode.cleanCss = true;
    return dimensionNode;
  }

  ///
  /// Remove empty block
  ///
  Directive visitDirective (Directive directiveNode, VisitArgs visitArgs) {
    if (directiveNode.rules != null && directiveNode.rules.isEmpty) return null;
    return directiveNode;
  }

  ///
  /// Remove spaces after ')' url() 0 0 -> url()0 0
  ///
  Expression visitExpression (Expression expressionNode, VisitArgs visitArgs) {
    expressionNode.cleanCss = true;
    return expressionNode;
  }

  ///
  /// Change font-weight:  normal -> 400, bold -> 700
  ///
  Rule visitRule(Rule ruleNode, VisitArgs visitArgs) {
    if (ruleNode.name == 'font-weight') {
      if (ruleNode.value is Keyword) {
        if (ruleNode.value.value == 'normal') ruleNode.value = new Dimension(400);
        if (ruleNode.value.value == 'bold') ruleNode.value = new Dimension(700);
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

  Function visitFtn(Node node) {
    if (node is Call)        return visitCall;
    if (node is Color)       return visitColor;
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