//source: less/tree/mixin.js 1.7.5 lines 154-314

part of tree.less;

class MixinDefinition extends Node with VariableMixin implements EvalNode, MatchConditionNode {
  /// Same as Selector
  String name;

  /// Mixin params
  List<MixinArgs> params;

  /// Mixin body
  List<Node> rules;

  /// when (condition) {}
  Node condition;

  /// Arguments number is variable
  bool variadic;

  /// Same as name
  List<Node> selectors;

  //not in original
  int index;
  FileInfo currentFileInfo;

  var frames;


  /// Number of params
  int arity;

  Ruleset originalRuleset;

  /// Arguments number required
  int required;

  //var _lookups = {};
  //var parent;

  final String type = 'MixinDefinition';

  //index, currentFileInfo not in original. See order when calling with frames.
  /// name, params, rules, condition, variadic, index, currentFileInfo, frames
  MixinDefinition(String this.name, List<MixinArgs> this.params,
      List<Node> this.rules, Node this.condition, bool this.variadic,
      int this.index, FileInfo this.currentFileInfo, [this.frames]) {

    this.selectors = [new Selector([new Element(null, name, this.index, this.currentFileInfo)])];
    this.arity = this.params.length;

    this.required = params.fold(0, (count , p){
      if (p.name == null || (p.name != null && p.value == null)) { return count + 1; }
      else { return count; }
    });

    //this.parent = Ruleset; //VariableMixin replaces this structure
  }

  ///
  void accept(Visitor visitor) {
    if (this.params != null && this.params.isNotEmpty) {
      this.params = visitor.visitArray(this.params);
    }
    this.rules = visitor.visitArray(this.rules);
    if (this.condition != null) visitor.visit(this.condition);
  }

// VariableMixin

//variable(String name) {
//    variable:  function (name) { return this.parent.variable.call(this, name); },
//}
//
// returns the variables list if exist, else creates it. #
//Map<String, Node> variables(){
//  Map<String, Node> _variables = (this.rules == null) ? {} : this.rules.fold({}, (hash, r){
//      if (r is Rule && r.variable) {
//        hash[r.name] = r;
//      }
//      return hash;
//    });
//  return _variables;
//}
//variables() {
//    variables: function ()     { return this.parent.variables.call(this); },
//}
//
//  find() {
////    find:      function ()     { return this.parent.find.apply(this, arguments); },
//  }
//
//  rulesets() {
////    rulesets:  function ()     { return this.parent.rulesets.apply(this); },
//  }

