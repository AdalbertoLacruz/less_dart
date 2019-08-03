//source: tree/mixin-call.js 3.5.0.beta.4 20180630

part of tree.less;

///
class MixinCall extends Node {
  @override
  final String type = 'MixinCall';

  ///
  List<MixinArgs> arguments;

  ///
  bool important;

  ///
  Selector selector;

  ///
  MixinCall(List<Node> elements, List<MixinArgs> args,
      {int index, FileInfo currentFileInfo, this.important})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    selector = Selector(elements);
    arguments = args ?? <MixinArgs>[];
    allowRoot = true;
    setParent(selector, this);

//3.0.0 20160714
// var MixinCall = function (elements, args, index, currentFileInfo, important) {
//     this.selector = new Selector(elements);
//     this.arguments = args || [];
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.important = important;
//     this.allowRoot = true;
//     this.setParent(this.selector, this);
// };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField =>
      <String, dynamic>{'elements': elements, 'arguments': arguments};

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    if (selector != null) selector = visitor.visit(selector);
    if (arguments.isNotEmpty) arguments = visitor.visitArray(arguments);

//2.5.1 20150625
// MixinCall.prototype.accept = function (visitor) {
//     if (this.selector) {
//         this.selector = visitor.visit(this.selector);
//     }
//     if (this.arguments.length) {
//         this.arguments = visitor.visitArray(this.arguments);
//     }
// };
  }

  ///
  /// Search the MixinDefinition and ...
  ///
  //In js returns a List<Node>. Changed to Nodeset.rules = List<Node>
  //List<Node> eval(Contexts context) {
  @override
  Node eval(Contexts context) {
    final List<MixinArgs> args = <MixinArgs>[];
    final List<Candidate> candidates = <Candidate>[];
    final List<bool> conditionResult = <bool>[null, null];
    int defaultResult;
    bool isOneFound = false;
    bool isRecursive;
    bool match = false;
    List<Node> mixinPath;
    List<MixinFound> mixins;
    final List<Node> rules = <Node>[];

    DefaultFunc defaultFunc;
    if (context.defaultFunc == null) {
      context.defaultFunc = defaultFunc = DefaultFunc();
    } else {
      defaultFunc = context.defaultFunc;
    }

    final int defFalseEitherCase = -1;

    final int defNone = 0;
    final int defTrue = 1;
    final int defFalse = 2;

    selector = selector.eval(context);

    // mixin is Node, mixinPath is List<Node>
    int calcDefGroup(MatchConditionNode mixin, List<Node> mixinPath) {
      for (int f = 0; f < 2; f++) {
        conditionResult[f] = true;
        defaultFunc.value(f);
        for (int p = 0; p < mixinPath.length && conditionResult[f]; p++) {
          final Node namespace = mixinPath[p];
          if (namespace is MatchConditionNode) {
            conditionResult[f] = conditionResult[f] &&
                (namespace as MatchConditionNode).matchCondition(null, context);
          }
        }
        if (mixin is MatchConditionNode) {
          conditionResult[f] =
              conditionResult[f] && mixin.matchCondition(args, context);
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

    arguments.forEach((MixinArgs arg) {
      dynamic argValue = arg.value.eval(context);
      if (arg.expand && argValue.value is List) {
        argValue = argValue.value;
        for (int m = 0; m < argValue.length; m++) {
          args.add(MixinArgs(value: argValue[m]));
        }
      } else {
        args.add(MixinArgs(name: arg.name, value: argValue));
      }
    });

    bool noArgumentsFilter(MatchConditionNode rule) =>
        rule.matchArgs(null, context);

    // Search MixinDefinition
    for (int i = 0; i < context.frames.length; i++) {
      if ((mixins = (context.frames[i] as VariableMixin)
              .find(selector, null, noArgumentsFilter))
          .isNotEmpty) {
        isOneFound = true;

        // To make `default()` function independent of definition order we have two "subpasses" here.
        // At first we evaluate each guard *twice* (with `default() == true` and `default() == false`),
        // and build candidate list with corresponding flags. Then, when we know all possible matches,
        // we make a final decision.

        for (int m = 0; m < mixins.length; m++) {
          final MatchConditionNode mixin = mixins[m].rule as MatchConditionNode;
          mixinPath = mixins[m].path;
          isRecursive = false;
          for (int f = 0; f < context.frames.length; f++) {
            if ((mixin is! MixinDefinition) &&
                ((mixin as Node) == context.frames[f].originalRuleset ||
                    (mixin as Node) == context.frames[f])) {
              isRecursive = true;
              break;
            }
          }
          if (isRecursive) continue;

          if (mixin.matchArgs(args, context)) {
            final Candidate candidate =
                Candidate(mixin: mixin, group: calcDefGroup(mixin, mixinPath));
            if (candidate.group != defFalseEitherCase) {
              candidates.add(candidate);
            }
            match = true;
          }
        }

        defaultFunc.reset();

        final List<int> count = <int>[0, 0, 0];
        for (int m = 0; m < candidates.length; m++) {
          count[candidates[m].group]++;
        }

        if (count[defNone] > 0) {
          defaultResult = defFalse;
        } else {
          defaultResult = defTrue;
          if ((count[defTrue] + count[defFalse]) > 1) {
            throw LessExceptionError(LessError(
                type: 'Runtime',
                message:
                    'Ambiguous use of `default()` found when matching for `${format(args)}`',
                index: index,
                filename: currentFileInfo.filename));
          }
        }

        for (int m = 0; m < candidates.length; m++) {
          final int candidateGroup = candidates[m].group;
          if (candidateGroup == defNone || candidateGroup == defaultResult) {
            try {
              MatchConditionNode mixin = candidates[m].mixin;
              if (mixin is! MixinDefinition) {
                final Ruleset originalRuleset =
                    (mixin as Ruleset).originalRuleset ?? mixin;
                mixin = MixinDefinition('', <MixinArgs>[], mixin.rules, null,
                    variadic: false,
                    index: index,
                    currentFileInfo: currentFileInfo,
                    visibilityInfo: originalRuleset.visibilityInfo());
                (mixin as MixinDefinition).originalRuleset = originalRuleset;
                if (originalRuleset != null) {
                  (mixin as MixinDefinition).id = originalRuleset.id;
                }
              }
              final List<Node> newRules = (mixin as MixinDefinition)
                  .evalCall(context, args, important: important)
                  .rules;
              _setVisibilityToReplacement(newRules);
              rules.addAll(newRules);
            } catch (e, s) {
//              print("$e, $s");
              //in js creates a new error and lost type: NameError -> SyntaxError
              throw LessExceptionError(LessError.transform(e,
                  index: index,
                  filename: currentFileInfo.filename,
                  stackTrace: s));
            }
          }
        }

        if (match) {
          //return rules; in js
          return Nodeset(rules);
        }
      }
    }

    if (isOneFound) {
      throw LessExceptionError(LessError(
          type: 'Runtime',
          message: 'No matching definition was found for `${format(args)}`',
          index: index,
          filename: currentFileInfo.filename));
    } else {
      throw LessExceptionError(LessError(
          type: 'Name',
          message: '${selector.toCSS(context).trim()} is undefined',
          index: index,
          filename: currentFileInfo.filename));
    }

// 3.5.0.beta.4 20180630
//  MixinCall.prototype.eval = function (context) {
//      var mixins, mixin, mixinPath, args = [], arg, argValue,
//          rules = [], match = false, i, m, f, isRecursive, isOneFound,
//          candidates = [], candidate, conditionResult = [], defaultResult, defFalseEitherCase = -1,
//          defNone = 0, defTrue = 1, defFalse = 2, count, originalRuleset, noArgumentsFilter;
//
//      this.selector = this.selector.eval(context);
//
//      function calcDefGroup(mixin, mixinPath) {
//          var f, p, namespace;
//
//          for (f = 0; f < 2; f++) {
//              conditionResult[f] = true;
//              defaultFunc.value(f);
//              for (p = 0; p < mixinPath.length && conditionResult[f]; p++) {
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
//      for (i = 0; i < this.arguments.length; i++) {
//          arg = this.arguments[i];
//          argValue = arg.value.eval(context);
//          if (arg.expand && Array.isArray(argValue.value)) {
//              argValue = argValue.value;
//              for (m = 0; m < argValue.length; m++) {
//                  args.push({value: argValue[m]});
//              }
//          } else {
//              args.push({name: arg.name, value: argValue});
//          }
//      }
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
//                  for (f = 0; f < context.frames.length; f++) {
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
//                          index: this.getIndex(), filename: this.fileInfo().filename };
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
//                              mixin = new MixinDefinition('', [], mixin.rules, null, false, null, originalRuleset.visibilityInfo());
//                              mixin.originalRuleset = originalRuleset;
//                          }
//                          var newRules = mixin.evalCall(context, args, this.important).rules;
//                          this._setVisibilityToReplacement(newRules);
//                          Array.prototype.push.apply(rules, newRules);
//                      } catch (e) {
//                          throw { message: e.message, index: this.getIndex(), filename: this.fileInfo().filename, stack: e.stack };
//                      }
//                  }
//              }
//
//              if (match) {
//                  return rules;
//              }
//          }
//      }
//      if (isOneFound) {
//          throw { type:    'Runtime',
//              message: 'No matching definition was found for `' + this.format(args) + '`',
//              index:   this.getIndex(), filename: this.fileInfo().filename };
//      } else {
//          throw { type:    'Name',
//              message: this.selector.toCSS().trim() + ' is undefined',
//              index:   this.getIndex(), filename: this.fileInfo().filename };
//      }
//  };
  }

  ///
  void _setVisibilityToReplacement(List<Node> replacement) {
    if (blocksVisibility()) {
      replacement.forEach((Node rule) {
        rule.addVisibilityBlock();
      });
    }

//2.5.3 20151120
// MixinCall.prototype._setVisibilityToReplacement = function (replacement) {
//     var i, rule;
//     if (this.blocksVisibility()) {
//         for (i = 0; i < replacement.length; i++) {
//             rule = replacement[i];
//             rule.addVisibilityBlock();
//         }
//     }
// };
  }

  /// Returns a String with the Mixin arguments
  String format(List<MixinArgs> args) {
    final String result = selector.toCSS(null).trim();
    final String argsStr = (args != null)
        ? args.fold(StringBuffer(), (StringBuffer sb, MixinArgs a) {
            if (sb.isNotEmpty) sb.write(', ');
            if (isNotEmpty(a.name)) sb.write('${a.name}:');
            if (a.value is Node) {
              sb.write(a.value.toCSS(null));
            } else {
              sb.write('???');
            }
            return sb;
          }).toString()
        : '';
    return '$result($argsStr)';

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

  @override
  String toString() => format(arguments);
}

///
class MixinArgs {
  ///
  String name;

  ///
  Node value;

  ///
  bool variadic;

  ///
  bool expand;

  ///
  MixinArgs(
      {this.name, this.value, this.variadic = false, this.expand = false});

  ///
  void genTree(Contexts env, Output output, [String prefix = '']) {
    String tabStr = '  ' * env.tabLevel;
    output.add('$tabStr${prefix}MixinArgs (${toString()})\n');

    env.tabLevel = env.tabLevel + 2;
    tabStr = '  ' * env.tabLevel;

    if (name?.isNotEmpty ?? false) output.add('$tabStr.name: String ($name)\n');
    if (value != null) value.genTree(env, output, '.value: ');

    env.tabLevel = env.tabLevel - 2;
  }

  ///
  @override
  String toString() {
    final String _name = name ?? '';
    final String _value = (value != null) ? value.toString() : '';
    final String _separator = _value.isNotEmpty ? ': ' : '';

    return '$_name$_separator$_value';
  }
}

///
class Candidate {
  ///
  MatchConditionNode mixin;

  ///
  int group;

  ///
  Candidate({this.mixin, this.group});
}
