//source: less/parser.js

library parsers.dart;

import '../less/env.dart';
import '../less/less_debug_info.dart';
import '../less/less_error.dart';
import '../nodejs/nodejs.dart';
import '../tree/tree.dart';

part 'current_chunk.dart';
part 'entities.dart';
part 'mixin.dart';

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
///  In general, most rules will try to parse a token with the `$()` function, and if the return
///  value is truly, will return a new node, of the relevant type. Sometimes, we need to check
///  first, before parsing, that's when we use `peek()`.
///
// less/parser.js 1.7.5 lines 0681-2093
class Parsers {
  Env env;
  CurrentChunk currentChunk;

  Entities entities;
  Mixin mixin;

  Parsers(Env this.env, List<String>chunks){
    currentChunk = new CurrentChunk(env, chunks);

    entities = new Entities(env, currentChunk, this);
    mixin = new Mixin(env, currentChunk, this, entities);
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
  //lines 726-746
  List<Node> primary(){
    var node;
    List root = [];

    while(currentChunk.noEmpty){
      node = extendRule();
      if (node == null) node = mixin.definition();
      if (node == null) node = rule();
      if (node == null) node = ruleset();
      if (node == null) node = mixin.call();
      if (node == null) node = comment();
      if (node == null) node = rulesetCall();
      if (node == null) node = directive();

      if (node != null) {
        root.add(node);
      } else {
        if (!(currentChunk.$re(r'^[\s\n]+') != null  || currentChunk.$re(r'^;+') != null)) break;
      }
      if (currentChunk.peekChar('}')) break;
    }

    return root;

//    primary: function () {
//        var mixin = this.mixin, $re = _$re, root = [], node;
//
//        while (current)
//        {
//            node = this.extendRule() || mixin.definition() || this.rule() || this.ruleset() ||
//                mixin.call() || this.comment() || this.rulesetCall() || this.directive();
//            if (node) {
//                root.push(node);
//            } else {
//                if (!($re(/^[\s\n]+/) || $re(/^;+/))) {
//                    break;
//                }
//            }
//            if (peekChar('}')) {
//                break;
//            }
//        }
//
//        return root;
//    },
  }

  /// check if input is empty. Else throw error.
  isFinished() => currentChunk.isFinished();

  ///
  /// We create a Comment node for CSS comments `/* */`,
  /// but keep the LeSS comments `//` silent, by just skipping
  /// over them.
  ///
  Comment comment(){
    String comment;
    int i = currentChunk.i;

    if (currentChunk.charAtPos() != '/') return null;

    if (currentChunk.charAtNextPos() == '/') return new Comment(currentChunk.$re(r'^\/\/.*'), true, i, env.currentFileInfo);

    comment = currentChunk.$re(r'^\/\*(?:[^*]|\*+[^\/*])*\*+\/\n?');
    if (comment != null) return new Comment(comment, false, i, env.currentFileInfo);

    return null;
  }

  ///
  List comments(){
    Comment comment;
    List<Comment> comments = [];

    while (true) {
      comment = this.comment();
      if (comment == null) break;
      comments.add(comment);
    }

    return comments;

//
//comments: function () {
//    var comment, comments = [];
//
//    while(true) {
//        comment = this.comment();
//        if (!comment) {
//            break;
//        }
//        comments.push(comment);
//    }
//
//    return comments;
//},
  }

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///      @fink:
  ///
  String variable(){
    String name;

    if (currentChunk.charAtPos() == '@' && (name = currentChunk.$re(r'^(@[\w-]+)\s*:')) != null) return name;
    return null;

//variable: function () {
//    var name;
//
//    if (input.charAt(i) === '@' && (name = $re(/^(@[\w-]+)\s*:/))) { return name[1]; }
//},
  }

  ///
  /// The variable part of a variable definition. Used in the `rule` parser
  ///
  ///       @fink();
  ///
  RulesetCall rulesetCall(){
    String name;

    if (currentChunk.charAtPos() == '@') {
      name = currentChunk.$re(r'^(@[\w-]+)\s*\(\s*\)\s*;');
      if (name != null) return new RulesetCall(name);
    }

    return null;

//rulesetCall: function () {
//    var name;
//
//    if (input.charAt(i) === '@' && (name = $re(/^(@[\w-]+)\s*\(\s*\)\s*;/))) {
//        return new tree.RulesetCall(name[1]);
//    }
//},
  }

  ///
  // extend syntax - used to extend selectors
  ///
  List<Extend> extend([bool isRule = false]) {
    Element e;
    List<Element> elements;
    Extend extend;
    List<Extend> extendedList;
    int index = currentChunk.i;
    String option;

    if ((isRule ? currentChunk.$re(r'^&:extend\(') : currentChunk.$re(r'^:extend\(')) == null) return null;

    do {
      option = null;
      elements = null;
      while((option = currentChunk.$re(r'^(all)(?=\s*(\)|,))', true, 1)) == null) {
        e = element();
        if (e == null) break;
        if (elements != null) { elements.add(e); } else { elements = [e]; }
      }

      if (elements == null) currentChunk.error('Missing target selector for :extend().');
      extend = new Extend(new Selector(elements), option, index);
      if (extendedList != null) { extendedList.add(extend); } else { extendedList = [extend]; }

    } while (currentChunk.$char(',') != null);

    currentChunk.expect(new RegExp(r'^\)'));
    if (isRule) currentChunk.expect(new RegExp(r'^;'));

    return extendedList;

//extend: function(isRule) {
//    var elements, e, index = i, option, extendList, extend;
//
//    if (!(isRule ? $re(/^&:extend\(/) : $re(/^:extend\(/))) { return; }
//
//    do {
//        option = null;
//        elements = null;
//        while (! (option = $re(/^(all)(?=\s*(\)|,))/))) {
//            e = this.element();
//            if (!e) { break; }
//            if (elements) { elements.push(e); } else { elements = [ e ]; }
//        }
//
//        option = option && option[1];
//        if (!elements)
//            error("Missing target selector for :extend().");
//        extend = new(tree.Extend)(new(tree.Selector)(elements), option, index);
//        if (extendList) { extendList.push(extend); } else { extendList = [ extend ]; }
//
//    } while($char(","));
//
//    expect(/^\)/);
//
//    if (isRule) {
//        expect(/^;/);
//    }
//
//    return extendList;
//},
  }

  /// extendRule - used in a rule to extend all the parent selectors
  List<Extend> extendRule() => extend(true);

  ///
  /// Entities are the smallest recognized token,
  /// and can be found inside a rule's value.
  ///
  Node entity() {
    Node                result = entities.literal();
    if (result == null) result = entities.variable();
    if (result == null) result = entities.url();
    if (result == null) result = entities.call();
    if (result == null) result = entities.keyword();
    if (result == null) result = entities.javascript();
    if (result == null) result = comment();
    return result;
  }

  ///
  /// A Rule terminator. Note that we use `peek()` to check for '}',
  /// because the `block` rule will be expecting it, but we still need to make sure
  /// it's there, if ';' was ommitted.
  ///
  bool end() {
    return (currentChunk.$char(';') != null) || currentChunk.peekChar('}');

//end: function () {
//    return $char(';') || peekChar('}');
//},
  }

  /*
   * IE's alpha function
   *
   *     alpha(opacity=88)
   */
  //see entities.alpha()
//  alpha() {
//alpha: function () {
//    var value;
//
//    if (! $re(/^\(opacity=/i)) { return; }
//    value = $re(/^\d+/) || this.entities.variable();
//    if (value) {
//        expectChar(')');
//        return new(tree.Alpha)(value);
//    }
//},
//  }

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
    int index = currentChunk.i;
    Selector v;

    c = combinator();

    e = currentChunk.$re(r'^(?:\d+\.\d+|\d+)%');
    if (e == null) e = currentChunk.$re(r'^(?:[.#]?|:*)(?:[\w-]|[^\x00-\x9f]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+');
    if (e == null) e = currentChunk.$char('*');
    if (e == null) e = currentChunk.$char('&');
    if (e == null) e = attribute();
    if (e == null) e = currentChunk.$re(r'^\([^()@]+\)');
    if (e == null) e = currentChunk.$re(r'^[\.#](?=@)');
    if (e == null) e = entities.variableCurly();

    if (e == null) {
      currentChunk.save();
      if (currentChunk.$char('(') != null) {
        if((v = selector()) != null && currentChunk.$char(')') != null) {
          e = new Paren(v);
          currentChunk.forget();
        } else {
          currentChunk.restore();
        }
      } else {
        currentChunk.forget();
      }
    }

    if (e != null) {
      return new Element(c, e, index, env.currentFileInfo);
    }

    return null;

//element: function () {
//    var e, c, v, index = i;
//
//    c = this.combinator();
//
//    e = $re(/^(?:\d+\.\d+|\d+)%/) || $re(/^(?:[.#]?|:*)(?:[\w-]|[^\x00-\x9f]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+/) ||
//        $char('*') || $char('&') || this.attribute() || $re(/^\([^()@]+\)/) || $re(/^[\.#](?=@)/) ||
//        this.entities.variableCurly();
//
//    if (! e) {
//        save();
//        if ($char('(')) {
//            if ((v = this.selector()) && $char(')')) {
//                e = new(tree.Paren)(v);
//                forget();
//            } else {
//                restore();
//            }
//        } else {
//            forget();
//        }
//    }
//
//    if (e) { return new(tree.Element)(c, e, index, env.currentFileInfo); }
//},
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
    String c = currentChunk.charAtPos();

    if (c == '/') {
      currentChunk.save();
      String slashedCombinator = currentChunk.$re(r'^\/[a-z]+\/', false); //i-nsensitive
      if (slashedCombinator != null) {
        currentChunk.forget();
        return new Combinator(slashedCombinator);
      }
      currentChunk.restore();
    }

    if (c == '>' || c == '+' || c == '~' || c == '|' || c == '^') {
      currentChunk.i++;
      if (c == '^' && currentChunk.charAtPos() == '^') {
        c = '^^';
        currentChunk.i++;
      }
      while (currentChunk.isWhitespacePos()) { currentChunk.i++; }
      return new Combinator(c);
    } else if (currentChunk.isWhitespacePrevPos()) {
      return new Combinator(' ');
    } else {
      return new Combinator(null);
    }

//combinator: function () {
//    var c = input.charAt(i);
//
//    if (c === '/') {
//        save();
//        var slashedCombinator = $re(/^\/[a-z]+\//i);
//        if (slashedCombinator) {
//            forget();
//            return new(tree.Combinator)(slashedCombinator);
//        }
//        restore();
//    }
//
//    if (c === '>' || c === '+' || c === '~' || c === '|' || c === '^') {
//        i++;
//        if (c === '^' && input.charAt(i) === '^') {
//            c = '^^';
//            i++;
//        }
//        while (isWhitespace(input, i)) { i++; }
//        return new(tree.Combinator)(c);
//    } else if (isWhitespace(input, i - 1)) {
//        return new(tree.Combinator)(" ");
//    } else {
//        return new(tree.Combinator)(null);
//    }
//},
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
    String  c;
    Condition condition;
    Element e;
    List<Element> elements;
    List<Extend> extend;
    List extendList;
    int index = currentChunk.i;
    String when;

    while ((isLess && (extend = this.extend()) != null) ||
        (isLess && (when = currentChunk.$re(r'^when')) != null) ||
        (e = element()) != null) {
      if (when != null) {
        condition = currentChunk.expect(conditions, 'expected condition');
      } else if (condition != null) {
        currentChunk.error('CSS guard can only be used at the end of selector');
      } else if (extend != null) {
        if (extendList != null) { extendList.add(extend); } else { extendList = [extend]; }
      } else {
        if (extendList != null) currentChunk.error('Extend can only be used at the end of selector');
        c = currentChunk.charAtPos();
        if (elements != null) { elements.add(e); } else { elements = [e]; }
        e = null;
      }
      if (c == '{' || c == '}' || c == ';' || c == ',' || c == ')' ) break;
    }

    if (elements != null) return new Selector(elements, extendList, condition, index, env.currentFileInfo);
    if (extendList != null) currentChunk.error('Extend must be used to extend a selector, it cannot be used on its own');

    return null;

//selector: function (isLess) {
//    var index = i, $re = _$re, elements, extendList, c, e, extend, when, condition;
//
//    while ((isLess && (extend = this.extend())) || (isLess && (when = $re(/^when/))) || (e = this.element())) {
//        if (when) {
//            condition = expect(this.conditions, 'expected condition');
//        } else if (condition) {
//            error("CSS guard can only be used at the end of selector");
//        } else if (extend) {
//            if (extendList) { extendList.push(extend); } else { extendList = [ extend ]; }
//        } else {
//            if (extendList) { error("Extend can only be used at the end of selector"); }
//            c = input.charAt(i);
//            if (elements) { elements.push(e); } else { elements = [ e ]; }
//            e = null;
//        }
//        if (c === '{' || c === '}' || c === ';' || c === ',' || c === ')') {
//            break;
//        }
//    }
//
//    if (elements) { return new(tree.Selector)(elements, extendList, condition, index, env.currentFileInfo); }
//    if (extendList) { error("Extend must be used to extend a selector, it cannot be used on its own"); }
//},
  }

