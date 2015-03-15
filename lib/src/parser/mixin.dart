//source: less/parser.js 2.4.0+7 lines 578-810

part of parser.less;

/*
 * Mixins
 */

class Mixin {
  Contexts context;
  ParserInput parserInput;
  Parsers parsers;
  Entities entities;

  FileInfo fileInfo;

  Mixin(Contexts this.context, ParserInput this.parserInput, Parsers this.parsers, Entities this.entities) {
    this.fileInfo = context.currentFileInfo;
  }

  ///
  /// A Mixin call, with an optional argument list
  ///
  ///     #mixins > .square(#fff);
  ///     .rounded(4px, black);
  ///     .button;
  ///
  /// The `while` loop is there because mixins can be
  /// namespaced, but we only support the child and descendant
  /// selector for now.
  ///
  MixinCall call() {
    List<MixinArgs> args;
    String c;
    String e;
    int elemIndex;
    Element elem;
    List<Element> elements;
    bool important = false;
    int index = parserInput.i;
    String s = parserInput.currentChar();

    if (s != '.' && s != '#') return null;

    parserInput.save(); // stop us absorbing part of an invalid selector

    while (true) {
      elemIndex = parserInput.i;
      e = parserInput.$re(r'^[#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+');
      if (e == null) break;
      elem = new Element(c, e, elemIndex, fileInfo);
      if (elements != null) {
        elements.add(elem);
      } else {
        elements = [elem];
      }
      c = parserInput.$char('>');
    }

    if (elements != null) {
      if (parserInput.$char('(') != null) {
        args = this.args(true).args;
        parserInput.expectChar(')');
      }
      if (parsers.important() != null) important = true;
      if (parsers.end()) {
        parserInput.forget();
        return new MixinCall(elements, args, index, fileInfo, important);
      }
    }

    parserInput.restore();
    return null;

//2.4.0
//  call: function () {
//      var s = parserInput.currentChar(), important = false, index = parserInput.i, elemIndex,
//          elements, elem, e, c, args;
//
//      if (s !== '.' && s !== '#') { return; }
//
//      parserInput.save(); // stop us absorbing part of an invalid selector
//
//      while (true) {
//          elemIndex = parserInput.i;
//          e = parserInput.$re(/^[#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+/);
//          if (!e) {
//              break;
//          }
//          elem = new(tree.Element)(c, e, elemIndex, fileInfo);
//          if (elements) {
//              elements.push(elem);
//          } else {
//              elements = [ elem ];
//          }
//          c = parserInput.$char('>');
//      }
//
//      if (elements) {
//          if (parserInput.$char('(')) {
//              args = this.args(true).args;
//              expectChar(')');
//          }
//
//          if (parsers.important()) {
//              important = true;
//          }
//
//          if (parsers.end()) {
//              parserInput.forget();
//              return new(tree.mixin.Call)(elements, args, index, fileInfo, important);
//          }
//      }
//
//      parserInput.restore();
//  },
  }

