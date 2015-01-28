//source: less/tree/element.js 1.7.5 line 3-43

part of tree.less;

class Element extends Node implements EvalNode, ToCSSNode {
  Combinator combinator;
  var value = ''; // String or Node
  int index;
  FileInfo currentFileInfo;

  final String type = 'Element';

  Element(combinator, value, int this.index, FileInfo this.currentFileInfo) {
    this.combinator = (combinator is Combinator) ? combinator : new Combinator(combinator);

    if (value is String) {
      this.value = value.trim();
    } else if (value != null) {
      this.value = value;
    }
  }

  ///
  void accept(Visitor visitor) {
    var value = this.value;
    this.combinator = visitor.visit(this.combinator);
    if (value is Node) this.value = visitor.visit(value);
  }

  ///
  Element eval(Contexts env) => new Element(
                        this.combinator,
                        (this.value is Node) ? this.value.eval(env) : this.value,
                        this.index,
                        this.currentFileInfo);

  ///
  void genCSS(Contexts env, Output output) {
    output.add(this.toCSS(env), this.currentFileInfo, this.index);
  }

  ///
  /// Converts value to String: Combinator + value
  /// #
  String toCSS(Contexts env) {
    String value = (this.value is ToCSSNode) ? this.value.toCSS(env) : this.value;
    if (value.isEmpty && this.combinator.value.startsWith('&')) {
      return '';
    } else {
      return this.combinator.toCSS(env != null ? env : new Contexts()) + value;
    }

//      toCSS: function (env) {
//          var value = (this.value.toCSS ? this.value.toCSS(env) : this.value);
//          if (value === '' && this.combinator.value.charAt(0) === '&') {
//              return '';
//          } else {
//              return this.combinator.toCSS(env || {}) + value;
//          }
//      }
  }
}