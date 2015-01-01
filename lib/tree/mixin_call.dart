//source: less/tree/mixin.js 1.7.5 lines 4-152

part of tree.less;

class MixinCall extends Node implements EvalNode{
  int index;
  FileInfo currentFileInfo;
  bool important;

  Selector selector;
  List<Node> arguments;

  final String type = 'MixinCall';

  MixinCall(elements, List args, int this.index, FileInfo this.currentFileInfo, bool this.important) {
    this.selector = new Selector(elements);
    if (args != null && args.isNotEmpty) this.arguments = args;
  }

  ///
  void accept(Visitor visitor) {
    if (this.selector != null) this.selector = visitor.visit(this.selector);
    if (this.arguments != null) this.arguments = visitor.visitArray(this.arguments);
  }

  ///
  /// Search the MixinDefinition and ...
  ///
  eval(Env env) {
    List<MixinDefinition> mixins;
    MatchConditionNode mixin;
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

    DefaultFunc defaultFunc;
    if (env.defaultFunc == null) {
      env.defaultFunc = defaultFunc = new DefaultFunc();
    } else {
      defaultFunc = env.defaultFunc;
    }

    int defaultResult;
    final int defNone = 0;
    final int defTrue = 1;
    final int defFalse = 2;
    List<int> count; // length == 3
    var originalRuleset;

    if (this.arguments != null) {
      args = this.arguments.map((a) {
        return new MixinArgs(name: a.name, value: a.value.eval(env));
      }).toList();
    }

    // Search MixinDefinition
    for (i = 0; i < env.frames.length; i++) {
      if ((mixins = (env.frames[i] as VariableMixin).find(this.selector)).isNotEmpty) {
        isOneFound = true;

        // To make `default()` function independent of definition order we have two "subpasses" here.
        // At first we evaluate each guard *twice* (with `default() == true` and `default() == false`),
        // and build candidate list with corresponding flags. Then, when we know all possible matches,
        // we make a final decision.

        for (m = 0; m < mixins.length; m++) {
          mixin = mixins[m];
          isRecursive = false;
          for (f = 0; f < env.frames.length; f++) {
            if ((mixin is! MixinDefinition) && (mixin == env.frames[f].originalRuleset || mixin == env.frames[f])) {
              isRecursive = true;
              break;
            }
          }
          if (isRecursive) continue;

          if (mixin.matchArgs(args, env)) {
            candidate = new Candidate(mixin: mixin, group: defNone);

            if (mixin is MatchConditionNode) { // if (mixin.matchCondition)
              for (f = 0; f < 2; f++) {
                defaultFunc.value(f);
                conditionResult[f] = mixin.matchCondition(args, env);
              }
              if (conditionResult[0] || conditionResult[1]) {
                if (conditionResult[0] != conditionResult[1]) {
                  candidate.group = conditionResult[1] ? defTrue : defFalse;
                }
                candidates.add(candidate);
              }

            } else {
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
                message: 'Ambiguous use of `default()` found when matching for `' + this.format(args) + '`',
                index: this.index,
                filename: this.currentFileInfo.filename));
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
                mixin = new MixinDefinition('', [], mixin.rules, null, false, this.index, this.currentFileInfo);
                (mixin as MixinDefinition).originalRuleset = originalRuleset;
                if (originalRuleset != null) (mixin as MixinDefinition).id = originalRuleset.id;
              }
              rules.addAll((mixin as MixinDefinition).evalCall(env, args, this.important).rules);
            } catch (e, s) {
              //in js creates a new error and lost type: NameError -> SyntaxError
              LessError error = LessError.transform(e,
                  index: this.index,
                  filename: this.currentFileInfo.filename,
                  stackTrace: s);
              throw new LessExceptionError(error);
            }
          }
        }

        if (match) {
          if (this.currentFileInfo == null || !this.currentFileInfo.reference) {
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
          message: 'No matching definition was found for `' + this.format(args) + '`',
          index: this.index,
          filename: this.currentFileInfo.filename
      ));
    } else {
      throw new LessExceptionError(new LessError(
          type: 'Name',
          message: this.selector.toCSS(env).trim() + ' is undefined',
          index: this.index,
          filename: this.currentFileInfo.filename
      ));
    }