  ///
  Attribute attribute() {
    if (currentChunk.$char('[') == null) return null;

    var key; //String or Node
    String op;
    var val; //String or Node

    if ((key = entities.variableCurly()) == null) {
      key = currentChunk.expect(new RegExp(r'^(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+'));
    }

    op = currentChunk.$re(r'^[|~*$^]?=');
    if (op != null) {
      val = entities.quoted();
      if (val == null) val = currentChunk.$re(r'^[0-9]+%');
      if (val == null) val = currentChunk.$re(r'^[\w-]+');
      if (val == null) val = entities.variableCurly();
    }

    currentChunk.expectChar(']');
    return new Attribute(key, op, val);

//attribute: function () {
//    if (! $char('[')) { return; }
//
//    var entities = this.entities,
//        key, val, op;
//
//    if (!(key = entities.variableCurly())) {
//        key = expect(/^(?:[_A-Za-z0-9-\*]*\|)?(?:[_A-Za-z0-9-]|\\.)+/);
//    }
//
//    op = $re(/^[|~*$^]?=/);
//    if (op) {
//        val = entities.quoted() || $re(/^[0-9]+%/) || $re(/^[\w-]+/) || entities.variableCurly();
//    }
//
//    expectChar(']');
//
//    return new(tree.Attribute)(key, op, val);
//},
  }

