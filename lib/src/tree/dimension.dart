//source: less/tree/dimension.js 3.0.0 20170111

part of tree.less;

///
/// A number with a unit
///
class Dimension extends Node implements CompareNode, OperateNode<Dimension> {
  @override final String      type = 'Dimension';
  @override covariant double  value;

  ///
  Unit unit;

  ///
  /// [value] is int/double or String
  /// [unit] is Unit or String
  ///
  Dimension(dynamic value, [dynamic unit]) {
//    try {
//      this.value = (value is String) ? double.parse(value) : value.toDouble();
//    } catch (e) {
//      throw new LessExceptionError(new LessError(
//        message: 'Dimension is not a number.')
//      );
//    }

    this.value = (value is String)
        ? double.parse(value)
        : (value is num)
          ? value.toDouble()
          : throw new LessExceptionError(new LessError(
              message: 'Dimension is not a number.')
          );

//    if (unit != null) {
//      this.unit = (unit is Unit) ? unit : new Unit(<String>[unit as String]);
//    } else {
//      this.unit = new Unit();
//    }

    this.unit = (unit is Unit)
        ? unit
        : (unit == null)
          ? new Unit()
          : new Unit(<String>[unit as String]);

    setParent(this.unit, this);

//3.0.0 20170111
// var Dimension = function (value, unit) {
//     this.value = parseFloat(value);
//     if (isNaN(this.value)) {
//         throw new Error("Dimension is not a number.");
//     }
//     this.unit = (unit && unit instanceof Unit) ? unit :
//       new Unit(unit ? [unit] : undefined);
//     this.setParent(this.unit, this);
// };
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value,
    'unit': unit
  };

  ///
  @override
  void accept(covariant VisitorBase visitor) {
    unit = visitor.visit(unit) as Unit;

//2.3.1
//  Dimension.prototype.accept = function (visitor) {
//      this.unit = visitor.visit(this.unit);
//  };
  }

  ///
  @override
  Dimension eval(Contexts context) => this;

  ///
  Color toColor() => new Color.fromList(<num>[value, value, value]);

  ///
  @override
  void genCSS(Contexts context, Output output) {
    if ((context?.strictUnits ?? false) && !unit.isSingular()) {
      throw new LessExceptionError(new LessError(
          message: 'Multiple units in dimension. Correct the units or use the unit function. Bad unit: ${unit.toString()}'));
    }

    if (cleanCss != null) return genCleanCSS(context, output);

    final double value = fround(context, this.value);
    String strValue = numToString(value); //10.0 -> '10'

    if (value != 0 && value < 0.000001 && value > -0.000001) {
      // would be output 1e-6 etc.
      strValue = value.toStringAsFixed(20).replaceFirst(new RegExp(r'0+$'), '');
    }

    if (context?.compress ?? false) {
      // Zero values doesn't need a unit
      if (value == 0 && unit.isLength(context)) {
        output.add(strValue);
        return null;
      }

      // Float values doesn't need a leading zero
      if (value > 0 && value < 1) strValue = strValue.substring(1);
    }

    output.add(strValue);
    unit.genCSS(context, output);

//2.3.1
//  Dimension.prototype.genCSS = function (context, output) {
//      if ((context && context.strictUnits) && !this.unit.isSingular()) {
//          throw new Error("Multiple units in dimension. Correct the units or use the unit function. Bad unit: " + this.unit.toString());
//      }
//
//      var value = this.fround(context, this.value),
//          strValue = String(value);
//
//      if (value !== 0 && value < 0.000001 && value > -0.000001) {
//          // would be output 1e-6 etc.
//          strValue = value.toFixed(20).replace(/0+$/, "");
//      }
//
//      if (context && context.compress) {
//          // Zero values doesn't need a unit
//          if (value === 0 && this.unit.isLength()) {
//              output.add(strValue);
//              return;
//          }
//
//          // Float values doesn't need a leading zero
//          if (value > 0 && value < 1) {
//              strValue = (strValue).substr(1);
//          }
//      }
//
//      output.add(strValue);
//      this.unit.genCSS(context, output);
//  };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    final double value = fround(context, this.value, cleanCss.precision);
    String strValue = numToString(value); // 10.0 -> '10'

    if (value != 0 && value < 0.000001 && value > -0.000001) {
      // would be output 1e-6 etc.
      strValue = value.toStringAsFixed(20).replaceFirst(new RegExp(r'0+$'), '');
    }
    if (value == 0 && (unit.isLength(context) || unit.isAngle(context))) {
      output.add(strValue);
      return;
    }
    if (value > 0 && value < 1) strValue = strValue.substring(1); // 0.5
    if (value < 0 && value > -1) strValue = '-${strValue.substring(2)}'; // -0.5

    output.add(strValue);
    unit.genCSS(context, output);
  }

