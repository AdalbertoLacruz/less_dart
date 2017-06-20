// source: lib/less/functions/types.js 2.5.0

part of functions.less;

///
class TypesFunctions extends FunctionBase {
//  var isa = function (n, Type) {
//      return (n instanceof Type) ? Keyword.True : Keyword.False;
//  }

  ///
  // handle non-array values as an array of length 1
  // return null if index is invalid
  @defineMethodSkip
  List<Node> getItemsFromNode(Node node) =>
      (node.value is List) ? node.value : <Node>[node];

//2.4.0+2
//  getItemsFromNode = function(node) {
//      // handle non-array values as an array of length 1
//      // return 'undefined' if index is invalid
//      var items = Array.isArray(node.value) ?
//          node.value : Array(node);
//
//      return items;
//  };

  ///
  /// Returns true if a value is a ruleset, false otherwise.
  ///
  /// Parameters:
  ///   value - a variable being evaluated.
  ///   Returns: true if value is a ruleset, false otherwise.
  /// Example:
  ///   @rules: {
  ///     color: red;
  ///   }
  ///   isruleset(@rules);   // true
  ///   isruleset(#ff0);     // false
  ///
  Keyword isruleset(Node n) =>
      (n is DetachedRuleset) ? new Keyword.True() : new Keyword.False();

//  isruleset: function (n) {
//      return isa(n, DetachedRuleset);
//  },

  ///
  /// Returns true if a value is a color, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a color, false otherwise.
  /// Example:
  ///   iscolor(#ff0);     // true
  ///   iscolor("string"); // false
  ///
  Keyword iscolor(Node n) =>
      (n is Color) ? new Keyword.True() : new Keyword.False();

  ///
  /// Returns true if a value is a number, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a number, false otherwise.
  /// Example:
  ///   isnumber(#ff0);     // false
  ///   isnumber(1234);     // true
  ///
  Keyword isnumber(Node n) =>
      (n is Dimension) ? new Keyword.True() : new Keyword.False();

  ///
  /// Returns true if a value is a string, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a string, false otherwise.
  /// Example:
  ///   isstring(#ff0);     // false
  ///   isstring("string"); // true
  ///
  Keyword isstring(Node n) =>
      (n is Quoted) ? new Keyword.True() : new Keyword.False();

  ///
  /// Returns true if a value is a keyword, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a keyword, false otherwise.
  /// Example:
  ///   iskeyword(#ff0);     // false
  ///   iskeyword(keyword);  // true
  ///
  Keyword iskeyword(Node n) =>
      (n is Keyword) ? new Keyword.True() : new Keyword.False();

  ///
  /// Returns true if a value is a url, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a url, false otherwise.
  /// Example:
  ///   isurl(#ff0);     // false
  ///   isurl(url(...)); // true
  ///
  Keyword isurl(Node n) =>
      (n is URL) ? new Keyword.True() : new Keyword.False();

  ///
  /// Returns true if a value is a number in pixels, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a pixel, false otherwise.
  /// Example:
  ///   ispixel(#ff0);     // false
  ///   ispixel(56px);     // true
  ///
  Keyword ispixel(Node n) => isunit(n, 'px');

  ///
  /// Returns true if a value is a percentage value, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is a percentage value, false otherwise.
  /// Example:
  ///   ispercentage(#ff0);     // false
  ///   ispercentage(7.8%);     // true
  ///
  Keyword ispercentage(Node n) => isunit(n, '%');

  ///
  /// Returns true if a value is an em value, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   Returns: true if value is an em value, false otherwise.
  /// Example:
  ///   isem(#ff0);     // false
  ///   isem(7.8em);    // true
  ///
  Keyword isem(Node n) => isunit(n, 'em');

  ///
  /// Returns true if a value is a number in specified units, false otherwise.
  ///
  /// Parameters:
  ///   value - a value or variable being evaluated.
  ///   unit - a unit identifier (optionaly quoted) to test for.
  ///   Returns: true if value is a number in specified units, false otherwise.
  /// Example:
  ///   isunit(11px, px);  // true
  ///   isunit(2.2%, px);  // false
  ///   isunit(56px, "%"); // false
  ///   isunit(7.8%, '%'); // true
  ///
  Keyword isunit(Node n, dynamic unit) {
    if (unit == null) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'missing the required second argument to isunit.'));
    }

    //String unitValue = (unit.value is String) ? unit.value : unit;
    final String unitValue = (unit is String) ? unit : unit.value;
    if (unitValue is! String) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'Second argument to isunit should be a unit or a string.'));
    }

    return (n is Dimension && n.unit.isUnit(unitValue))
        ? new Keyword.True()
        : new Keyword.False();

