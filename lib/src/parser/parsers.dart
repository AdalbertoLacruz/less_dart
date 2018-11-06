//source: less/parser/parser.js ines 250-end 3.5.0.beta.7 20180704

part of parser.less;

///
/// Here in, the parsing rules/functions
///
/// The basic structure of the syntax tree generated is as follows:
///
///   `Ruleset ->  Declaration -> Value -> Expression -> Entity`
///
/// Here's some Less code:
///
///     .class {
///       color: #fff;
///       border: 1px solid #000;
///       width: @w + 4px;
///       > .child {...}
///     }
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
  /// Environment variables
  Contexts    context;

  /// Reference to Entities class with additional parser functions
  Entities    entities;

  /// Data about the file being parsed
  FileInfo    fileInfo;

  /// String to be parsed
  String      input;

  /// Mixin class reference with additional parser functions
  Mixin       mixin;

  /// Input management
  ParserInput parserInput;

  ///
  /// The Parsers class constructor.
  ///
  /// [input] is the String to be parsed
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
        if (node == null) break;
        root.add(node);
      }

      // always process comments before deciding if finished
      if (parserInput.finished || parserInput.isEmpty) break;
      if (parserInput.peekChar('}')) break;

      nodeList = extendRule();
      if (nodeList != null) {
        root.addAll(nodeList);
        continue;
      }

      node = mixin.definition()
          ?? declaration()
          ?? ruleset()
          ?? mixin.call(inValue: false, getLookup: false)
          ?? variableCall()
          ?? entities.call()
          ?? atrule();

      if (node != null) {
        root.add(node);
      } else {
        bool foundSemiColon = false;
        while (parserInput.$char(';') != null) {
          foundSemiColon = true;
        }
        if (!foundSemiColon) break;
      }
    }

    return root;

// 3.5.0.beta.5 20180702
//  primary: function () {
//      var mixin = this.mixin, root = [], node;
//
//      while (true) {
//          while (true) {
//              node = this.comment();
//              if (!node) { break; }
//              root.push(node);
//          }
//          // always process comments before deciding if finished
//          if (parserInput.finished) {
//              break;
//          }
//          if (parserInput.peek('}')) {
//              break;
//          }
//
//          node = this.extendRule();
//          if (node) {
//              root = root.concat(node);
//              continue;
//          }
//
//          node = mixin.definition() || this.declaration() || this.ruleset() ||
//              mixin.call(false, false) || this.variableCall() || this.entities.call() || this.atrule();
//          if (node) {
//              root.push(node);
//          } else {
//              var foundSemiColon = false;
//              while (parserInput.$char(';')) {
//                  foundSemiColon = true;
//              }
//              if (!foundSemiColon) {
//                  break;
//              }
//          }
//      }
//
//      return root;
//  },
  }

  ///
  /// Check if input is empty. Else throw error.
  ///
  void isFinished() => parserInput.isFinished();

  ///
  /// Comments are collected by the main parsing mechanism and then assigned to nodes
  /// where the current structure allows it
  ///
  /// CSS comments:
  ///
  ///     /* */
  ///
  /// LeSS comments:
  ///
  ///     //
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
        (name = parserInput.$re(_variableRegExp)) != null) {
      return name;
    }
    return null;