//      eval: function (env) {
//          var mixins, mixin, args, rules = [], match = false, i, m, f, isRecursive, isOneFound, rule,
//              candidates = [], candidate, conditionResult = [], defaultFunc = tree.defaultFunc,
//              defaultResult, defNone = 0, defTrue = 1, defFalse = 2, count, originalRuleset;
//
//          args = this.arguments && this.arguments.map(function (a) {
//              return { name: a.name, value: a.value.eval(env) };
//          });
//
//          for (i = 0; i < env.frames.length; i++) {
//              if ((mixins = env.frames[i].find(this.selector)).length > 0) {
//                  isOneFound = true;
//
//                  // To make `default()` function independent of definition order we have two "subpasses" here.
//                  // At first we evaluate each guard *twice* (with `default() == true` and `default() == false`),
//                  // and build candidate list with corresponding flags. Then, when we know all possible matches,
//                  // we make a final decision.
//
//                  for (m = 0; m < mixins.length; m++) {
//                      mixin = mixins[m];
//                      isRecursive = false;
//                      for(f = 0; f < env.frames.length; f++) {
//                          if ((!(mixin instanceof tree.mixin.Definition)) && mixin === (env.frames[f].originalRuleset || env.frames[f])) {
//                              isRecursive = true;
//                              break;
//                          }
//                      }
//                      if (isRecursive) {
//                          continue;
//                      }
//
//                      if (mixin.matchArgs(args, env)) {
//                          candidate = {mixin: mixin, group: defNone};
//
//                          if (mixin.matchCondition) {
//                              for (f = 0; f < 2; f++) {
//                                  defaultFunc.value(f);
//                                  conditionResult[f] = mixin.matchCondition(args, env);
//                              }
//                              if (conditionResult[0] || conditionResult[1]) {
//                                  if (conditionResult[0] != conditionResult[1]) {
//                                      candidate.group = conditionResult[1] ?
//                                          defTrue : defFalse;
//                                  }
//
//                                  candidates.push(candidate);
//                              }
//                          }
//                          else {
//                              candidates.push(candidate);
//                          }
//
//                          match = true;
//                      }
//                  }
//
//                  defaultFunc.reset();
//
//                  count = [0, 0, 0];
//                  for (m = 0; m < candidates.length; m++) {
//                      count[candidates[m].group]++;
//                  }
//
//                  if (count[defNone] > 0) {
//                      defaultResult = defFalse;
//                  } else {
//                      defaultResult = defTrue;
//                      if ((count[defTrue] + count[defFalse]) > 1) {
//                          throw { type: 'Runtime',
//                              message: 'Ambiguous use of `default()` found when matching for `'
//                                  + this.format(args) + '`',
//                              index: this.index, filename: this.currentFileInfo.filename };
//                      }
//                  }
//
//                  for (m = 0; m < candidates.length; m++) {
//                      candidate = candidates[m].group;
//                      if ((candidate === defNone) || (candidate === defaultResult)) {
//                          try {
//                              mixin = candidates[m].mixin;
//                              if (!(mixin instanceof tree.mixin.Definition)) {
//                                  originalRuleset = mixin.originalRuleset || mixin;
//                                  mixin = new tree.mixin.Definition("", [], mixin.rules, null, false);
//                                  mixin.originalRuleset = originalRuleset;
//                              }
//                              Array.prototype.push.apply(
//                                    rules, mixin.evalCall(env, args, this.important).rules);
//                          } catch (e) {
//                              throw { message: e.message, index: this.index, filename: this.currentFileInfo.filename, stack: e.stack };
//                          }
//                      }
//                  }
//
//                  if (match) {
//                      if (!this.currentFileInfo || !this.currentFileInfo.reference) {
//                          for (i = 0; i < rules.length; i++) {
//                              rule = rules[i];
//                              if (rule.markReferenced) {
//                                  rule.markReferenced();
//                              }
//                          }
//                      }
//                      return rules;
//                  }
//              }
//          }
//          if (isOneFound) {
//              throw { type:    'Runtime',
//                      message: 'No matching definition was found for `' + this.format(args) + '`',
//                      index:   this.index, filename: this.currentFileInfo.filename };
//          } else {
//              throw { type:    'Name',
//                      message: this.selector.toCSS().trim() + " is undefined",
//                      index:   this.index, filename: this.currentFileInfo.filename };
//          }
//      },
  }

  /// Returns a String with the Mixin arguments
  String format(List<MixinArgs> args) {
    String result = this.selector.toCSS(null).trim();
    String argsStr = (args != null)? args.map((a){
      String argValue = '';
      if (isNotEmpty(a.name)) argValue += a.name + ':';
      if (a.value is ToCSSNode) {
        argValue += a.value.toCSS(null);
      } else {
        argValue += '???';
      }
      return argValue;
    }).toList().join(', ') : '';

    return result + '(' + argsStr + ')';

//      format: function (args) {
//          return this.selector.toCSS().trim() + '(' +
//              (args ? args.map(function (a) {
//                  var argValue = "";
//                  if (a.name) {
//                      argValue += a.name + ":";
//                  }
//                  if (a.value.toCSS) {
//                      argValue += a.value.toCSS();
//                  } else {
//                      argValue += "???";
//                  }
//                  return argValue;
//              }).join(', ') : "") + ")";
//      }
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