//    isunit = function (n, unit) {
//        if (unit === undefined) {
//            throw { type: "Argument", message: "missing the required second argument to isunit." };
//        }
//        unit = typeof unit.value === "string" ? unit.value : unit;
//        if (typeof unit !== "string") {
//            throw { type: "Argument", message: "Second argument to isunit should be a unit or a string." };
//        }
//        return (n instanceof Dimension) && n.unit.is(unit) ? Keyword.True : Keyword.False;
//    };
  }

  ///
  /// Remove or change the unit of a dimension
  ///
  /// Parameters:
  ///   dimension: A number, with or without a dimension.
  ///   unit: (Optional) the unit to change to, or if omitted it will remove the unit.
  /// Example:
  ///   unit(5, px)
  ///   Output: 5px
  ///
  Dimension unit(Node val, [Node unit]) {
    String unitValue;

    if (val is! Dimension) {
      final String p = val is Operation ? '. Have you forgotten parenthesis?' : '';
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'the first argument to unit must be a number$p'));
    }
    if (unit != null) {
      if (unit is Keyword) {
        unitValue = unit.value;
      } else {
        unitValue = unit.toCSS(null);
      }
    } else {
      unitValue = '';
    }
    return new Dimension(val.value, unitValue);

//2.4.0
//  unit: function (val, unit) {
//      if (!(val instanceof Dimension)) {
//          throw { type: "Argument",
//              message: "the first argument to unit must be a number" +
//                  (val instanceof Operation ? ". Have you forgotten parenthesis?" : "") };
//      }
//      if (unit) {
//          if (unit instanceof Keyword) {
//              unit = unit.value;
//          } else {
//              unit = unit.toCSS();
//          }
//      } else {
//          unit = "";
//      }
//      return new Dimension(val.value, unit);
//  },
  }

  ///
  /// get-unit
  /// Returns units of a number.
  ///
  /// If the argument contains a number with units, the function returns its units.
  /// The argument without units results in an empty return value.
  //
  /// Parameters:
  ///   number: a number with or without units.
  ///   Example: get-unit(5px)
  ///   Output: px
  /// Example: get-unit(5)
  ///   Output: //nothing
  ///
  @DefineMethod(name: 'get-unit')
  Anonymous getUnit(Dimension n) => new Anonymous(n.unit);

  ///
  /// Returns the value at a specified position in a list.
  ///
  /// Parameters:
  ///
  ///     [values] - list, a comma or space separated list of values.
  ///     [index] - an integer that specifies a position of a list element to return.
  ///
  /// Returns: a value at the specified position in a list.
  ///
  /// Example:
  ///
  ///     extract(8px dotted red, 2);
  ///     Output: dotted
  ///
  Node extract(Node values, Node index) {
    final int iIndex = (index.value as num).toInt() - 1; // (1-based index)
    //return MoreList.elementAt(getItemsFromNode(values), iIndex); //cover out of range
    try {
      return getItemsFromNode(values).elementAt(iIndex);
    } catch (e) {
      return null;
    }

//2.4.0
//  extract: function(values, index) {
//      index = index.value - 1; // (1-based index)
//      return getItemsFromNode(values)[index];
//  },
  }

  ///
  /// Returns the number of elements in a value list.
  ///
  /// Parameters:
  ///   list - a comma or space separated list of values.
  ///   Returns: an integer number of elements in a list
  /// Example: length(1px solid #0080ff);
  ///   Output: 3
  ///
  Dimension length(Node values) =>
      new Dimension(getItemsFromNode(values).length);

//2.4.0
//  length: function(values) {
//
//      return new Dimension(getItemsFromNode(values).length);
//  }

  ///
  /// Converts from px, pt or em to rem units
  ///
  /// Parameters:
  ///   number: a number with or without units (px by default).
  ///   base: (optional) number (16px, 12pt, 1em)
  ///   Returns: the number converted to em
  /// Example: rem(16), rem(32px), rem(28pt, 14)
  ///   Output: 1rem, 2rem, 2rem
  ///
  Dimension rem(Node fontSize, [Node baseFont]) {
    num base = 16; //px
    if (fontSize is Dimension) {
      switch (fontSize.unit.toCSS(null)) {
        case 'px':
          base = 16;
          break;
        case 'pt':
          base = 12;
          break;
        case 'em':
          base = 1;
          break;
        default:
      }
    }
    //base = baseFont != null ? baseFont.value : base;
    base = baseFont?.value ?? base;
    return new Dimension(fontSize.value / base, 'rem');
  }
}
