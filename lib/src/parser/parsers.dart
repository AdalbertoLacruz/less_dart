//source: less/parser.js 2.5.0 lines 195-end

part of parser.less;

///
/// Here in, the parsing rules/functions
///
/// The basic structure of the syntax tree generated is as follows:
///
///   Ruleset ->  Rule -> Value -> Expression -> Entity
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
///         Rule ("color",  Value ([Expression [Color #fff]]))
///         Rule ("border", Value ([Expression [Dimension 1px][Keyword "solid"][Color #000]]))
///         Rule ("width",  Value ([Expression [Operation "+" [Variable "@w"][Dimension 4px]]]))
///         Ruleset (Selector [Element '>', '.child'], [...])
///     ])
///
///  In general, most rules will try to parse a token with the `$re()` function, and if the return
///  value is truly, will return a new node, of the relevant type. Sometimes, we need to check
///  first, before parsing, that's when we use `peek()`.
///
class Parsers {
  String input;
  Contexts context;
  ParserInput parserInput;

  Entities entities;
  FileInfo fileInfo;
  Mixin mixin;

  Parsers(String this.input, Contexts this.context){
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
  ///     primary  →  (ruleset | rule)+
  ///     ruleset  →  selector+ block
  ///     block    →  '{' primary '}'
  ///
  /// Only at one point is the primary rule not called from the
  /// block rule: at the root level.
  ///
  List<Node> primary(){
    Node node;
    List<Node> nodeList;
    List root = [];

    while(true){
      while(true) {
        node = comment();
        if (node == null) break;
        root.add(node);
      }

      // always process comments before deciding if finished
      if (parserInput.finished) break;
      if (parserInput.peekChar('}')) break;

      nodeList = extendRule();
      if (nodeList != null) {
        root.addAll(nodeList);
        continue;
      }

      node = mixin.definition();
      if (node == null) node = rule();
      if (node == null) node = ruleset();
      if (node == null) node = mixin.call();
      if (node == null) node = rulesetCall();
      if (node == null) node = directive();

      if (node != null) {
        root.add(node);
      } else {
        bool foundSemiColon = false;
        while (parserInput.$char(";") != null){
          foundSemiColon = true;
        }
        if (!foundSemiColon) break;
      }
    }

    return root;

//2.4.0 20150321
//  primary: function () {
//      var mixin = this.mixin, root = [], node;
//
//      while (true)
//      {
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
//          node = mixin.definition() || this.rule() || this.ruleset() ||
//              mixin.call() || this.rulesetCall() || this.directive();
//          if (node) {
//              root.push(node);
//          } else {
//              var foundSemiColon = false;
//              while (parserInput.$char(";")) {
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

  /// check if input is empty. Else throw error.
  isFinished() => parserInput.isFinished();

  ///
  /// Comments are collected by the main parsing mechanism and then assigned to nodes
  /// where the current structure allows it
  ///
  /// CSS comments `/* */`, LeSS comments `//`
  ///
  Comment comment(){
    if (parserInput.commentStore.isNotEmpty) {
      CommentPointer comment = parserInput.commentStore.removeAt(0);
      return new Comment(comment.text, comment.isLineComment, comment.index, context.currentFileInfo);
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

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///      @fink:
  ///
  String variable(){
    String name;

    if (parserInput.currentChar() == '@' && (name = parserInput.$re(r'^(@[\w-]+)\s*:')) != null) return name;
    return null;

//2.2.0
//  variable: function () {
//      var name;
//
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^(@[\w-]+)\s*:/))) { return name[1]; }
//  }
  }

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///       @fink();
  ///
  RulesetCall rulesetCall(){
    String name;

    if (parserInput.currentChar() == '@') {
      name = parserInput.$re(r'^(@[\w-]+)\s*\(\s*\)\s*;');
      if (name != null) return new RulesetCall(name);
    }

    return null;

//2.2.0
//  rulesetCall: function () {
//      var name;
//
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^(@[\w-]+)\s*\(\s*\)\s*;/))) {
//          return new tree.RulesetCall(name[1]);
//      }
//  }
  }

  ///
  /// extend syntax - used to extend selectors
  ///
  List<Extend> extend([bool isRule = false]) {
    Element       e;
    List<Element> elements;
    Extend        extend;
    List<Extend>  extendedList;
    int           index = parserInput.i;
    String        option;

    if (parserInput.$str(isRule ? '&:extend(' : ':extend(') ==  null) return null;

    do {
      option = null;
      elements = null;
      while((option = parserInput.$re(r'^(all)(?=\s*(\)|,))', true, 1)) == null) {
        e = element();
        if (e == null) break;

        if (elements != null) {
          elements.add(e);
        } else {
          elements = [e];
        }
      }

      if (elements == null) {
        parserInput.error('Missing target selector for :extend().');
      }
      extend = new Extend(new Selector(elements), option, index);
      if (extendedList != null) {
        extendedList.add(extend);
      } else {
        extendedList = [extend];
      }

    } while (parserInput.$char(',') != null);

    parserInput.expect(new RegExp(r'^\)'));
    if (isRule) parserInput.expect(new RegExp(r'^;'));

    return extendedList;

//2.4.0 20150315
//  extend: function(isRule) {
//      var elements, e, index = parserInput.i, option, extendList, extend;
//
//      if (!parserInput.$str(isRule ? "&:extend(" : ":extend(")) {
//          return;
//      }
//
//      do {
//          option = null;
//          elements = null;
//          while (! (option = parserInput.$re(/^(all)(?=\s*(\)|,))/))) {
//              e = this.element();
//              if (!e) {
//                  break;
//              }
//              if (elements) {
//                  elements.push(e);
//              } else {
//                  elements = [ e ];
//              }
//          }
//
//          option = option && option[1];
//          if (!elements) {
//              error("Missing target selector for :extend().");
//          }
//          extend = new(tree.Extend)(new(tree.Selector)(elements), option, index);
//          if (extendList) {
//              extendList.push(extend);
//          } else {
//              extendList = [ extend ];
//          }
//      } while (parserInput.$char(","));
//
//      expect(/^\)/);
//
//      if (isRule) {
//          expect(/^;/);
//      }
//
//      return extendList;
//  },
  }

  /// extendRule - used in a rule to extend all the parent selectors
  List<Extend> extendRule() => extend(true);

  ///
  /// Entities are the smallest recognized token,
  /// and can be found inside a rule's value.
  ///
  Node entity() {
    Node                result = comment();
    if (result == null) result = entities.literal();
    if (result == null) result = entities.variable();
    if (result == null) result = entities.url();
    if (result == null) result = entities.call();
    if (result == null) result = entities.keyword();
    if (result == null) result = entities.javascript();
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
  /// A Rule terminator. Note that we use `peek()` to check for '}',
  /// because the `block` rule will be expecting it, but we still need to make sure
  /// it's there, if ';' was ommitted.
  ///
  bool end() {
    return (parserInput.$char(';') != null) || parserInput.peekChar('}');

//2.2.0
//  end: function () {
//      return parserInput.$char(';') || parserInput.peek('}');
//  }
  }

//
//alpha: see entities.alpha()
//

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
    Combinator c;
    var e; //String or Node
    int index = parserInput.i;
    Selector v;

    c = combinator();

    e = parserInput.$re(r'^(?:\d+\.\d+|\d+)%');
    if (e == null) e = parserInput.$re(r'^(?:[.#]?|:*)(?:[\w-]|[^\x00-\x9f]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+');
    if (e == null) e = parserInput.$char('*');
    if (e == null) e = parserInput.$char('&');
    if (e == null) e = attribute();
    if (e == null) e = parserInput.$re(r'^\([^&()@]+\)');
    if (e == null) e = parserInput.$re(r'^[\.#:](?=@)');
    if (e == null) e = entities.variableCurly();

    if (e == null) {
      parserInput.save();
      if (parserInput.$char('(') != null) {
        if((v = selector()) != null && parserInput.$char(')') != null) {
          e = new Paren(v);
          parserInput.forget();
        } else {
          parserInput.restore("Missing closing ')'");
        }
      } else {
        parserInput.forget();
      }
    }

    if (e != null) return new Element(c, e, index, fileInfo);

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
      String slashedCombinator = parserInput.$re(r'^\/[a-z]+\/', false); //i-nsensitive
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
      while (parserInput.isWhitespacePos()) { parserInput.i++; }
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
  Selector lessSelector() => selector(true);

  ///
  /// A CSS Selector
  ///
  ///     .class > div + h1
  ///     li a:hover
  ///
  /// Selectors are made out of one or more Elements, see above.
  ///
  Selector selector([bool isLess = false]) {
    List<Extend> allExtends;
    String  c;
    Condition condition;
    Element e;
    List<Element> elements;
    List<Extend> extendList;
    int index = parserInput.i;
    String when;

    while ((isLess && (extendList = this.extend()) != null) ||
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
        if (allExtends != null) parserInput.error('Extend can only be used at the end of selector');
        c = parserInput.currentChar();
        if (elements != null) {
          elements.add(e);
        } else {
          elements = [e];
        }
        e = null;
      }
      if (c == '{' || c == '}' || c == ';' || c == ',' || c == ')' ) break;
    }

    if (elements != null) return new Selector(elements, allExtends, condition, index, fileInfo);
    if (allExtends != null) parserInput.error('Extend must be used to extend a selector, it cannot be used on its own');

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

  ///
  Attribute attribute() {
    if (parserInput.$char('[') == null) return null;

    var key; //String or Node
    String op;
    var val; //String or Node

    if ((key = entities.variableCurly()) == null) {
      key = parserInput.expect(new RegExp(r'^(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+'));
    }

    op = parserInput.$re(r'^[|~*$^]?=');
    if (op != null) {
      val = entities.quoted();
      if (val == null) val = parserInput.$re(r'^[0-9]+%');
      if (val == null) val = parserInput.$re(r'^[\w-]+');
      if (val == null) val = entities.variableCurly();
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

    if (parserInput.$char('{') != null && (content = primary()) != null && parserInput.$char('}') != null){
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
  Ruleset blockRuleset() {
    List<Node> block = this.block();

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
    Ruleset blockRuleset = this.blockRuleset();
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
    DebugInfo debugInfo;
    List<Node> rules;
    Selector s;
    List<Selector> selectors;

    parserInput.save();

    if (isNotEmpty(context.dumpLineNumbers)) {
      debugInfo = getDebugInfo(parserInput.i);
    }

    while (true) {
      s = lessSelector();
      if (s == null) break;

      // --polymer-mixin: {}
      // No standard js implementation
      if (parserInput.peekChar(':') && s.elements.length == 1) {
        if (s.elements[0].value is String && s.elements[0].value.startsWith('--')) {
          s.elements[0].value = s.elements[0].value + ':';
          parserInput.$char(':'); //move pointer
        }
      }
      // end no standard

      if (selectors != null) {
        selectors.add(s);
      } else {
        selectors = [s];
      }
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

    if (selectors != null && (rules = block()) != null) {
      parserInput.forget();
      Ruleset ruleset = new Ruleset(selectors, rules, context.strictImports);
      if (isNotEmpty(context.dumpLineNumbers)) ruleset.debugInfo = debugInfo;
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
  Rule rule([tryAnonymous = false]) {
    String c = parserInput.currentChar();
    String important;
    bool isVariable;
    String merge = '';
    var name; //String or Node
    int startOfRule = parserInput.i;
    Node value;

    if (c == '.' || c == '#' || c == '&' || c == ':') return null;

    parserInput.save();

    name = variable();
    if (name == null) name = ruleProperty();

    if (name != null) {
      isVariable = name is String;

      if (isVariable) value = detachedRuleset();

      parserInput.commentStore.length = 0;
      if (value == null) {
        // a name returned by this.ruleProperty() is always an array of the form:
        // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
        // where each item is a tree.Keyword or tree.Variable
        merge = (!isVariable && name.length > 1)? (name as List<Node>).removeLast().value : '';

        // prefer to try to parse first if its a variable or we are compressing
        // but always fallback on the other one
        bool tryValueFirst = !tryAnonymous && (context.compress || isVariable || context.cleanCss);

        if (tryValueFirst) value = this.value();

        if (value == null) {
          value = anonymousValue();
          if (value != null) {
            parserInput.forget();
            // anonymous values absorb the end ';' which is required for them to work
            return new Rule(name, value, '', merge, startOfRule, fileInfo); //TODO important '' is false
          }
        }

        if (!tryValueFirst && value == null) value = this.value();

        important = this.important();
      }

      if (value != null && end()) {
        parserInput.forget();
        return new Rule(name, value, important, merge, startOfRule, fileInfo);
      } else {
        parserInput.restore();
        if (value != null && !tryAnonymous) return rule(true);
      }
    } else {
      parserInput.forget();
    }

    return null;

//2.4.0 20150315 1739
//  rule: function (tryAnonymous) {
//      var name, value, startOfRule = parserInput.i, c = parserInput.currentChar(), important, merge, isVariable;
//
//      if (c === '.' || c === '#' || c === '&' || c === ':') { return; }
//
//      parserInput.save();
//
//      name = this.variable() || this.ruleProperty();
//      if (name) {
//          isVariable = typeof name === "string";
//
//          if (isVariable) {
//              value = this.detachedRuleset();
//          }
//
//          parserInput.commentStore.length = 0;
//          if (!value) {
//              // a name returned by this.ruleProperty() is always an array of the form:
//              // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
//              // where each item is a tree.Keyword or tree.Variable
//              merge = !isVariable && name.length > 1 && name.pop().value;
//
//              // prefer to try to parse first if its a variable or we are compressing
//              // but always fallback on the other one
//              var tryValueFirst = !tryAnonymous && (context.compress || isVariable);
//
//              if (tryValueFirst) {
//                  value = this.value();
//              }
//              if (!value) {
//                  value = this.anonymousValue();
//                  if (value) {
//                      parserInput.forget();
//                      // anonymous values absorb the end ';' which is reequired for them to work
//                      return new (tree.Rule)(name, value, false, merge, startOfRule, fileInfo);
//                  }
//              }
//              if (!tryValueFirst && !value) {
//                  value = this.value();
//              }
//
//              important = this.important();
//          }
//
//          if (value && this.end()) {
//              parserInput.forget();
//              return new (tree.Rule)(name, value, important, merge, startOfRule, fileInfo);
//          } else {
//              parserInput.restore();
//              if (value && !tryAnonymous) {
//                  return this.rule(true);
//              }
//          }
//      } else {
//          parserInput.forget();
//      }
//  },
//2.2.0
//  rule: function (tryAnonymous) {
//      var name, value, startOfRule = parserInput.i, c = parserInput.currentChar(), important, merge, isVariable;
//
//      if (c === '.' || c === '#' || c === '&') { return; }
//
//      parserInput.save();
//
//      name = this.variable() || this.ruleProperty();
//      if (name) {
//          isVariable = typeof name === "string";
//
//          if (isVariable) {
//              value = this.detachedRuleset();
//          }
//
//          parserInput.commentStore.length = 0;
//          if (!value) {
//              // a name returned by this.ruleProperty() is always an array of the form:
//              // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
//              // where each item is a tree.Keyword or tree.Variable
//              merge = !isVariable && name.pop().value;
//
//              // prefer to try to parse first if its a variable or we are compressing
//              // but always fallback on the other one
//              var tryValueFirst = !tryAnonymous && (context.compress || isVariable);
//
//              if (tryValueFirst) {
//                  value = this.value();
//              }
//              if (!value) {
//                  value = this.anonymousValue();
//                  if (value) {
//                      parserInput.forget();
//                      // anonymous values absorb the end ';' which is reequired for them to work
//                      return new (tree.Rule)(name, value, false, merge, startOfRule, fileInfo);
//                  }
//              }
//              if (!tryValueFirst && !value) {
//                  value = this.value();
//              }
//
//              important = this.important();
//          }
//
//          if (value && this.end()) {
//              parserInput.forget();
//              return new (tree.Rule)(name, value, important, merge, startOfRule, fileInfo);
//          } else {
//              parserInput.restore();
//              if (value && !tryAnonymous) {
//                  return this.rule(true);
//              }
//          }
//      } else {
//          parserInput.forget();
//      }
//  }
  }

  ///
  Anonymous anonymousValue() {
    String match = parserInput.$re(r'''^([^@+\/'"*`(;{}-]*);''', false, 1);
    if (match != null) {
      return new Anonymous(match);
    }
    return null;

//2.2.0
//  anonymousValue: function () {
//      var match = parserInput.$re(/^([^@+\/'"*`(;{}-]*);/);
//      if (match) {
//          return new(tree.Anonymous)(match[1]);
//      }
//  }
  }

  ///
  /// An @import directive
  ///
  ///     @import "lib";
  ///
  /// Depending on our environment, importing is done differently:
  /// In the browser, it's an XHR request, in Node, it would be a
  /// file-system operation. The function used for importing is
  /// stored in `import`, which we pass to the Import constructor.
  ///
  Import import() {
    int index = parserInput.i;
    List<Node> features;
    Value nodeFeatures;
    ImportOptions options = new ImportOptions();
    Node path;

    String dir = parserInput.$re(r'^@import?\s+');

    if (dir != null) {
      options = importOptions();
      if (options == null) options = new ImportOptions();

      path = entities.quoted();
      if (path == null) path = entities.url();
      if (path != null) {
        features = mediaFeatures();

        if (parserInput.$char(';') == null) {
          parserInput.i = index;
          parserInput.error('missing semi-colon or unrecognised media features on import');
        }
        if (features != null) nodeFeatures = new Value(features);
        return new Import(path, nodeFeatures, options, index, fileInfo);
      } else {
        parserInput.i = index;
        parserInput.error('malformed import statement');
      }
    }

    return null;

//2.4.0 20150315
//  "import": function () {
//      var path, features, index = parserInput.i;
//
//      var dir = parserInput.$re(/^@import?\s+/);
//
//      if (dir) {
//          var options = (dir ? this.importOptions() : null) || {};
//
//          if ((path = this.entities.quoted() || this.entities.url())) {
//              features = this.mediaFeatures();
//
//              if (!parserInput.$char(';')) {
//                  parserInput.i = index;
//                  error("missing semi-colon or unrecognised media features on import");
//              }
//              features = features && new(tree.Value)(features);
//              return new(tree.Import)(path, features, options, index, fileInfo);
//          }
//          else
//          {
//              parserInput.i = index;
//              error("malformed import statement");
//          }
//      }
//  },
  }

  ///
  /// ex. @import (less, multiple) "file.css";
  /// return {less: true, multiple: true}
  ///
  ImportOptions importOptions() {
    String o;
    String optionName;
    ImportOptions options = new ImportOptions();
    bool value;

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

  ///
  String importOption() => parserInput.$re('^(less|css|multiple|once|inline|reference|optional)');

//2.4.0
//  importOption: function() {
//      var opt = parserInput.$re(/^(less|css|multiple|once|inline|reference|optional)/);
//      if (opt) {
//          return opt[1];
//      }
//  },

  ///
  Expression mediaFeature() {
    Node e;
    List<Node> nodes = [];
    String p;

    parserInput.save();
    do {
      e = entities.keyword();
      if (e == null) e = entities.variable();
      if (e != null) {
        nodes.add(e);
      } else if (parserInput.$char('(') != null) {
        p = property();
        e = value();
        if (parserInput.$char(')') != null) {
          if (p != null && e != null) {
            nodes.add(new Paren(new Rule(p, e, null, null, parserInput.i, fileInfo, true)));
          } else if (e != null) {
            nodes.add(new Paren(e));
          } else {
            parserInput.restore('badly formed media feature definition');
            return null;
          }
        } else {
          parserInput.restore("Missing closing ')'");
          return null;
        }
      }
    } while (e != null);

    parserInput.forget();
    if (nodes.isNotEmpty) return new Expression(nodes);

    return null;

//2.2.0
//  mediaFeature: function () {
//      var entities = this.entities, nodes = [], e, p;
//      parserInput.save();
//      do {
//          e = entities.keyword() || entities.variable();
//          if (e) {
//              nodes.push(e);
//          } else if (parserInput.$char('(')) {
//              p = this.property();
//              e = this.value();
//              if (parserInput.$char(')')) {
//                  if (p && e) {
//                      nodes.push(new(tree.Paren)(new(tree.Rule)(p, e, null, null, parserInput.i, fileInfo, true)));
//                  } else if (e) {
//                      nodes.push(new(tree.Paren)(e));
//                  } else {
//                      parserInput.restore("badly formed media feature definition");
//                      return null;
//                  }
//              } else {
//                  parserInput.restore("Missing closing ')'");
//                  return null;
//              }
//          }
//      } while (e);
//
//      parserInput.forget();
//      if (nodes.length > 0) {
//          return new(tree.Expression)(nodes);
//      }
//  }
  }

  ///
  List<Node> mediaFeatures() {
    Node e;
    List<Node> features = [];

    do{
      e = mediaFeature();
      if (e != null) {
        features.add(e);
        if (parserInput.$char(',') == null) break;
      } else {
        e = entities.variable();
        if (e != null) {
          features.add(e);
          if (parserInput.$char(',') == null) break;
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
    DebugInfo debugInfo;
    List<Node> features;
    Media media;
    List<Node> rules;

    if (isNotEmpty(context.dumpLineNumbers)) {
      debugInfo = getDebugInfo(parserInput.i);
    }

    parserInput.save();

    if (parserInput.$str('@media') != null) {
      features = mediaFeatures();

      rules = block();

      if (rules == null) {
        parserInput.restore('media definitions require block statements after any features');
        return null;
      }

      parserInput.forget();

      media = new Media(rules, features, parserInput.i, fileInfo);
      if (isNotEmpty(context.dumpLineNumbers)) media.debugInfo = debugInfo;
      return media;

    }
    parserInput.restore();
    return null;

//2.4.0 20150320
//  media: function () {
//      var features, rules, media, debugInfo;
//
//      if (context.dumpLineNumbers) {
//          debugInfo = getDebugInfo(parserInput.i);
//      }
//
//      parserInput.save();
//
//      if (parserInput.$str("@media")) {
//          features = this.mediaFeatures();
//
//          rules = this.block();
//
//          if (!rules) {
//              parserInput.restore("media definitions require block statements after any features");
//              return;
//          }
//
//          parserInput.forget();
//
//          media = new(tree.Media)(rules, features, parserInput.i, fileInfo);
//          if (context.dumpLineNumbers) {
//              media.debugInfo = debugInfo;
//          }
//
//          return media;
//      }
//
//      parserInput.restore();
//  },
  }

  ///
  /// @apply(--mixin-name);
  /// No standard less implementation
  /// Pass-throught to css to let polymer work
  ///
  Apply apply() {
    int index = parserInput.i;
    String name;
    if (parserInput.$re(r'^@apply?\s*') != null) {
      parserInput.save();
      if (parserInput.$char('(') != null) {
        name = parserInput.$re(r'^[0-9A-Za-z-]+');
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


  ///
  /// @options "--flags";
  /// No standard less implementation
  /// To load a plugin use @plugin, this don't work for that
  ///
  Options options() {
    int index = parserInput.i;
    Quoted value;
    String dir = parserInput.$re(r'^@options?\s+');
    if (dir != null) {
      if ((value = entities.quoted()) != null) {
        if (parserInput.$char(';') == null) {
            parserInput.i = index;
            parserInput.error('missing semi-colon on options');
        }
        return new Options(value, index, fileInfo);
      } else {
        parserInput.i = index;
        parserInput.error('malformed options statement');
      }
    }

    return null;
  }

  ///
  /// @plugin "lib";
  /// Differs implementation. Here is Options and no import
  ///
  Options plugin() {
    int index = parserInput.i;
    Quoted value;
    String dir = parserInput.$re(r'^@plugin?\s+');

    if (dir != null) {
      if ((value = entities.quoted()) != null) {
        if (parserInput.$char(';') == null) {
            parserInput.i = index;
            parserInput.error('missing semi-colon on plugin');
        }
        if(value.value.contains('clean-css')) context.cleanCss = true; //parser needs this
        return new Options(value, index, fileInfo, isPlugin: true);
      } else {
        parserInput.i = index;
        parserInput.error('malformed plugin statement');
      }
    }
    return null;

//2.4.0 20150315
//  plugin: function () {
//      var path,
//          index = parserInput.i,
//          dir   = parserInput.$re(/^@plugin?\s+/);
//
//      if (dir) {
//          var options = { plugin : true };
//
//          if ((path = this.entities.quoted() || this.entities.url())) {
//
//              if (!parserInput.$char(';')) {
//                  parserInput.i = index;
//                  error("missing semi-colon on plugin");
//              }
//
//              return new(tree.Import)(path, null, options, index, fileInfo);
//          }
//          else
//          {
//              parserInput.i = index;
//              error("malformed plugin statement");
//          }
//      }
//  },
  }

  ///
  /// A CSS Directive
  ///
  ///     @charset "utf-8";
  ///
  Node directive() {
    bool hasBlock = true;
    bool hasExpression = false;
    bool hasIdentifier = false;
    bool hasUnknown = false;
    int index = parserInput.i;
    bool isRooted = true;
    String name;
    String nonVendorSpecificName;
    Ruleset rules;
    Node value;

    if (parserInput.currentChar() != '@') return null;

    value = import();
    if (value == null) value = options();
    if (value == null) value = plugin();
    if (value == null) value = apply();
    if (value == null) value = media();
    if (value != null) return value;

    parserInput.save();

    name = parserInput.$re(r'^@[a-z-]+');
    if (name == null) return null;

    nonVendorSpecificName = name;
    if (name[1] == '-' && name.indexOf('-', 2) > 0) {
      nonVendorSpecificName = '@' + name.substring(name.indexOf('-', 2) + 1);
    }

    switch (nonVendorSpecificName) {
      /*
      case "@font-face":
      case "@viewport":
      case "@top-left":
      case "@top-left-corner":
      case "@top-center":
      case "@top-right":
      case "@top-right-corner":
      case "@bottom-left":
      case "@bottom-left-corner":
      case "@bottom-center":
      case "@bottom-right":
      case "@bottom-right-corner":
      case "@left-top":
      case "@left-middle":
      case "@left-bottom":
      case "@right-top":
      case "@right-middle":
      case "@right-bottom":
        hasBlock = true;
        isRooted = true;
        break;
      */

      case '@counter-style':
        hasIdentifier = true;
        hasBlock = true;
        break;
      case '@charset':
        hasIdentifier = true;
        hasBlock = false;
        break;
      case '@namespace':
        hasExpression = true;
        hasBlock = false;
        break;
      case '@keyframes':
        hasIdentifier = true;
        break;
      case '@host':
      case '@page':
        hasUnknown = true;
        break;
      case '@document':
      case '@supports':
        hasUnknown = true;
        isRooted = false;
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
      String unknown = getValueOrDefault(parserInput.$re(r'^[^{;]+'), '').trim();
      if (isNotEmpty(unknown)) value = new Anonymous(unknown);
    }

    if (hasBlock) rules = blockRuleset();

    if (rules != null || (!hasBlock && value != null && parserInput.$char(';') != null)) {
      parserInput.forget();
      return new Directive(name, value, rules, index, fileInfo,
          isNotEmpty(context.dumpLineNumbers) ? getDebugInfo(index) : null,
          false, isRooted);
    }

    parserInput.restore('directive options not recognised');
    return null;

//2.4.0 20150319
//  directive: function () {
//      var index = parserInput.i, name, value, rules, nonVendorSpecificName,
//          hasIdentifier, hasExpression, hasUnknown, hasBlock = true, isRooted = true;
//
//      if (parserInput.currentChar() !== '@') { return; }
//
//      value = this['import']() || this.plugin() || this.media();
//      if (value) {
//          return value;
//      }
//
//      parserInput.save();
//
//      name = parserInput.$re(/^@[a-z-]+/);
//
//      if (!name) { return; }
//
//      nonVendorSpecificName = name;
//      if (name.charAt(1) == '-' && name.indexOf('-', 2) > 0) {
//          nonVendorSpecificName = "@" + name.slice(name.indexOf('-', 2) + 1);
//      }
//
//      switch(nonVendorSpecificName) {
//          /*
//          case "@font-face":
//          case "@viewport":
//          case "@top-left":
//          case "@top-left-corner":
//          case "@top-center":
//          case "@top-right":
//          case "@top-right-corner":
//          case "@bottom-left":
//          case "@bottom-left-corner":
//          case "@bottom-center":
//          case "@bottom-right":
//          case "@bottom-right-corner":
//          case "@left-top":
//          case "@left-middle":
//          case "@left-bottom":
//          case "@right-top":
//          case "@right-middle":
//          case "@right-bottom":
//              hasBlock = true;
//              isRooted = true;
//              break;
//          */
//          case "@counter-style":
//              hasIdentifier = true;
//              hasBlock = true;
//              break;
//          case "@charset":
//              hasIdentifier = true;
//              hasBlock = false;
//              break;
//          case "@namespace":
//              hasExpression = true;
//              hasBlock = false;
//              break;
//          case "@keyframes":
//              hasIdentifier = true;
//              break;
//          case "@host":
//          case "@page":
//              hasUnknown = true;
//              break;
//          case "@document":
//          case "@supports":
//              hasUnknown = true;
//              isRooted = false;
//              break;
//      }
//
//      parserInput.commentStore.length = 0;
//
//      if (hasIdentifier) {
//          value = this.entity();
//          if (!value) {
//              error("expected " + name + " identifier");
//          }
//      } else if (hasExpression) {
//          value = this.expression();
//          if (!value) {
//              error("expected " + name + " expression");
//          }
//      } else if (hasUnknown) {
//          value = (parserInput.$re(/^[^{;]+/) || '').trim();
//          if (value) {
//              value = new(tree.Anonymous)(value);
//          }
//      }
//
//      if (hasBlock) {
//          rules = this.blockRuleset();
//      }
//
//      if (rules || (!hasBlock && value && parserInput.$char(';'))) {
//          parserInput.forget();
//          return new (tree.Directive)(name, value, rules, index, fileInfo,
//              context.dumpLineNumbers ? getDebugInfo(index) : null,
//              false,
//              isRooted
//          );
//      }
//
//      parserInput.restore("directive options not recognised");
//  },
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
    Expression e;
    List<Expression> expressions = [];

    do {
      e = expression();
      if (e != null) {
        expressions.add(e);
        if (parserInput.$char(',') == null) break;
      }
    } while (e != null);

    if (expressions.isNotEmpty) return new Value(expressions);
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

  ///
  String important() {
    if (parserInput.currentChar() == '!') {
      return parserInput.$re(r'^! *important');
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
    Expression e;

    parserInput.save();
    if (parserInput.$char('(') != null) {
      a = addition();
      if (a != null && parserInput.$char(')') != null) {
        parserInput.forget();
        e  = new Expression([a]);
        e.parens = true;
        return e;
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

  ///
  Node multiplication() {
    Node a;
    bool isSpaced;
    Node m;
    String op;
    Operation operation;

    m = operand();
    if (m != null) {
      isSpaced = parserInput.isWhitespacePrevPos();
      while (true) {
        if (parserInput.peek(new RegExp(r'^\/[*\/]'))) break;

        parserInput.save();

        op = parserInput.$char('/');
        if (op == null) op = parserInput.$char('*');
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
        operation = new Operation(op, [operation != null ? operation : m, a], isSpaced);
        isSpaced = parserInput.isWhitespacePrevPos();
      }
      return operation != null ? operation : m;
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

  ///
  Node addition() {
    Node a;
    Node m;
    String op;
    Operation operation;
    bool isSpaced;

    m = multiplication();
    if (m != null) {
      isSpaced = parserInput.isWhitespacePrevPos();
      while (true) {
        op = parserInput.$re(r'^[-+]\s+');
        if (op == null && !isSpaced) op = parserInput.$char('+');
        if (op == null && !isSpaced) op = parserInput.$char('-');
        if (op == null) break;

        a = multiplication();
        if (a == null) break;

        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op, [operation != null ? operation : m, a], isSpaced);
        isSpaced = parserInput.isWhitespacePrevPos();
      }
      return operation != null ? operation : m;
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

  ///
  //to be passed to currentChunk.expect
  Node conditions() {
    Node a;
    Node b;
    Condition condition;
    int index = parserInput.i;

    a = this.condition();
    if (a != null) {
      while (true) {
        if (!parserInput.peek(new RegExp(r'^,\s*(not\s*)?\('))
            || (parserInput.$char(',') == null )) break;
        b = this.condition();
        if (b == null) break;

        condition = new Condition('or', condition != null ? condition : a, b, index);
      }
      return condition != null ? condition : a;
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
  Node condition() {
    int index = parserInput.i;
    bool negate = false;
    Node a;
    Node b;
    Condition c;
    String op;

    if (parserInput.$str('not') != null) negate = true;
    parserInput.expectChar('(');

    a = addition();
    if (a == null) a = entities.keyword();
    if (a == null) a = entities.quoted();
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
        b = addition();
        if (b == null) b = entities.keyword();
        if (b == null) b = entities.quoted();
        if (b != null) {
          c = new Condition(op, a, b, index, negate);
        } else {
          parserInput.error('expected expression');
        }
      } else {
        c = new Condition('=', a, new Keyword.True(), index, negate);
      }
      parserInput.expectChar(')');
      return parserInput.$str('and') != null ? new Condition('and', c, condition()) : c;
    }
    return null;

//2.4.0 20150321-1640
//  condition: function () {
//      var entities = this.entities, index = parserInput.i, negate = false,
//          a, b, c, op;
//
//      if (parserInput.$str("not")) { negate = true; }
//      expectChar('(');
//      a = this.addition() || entities.keyword() || entities.quoted();
//      if (a) {
//          if (parserInput.$char('>')) {
//              if (parserInput.$char('=')) {
//                  op = ">=";
//              } else {
//                  op = '>';
//              }
//          } else
//          if (parserInput.$char('<')) {
//              if (parserInput.$char('=')) {
//                  op = "<=";
//              } else {
//                  op = '<';
//              }
//          } else
//          if (parserInput.$char('=')) {
//              if (parserInput.$char('>')) {
//                  op = "=>";
//              } else if (parserInput.$char('<')) {
//                  op = '=<';
//              } else {
//                  op = '=';
//              }
//          }
//          if (op) {
//              b = this.addition() || entities.keyword() || entities.quoted();
//              if (b) {
//                  c = new(tree.Condition)(op, a, b, index, negate);
//              } else {
//                  error('expected expression');
//              }
//          } else {
//              c = new(tree.Condition)('=', a, new(tree.Keyword)('true'), index, negate);
//          }
//          expectChar(')');
//          return parserInput.$str("and") ? new(tree.Condition)('and', c, this.condition()) : c;
//      }
//  },
  }

  ///
  /// An operand is anything that can be part of an operation,
  /// such as a Color, or a Variable
  ///
  Node operand() {
    String negate;
    Node o;

    if (parserInput.peek(new RegExp(r'^-[@\(]'))) {
      negate = parserInput.$char('-');
    }
    o = sub();
    if (o == null) o = entities.dimension();
    if (o == null) o = entities.color();
    if (o == null) o = entities.variable();
    if (o == null) o = entities.call();

    if (negate != null) {
      o.parensInOp = true;
      o = new Negative(o);
    }

    return o;

//2.2.0
//  operand: function () {
//      var entities = this.entities, negate;
//
//      if (parserInput.peek(/^-[@\(]/)) {
//          negate = parserInput.$char('-');
//      }
//
//
//      var o = this.sub() || entities.dimension() ||
//              entities.color() || entities.variable() ||
//              entities.call();
//
//      if (negate) {
//          o.parensInOp = true;
//          o = new(tree.Negative)(o);
//      }
//
//      return o;
//  }
  }

  ///
  /// Expressions either represent mathematical operations,
  /// or white-space delimited Entities.
  ///
  ///     1px solid black
  ///     @var * 2
  ///
  Expression expression() {
    String delim;
    Node e;
    List<Node> entities = [];

    do {
      e = comment();
      if (e != null) {
        entities.add(e);
        continue;
      }

      e = addition();
      if (e == null) e = entity();
      if (e != null) {
        entities.add(e);
        // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
        if(!parserInput.peek(new RegExp(r'^\/[\/*]'))) {
          delim = parserInput.$char('/');
          if (delim != null) entities.add(new Anonymous(delim));
        }
      }
    } while (e != null);
    if (entities.isNotEmpty) return new Expression(entities);

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

  ///
  String property() => parserInput.$re(r'^(\*?-?[_a-zA-Z0-9-]+)\s*:');

//2.2.0
//  property: function () {
//      var name = parserInput.$re(/^(\*?-?[_a-zA-Z0-9-]+)\s*:/);
//      if (name) {
//          return name[1];
//      }
//  }

  /// Returns List<String> or List<Node>
  List ruleProperty() {
    List<int> index = [];
    int length = 0;
    List name = [];
    String s;

    parserInput.save();

    String simpleProperty = parserInput.$re(r'^([_a-zA-Z0-9-]+)\s*:');
    if (simpleProperty != null) {
      name = [new Keyword(simpleProperty)];
      parserInput.forget();
      return name;
    }

    bool match(String re) {
      int i = parserInput.i;
      String chunk = parserInput.$re(re);

      if (chunk != null) {
        index.add(i);
        name.add(chunk);
        return true;
      }
      return false;
    }

    match(r'^(\*?)');
    while (true){
      if (!match(r'^((?:[\w-]+)|(?:@\{[\w-]+\}))')) break;
    }

    if (name.length > 1 && match(r'^((?:\+_|\+)?)\s*:')) {
      parserInput.forget();

      // at last, we have the complete match now. move forward,
      // convert name particles to tree objects and return:
      if (name[0] == '') {
        name.removeAt(0);
        index.removeAt(0);
      }
      for (int k = 0; k < name.length; k++) {
        s = name[k];
        name[k] = (!s.startsWith('@'))
            ? new Keyword(s)
            : new Variable('@${s.substring(2, (s.length - 1))}', index[k], fileInfo);
      }
      return name;
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
  DebugInfo getDebugInfo(int index, [String xinputStream, Contexts xcontext]) {
    String filename = fileInfo.filename;

    return new DebugInfo(
        lineNumber: Utils.getLocation(index, input).line + 1,
        fileName: filename);

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
}
