//source: less/tree/rule.js 1.7.5

part of tree.less;

class Rule extends Node implements EvalNode, MakeImportantNode, ToCSSNode {
  var name; //String or List<Keyword>
  Node value;
  String important = '';
  String merge;
  int index;
  FileInfo currentFileInfo;
  bool inline;
  bool variable = false;

  final String type = 'Rule';

  Rule(this.name, value, [String important, this.merge, int this.index, FileInfo this.currentFileInfo,
      bool this.inline = false, bool variable = null]) {

    if (value is Value || value is Ruleset) {
      this.value = value;
    } else {
      this.value = new Value([value]);
    }

    if (important != null && important.isNotEmpty) this.important = ' ' + important.trim();

    if (variable != null) {
      this.variable = variable;
    } else if (name != null) {
      this.variable = (name[0] == '@');
    }
  }

  ///
  void accept(Visitor visitor) {
    this.value = visitor.visit(this.value);
  }

  void genCSS(Env env, Output output) {
    output.add(this.name + (env.compress ? ':' : ': '), this.currentFileInfo, this.index);
    try {
      this.value.genCSS(env, output);
    } catch (e) {
      LessError error = LessError.transform(e,
          index: this.index,
          filename: this.currentFileInfo.filename,
          env: env);
      throw new LessExceptionError(error);
    }
    String out = '';
    if (!this.inline) out = (env.lastRule && env.compress) ? '' : ';';
    output.add(this.important + out, this.currentFileInfo, this.index);

//    genCSS: function (env, output) {
//        output.add(this.name + (env.compress ? ':' : ': '), this.currentFileInfo, this.index);
//        try {
//            this.value.genCSS(env, output);
//        }
//        catch(e) {
//            e.index = this.index;
//            e.filename = this.currentFileInfo.filename;
//            throw e;
//        }
//        output.add(this.important + ((this.inline || (env.lastRule && env.compress)) ? "" : ";"), this.currentFileInfo, this.index);
//    },
  }

//    toCSS: tree.toCSS,

  ///
  eval(Env env) {
    bool strictMathBypass = false;
    var name = this.name;
    bool variable = this.variable;
    var evaldValue;

    if (name is! String) {
      // expand 'primitive' name directly to get
      // things faster (~10% for benchmark.less):
      name = ((name as List).length == 1) && (name[0] is Keyword) ? (name[0] as Keyword).value : evalName(env, name);
      variable = false; // never treat expanded interpolation as new variable name
    }
    if (name == 'font' && !env.strictMath) {
      strictMathBypass = true;
      env.strictMath = true;
    }
    try {
      evaldValue = this.value.eval(env);

      if (!this.variable && (evaldValue is DetachedRuleset)) {
        throw new LessExceptionError(new LessError(
            message: 'Rulesets cannot be evaluated on a property.',
            index: this.index,
            filename: this.currentFileInfo.filename,
            env: env
         ));
      }
      return new Rule(name, evaldValue, this.important, this.merge, this.index, this.currentFileInfo,
        this.inline, variable);

    } catch (e) {
      LessError error = LessError.transform(e,
          index: this.index,
          filename: this.currentFileInfo.filename);
      throw new LessExceptionError(error);
    } finally {
      if (strictMathBypass) env.strictMath = false;
    }

//    eval: function (env) {
//        var strictMathBypass = false, name = this.name, variable = this.variable, evaldValue;
//        if (typeof name !== "string") {
//            // expand 'primitive' name directly to get
//            // things faster (~10% for benchmark.less):
//            name = (name.length === 1)
//                && (name[0] instanceof tree.Keyword)
//                    ? name[0].value : evalName(env, name);
//            variable = false; // never treat expanded interpolation as new variable name
//        }
//        if (name === "font" && !env.strictMath) {
//            strictMathBypass = true;
//            env.strictMath = true;
//        }
//        try {
//            evaldValue = this.value.eval(env);
//
//            if (!this.variable && evaldValue.type === "DetachedRuleset") {
//                throw { message: "Rulesets cannot be evaluated on a property.",
//                        index: this.index, filename: this.currentFileInfo.filename };
//            }
//
//            return new(tree.Rule)(name,
//                              evaldValue,
//                              this.important,
//                              this.merge,
//                              this.index, this.currentFileInfo, this.inline,
//                              variable);
//        }
//        catch(e) {
//            if (typeof e.index !== 'number') {
//                e.index = this.index;
//                e.filename = this.currentFileInfo.filename;
//            }
//            throw e;
//        }
//        finally {
//            if (strictMathBypass) {
//                env.strictMath = false;
//            }
//        }
//    },
  }

  ///
  Rule makeImportant() => new Rule(this.name,
                                this.value,
                                '!important',
                                this.merge,
                                this.index, this.currentFileInfo, this.inline);

  //function external to class. static?
  String evalName(Env env, List<Node> name) {
    int n = name.length;
    Output output = new Output();

    for (int i = 0; i < n; i++) {
      name[i].eval(env).genCSS(env, output);
    }
    return output.toString();

//function evalName(env, name) {
//    var value = "", i, n = name.length,
//        output = {add: function (s) {value += s;}};
//    for (i = 0; i < n; i++) {
//        name[i].eval(env).genCSS(env, output);
//    }
//    return value;
//}
  }
}