  ///
  MixinReturner args(bool isCall) {
    Node arg;
    List argsComma = [];
    List argsSemiColon = [];
    bool expressionContainsNamed = false;
    List expressions = [];
    String name;
    String nameLoop;
    bool isSemiColonSeperated = false;
    MixinReturner returner = new MixinReturner();
    Node value;

    parserInput.save();

    while (true) {
      if (isCall) {
        arg = parsers.detachedRuleset();
        if (arg == null) arg = parsers.expression();
      } else {
        parserInput.commentStore.length = 0;
        if (parserInput.currentChar() == '.' && parserInput.$re(r'^\.{3}') != null) {
          returner.variadic = true;
          if (parserInput.$char(';') != null && !isSemiColonSeperated) isSemiColonSeperated = true;
          if (isSemiColonSeperated) { argsSemiColon.add(new MixinArgs(variadic: true)); } else { argsComma.add(new MixinArgs(variadic: true)); }
          break;
        }
        arg = entities.variable();
        if (arg == null) arg = entities.literal();
        if (arg == null) arg = entities.keyword();
      }

      if (arg == null) break;

      nameLoop = null;
      arg.throwAwayComments();
      value = arg;
      var val = null;

      if (isCall) {
        // Variable
        if (arg.value != null && arg.value.length == 1) val = arg.value[0];
      } else {
        val = arg;
      }

      if (val != null && val is Variable) {
        if (parserInput.$char(':') != null) {
          if (expressions.isNotEmpty) {
            if (isSemiColonSeperated) parserInput.error('Cannot mix ; and , as delimiter types');
            expressionContainsNamed = true;
          }

          value = parsers.detachedRuleset();
          if (value == null) value = parsers.expression();

          if (value == null) {
            if (isCall) {
              parserInput.error('could not understand value for named argument');
            } else {
              parserInput.restore();
              returner.args = [];
              return returner;
            }
          }
          nameLoop = (name = val.name);
        } else if (!isCall && parserInput.$re(r'^\.{3}') != null){
          returner.variadic = true;
          if (parserInput.$char(';') != null && !isSemiColonSeperated) isSemiColonSeperated = true;
          if (isSemiColonSeperated) { argsSemiColon.add(new MixinArgs(name: arg.name, variadic: true)); }
            else { argsComma.add(new MixinArgs(name: arg.name, variadic: true)); }
          break;
        } else if (!isCall) {
          name = nameLoop = val.name;
          value = null;
        }
      }

      if (value != null) expressions.add(value);

      argsComma.add(new MixinArgs(name: nameLoop, value: value));

      if (parserInput.$char(',') != null) continue;

      if (parserInput.$char(';') != null || isSemiColonSeperated) {
        if (expressionContainsNamed) parserInput.error('Cannot mix ; and , as delimiter types');

        isSemiColonSeperated = true;

        if (expressions.isNotEmpty) value = new Value(expressions);
        argsSemiColon.add(new MixinArgs(name: name, value: value));

        name = null;
        expressions = [];
        expressionContainsNamed = false;
      }
    }

    parserInput.forget();
    returner.args = isSemiColonSeperated ? argsSemiColon : argsComma;
    return returner;

//2.4.0+7
//    args: function (isCall) {
//      var entities = parsers.entities,
//          returner = { args:null, variadic: false },
//          expressions = [], argsSemiColon = [], argsComma = [],
//          isSemiColonSeparated, expressionContainsNamed, name, nameLoop, value, arg;
//
//      parserInput.save();
//
//      while (true) {
//          if (isCall) {
//              arg = parsers.detachedRuleset() || parsers.expression();
//          } else {
//              parserInput.commentStore.length = 0;
//              if (parserInput.currentChar() === '.' && parserInput.$re(/^\.{3}/)) {
//                  returner.variadic = true;
//                  if (parserInput.$char(";") && !isSemiColonSeparated) {
//                      isSemiColonSeparated = true;
//                  }
//                  (isSemiColonSeparated ? argsSemiColon : argsComma)
//                      .push({ variadic: true });
//                  break;
//              }
//              arg = entities.variable() || entities.literal() || entities.keyword();
//          }
//
//          if (!arg) {
//              break;
//          }
//
//          nameLoop = null;
//          if (arg.throwAwayComments) {
//              arg.throwAwayComments();
//          }
//          value = arg;
//          var val = null;
//
//          if (isCall) {
//              // Variable
//              if (arg.value && arg.value.length == 1) {
//                  val = arg.value[0];
//              }
//          } else {
//              val = arg;
//          }
//
//          if (val && val instanceof tree.Variable) {
//              if (parserInput.$char(':')) {
//                  if (expressions.length > 0) {
//                      if (isSemiColonSeparated) {
//                          error("Cannot mix ; and , as delimiter types");
//                      }
//                      expressionContainsNamed = true;
//                  }
//
//                  value = parsers.detachedRuleset() || parsers.expression();
//
//                  if (!value) {
//                      if (isCall) {
//                          error("could not understand value for named argument");
//                      } else {
//                          parserInput.restore();
//                          returner.args = [];
//                          return returner;
//                      }
//                  }
//                  nameLoop = (name = val.name);
//              } else if (!isCall && parserInput.$re(/^\.{3}/)) {
//                  returner.variadic = true;
//                  if (parserInput.$char(";") && !isSemiColonSeparated) {
//                      isSemiColonSeparated = true;
//                  }
//                  (isSemiColonSeparated ? argsSemiColon : argsComma)
//                      .push({ name: arg.name, variadic: true });
//                  break;
//              } else if (!isCall) {
//                  name = nameLoop = val.name;
//                  value = null;
//              }
//          }
//
//          if (value) {
//              expressions.push(value);
//          }
//
//          argsComma.push({ name:nameLoop, value:value });
//
//          if (parserInput.$char(',')) {
//              continue;
//          }
//
//          if (parserInput.$char(';') || isSemiColonSeparated) {
//
//              if (expressionContainsNamed) {
//                  error("Cannot mix ; and , as delimiter types");
//              }
//
//              isSemiColonSeparated = true;
//
//              if (expressions.length > 1) {
//                  value = new(tree.Value)(expressions);
//              }
//              argsSemiColon.push({ name:name, value:value });
//
//              name = null;
//              expressions = [];
//              expressionContainsNamed = false;
//          }
//      }
//
//      parserInput.forget();
//      returner.args = isSemiColonSeparated ? argsSemiColon : argsComma;
//      return returner;
//  },
  }

