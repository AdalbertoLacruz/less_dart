// source: lib/less/functions/math.js 2.5.0

part of functions.less;

class MathFunctions extends FunctionBase {
  ///
  /// Applies Function [fn] to Node [n].
  /// [unit] String ex: 'rad'
  ///
  @defineMethodSkip
  Dimension _math(Function fn, String unit, Node n) {
    if (n is! Dimension) {
     throw new LessExceptionError(new LessError(
         type: 'Argument',
         message: 'argument must be a number'));
    }

    Dimension node = n;
    Unit nodeUnit;

    if (unit == null) {
      nodeUnit = node.unit;
    } else {
      node = node.unify();
      nodeUnit = new Unit(<String>[unit]);
    }
    return new Dimension(fn(node.value.toDouble()), nodeUnit);
  }

//function _math(fn, unit, n) {
//    if (!(n instanceof Dimension)) {
//        throw { type: "Argument", message: "argument must be a number" };
//    }
//    if (unit == null) {
//        unit = n.unit;
//    } else {
//        n = n.unify();
//    }
//    return new Dimension(fn(parseFloat(n.value)), unit);
//}

  @defineMethodSkip
  num _ceil(num n) => n.ceil();

  @defineMethodSkip
  num _floor(num n) => n.floor();

  @defineMethodSkip
  num _abs(num n) => n.abs();

//var mathFunctions = {
// // name,  unit
//    ceil:  null,
//    floor: null,
//    sqrt:  null,
//    abs:   null,
//    tan:   "",
//    sin:   "",
//    cos:   "",
//    atan:  "rad",
//    asin:  "rad",
//    acos:  "rad"
//};

  ///
  /// Rounds up to the next highest integer.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: integer
  /// Example: ceil(2.4)
  ///   Output: 3
  ///
  Dimension ceil(Node n) => _math(_ceil, null, n);

  ///
  /// Rounds down to the next lowest integer.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: integer
  /// Example: floor(2.6)
  ///   Output: 2
  ///
  Dimension floor(Node n) => _math(_floor, null, n);

  ///
  /// Calculates square root of a number. Keeps units as they are.
  ///
  /// Parameters:
  ///   number - floating point number.
  ///   Returns: number
  /// Example: sqrt(25cm)
  ///   Output: 5cm
  ///
  Dimension sqrt(Node n) => _math(math.sqrt, null, n);

  ///
  /// Calculates absolute value of a number. Keeps units as they are.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example: abs(-18.6%)
  ///   Output: 18.6%;
  ///
  Dimension abs(Node n) => _math(_abs, null, n);

  ///
  /// Calculates tangent function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   tan(1deg) // tangent of 1 degree
  ///   Output: 0.017455064928217585
  ///
  Dimension tan(Node n) => _math(math.tan, '', n);

  ///
  /// Calculates sine function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   sin(1deg); // sine of 1 degree
  ///   Output: 0.01745240643728351;
  ///
  Dimension sin(Node n) => _math(math.sin, '', n);

  ///
  /// Calculates cosine function.
  /// Assumes radians on numbers without units.
  //
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   cos(1deg) // cosine of 1 degree
  ///   Output: 0.9998476951563913;
  ///
  Dimension cos(Node n) => _math(math.cos, '', n);

  ///
  /// Calculates arctangent (inverse of tangent) function.
  /// Returns number in radians e.g. a number between -π/2 and π/2.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: number
  /// Example:
  ///   atan(-1.5574077246549023)
  /// Output: -1rad;
  ///
  Dimension atan(Node n) => _math(math.atan, 'rad', n);

  ///
  /// Calculates arcsine (inverse of sine) function.
  /// Returns number in radians e.g. a number between -π/2 and π/2.
  ///
  /// Parameters:
  ///   number - floating point number from [-1, 1] interval.
  ///   Returns: number
  /// Example:
  ///   asin(-0.8414709848078965)
  ///   Output: -1rad
  ///
  Dimension asin(Node n) => _math(math.asin, 'rad', n);

  ///
  /// Calculates arccosine (inverse of cosine) function.
  /// Returns number in radians e.g. a number between 0 and π.
  //
  /// Parameters:
  ///   number - a floating point number from [-1, 1] interval.
  ///   Returns: number
  /// Example:
  ///   acos(0.5403023058681398)
  ///   Output: 1rad
  ///
  Dimension acos(Node n) => _math(math.acos, 'rad', n);

  ///
  /// Applies rounding.
  ///
  /// Parameters:
  ///   number: A floating point number.
  ///   decimalPlaces: Optional: The number of decimal places to round to. Defaults to 0.
  ///   Returns: number
  /// Example: round(1.67)
  ///   Output: 2
  /// Example: round(1.67, 1)
  ///   Output: 1.7
  ///
  Dimension round(Node n, [Node f]) {
    final num fraction = (f == null) ? 0 : f.value;

    return _math((num d) {
      final double exp = math.pow(10, fraction).toDouble();
      return (d * exp).roundToDouble() / exp;
    }, null, n);

//    mathFunctions.round = function (n, f) {
//        var fraction = typeof(f) === "undefined" ? 0 : f.value;
//        return _math(function(num) { return num.toFixed(fraction); }, null, n);
//    };
  }
}
