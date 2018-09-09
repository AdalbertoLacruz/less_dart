// source: lib/less/functions/number.js 2.5.1 20150720

part of functions.less;

///
class NumberFunctions extends FunctionBase {
  @defineMethodSkip
  Node _minmax(bool isMin, List<Node> args) {
    if (args.isEmpty) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'one or more arguments required'));
    }

    Dimension current;
    Dimension currentUnified;
    int       j;
    Dimension referenceUnified;
    String    unit;
    String    unitClone;
    String    unitStatic;

    // elems only contains original argument values.
    final List<Dimension> order = <Dimension>[];

    // key is the unit.toString() for unified Dimension values,
    // value is the index into the order array.
    final Map<String, int> values = <String, int>{};

    for (int i = 0; i < args.length; i++) {
      if (args[i] is! Dimension) {
        if (args[i].value is List) args.addAll(args[i].value);
        continue;
      }
      current = args[i];
      currentUnified = (current.unit.toString() == '' && unitClone != null)
          ? new Dimension(current.value, unitClone).unify()
          : current.unify();
      unit = (currentUnified.unit.toString() == '' && unitStatic != null)
          ? unitStatic
          : currentUnified.unit.toString();
      unitStatic = (unit != '' && unitStatic == null || unit != '' && order[0].unify().unit.toString() == '')
          ? unit
          : unitStatic;
      unitClone = (unit != '' && unitClone == null)
          ? current.unit.toString()
          : unitClone;
      j = (values[''] != null && unit != '' && unit == unitStatic)
          ? values['']
          : values[unit];
      if (j == null) {
        if (unitStatic != null && unit != unitStatic) {
          throw new LessExceptionError(new LessError(
              type: 'Argument',
              message: 'incompatible types'));
        }
        values[unit] = order.length;
        order.add(current);
        continue;
      }
      referenceUnified = (order[j].unit.toString() == '' && unitClone != null)
          ? new Dimension(order[j].value, unitClone).unify()
          : order[j].unify();
      if (isMin && currentUnified.value < referenceUnified.value ||
          !isMin && currentUnified.value > referenceUnified.value) {
        order[j] = current;
      }
    }

    if (order.length == 1) return order[0];
    final String arguments = order
        .map((Dimension a) => a.toCSS(context))
        .toList()
        .join(context.compress ? ',' : ', ');

    return new Anonymous('${isMin ? 'min' : 'max'}($arguments)');

