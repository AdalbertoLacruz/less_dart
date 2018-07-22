//source: less/tree/declaration.js 3.0.0 20160719

part of tree.less;

///
/// a css rule/declaration 'name: value;' such as:
///
///   color: black;
///   @a: 2;
///   *zoom: 1;
///
class Declaration extends Node implements MakeImportantNode {
  ///
  /// rule/declaration left side:
  ///
  ///   color ->  [0] keyword color
  ///   @a    -> String
  ///   *zoom -> [0] keyword *, [1] keyword zoom
  ///
  @override dynamic         name; //String or List<Keyword>

  @override final String    type = 'Declaration';

  /// rule/declaration right side
  @override covariant Node  value;

  ///
  String  important = '';
  ///
  bool    inline;
  ///
  String  merge;
  ///
  bool    variable = false;

  ///
  Declaration(dynamic this.name, dynamic value,
      {String important,
      String this.merge,
      int index,
      FileInfo currentFileInfo,
      bool this.inline = false,
      bool variable})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    //
    this.value = (value is Node)
        ? value
        : new Value(<Node>[value != null ? new Anonymous(value) : null]);

    if (important?.isNotEmpty ?? false) this.important = ' ${important.trim()}';

    this.variable = variable ?? (name is String && (name as String).startsWith('@'));
    allowRoot = true;
    setParent(this.value, this);

//3.0.0 20160719
// var Declaration = function (name, value, important, merge, index, currentFileInfo, inline, variable) {
//     this.name = name;
//     this.value = (value instanceof Node) ? value : new Value([value ? new Anonymous(value) : null]);
//     this.important = important ? ' ' + important.trim() : '';
//     this.merge = merge;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.inline = inline || false;
//     this.variable = (variable !== undefined) ? variable
//         : (name.charAt && (name.charAt(0) === '@'));
//     this.allowRoot = true;
//     this.setParent(this.value, this);
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'name': name,
    'value': value
  };

  ///
  ///  clone this Declaration
  ///
  Declaration clone() => new Declaration(name, value,
      important: important,
      merge: merge,
      index:  index,
      currentFileInfo: currentFileInfo,
      inline: inline,
      variable: variable);

  ///
  //function external to class. static?
  String evalName(Contexts context, List<Node> name) {
    final Output output = new Output();

    for (int i = 0; i < name.length; i++) {
      name[i].eval(context).genCSS(context, output);
    }
    return output.toString();

//2.8.0 20160702
// function evalName(context, name) {
//     var value = "", i, n = name.length,
//         output = {add: function (s) {value += s;}};
//     for (i = 0; i < n; i++) {
//         name[i].eval(context).genCSS(context, output);
//     }
//     return value;
// }
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (cleanCss != null) return genCleanCSS(context, output);

    final String colon = (context?.compress ?? false) ? ':' : ': ';
    output.add('$name$colon', fileInfo: currentFileInfo, index: index);

    try {
      if (value != null) value.genCSS(context, output);
    } catch (e) {
      throw new LessExceptionError(LessError.transform(e,
          index: _index,
          filename: _fileInfo.filename,
          context: context));
    }

    String out = '';
    if (!(inline ?? false)) {
      out = ((context?.lastRule ?? false) && (context?.compress ?? false))
          ? ''
          : ';';
    }
    output.add('$important$out', fileInfo: _fileInfo, index: _index);

//3.0.0 20160714
// Declaration.prototype.genCSS = function (context, output) {
//     output.add(this.name + (context.compress ? ':' : ': '), this.fileInfo(), this.getIndex());
//     try {
//         this.value.genCSS(context, output);
//     }
//     catch(e) {
//         e.index = this._index;
//         e.filename = this._fileInfo.filename;
//         throw e;
//     }
//     output.add(this.important + ((this.inline || (context.lastRule && context.compress)) ? "" : ";"), this._fileInfo, this._index);
// };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    output.add('$name:', fileInfo: currentFileInfo, index: index);

    try {
      if (value != null) value.genCSS(context, output);
    } catch (e) {
      throw new LessExceptionError(LessError.transform(e,
          index: index,
          filename: currentFileInfo.filename,
          context: context));
    }

    String out = '';
    if (!(inline ?? false)) {
      out = (context.lastRule) ? '' : ';';
    }
    output.add('$important$out', fileInfo: currentFileInfo, index: index);
  }

  ///
  @override
  Declaration eval(Contexts context) {
    bool strictMathBypass = false;
    dynamic name = this.name; // String || List<Node> (Variable, Keyword, ...)
    bool variable = this.variable;

    if (name is! String) {
      // expand 'primitive' name directly to get
      // things faster (~10% for benchmark.less):
      name = ((name as List<Node>).length == 1) && (name[0] is Keyword)
          ? (name[0] as Keyword).value
          : evalName(context, name as List<Node>);
      variable = false; // never treat expanded interpolation as new variable name
    }

    if (name == 'font' && !context.strictMath) {
      strictMathBypass = true;
      context.strictMath = true;
    }
    
    try {
      context.importantScope.add(new ImportantRule());
      final Node evaldValue = value.eval(context);

      if (!this.variable && (evaldValue is DetachedRuleset)) {
        throw new LessExceptionError(new LessError(
            message: 'Rulesets cannot be evaluated on a property.',
            index: index,
            filename: currentFileInfo.filename,
            context: context));
      }

      String important = this.important;
      final ImportantRule importantResult = context.importantScope.removeLast();
      if (important.isEmpty && importantResult.important.isNotEmpty) {
        important = importantResult.important;
      }

      return new Declaration(name, evaldValue, //TODO clone()
          important: important,
          merge: merge,
          index: index,
          currentFileInfo: currentFileInfo,
          inline: inline,
          variable: variable);
    } catch (e) {
      throw new LessExceptionError(LessError.transform(e,
          index: index,
          filename: currentFileInfo.filename));
    } finally {
      if (strictMathBypass) context.strictMath = false;
    }

//3.0.0 20160714
// Declaration.prototype.eval = function (context) {
//     var strictMathBypass = false, name = this.name, evaldValue, variable = this.variable;
//     if (typeof name !== "string") {
//         // expand 'primitive' name directly to get
//         // things faster (~10% for benchmark.less):
//         name = (name.length === 1) && (name[0] instanceof Keyword) ?
//                 name[0].value : evalName(context, name);
//         variable = false; // never treat expanded interpolation as new variable name
//     }
//     if (name === "font" && !context.strictMath) {
//         strictMathBypass = true;
//         context.strictMath = true;
//     }
//     try {
//         context.importantScope.push({});
//         evaldValue = this.value.eval(context);
//
//         if (!this.variable && evaldValue.type === "DetachedRuleset") {
//             throw { message: "Rulesets cannot be evaluated on a property.",
//                     index: this.getIndex(), filename: this.fileInfo().filename };
//         }
//         var important = this.important,
//             importantResult = context.importantScope.pop();
//         if (!important && importantResult.important) {
//             important = importantResult.important;
//         }
//
//         return new Declaration(name,
//                           evaldValue,
//                           important,
//                           this.merge,
//                           this.getIndex(), this.fileInfo(), this.inline,
//                               variable);
//     }
//     catch(e) {
//         if (typeof e.index !== 'number') {
//             e.index = this.getIndex();
//             e.filename = this.fileInfo().filename;
//         }
//         throw e;
//     }
//     finally {
//         if (strictMathBypass) {
//             context.strictMath = false;
//         }
//     }
// };
  }

  ///
  @override
  Declaration makeImportant() =>
      new Declaration(name, value,
          important: '!important',
          merge: merge,
          index: index,
          currentFileInfo: currentFileInfo,
          inline: inline);

