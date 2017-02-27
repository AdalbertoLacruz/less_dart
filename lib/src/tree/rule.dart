//source: less/tree/rule.js 2.5.0

part of tree.less;

class Rule extends Node<Node> implements MakeImportantNode {
  var name; //String or List<Keyword>
  String important = '';
  String merge;
  int index;
  bool inline;
  bool variable = false;

  final String type = 'Rule';

  ///
  Rule(this.name, Node value, [String important, String this.merge, int this.index, FileInfo currentFileInfo,
      bool this.inline = false, bool variable = null]) {
    this.value = value;
    this.currentFileInfo = currentFileInfo;

    this.value = (value is Node) ? value : new Value([value]);
    if (important != null && important.isNotEmpty) this.important = ' ' + important.trim();

    this.variable = (variable != null)
        ? variable
        : this.name is String && (this.name as String).startsWith('@');

//2.3.1
//  var Rule = function (name, value, important, merge, index, currentFileInfo, inline, variable) {
//      this.name = name;
//      this.value = (value instanceof Node) ? value : new Value([value]); //value instanceof tree.Value || value instanceof tree.Ruleset ??
//      this.important = important ? ' ' + important.trim() : '';
//      this.merge = merge;
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//      this.inline = inline || false;
//      this.variable = (variable !== undefined) ? variable
//          : (name.charAt && (name.charAt(0) === '@'));
//  };
  }

  ///
  //function external to class. static?
  String evalName(Contexts context, List<Node> name) {
    Output output = new Output();

    for (int i = 0; i < name.length; i++) {
      name[i].eval(context).genCSS(context, output);
    }
    return output.toString();

//2.3.1
//  function evalName(context, name) {
//      var value = "", i, n = name.length,
//          output = {add: function (s) {value += s;}};
//      for (i = 0; i < n; i++) {
//          name[i].eval(context).genCSS(context, output);
//      }
//      return value;
//  }
  }

  ///
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null) return genCleanCSS(context, output);

    output.add(name + (context.compress ? ':' : ': '), currentFileInfo, index);
    try {
      if (value != null) value.genCSS(context, output);
    } catch (e) {
      LessError error = LessError.transform(e,
          index: index,
          filename: currentFileInfo.filename,
          context: context);
      throw new LessExceptionError(error);
    }
    String out = '';
    if (!inline) out = (context.lastRule && context.compress) ? '' : ';';
    output.add(important + out, currentFileInfo, index);

//2.3.1
//  Rule.prototype.genCSS = function (context, output) {
//      output.add(this.name + (context.compress ? ':' : ': '), this.currentFileInfo, this.index);
//      try {
//          this.value.genCSS(context, output);
//      }
//      catch(e) {
//          e.index = this.index;
//          e.filename = this.currentFileInfo.filename;
//          throw e;
//      }
//      output.add(this.important + ((this.inline || (context.lastRule && context.compress)) ? "" : ";"), this.currentFileInfo, this.index);
//  };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    output.add(name + ':', currentFileInfo, index);
    try {
      if (value != null) value.genCSS(context, output);
    } catch (e) {
      LessError error = LessError.transform(e,
          index: index,
          filename: currentFileInfo.filename,
          context: context);
      throw new LessExceptionError(error);
    }
    String out = '';
    if (!inline) out = (context.lastRule) ? '' : ';';
    output.add(important + out, currentFileInfo, index);
  }

  ///
  eval(Contexts context) {
    bool strictMathBypass = false;
    var name = this.name;
    bool variable = this.variable;
    var evaldValue;

    if (name is! String) {
      // expand 'primitive' name directly to get
      // things faster (~10% for benchmark.less):
      name = ((name as List).length == 1) && (name[0] is Keyword) ? (name[0] as Keyword).value : evalName(context, name);
      variable = false; // never treat expanded interpolation as new variable name
    }
    if (name == 'font' && !context.strictMath) {
      strictMathBypass = true;
      context.strictMath = true;
    }
    try {
      context.importantScope.add(new ImportantRule());
      evaldValue = this.value.eval(context);

      if (!this.variable && (evaldValue is DetachedRuleset)) {
        throw new LessExceptionError(new LessError(
            message: 'Rulesets cannot be evaluated on a property.',
            index: index,
            filename: currentFileInfo.filename,
            context: context
         ));
      }

      String important = this.important;
      ImportantRule importantResult = context.importantScope.removeLast();
      if (important.isEmpty && importantResult.important.isNotEmpty) {
        important = importantResult.important;
      }

      return new Rule(name, evaldValue, important, merge, index, currentFileInfo,
        inline, variable);

    } catch (e) {
      LessError error = LessError.transform(e,
          index: index,
          filename: currentFileInfo.filename);
      throw new LessExceptionError(error);
    } finally {
      if (strictMathBypass) context.strictMath = false;
    }

//2.3.1
//  Rule.prototype.eval = function (context) {
//      var strictMathBypass = false, name = this.name, evaldValue, variable = this.variable;
//      if (typeof name !== "string") {
//          // expand 'primitive' name directly to get
//          // things faster (~10% for benchmark.less):
//          name = (name.length === 1) && (name[0] instanceof Keyword) ?
//                  name[0].value : evalName(context, name);
//              variable = false; // never treat expanded interpolation as new variable name
//      }
//      if (name === "font" && !context.strictMath) {
//          strictMathBypass = true;
//          context.strictMath = true;
//      }
//      try {
//          context.importantScope.push({});
//          evaldValue = this.value.eval(context);
//
//          if (!this.variable && evaldValue.type === "DetachedRuleset") {
//              throw { message: "Rulesets cannot be evaluated on a property.",
//                      index: this.index, filename: this.currentFileInfo.filename };
//          }
//          var important = this.important,
//              importantResult = context.importantScope.pop();
//          if (!important && importantResult.important) {
//              important = importantResult.important;
//          }
//
//          return new Rule(name,
//                            evaldValue,
//                            important,
//                            this.merge,
//                            this.index, this.currentFileInfo, this.inline,
//                                variable);
//      }
//      catch(e) {
//          if (typeof e.index !== 'number') {
//              e.index = this.index;
//              e.filename = this.currentFileInfo.filename;
//          }
//          throw e;
//      }
//      finally {
//          if (strictMathBypass) {
//              context.strictMath = false;
//          }
//      }
//  };
  }

  ///
  Rule makeImportant() => new Rule(name, value, '!important', merge,index, currentFileInfo, inline);

//2.3.1
//  Rule.prototype.makeImportant = function () {
//      return new Rule(this.name,
//                            this.value,
//                            "!important",
//                            this.merge,
//                            this.index, this.currentFileInfo, this.inline);
//  };
}

// ------------------------------------------------

///
class ImportantRule {
  String important = ''; // '!important'
}
