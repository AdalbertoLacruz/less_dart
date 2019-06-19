//source: less/tree/quoted.js 3.0.4 20180622

part of tree.less;

///
/// A string, which supports escaping `~`, `"` and `'`
///
///     "milky way" 'he\'s the one!'
///
class Quoted extends Node implements CompareNode {
  @override final String      name = null;
  @override final String      type = 'Quoted';
  @override covariant String  value;

  /// false writes quote. true not.
  bool   escaped;

  /// Default value to identify a property: /\$\{([\w-]+)\}/g
  RegExp propRegex;

  /// ' or "
  String quote;

  ///
  bool   reparse = false;

  /// Default value to identify a variable: /@\{([\w-]+)\}/g
  RegExp variableRegex;

  ///
  Quoted(String str, String content,
      {this.escaped, int index, FileInfo currentFileInfo}) {
    this.index = index;
    this.currentFileInfo = currentFileInfo;

    escaped ??= true;
    value = content ?? '';
    quote = str.isNotEmpty ? str[0] : '';
    if (!(quote == '"' || quote == "'" || quote == '')) quote = ''; // also ~ ?

    variableRegex = new RegExp(r'@\{([\w-]+)\}');
    propRegex = new RegExp(r'\$\{([\w-]+)\}');

//3.0.4 20180622
// var Quoted = function (str, content, escaped, index, currentFileInfo) {
//     this.escaped = (escaped == null) ? true : escaped;
//     this.value = content || '';
//     this.quote = str.charAt(0);
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.variableRegex = /@\{([\w-]+)\}/g;
//     this.propRegex = /\$\{([\w-]+)\}/g;
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (!escaped) output.add(quote, fileInfo: currentFileInfo, index: index);
    output.add(value);
    if (!escaped) output.add(quote);

//3.0.0 20160714
// Quoted.prototype.genCSS = function (context, output) {
//     if (!this.escaped) {
//         output.add(this.quote, this.fileInfo(), this.getIndex());
//     }
//     output.add(this.value);
//     if (!this.escaped) {
//         output.add(this.quote);
//     }
// };
  }

  ///
  bool containsVariables() => variableRegex.hasMatch(value);

//3.0.4 20180622
//  Quoted.prototype.containsVariables = function() {
//    return this.value.match(this.variableRegex);
//  };

  ///
  @override
  Node eval(Contexts context) {
    //RegExp reJS = new RegExp(r'`([^`]+)`'); //javascript expresion
    final Quoted that = this;
    String       value = this.value;

    //@f: 'ables';
    //@import 'vari@{f}.less';
    //result = @import 'variables.less';
    String variableReplacement(Match m) {
      final String  name = m[1];
      final Node    v = new Variable('@$name', that.index, that.currentFileInfo).eval(context);

      return (v is Quoted) ? v.value : v.toCSS(null);
    }

    String propertyReplacement(Match m) {
      final String  name = m[1];
      final Node v = new Property('\$$name', index, currentFileInfo).eval(context);
      return (v is Quoted) ? v.value : v.toCSS(null);
    }

    String iterativeReplace(String value, RegExp regexp, String replacementFnc(Match match) ) {
      String evaluatedValue = value;
      String _value;

      do {
        _value = evaluatedValue;
        evaluatedValue = _value.replaceAllMapped(regexp, replacementFnc);
      } while (_value != evaluatedValue);

      return evaluatedValue;
    }

    value = iterativeReplace(value, variableRegex, variableReplacement);
    value = iterativeReplace(value, propRegex, propertyReplacement);

    return new Quoted('$quote$value$quote', value,
        escaped: escaped,
        index: index,
        currentFileInfo: currentFileInfo);

//3.0.4 20180622
//Quoted.prototype.eval = function (context) {
//    var that = this, value = this.value;
//    var variableReplacement = function (_, name) {
//        var v = new Variable('@' + name, that.getIndex(), that.fileInfo()).eval(context, true);
//        return (v instanceof Quoted) ? v.value : v.toCSS();
//    };
//    var propertyReplacement = function (_, name) {
//        var v = new Property('$' + name, that.getIndex(), that.fileInfo()).eval(context, true);
//        return (v instanceof Quoted) ? v.value : v.toCSS();
//    };
//    function iterativeReplace(value, regexp, replacementFnc) {
//        var evaluatedValue = value;
//        do {
//            value = evaluatedValue;
//            evaluatedValue = value.replace(regexp, replacementFnc);
//        } while (value !== evaluatedValue);
//        return evaluatedValue;
//    }
//    value = iterativeReplace(value, this.variableRegex, variableReplacement);
//    value = iterativeReplace(value, this.propRegex, propertyReplacement);
//    return new Quoted(this.quote + value + this.quote, value, this.escaped, this.getIndex(), this.fileInfo());
//};
  }

//--- CompareNode

  /// Returns -1, 0 or +1 or null
  @override
  int compare(Node other) {
    // when comparing quoted strings allow the quote to differ
    // We need compare strings with: string.copareTo(otherString)

    if (other is Quoted && !escaped && !other.escaped) {
      return value.compareTo(other.value);
    } else {
      return toCSS(null) == other.toCSS(null) ? 0 : null;
    }

//2.4.0
//  Quoted.prototype.compare = function (other) {
//      // when comparing quoted strings allow the quote to differ
//      if (other.type === "Quoted" && !this.escaped && !other.escaped) {
//          return Node.numericCompare(this.value, other.value);
//      } else {
//          return other.toCSS && this.toCSS() === other.toCSS() ? 0 : undefined;
//      }
//  };
  }

  @override
  String toString() => '${!escaped ? quote : ""}$value${!escaped ? quote : ""}';
}