//2.2.0
//  variable: function () {
//      var name;
//
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^(@[\w-]+)\s*:/))) { return name[1]; }
//  }
  }

  // static final RegExp _variableCallRegExp = new RegExp(r'(@[\w-]+)\(\s*\)', caseSensitive: true);
  static final RegExp _variableCallRegExp = new RegExp(r'(@[\w-]+)(\(\s*\))?', caseSensitive: true);

  ///
  /// Call a variable value to retrieve a detached ruleset
  /// or a value from a detached ruleset's rules.
  ///
  ///     @fink();
  ///     @fink;
  ///     color: @fink[@color];
  ///
  Node variableCall([String parsedName]) {
    final int    index = parserInput.i;
    bool         important = false;
    final bool   inValue = parsedName != null;
    String       name = parsedName;
    List<String> lsName; // Each () matched in regExp

    parserInput.save();
    if ((inValue) ||
        (parserInput.currentChar() == '@' &&
            (lsName = parserInput.$re(_variableCallRegExp)) != null)) {

      final List<String> lookups = mixin.ruleLookups();

      if (lookups == null && lsName?.elementAt(2) != '()') {  // lsName[2]
        parserInput.restore("Missing '[...]' lookup in variable call");
        return null;
      }

      if (!inValue) name = lsName[1];
      
      if ((lookups != null) && (this.important() != null)) important = true;
      
      final VariableCall call = new VariableCall(name, index, fileInfo);

      if (!inValue && end()) {
        parserInput.forget();
        return call;
      } else {
        parserInput.forget();
        return new NamespaceValue(call, lookups,
            index: index, fileInfo: fileInfo, important: important);
      }
    }

    parserInput.restore();
    return null;

// 3.5.0.beta.4 20180630
//  variableCall: function (parsedName) {
//      var lookups, important, i = parserInput.i,
//          inValue = !!parsedName, name = parsedName;
//
//      parserInput.save();
//
//      if (name || (parserInput.currentChar() === '@'
//          && (name = parserInput.$re(/^(@[\w-]+)(\(\s*\))?/)))) {
//
//          lookups = this.mixin.ruleLookups();
//
//          if (!lookups && name[2] !== '()') {
//              parserInput.restore('Missing \'[...]\' lookup in variable call');
//              return;
//          }
//
//          if (!inValue) {
//              name = name[1];
//          }
//
//          if (lookups && parsers.important()) {
//              important = true;
//          }
//
//          var call = new tree.VariableCall(name, i, fileInfo);
//          if (!inValue && parsers.end()) {
//              parserInput.forget();
//              return call;
//          }
//          else {
//              parserInput.forget();
//              return new tree.NamespaceValue(call, lookups, important, i, fileInfo);
//          }
//      }
//
//      parserInput.restore();
//  },
  }

  static final RegExp _extendRegExp = new RegExp(r'(all)(?=\s*(\)|,))', caseSensitive: true);

  ///
  /// extend syntax - used to extend selectors:
  ///
  ///     :extend( )
  ///
  List<Extend> extend({bool isRule = false}) {
    Element       e;
    List<Element> elements;
    List<Extend>  extendedList;
    final int     index = parserInput.i;
    String        option;

    if (parserInput.$str(isRule ? '&:extend(' : ':extend(') ==  null) {
      return null;
    }

    do {
      option = null;
      elements = null;
      while ((option = parserInput.$re(_extendRegExp, 1)) == null) {
        e = element();
        if (e == null) break;

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
    if (isRule) parserInput.expectChar(';');

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

  ///
  /// extendRule - used in a rule to extend all the parent selectors
  ///
  List<Extend> extendRule() => extend(isRule: true);

  ///
  /// Entities are the smallest recognized token,
  /// and can be found inside a rule's value.
  ///
  Node entity() => comment()
        ?? entities.literal()
        ?? entities.variable()
        ?? entities.url()
        ?? entities.property()
        ?? entities.call()
        ?? entities.keyword()
        ?? mixin.call(inValue: true)
        ?? entities.javascript();

// 3.5.0.beta.5 20180702
//  entity: function () {
//      var entities = this.entities;
//
//      return this.comment() || entities.literal() || entities.variable() || entities.url() ||
//          entities.property() || entities.call() || entities.keyword() || this.mixin.call(true) ||
//          entities.javascript();
//  },

  ///
  /// A Declaration terminator.
  ///
  /// Note that the `peek()` use to check for `}`,
  /// because the `block` rule will be expecting it, but we still need to make sure
  /// it's there, if `;` was omitted.
  ///
  bool end() => (parserInput.$char(';') != null) || parserInput.peekChar('}');

//2.2.0
//  end: function () {
//      return parserInput.$char(';') || parserInput.peek('}');
//  }

//
//alphaIe: see entities.alphaIe()
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
        if ((v = selector(isLess: false)) != null && parserInput.$char(')') != null) {
          e = new Paren(v);
          parserInput.forget();
        } else {
          parserInput.restore("Missing closing ')'");
        }
      } else {
        parserInput.forget();
      }
    }

    return (e != null)
        ? new Element(c, e,
            isVariable: e is Variable,
            index: index,
            currentFileInfo: fileInfo)
        : null;

// 3.5.0.beta 20180625
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
//      if (!e) {
//          parserInput.save();
//          if (parserInput.$char('(')) {
//              if ((v = this.selector(false)) && parserInput.$char(')')) {
//                  e = new(tree.Paren)(v);
//                  parserInput.forget();
//              } else {
//                  parserInput.restore('Missing closing \')\'');
//              }
//          } else {
//              parserInput.forget();
//          }
//      }
//
//      if (e) { return new(tree.Element)(c, e, e instanceof tree.Variable, index, fileInfo); }
//  },
  }

  static final RegExp _combinatorRegExp1 = new RegExp(r'\/[a-z]+\/', caseSensitive: false);

  ///
  /// Combinators combine elements together, in a Selector.
  ///
  /// Because the parser isn't white-space sensitive, special care
  /// has to be taken, when parsing the descendant combinator, ` `,
  /// as it's an empty space. We have to check the previous character
  /// in the input, to see if it's a ` ` character. More info on how
  /// we deal with this in *combinator.dart*.
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
  /// A CSS Selector
  ///
  /// with less extensions e.g. the ability to extend and guard
  ///
  ///     .class > div + h1
  ///     li a:hover
  ///
  /// Selectors are made out of one or more Elements, see above.
  ///
  Selector selector({bool isLess = true}) {
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
        if (allExtends != null) {
          parserInput.error('Extend can only be used at the end of selector');
        }
        c = parserInput.currentChar();
        (elements ??= <Element>[])
            ..add(e);
        e = null;
      }
      if (c == '{' || c == '}' || c == ';' || c == ',' || c == ')' ) break;
    }

    if (elements != null) {
      return new Selector(elements,
          extendList: allExtends,
          condition: condition,
          index: index,
          currentFileInfo: fileInfo);
    }
    if (allExtends != null) {
      parserInput.error(
          'Extend must be used to extend a selector, it cannot be used on its own');
    }

    return null;