  ///
  /// The `block` rule is used by `ruleset` and `mixin.definition`.
  /// It's a wrapper around the `primary` rule, with added `{}`.
  ///
  List<Node> block() {
    List<Node> content;

    if (currentChunk.$char('{') != null && (content = primary()) != null && currentChunk.$char('}') != null){
      return content;
    }

    return null;

//block: function () {
//    var content;
//    if ($char('{') && (content = this.primary()) && $char('}')) {
//        return content;
//    }
//},
  }

  ///
  Ruleset blockRuleset() {
    List<Node> block = this.block();

    return (block != null) ? new Ruleset(null, block) : null;

//blockRuleset: function() {
//    var block = this.block();
//
//    if (block) {
//        block = new tree.Ruleset(null, block);
//    }
//    return block;
//},
  }

  ///
  DetachedRuleset detachedRuleset() {
    Ruleset blockRuleset = this.blockRuleset();
    return (blockRuleset != null) ? new DetachedRuleset(blockRuleset) : null;

//detachedRuleset: function() {
//    var blockRuleset = this.blockRuleset();
//    if (blockRuleset) {
//        return new tree.DetachedRuleset(blockRuleset);
//    }
//},
  }

  ///
  // div, .class, body > p {...}
  ///
  Ruleset ruleset() {
    LessDebugInfo debugInfo;
    List<Node> rules;
    Selector s;
    List<Selector> selectors;

    currentChunk.save();

    if (isNotEmpty(env.dumpLineNumbers)) debugInfo = LessError.getDebugInfo(currentChunk.i, currentChunk.input, env);

    while (true) {
      s = lessSelector();
      if (s == null) break;
      if (selectors != null) { selectors.add(s); } else { selectors = [s]; }
      comments();
      if (s.condition != null && selectors.length > 1) {
        currentChunk.error('Guards are only currently allowed on a single selector.');
      }
      if (currentChunk.$char(',') == null) break;
      if (s.condition != null) {
        currentChunk.error('Guards are only currently allowed on a single selector.');
      }
      comments();
    }

    if (selectors != null && (rules = block()) != null) {
      currentChunk.forget();
      Ruleset ruleset = new Ruleset(selectors, rules, env.strictImports);
      if (isNotEmpty(env.dumpLineNumbers)) ruleset.debugInfo = debugInfo;
      return ruleset;
    } else {
      // Backtrack
      currentChunk.furthest = currentChunk.i;
      currentChunk.restore();
    }
    return null;

//ruleset: function () {
//    var selectors, s, rules, debugInfo;
//
//    save();
//
//    if (env.dumpLineNumbers) {
//        debugInfo = getDebugInfo(i, input, env);
//    }
//
//    while (true) {
//        s = this.lessSelector();
//        if (!s) {
//            break;
//        }
//        if (selectors) { selectors.push(s); } else { selectors = [ s ]; }
//        this.comments();
//        if (s.condition && selectors.length > 1) {
//            error("Guards are only currently allowed on a single selector.");
//        }
//        if (! $char(',')) { break; }
//        if (s.condition) {
//            error("Guards are only currently allowed on a single selector.");
//        }
//        this.comments();
//    }
//
//    if (selectors && (rules = this.block())) {
//        forget();
//        var ruleset = new(tree.Ruleset)(selectors, rules, env.strictImports);
//        if (env.dumpLineNumbers) {
//            ruleset.debugInfo = debugInfo;
//        }
//        return ruleset;
//    } else {
//        // Backtrack
//        furthest = i;
//        restore();
//    }
//},
  }