  ///
  /// Build a Ruleset where the rules are the mixin params evaluated
  /// Build evaldArguments
  Ruleset evalParams(Env env, Env mixinEnv, List<MixinArgs> args, List evaldArguments) {
    Ruleset frame = new Ruleset(null, null);
    List<Node> varargs;
    MixinArgs arg;
    List<MixinArgs> params = this.params.sublist(0);
    int i, j;
    var val;
    String name;
    bool isNamedFound;
    int argIndex;
    int argsLength = 0;

    //Fill with nulls the list
    evaldArguments.length = math.max(
        (params != null) ? params.length : 0,
        (args != null)   ? args.length : 0);

    mixinEnv = new Env.evalEnv(mixinEnv,
                             [frame]..addAll(mixinEnv.frames));

    if (args != null) {
      args = args.sublist(0);
      argsLength = args.length;

      for (i = 0; i < args.length; i++) {
        arg = args[i];
        name = (arg != null) ? arg.name : null;
        if (name != null) {
          isNamedFound = false;
          for (j = 0; j < params.length; j++) {
            if (evaldArguments[j] == null && name == params[j].name) {
              evaldArguments[j] = arg.value.eval(env);
              frame.prependRule(new Rule(name, arg.value.eval(env)));
              isNamedFound = true;
              break;
            }
          }
          if (isNamedFound) {
            args.removeAt(i);
            i--;
            continue;
          } else {
            throw new LessExceptionError(new LessError(
                type: 'Runtime',
                message: 'Named argument for ${this.name} ${args[i].name}  not found'
                ));
          }
        }
      }
    }

    argIndex = 0;
    for (i = 0; i < params.length; i++) {
      if (i < evaldArguments.length && evaldArguments[i] != null) continue;

      arg = (args != null && argIndex < args.length) ? args[argIndex] : null;

      if ((name = params[i].name) != null) {
        if (params[i].variadic) {
          varargs = [];
          for (j = argIndex; j < argsLength; j++) {
            varargs.add(args[j].value.eval(env));
          }
          frame.prependRule(new Rule(name, new Expression(varargs).eval(env)));
        } else {
          val = (arg != null) ? arg.value : null;
          if (val != null) {
            val = val.eval(env);
          } else if (params[i].value != null) {
            val = params[i].value.eval(mixinEnv);
            frame.resetCache();
          } else {
            throw new LessExceptionError(new LessError(
                type: 'Runtime',
                message: 'wrong number of arguments for ${this.name} (${argsLength} for ${this.arity})'));
          }
          frame.prependRule(new Rule(name, val));
          evaldArguments[i] = val;
        }
      }
      if (params[i].variadic && args != null) {
        for (j = argIndex; j < argsLength; j++) {
          evaldArguments[j] = args[j].value.eval(env);
        }
      }
      argIndex++;
    }

    // Remove null elements at the end
    while (evaldArguments.isNotEmpty) {
      if (evaldArguments.last == null) {
        evaldArguments.removeLast();
      } else {
        break;
      }
    }
    return frame;

//    evalParams: function (env, mixinEnv, args, evaldArguments) {
//        /*jshint boss:true */
//        var frame = new(tree.Ruleset)(null, null),
//            varargs, arg,
//            params = this.params.slice(0),
//            i, j, val, name, isNamedFound, argIndex, argsLength = 0;
//
//        mixinEnv = new tree.evalEnv(mixinEnv, [frame].concat(mixinEnv.frames)); //TODO AL concat sublist(0)
//
//        if (args) {
//            args = args.slice(0);
//            argsLength = args.length;
//
//            for(i = 0; i < argsLength; i++) {
//                arg = args[i];
//                if (name = (arg && arg.name)) {
//                    isNamedFound = false;
//                    for(j = 0; j < params.length; j++) {
//                        if (!evaldArguments[j] && name === params[j].name) {
//                            evaldArguments[j] = arg.value.eval(env);
//                            frame.prependRule(new(tree.Rule)(name, arg.value.eval(env)));
//                            isNamedFound = true;
//                            break;
//                        }
//                    }
//                    if (isNamedFound) {
//                        args.splice(i, 1);
//                        i--;
//                        continue;
//                    } else {
//                        throw { type: 'Runtime', message: "Named argument for " + this.name +
//                            ' ' + args[i].name + ' not found' };
//                    }
//                }
//            }
//        }
//        argIndex = 0;
//        for (i = 0; i < params.length; i++) {
//            if (evaldArguments[i]) { continue; }
//
//            arg = args && args[argIndex];
//
//            if (name = params[i].name) {
//                if (params[i].variadic) {
//                    varargs = [];
//                    for (j = argIndex; j < argsLength; j++) {
//                        varargs.push(args[j].value.eval(env));
//                    }
//                    frame.prependRule(new(tree.Rule)(name, new(tree.Expression)(varargs).eval(env)));
//                } else {
//                    val = arg && arg.value;
//                    if (val) {
//                        val = val.eval(env);
//                    } else if (params[i].value) {
//                        val = params[i].value.eval(mixinEnv);
//                        frame.resetCache();
//                    } else {
//                        throw { type: 'Runtime', message: "wrong number of arguments for " + this.name +
//                            ' (' + argsLength + ' for ' + this.arity + ')' };
//                    }
//
//                    frame.prependRule(new(tree.Rule)(name, val));
//                    evaldArguments[i] = val;
//                }
//            }
//
//            if (params[i].variadic && args) {
//                for (j = argIndex; j < argsLength; j++) {
//                    evaldArguments[j] = args[j].value.eval(env);
//                }
//            }
//            argIndex++;
//        }
//
//        return frame;
//    },
  }

  ///
  MixinDefinition eval(Env env) {
    var frames = (this.frames != null) ? this.frames : env.frames.sublist(0);
    return new MixinDefinition(this.name, this.params, this.rules, this.condition,
        this.variadic, this.index, this.currentFileInfo, frames);

//    eval: function (env) {
//        return new tree.mixin.Definition(this.name, this.params, this.rules, this.condition, this.variadic, this.frames || env.frames.slice(0));
//    },
  }

