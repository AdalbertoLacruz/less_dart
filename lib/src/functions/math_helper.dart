// source: lib/less/functions/math-helper.js 2.5.1 20150720

part of functions.less;

///
class MathHelper {
  ///
  /// Applies Function [fn] to Node [n].
  /// [unit] String ex: 'rad'
  ///
  //@defineMethodSkip
  static Dimension _math(Function fn, String unit, Node n) {
    if (n is! Dimension) {
      throw LessExceptionError(
          LessError(type: 'Argument', message: 'argument must be a number'));
    }

    Dimension node = n;
    Unit nodeUnit;

    if (unit == null) {
      nodeUnit = node.unit;
    } else {
      node = node.unify();
      nodeUnit = Unit(<String>[unit]);
    }
    return Dimension(fn(node.value.toDouble()), nodeUnit);

//2.5.1 20150720
// MathHelper._math = function (fn, unit, n) {
//     if (!(n instanceof Dimension)) {
//         throw { type: "Argument", message: "argument must be a number" };
//     }
//     if (unit == null) {
//         unit = n.unit;
//     } else {
//         n = n.unify();
//     }
//     return new Dimension(fn(parseFloat(n.value)), unit);
// };
  }
}