  ///
  Node rule([tryAnonymous = false]) {
    String c = currentChunk.charAtPos();
    String important;
    bool isVariable;
    String merge = '';
    var name; //String or Node
    int startOfRule = currentChunk.i;
    Node value;

    if (c == '.' || c == '#' || c == '&') return null;

    currentChunk.save();

    name = variable();
    if (name == null) name = ruleProperty();

    if (name != null) {
      isVariable = name is String;

      if (isVariable) value = detachedRuleset();

      comments();
      if (value == null) {
        // prefer to try to parse first if its a variable or we are compressing
        // but always fallback on the other one
        if (!tryAnonymous && (env.compress || isVariable)) {
          value = this.value();
          if (value == null) value = anonymousValue();
        } else {
          value = anonymousValue();
          if (value == null) value = this.value();
        }

        important = this.important();

        // a name returned by this.ruleProperty() is always an array of the form:
        // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
        // where each item is a tree.Keyword or tree.Variable
        merge = !isVariable ? (name as List<Node>).removeLast().value : '';
        //merge = !isVariable && (name as List<Node>).removeLast().value;
      }

      if (value != null && end()) {
        currentChunk.forget();
        return new Rule(name, value, important, merge, startOfRule, env.currentFileInfo);
      } else {
        currentChunk.furthest = currentChunk.i;
        currentChunk.restore();
        if (value != null && !tryAnonymous) return rule(true);
      }
    } else {
      currentChunk.forget();
    }

    return null;

//rule: function (tryAnonymous) {
//    var name, value, startOfRule = i, c = input.charAt(startOfRule), important, merge, isVariable;
//
//    if (c === '.' || c === '#' || c === '&') { return; }
//
//    save();
//
//    name = this.variable() || this.ruleProperty();
//    if (name) {
//        isVariable = typeof name === "string";
//
//        if (isVariable) {
//            value = this.detachedRuleset();
//        }
//
//        this.comments();
//        if (!value) {
//            // prefer to try to parse first if its a variable or we are compressing
//            // but always fallback on the other one
//            value = !tryAnonymous && (env.compress || isVariable) ?
//                (this.value() || this.anonymousValue()) :
//                (this.anonymousValue() || this.value());
//
//            important = this.important();
//
//            // a name returned by this.ruleProperty() is always an array of the form:
//            // [string-1, ..., string-n, ""] or [string-1, ..., string-n, "+"]
//            // where each item is a tree.Keyword or tree.Variable
//            merge = !isVariable && name.pop().value;
//        }
//
//        if (value && this.end()) {
//            forget();
//            return new (tree.Rule)(name, value, important, merge, startOfRule, env.currentFileInfo);
//        } else {
//            furthest = i;
//            restore();
//            if (value && !tryAnonymous) {
//                return this.rule(true);
//            }
//        }
//    } else {
//        forget();
//    }
//},
  }

