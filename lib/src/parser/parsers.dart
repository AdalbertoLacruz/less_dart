//source: less/parser.js ines 195-end 2.8.0 20160713

part of parser.less;

///
/// Here in, the parsing rules/functions
///
/// The basic structure of the syntax tree generated is as follows:
///
///   Ruleset ->  Declaration -> Value -> Expression -> Entity
///
/// Here's some Less code:
///
///    .class {
///      color: #fff;
///      border: 1px solid #000;
///      width: @w + 4px;
///      > .child {...}
///    }
///
/// And here's what the parse tree might look like:
///
///     Ruleset (Selector '.class', [
///         Declaration ("color",  Value ([Expression [Color #fff]]))
///         Declaration ("border", Value ([Expression [Dimension 1px][Keyword "solid"][Color #000]]))
///         Declaration ("width",  Value ([Expression [Operation "+" [Variable "@w"][Dimension 4px]]]))
///         Ruleset (Selector [Element '>', '.child'], [...])
///     ])
///
///  In general, most rules will try to parse a token with the `$re()` function, and if the return
///  value is truly, will return a new node, of the relevant type. Sometimes, we need to check
///  first, before parsing, that's when we use `peek()`.
///
class Parsers {
  ///
  Contexts    context;
  ///
  Entities    entities;
  ///
  FileInfo    fileInfo;
  ///
  String      input;
  ///
  Mixin       mixin;
  ///
  ParserInput parserInput;

  ///
  Parsers(String this.input, Contexts this.context) {
    context.input = input;
    fileInfo = context.currentFileInfo;
    parserInput = new ParserInput(input, context);
    entities = new Entities(context, parserInput, this);
    mixin = new Mixin(context, parserInput, this, entities);
  }

  ///
  /// The `primary` rule is the *entry* and *exit* point of the parser.
  /// The rules here can appear at any level of the parse tree.
  ///
  /// The recursive nature of the grammar is an interplay between the `block`
  /// rule, which represents `{ ... }`, the `ruleset` rule, and this `primary` rule,
  /// as represented by this simplified grammar:
  ///
  ///     primary  →  (ruleset | declaration)+
  ///     ruleset  →  selector+ block
  ///     block    →  '{' primary '}'
  ///
  /// Only at one point is the primary rule not called from the
  /// block rule: at the root level.
  ///
  List<Node> primary() {
    Node              node;
    List<Node>        nodeList;
    final List<Node>  root = <Node>[];

    while (true) {
      while (true) {
        node = comment();
        if (node == null)
            break;
        root.add(node);
      }

      // always process comments before deciding if finished
      if (parserInput.finished || parserInput.empty)
          break;
      if (parserInput.peekChar('}'))
          break;

      nodeList = extendRule();
      if (nodeList != null) {
        root.addAll(nodeList);
        continue;
      }

      node = mixin.definition()
          ?? declaration()
          ?? ruleset()
          ?? mixin.call()
          ?? rulesetCall()
          ?? entities.call()
          ?? atrule();

      if (node != null) {
        root.add(node);
      } else {
        bool foundSemiColon = false;
        while (parserInput.$char(";") != null) {
          foundSemiColon = true;
        }
        if (!foundSemiColon)
            break;
      }
    }

    return root;

//2.8.0 20160702
// primary: function () {
//     var mixin = this.mixin, root = [], node;
//
//     while (true) {
//         while (true) {
//             node = this.comment();
//             if (!node) { break; }
//             root.push(node);
//         }
//         // always process comments before deciding if finished
//         if (parserInput.finished) {
//             break;
//         }
//         if (parserInput.peek('}')) {
//             break;
//         }
//
//         node = this.extendRule();
//         if (node) {
//             root = root.concat(node);
//             continue;
//         }
//
//         node = mixin.definition() || this.declaration() || this.ruleset() ||
//             mixin.call() || this.rulesetCall() || this.entities.call() || this.atrule();
//         if (node) {
//             root.push(node);
//         } else {
//             var foundSemiColon = false;
//             while (parserInput.$char(";")) {
//                 foundSemiColon = true;
//             }
//             if (!foundSemiColon) {
//                 break;
//             }
//         }
//     }
//
//     return root;
// },
  }

  /// Check if input is empty. Else throw error.
  void isFinished() => parserInput.isFinished();

  ///
  /// Comments are collected by the main parsing mechanism and then assigned to nodes
  /// where the current structure allows it
  ///
  /// CSS comments `/* */`, LeSS comments `//`
  ///
  Comment comment() {
    if (parserInput.commentStore.isNotEmpty) {
      final CommentPointer comment = parserInput.commentStore.removeAt(0);
      return new Comment(comment.text,
          isLineComment: comment.isLineComment,
          index: comment.index,
          currentFileInfo: context.currentFileInfo);
    }
    return null;

//2.2.0
//  comment: function () {
//      if (parserInput.commentStore.length) {
//          var comment = parserInput.commentStore.shift();
//          return new(tree.Comment)(comment.text, comment.isLineComment, comment.index, fileInfo);
//      }
//  }
  }

  static final RegExp _variableRegExp = new RegExp(r'(@[\w-]+)\s*:', caseSensitive: true);

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///      @fink:
  ///
  String variable() {
    String name;

    if (parserInput.currentChar() == '@' &&
        (name = parserInput.$re(_variableRegExp)) != null)
        return name;
    return null;

//2.2.0
//  variable: function () {
//      var name;
//
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^(@[\w-]+)\s*:/))) { return name[1]; }
//  }
  }

  static final RegExp _rulesetCallRegExp = new RegExp(r'(@[\w-]+)\(\s*\)\s*;', caseSensitive: true);

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///       @fink();
  ///
  RulesetCall rulesetCall() {
    String name;

    if (parserInput.currentChar() == '@') {
      name = parserInput.$re(_rulesetCallRegExp);
      if (name != null)
          return new RulesetCall(name);
    }

    return null;

//2.6.0 20160224
//
// The variable part of a variable definition. Used in the `rule` parser
//
//     @fink();
//
// rulesetCall: function () {
//     var name;
//
//     if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^(@[\w-]+)\(\s*\)\s*;/))) {
//         return new tree.RulesetCall(name[1]);
//     }
// },
  }

  static final RegExp _extendRegExp = new RegExp(r'(all)(?=\s*(\)|,))', caseSensitive: true);

  ///
  /// extend syntax - used to extend selectors
  ///
  List<Extend> extend({bool isRule = false}) {
    Element       e;
    List<Element> elements;
    List<Extend>  extendedList;
    final int     index = parserInput.i;
    String        option;

    if (parserInput.$str(isRule ? '&:extend(' : ':extend(') ==  null)
        return null;

    do {
      option = null;
      elements = null;
      while ((option = parserInput.$re(_extendRegExp, 1)) == null) {
        e = element();
        if (e == null)
            break;

        (elements ??= <Element>[])
            ..add(e);
      }

      if (elements == null) {
        parserInput.error('Missing target selector for :extend().');
      }

      (extendedList ??= <Extend>[])
          ..add(new Extend(new Selector(elements), option, index, fileInfo));
    } while (parserInput.$char(',') != null);

    parserInput.expectChar(')');
    if (isRule)
        parserInput.expectChar(';');

    return extendedList;

//2.5.3 20151120
//
// // extend syntax - used to extend selectors
// //
// extend: function(isRule) {
//     var elements, e, index = parserInput.i, option, extendList, extend;
//
//     if (!parserInput.$str(isRule ? "&:extend(" : ":extend(")) {
//         return;
//     }
//
//     do {
//         option = null;
//         elements = null;
//         while (! (option = parserInput.$re(/^(all)(?=\s*(\)|,))/))) {
//             e = this.element();
//             if (!e) {
//                 break;
//             }
//             if (elements) {
//                 elements.push(e);
//             } else {
//                 elements = [ e ];
//             }
//         }
//
//         option = option && option[1];
//         if (!elements) {
//             error("Missing target selector for :extend().");
//         }
//         extend = new(tree.Extend)(new(tree.Selector)(elements), option, index);
//         if (extendList) {
//             extendList.push(extend);
//         } else {
//             extendList = [ extend ];
//         }
//     } while (parserInput.$char(","));
//
//     expect(/^\)/);
//
//     if (isRule) {
//         expect(/^;/);
//     }
//
//     return extendList;
// },
  }

  /// extendRule - used in a rule to extend all the parent selectors
  List<Extend> extendRule() => extend(isRule: true);

  ///
  /// Entities are the smallest recognized token,
  /// and can be found inside a rule's value.
  ///
  Node entity() {
    final Node result = comment()
        ?? entities.literal()
        ?? entities.variable()
        ?? entities.url()
        ?? entities.call()
        ?? entities.keyword()
        ?? entities.javascript();
    return result;

//2.2.0
//  entity: function () {
//      var entities = this.entities;
//
//      return this.comment() || entities.literal() || entities.variable() || entities.url() ||
//             entities.call()    || entities.keyword()  || entities.javascript();
//  }
  }

  ///
  /// A Declaration terminator. Note that we use `peek()` to check for '}',
  /// because the `block` rule will be expecting it, but we still need to make sure
  /// it's there, if ';' was omitted.
  ///
  bool end() => (parserInput.$char(';') != null) || parserInput.peekChar('}');

