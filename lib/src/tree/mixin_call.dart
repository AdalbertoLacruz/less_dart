//source: tree/mixin-call.js 2.5.0

part of tree.less;

class MixinCall extends Node {
  int index;
  bool important;

  Selector selector;
  List<Node> arguments;

  final String type = 'MixinCall';

  ///
  MixinCall(elements, List args, int this.index, FileInfo currentFileInfo, bool this.important) {
    this.currentFileInfo = currentFileInfo;
    selector = new Selector(elements);
    if (args != null && args.isNotEmpty) this.arguments = args;

//2.3.1
//  var MixinCall = function (elements, args, index, currentFileInfo, important) {
//      this.selector = new Selector(elements);
//      this.arguments = (args && args.length) ? args : null;
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//      this.important = important;
//  };
  }

  ///
  void accept(Visitor visitor) {
    if (selector != null) selector = visitor.visit(selector);
    if (arguments != null) arguments = visitor.visitArray(arguments);

//2.3.1
//  MixinCall.prototype.accept = function (visitor) {
//      if (this.selector) {
//          this.selector = visitor.visit(this.selector);
//      }
//      if (this.arguments) {
//          this.arguments = visitor.visitArray(this.arguments);
//      }
//  };
  }

  ///
  /// Search the MixinDefinition and ...
  ///
  eval(Contexts context) {
    List<MixinFound> mixins;
    MatchConditionNode mixin;
    List<Node> mixinPath;
    List<MixinArgs> args;
    List<Node> rules = [];
    bool match = false;
    int i, m, f; // for counters
    bool isRecursive;
    bool isOneFound = false;
    Node rule;
    List<Candidate> candidates = [];
    Candidate candidate;
    List conditionResult = [null, null];
    int defaultResult;

    DefaultFunc defaultFunc;
    if (context.defaultFunc == null) {
      context.defaultFunc = defaultFunc = new DefaultFunc();
    } else {
      defaultFunc = context.defaultFunc;
    }

    int defFalseEitherCase = -1;

    final int defNone = 0;
    final int defTrue = 1;
    final int defFalse = 2;
    List<int> count; // length == 3
    Ruleset originalRuleset;

    // mixin is Node, mixinPath is List<Node>
    int calcDefGroup(mixin, List mixinPath) {
      var namespace;

      for (int f = 0; f < 2; f++) {
        conditionResult[f] = true;
        defaultFunc.value(f);
        for (int p = 0; p < mixinPath.length && conditionResult[f]; p++) {
          namespace = mixinPath[p];
          if (namespace is MatchConditionNode) {
            conditionResult[f] = conditionResult[f] && namespace.matchCondition(null, context);
          }
        }
        if (mixin is MatchConditionNode) {
          conditionResult[f] = conditionResult[f] && mixin.matchCondition(args, context);
        }
      }
      if (conditionResult[0] || conditionResult[1]) {
        if (conditionResult[0] != conditionResult[1]) {
          return conditionResult[1] ? defTrue : defFalse;
        }
        return defNone;
      }
      return defFalseEitherCase;
    }

    if (arguments != null) {
      args = arguments.map((a) {
        return new MixinArgs(name: a.name, value: a.value.eval(context));
      }).toList();
    }

    noArgumentsFilter(rule) => rule.matchArgs(null, context);

    // Search MixinDefinition
    for (i = 0; i < context.frames.length; i++) {
      if ((mixins = (context.frames[i] as VariableMixin).find(selector, null, noArgumentsFilter)).isNotEmpty) {
        isOneFound = true;

        // To make `default()` function independent of definition order we have two "subpasses" here.
        // At first we evaluate each guard *twice* (with `default() == true` and `default() == false`),
        // and build candidate list with corresponding flags. Then, when we know all possible matches,
        // we make a final decision.

        for (m = 0; m < mixins.length; m++) {
          mixin = mixins[m].rule as MatchConditionNode;
          mixinPath = mixins[m].path;
          isRecursive = false;
          for (f = 0; f < context.frames.length; f++) {
            if ((mixin is! MixinDefinition) && (mixin == context.frames[f].originalRuleset || mixin == context.frames[f])) {
              isRecursive = true;
              break;
            }
          }
          if (isRecursive) continue;

          if (mixin.matchArgs(args, context)) {
            candidate = new Candidate(mixin: mixin, group: calcDefGroup(mixin, mixinPath));

            if (candidate.group != defFalseEitherCase) {
              candidates.add(candidate);
            }

            match = true;
          }
        }

        defaultFunc.reset();

        count = [0, 0, 0];
        for (m = 0; m < candidates.length; m++) {
          count[candidates[m].group]++;
        }

        if (count[defNone] > 0) {
          defaultResult = defFalse;
        } else {
          defaultResult = defTrue;
          if ((count[defTrue] + count[defFalse]) > 1) {
            throw new LessExceptionError(new LessError(
                type: 'Runtime',
                message: 'Ambiguous use of `default()` found when matching for `' + format(args) + '`',
                index: index,
                filename: currentFileInfo.filename));
          }
        }

        for (m = 0; m < candidates.length; m++) {
          int candidateGroup = candidates[m].group;
          if (candidateGroup == defNone || candidateGroup == defaultResult) {
            try {
              mixin = candidates[m].mixin;
              if (mixin is! MixinDefinition) {
                originalRuleset = (mixin as Ruleset).originalRuleset;
                if (originalRuleset == null) originalRuleset = mixin;
                mixin = new MixinDefinition('', [], mixin.rules, null, false, index, currentFileInfo);
                (mixin as MixinDefinition).originalRuleset = originalRuleset;
                if (originalRuleset != null) (mixin as MixinDefinition).id = originalRuleset.id;
              }
              rules.addAll((mixin as MixinDefinition).evalCall(context, args, important).rules);
            } catch (e, s) {
//              print("$e, $s");
              //in js creates a new error and lost type: NameError -> SyntaxError
              LessError error = LessError.transform(e,
                  index: index,
                  filename: currentFileInfo.filename,
                  stackTrace: s);
              throw new LessExceptionError(error);
            }
          }
        }

        if (match) {
          if (currentFileInfo == null || !currentFileInfo.reference) {
            for (i = 0; i < rules.length; i++) {
              rule = rules[i];
              if (rule is MarkReferencedNode) (rule as MarkReferencedNode).markReferenced();
            }
          }
          return rules;
        }
      }
    }

    if (isOneFound) {
      throw new LessExceptionError(new LessError(
          type: 'Runtime',
          message: 'No matching definition was found for `' + format(args) + '`',
          index: index,
          filename: currentFileInfo.filename
      ));
    } else {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: selector.toCSS(context).trim() + ' is undefined',
          index: index,
          filename: currentFileInfo.filename
      ));
    }

