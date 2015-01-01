//source: less/parser.js 1.7.5

part of parsers.dart;

/*
 * Mixins
 */
// source: less/parser.js 1.7.5 lines 1092-1325
class Mixin {
  Env env;
  CurrentChunk currentChunk;
  Parsers parsers;
  Entities entities;

  Mixin(Env this.env, CurrentChunk this.currentChunk, Parsers this.parsers, Entities this.entities);

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
  Node call() {
    List<MixinArgs> args;
    String c;
    String e;
    int elemIndex;
    Element elem;
    List<Element> elements;
    bool important = false;
    int index = currentChunk.i;
    String s = currentChunk.charAtPos();

    if (s != '.' && s != '#') return null;

    currentChunk.save(); // stop us absorbing part of an invalid selector

    while (true) {
      elemIndex = currentChunk.i;
      e = currentChunk.$re(r'^[#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+');
      if (e == null) break;
      elem = new Element(c, e, elemIndex, env.currentFileInfo);
      if (elements != null) { elements.add(elem); } else { elements = [elem]; }
      c = currentChunk.$char('>');
    }

    if (elements != null) {
      if (currentChunk.$char('(') != null) {
        args = this.args(true).args;
        currentChunk.expectChar(')');
      }
      if (parsers.important() != null) important = true;
      if (parsers.end()) {
        currentChunk.forget();
        return new MixinCall(elements, args, index, env.currentFileInfo, important);
      }
    }

    currentChunk.restore();
    return null;

//    call: function () {
//        var s = input.charAt(i), important = false, index = i, elemIndex,
//            elements, elem, e, c, args;
//
//        if (s !== '.' && s !== '#') { return; }
//
//        save(); // stop us absorbing part of an invalid selector
//
//        while (true) {
//            elemIndex = i;
//            e = $re(/^[#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+/);
//            if (!e) {
//                break;
//            }
//            elem = new(tree.Element)(c, e, elemIndex, env.currentFileInfo);
//            if (elements) { elements.push(elem); } else { elements = [ elem ]; }
//            c = $char('>');
//        }
//
//        if (elements) {
//            if ($char('(')) {
//                args = this.args(true).args;
//                expectChar(')');
//            }
//
//            if (parsers.important()) {
//                important = true;
//            }
//
//            if (parsers.end()) {
//                forget();
//                return new(tree.mixin.Call)(elements, args, index, env.currentFileInfo, important);
//            }
//        }
//
//        restore();
//    },
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

    currentChunk.save();

    while (true) {
      if (isCall) {
        arg = parsers.detachedRuleset();
        if (arg == null) arg = parsers.expression();
      } else {
        parsers.comments();
        if (currentChunk.charAtPos() == '.' && currentChunk.$re(r'^\.{3}') != null) {
          returner.variadic = true;
          if (currentChunk.$char(';') != null && !isSemiColonSeperated) isSemiColonSeperated = true;
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
        if (currentChunk.$char(':') != null) {
          if (expressions.isNotEmpty) {
            if (isSemiColonSeperated) currentChunk.error('Cannot mix ; and , as delimiter types');
            expressionContainsNamed = true;
          }

          // we do not support setting a ruleset as a default variable - it doesn't make sense
          // However if we do want to add it, there is nothing blocking it, just don't error
          // and remove isCall dependency below
          value = null;
          if (isCall) value = parsers.detachedRuleset();
          if (value == null) value = parsers.expression();

          if (value == null) {
            if (isCall) {
              currentChunk.error('could not understand value for named argument');
            } else {
              currentChunk.restore();
              returner.args = [];
              return returner;
            }
          }
          nameLoop = (name = val.name);
        } else if (!isCall && currentChunk.$re(r'^\.{3}') != null){
          returner.variadic = true;
          if (currentChunk.$char(';') != null && !isSemiColonSeperated) isSemiColonSeperated = true;
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

      if (currentChunk.$char(',') != null) continue;

      if (currentChunk.$char(';') != null || isSemiColonSeperated) {
        if (expressionContainsNamed) currentChunk.error('Cannot mix ; and , as delimiter types');

        isSemiColonSeperated = true;

        if (expressions.isNotEmpty) value = new Value(expressions);
        argsSemiColon.add(new MixinArgs(name: name, value: value));

        name = null;
        expressions = [];
        expressionContainsNamed = false;
      }
    }

    currentChunk.forget();
    returner.args = isSemiColonSeperated ? argsSemiColon : argsComma;
    return returner;

//    args: function (isCall) {
//        var parsers = parser.parsers, entities = parsers.entities,
//            returner = { args:null, variadic: false },
//            expressions = [], argsSemiColon = [], argsComma = [],
//            isSemiColonSeperated, expressionContainsNamed, name, nameLoop, value, arg;
//
//        save();
//
//        while (true) {
//            if (isCall) {
//                arg = parsers.detachedRuleset() || parsers.expression();
//            } else {
//                parsers.comments();
//                if (input.charAt(i) === '.' && $re(/^\.{3}/)) {
//                    returner.variadic = true;
//                    if ($char(";") && !isSemiColonSeperated) {
//                        isSemiColonSeperated = true;
//                    }
//                    (isSemiColonSeperated ? argsSemiColon : argsComma)
//                        .push({ variadic: true });
//                    break;
//                }
//                arg = entities.variable() || entities.literal() || entities.keyword();
//            }
//
//            if (!arg) {
//                break;
//            }
//
//            nameLoop = null;
//            if (arg.throwAwayComments) {
//                arg.throwAwayComments();
//            }
//            value = arg;
//            var val = null;
//
//            if (isCall) {
//                // Variable
//                if (arg.value && arg.value.length == 1) {
//                    val = arg.value[0];
//                }
//            } else {
//                val = arg;
//            }
//
//            if (val && val instanceof tree.Variable) {
//                if ($char(':')) {
//                    if (expressions.length > 0) {
//                        if (isSemiColonSeperated) {
//                            error("Cannot mix ; and , as delimiter types");
//                        }
//                        expressionContainsNamed = true;
//                    }
//
//                    // we do not support setting a ruleset as a default variable - it doesn't make sense
//                    // However if we do want to add it, there is nothing blocking it, just don't error
//                    // and remove isCall dependency below
//                    value = (isCall && parsers.detachedRuleset()) || parsers.expression();
//
//                    if (!value) {
//                        if (isCall) {
//                            error("could not understand value for named argument");
//                        } else {
//                            restore();
//                            returner.args = [];
//                            return returner;
//                        }
//                    }
//                    nameLoop = (name = val.name);
//                } else if (!isCall && $re(/^\.{3}/)) {
//                    returner.variadic = true;
//                    if ($char(";") && !isSemiColonSeperated) {
//                        isSemiColonSeperated = true;
//                    }
//                    (isSemiColonSeperated ? argsSemiColon : argsComma)
//                        .push({ name: arg.name, variadic: true });
//                    break;
//                } else if (!isCall) {
//                    name = nameLoop = val.name;
//                    value = null;
//                }
//            }
//
//            if (value) {
//                expressions.push(value);
//            }
//
//            argsComma.push({ name:nameLoop, value:value });
//
//            if ($char(',')) {
//                continue;
//            }
//
//            if ($char(';') || isSemiColonSeperated) {
//
//                if (expressionContainsNamed) {
//                    error("Cannot mix ; and , as delimiter types");
//                }
//
//                isSemiColonSeperated = true;
//
//                if (expressions.length > 1) {
//                    value = new(tree.Value)(expressions);
//                }
//                argsSemiColon.push({ name:name, value:value });
//
//                name = null;
//                expressions = [];
//                expressionContainsNamed = false;
//            }
//        }
//
//        forget();
//        returner.args = isSemiColonSeperated ? argsSemiColon : argsComma;
//        return returner;
//    },
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
    int index = currentChunk.i; //not in original
    String name;
    List<MixinArgs> params = [];
    List<Node> ruleset;
    bool variadic = false;

    if ((currentChunk.charAtPos() != '.' && currentChunk.charAtPos() != '#') || currentChunk.peek(new RegExp(r'^[^{]*\}'))) return null;

    currentChunk.save();

    name = currentChunk.$re(r'^([#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+)\s*\(');
    if (name != null) {
      MixinReturner argInfo = args(false);
      params = argInfo.args;
      variadic = argInfo.variadic;

      // .mixincall("@{a}");
      // looks a bit like a mixin definition..
      // also
      // .mixincall(@a: {rule: set;});
      // so we have to be nice and restore
      if (currentChunk.$char(')') == null) {
        currentChunk.furthest = currentChunk.i;
        currentChunk.restore();
        return null;
      }

      parsers.comments();

      if (currentChunk.$re(r'^when') != null) { // Guard
        cond = currentChunk.expect(parsers.conditions, 'expected condition');
      }

      ruleset = parsers.block();
      if (ruleset != null) {
        currentChunk.forget();
        return new MixinDefinition(name, params, ruleset, cond, variadic, index, env.currentFileInfo);
      } else {
        currentChunk.restore();
      }
    } else {
      currentChunk.forget();
    }

    return null;

//    definition: function () {
//        var name, params = [], match, ruleset, cond, variadic = false;
//        if ((input.charAt(i) !== '.' && input.charAt(i) !== '#') ||
//            peek(/^[^{]*\}/)) {
//            return;
//        }
//
//        save();
//
//        match = $re(/^([#.](?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+)\s*\(/);
//        if (match) {
//            name = match[1];
//
//            var argInfo = this.args(false);
//            params = argInfo.args;
//            variadic = argInfo.variadic;
//
//            // .mixincall("@{a}");
//            // looks a bit like a mixin definition..
//            // also
//            // .mixincall(@a: {rule: set;});
//            // so we have to be nice and restore
//            if (!$char(')')) {
//                furthest = i;
//                restore();
//                return;
//            }
//
//            parsers.comments();
//
//            if ($re(/^when/)) { // Guard
//                cond = expect(parsers.conditions, 'expected condition');
//            }
//
//            ruleset = parsers.block();
//
//            if (ruleset) {
//                forget();
//                return new(tree.mixin.Definition)(name, params, ruleset, cond, variadic);
//            } else {
//                restore();
//            }
//        } else {
//            forget();
//        }
//    }
//},
  }
}

/* ************************************************ */

class MixinReturner {
  List<MixinArgs> args;
  bool variadic;

  MixinReturner([this.args = null, this.variadic = false]);
}