//2.2.0
//  end: function () {
//      return parserInput.$char(';') || parserInput.peek('}');
//  }

//
//alpha: see entities.alpha()
//

  static final RegExp _elementRegExp1 = new RegExp(r'(?:\d+\.\d+|\d+)%', caseSensitive: true);
  static final RegExp _elementRegExp2 = new RegExp(r'(?:[.#]?|:*)(?:[\w-]|[^\x00-\x9f]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+', caseSensitive: true);
  static final RegExp _elementRegExp3 = new RegExp(r'\([^&()@]+\)', caseSensitive: true);
  static final RegExp _elementRegExp4 = new RegExp(r'[\.#:](?=@)', caseSensitive: true);

  ///
  /// A Selector Element
  ///
  ///     div
  ///     + h1
  ///     #socks
  ///     input[type="text"]
  ///
  /// Elements are the building blocks for Selectors,
  /// they are made out of a `Combinator` (see combinator rule),
  /// and an element name, such as a tag a class, or `*`.
  ///
  Element element() {
    Combinator  c;
    dynamic     e; //String or Node
    final int   index = parserInput.i;
    Selector    v;

    c = combinator();

    e =    parserInput.$re(_elementRegExp1)
        ?? parserInput.$re(_elementRegExp2)
        ?? parserInput.$char('*')
        ?? parserInput.$char('&')
        ?? attribute()
        ?? parserInput.$re(_elementRegExp3)
        ?? parserInput.$re(_elementRegExp4)
        ?? entities.variableCurly();

    if (e == null) {
      parserInput.save();
      if (parserInput.$char('(') != null) {
        if ((v = selector()) != null && parserInput.$char(')') != null) {
          e = new Paren(v);
          parserInput.forget();
        } else {
          parserInput.restore("Missing closing ')'");
        }
      } else {
        parserInput.forget();
      }
    }

    if (e != null)
        return new Element(c, e, index, fileInfo);
    return null;

//2.4.0
//  element: function () {
//      var e, c, v, index = parserInput.i;
//
//      c = this.combinator();
//
//      e = parserInput.$re(/^(?:\d+\.\d+|\d+)%/) ||
//          parserInput.$re(/^(?:[.#]?|:*)(?:[\w-]|[^\x00-\x9f]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+/) ||
//          parserInput.$char('*') || parserInput.$char('&') || this.attribute() ||
//          parserInput.$re(/^\([^&()@]+\)/) ||  parserInput.$re(/^[\.#:](?=@)/) ||
//          this.entities.variableCurly();
//
//      if (! e) {
//          parserInput.save();
//          if (parserInput.$char('(')) {
//              if ((v = this.selector()) && parserInput.$char(')')) {
//                  e = new(tree.Paren)(v);
//                  parserInput.forget();
//              } else {
//                  parserInput.restore("Missing closing ')'");
//              }
//          } else {
//              parserInput.forget();
//          }
//      }
//
//      if (e) { return new(tree.Element)(c, e, index, fileInfo); }
//  },
  }

  static final RegExp _combinatorRegExp1 = new RegExp(r'\/[a-z]+\/', caseSensitive: false);

  ///
  /// Combinators combine elements together, in a Selector.
  ///
  /// Because our parser isn't white-space sensitive, special care
  /// has to be taken, when parsing the descendant combinator, ` `,
  /// as it's an empty space. We have to check the previous character
  /// in the input, to see if it's a ` ` character. More info on how
  /// we deal with this in *combinator.js*.
  ///
  Combinator combinator() {
    String c = parserInput.currentChar();

    if (c == '/') {
      parserInput.save();
      final String slashedCombinator = parserInput.$re(_combinatorRegExp1); //i-nsensitive
      if (slashedCombinator != null) {
        parserInput.forget();
        return new Combinator(slashedCombinator);
      }
      parserInput.restore();
    }

    if (c == '>' || c == '+' || c == '~' || c == '|' || c == '^') {
      parserInput.i++;
      if (c == '^' && parserInput.currentChar() == '^') {
        c = '^^';
        parserInput.i++;
      }
      while (parserInput.isWhitespacePos()) {
        parserInput.i++;
      }
      return new Combinator(c);
    } else if (parserInput.isWhitespacePrevPos()) {
      return new Combinator(' ');
    } else {
      return new Combinator(null);
    }

//2.2.0
//  combinator: function () {
//      var c = parserInput.currentChar();
//
//      if (c === '/') {
//          parserInput.save();
//          var slashedCombinator = parserInput.$re(/^\/[a-z]+\//i);
//          if (slashedCombinator) {
//              parserInput.forget();
//              return new(tree.Combinator)(slashedCombinator);
//          }
//          parserInput.restore();
//      }
//
//      if (c === '>' || c === '+' || c === '~' || c === '|' || c === '^') {
//          parserInput.i++;
//          if (c === '^' && parserInput.currentChar() === '^') {
//              c = '^^';
//              parserInput.i++;
//          }
//          while (parserInput.isWhitespace()) { parserInput.i++; }
//          return new(tree.Combinator)(c);
//      } else if (parserInput.isWhitespace(-1)) {
//          return new(tree.Combinator)(" ");
//      } else {
//          return new(tree.Combinator)(null);
//      }
//  }
  }

  ///
  /// A CSS selector (see selector below)
  /// with less extensions e.g. the ability to extend and guard
  ///
  Selector lessSelector() => selector(isLess: true);

  ///
  /// A CSS Selector
  ///
  ///     .class > div + h1
  ///     li a:hover
  ///
  /// Selectors are made out of one or more Elements, see above.
  ///
  Selector selector({bool isLess = false}) {
    List<Extend>  allExtends;
    String        c;
    Condition     condition;
    Element       e;
    List<Element> elements;
    List<Extend>  extendList;
    final int     index = parserInput.i;
    String        when;

    while ((isLess && (extendList = extend()) != null) ||
        (isLess && (when = parserInput.$str('when')) != null) ||
        (e = element()) != null) {
      if (when != null) {
        condition = parserInput.expect(conditions, 'expected condition');
      } else if (condition != null) {
        parserInput.error('CSS guard can only be used at the end of selector');
      } else if (extendList != null) {
        if (allExtends != null) {
          allExtends.addAll(extendList);
        } else {
          allExtends = extendList;
        }
      } else {
        if (allExtends != null)
            parserInput.error('Extend can only be used at the end of selector');
        c = parserInput.currentChar();
        (elements ??= <Element>[])
            ..add(e);
        e = null;
      }
      if (c == '{' || c == '}' || c == ';' || c == ',' || c == ')' )
          break;
    }

    if (elements != null)
        return new Selector(elements,
            extendList: allExtends,
            condition: condition,
            index: index,
            currentFileInfo: fileInfo);
    if (allExtends != null)
        parserInput.error('Extend must be used to extend a selector, it cannot be used on its own');

    return null;

//2.4.0 20150315
//  selector: function (isLess) {
//      var index = parserInput.i, elements, extendList, c, e, allExtends, when, condition;
//
//      while ((isLess && (extendList = this.extend())) || (isLess && (when = parserInput.$str("when"))) || (e = this.element())) {
//          if (when) {
//              condition = expect(this.conditions, 'expected condition');
//          } else if (condition) {
//              error("CSS guard can only be used at the end of selector");
//          } else if (extendList) {
//              if (allExtends) {
//                  allExtends = allExtends.concat(extendList);
//              } else {
//                  allExtends = extendList;
//              }
//          } else {
//              if (allExtends) { error("Extend can only be used at the end of selector"); }
//              c = parserInput.currentChar();
//              if (elements) {
//                  elements.push(e);
//              } else {
//                  elements = [ e ];
//              }
//              e = null;
//          }
//          if (c === '{' || c === '}' || c === ';' || c === ',' || c === ')') {
//              break;
//          }
//      }
//
//      if (elements) { return new(tree.Selector)(elements, allExtends, condition, index, fileInfo); }
//      if (allExtends) { error("Extend must be used to extend a selector, it cannot be used on its own"); }
//  },
  }
  static final RegExp _attributeRegExp1 = new RegExp(r'[|~*$^]?=', caseSensitive: true);
  static final RegExp _attributeRegExp2 = new RegExp(r'[0-9]+%', caseSensitive: true);
  static final RegExp _attributeRegExp3 = new RegExp(r'[\w-]+', caseSensitive: true);
  static final RegExp _attributeRegExp4 = new RegExp(r'(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+');

  ///
  Attribute attribute() {
    if (parserInput.$char('[') == null)
        return null;

    dynamic key; //String or Node
    String  op;
    dynamic val; //String or Node

    key = entities.variableCurly()
        ?? parserInput.expect(_attributeRegExp4);

    op = parserInput.$re(_attributeRegExp1);
    if (op != null) {
      val = entities.quoted()
          ?? parserInput.$re(_attributeRegExp2)
          ?? parserInput.$re(_attributeRegExp3)
          ?? entities.variableCurly();
    }

    parserInput.expectChar(']');
    return new Attribute(key, op, val);

//2.2.0
//  attribute: function () {
//      if (! parserInput.$char('[')) { return; }
//
//      var entities = this.entities,
//          key, val, op;
//
//      if (!(key = entities.variableCurly())) {
//          key = expect(/^(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+/);
//      }
//
//      op = parserInput.$re(/^[|~*$^]?=/);
//      if (op) {
//          val = entities.quoted() || parserInput.$re(/^[0-9]+%/) || parserInput.$re(/^[\w-]+/) || entities.variableCurly();
//      }
//
//      expectChar(']');
//
//      return new(tree.Attribute)(key, op, val);
//  }
  }

  ///
  /// The `block` rule is used by `ruleset` and `mixin.definition`.
  /// It's a wrapper around the `primary` rule, with added `{}`.
  ///
  List<Node> block() {
    List<Node> content;

    if (parserInput.$char('{') != null &&
        (content = primary()) != null &&
        parserInput.$char('}') != null)
        return content;
    return null;

//2.2.0
//  block: function () {
//      var content;
//      if (parserInput.$char('{') && (content = this.primary()) && parserInput.$char('}')) {
//          return content;
//      }
//  }
  }

  ///
  Ruleset blockRuleset() {
    final List<Node> block = this.block();

    return (block != null) ? new Ruleset(null, block) : null;

//2.2.0
//  blockRuleset: function() {
//      var block = this.block();
//
//      if (block) {
//          block = new tree.Ruleset(null, block);
//      }
//      return block;
//  }
  }

  ///
  DetachedRuleset detachedRuleset() {
    final Ruleset blockRuleset = this.blockRuleset();
    return (blockRuleset != null) ? new DetachedRuleset(blockRuleset) : null;

//2.2.0
//  detachedRuleset: function() {
//      var blockRuleset = this.blockRuleset();
//      if (blockRuleset) {
//          return new tree.DetachedRuleset(blockRuleset);
//      }
//  }
  }

  ///
  /// div, .class, body > p {...}
  ///
  Ruleset ruleset() {
    DebugInfo       debugInfo;
    List<Node>      rules;
    Selector        s;
    List<Selector>  selectors;

    parserInput.save();

    if (isNotEmpty(context.dumpLineNumbers)) {
      debugInfo = getDebugInfo(parserInput.i);
    }

    while (true) {
      s = lessSelector();
      if (s == null)
          break;

      // --polymer-mixin: {}
      // No standard js implementation
      if (parserInput.peekChar(':') && s.elements.length == 1) {
        if (s.elements[0].value is String && s.elements[0].value.startsWith('--')) {
          s.elements[0].value = '${s.elements[0].value}:';
          parserInput.$char(':'); //move pointer
        }
      }
      // end no standard

      (selectors ??= <Selector>[])
          ..add(s);

      parserInput.commentStore.length = 0;
      if (s.condition != null && selectors.length > 1) {
        parserInput.error('Guards are only currently allowed on a single selector.');
      }
      if (parserInput.$char(',') == null)
          break;
      if (s.condition != null) {
        parserInput.error('Guards are only currently allowed on a single selector.');
      }
      parserInput.commentStore.length = 0;
    }

    if (selectors != null && (rules = block()) != null) {
      parserInput.forget();
      final Ruleset ruleset = new Ruleset(selectors, rules,
          strictImports: context.strictImports);
      if (context.dumpLineNumbers?.isNotEmpty ?? false)
          ruleset.debugInfo = debugInfo;
      return ruleset;
    } else {
      parserInput.restore();
    }
    return null;

//2.4.0
//  ruleset: function () {
//      var selectors, s, rules, debugInfo;
//
//      parserInput.save();
//
//      if (context.dumpLineNumbers) {
//          debugInfo = getDebugInfo(parserInput.i);
//      }
//
//      while (true) {
//          s = this.lessSelector();
//          if (!s) {
//              break;
//          }
//          if (selectors) {
//              selectors.push(s);
//          } else {
//              selectors = [ s ];
//          }
//          parserInput.commentStore.length = 0;
//          if (s.condition && selectors.length > 1) {
//              error("Guards are only currently allowed on a single selector.");
//          }
//          if (! parserInput.$char(',')) { break; }
//          if (s.condition) {
//              error("Guards are only currently allowed on a single selector.");
//          }
//          parserInput.commentStore.length = 0;
//      }
//
//      if (selectors && (rules = this.block())) {
//          parserInput.forget();
//          var ruleset = new(tree.Ruleset)(selectors, rules, context.strictImports);
//          if (context.dumpLineNumbers) {
//              ruleset.debugInfo = debugInfo;
//          }
//          return ruleset;
//      } else {
//          parserInput.restore();
//      }
//  },
  }

  ///
  Declaration declaration({bool tryAnonymous = false}) {
    final String  c = parserInput.currentChar();
    String        important;
    bool          isVariable;
    String        merge = '';
    dynamic       name; //String or Node
    final int     startOfRule = parserInput.i;
    Node          value;

    if (c == '.' || c == '#' || c == '&' || c == ':')
        return null;

    parserInput.save();

    name = variable()
        ?? ruleProperty();

    if (name != null) {
      isVariable = name is String;
      if (isVariable)
          value = detachedRuleset();

      parserInput.commentStore.length = 0;
      if (value == null) {
        // a name returned by this.ruleProperty() is always an array of the form:
        // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
        // where each item is a tree.Keyword or tree.Variable
        merge = (!isVariable && name.length > 1)
            ? (name as List<Node>).removeLast().value
            : '';

        // prefer to try to parse first if its a variable or we are compressing
        // but always fallback on the other one
        final bool tryValueFirst = !tryAnonymous && (context.compress || isVariable || context.cleanCss);
        if (tryValueFirst)
            value = this.value();

        if (value == null) {
          value = anonymousValue();
          if (value != null) {
            parserInput.forget();
            // anonymous values absorb the end ';' which is required for them to work
            return new Declaration(name, value,
                important: '',
                merge: merge,
                index: startOfRule,
                currentFileInfo: fileInfo);
          }
        }

        if (!tryValueFirst && value == null)
            value = this.value();

        important = this.important();
      }

      if (value != null && end()) {
        parserInput.forget();
        return new Declaration(name, value,
            important: important,
            merge: merge,
            index: startOfRule,
            currentFileInfo: fileInfo);
      } else {
        parserInput.restore();
        if (value != null && !tryAnonymous)
            return declaration(tryAnonymous: true);
      }
    } else {
      parserInput.forget();
    }

    return null;

//2.8.0 20160702
// declaration: function (tryAnonymous) {
//     var name, value, startOfRule = parserInput.i, c = parserInput.currentChar(), important, merge, isVariable;
//
//     if (c === '.' || c === '#' || c === '&' || c === ':') { return; }
//
//     parserInput.save();
//
//     name = this.variable() || this.ruleProperty();
//     if (name) {
//         isVariable = typeof name === "string";
//
//         if (isVariable) {
//             value = this.detachedRuleset();
//         }
//
//         parserInput.commentStore.length = 0;
//         if (!value) {
//             // a name returned by this.ruleProperty() is always an array of the form:
//             // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
//             // where each item is a tree.Keyword or tree.Variable
//             merge = !isVariable && name.length > 1 && name.pop().value;
//
//             // prefer to try to parse first if its a variable or we are compressing
//             // but always fallback on the other one
//             var tryValueFirst = !tryAnonymous && (context.compress || isVariable);
//
//             if (tryValueFirst) {
//                 value = this.value();
//             }
//             if (!value) {
//                 value = this.anonymousValue();
//                 if (value) {
//                     parserInput.forget();
//                     // anonymous values absorb the end ';' which is required for them to work
//                     return new (tree.Declaration)(name, value, false, merge, startOfRule, fileInfo);
//                 }
//             }
//             if (!tryValueFirst && !value) {
//                 value = this.value();
//             }
//
//             important = this.important();
//         }
//
//         if (value && this.end()) {
//             parserInput.forget();
//             return new (tree.Declaration)(name, value, important, merge, startOfRule, fileInfo);
//         } else {
//             parserInput.restore();
//             if (value && !tryAnonymous) {
//                 return this.declaration(true);
//             }
//         }
//     } else {
//         parserInput.forget();
//     }
// },
  }

  static final RegExp _anonymousValueRegExp1 = new RegExp(r'''([^@+\/'"*`(;{}-]*);''', caseSensitive: false);

  ///
  Anonymous anonymousValue() {
    final String match = parserInput.$re(_anonymousValueRegExp1, 1);
    if (match != null)
        return new Anonymous(match);
    return null;

//2.2.0
//  anonymousValue: function () {
//      var match = parserInput.$re(/^([^@+\/'"*`(;{}-]*);/);
//      if (match) {
//          return new(tree.Anonymous)(match[1]);
//      }
//  }
  }

  static final RegExp _importRegExp1 = new RegExp(r'@import?\s+', caseSensitive: true);

  ///
  /// An @import atrule
  ///
  ///     @import "lib";
  ///
  /// Depending on our environment, importing is done differently:
  /// In the browser, it's an XHR request, in Node, it would be a
  /// file-system operation. The function used for importing is
  /// stored in `import`, which we pass to the Import constructor.
  ///
  Import import() {
    final int     index = parserInput.i;
    List<Node>    features;
    Value         nodeFeatures;
    ImportOptions options = new ImportOptions();
    Node          path;

    final String dir = parserInput.$re(_importRegExp1);

    if (dir != null) {
      options = importOptions()
          ?? new ImportOptions();

      path = entities.quoted()
          ?? entities.url();

      if (path != null) {
        features = mediaFeatures();

        if (parserInput.$char(';') == null) {
          parserInput
              ..i = index
              ..error('missing semi-colon or unrecognised media features on import');
        }
        if (features != null)
            nodeFeatures = new Value(features);
        return new Import(path, nodeFeatures, options, index, fileInfo);
      } else {
        parserInput
            ..i = index
            ..error('malformed import statement');
      }
    }

    return null;

//2.8.0 20160702
// "import": function () {
//     var path, features, index = parserInput.i;
//
//     var dir = parserInput.$re(/^@import?\s+/);
//
//     if (dir) {
//         var options = (dir ? this.importOptions() : null) || {};
//
//         if ((path = this.entities.quoted() || this.entities.url())) {
//             features = this.mediaFeatures();
//
//             if (!parserInput.$char(';')) {
//                 parserInput.i = index;
//                 error("missing semi-colon or unrecognised media features on import");
//             }
//             features = features && new(tree.Value)(features);
//             return new(tree.Import)(path, features, options, index, fileInfo);
//         }
//         else {
//             parserInput.i = index;
//             error("malformed import statement");
//         }
//     }
// },
  }

  ///
  /// ex. @import (less, multiple) "file.css";
  /// return {less: true, multiple: true}
  ///
  ImportOptions importOptions() {
    String              o;
    String              optionName;
    final ImportOptions options = new ImportOptions();
    bool                value;

    // list of options, surrounded by parens
    if (parserInput.$char('(') == null)
        return null;
    do {
      o = importOption();
      if (o != null) {
        optionName = o;
        value = true;
        switch (optionName) {
          case 'css':
            optionName = 'less';
            value = false;
            break;
          case 'once':
            optionName = 'multiple';
            value = false;
            break;
        }
        options[optionName] = value;
        if(parserInput.$char(',') == null)
            break;
      }
    } while (o != null);
    parserInput.expectChar(')');
    return options;
  }