  ///
  /// A Mixin definition, with a list of parameters
  ///
  ///     .rounded (@radius: 2px, @color) {
  ///        ...
  ///     }
  ///
  /// Until we have a finer grained state-machine, we have to
  /// do a look-ahead, to make sure we don't have a mixin call.
  /// See the `rule` function for more information.
  ///
  /// We start by matching `.rounded (`, and then proceed on to
  /// the argument list, which has optional default values.
  /// We store the parameters in `params`, with a `value` key,
  /// if there is a value, such as in the case of `@radius`.
  ///
  /// Once we've got our params list, and a closing `)`, we parse
  /// the `{...}` block.
  ///
  MixinDefinition definition() {
    Condition cond;
    int index = parserInput.i; //not in original
    String name;
    List<MixinArgs> params = [];
    List<Node> ruleset;
    bool variadic = false;

    if ((parserInput.currentChar() != '.' && parserInput.currentChar() != '#') || parserInput.peek(new RegExp(r'^[^{]*\}'))) return null;

    parserInput.save();

    name = parserInput.$re(r'^([#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+)\s*\(');
    if (name != null) {
      MixinReturner argInfo = args(false);
      params = argInfo.args;
      variadic = argInfo.variadic;

      // .mixincall("@{a}");
      // looks a bit like a mixin definition..
      // also
      // .mixincall(@a: {rule: set;});
      // so we have to be nice and restore
      if (parserInput.$char(')') == null) {
        //parserInput.furthest = parserInput.i;
        parserInput.restore("Missing closing ')'");
        return null;
      }

      parserInput.commentStore.length = 0;

      if (parserInput.$re(r'^when') != null) { // Guard
        cond = parserInput.expect(parsers.conditions, 'expected condition');
      }

      ruleset = parsers.block();
      if (ruleset != null) {
        parserInput.forget();
        return new MixinDefinition(name, params, ruleset, cond, variadic, index, context.currentFileInfo);
      } else {
        parserInput.restore();
      }
    } else {
      parserInput.forget();
    }

    return null;

//2.2.0
//  definition: function () {
//      var name, params = [], match, ruleset, cond, variadic = false;
//      if ((parserInput.currentChar() !== '.' && parserInput.currentChar() !== '#') ||
//          parserInput.peek(/^[^{]*\}/)) {
//          return;
//      }
//
//      parserInput.save();
//
//      match = parserInput.$re(/^([#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+)\s*\(/);
//      if (match) {
//          name = match[1];
//
//          var argInfo = this.args(false);
//          params = argInfo.args;
//          variadic = argInfo.variadic;
//
//          // .mixincall("@{a}");
//          // looks a bit like a mixin definition..
//          // also
//          // .mixincall(@a: {rule: set;});
//          // so we have to be nice and restore
//          if (!parserInput.$char(')')) {
//              parserInput.restore("Missing closing ')'");
//              return;
//          }
//
//          parserInput.commentStore.length = 0;
//
//          if (parserInput.$re(/^when/)) { // Guard
//              cond = expect(parsers.conditions, 'expected condition');
//          }
//
//          ruleset = parsers.block();
//
//          if (ruleset) {
//              parserInput.forget();
//              return new(tree.mixin.Definition)(name, params, ruleset, cond, variadic);
//          } else {
//              parserInput.restore();
//          }
//      } else {
//          parserInput.forget();
//      }
//  }
  }
}

/* ************************************************ */

class MixinReturner {
  List<MixinArgs> args;
  bool variadic;

  MixinReturner([this.args = null, this.variadic = false]);
}