//3.0.0 20160719
// selector: function (isLess) {
//     var index = parserInput.i, elements, extendList, c, e, allExtends, when, condition;
//     isLess = isLess !== false;
//     while ((isLess && (extendList = this.extend())) || (isLess && (when = parserInput.$str("when"))) || (e = this.element())) {
//         if (when) {
//             condition = expect(this.conditions, 'expected condition');
//         } else if (condition) {
//             error("CSS guard can only be used at the end of selector");
//         } else if (extendList) {
//             if (allExtends) {
//                 allExtends = allExtends.concat(extendList);
//             } else {
//                 allExtends = extendList;
//             }
//         } else {
//             if (allExtends) { error("Extend can only be used at the end of selector"); }
//             c = parserInput.currentChar();
//             if (elements) {
//                 elements.push(e);
//             } else {
//                 elements = [ e ];
//             }
//             e = null;
//         }
//         if (c === '{' || c === '}' || c === ';' || c === ',' || c === ')') {
//             break;
//         }
//     }
//
//     if (elements) { return new(tree.Selector)(elements, allExtends, condition, index, fileInfo); }
//     if (allExtends) { error("Extend must be used to extend a selector, it cannot be used on its own"); }
// },
  }

  ///
  List<Selector> selectors() {
    Selector       s;
    List<Selector> selectors;

    while (true) {
      s = selector();
      if (s == null) break;

      // --polymer-mixin: {}
      // No standard js implementation
      if (parserInput.peekChar(':') && s.elements.length == 1) {
        if (s.elements[0].value is String && s.elements[0].value.startsWith('--')) {
          s.elements[0].value = '${s.elements[0].value}:';
          parserInput.$char(':'); //move pointer
        }
      }
      // End no standard

      (selectors ??= <Selector>[]).add(s);

      parserInput.commentStore.length = 0;
      if (s.condition != null && selectors.length > 1) {
        parserInput.error('Guards are only currently allowed on a single selector.');
      }
      if (parserInput.$char(',') == null) break;
      if (s.condition != null) {
        parserInput.error('Guards are only currently allowed on a single selector.');
      }
      parserInput.commentStore.length = 0;
    }
    return selectors;

// 3.5.0.beta 20180625
//  selectors: function () {
//      var s, selectors;
//      while (true) {
//          s = this.selector();
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
//          if (!parserInput.$char(',')) { break; }
//          if (s.condition) {
//              error("Guards are only currently allowed on a single selector.");
//          }
//          parserInput.commentStore.length = 0;
//      }
//      return selectors;
//  },
  }

  static final RegExp _attributeRegExp1 = new RegExp(r'[|~*$^]?=', caseSensitive: true);
  static final RegExp _attributeRegExp2 = new RegExp(r'[0-9]+%', caseSensitive: true);
  static final RegExp _attributeRegExp3 = new RegExp(r'[\w-]+', caseSensitive: true);
  static final RegExp _attributeRegExp4 = new RegExp(r'(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+');

  ///
  /// Attribute is a operation inside `[]`:
  ///
  ///     [key operator value]
  ///
  /// Example:
  ///
  ///     [type = "text"]
  ///
  Attribute attribute() {
    if (parserInput.$char('[') == null) return null;

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
  ///
  /// It's a wrapper around the `primary` rule, with added `{}`.
  ///
  List<Node> block() {
    List<Node> content;

    if (parserInput.$char('{') != null
        && (content = primary()) != null
        && parserInput.$char('}') != null) {
      return content;
    }
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
  /// The rules inside the:
  ///
  ///     { rules }
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
  /// Search for
  ///
  ///     { rules }
  ///
  DetachedRuleset detachedRuleset() {
    final Ruleset blockRuleset = this.blockRuleset();
    return (blockRuleset != null) ? new DetachedRuleset(blockRuleset) : null;

// 3.5.0.beta.7 20180704
//  detachedRuleset: function() {
//      var blockRuleset = this.blockRuleset();
//      if (blockRuleset) {
//          return new tree.DetachedRuleset(blockRuleset);
//      }
//  },
  }

  ///
  /// A Ruleset is something like:
  ///
  ///     div, .class, body > p {...}
  ///
  /// It has selectors and rules:
  ///
  ///     selectors { rules }
  ///
  Ruleset ruleset() {
    DebugInfo  debugInfo;
    List<Node> rules;

    parserInput.save();

    if (isNotEmpty(context.dumpLineNumbers)) {
      debugInfo = getDebugInfo(parserInput.i);
    }

    final List<Selector> selectors = this.selectors();

    if (selectors != null && (rules = block()) != null) {
      parserInput.forget();
      final Ruleset ruleset = new Ruleset(selectors, rules,
          strictImports: context.strictImports);
      if (context.dumpLineNumbers?.isNotEmpty ?? false) {
        ruleset.debugInfo = debugInfo;
      }
      return ruleset;
    } else {
      parserInput.restore();
    }
    return null;

// 3.5.0.beta 20180625
//  ruleset: function () {
//      var selectors, rules, debugInfo;
//
//      parserInput.save();
//
//      if (context.dumpLineNumbers) {
//          debugInfo = getDebugInfo(parserInput.i);
//      }
//
//      selectors = this.selectors();
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
  /// Declaration is
  ///
  ///     property: value;
  ///     @variable: value;
  ///
  /// Example:
  ///
  ///     color: red;
  ///
  Declaration declaration() {
    final String  c = parserInput.currentChar();
    bool          hasDR = false; // has DetachedRuleset
    String        important;
    final int     index = parserInput.i;
    bool          isVariable;
    String        merge = '';
    dynamic       name; //String or List<Node>
    Node          value;

    if (c == '.' || c == '#' || c == '&' || c == ':') return null;

    parserInput.save();

    name = variable()
        ?? ruleProperty();

    if (name != null) {
      isVariable = name is String;

      if (isVariable) {
        value = detachedRuleset();
        if (value != null) hasDR = true;
      }

      parserInput.commentStore.length = 0;
      if (value == null) {
        // a name returned by this.ruleProperty() is always an array of the form:
        // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
        // where each item is a tree.Keyword or tree.Variable
        merge = (!isVariable && name.length > 1)
            ? (name as List<Node>).removeLast().value
            : '';

        // Custom property values get permissive parsing
        if ((name is List) && (name.first.value is String) && (name.first.value as String).startsWith('--')) {
          value = permissiveValue();
        } else {
          // Try to store values as anonymous
          // If we need the value later we'll re-parse it in ruleset.parseValue
          value = anonymousValue();
        }

        if (value != null) {
          parserInput.forget();
          // anonymous values absorb the end ';' which is required for them to work
          return new Declaration(name, value,
                  important: '',
                  merge: merge,
                  index: index,
                  currentFileInfo: fileInfo);
        }

        value ??= this.value();

        // As a last resort, let a variable try to be parsed as a permissive value
        if (value == null && isVariable) value = permissiveValue();

        important = this.important();
      }

      if (value != null && (end() || hasDR)) {
        parserInput.forget();
        return new Declaration(name, value,
            important: important,
            merge: merge,
            index: index,
            currentFileInfo: fileInfo);
      } else {
        parserInput.restore();
      }
    } else {
      parserInput.restore();
    }

    return null;

// 3.5.0.beta.5 20180702
//  declaration: function () {
//      var name, value, index = parserInput.i, hasDR,
//          c = parserInput.currentChar(), important, merge, isVariable;
//
//      if (c === '.' || c === '#' || c === '&' || c === ':') { return; }
//
//      parserInput.save();
//
//      name = this.variable() || this.ruleProperty();
//      if (name) {
//          isVariable = typeof name === 'string';
//
//          if (isVariable) {
//              value = this.detachedRuleset();
//              if (value) {
//                  hasDR = true;
//              }
//          }
//
//          parserInput.commentStore.length = 0;
//          if (!value) {
//              // a name returned by this.ruleProperty() is always an array of the form:
//              // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
//              // where each item is a tree.Keyword or tree.Variable
//              merge = !isVariable && name.length > 1 && name.pop().value;
//
//              // Custom property values get permissive parsing
//              if (name[0].value && name[0].value.slice(0, 2) === '--') {
//                  value = this.permissiveValue();
//              }
//              // Try to store values as anonymous
//              // If we need the value later we'll re-parse it in ruleset.parseValue
//              else {
//                  value = this.anonymousValue();
//              }
//              if (value) {
//                  parserInput.forget();
//                  // anonymous values absorb the end ';' which is required for them to work
//                  return new (tree.Declaration)(name, value, false, merge, index, fileInfo);
//              }
//
//              if (!value) {
//                  value = this.value();
//              }
//              // As a last resort, try permissiveValue
//              if (!value && isVariable) {
//                  value = this.permissiveValue();
//              }
//
//              important = this.important();
//          }
//
//          if (value && (this.end() || hasDR)) {
//              parserInput.forget();
//              return new (tree.Declaration)(name, value, important, merge, index, fileInfo);
//          }
//          else {
//              parserInput.restore();
//          }
//      } else {
//          parserInput.restore();
//      }
//  },
  }

  static final RegExp _anonymousValueRegExp1 = new RegExp(r'''([^.#@\$+\/'"*`(;{}-]*);''', caseSensitive: false);

  ///
  /// Anonymous is almost anything. Example:
  ///
  ///     border: 2px solid superred
  ///
  /// returns as Anonymous
  ///
  ///     2px solid superred
  ///
  Anonymous anonymousValue() {
    final int index = parserInput.i;
    final String match = parserInput.$re(_anonymousValueRegExp1, 1);
    if (match != null) return new Anonymous(match, index: index);
    return null;

// 3.5.0.beta.4 20180630
//  anonymousValue: function () {
//      var index = parserInput.i;
//      var match = parserInput.$re(/^([^.#@\$+\/'"*`(;{}-]*);/);
//      if (match) {
//          return new(tree.Anonymous)(match[1], index);
//      }
//  },
  }

  ///
  /// Used for custom properties, at-rules, and variables (as fallback)
  /// Parses almost anything inside of {} [] () "" blocks
  /// until it reaches outer-most tokens.
  ///
  /// First, it will try to parse comments and entities to reach
  /// the end. This is mostly like the Expression parser except no
  /// math is allowed.
  ///
  Node permissiveValue({String untilTokensString, RegExp untilTokensRegExp}) {
    final int         index = parserInput.i;
    final List<Node>  result = <Node>[];

    final TestChar tc = new TestChar(untilTokensString, untilTokensRegExp);
    bool testCurrentChar() => tc.test(parserInput.currentChar());

    if (testCurrentChar()) return null;

    Node e;
    final List<Node> valueNodes = <Node>[];
    do {
      e = comment();
      if (e != null) {
        valueNodes.add(e);
        continue;
      }
      e = entity();
      if (e != null) valueNodes.add(e);
    } while (e != null);

    if (valueNodes.isNotEmpty) {
      final Expression expression = new Expression(valueNodes);
      if (testCurrentChar()) { // done
        return expression;
      } else {
        result.add(expression);
      }
      // Preserve space before $parseUntil as it will not
      if (parserInput.prevChar() == ' ') {
        result.add(new Anonymous(' ', index: index)); // fileInfo ?
      }
    }
    parserInput.save();

    List<ParseUntilReturnItem> value;
    try {
      value = parserInput.$parseUntil(tok: untilTokensString, tokre: untilTokensRegExp);
    } on ParserInputException catch(e) {
      if (e.expected != null) {
        parserInput.error("Expected '${e.expected}'", 'Parse');
      }
    }

    if (value != null) {
      if (value.length == 1 && value.single.isEnd) {
        parserInput.forget();
        return new Anonymous('', index: index);
      }

      for (int i = 0; i < value.length; i++) {
        final ParseUntilReturnItem item = value[i];

        if (item.quote != null) {
          // Treat actual quotes as normal quoted values
          result.add(new Quoted(item.quote, item.value,
              escaped: true, index: index, currentFileInfo: fileInfo));
        } else {
          if (i == value.length - 1) item.value = item.value.trim();

          // Treat like quoted values, but replace vars like unquoted expressions
          result.add(new Quoted("'",  item.value,
              escaped: true, index: index, currentFileInfo: fileInfo)
            ..variableRegex = new RegExp(r'@([\w-]+)')
            ..propRegex = new RegExp(r'\$([\w-]+)'));
//            ..reparse = true);
        }
      }
      parserInput.forget();
      return new Expression(result, noSpacing: true);
    }
    parserInput.restore();
    return null;

// 3.5.0.beta 20180627
//  permissiveValue: function (untilTokens) {
//      var i, e, done, value,
//          tok = untilTokens || ';',
//          index = parserInput.i, result = [];
//
//      function testCurrentChar() {
//          var char = parserInput.currentChar();
//          if (typeof tok === 'string') {
//              return char === tok;
//          } else {
//              return tok.test(char);
//          }
//      }
//      if (testCurrentChar()) {
//          return;
//      }
//      value = [];
//      do {
//          e = this.comment();
//          if (e) {
//              value.push(e);
//              continue;
//          }
//          e = this.entity();
//          if (e) {
//              value.push(e);
//          }
//      } while (e);
//
//      done = testCurrentChar();
//
//      if (value.length > 0) {
//          value = new(tree.Expression)(value);
//          if (done) {
//              return value;
//          }
//          else {
//              result.push(value);
//          }
//          // Preserve space before $parseUntil as it will not
//          if (parserInput.prevChar() === ' ') {
//              result.push(new tree.Anonymous(' ', index));
//          }
//      }
//      parserInput.save();
//
//      value = parserInput.$parseUntil(tok);
//
//      if (value) {
//          if (typeof value === 'string') {
//              error('Expected \'' + value + '\'', 'Parse');
//          }
//          if (value.length === 1 && value[0] === ' ') {
//              parserInput.forget();
//              return new tree.Anonymous('', index);
//          }
//          var item;
//          for (i = 0; i < value.length; i++) {
//              item = value[i];
//              if (Array.isArray(item)) {
//                  // Treat actual quotes as normal quoted values
//                  result.push(new tree.Quoted(item[0], item[1], true, index, fileInfo));
//              }
//              else {
//                  if (i === value.length - 1) {
//                      item = item.trim();
//                  }
//                  // Treat like quoted values, but replace vars like unquoted expressions
//                  var quote = new tree.Quoted('\'', item, true, index, fileInfo);
//                  quote.variableRegex = /@([\w-]+)/g;
//                  quote.propRegex = /\$([\w-]+)/g;
//                  result.push(quote);
//              }
//          }
//          parserInput.forget();
//          return new tree.Expression(result, true);
//      }
//      parserInput.restore();
//  },
  }

  static final RegExp _importRegExp1 = new RegExp(r'@import?\s+', caseSensitive: true);

  ///
  /// An @import atrule
  ///
  ///     @import "lib";
  ///
  /// The importing is a file-system operation, ruled by the Import node.
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
        if (features != null) nodeFeatures = new Value(features);
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
  /// For @import(options) returns the activated options. Example:
  ///
  ///     @import (less, multiple) "file.css";
  ///
  ///     returns {less: true, multiple: true}
  ///
  ImportOptions importOptions() {
    String              o;
    String              optionName;
    final ImportOptions options = new ImportOptions();
    bool                value;

    // list of options, surrounded by parens
    if (parserInput.$char('(') == null) return null;

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
        if(parserInput.$char(',') == null) break;
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
  /// The option in @import(option). Example:
  ///
  ///     @import(optional)  returns optional
  ///
  /// Valid values are:
  ///
  ///     less | css | multiple | once | inline | reference | optional
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
  /// Search for something like:
  ///
  ///     @media all and (max-width: 1024px)
  ///
  Expression mediaFeature() {
    Node              e;
    final List<Node>  nodes = <Node>[];
    String            p;

    parserInput.save();
    do {
      e = entities.keyword()
          ?? entities.variable()
          ?? entities.mixinLookup();

      if (e != null) {
        nodes.add(e);
      } else if (parserInput.$char('(') != null) {
        p = property();
        e = permissiveValue(untilTokensString: ')');
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
    if (nodes.isNotEmpty) return new Expression(nodes);
    return null;

// 3.5.0.beta.5 20180703
//  mediaFeature: function () {
//      var entities = this.entities, nodes = [], e, p;
//      parserInput.save();
//      do {
//          e = entities.keyword() || entities.variable() || entities.mixinLookup();
//          if (e) {
//              nodes.push(e);
//          } else if (parserInput.$char('(')) {
//              p = this.property();
//              e = this.permissiveValue(')');
//              if (parserInput.$char(')')) {
//                  if (p && e) {
//                      nodes.push(new(tree.Paren)(new(tree.Declaration)(p, e, null, null, parserInput.i, fileInfo, true)));
//                  } else if (e) {
//                      nodes.push(new(tree.Paren)(e));
//                  } else {
//                      error('badly formed media feature definition');
//                  }
//              } else {
//                  error('Missing closing \')\'', 'Parse');
//              }
//          }
//      } while (e);
//
//      parserInput.forget();
//      if (nodes.length > 0) {
//          return new(tree.Expression)(nodes);
//      }
//  },

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
  /// Search for a list of mediaFeature, such as:
  ///
  ///     @media all and (max-width: 1024px)
  ///     @media handheld and (min-width: @var), scrreen and (min-width: 20em)
  ///
  List<Node> mediaFeatures() {
    Node              e;
    final List<Node>  features = <Node>[];

    do {
      e = mediaFeature();
      if (e != null) {
        features.add(e);
        if (parserInput.$char(',') == null) break;
      } else {
        e = entities.variable()
          ?? entities.mixinLookup();

        if (e != null) {
          features.add(e);
          if (parserInput.$char(',') == null) break;
        }
      }
    } while (e != null);

    return features.isNotEmpty ? features : null;

// 3.5.0.beta.5 20180703
//  mediaFeatures: function () {
//      var entities = this.entities, features = [], e;
//      do {
//          e = this.mediaFeature();
//          if (e) {
//              features.push(e);
//              if (!parserInput.$char(',')) { break; }
//          } else {
//              e = entities.variable() || entities.mixinLookup();
//              if (e) {
//                  features.push(e);
//                  if (!parserInput.$char(',')) { break; }
//              }
//          }
//      } while (e);
//
//      return features.length > 0 ? features : null;
//  },
  }

  ///
  /// Search for something like:
  ///
  ///     @media all and (max-width: 1024px) { }
  ///     @media print { }
  ///
  Media media() {
    DebugInfo   debugInfo;
    List<Node>  features;
    Media       media;
    List<Node>  rules;

    final int index = parserInput.i;

    if (context.dumpLineNumbers?.isNotEmpty ?? false) {
      debugInfo = getDebugInfo(index);
    }

    parserInput.save();

    if (parserInput.$str('@media') != null) {
      features = mediaFeatures();

      rules = block();

      if (rules == null) {
        parserInput.error('media definitions require block statements after any features');
      }

      parserInput.forget();

      media = new Media(rules, features, index, fileInfo);
      if (context.dumpLineNumbers?.isNotEmpty ?? false) {
        media.debugInfo = debugInfo;
      }
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
  /// Search for something like:
  ///
  ///     @apply(--mixin-name);
  ///
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
          parserInput.restore('Bad argument');
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
  /// Search for something like:
  ///
  ///     @options "--flags";
  ///
  /// No standard less implementation.
  /// To load a plugin use @plugin.
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
  ///
  ///     @plugin (args) "lib";
  ///
  /// Differs from standard implementation. Here is Options and not import.
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
        if (value.value.contains('clean-css')) {
          context.cleanCss = true; //parser needs this
        }
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
  /// list of options, surrounded by parens, to be processed by the plugin.
  ///
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
//  static final RegExp _directiveRegExp2 = new RegExp(r'[^{;]+', caseSensitive: true);


  ///
  /// A CSS AtRule, such as:
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

    if (parserInput.currentChar() != '@') return null;

    value = import()
        ?? options()
        ?? plugin()
        ?? apply()
        ?? media();
    if (value != null) return value;

    parserInput.save();

    name = parserInput.$re(_directiveRegExp1);
    if (name == null) return null;

    nonVendorSpecificName = name;
    if (name[1] == '-' && name.indexOf('-', 2) > 0) {
      nonVendorSpecificName = '@${name.substring(name.indexOf("-", 2) + 1)}';
    }

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
      if (value == null) parserInput.error('expected $name identifier');
    } else if (hasExpression) {
      value = expression();
      if (value == null) parserInput.error('expected $name expression');
      } else if (hasUnknown) {
        value = permissiveValue(untilTokensRegExp: new RegExp(r'[{;]')); // /^[{;]/
        hasBlock = (parserInput.currentChar() == '{');
        if (value == null) {
          if (!hasBlock && parserInput.currentChar() != ';') {
            parserInput.error('$name rule is missing block or ending semi-colon');
          }
        } else if (value.value?.isEmpty ?? true) {
          value = null;
        }
      }

    if (hasBlock) rules = blockRuleset();

    if (rules != null || (!hasBlock && value != null && parserInput.$char(';') != null)) {
      parserInput.forget();
      return new AtRule(name, value,
          rules: rules,
          index: index,
          currentFileInfo: fileInfo,
          debugInfo: isNotEmpty(context.dumpLineNumbers) ? getDebugInfo(index) : null,
          isRooted: isRooted);
    }

    parserInput.restore('at-rule options not recognised');
    return null;

//3.0.4 20180622
//atrule: function () {
//    var index = parserInput.i, name, value, rules, nonVendorSpecificName,
//        hasIdentifier, hasExpression, hasUnknown, hasBlock = true, isRooted = true;
//
//    if (parserInput.currentChar() !== '@') { return; }
//
//    value = this['import']() || this.plugin() || this.media();
//    if (value) {
//        return value;
//    }
//
//    parserInput.save();
//
//    name = parserInput.$re(/^@[a-z-]+/);
//
//    if (!name) { return; }
//
//    nonVendorSpecificName = name;
//    if (name.charAt(1) == '-' && name.indexOf('-', 2) > 0) {
//        nonVendorSpecificName = "@" + name.slice(name.indexOf('-', 2) + 1);
//    }
//
//    switch (nonVendorSpecificName) {
//        case "@charset":
//            hasIdentifier = true;
//            hasBlock = false;
//            break;
//        case "@namespace":
//            hasExpression = true;
//            hasBlock = false;
//            break;
//        case "@keyframes":
//        case "@counter-style":
//            hasIdentifier = true;
//            break;
//        case "@document":
//        case "@supports":
//            hasUnknown = true;
//            isRooted = false;
//            break;
//        default:
//            hasUnknown = true;
//            break;
//    }
//
//    parserInput.commentStore.length = 0;
//
//    if (hasIdentifier) {
//        value = this.entity();
//        if (!value) {
//            error("expected " + name + " identifier");
//        }
//    } else if (hasExpression) {
//        value = this.expression();
//        if (!value) {
//            error("expected " + name + " expression");
//        }
//    } else if (hasUnknown) {
//        value = this.permissiveValue(/^[{;]/);
//        hasBlock = (parserInput.currentChar() === '{');
//        if (!value) {
//            if (!hasBlock && parserInput.currentChar() !== ';') {
//                error(name + " rule is missing block or ending semi-colon");
//            }
//        }
//        else if (!value.value) {
//            value = null;
//        }
//    }
//
//    if (hasBlock) {
//        rules = this.blockRuleset();
//    }
//
//    if (rules || (!hasBlock && value && parserInput.$char(';'))) {
//        parserInput.forget();
//        return new (tree.AtRule)(name, value, rules, index, fileInfo,
//            context.dumpLineNumbers ? getDebugInfo(index) : null,
//            isRooted
//        );
//    }
//
//    parserInput.restore("at-rule options not recognised");
//},
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
    final int               index = parserInput.i;

    do {
      e = expression();
      if (e != null) {
        expressions.add(e);
        if (parserInput.$char(',') == null) break;
      }
    } while (e != null);

    if (expressions.isNotEmpty) return new Value(expressions, index: index);
    return null;

//3.0.0 20160718
// value: function () {
//     var e, expressions = [], index = parserInput.i;
//
//     do {
//         e = this.expression();
//         if (e) {
//             expressions.push(e);
//             if (! parserInput.$char(',')) { break; }
//         }
//     } while (e);
//
//     if (expressions.length > 0) {
//         return new(tree.Value)(expressions, index);
//     }
// },
  }

  static final RegExp _importantRegExp1 = new RegExp(r'! *important', caseSensitive: true);

  ///
  /// Search for:
  ///
  ///     !important
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
  /// Search for parens subexpressions like:
  ///
  ///     (#111111 - #444444) in color: (#111111 - #444444)
  ///     (2px + 4) in inner-radius: (2px + 4)
  ///     (@r / 3) in round(@r / 3), 2)
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
  /// Search for:
  ///
  ///     operand operator operandN
  ///     operator is * | /
  ///     operandN is 0 | more operands
  ///
  /// Example:
  ///
  ///     @a
  ///     @a * 2
  ///     @a * @b / 2
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
        if (parserInput.peek(_reMultiplication)) break; //comments found

        parserInput.save();

        op = parserInput.$char('/')
            ?? parserInput.$char('*')
            ?? parserInput.$str('./');
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

//3.0.4 20180625
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
//              op = parserInput.$char('/') || parserInput.$char('*') || parserInput.$str('./');
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
//  },
  }

  static final RegExp _additionRegExp1 = new RegExp(r'[-+]\s+', caseSensitive: true);

  ///
  /// Search for:
  ///
  ///     multiplication operator multiplicationN
  ///     operator is + | -
  ///     multiplicationN is 0 | more multiplication
  ///
  /// Example:
  ///
  ///     @a
  ///     @a + @b
  ///     @a + @b - 2
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
        if (op == null && !isSpaced) op = parserInput.$char('+');
        if (op == null && !isSpaced) op = parserInput.$char('-');
        if (op == null) break;

        a = multiplication();
        if (a == null) break;

        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op,
            <Node>[operation != null ? operation : m, a], isSpaced: isSpaced);
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
  /// Function to be passed to ParserInput.expect().
  ///
  /// Search for conditions like:
  ///
  ///     (@a = white) in when (@a = white) { } or
  ///     when (@b = 1), (@c = 2) ... { }
  ///
  Node conditions() {
    Node      a;
    Node      b;
    Condition condition;
    final int index = parserInput.i;

    a = this.condition(needsParens: true);
    if (a != null) {
      while (true) {
        if (!parserInput.peek(_reConditions) || (parserInput.$char(',') == null)) {
          break;
        }
        b = this.condition(needsParens: true);
        if (b == null) break;

        condition = new Condition('or', condition != null ? condition : a, b,
            index: index);
      }
      return condition ?? a;
    }

    return null;

// 20180708
//  conditions: function () {
//      var a, b, index = parserInput.i, condition;
//
//      a = this.condition(true);
//      if (a) {
//          while (true) {
//              if (!parserInput.peek(/^,\s*(not\s*)?\(/) || !parserInput.$char(',')) {
//                  break;
//              }
//              b = this.condition(true);
//              if (!b) {
//                  break;
//              }
//              condition = new(tree.Condition)('or', condition || a, b, index);
//          }
//          return condition || a;
//      }
//  },
  }

  ///
  /// Inside a MixinDefinition, conditions such as
  ///     when, and, or, not, ...
  ///
  /// Example:
  ///
  ///     when ((@1) and (@2) or (@3))
  ///
  ///     .light (@a) when (lightness(@a) > 50%) {
  ///       color: white;
  ///     }
  ///
  Condition condition({bool needsParens = false}) {
    String or() => parserInput.$str('or');

    Condition result = conditionAnd(needsParens: needsParens);
    if (result == null) return null;

    final String logical = or();
    if (logical != null) {
      final Condition next = condition(needsParens: needsParens);
      if (next != null) {
        result = new Condition(logical, result, next);
      } else {
        return null;
      }
    }
    return result;

// 20180708
//  condition: function (needsParens) {
//      var result, logical, next;
//      function or() {
//          return parserInput.$str('or');
//      }
//
//      result = this.conditionAnd(needsParens);
//      if (!result) {
//          return ;
//      }
//      logical = or();
//      if (logical) {
//          next = this.condition(needsParens);
//          if (next) {
//              result = new(tree.Condition)(logical, result, next);
//          } else {
//              return ;
//          }
//      }
//      return result;
//  },
  }

  ///
  /// Search for conditions such as:
  ///
  ///     (@a = white)
  ///     (@a = white) and (@b = black) and ...
  ///
  Condition conditionAnd({bool needsParens = false}) {
    // inside functions
    Condition insideCondition() {
      final Condition cond = negatedCondition(needsParens: needsParens)
          ?? parenthesisCondition(needsParens: needsParens);
      if (cond == null && !needsParens) {
        return atomicCondition(needsParens: needsParens);
      }
      return cond;
    }

    String and() => parserInput.$str('and');

    // code
    Condition result = insideCondition();
    if (result == null) return null;

    final String logical = and();
    if (logical != null) {
      final Condition next = conditionAnd(needsParens: needsParens);
      if (next != null) {
        result = new Condition(logical, result, next);
      } else {
        return null;
      }
    }
    return result;

// 20180708
//  conditionAnd: function (needsParens) {
//      var result, logical, next, self = this;
//      function insideCondition() {
//          var cond = self.negatedCondition(needsParens) || self.parenthesisCondition(needsParens);
//          if (!cond && !needsParens) {
//              return self.atomicCondition(needsParens);
//          }
//          return cond;
//      }
//      function and() {
//          return parserInput.$str('and');
//      }
//
//      result = insideCondition();
//      if (!result) {
//          return ;
//      }
//      logical = and();
//      if (logical) {
//          next = this.conditionAnd(needsParens);
//          if (next) {
//              result = new(tree.Condition)(logical, result, next);
//          } else {
//              return ;
//          }
//      }
//      return result;
//  },

// 3.5.0.beta.7 20180704
//  conditionAnd: function () {
//      var result, logical, next;
//      function insideCondition(me) {
//          return me.negatedCondition() || me.parenthesisCondition() || me.atomicCondition();
//      }
//      function and() {
//          return parserInput.$str('and');
//      }
//
//      result = insideCondition(this);
//      if (!result) {
//          return ;
//      }
//      logical = and();
//      if (logical) {
//          next = this.conditionAnd();
//          if (next) {
//              result = new(tree.Condition)(logical, result, next);
//          } else {
//              return ;
//          }
//      }
//      return result;
//  },
  }

  ///
  /// Search for conditions such as:
  ///
  ///     not(@a = 0)
  ///
  Condition negatedCondition({bool needsParens = false}) {
    if (parserInput.$str('not') != null) {
      final Condition result = parenthesisCondition(needsParens: needsParens);
      if (result != null) result.negate = !result.negate;
      return result;
    }
    return null;

// 20180708
//  negatedCondition: function (needsParens) {
//      if (parserInput.$str('not')) {
//          var result = this.parenthesisCondition(needsParens);
//          if (result) {
//              result.negate = !result.negate;
//          }
//          return result;
//      }
//  },

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
  /// Search for a condition inside a parenthesis:
  ///
  ///     ( condition )
  ///
  /// Example:
  ///
  ///     (@a = 0)
  ///
  Condition parenthesisCondition({bool needsParens = false}) {
    //
    Condition tryConditionFollowedByParenthesis() {
      parserInput.save();
      final Condition body = condition(needsParens: needsParens);
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
    if (parserInput.$str('(') == null) {
      parserInput.restore();
      return null;
    }

    Condition body = tryConditionFollowedByParenthesis();
    if (body != null) {
      parserInput.forget();
      return body;
    }

    body = atomicCondition(needsParens: needsParens);
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

// 20180708
//  parenthesisCondition: function (needsParens) {
//      function tryConditionFollowedByParenthesis(me) {
//          var body;
//          parserInput.save();
//          body = me.condition(needsParens);
//          if (!body) {
//              parserInput.restore();
//              return ;
//          }
//          if (!parserInput.$char(')')) {
//              parserInput.restore();
//              return ;
//          }
//          parserInput.forget();
//          return body;
//      }
//
//      var body;
//      parserInput.save();
//      if (!parserInput.$str('(')) {
//          parserInput.restore();
//          return ;
//      }
//      body = tryConditionFollowedByParenthesis(this);
//      if (body) {
//          parserInput.forget();
//          return body;
//      }
//
//      body = this.atomicCondition(needsParens);
//      if (!body) {
//          parserInput.restore();
//          return ;
//      }
//      if (!parserInput.$char(')')) {
//          parserInput.restore('expected \')\' got \'' + parserInput.currentChar() + '\'');
//          return ;
//      }
//      parserInput.forget();
//      return body;
//  },

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
  /// The simplest condition, such as
  ///
  ///     @a > @b
  ///
  /// More complex conditions have atomic conditions inside:
  ///
  ///     ((@a = true) and (@b = true))
  ///
  /// Syntax:
  ///
  ///     LeftValue operator RightValue
  ///     Value is addition | keyword | quoted
  ///     operator is  >= | <= | => |  =< | > | < | =
  ///
  /// also:
  ///
  ///     Value
  ///     Example: @a  is the same as @a = true
  ///
  ///
  Condition atomicCondition({bool needsParens = false}) {
    Node      a;
    Node      b;
    Condition c;
    final int index = parserInput.i;
    String    op;

    // function definition
    Node cond() => addition()
        ?? entities.keyword()
        ?? entities.quoted()
        ?? entities.mixinLookup();

    a = cond();

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
        b = cond();

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

// 20180708
//  atomicCondition: function (needsParens) {
//      var entities = this.entities, index = parserInput.i, a, b, c, op;
//
//      function cond() {
//          return this.addition() || entities.keyword() || entities.quoted() || entities.mixinLookup();
//      }
//      cond = cond.bind(this);
//
//      a = cond();
//      if (a) {
//          if (parserInput.$char('>')) {
//              if (parserInput.$char('=')) {
//                  op = '>=';
//              } else {
//                  op = '>';
//              }
//          } else
//          if (parserInput.$char('<')) {
//              if (parserInput.$char('=')) {
//                  op = '<=';
//              } else {
//                  op = '<';
//              }
//          } else
//          if (parserInput.$char('=')) {
//              if (parserInput.$char('>')) {
//                  op = '=>';
//              } else if (parserInput.$char('<')) {
//                  op = '=<';
//              } else {
//                  op = '=';
//              }
//          }
//          if (op) {
//              b = cond();
//              if (b) {
//                  c = new(tree.Condition)(op, a, b, index, false);
//              } else {
//                  error('expected expression');
//              }
//          } else {
//              c = new(tree.Condition)('=', a, new(tree.Keyword)('true'), index, false);
//          }
//          return c;
//      }
//  },

// 3.5.0.beta.5 20180702
//  atomicCondition: function () {
//      var entities = this.entities, index = parserInput.i, a, b, c, op;
//
//      function cond() {
//          return this.addition() || entities.keyword() || entities.quoted() || entities.mixinLookup();
//      }
//      cond = cond.bind(this);
//
//      a = cond();
//      if (a) {
//          if (parserInput.$char('>')) {
//              if (parserInput.$char('=')) {
//                  op = '>=';
//              } else {
//                  op = '>';
//              }
//          } else
//          if (parserInput.$char('<')) {
//              if (parserInput.$char('=')) {
//                  op = '<=';
//              } else {
//                  op = '<';
//              }
//          } else
//          if (parserInput.$char('=')) {
//              if (parserInput.$char('>')) {
//                  op = '=>';
//              } else if (parserInput.$char('<')) {
//                  op = '=<';
//              } else {
//                  op = '=';
//              }
//          }
//          if (op) {
//              b = cond();
//              if (b) {
//                  c = new(tree.Condition)(op, a, b, index, false);
//              } else {
//                  error('expected expression');
//              }
//          } else {
//              c = new(tree.Condition)('=', a, new(tree.Keyword)('true'), index, false);
//          }
//          return c;
//      }
//  },
  }

  static final RegExp _reOperand = new RegExp(r'-[@\$\(]');

  ///
  /// An operand is anything that can be part of an operation.
  ///
  /// operand is:
  ///
  ///     (-) dimension | color | variable | property | call
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
        ?? entities.property()
        ?? entities.call()
        ?? entities.quoted(forceEscaped: true)
        ?? entities.colorKeyword()
        ?? entities.mixinLookup();

    if (negate != null) {
      o.parensInOp = true;
      o = new Negative(o);
    }

    return o;

// 3.5.0.beta.5 20180702
//  operand: function () {
//      var entities = this.entities, negate;
//
//      if (parserInput.peek(/^-[@\$\(]/)) {
//          negate = parserInput.$char('-');
//      }
//
//      var o = this.sub() || entities.dimension() ||
//              entities.color() || entities.variable() ||
//              entities.property() || entities.call() ||
//              entities.quoted(true) || entities.colorKeyword() ||
//              entities.mixinLookup();
//
//      if (negate) {
//          o.parensInOp = true;
//          o = new(tree.Negative)(o);
//      }
//
//      return o;
//  },
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
    final int         index = parserInput.i;

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
          if (delim != null) {
            entities.add(new Anonymous(delim, index: index));
          }
        }
      }
    } while (e != null);

    if (entities.isNotEmpty) return new Expression(entities);
    return null;

//3.0.0 20160718
// expression: function () {
//     var entities = [], e, delim, index = parserInput.i;
//
//     do {
//         e = this.comment();
//         if (e) {
//             entities.push(e);
//             continue;
//         }
//         e = this.addition() || this.entity();
//         if (e) {
//             entities.push(e);
//             // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
//             if (!parserInput.peek(/^\/[\/*]/)) {
//                 delim = parserInput.$char('/');
//                 if (delim) {
//                     entities.push(new(tree.Anonymous)(delim, index));
//                 }
//             }
//         }
//     } while (e);
//     if (entities.length > 0) {
//         return new(tree.Expression)(entities);
//     }
// },
  }

  static final RegExp _propertyRegExp1 = new RegExp(r'(\*?-?[_a-zA-Z0-9-]+)\s*:', caseSensitive: true);

  ///
  /// Something like:
  ///
  ///     max-width:
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
  static final RegExp _rulePropertyRegExp3 = new RegExp(r'((?:[\w-]+)|(?:[@\$]\{[\w-]+\}))', caseSensitive: true);
  static final RegExp _rulePropertyRegExp4 = new RegExp(r'((?:\+_|\+)?)\s*:', caseSensitive: true);

  ///
  /// Search for something like:
  ///
  ///     color: or  border: or background-color:
  ///     transform+: or *zoom: or @(prefix)width:
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
      if (!match(_rulePropertyRegExp3)) break;
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
        result.add((!s.startsWith('@') && !s.startsWith(r'$'))
            ? new Keyword(s)
            : (s.startsWith('@'))
                ? new Variable('@${s.substring(2, (s.length - 1))}', index[k], fileInfo)
                : new Property('\$${s.substring(2, (s.length - 1))}', index[k], fileInfo)
        );
      }
      return result;
    }
    parserInput.restore();
    return null;

//3.0.0 20160718
// ruleProperty: function () {
//     var name = [], index = [], s, k;
//
//     parserInput.save();
//
//     var simpleProperty = parserInput.$re(/^([_a-zA-Z0-9-]+)\s*:/);
//     if (simpleProperty) {
//         name = [new(tree.Keyword)(simpleProperty[1])];
//         parserInput.forget();
//         return name;
//     }
//
//     function match(re) {
//         var i = parserInput.i,
//             chunk = parserInput.$re(re);
//         if (chunk) {
//             index.push(i);
//             return name.push(chunk[1]);
//         }
//     }
//
//     match(/^(\*?)/);
//     while (true) {
//         if (!match(/^((?:[\w-]+)|(?:[@\$]\{[\w-]+\}))/)) {
//             break;
//         }
//     }
//
//     if ((name.length > 1) && match(/^((?:\+_|\+)?)\s*:/)) {
//         parserInput.forget();
//
//         // at last, we have the complete match now. move forward,
//         // convert name particles to tree objects and return:
//         if (name[0] === '') {
//             name.shift();
//             index.shift();
//         }
//         for (k = 0; k < name.length; k++) {
//             s = name[k];
//             name[k] = (s.charAt(0) !== '@' && s.charAt(0) !== '$') ?
//                 new(tree.Keyword)(s) :
//                 (s.charAt(0) === '@' ?
//                     new(tree.Variable)('@' + s.slice(2, -1), index[k], fileInfo) :
//                     new(tree.Property)('$' + s.slice(2, -1), index[k], fileInfo));
//         }
//         return name;
//     }
//     parserInput.restore();
// }
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