//2.4.0
//  importOptions: function() {
//      var o, options = {}, optionName, value;
//
//      // list of options, surrounded by parens
//      if (! parserInput.$char('(')) { return null; }
//      do {
//          o = this.importOption();
//          if (o) {
//              optionName = o;
//              value = true;
//              switch(optionName) {
//                  case "css":
//                      optionName = "less";
//                      value = false;
//                      break;
//                  case "once":
//                      optionName = "multiple";
//                      value = false;
//                      break;
//              }
//              options[optionName] = value;
//              if (! parserInput.$char(',')) { break; }
//          }
//      } while (o);
//      expectChar(')');
//      return options;
//  },

  static final RegExp _importOptionRegExp1 = new RegExp(r'(less|css|multiple|once|inline|reference|optional)', caseSensitive: true);

  ///
  String importOption() => parserInput.$re(_importOptionRegExp1);

//2.4.0
//  importOption: function() {
//      var opt = parserInput.$re(/^(less|css|multiple|once|inline|reference|optional)/);
//      if (opt) {
//          return opt[1];
//      }
//  },

  ///
  Expression mediaFeature() {
    Node              e;
    final List<Node>  nodes = <Node>[];
    String            p;

    parserInput.save();
    do {
      e = entities.keyword()
          ?? entities.variable();

      if (e != null) {
        nodes.add(e);
      } else if (parserInput.$char('(') != null) {
        p = property();
        e = value();
        if (parserInput.$char(')') != null) {
          if (p != null && e != null) {
            nodes.add(new Paren(new Declaration(p, e,
              index: parserInput.i,
              currentFileInfo: fileInfo,
              inline: true)));
          } else if (e != null) {
            nodes.add(new Paren(e));
          } else {
            parserInput.error('badly formed media feature definition');
          }
        } else {
          parserInput.error("Missing closing ')'", 'Parse');
        }
      }
    } while (e != null);

    parserInput.forget();
    if (nodes.isNotEmpty)
        return new Expression(nodes);
    return null;

//2.8.0 20160702
// mediaFeature: function () {
//     var entities = this.entities, nodes = [], e, p;
//     parserInput.save();
//     do {
//         e = entities.keyword() || entities.variable();
//         if (e) {
//             nodes.push(e);
//         } else if (parserInput.$char('(')) {
//             p = this.property();
//             e = this.value();
//             if (parserInput.$char(')')) {
//                 if (p && e) {
//                     nodes.push(new(tree.Paren)(new(tree.Declaration)(p, e, null, null, parserInput.i, fileInfo, true)));
//                 } else if (e) {
//                     nodes.push(new(tree.Paren)(e));
//                 } else {
//                     error("badly formed media feature definition");
//                 }
//             } else {
//                 error("Missing closing ')'", "Parse");
//             }
//         }
//     } while (e);
//
//     parserInput.forget();
//     if (nodes.length > 0) {
//         return new(tree.Expression)(nodes);
//     }
// },
  }

  ///
  List<Node> mediaFeatures() {
    Node              e;
    final List<Node>  features = <Node>[];

    do {
      e = mediaFeature();
      if (e != null) {
        features.add(e);
        if (parserInput.$char(',') == null)
            break;
      } else {
        e = entities.variable();
        if (e != null) {
          features.add(e);
          if (parserInput.$char(',') == null)
              break;
        }
      }
    } while (e != null);

    return features.isNotEmpty ? features : null;

//2.2.0
//  mediaFeatures: function () {
//      var entities = this.entities, features = [], e;
//      do {
//          e = this.mediaFeature();
//          if (e) {
//              features.push(e);
//              if (! parserInput.$char(',')) { break; }
//          } else {
//              e = entities.variable();
//              if (e) {
//                  features.push(e);
//                  if (! parserInput.$char(',')) { break; }
//              }
//          }
//      } while (e);
//
//      return features.length > 0 ? features : null;
//  }
  }

  ///
  Media media() {
    DebugInfo   debugInfo;
    List<Node>  features;
    Media       media;
    List<Node>  rules;

    final int index = parserInput.i;

    if (context.dumpLineNumbers?.isNotEmpty ?? false)
        debugInfo = getDebugInfo(index);

    parserInput.save();

    if (parserInput.$str('@media') != null) {
      features = mediaFeatures();

      rules = block();

      if (rules == null) {
        parserInput.error('media definitions require block statements after any features');
      }

      parserInput.forget();

      media = new Media(rules, features, index, fileInfo);
      if (context.dumpLineNumbers?.isNotEmpty ?? false)
          media.debugInfo = debugInfo;
      return media;
    }
    parserInput.restore();
    return null;

//2.7.0 20160508
// media: function () {
//     var features, rules, media, debugInfo, index = parserInput.i;
//
//     if (context.dumpLineNumbers) {
//         debugInfo = getDebugInfo(index);
//     }
//
//     parserInput.save();
//
//     if (parserInput.$str("@media")) {
//         features = this.mediaFeatures();
//
//         rules = this.block();
//
//         if (!rules) {
//             error("media definitions require block statements after any features");
//         }
//
//         parserInput.forget();
//
//         media = new(tree.Media)(rules, features, index, fileInfo);
//         if (context.dumpLineNumbers) {
//             media.debugInfo = debugInfo;
//         }
//
//         return media;
//     }
//
//     parserInput.restore();
// },
  }

  static final RegExp _applyRegExp1 = new RegExp(r'@apply?\s*', caseSensitive: true);
  static final RegExp _applyRegExp2 = new RegExp(r'[0-9A-Za-z-]+', caseSensitive: true);


  ///
  /// @apply(--mixin-name);
  /// No standard less implementation
  /// Pass-throught to css to let polymer work
  ///
  Apply apply() {
    final int index = parserInput.i;
    String    name;

    if (parserInput.$re(_applyRegExp1) != null) {
      parserInput.save();
      if (parserInput.$char('(') != null) {
        name = parserInput.$re(_applyRegExp2);
        if (name == null) {
          parserInput.restore("Bad argument");
          return null;
        }
        if (parserInput.$char(')') != null) {
          parserInput.forget();
          return new Apply(new Anonymous(name), index, fileInfo);
        }
        parserInput.restore("Expected ')'");
      }
      parserInput.restore();
    }
    return null;
  }


  static final RegExp _optionsRegExp1 = new RegExp(r'@options?\s+', caseSensitive: true);

  ///
  /// @options "--flags";
  /// No standard less implementation
  /// To load a plugin use @plugin, this don't work for that
  ///
  Options options() {
    final int index = parserInput.i;
    Quoted    value;

    final String dir = parserInput.$re(_optionsRegExp1);
    if (dir != null) {
      if ((value = entities.quoted()) != null) {
        if (parserInput.$char(';') == null) {
            parserInput
                ..i = index
                ..error('missing semi-colon on options');
        }
        return new Options(value, index, fileInfo);
      } else {
        parserInput
            ..i = index
            ..error('malformed options statement');
      }
    }

    return null;
  }

  static final RegExp _pluginRegExp1 = new RegExp(r'@plugin?\s+', caseSensitive: true);

  ///
  /// A @plugin directive, used to import plugins dynamically.
  ///     @plugin (args) "lib";
  ///
  /// Differs implementation. Here is Options and no import
  ///
  Options plugin() {
    final int index = parserInput.i;
    Quoted    value;

    final String dir = parserInput.$re(_pluginRegExp1);
    if (dir != null) {
      final String args = pluginArgs();
      if ((value = entities.quoted()) != null) {
        if (parserInput.$char(';') == null) {
            parserInput
                ..i = index
                ..error('missing semi-colon on @plugin');
        }
        if (value.value.contains('clean-css'))
            context.cleanCss = true; //parser needs this
        return new Options(value, index, fileInfo,
            isPlugin: true,
            pluginArgs: args);
      } else {
        parserInput
            ..i = index
            ..error('malformed @plugin statement');
      }
    }
    return null;

//2.8.0 20160713
// plugin: function () {
//     var path, args, options,
//         index = parserInput.i,
//         dir   = parserInput.$re(/^@plugin?\s+/);
//
//     if (dir) {
//         args = this.pluginArgs();
//
//         if (args) {
//             options = {
//                 pluginArgs: args,
//                 isPlugin: true
//             };
//         }
//         else {
//             options = { isPlugin: true };
//         }
//
//         if ((path = this.entities.quoted() || this.entities.url())) {
//
//             if (!parserInput.$char(';')) {
//                 parserInput.i = index;
//                 error("missing semi-colon on @plugin");
//             }
//             return new(tree.Import)(path, null, options, index, fileInfo);
//         }
//         else {
//             parserInput.i = index;
//             error("malformed @plugin statement");
//         }
//     }
// },
  }

  static final RegExp _pluginArgsRegExp = new RegExp(r'\s*([^\);]+)\)\s*', caseSensitive: true);

  ///
  /// list of options, surrounded by parens
  ///      @plugin (args) "lib";
  ///
  String pluginArgs() {
    parserInput.save();
    if (parserInput.$char('(') == null) {
      parserInput.restore();
      return null;
    }
    final String args = parserInput.$re(_pluginArgsRegExp);
    if (args != null) {
      parserInput.forget();
      return args.trim();
    } else {
      parserInput.restore();
      return null;
    }

//2.8.0 20160713
// pluginArgs: function() {
//     // list of options, surrounded by parens
//     parserInput.save();
//     if (! parserInput.$char('(')) {
//         parserInput.restore();
//         return null;
//     }
//     var args = parserInput.$re(/^\s*([^\);]+)\)\s*/);
//     if (args[1]) {
//         parserInput.forget();
//         return args[1].trim();
//     }
//     else {
//         parserInput.restore();
//         return null;
//     }
// },
  }

  static final RegExp _directiveRegExp1 = new RegExp(r'@[a-z-]+', caseSensitive: true);
  static final RegExp _directiveRegExp2 = new RegExp(r'[^{;]+', caseSensitive: true);


  ///
  /// A CSS AtRule
  ///
  ///     @charset "utf-8";
  ///
  Node atrule() {
    bool      hasBlock = true;
    bool      hasExpression = false;
    bool      hasIdentifier = false;
    bool      hasUnknown = false;
    final int index = parserInput.i;
    bool      isRooted = true;
    String    name;
    String    nonVendorSpecificName;
    Ruleset   rules;
    Node      value;

    if (parserInput.currentChar() != '@')
        return null;

    value = import()
        ?? options()
        ?? plugin()
        ?? apply()
        ?? media();
    if (value != null)
        return value;

    parserInput.save();

    name = parserInput.$re(_directiveRegExp1);
    if (name == null)
        return null;

    nonVendorSpecificName = name;
    if (name[1] == '-' && name.indexOf('-', 2) > 0)
        nonVendorSpecificName = '@${name.substring(name.indexOf("-", 2) + 1)}';

    switch (nonVendorSpecificName) {
      case '@charset':
        hasIdentifier = true;
        hasBlock = false;
        break;
      case '@namespace':
        hasExpression = true;
        hasBlock = false;
        break;
      case '@keyframes':
      case '@counter-style':
        hasIdentifier = true;
        break;
      case '@document':
      case '@supports':
        hasUnknown = true;
        isRooted = false;
        break;
      default:
        hasUnknown = true;
        break;
    }

    parserInput.commentStore.length = 0;

    if (hasIdentifier) {
      value = entity();
      if (value == null)
          parserInput.error('expected $name identifier');
    } else if (hasExpression) {
      value = expression();
      if (value == null)
          parserInput.error('expected $name expression');
    } else if (hasUnknown) {
      final String unknown = (parserInput.$re(_directiveRegExp2) ?? '').trim();
      hasBlock = (parserInput.currentChar() == '{');
      if (unknown?.isNotEmpty ?? false)
          value = new Anonymous(unknown);
    }

    if (hasBlock)
        rules = blockRuleset();

    if (rules != null || (!hasBlock && value != null && parserInput.$char(';') != null)) {
      parserInput.forget();
      return new AtRule(name, value, rules, index, fileInfo,
          isNotEmpty(context.dumpLineNumbers) ? getDebugInfo(index) : null,
          isRooted: isRooted);
    }

    parserInput.restore('at-rule options not recognised');
    return null;

//2.8.0 20160713
// atrule: function () {
//     var index = parserInput.i, name, value, rules, nonVendorSpecificName,
//         hasIdentifier, hasExpression, hasUnknown, hasBlock = true, isRooted = true;
//
//     if (parserInput.currentChar() !== '@') { return; }
//
//     value = this['import']() || this.plugin() || this.media();
//     if (value) {
//         return value;
//     }
//
//     parserInput.save();
//
//     name = parserInput.$re(/^@[a-z-]+/);
//
//     if (!name) { return; }
//
//     nonVendorSpecificName = name;
//     if (name.charAt(1) == '-' && name.indexOf('-', 2) > 0) {
//         nonVendorSpecificName = "@" + name.slice(name.indexOf('-', 2) + 1);
//     }
//
//     switch(nonVendorSpecificName) {
//         case "@charset":
//             hasIdentifier = true;
//             hasBlock = false;
//             break;
//         case "@namespace":
//             hasExpression = true;
//             hasBlock = false;
//             break;
//         case "@keyframes":
//         case "@counter-style":
//             hasIdentifier = true;
//             break;
//         case "@document":
//         case "@supports":
//             hasUnknown = true;
//             isRooted = false;
//             break;
//         default:
//             hasUnknown = true;
//             break;
//     }
//
//     parserInput.commentStore.length = 0;
//
//     if (hasIdentifier) {
//         value = this.entity();
//         if (!value) {
//             error("expected " + name + " identifier");
//         }
//     } else if (hasExpression) {
//         value = this.expression();
//         if (!value) {
//             error("expected " + name + " expression");
//         }
//     } else if (hasUnknown) {
//         value = (parserInput.$re(/^[^{;]+/) || '').trim();
//         hasBlock = (parserInput.currentChar() == '{');
//         if (value) {
//             value = new(tree.Anonymous)(value);
//         }
//     }
//
//     if (hasBlock) {
//         rules = this.blockRuleset();
//     }
//
//     if (rules || (!hasBlock && value && parserInput.$char(';'))) {
//         parserInput.forget();
//         return new (tree.AtRule)(name, value, rules, index, fileInfo,
//             context.dumpLineNumbers ? getDebugInfo(index) : null,
//             isRooted
//         );
//     }
//
//     parserInput.restore("at-rule options not recognised");
// },
  }

  ///
  /// A Value is a comma-delimited list of Expressions
  ///
  ///     font-family: Baskerville, Georgia, serif;
  ///
  /// In a Rule, a Value represents everything after the `:`,
  /// and before the `;`.
  ///
  Value value() {
    Expression              e;
    final List<Expression>  expressions = <Expression>[];

    do {
      e = expression();
      if (e != null) {
        expressions.add(e);
        if (parserInput.$char(',') == null)
            break;
      }
    } while (e != null);

    if (expressions.isNotEmpty)
        return new Value(expressions);
    return null;

//2.2.0
//  value: function () {
//      var e, expressions = [];
//
//      do {
//          e = this.expression();
//          if (e) {
//              expressions.push(e);
//              if (! parserInput.$char(',')) { break; }
//          }
//      } while(e);
//
//      if (expressions.length > 0) {
//          return new(tree.Value)(expressions);
//      }
//  }
  }

  static final RegExp _importantRegExp1 = new RegExp(r'! *important', caseSensitive: true);

  ///
  String important() {
    if (parserInput.currentChar() == '!') {
      return parserInput.$re(_importantRegExp1);
    }
    return null;

//2.2.0
//  important: function () {
//      if (parserInput.currentChar() === '!') {
//          return parserInput.$re(/^! *important/);
//      }
//  }
  }

  ///
  Expression sub() {
    Node a;

    parserInput.save();
    if (parserInput.$char('(') != null) {
      a = addition();
      if (a != null && parserInput.$char(')') != null) {
        parserInput.forget();
        return new Expression(<Node>[a])
            ..parens = true;
      }
      parserInput.restore("Expected ')'");
      return null;
    }
    parserInput.restore();
    return null;

//2.2.0
//  sub: function () {
//      var a, e;
//
//    parserInput.save();
//      if (parserInput.$char('(')) {
//          a = this.addition();
//          if (a && parserInput.$char(')')) {
//            parserInput.forget();
//            e = new(tree.Expression)([a]);
//            e.parens = true;
//              return e;
//          }
//        parserInput.restore("Expected ')'");
//        return;
//      }
//    parserInput.restore();
//  }
  }

  static final RegExp _reMultiplication = new RegExp(r'\/[*\/]');

  ///
  Node multiplication() {
    Node      a;
    bool      isSpaced;
    Node      m;
    String    op;
    Operation operation;

    m = operand();
    if (m != null) {
      isSpaced = parserInput.isWhitespacePrevPos();
      while (true) {
        if (parserInput.peek(_reMultiplication))
            break;

        parserInput.save();

        op = parserInput.$char('/')
            ?? parserInput.$char('*');
        if (op == null) {
          parserInput.forget();
          break;
        }

        a = operand();
        if (a == null) {
          parserInput.restore();
          break;
        }

        parserInput.forget();
        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op,
            <Node>[operation != null ? operation : m, a],
            isSpaced: isSpaced);
        isSpaced = parserInput.isWhitespacePrevPos();
      }
      return operation ?? m;
    }
    return null;

