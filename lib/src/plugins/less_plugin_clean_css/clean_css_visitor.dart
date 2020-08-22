part of less_plugin_clean_css.plugins.less;

///
/// cleanCSS optimizations
///
/// In the last phase marks node.cleanCss = true to avoid conflicts with eval().
///
class CleanCssVisitor extends VisitorBase {
  ///
  CleanCssContext cleancsscontext = CleanCssContext();

  ///
  CleanCssOptions cleanCssOptions;

  ///
  bool keepOneComment = false;

  ///
  bool keepAllComments = false;

  ///
  LessOptions lessOptions;

  ///
  Visitor _visitor;

  ///
  CleanCssVisitor(this.cleanCssOptions) {
    isReplacing = true;
    lessOptions = Environment().options;
    _visitor = Visitor(this);

    if (cleanCssOptions.keepSpecialComments == '*') {
      keepAllComments = true;
    }
    if (cleanCssOptions.keepSpecialComments == '1') {
      keepOneComment = true;
    }

    cleancsscontext.compatibility = cleanCssOptions.compatibility;
    Output.separators[')'] =
        !cleancsscontext.compatibility.properties.spaceAfterClosingBrace;
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
    dimensionNode.cleanCss = CleanCssContext();
    if (dimensionNode.isUnit('px')) {
      dimensionNode.cleanCss.precision = cleanCssOptions.roundingPrecision;
    }

    return dimensionNode;
  }

  ///
  /// Remove empty block
  /// Remove value spaces. @supports ( box-shadow: 2px 2px 2px black ) or ( -moz-box-shadow: 2px 2px 2px black )
  ///
  AtRule visitAtRule(AtRule atRuleNode, VisitArgs visitArgs) {
    if (atRuleNode.rules != null && atRuleNode.rules.isEmpty) return null;

    if (atRuleNode.value is Anonymous) {
      final Anonymous anonymous = atRuleNode.value;
      if (anonymous.value is String) {
        anonymous.value = removeSpaces(anonymous.value);
      }
    }
    return atRuleNode;
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
  Declaration visitDeclaration(Declaration declNode, VisitArgs visitArgs) {
    Keyword keyword;
    //Color color;

    declNode.cleanCss = cleancsscontext;

    // ' ! important'
    if (declNode.important.isNotEmpty) {
      declNode.important = declNode.important.replaceAll(' ', '');
    }

    if (declNode.name == 'background') {
      final value = declNode.value.toString();
      if (value == 'none' || value == 'transparent') {
        declNode.value = Keyword('0 0');
      }

      // if (declNode.value is Keyword) {
      //   keyword = declNode.value;
      //   if (keyword.value == 'none')
      //       keyword.value = '0 0';
      // }

      // if (declNode.value is Color) {
      //   color = declNode.value;
      //   if (color.value != null && color.value == 'transparent')
      //       declNode.value = new Keyword('0 0');
      // }
    }

    if (declNode.name == 'font') {
      if ((keyword = getFirstKeyword(declNode)) != null) {
        if (keyword.value == 'normal') keyword.value = '400';
        if (keyword.value == 'bold') keyword.value = '700';
      }
    }

    if (declNode.name == 'font-weight') {
      final value = declNode.value.toString();
      if (value == 'normal') {
        declNode.value = Dimension(400);
      }
      if (value == 'bold') {
        declNode.value = Dimension(700);
      }
      // if (declNode.value is Keyword) {
      //   if (declNode.value.value == 'normal')
      //       declNode.value = new Dimension(400);
      //   if (declNode.value.value == 'bold')
      //       declNode.value = new Dimension(700);
      // }
    }

    if (declNode.name == 'outline') {
      final value = declNode.value.toString();
      if (value == 'none') {
        declNode.value = Dimension(0);
      }

      // if (declNode.value is Keyword) {
      //   keyword = declNode.value;
      //   if (keyword.value == 'none')
      //       keyword.value = '0';
      // }
    }

    return declNode;
  }

  ///
  /// Change selectors attribute from quoted
  /// - Example: `input[type="text"] -> input[type=text]``
  /// - Example: `input[type="1"] -> input[type="1"]`` (starts with number)
  /// - Example: `([class*="lead"]) -> ([class*=lead])`
  ///
  Ruleset visitRuleset(Ruleset rulesetNode, VisitArgs visitArgs) {
    Attribute attribute;
    List<Element> elements;
    Match match;
    Quoted quoted;
    List<Selector> selectors;
    String valueStr;

    //for compress analysis we need the full parsed node. Ex. Color
    rulesetNode.parseForCompression();

    //RegExp symbolRe = new RegExp(r'[^a-zA-Z0-9]');
    final attrRe = RegExp(r'\[(.)*=\s*("[a-z0-9]+")\s*]', caseSensitive: false);

    rulesetNode.cleanCss = CleanCssContext();
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
                  if (!hasSymbol(valueStr)) {
                    //remove for text/digits only: input[type="text"] -> input[type=text]
                    quoted.quote = '';
                  }
                }
              } else if (cleanCssOptions.advanced) {
                // "([class*="lead"])"
                if (element.value is String) {
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
  /// `url('...') -> url(...)`
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

  ///
  /// Has ./$ ... characters. Starts with letter
  ///
//  bool hasSymbol(String value) => RegExp(r'[^a-zA-Z0-9]').hasMatch(value);
  bool hasSymbol(String value) => RegExp(r'[^a-zA-Z]').hasMatch(value);

  ///
  /// Remove spaces and quotes. [indexQuoted] for quotes in the [match]
  /// [source] is the original string
  /// Example: "([class *= "lead"])" -> "([class*=lead])"
  ///
  String removeQuotesAndSpace(Match match, String source, int indexQuoted) {
    var quoted = match[indexQuoted];
    final start = source.indexOf(quoted);

    final prefix = source.substring(0, start).replaceAll(' ', '');
    final suffix = source.substring(start + quoted.length).replaceAll(' ', '');

    final newQuoted = quoted.substring(1, quoted.length - 1); //remove quotes
    if (!hasSymbol(newQuoted)) quoted = newQuoted;

    return '$prefix$quoted$suffix';
  }

  ///
  /// Remove ' ( ', ' ) ', ': ', \n '  '
  ///
  String removeSpaces(String value) {
    int len;
    var _value = value;

    do {
      len = _value.length;
      _value = _value.replaceAll('  ', ' ');
    } while (_value.length != len);

    _value = _value
        .replaceAll('\n', '')
        .replaceAll(' (', '(')
        .replaceAll('( ', '(')
        .replaceAll(' )', ')');

    if (!cleancsscontext.compatibility.properties.spaceAfterClosingBrace) {
      _value = _value.replaceAll(') ', ')');
    }

    return _value.replaceAll(': ', ':');
  }

  @override
  Function visitFtn(Node node) {
    if (node is Call) return visitCall;
    if (node is Color) return visitColor;
    if (node is Comment) return visitComment;
    if (node is Dimension) return visitDimension;
    if (node is AtRule) return visitAtRule;
    if (node is Expression) return visitExpression;
    if (node is Declaration) return visitDeclaration;
    if (node is Ruleset) return visitRuleset;
    if (node is URL) return visitUrl;
    return null;
  }

  @override
  Function visitFtnOut(Node node) => null;
}