//3.0.0 20160714
// Declaration.prototype.makeImportant = function () {
//     return new Declaration(this.name,
//                           this.value,
//                           "!important",
//                           this.merge,
//                           this.getIndex(), this.fileInfo(), this.inline);
// };

  @override
  void genTree(Contexts env, Output output, [String prefix = '']) {
      genTreeTitle(env, output, prefix, type, toString());

      final int tabs = prefix.isEmpty ? 1 : 2;
      env.tabLevel = env.tabLevel + tabs ;

      if (treeField == null) {
        output.add('***** FIELDS NOT DEFINED *****');
      } else {
        treeField.forEach((String fieldName, dynamic fieldValue){
          genTreeField(env, output, fieldName, fieldValue);
        });
      }

      env.tabLevel = env.tabLevel - tabs;
  }

  ///
  /// Rebuild the original rule, such as
  ///     color: black;
  ///
  @override
  String toString() {
    final StringBuffer sb = new StringBuffer();

    if (name is String) sb.write(name);
    if (name is List) {
      name.forEach((Node e) {
        sb.write(e.toString());
      });
    }
    sb.write(': ${value.toString()};');

    return sb.toString();
  }
}

// ------------------------------------------------

///
class ImportantRule {
  ///
  String important = ''; // '!important'
}