  ///
  Anonymous anonymousValue() {
    //Match match = new RegExp(r'^([^@+\/' + r"'" + r'"*`(;{}-]*);').firstMatch(currentChunk.current);
    Match match = new RegExp(r'''^([^@+\/'"*`(;{}-]*);''').firstMatch(currentChunk.current);
    if (match != null) {
      currentChunk.i += match[0].length - 1;
      return new Anonymous(match[1]);
    }
    return null;

//anonymousValue: function () {
//    var match;
//    match = /^([^@+\/'"*`(;{}-]*);/.exec(current);
//    if (match) {
//        i += match[0].length - 1;
//        return new(tree.Anonymous)(match[1]);
//    }
//},
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
    int index = currentChunk.i;
    List<Node> features;
    Value nodeFeatures;
    ImportOptions options = new ImportOptions();
    Node path;

    String dir = currentChunk.$re(r'^@import?\s+');

    if (dir != null) {
      options = importOptions();
      if (options == null) options = new ImportOptions();

      path = entities.quoted();
      if (path == null) path = entities.url();
      if (path != null) {
        features = mediaFeatures();
        if (currentChunk.$(';') == null) {
          currentChunk.i = index;
          currentChunk.error('missing semi-colon or unrecognised media features on import');
        }
        if (features != null) nodeFeatures = new Value(features);
        return new Import(path, nodeFeatures, options, index, env.currentFileInfo);
      } else {
        currentChunk.i = index;
        currentChunk.error('malformed import statement');
      }
    }

    return null;

//"import": function () {
//    var path, features, index = i;
//
//    var dir = $re(/^@import?\s+/);
//
//    if (dir) {
//        var options = (dir ? this.importOptions() : null) || {};
//
//        if ((path = this.entities.quoted() || this.entities.url())) {
//            features = this.mediaFeatures();
//
//            if (!$(';')) {
//                i = index;
//                error("missing semi-colon or unrecognised media features on import");
//            }
//            features = features && new(tree.Value)(features);
//            return new(tree.Import)(path, features, options, index, env.currentFileInfo);
//        }
//        else
//        {
//            i = index;
//            error("malformed import statement");
//        }
//    }
//},
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
    if (currentChunk.$char('(') == null) return null;
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
        if(currentChunk.$char(',') == null) break;
      }
    } while (o != null);
    currentChunk.expectChar(')');
    return options;
  }

  ///
  String importOption() => currentChunk.$re('^(less|css|multiple|once|inline|reference)');

  ///
  Expression mediaFeature() {
    Node e;
    List<Node> nodes = [];
    String p;

    do {
      e = entities.keyword();
      if (e == null) e = entities.variable();
      if (e != null) {
        nodes.add(e);
      } else if (currentChunk.$char('(') != null) {
        p = property();
        e = value();
        if (currentChunk.$char(')') != null) {
          if (p != null && e != null) {
            nodes.add(new Paren(new Rule(p, e, null, null, currentChunk.i, env.currentFileInfo, true)));
          } else if (e != null) {
            nodes.add(new Paren(e));
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
    } while (e != null);

    if (nodes.isNotEmpty) return new Expression(nodes);

    return null;

//mediaFeature: function () {
//    var entities = this.entities, nodes = [], e, p;
//    do {
//        e = entities.keyword() || entities.variable();
//        if (e) {
//            nodes.push(e);
//        } else if ($char('(')) {
//            p = this.property();
//            e = this.value();
//            if ($char(')')) {
//                if (p && e) {
//                    nodes.push(new(tree.Paren)(new(tree.Rule)(p, e, null, null, i, env.currentFileInfo, true)));
//                } else if (e) {
//                    nodes.push(new(tree.Paren)(e));
//                } else {
//                    return null;
//                }
//            } else { return null; }
//        }
//    } while (e);
//
//    if (nodes.length > 0) {
//        return new(tree.Expression)(nodes);
//    }
//},
  }

  ///
  List<Node> mediaFeatures() {
    Node e;
    List<Node> features = [];

    do{
      e = mediaFeature();
      if (e != null) {
        features.add(e);
        if (currentChunk.$char(',') == null) break;
      } else {
        e = entities.variable();
        if (e != null) {
          features.add(e);
          if (currentChunk.$char(',') == null) break;
        }
      }
    } while (e != null);

    return features.isNotEmpty ? features : null;

//mediaFeatures: function () {
//    var entities = this.entities, features = [], e;
//    do {
//       e = this.mediaFeature();
//        if (e) {
//            features.push(e);
//            if (! $char(',')) { break; }
//        } else {
//            e = entities.variable();
//            if (e) {
//                features.push(e);
//                if (! $char(',')) { break; }
//            }
//        }
//    } while (e);
//
//    return features.length > 0 ? features : null;
//},
  }

  ///
  Media media() {
    LessDebugInfo debugInfo;
    List<Node> features;
    Media media;
    List<Node> rules;

    if (isNotEmpty(env.dumpLineNumbers)) debugInfo = LessError.getDebugInfo(currentChunk.i, currentChunk.input, env);

    if (currentChunk.$re(r'^@media') != null) {
      features = mediaFeatures();

      rules = block();
      if (rules != null) {
        media = new Media(rules, features, currentChunk.i, env.currentFileInfo);
        if (isNotEmpty(env.dumpLineNumbers)) media.debugInfo = debugInfo;
        return media;
      }
    }
    return null;

//media: function () {
//    var features, rules, media, debugInfo;
//
//    if (env.dumpLineNumbers) {
//        debugInfo = getDebugInfo(i, input, env);
//    }
//
//    if ($re(/^@media/)) {
//        features = this.mediaFeatures();
//
//        rules = this.block();
//        if (rules) {
//            media = new(tree.Media)(rules, features, i, env.currentFileInfo);
//            if (env.dumpLineNumbers) {
//                media.debugInfo = debugInfo;
//            }
//            return media;
//        }
//    }
//},
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
    int index = currentChunk.i;
    String name;
    String nonVendorSpecificName;
    Ruleset rules;
    Node value;

    if (currentChunk.charAtPos() != '@') return null;

    value = import();
    if (value == null) value = media();
    if (value != null) return value;

    currentChunk.save();

    name = currentChunk.$re(r'^@[a-z-]+');
    if (name == null) return null;

    nonVendorSpecificName = name;
    if (name[1] == '-' && name.indexOf('-', 2) > 0) nonVendorSpecificName = '@' + name.substring(name.indexOf('-', 2) + 1);

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
        break;
      */

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
      case '@document':
      case '@supports':
        hasUnknown = true;
        break;
    }

    comments();

    if (hasIdentifier) {
      value = entity();
      if (value == null) currentChunk.error('expected $name identifier');
    } else if (hasExpression) {
      value = expression();
      if (value == null) currentChunk.error('expected $name expression');
    } else if (hasUnknown) {
      String unknown = getValueOrDefault(currentChunk.$re(r'^[^{;]+'), '').trim();
      if (isNotEmpty(unknown)) value = new Anonymous(unknown);
    }

    comments();

    if (hasBlock) rules = blockRuleset();

    if (rules != null || (!hasBlock && value != null && currentChunk.$char(';') != null)) {
      currentChunk.forget();
      return new Directive(name, value, rules, index, env.currentFileInfo,
          isNotEmpty(env.dumpLineNumbers) ? LessError.getDebugInfo(index, currentChunk.input, env) : null);
    }

    currentChunk.restore();
    return null;

//directive: function () {
//    var index = i, name, value, rules, nonVendorSpecificName,
//        hasIdentifier, hasExpression, hasUnknown, hasBlock = true;
//
//    if (input.charAt(i) !== '@') { return; }
//
//    value = this['import']() || this.media();
//    if (value) {
//        return value;
//    }
//
//    save();
//
//    name = $re(/^@[a-z-]+/);
//
//    if (!name) { return; }
//
//    nonVendorSpecificName = name;
//    if (name.charAt(1) == '-' && name.indexOf('-', 2) > 0) {
//        nonVendorSpecificName = "@" + name.slice(name.indexOf('-', 2) + 1);
//    }
//
//    switch(nonVendorSpecificName) {
//        /*
//        case "@font-face":
//        case "@viewport":
//        case "@top-left":
//        case "@top-left-corner":
//        case "@top-center":
//        case "@top-right":
//        case "@top-right-corner":
//        case "@bottom-left":
//        case "@bottom-left-corner":
//        case "@bottom-center":
//        case "@bottom-right":
//        case "@bottom-right-corner":
//        case "@left-top":
//        case "@left-middle":
//        case "@left-bottom":
//        case "@right-top":
//        case "@right-middle":
//        case "@right-bottom":
//            hasBlock = true;
//            break;
//        */
//        case "@charset":
//            hasIdentifier = true;
//            hasBlock = false;
//            break;
//        case "@namespace":
//            hasExpression = true;
//            hasBlock = false;
//            break;
//        case "@keyframes":
//            hasIdentifier = true;
//            break;
//        case "@host":
//        case "@page":
//        case "@document":
//        case "@supports":
//            hasUnknown = true;
//            break;
//    }
//
//    this.comments();
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
//        value = ($re(/^[^{;]+/) || '').trim();
//        if (value) {
//            value = new(tree.Anonymous)(value);
//        }
//    }
//
//    this.comments();
//
//    if (hasBlock) {
//        rules = this.blockRuleset();
//    }
//
//    if (rules || (!hasBlock && value && $char(';'))) {
//        forget();
//        return new(tree.Directive)(name, value, rules, index, env.currentFileInfo,
//            env.dumpLineNumbers ? getDebugInfo(index, input, env) : null);
//    }
//
//    restore();
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
    Expression e;
    List<Expression> expressions = [];

    do {
      e = expression();
      if (e != null) {
        expressions.add(e);
        if (currentChunk.$char(',') == null) break;
      }
    } while (e != null);

    if (expressions.isNotEmpty) return new Value(expressions);
    return null;

//value: function () {
//    var e, expressions = [];
//
//    do {
//        e = this.expression();
//        if (e) {
//            expressions.push(e);
//            if (! $char(',')) { break; }
//        }
//    } while(e);
//
//    if (expressions.length > 0) {
//        return new(tree.Value)(expressions);
//    }
//},
  }

  ///
  String important() {
    if (currentChunk.charAtPos() == '!') return currentChunk.$re(r'^! *important');
    return null;

//important: function () {
//    if (input.charAt(i) === '!') {
//        return $re(/^! *important/);
//    }
//},
  }

  ///
  Expression sub() {
    Node a;
    Expression e;

    if (currentChunk.$char('(') != null) {
      a = addition();
      if (a != null) {
        e  = new Expression([a]);
        currentChunk.expectChar(')');
        e.parens = true;
        return e;
      }
    }
    return null;

//sub: function () {
//    var a, e;
//
//    if ($char('(')) {
//        a = this.addition();
//        if (a) {
//            e = new(tree.Expression)([a]);
//            expectChar(')');
//            e.parens = true;
//            return e;
//        }
//    }
//},
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
      isSpaced = currentChunk.isWhitespacePrevPos();
      while (true) {
        if (currentChunk.peek(new RegExp(r'^\/[*\/]'))) break;

        currentChunk.save();

        op = currentChunk.$char('/');
        if (op == null) op = currentChunk.$char('*');
        if (op == null) {
          currentChunk.forget();
          break;
        }

        a = operand();
        if (a == null) {
          currentChunk.restore();
          break;
        }

        currentChunk.forget();
        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op, [operation != null ? operation : m, a], isSpaced);
        isSpaced = currentChunk.isWhitespacePrevPos();
      }
      return operation != null ? operation : m;
    }
    return null;

//multiplication: function () {
//    var m, a, op, operation, isSpaced;
//    m = this.operand();
//    if (m) {
//        isSpaced = isWhitespace(input, i - 1);
//        while (true) {
//            if (peek(/^\/[*\/]/)) {
//                break;
//            }
//
//            save();
//
//            op = $char('/') || $char('*');
//
//            if (!op) { forget(); break; }
//
//            a = this.operand();
//
//            if (!a) { restore(); break; }
//            forget();
//
//            m.parensInOp = true;
//            a.parensInOp = true;
//            operation = new(tree.Operation)(op, [operation || m, a], isSpaced);
//            isSpaced = isWhitespace(input, i - 1);
//        }
//        return operation || m;
//    }
//},
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
      isSpaced = currentChunk.isWhitespacePrevPos();
      while (true) {
        op = currentChunk.$re(r'^[-+]\s+');
        if (op == null && !isSpaced) op = currentChunk.$char('+');
        if (op == null && !isSpaced) op = currentChunk.$char('-');
        if (op == null) break;

        a = multiplication();
        if (a == null) break;

        m.parensInOp = true;
        a.parensInOp = true;
        operation = new Operation(op, [operation != null ? operation : m, a], isSpaced);
        isSpaced = currentChunk.isWhitespacePrevPos();
      }
      return operation != null ? operation : m;
    }
    return null;

