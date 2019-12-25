// source: lib/less/functions/types.js 3.5.0.beta.6 20180704

part of functions.less;

///
class TypesFunctions extends FunctionBase {
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
      (n is DetachedRuleset) ? Keyword.True() : Keyword.False();

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
  Keyword iscolor(Node n) => (n is Color) ? Keyword.True() : Keyword.False();

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
      (n is Dimension) ? Keyword.True() : Keyword.False();

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
  Keyword isstring(Node n) => (n is Quoted) ? Keyword.True() : Keyword.False();

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
      (n is Keyword) ? Keyword.True() : Keyword.False();

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
  Keyword isurl(Node n) => (n is URL) ? Keyword.True() : Keyword.False();

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
      throw LessExceptionError(LessError(
          type: 'Argument',
          message: 'missing the required second argument to isunit.'));
    }

    final String unitValue = (unit is String) ? unit : unit.value;
    if (unitValue is! String) {
      throw LessExceptionError(LessError(
          type: 'Argument',
          message: 'Second argument to isunit should be a unit or a string.'));
    }

    return (n is Dimension && n.unit.isUnit(unitValue))
        ? Keyword.True()
        : Keyword.False();

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
      final p = val is Operation ? '. Have you forgotten parenthesis?' : '';
      throw LessExceptionError(LessError(
          type: 'Argument',
          message: 'the first argument to unit must be a number$p'));
    }

    if (unit != null) {
      unitValue = unit is Keyword ? unit.value : unit.toCSS(null);
    } else {
      unitValue = '';
    }
    return Dimension(val.value, unitValue);

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
  Anonymous getUnit(Dimension n) => Anonymous(n.unit);

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
    base = baseFont?.value ?? base;
    return Dimension(fontSize.value / base, 'rem');
  }
}