  ///
  Ruleset evalCall(Env env, List<MixinArgs> args, bool important) {
    List _arguments = [];
    List<Node> mixinFrames = (this.frames != null) ? (this.frames.sublist(0)..addAll(env.frames)) : env.frames;
    Ruleset frame = this.evalParams(env, new Env.evalEnv(env, mixinFrames), args, _arguments);
    List<Node> rules;
    Ruleset ruleset;

    frame.prependRule(new Rule('@arguments', new Expression(_arguments).eval(env)));

    rules = this.rules.sublist(0);

    ruleset = new Ruleset(null, rules);
    ruleset.originalRuleset = this;
    ruleset.id = this.id;
    ruleset = ruleset.eval(new Env.evalEnv(env, [this, frame]..addAll(mixinFrames)));
    if (important) {
      ruleset = ruleset.makeImportant();
      //ruleset = this.parent.makeImportant.apply(ruleset);
    }
    return ruleset;

//    evalCall: function (env, args, important) {
//        var _arguments = [],
//            mixinFrames = this.frames ? this.frames.concat(env.frames) : env.frames,
//            frame = this.evalParams(env, new(tree.evalEnv)(env, mixinFrames), args, _arguments),
//            rules, ruleset;
//
//        frame.prependRule(new(tree.Rule)('@arguments', new(tree.Expression)(_arguments).eval(env)));
//
//        rules = this.rules.slice(0);
//
//        ruleset = new(tree.Ruleset)(null, rules);
//        ruleset.originalRuleset = this;
//        ruleset = ruleset.eval(new(tree.evalEnv)(env, [this, frame].concat(mixinFrames)));//TODO AL concat sublist(0)
//        if (important) {
//            ruleset = this.parent.makeImportant.apply(ruleset);
//        }
//        return ruleset;
//    },
  }

  //--- MatchConditionNode

  ///
  bool matchCondition(List<MixinArgs> args, Env env) {
    List thisFrames = (this.frames != null) ? (this.frames.sublist(0)..addAll(env.frames)) : env.frames;
    List frames = [this.evalParams(env, new Env.evalEnv(env, thisFrames), args, [])] // the parameter variables
      ..addAll(this.frames != null ? this.frames : [] ) // the parent namespace/mixin frames
      ..addAll(env.frames); // the current environment frames
    if (this.condition != null && !this.condition.eval(new Env.evalEnv(env, frames))) return false;
    return true;

//    matchCondition: function (args, env) {
//        if (this.condition && !this.condition.eval(
//            new(tree.evalEnv)(env,
//                [this.evalParams(env, new(tree.evalEnv)(env, this.frames ? this.frames.concat(env.frames) : env.frames), args, [])] // the parameter variables
//                    .concat(this.frames) // the parent namespace/mixin frames
//                    .concat(env.frames)))) { // the current environment frames
//            return false;
//        }
//        return true;
//    },
  }

  ///
  /// Check arguments call is according mixin definition
  ///
  bool matchArgs(List<MixinArgs> args, Env env) {
    int argsLength = 0;
    if (args != null) argsLength = args.length;
    int len;

    if (!this.variadic) {
      if (argsLength < this.required)       return false;
      if (argsLength > this.params.length)  return false;
    } else {
      if (argsLength < (this.required - 1)) return false;
    }

    len = math.min(argsLength, this.arity);

    for (int i = 0; i < len; i++) {
      if (this.params[i].name == null && !this.params[i].variadic) {
        if (args[i].value.eval(env).toCSS(env) != this.params[i].value.eval(env).toCSS(env)) {
          return false;
        }
      }
    }
    return true;

//    matchArgs: function (args, env) {
//        var argsLength = (args && args.length) || 0, len;
//
//        if (! this.variadic) {
//            if (argsLength < this.required)                               { return false; }
//            if (argsLength > this.params.length)                          { return false; }
//        } else {
//            if (argsLength < (this.required - 1))                         { return false; }
//        }
//
//        len = Math.min(argsLength, this.arity);
//
//        for (var i = 0; i < len; i++) {
//            if (!this.params[i].name && !this.params[i].variadic) {
//                if (args[i].value.eval(env).toCSS() != this.params[i].value.eval(env).toCSS()) {
//                    return false;
//                }
//            }
//        }
//        return true;
//    }
  }
}