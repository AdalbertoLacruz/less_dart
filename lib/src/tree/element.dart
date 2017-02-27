//source: less/tree/element.js 2.5.0

part of tree.less;

///
/// A Selector Element
///
///     div
///     + h1
///     #socks
///     input[type="text"]
///
/// Elements are the building blocks for Selectors,
/// they are made out of a `Combinator` and an element name,
/// such as a tag a class, or `*`.
///
class Element extends Node {
  Combinator  combinator;
  int         index;

  final String type = 'Element';

  ///
  Element(combinator, value, this.index, FileInfo currentFileInfo) {
    this.value = '';
    this.currentFileInfo = currentFileInfo;
    this.combinator = (combinator is Combinator) ? combinator : new Combinator(combinator);

    if (value is String) {
      this.value = value.trim();
    } else if (value != null) {
      this.value = value;
    }

//2.3.1
//  var Element = function (combinator, value, index, currentFileInfo) {
//      this.combinator = combinator instanceof Combinator ?
//                        combinator : new Combinator(combinator);
//
//      if (typeof(value) === 'string') {
//          this.value = value.trim();
//      } else if (value) {
//          this.value = value;
//      } else {
//          this.value = "";
//      }
//      this.index = index;
//      this.currentFileInfo = currentFileInfo;
//  };
  }

  ///
  /// Tree navegation for visitors
  ///
  void accept(covariant Visitor visitor) {
    combinator = visitor.visit(combinator);
    if (value is Node) value = visitor.visit(value);

//2.3.1
//  Element.prototype.accept = function (visitor) {
//      var value = this.value;
//      this.combinator = visitor.visit(this.combinator);
//      if (typeof value === "object") {
//          this.value = visitor.visit(value);
//      }
//  };
  }

  ///
  /// Replace variables by value
  ///
  Element eval(Contexts context) => new Element(
                        combinator,
                        (value is Node) ? value.eval(context) : value,
                        index,
                        currentFileInfo);

  //2.3.1
//  Element.prototype.eval = function (context) {
//      return new Element(this.combinator,
//                               this.value.eval ? this.value.eval(context) : this.value,
//                               this.index,
//                               this.currentFileInfo);
//  };

  ///
  /// Writes the css code
  ///
  void genCSS(Contexts context, Output output) {
    output.add(toCSS(context), currentFileInfo, index);

//2.3.1
//  Element.prototype.genCSS = function (context, output) {
//      output.add(this.toCSS(context), this.currentFileInfo, this.index);
//  };
  }

  ///
  /// Converts value to String: Combinator + value
  ///
  String toCSS(Contexts context) {
    if (context == null) context = new Contexts();
    var value = this.value;
    bool firstSelector = context.firstSelector;

    if (value is Paren) {
      // selector in parens should not be affected by outer selector
      // flags (breaks only interpolated selectors - see #1973)
      context.firstSelector = true;
    }

    value = (value is Node) ? value.toCSS(context) : value;
    context.firstSelector = firstSelector;
    if (value.isEmpty && combinator.value.startsWith('&')) {
      return '';
    } else {
      return combinator.toCSS(context) + value;
    }

//2.3.1
//  Element.prototype.toCSS = function (context) {
//      context = context || {};
//      var value = this.value, firstSelector = context.firstSelector;
//      if (value instanceof Paren) {
//          // selector in parens should not be affected by outer selector
//          // flags (breaks only interpolated selectors - see #1973)
//          context.firstSelector = true;
//      }
//      value = value.toCSS ? value.toCSS(context) : value;
//      context.firstSelector = firstSelector;
//      if (value === '' && this.combinator.value.charAt(0) === '&') {
//          return '';
//      } else {
//          return this.combinator.toCSS(context) + value;
//      }
//  };
  }
}
