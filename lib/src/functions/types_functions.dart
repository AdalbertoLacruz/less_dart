// source: lib/less/functions/types.js 2.2.0

part of functions.less;

class TypesFunctions extends FunctionBase {

//  var isa = function (n, Type) {
//      return (n instanceof Type) ? Keyword.True : Keyword.False;
//  }

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
  Keyword iscolor(n) => (n is Color) ? new Keyword.True() : new Keyword.False();

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
  Keyword isnumber(n) => (n is Dimension) ? new Keyword.True() : new Keyword.False();

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
  Keyword isstring(n) => (n is Quoted) ? new Keyword.True() : new Keyword.False();

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
  Keyword iskeyword(n) => (n is Keyword) ? new Keyword.True() : new Keyword.False();

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
  Keyword isurl(n) => (n is URL) ? new Keyword.True() : new Keyword.False();

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
  Keyword ispixel(n) => isunit(n, 'px');

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
  Keyword ispercentage(n) => isunit(n, '%');

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
  Keyword isem(n) => isunit(n, 'em');

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
  Keyword isunit(n, unit) {
    if (unit == null) {
      throw new LessExceptionError(new LessError(
        type: 'Argument',
        message: 'missing the required second argument to isunit.'));
    }

    //String unitValue = (unit.value is String) ? unit.value : unit;
    String unitValue = (unit is String) ? unit : unit.value;
    if(unitValue is! String) {
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
    var unitValue;

    if (val is! Dimension) {
      String p = val is Operation ? '. Have you forgotten parenthesis?' : '';
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'the first argument to unit must be a number${p}'));
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

//    unit: function (val, unit) {
//            if(!(val instanceof Dimension)) {
//                throw { type: "Argument", message: "the first argument to unit must be a number" + (val instanceof Operation ? ". Have you forgotten parenthesis?" : "") };
//            }
//            if (unit) {
//                if (unit instanceof Keyword) {
//                    unit = unit.value;
//                } else {
//                    unit = unit.toCSS();
//                }
//            } else {
//                unit = "";
//            }
//            return new Dimension(val.value, unit);
//        }
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
  @defineMethod(name: 'get-unit')
  Anonymous getUnit(Dimension n) => new Anonymous(n.unit);

  ///
  /// Returns the value at a specified position in a list.
  ///
  /// Parameters:
  ///   list - a comma or space separated list of values.
  ///   index - an integer that specifies a position of a list element to return.
  ///   Returns: a value at the specified position in a list.
  /// Example: extract(8px dotted red, 2);
  ///   Output: dotted
  ///
  Node extract(Node values, Node index) {
    int iIndex = (index.value as num).toInt() - 1; // (1-based index)
    if (iIndex < 0) return null;

    // handle non-array values as an array of length 1
    // return 'null' if index is invalid
    if (values.value is List) {
      return (iIndex >= values.value.length) ? null : values.value[iIndex];
    } else {
      return (iIndex > 0) ? null : values; //TODO ???
    }

//    extract: function(values, index) {
//        index = index.value - 1; // (1-based index)
//        // handle non-array values as an array of length 1
//        // return 'undefined' if index is invalid
//        return Array.isArray(values.value)
//            ? values.value[index] : Array(values)[index];
//    },
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
  Dimension length(Node values) {
    int n = (values.value is List) ? values.value.length : 1;
    return new Dimension(n);

//    length: function(values) {
//        var n = Array.isArray(values.value) ? values.value.length : 1;
//        return new Dimension(n);
//    },
  }
}