//    var minMax = function (isMin, args) {
//        args = Array.prototype.slice.call(args);
//        switch(args.length) {
//            case 0: throw { type: "Argument", message: "one or more arguments required" };
//        }
//        var i, j, current, currentUnified, referenceUnified, unit, unitStatic, unitClone,
//            order  = [], // elems only contains original argument values.
//            values = {}; // key is the unit.toString() for unified Dimension values,
//        // value is the index into the order array.
//        for (i = 0; i < args.length; i++) {
//            current = args[i];
//            if (!(current instanceof Dimension)) {
//                if(Array.isArray(args[i].value)) {
//                    Array.prototype.push.apply(args, Array.prototype.slice.call(args[i].value));
//                }
//                continue;
//            }
//            currentUnified = current.unit.toString() === "" && unitClone !== undefined ? new Dimension(current.value, unitClone).unify() : current.unify();
//            unit = currentUnified.unit.toString() === "" && unitStatic !== undefined ? unitStatic : currentUnified.unit.toString();
//            unitStatic = unit !== "" && unitStatic === undefined || unit !== "" && order[0].unify().unit.toString() === "" ? unit : unitStatic;
//            unitClone = unit !== "" && unitClone === undefined ? current.unit.toString() : unitClone;
//            j = values[""] !== undefined && unit !== "" && unit === unitStatic ? values[""] : values[unit];
//            if (j === undefined) {
//                if(unitStatic !== undefined && unit !== unitStatic) {
//                    throw{ type: "Argument", message: "incompatible types" };
//                }
//                values[unit] = order.length;
//                order.push(current);
//                continue;
//            }
//            referenceUnified = order[j].unit.toString() === "" && unitClone !== undefined ? new Dimension(order[j].value, unitClone).unify() : order[j].unify();
//            if ( isMin && currentUnified.value < referenceUnified.value ||
//                !isMin && currentUnified.value > referenceUnified.value) {
//                order[j] = current;
//            }
//        }
//        if (order.length == 1) {
//            return order[0];
//        }
//        args = order.map(function (a) { return a.toCSS(this.context); }).join(this.context.compress ? "," : ", ");
//        return new Anonymous((isMin ? "min" : "max") + "(" + args + ")");
//    };
  }

  ///
  /// Returns the lowest of one or more values.
  ///
  /// Parameters: value1, ..., valueN - one or more values to compare.
  ///   Returns: the lowest value.
  /// Example: min(3px, 42px, 1px, 16px);
  ///   Output: 1px
  ///
  ///
  @defineMethodListArguments
  Node min(List<Node> arguments) => _minmax(true, arguments);

  ///
  /// Returns the highest of one or more values.
  ///
  /// Parameters: value1, ..., valueN - one or more values to compare.
  ///   Returns: the highest value.
  /// Example: max(3%, 42%, 1%, 16%);
  /// Output: 42%
  ///
  ///
  @defineMethodListArguments
  Node max(List<Node> arguments) => _minmax(false, arguments);

  ///
  /// Convert a number from one unit into another.
  ///
  /// The first argument contains a number with units and second argument contains units.
  /// If the units are compatible, the number is converted.
  /// If they are not compatible, the first argument is returned unmodified.
  ///
  /// Compatible unit groups:
  ///   lengths: m, cm, mm, in, pt and pc,
  ///   time: s and ms,
  ///   angle: rad, deg, grad and turn.
  /// Parameters:
  ///   number: a floating point number with units.
  ///   identifier, string or escaped value: units
  ///   Returns: number
  /// Example:
  ///   convert(9s, "ms")
  ///   Output: 9000ms
  ///
  ///
  Dimension convert(Dimension val, Node unit) => val.convertTo(unit.value);

  ///
  /// Returns π (pi);
  ///
  /// Parameters: none
  ///   Returns: number
  /// Example:
  ///   pi()
  ///   Output: 3.141592653589793
  ///
  ///
  Dimension pi() => new Dimension(math.pi);

  ///
  /// Returns the value of the first argument modulus second argument.
  /// Returned value has the same dimension as the first parameter, the dimension
  /// of the second parameter is ignored.
  ///
  /// Parameters:
  ///   number: a floating point number.
  ///   number: a floating point number.
  ///   Returns: number
  /// Example:
  ///   mod(11cm, 6px);
  ///   Output: 5cm
  ///
  Dimension mod(Dimension a, Dimension b) =>
      new Dimension(a.value % b.value, a.unit);

  ///
  /// Returns the value of the first argument raised to the power of the second argument.
  /// Returned value has the same dimension as the first parameter and the dimension of the second parameter is ignored.
  ///
  /// Parameters:
  ///   number: base -a floating point number.
  ///   number: exponent - a floating point number.
  ///   Returns: number
  /// Example:
  ///   pow(0cm, 0px)
  ///   Output: 1cm
  ///
  ///
  Dimension pow(dynamic x, dynamic y) {
    dynamic _x = x;
    dynamic _y = y;

    if (_x is num && _y is num) {
      _x = new Dimension(_x);
      _y = new Dimension(_y);
    } else if (_x is! Dimension || _y is! Dimension) {
      throw new LessExceptionError(new LessError(
          type: 'Argument',
          message: 'arguments must be numbers'));
    }

    return new Dimension(math.pow(_x.value, _y.value), _x.unit);

//    pow: function(x, y) {
//        if (typeof x === "number" && typeof y === "number") {
//            x = new Dimension(x);
//            y = new Dimension(y);
//        } else if (!(x instanceof Dimension) || !(y instanceof Dimension)) {
//            throw { type: "Argument", message: "arguments must be numbers" };
//        }
//
//        return new Dimension(Math.pow(x.value, y.value), x.unit);
//    },
  }

  ///
  /// Converts a floating point number into a percentage string.
  ///
  /// Parameters:
  ///   number - a floating point number.
  ///   Returns: string
  /// Example: percentage(0.5)
  ///   Output: 50%
  ///
  Dimension percentage(Node n) => MathHelper._math((num d) => d * 100, '%', n);

//2.5.1 20150720
// percentage: function (n) {
//     var result = mathHelper._math(function(num) {
//         return num * 100;
//     }, '%', n);
//
//     return result;
// }
}