//2.3.1
//  MixinCall.prototype.eval = function (context) {
//      var mixins, mixin, mixinPath, args, rules = [], match = false, i, m, f, isRecursive, isOneFound, rule,
//          candidates = [], candidate, conditionResult = [], defaultResult, defFalseEitherCase = -1,
//          defNone = 0, defTrue = 1, defFalse = 2, count, originalRuleset, noArgumentsFilter;
//
//      function calcDefGroup(mixin, mixinPath) {
//          var p, namespace;
//
//          for (f = 0; f < 2; f++) {
//              conditionResult[f] = true;
//              defaultFunc.value(f);
//              for(p = 0; p < mixinPath.length && conditionResult[f]; p++) {
//                  namespace = mixinPath[p];
//                  if (namespace.matchCondition) {
//                      conditionResult[f] = conditionResult[f] && namespace.matchCondition(null, context);
//                  }
//              }
//              if (mixin.matchCondition) {
//                  conditionResult[f] = conditionResult[f] && mixin.matchCondition(args, context);
//              }
//          }
//          if (conditionResult[0] || conditionResult[1]) {
//              if (conditionResult[0] != conditionResult[1]) {
//                  return conditionResult[1] ?
//                      defTrue : defFalse;
//              }
//
//              return defNone;
//          }
//          return defFalseEitherCase;
//      }
//
//      args = this.arguments && this.arguments.map(function (a) {
//          return { name: a.name, value: a.value.eval(context) };
//      });
//
//      noArgumentsFilter = function(rule) {return rule.matchArgs(null, context);};
//
//      for (i = 0; i < context.frames.length; i++) {
//          if ((mixins = context.frames[i].find(this.selector, null, noArgumentsFilter)).length > 0) {
//              isOneFound = true;
//
//              // To make `default()` function independent of definition order we have two "subpasses" here.
//              // At first we evaluate each guard *twice* (with `default() == true` and `default() == false`),
//              // and build candidate list with corresponding flags. Then, when we know all possible matches,
//              // we make a final decision.
//
//              for (m = 0; m < mixins.length; m++) {
//                  mixin = mixins[m].rule;
//                  mixinPath = mixins[m].path;
//                  isRecursive = false;
//                  for(f = 0; f < context.frames.length; f++) {
//                      if ((!(mixin instanceof MixinDefinition)) && mixin === (context.frames[f].originalRuleset || context.frames[f])) {
//                          isRecursive = true;
//                          break;
//                      }
//                  }
//                  if (isRecursive) {
//                      continue;
//                  }
//
//                  if (mixin.matchArgs(args, context)) {
//                      candidate = {mixin: mixin, group: calcDefGroup(mixin, mixinPath)};
//
//                      if (candidate.group !== defFalseEitherCase) {
//                          candidates.push(candidate);
//                      }
//
//                      match = true;
//                  }
//              }
//
//              defaultFunc.reset();
//
//              count = [0, 0, 0];
//              for (m = 0; m < candidates.length; m++) {
//                  count[candidates[m].group]++;
//              }
//
//              if (count[defNone] > 0) {
//                  defaultResult = defFalse;
//              } else {
//                  defaultResult = defTrue;
//                  if ((count[defTrue] + count[defFalse]) > 1) {
//                      throw { type: 'Runtime',
//                          message: 'Ambiguous use of `default()` found when matching for `' + this.format(args) + '`',
//                          index: this.index, filename: this.currentFileInfo.filename };
//                  }
//              }
//
//              for (m = 0; m < candidates.length; m++) {
//                  candidate = candidates[m].group;
//                  if ((candidate === defNone) || (candidate === defaultResult)) {
//                      try {
//                          mixin = candidates[m].mixin;
//                          if (!(mixin instanceof MixinDefinition)) {
//                              originalRuleset = mixin.originalRuleset || mixin;
//                              mixin = new MixinDefinition("", [], mixin.rules, null, false);
//                              mixin.originalRuleset = originalRuleset;
//                          }
//                          Array.prototype.push.apply(
//                              rules, mixin.evalCall(context, args, this.important).rules);
//                      } catch (e) {
//                          throw { message: e.message, index: this.index, filename: this.currentFileInfo.filename, stack: e.stack };
//                      }
//                  }
//              }
//
//              if (match) {
//                  if (!this.currentFileInfo || !this.currentFileInfo.reference) {
//                      for (i = 0; i < rules.length; i++) {
//                          rule = rules[i];
//                          if (rule.markReferenced) {
//                              rule.markReferenced();
//                          }
//                      }
//                  }
//                  return rules;
//              }
//          }
//      }
//      if (isOneFound) {
//          throw { type:    'Runtime',
//              message: 'No matching definition was found for `' + this.format(args) + '`',
//              index:   this.index, filename: this.currentFileInfo.filename };
//      } else {
//          throw { type:    'Name',
//              message: this.selector.toCSS().trim() + " is undefined",
//              index:   this.index, filename: this.currentFileInfo.filename };
//      }
//  };
  }

  /// Returns a String with the Mixin arguments
  String format(List<MixinArgs> args) {
    String result = selector.toCSS(null).trim();
    String argsStr = (args != null)? args.map((a){
      String argValue = '';
      if (isNotEmpty(a.name)) argValue += a.name + ':';
      if (a.value is Node) {
        argValue += a.value.toCSS(null);
      } else {
        argValue += '???';
      }
      return argValue;
    }).toList().join(', ') : '';

    return result + '(' + argsStr + ')';

//2.3.1
//  MixinCall.prototype.format = function (args) {
//      return this.selector.toCSS().trim() + '(' +
//          (args ? args.map(function (a) {
//              var argValue = "";
//              if (a.name) {
//                  argValue += a.name + ":";
//              }
//              if (a.value.toCSS) {
//                  argValue += a.value.toCSS();
//              } else {
//                  argValue += "???";
//              }
//              return argValue;
//          }).join(', ') : "") + ")";
//  };
  }
}

class MixinArgs {
  String name;
  Node value;
  bool variadic;

  MixinArgs({String this.name, Node this.value, bool this.variadic: false});
}

class Candidate {
  MatchConditionNode mixin;
  int group;

  Candidate({this.mixin, this.group});
}