//addition: function () {
//    var m, a, op, operation, isSpaced;
//    m = this.multiplication();
//    if (m) {
//        isSpaced = isWhitespace(input, i - 1);
//        while (true) {
//            op = $re(/^[-+]\s+/) || (!isSpaced && ($char('+') || $char('-')));
//            if (!op) {
//                break;
//            }
//            a = this.multiplication();
//            if (!a) {
//                break;
//            }
//
//            m.parensInOp = true;
//            a.parensInOp = true;
//            operation = new(tree.Operation)(op, [operation || m, a], isSpaced);
//            isSpaced = isWhitespace(input, i - 1);
//        }
//        return operation || m;
//    }
//},
  }

  //to be passed to currentChunk.expect
  Node conditions() {
    Node a;
    Node b;
    Condition condition;
    int index = currentChunk.i;

    a = this.condition();
    if (a != null) {
      while (true) {
        if (!currentChunk.peek(new RegExp(r'^,\s*(not\s*)?\('))
            || (currentChunk.$char(',') == null )) break;
        b = this.condition();
        if (b == null) break;

        condition = new Condition('or', condition != null ? condition : a, b, index);
      }
      return condition != null ? condition : a;
    }

    return null;

//conditions: function () {
//    var a, b, index = i, condition;
//
//    a = this.condition();
//    if (a) {
//        while (true) {
//            if (!peek(/^,\s*(not\s*)?\(/) || !$char(',')) {
//                break;
//            }
//            b = this.condition();
//            if (!b) {
//                break;
//            }
//            condition = new(tree.Condition)('or', condition || a, b, index);
//        }
//        return condition || a;
//    }
//},
  }

  ///
  Node condition() {
    int index = currentChunk.i;
    bool negate = false;
    Node a;
    Node b;
    Condition c;
    String op;

    if (currentChunk.$re(r'^not') != null) negate = true;
    currentChunk.expectChar('(');

    a = addition();
    if (a == null) a = entities.keyword();
    if (a == null) a = entities.quoted();
    if (a != null) {
      op = currentChunk.$re(r'^(?:>=|<=|=<|[<=>])');
      if (op != null) {
        b = addition();
        if (b == null) b = entities.keyword();
        if (b == null) b = entities.quoted();
        if (b != null) {
          c = new Condition(op, a, b, index, negate);
        } else {
          currentChunk.error('expected expression');
        }
      } else {
        c = new Condition('=', a, new Keyword.True(), index, negate);
      }
      currentChunk.expectChar(')');
      return currentChunk.$re(r'^and') != null ? new Condition('and', c, condition()) : c;
    }
    return null;

//condition: function () {
//    var entities = this.entities, index = i, negate = false,
//        a, b, c, op;
//
//    if ($re(/^not/)) { negate = true; }
//    expectChar('(');
//    a = this.addition() || entities.keyword() || entities.quoted();
//    if (a) {
//        op = $re(/^(?:>=|<=|=<|[<=>])/);
//        if (op) {
//            b = this.addition() || entities.keyword() || entities.quoted();
//            if (b) {
//                c = new(tree.Condition)(op, a, b, index, negate);
//            } else {
//                error('expected expression');
//            }
//        } else {
//            c = new(tree.Condition)('=', a, new(tree.Keyword)('true'), index, negate);
//        }
//        expectChar(')');
//        return $re(/^and/) ? new(tree.Condition)('and', c, this.condition()) : c;
//    }
//},
  }

  ///
  /// An operand is anything that can be part of an operation,
  /// such as a Color, or a Variable
  ///
  Node operand() {
    String negate;
    Node o;
    String p = currentChunk.charAtNextPos();

    if (currentChunk.charAtPos() == '-' && (p == '@' || p == '(')) negate = currentChunk.$char('-');
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

//
//operand: function () {
//    var entities = this.entities,
//        p = input.charAt(i + 1), negate;
//
//    if (input.charAt(i) === '-' && (p === '@' || p === '(')) { negate = $char('-'); }
//    var o = this.sub() || entities.dimension() ||
//            entities.color() || entities.variable() ||
//            entities.call();
//
//    if (negate) {
//        o.parensInOp = true;
//        o = new(tree.Negative)(o);
//    }
//
//    return o;
//},
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
      e = addition();
      if (e == null) e = entity();
      if (e != null) {
        entities.add(e);
        // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
        if(!currentChunk.peek(new RegExp(r'^\/[\/*]'))) {
          delim = currentChunk.$char('/');
          if (delim != null) entities.add(new Anonymous(delim));
        }
      }
    } while (e != null);
    if (entities.isNotEmpty) return new Expression(entities);

    return null;

