//source: less/tree/element.js 3.0.0 20160714

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
  @override final String type = 'Element';

  ///
  Combinator  combinator;

  ///
  Element(dynamic combinator, dynamic value, int index,
      FileInfo currentFileInfo, {VisibilityInfo visibilityInfo})
      : super.init(currentFileInfo: currentFileInfo, index: index) {

    this.combinator =
        (combinator is Combinator) ? combinator : new Combinator(combinator);

    if (value is String) {
      this.value = value.trim();
    } else if (value != null) {
      this.value = value;
    } else {
      this.value = '';
    }

    copyVisibilityInfo(visibilityInfo);
    setParent(this.combinator, this);

//3.0.0 20160714
// var Element = function (combinator, value, index, currentFileInfo, visibilityInfo) {
//     this.combinator = combinator instanceof Combinator ?
//                       combinator : new Combinator(combinator);
//
//     if (typeof value === 'string') {
//         this.value = value.trim();
//     } else if (value) {
//         this.value = value;
//     } else {
//         this.value = "";
//     }
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.copyVisibilityInfo(visibilityInfo);
//     this.setParent(this.combinator, this);
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'combinator': combinator,
    'value': value
  };

  ///
  /// Tree navegation for visitors
  ///
  @override
  void accept(covariant VisitorBase visitor) {
    combinator = visitor.visit(combinator);
    if (value is Node)
        value = visitor.visit(value);

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
  @override
  Element eval(Contexts context) => new Element(
      combinator,
      (value is Node) ? value.eval(context) : value,
      index,
      currentFileInfo,
      visibilityInfo: visibilityInfo());

//3.0.0 20160714
// Element.prototype.eval = function (context) {
//     return new Element(this.combinator,
//                              this.value.eval ? this.value.eval(context) : this.value,
//                              this.getIndex(),
//                              this.fileInfo(), this.visibilityInfo());
// };

  ///
  Element clone() =>
      new Element(combinator, value, index, currentFileInfo,
        visibilityInfo: visibilityInfo());

//3.0.0 20160714
// Element.prototype.clone = function () {
//     return new Element(this.combinator,
//         this.value,
//         this.getIndex(),
//         this.fileInfo(), this.visibilityInfo());
// };

  ///
  /// Writes the css code
  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add(toCSS(context), fileInfo: currentFileInfo, index: index);

//3.0.0 20160714
// Element.prototype.genCSS = function (context, output) {
//     output.add(this.toCSS(context), this.fileInfo(), this.getIndex());
// };
  }

  ///
  /// Converts value to String: Combinator + value
  ///
  @override
  String toCSS(Contexts context) {
    final Contexts    _context = context ?? new Contexts();
    dynamic           value = this.value; // Node | String
    final bool        firstSelector = _context.firstSelector;

    if (value is Paren)
        // selector in parens should not be affected by outer selector
        // flags (breaks only interpolated selectors - see #1973)
        _context.firstSelector = true;

    value = (value is Node) ? value.toCSS(_context) : value; // String
    _context.firstSelector = firstSelector;

    if (value.isEmpty && combinator.value.startsWith('&')) {
      return '';
    } else {
      // ignore: prefer_interpolation_to_compose_strings
      return combinator.toCSS(_context) + value;
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

  @override
  String toString() => toCSS(null).trim();
}