//2.2.0
//  multiplication: function () {
//      var m, a, op, operation, isSpaced;
//      m = this.operand();
//      if (m) {
//          isSpaced = parserInput.isWhitespace(-1);
//          while (true) {
//              if (parserInput.peek(/^\/[*\/]/)) {
//                  break;
//              }
//
//              parserInput.save();
//
//              op = parserInput.$char('/') || parserInput.$char('*');
//
//              if (!op) { parserInput.forget(); break; }
//
//              a = this.operand();
//
//              if (!a) { parserInput.restore(); break; }
//              parserInput.forget();
//
//              m.parensInOp = true;
//              a.parensInOp = true;
//              operation = new(tree.Operation)(op, [operation || m, a], isSpaced);
//              isSpaced = parserInput.isWhitespace(-1);
//          }
//          return operation || m;
//      }
//  }
  }

  static final RegExp _additionRegExp1 = new RegExp(r'[-+]\s+', caseSensitive: true);

  ///
  Node addition() {
    Node      a;
    Node      m;
    String    op;
    Operation operation;
    bool      isSpaced;

    m = multiplication();
    if (m != null) {
      isSpaced = parserInput.isWhitespacePrevPos();
      while (true) {
        op = parserInput.$re(_additionRegExp1);
        if (op == null && !isSpaced)
            op = parserInput.$char('+');
        if (op == null && !isSpaced)
            op = parserInput.$char('-');
        if (op == null)
            break;

        a = multiplication();
        if (a == null)
            break;

        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op,
            <Node>[operation != null ? operation : m, a],
            isSpaced: isSpaced);
        isSpaced = parserInput.isWhitespacePrevPos();
      }
      return operation ?? m;
    }
    return null;

