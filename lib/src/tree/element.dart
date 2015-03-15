//source: less/tree/element.js 2.4.0

part of tree.less;

class Element extends Node {
  Combinator combinator;
  var value = ''; // String or Node
  int index;
  FileInfo currentFileInfo;

  final String type = 'Element';

  ///
  Element(combinator, value, int this.index, FileInfo this.currentFileInfo) {
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
  void accept(Visitor visitor) {
    var value = this.value;
    this.combinator = visitor.visit(this.combinator);
    if (value is Node) this.value = visitor.visit(value);

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
  Element eval(Contexts context) => new Element(
                        this.combinator,
                        (this.value is Node) ? this.value.eval(context) : this.value,
                        this.index,
                        this.currentFileInfo);

  //2.3.1
//  Element.prototype.eval = function (context) {
//      return new Element(this.combinator,
//                               this.value.eval ? this.value.eval(context) : this.value,
//                               this.index,
//                               this.currentFileInfo);
//  };

  ///
  void genCSS(Contexts context, Output output) {
    output.add(this.toCSS(context), this.currentFileInfo, this.index);

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
    if (value.isEmpty && this.combinator.value.startsWith('&')) {
      return '';
    } else {
      return this.combinator.toCSS(context) + value;
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