//expression: function () {
//    var entities = [], e, delim;
//
//    do {
//        e = this.addition() || this.entity();
//        if (e) {
//            entities.push(e);
//            // operations do not allow keyword "/" dimension (e.g. small/20px) so we support that here
//            if (!peek(/^\/[\/*]/)) {
//                  delim = $char('/');
//                  if (delim) {
//                      entities.push(new(tree.Anonymous)(delim));
//                  }
//              }
//          }
//      } while (e);
//      if (entities.length > 0) {
//          return new(tree.Expression)(entities);
//      }
//  },
  }

  ///
  String property() => currentChunk.$re(r'^(\*?-?[_a-zA-Z0-9-]+)\s*:');

//  property: function () {
//      var name = $re(/^(\*?-?[_a-zA-Z0-9-]+)\s*:/);
//      if (name) {
//          return name[1];
//      }
//  },

  ///
  List<String> ruleProperty() {
    String c = currentChunk.current;
    List<int> index = [];
    int length = 0;
    List<String> name = [];
    String s;

    List<String> match(String sre) {
      RegExp re = new RegExp(sre);
      Match a = re.firstMatch(c);
      if (a != null) {
        index.add(currentChunk.i + length);
        length += a[0].length;
        c = c.substring(a[1].length);
        return name..add(a[1]);
      }
      return null;
    }
//      function match(re) {
//          var a = re.exec(c);
//          if (a) {
//              index.push(i + length);
//              length += a[0].length;
//              c = c.slice(a[1].length);
//              return name.push(a[1]);
//          }
//      }

    ///
    bool cutOutBlockComments() {
      //match block comments
      Match a = new RegExp(r'^\s*\/\*(?:[^*]|\*+[^\/*])*\*+\/').firstMatch(c);
      if (a != null) {
        length += a[0].length;
        c = c.substring(a[0].length);
        return true;
      }
      return false;
    }

    match(r'^(\*?)');
    while (match(r'^((?:[\w-]+)|(?:@\{[\w-]+\}))') != null); // !
    while (cutOutBlockComments());
    if (name.length > 1 && match(r'^\s*((?:\+_|\+)?)\s*:') != null) { // /^\s*((?:\+_|\+)?)\s*:/
      // at last, we have the complete match now. move forward,
      // convert name particles to tree objects and return:
      currentChunk.skipWhitespace(length);
      if (name[0] == '') {
        name.removeAt(0);
        index.removeAt(0);
      }
      for (int k = 0; k < name.length; k++) {
        s = name[k];
        name[k] = (!s.startsWith('@'))
            ? new Keyword(s)
            : new Variable('@${s.substring(2, (s.length - 1))}', index[k], env.currentFileInfo);
      }
      return name;
    }
    return null;

//  ruleProperty: function () {
//      var c = current, name = [], index = [], length = 0, s, k;
//
//      function match(re) {
//          var a = re.exec(c);
//          if (a) {
//              index.push(i + length);
//              length += a[0].length;
//              c = c.slice(a[1].length);
//              return name.push(a[1]);
//          }
//      }
//      function cutOutBlockComments() {
//          //match block comments
//          var a = /^\s*\/\*(?:[^*]|\*+[^\/*])*\*+\//.exec(c);
//          if (a) {
//              length += a[0].length;
//              c = c.slice(a[0].length);
//              return true;
//          }
//          return false;
//      }
//
//      match(/^(\*?)/);
//      while (match(/^((?:[\w-]+)|(?:@\{[\w-]+\}))/)); // !
//      while (cutOutBlockComments());
//      if ((name.length > 1) && match(/^\s*((?:\+_|\+)?)\s*:/)) {
//          // at last, we have the complete match now. move forward,
//          // convert name particles to tree objects and return:
//          skipWhitespace(length);
//          if (name[0] === '') {
//              name.shift();
//              index.shift();
//          }
//          for (k = 0; k < name.length; k++) {
//              s = name[k];
//              name[k] = (s.charAt(0) !== '@')
//                  ? new(tree.Keyword)(s)
//                  : new(tree.Variable)('@' + s.slice(2, -1),
//                      index[k], env.currentFileInfo);
//          }
//          return name;
//      }
//  }
  }
}