//2.2.0
//  addition: function () {
//      var m, a, op, operation, isSpaced;
//      m = this.multiplication();
//      if (m) {
//          isSpaced = parserInput.isWhitespace(-1);
//          while (true) {
//              op = parserInput.$re(/^[-+]\s+/) || (!isSpaced && (parserInput.$char('+') || parserInput.$char('-')));
//              if (!op) {
//                  break;
//              }
//              a = this.multiplication();
//              if (!a) {
//                  break;
//              }
//
//              m.parensInOp = true;
//              a.parensInOp = true;
//              operation = new(tree.Operation)(op, [operation || m, a], isSpaced);
//              isSpaced = parserInput.isWhitespace(-1);
//          }
//          return operation || m;
//      }
//  }
  }

  static final RegExp _reConditions = new RegExp(r',\s*(not\s*)?\(', caseSensitive: true);

  ///
  //to be passed to currentChunk.expect
  Node conditions() {
    Node      a;
    Node      b;
    Condition condition;
    final int index = parserInput.i;

    a = this.condition();
    if (a != null) {
      while (true) {
        if (!parserInput.peek(_reConditions) || (parserInput.$char(',') == null))
            break;
        b = this.condition();
        if (b == null)
            break;

        condition = new Condition('or', condition != null ? condition : a, b,
            index: index);
      }
      return condition ?? a;
    }

    return null;

//2.2.0
//  conditions: function () {
//      var a, b, index = parserInput.i, condition;
//
//      a = this.condition();
//      if (a) {
//          while (true) {
//              if (!parserInput.peek(/^,\s*(not\s*)?\(/) || !parserInput.$char(',')) {
//                  break;
//              }
//              b = this.condition();
//              if (!b) {
//                  break;
//              }
//              condition = new(tree.Condition)('or', condition || a, b, index);
//          }
//          return condition || a;
//      }
//  }
  }

  ///
  Condition condition() {
    String or() => parserInput.$str("or");

    Condition result = conditionAnd();
    if (result == null)
        return null;

    final String logical = or();
    if (logical != null) {
      final Condition next = condition();
      if (next != null) {
        result = new Condition(logical, result, next);
      } else {
        return null;
      }
    }
    return result;

//2.5.3 20160117
// condition: function () {
//     var result, logical, next;
//     function or() {
//         return parserInput.$str("or");
//     }
//
//     result = this.conditionAnd(this);
//     if (!result) {
//         return ;
//     }
//     logical = or();
//     if (logical) {
//         next = this.condition();
//         if (next) {
//             result = new(tree.Condition)(logical, result, next);
//         } else {
//             return ;
//         }
//     }
//     return result;
// },
  }

  ///
  Condition conditionAnd() {
    Condition insideCondition() => negatedCondition() ?? parenthesisCondition();
    String and() => parserInput.$str("and");

    Condition result = insideCondition();
    if (result == null)
        return null;

    final String logical = and();
    if (logical != null) {
      final Condition next = conditionAnd();
      if (next != null) {
        result = new Condition(logical, result, next);
      } else {
        return null;
      }
    }
    return result;

//2.5.3 20160117
// conditionAnd: function () {
//     var result, logical, next;
//     function insideCondition(me) {
//         return me.negatedCondition() || me.parenthesisCondition();
//     }
//     function and() {
//         return parserInput.$str("and");
//     }
//
//     result = insideCondition(this);
//     if (!result) {
//         return ;
//     }
//     logical = and();
//     if (logical) {
//         next = this.conditionAnd();
//         if (next) {
//             result = new(tree.Condition)(logical, result, next);
//         } else {
//             return ;
//         }
//     }
//     return result;
// },
  }

  ///
  Condition negatedCondition() {
    if (parserInput.$str("not") != null) {
      final Condition result = parenthesisCondition();
      if (result != null)
          result.negate = !result.negate;
      return result;
    }
    return null;

//2.5.3 20160114
// negatedCondition: function () {
//     if (parserInput.$str("not")) {
//         var result = this.parenthesisCondition();
//         if (result) {
//             result.negate = !result.negate;
//         }
//         return result;
//     }
// },
  }

  ///
  Condition parenthesisCondition() {
    //
    Condition tryConditionFollowedByParenthesis() {
      parserInput.save();
      final Condition body = condition();
      if (body == null) {
        parserInput.restore();
        return null;
      }
      if (parserInput.$char(')') == null) {
        parserInput.restore();
        return null;
      }
      parserInput.forget();
      return body;
    }

    parserInput.save();
    if (parserInput.$str("(") == null) {
      parserInput.restore();
      return null;
    }

    Condition body = tryConditionFollowedByParenthesis();
    if (body != null) {
      parserInput.forget();
      return body;
    }

    body = atomicCondition();
    if (body == null) {
      parserInput.restore();
      return null;
    }
    if (parserInput.$char(')') == null) {
      parserInput.restore("expected ')' got '${parserInput.currentChar()}'");
      return null;
    }
    parserInput.forget();
    return body;

//2.6.0 20160217
// parenthesisCondition: function () {
//     function tryConditionFollowedByParenthesis(me) {
//         var body;
//         parserInput.save();
//         body = me.condition();
//         if (!body) {
//             parserInput.restore();
//             return ;
//         }
//         if (!parserInput.$char(')')) {
//             parserInput.restore();
//             return ;
//         }
//         parserInput.forget();
//         return body;
//     }
//
//     var body;
//     parserInput.save();
//     if (!parserInput.$str("(")) {
//         parserInput.restore();
//         return ;
//     }
//     body = tryConditionFollowedByParenthesis(this);
//     if (body) {
//         parserInput.forget();
//         return body;
//     }
//
//     body = this.atomicCondition();
//     if (!body) {
//         parserInput.restore();
//         return ;
//     }
//     if (!parserInput.$char(')')) {
//         parserInput.restore("expected ')' got '" + parserInput.currentChar() + "'");
//         return ;
//     }
//     parserInput.forget();
//     return body;
// },
  }

  ///
  Condition atomicCondition() {
    Node      a;
    Node      b;
    Condition c;
    final int index = parserInput.i;
    String    op;

    a = addition()
        ?? entities.keyword()
        ?? entities.quoted();

    if (a != null) {
      if (parserInput.$char('>') != null) {
        if (parserInput.$char('=') != null) {
          op = '>=';
        } else {
          op = '>';
        }
      } else if (parserInput.$char('<') != null) {
        if (parserInput.$char('=') != null) {
          op = '<=';
        } else {
          op = '<';
        }
      } else if (parserInput.$char('=') != null) {
        if (parserInput.$char('>') != null) {
          op = '=>';
        } else if (parserInput.$char('<') != null) {
          op = '=<';
        } else {
          op = '=';
        }
      }

      if (op != null) {
        b = addition()
            ?? entities.keyword()
            ?? entities.quoted();

        if (b != null) {
          c = new Condition(op, a, b, index: index);
        } else {
          parserInput.error('expected expression');
        }
      } else {
        c = new Condition('=', a, new Keyword.True(), index: index);
      }
      return c;
    }
    return null;

//2.5.3 20160114
// atomicCondition: function () {
//     var entities = this.entities, index = parserInput.i, a, b, c, op;
//
//     a = this.addition() || entities.keyword() || entities.quoted();
//     if (a) {
//         if (parserInput.$char('>')) {
//             if (parserInput.$char('=')) {
//                 op = ">=";
//             } else {
//                 op = '>';
//             }
//         } else
//         if (parserInput.$char('<')) {
//             if (parserInput.$char('=')) {
//                 op = "<=";
//             } else {
//                 op = '<';
//             }
//         } else
//         if (parserInput.$char('=')) {
//             if (parserInput.$char('>')) {
//                 op = "=>";
//             } else if (parserInput.$char('<')) {
//                 op = '=<';
//             } else {
//                 op = '=';
//             }
//         }
//         if (op) {
//             b = this.addition() || entities.keyword() || entities.quoted();
//             if (b) {
//                 c = new(tree.Condition)(op, a, b, index, false);
//             } else {
//                 error('expected expression');
//             }
//         } else {
//             c = new(tree.Condition)('=', a, new(tree.Keyword)('true'), index, false);
//         }
//         return c;
//     }
// },
  }

  static final RegExp _reOperand = new RegExp(r'-[@\(]');

  ///
  /// An operand is anything that can be part of an operation,
  /// such as a Color, or a Variable
  ///
  Node operand() {
    String  negate;
    Node    o;

    if (parserInput.peek(_reOperand))
        negate = parserInput.$char('-');

    o = sub()
        ?? entities.dimension()
        ?? entities.color()
        ?? entities.variable()
        ?? entities.call()
        ?? entities.colorKeyword();

    if (negate != null) {
      o.parensInOp = true;
      o = new Negative(o);
    }

    return o;

//2.6.0 20160206
//
// An operand is anything that can be part of an operation,
// such as a Color, or a Variable
//
// operand: function () {
//     var entities = this.entities, negate;
//
//     if (parserInput.peek(/^-[@\(]/)) {
//         negate = parserInput.$char('-');
//     }
//
//     var o = this.sub() || entities.dimension() ||
//             entities.color() || entities.variable() ||
//             entities.call() || entities.colorKeyword();
//
//     if (negate) {
//         o.parensInOp = true;
//         o = new(tree.Negative)(o);
//     }
//
//     return o;
// },

//2.5.3 20160115
//
// An operand is anything that can be part of an operation,
// such as a Color, or a Variable
//
// operand: function () {
//     var entities = this.entities, negate;
//
//     if (parserInput.peek(/^-[@\(]/)) {
//         negate = parserInput.$char('-');
//     }
//
//     var o = this.sub() || entities.dimension() ||
//             entities.variable() ||
//             entities.call() || entities.color();
//
//     if (negate) {
//         o.parensInOp = true;
//         o = new(tree.Negative)(o);
//     }
//
//     return o;
// },
  }

  static final RegExp _reExpression = new RegExp(r'\/[\/*]');

  ///
  /// Expressions either represent mathematical operations,
  /// or white-space delimited Entities.
  ///
  ///     1px solid black
  ///     @var * 2
  ///
  Expression expression() {
    String            delim;
    Node              e;
    final List<Node>  entities = <Node>[];

    do {
      e = comment();
      if (e != null) {
        entities.add(e);
        continue;
      }

      e = addition()
          ?? entity();

      if (e != null) {
        entities.add(e);
        // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
        if (!parserInput.peek(_reExpression)) {
          delim = parserInput.$char('/');
          if (delim != null)
              entities.add(new Anonymous(delim));
        }
      }
    } while (e != null);
    if (entities.isNotEmpty)
        return new Expression(entities);

    return null;

//2.2.0
//  expression: function () {
//      var entities = [], e, delim;
//
//      do {
//          e = this.comment();
//          if (e) {
//              entities.push(e);
//              continue;
//          }
//          e = this.addition() || this.entity();
//          if (e) {
//              entities.push(e);
//              // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
//              if (!parserInput.peek(/^\/[\/*]/)) {
//                  delim = parserInput.$char('/');
//                  if (delim) {
//                      entities.push(new(tree.Anonymous)(delim));
//                  }
//              }
//          }
//      } while (e);
//      if (entities.length > 0) {
//          return new(tree.Expression)(entities);
//      }
//  }
  }

  static final RegExp _propertyRegExp1 = new RegExp(r'(\*?-?[_a-zA-Z0-9-]+)\s*:', caseSensitive: true);

  ///
  String property() => parserInput.$re(_propertyRegExp1);

