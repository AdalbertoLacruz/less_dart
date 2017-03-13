//source: less/tree/quoted.js 2.5.0

part of tree.less;

class Quoted extends Node with JsEvalNodeMixin implements CompareNode {
  @override String get name => null;
  @override final String type = 'Quoted';
  @override covariant String value; //TODO used?

  bool    escaped;
  String  quote; // ' or "

  ///
  Quoted(String str, String content, bool this.escaped, [int index, FileInfo currentFileInfo]){
    value = '';
    this.index = index;
    this.currentFileInfo = currentFileInfo;
    if (this.escaped == null) this.escaped = true;
    if(content != null) value = content;
    quote = str.isNotEmpty ? str[0] : '';
    if (!(quote == '"' || quote == "'" || quote == '')) quote = '';

//2.3.1
//  var Quoted = function (str, content, escaped, index, currentFileInfo) {
//      this.escaped = (escaped == null) ? true : escaped;
//      this.value = content || '';
//      this.quote = str.charAt(0);
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//  };
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (!escaped) {
      output.add(quote, currentFileInfo, index);
    }
    output.add(value);
    if (!escaped) {
      output.add(quote);
    }

//2.3.1
//  Quoted.prototype.genCSS = function (context, output) {
//      if (!this.escaped) {
//          output.add(this.quote, this.currentFileInfo, this.index);
//      }
//      output.add(this.value);
//      if (!this.escaped) {
//          output.add(this.quote);
//      }
//  };
  }

  ///
  bool containsVariables() => new RegExp(r'(`([^`]+)`)|@\{([\w-]+)\}').hasMatch(value);

//2.3.1
//  Quoted.prototype.containsVariables = function() {
//      return this.value.match(/(`([^`]+)`)|@\{([\w-]+)\}/);
//  };

  ///
  @override
  Node eval(Contexts context){
    Quoted that = this;
    String value = this.value;
    //RegExp reJS = new RegExp(r'`([^`]+)`'); //javascript expresion
    RegExp reVar = new RegExp(r'@\{([\w-]+)\}');

//      var javascriptReplacement = function (_, exp) {
//          return String(that.evaluateJavaScript(exp, context));
//      };

    //@f: 'ables';
    //@import 'vari@{f}.less';
    //result = @import 'variables.less';
    String interpolationReplacement(Match m) {
      String name = m[1];
      Node v = new Variable('@' + name, that.index, that.currentFileInfo).eval(context);
      return (v is Quoted) ? v.value : v.toCSS(null);
    }

    String iterativeReplace(String value, RegExp regexp, String replacementFnc(Match match) ) {
      String evaluatedValue = value;
      do {
        value = evaluatedValue;
        evaluatedValue = value.replaceAllMapped(regexp, replacementFnc);
      } while (value != evaluatedValue);
      return evaluatedValue;
    }

//      value = iterativeReplace(value, /`([^`]+)`/g, javascriptReplacement); // JS Not supported
    value = iterativeReplace(value, reVar, interpolationReplacement);

    return new Quoted(quote + value + quote, value, escaped, index, currentFileInfo);

//2.3.1
//  Quoted.prototype.eval = function (context) {
//      var that = this, value = this.value;
//      var javascriptReplacement = function (_, exp) {
//          return String(that.evaluateJavaScript(exp, context));
//      };
//      var interpolationReplacement = function (_, name) {
//          var v = new Variable('@' + name, that.index, that.currentFileInfo).eval(context, true);
//          return (v instanceof Quoted) ? v.value : v.toCSS();
//      };
//      function iterativeReplace(value, regexp, replacementFnc) {
//          var evaluatedValue = value;
//          do {
//            value = evaluatedValue;
//            evaluatedValue = value.replace(regexp, replacementFnc);
//          } while  (value !== evaluatedValue);
//          return evaluatedValue;
//      }
//      value = iterativeReplace(value, /`([^`]+)`/g, javascriptReplacement);
//      value = iterativeReplace(value, /@\{([\w-]+)\}/g, interpolationReplacement);
//      return new Quoted(this.quote + value + this.quote, value, this.escaped, this.index, this.currentFileInfo);
//  };
  }


//--- CompareNode

  /// Returns -1, 0 or +1 or null
  @override
  int compare(Node other) {
    // when comparing quoted strings allow the quote to differ
    // We need compare strings with: string.copareTo(otherString)

    if (other is Quoted && !this.escaped && !other.escaped) {
      return this.value.compareTo(other.value);
    } else {
      return this.toCSS(null) == other.toCSS(null) ? 0 : null;
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
}