  ///
  /// True if unit is [unitString]
  ///
  bool isUnit(String unitString) => unit?.isUnit(unitString) ?? false;

//--- OperateNode

  ///
  /// In an operation between two Dimensions,
  /// we default to the first Dimension's unit,
  /// so `1px + 2` will yield `3px`.
  ///
  @override
  Dimension operate(Contexts context, String op, Dimension other) {
    Dimension _other = other;
    Unit      unit = this.unit.clone();
    num       value = _operate(context, op, this.value, _other.value);

    if (op == '+' || op == '-') {
      if (unit.numerator.isEmpty && unit.denominator.isEmpty) {
        unit = _other.unit.clone();
        if (this.unit.backupUnit != null) unit.backupUnit = this.unit.backupUnit;
      } else if (_other.unit.numerator.isEmpty && unit.denominator.isEmpty) {
        // do nothing
      } else {
        _other = _other.convertTo(this.unit.usedUnits());

        if (context.strictUnits && _other.unit.toString() != unit.toString()) {
          throw new LessExceptionError(new LessError(
              message: "Incompatible units. Change the units or use the unit function. Bad units: '${
                  unit.toString()}' and '${_other.unit.toString()}'."));
        }
        value = _operate(context, op, this.value, _other.value);
      }
    } else if (op == '*') {
      unit.numerator
          ..addAll(_other.unit.numerator)
          ..sort();
      unit.denominator
          ..addAll(_other.unit.denominator)
          .. sort();
      unit.cancel();
    } else if (op == '/') {
      unit.numerator
          ..addAll(_other.unit.denominator)
          ..sort();
      unit.denominator
          ..addAll(_other.unit.numerator)
          ..sort();
      unit.cancel();
    }

    return new Dimension(value, unit);

//2.4.0+3
//  Dimension.prototype.operate = function (context, op, other) {
//      /*jshint noempty:false */
//      var value = this._operate(context, op, this.value, other.value),
//          unit = this.unit.clone();
//
//      if (op === '+' || op === '-') {
//          if (unit.numerator.length === 0 && unit.denominator.length === 0) {
//              unit = other.unit.clone();
//              if (this.unit.backupUnit) {
//                  unit.backupUnit = this.unit.backupUnit;
//              }
//          } else if (other.unit.numerator.length === 0 && unit.denominator.length === 0) {
//              // do nothing
//          } else {
//              other = other.convertTo(this.unit.usedUnits());
//
//              if (context.strictUnits && other.unit.toString() !== unit.toString()) {
//                  throw new Error("Incompatible units. Change the units or use the unit function. Bad units: '" + unit.toString() +
//                      "' and '" + other.unit.toString() + "'.");
//              }
//
//              value = this._operate(context, op, this.value, other.value);
//          }
//      } else if (op === '*') {
//          unit.numerator = unit.numerator.concat(other.unit.numerator).sort();
//          unit.denominator = unit.denominator.concat(other.unit.denominator).sort();
//          unit.cancel();
//      } else if (op === '/') {
//          unit.numerator = unit.numerator.concat(other.unit.denominator).sort();
//          unit.denominator = unit.denominator.concat(other.unit.numerator).sort();
//          unit.cancel();
//      }
//      return new Dimension(value, unit);
//  };
  }

//--- CompareNode

  ///
  /// Returns -1, 0 or +1
  ///
  @override
  int compare(Node otherNode) {
    if (otherNode is! Dimension) return null;

    Dimension       a;
    Dimension       b;
    final Dimension other = otherNode;

    if (unit.isEmpty() || other.unit.isEmpty()) {
      a = this;
      b = other;
    } else {
      a = unify();
      b = other.unify();
      if (a.unit.compare(b.unit) != 0) return null;
    }

    return Node.numericCompare(a.value, b.value);

//2.3.1
//  Dimension.prototype.compare = function (other) {
//      var a, b;
//
//      if (!(other instanceof Dimension)) {
//          return undefined;
//      }
//
//      if (this.unit.isEmpty() || other.unit.isEmpty()) {
//          a = this;
//          b = other;
//      } else {
//          a = this.unify();
//          b = other.unify();
//          if (a.unit.compare(b.unit) !== 0) {
//              return undefined;
//          }
//      }
//
//      return Node.numericCompare(a.value, b.value);
//  };
  }

  ///
  /// Normalize the units to px, s, or rad
  ///
  Dimension unify() => convertTo(<String, String>{
      'length': 'px',
      'duration': 's',
      'angle': 'rad'
  });

//2.3.1
//  Dimension.prototype.unify = function () {
//      return this.convertTo({ length: 'px', duration: 's', angle: 'rad' });
//  };

  ///
  /// Converts a number from one unit into another
  /// [conversions] ==  'px', 's' , ... or { length: 'px', duration: 's', angle: 'rad' }
  /// String | Map<String, String>
  ///
  Dimension convertTo(dynamic conversions) {
    Map<String, String>       conversionsMap;
    final Map<String, String> derivedConversions = <String, String>{};
    Map<String, double>       group;
    String                    targetUnit; //new unit
    final Unit                unit = this.unit.clone();
    double                    value = this.value;

    if (conversions is String) {
      for (String i in UnitConversions.groups.keys) { //length, duration, angle
        if (UnitConversions.groups[i].containsKey(conversions)) {
          derivedConversions.clear();
          derivedConversions[i] = conversions;
        }
      }
      conversionsMap = derivedConversions; // {length: 'px', ..}
    } else {
      conversionsMap = conversions as Map<String, String>;
    }

    // maths on units
    // [atomicUnit] origina unit
    // ignore: avoid_positional_boolean_parameters
    String applyUnit(String atomicUnit, bool denominator) {
      if (group.containsKey(atomicUnit)) {
        if (denominator) {
          value = value / (group[atomicUnit] / group[targetUnit]);
        } else {
          value = value * (group[atomicUnit] / group[targetUnit]);
        }
        return targetUnit;
      }
      return atomicUnit;
    }

    for (String groupName in conversionsMap.keys) {
      if (conversionsMap.containsKey(groupName)) {
        targetUnit = conversionsMap[groupName];
        group = UnitConversions.groups[groupName];

        unit.map(applyUnit);
      }
    }

    unit.cancel();

    return new Dimension(value, unit);

//2.3.1
//  Dimension.prototype.convertTo = function (conversions) {
//      var value = this.value, unit = this.unit.clone(),
//          i, groupName, group, targetUnit, derivedConversions = {}, applyUnit;
//
//      if (typeof conversions === 'string') {
//          for(i in unitConversions) {
//              if (unitConversions[i].hasOwnProperty(conversions)) {
//                  derivedConversions = {};
//                  derivedConversions[i] = conversions;
//              }
//          }
//          conversions = derivedConversions;
//      }
//      applyUnit = function (atomicUnit, denominator) {
//        /*jshint loopfunc:true */
//          if (group.hasOwnProperty(atomicUnit)) {
//              if (denominator) {
//                  value = value / (group[atomicUnit] / group[targetUnit]);
//              } else {
//                  value = value * (group[atomicUnit] / group[targetUnit]);
//              }
//
//              return targetUnit;
//          }
//
//          return atomicUnit;
//      };
//
//      for (groupName in conversions) {
//          if (conversions.hasOwnProperty(groupName)) {
//              targetUnit = conversions[groupName];
//              group = unitConversions[groupName];
//
//              unit.map(applyUnit);
//          }
//      }
//
//      unit.cancel();
//
//      return new Dimension(value, unit);
//  };
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