//2.2.0
//  property: function () {
//      var name = parserInput.$re(/^(\*?-?[_a-zA-Z0-9-]+)\s*:/);
//      if (name) {
//          return name[1];
//      }
//  }

  static final RegExp _rulePropertyRegExp1 = new RegExp(r'([_a-zA-Z0-9-]+)\s*:', caseSensitive: true);
  static final RegExp _rulePropertyRegExp2 = new RegExp(r'(\*?)', caseSensitive: true);
  static final RegExp _rulePropertyRegExp3 = new RegExp(r'((?:[\w-]+)|(?:@\{[\w-]+\}))', caseSensitive: true);
  static final RegExp _rulePropertyRegExp4 = new RegExp(r'((?:\+_|\+)?)\s*:', caseSensitive: true);

  ///
  List<Node> ruleProperty() {
    final List<int>     index = <int>[];
    final List<String>  name = <String>[];
    final List<Node>    result = <Node>[];  //in js is name
    String              s;

    parserInput.save();

    final String simpleProperty = parserInput.$re(_rulePropertyRegExp1);
    if (simpleProperty != null) {
      result.add(new Keyword(simpleProperty));
      parserInput.forget();
      return result;
    }

    bool match(RegExp re) {
      final int i = parserInput.i;
      final String chunk = parserInput.$re(re);

      if (chunk != null) {
        index.add(i);
        name.add(chunk);
        return true;
      }
      return false;
    }

    match(_rulePropertyRegExp2);
    while (true) {
      if (!match(_rulePropertyRegExp3))
          break;
    }

    if (name.length > 1 && match(_rulePropertyRegExp4)) {
      parserInput.forget();

      // at last, we have the complete match now. move forward,
      // convert name particles to tree objects and return:
      if (name[0] == '') {
        name.removeAt(0);
        index.removeAt(0);
      }
      for (int k = 0; k < name.length; k++) {
        s = name[k];
        result.add((!s.startsWith('@'))
            ? new Keyword(s)
            : new Variable('@${s.substring(2, (s.length - 1))}', index[k], fileInfo)
        );
      }
      return result;
    }
    parserInput.restore();
    return null;

//2.4.0 20150315 1739
//  ruleProperty: function () {
//      var name = [], index = [], s, k;
//
//      parserInput.save();
//
//      var simpleProperty = parserInput.$re(/^([_a-zA-Z0-9-]+)\s*:/);
//      if (simpleProperty) {
//          name = [new(tree.Keyword)(simpleProperty[1])];
//          parserInput.forget();
//          return name;
//      }
//
//      function match(re) {
//          var i = parserInput.i,
//              chunk = parserInput.$re(re);
//          if (chunk) {
//              index.push(i);
//              return name.push(chunk[1]);
//          }
//      }
//
//      match(/^(\*?)/);
//      while (true) {
//          if (!match(/^((?:[\w-]+)|(?:@\{[\w-]+\}))/)) {
//              break;
//          }
//      }
//
//      if ((name.length > 1) && match(/^((?:\+_|\+)?)\s*:/)) {
//          parserInput.forget();
//
//          // at last, we have the complete match now. move forward,
//          // convert name particles to tree objects and return:
//          if (name[0] === '') {
//              name.shift();
//              index.shift();
//          }
//          for (k = 0; k < name.length; k++) {
//              s = name[k];
//              name[k] = (s.charAt(0) !== '@') ?
//                  new(tree.Keyword)(s) :
//                  new(tree.Variable)('@' + s.slice(2, -1),
//                        index[k], fileInfo);
//            }
//            return name;
//        }
//        parserInput.restore();
//    }
//}
  }

  ///
  /// Returns filename and line corresponding to [index]
  ///
  // less/parser.js 2.2.0 lines 76-84
  DebugInfo getDebugInfo(int index, [String xinputStream, Contexts xcontext]) =>
      new DebugInfo(
          lineNumber: Utils.getLocation(index, input).line + 1,
          fileName: fileInfo.filename);

//2.2.0
//  function getDebugInfo(index) {
//      var filename = fileInfo.filename;
//
//
//      return {
//          lineNumber: utils.getLocation(index, parserInput.getInput()).line + 1,
//          fileName: filename
//      };
//  }
}
