//source: less/tree/dimension.js 1.7.5

part of tree.less;

/*
 * A number with a unit
 */
class Dimension extends Node implements CompareNode, EvalNode, OperateNode, ToCSSNode {
  double value;
  Unit unit;

  final String type = 'Dimension';

  /// [value] is double or String
  /// [unit] is Unit or String
  Dimension(value, [unit = null]) {
    this.value = (value is String) ? double.parse(value) : value.toDouble();

    if (unit != null) {
      this.unit = (unit is Unit) ? unit : new Unit([unit]);
    } else {
      this.unit = new Unit();
    }
  }

  ///
  void accept(Visitor visitor) {
    this.unit = visitor.visit(this.unit);
  }

  ///
  Dimension eval(Contexts env) => this;

  ///
  Color toColor() => new Color([this.value, this.value, this.value]);

  void genCSS(Contexts env, Output output) {
    if ((env != null && isTrue(env.strictUnits)) && !this.unit.isSingular()) {
      throw new LessExceptionError(new LessError(
          message: 'Multiple units in dimension. Correct the units or use the unit function. Bad unit: ${this.unit.toString()}'));
    }

    double value = fround(env, this.value);
    String strValue = numToString(value); //10.0 -> '10'

    if (value != 0 && value < 0.000001 && value > -0.000001) {
      // would be output 1e-6 etc.
      strValue = value.toStringAsFixed(20).replaceFirst(new RegExp(r'0+$'), '');
    }

    if (env != null && env.compress) {
      // Zero values doesn't need a unit
      if (value == 0 && this.unit.isLength(env)) {
        output.add(strValue);
        return;
      }

      // Float values doesn't need a leading zero
      if (value > 0 && value < 1) {
        strValue = strValue.substring(1);
      }
    }

    output.add(strValue);
    this.unit.genCSS(env, output);

//      genCSS: function (env, output) {
//          if ((env && env.strictUnits) && !this.unit.isSingular()) {
//              throw new Error("Multiple units in dimension. Correct the units or use the unit function. Bad unit: "+this.unit.toString());
//          }
//
//          var value = tree.fround(env, this.value),
//              strValue = String(value);
//
//          if (value !== 0 && value < 0.000001 && value > -0.000001) {
//              // would be output 1e-6 etc.
//              strValue = value.toFixed(20).replace(/0+$/, "");
//          }
//
//          if (env && env.compress) {
//              // Zero values doesn't need a unit
//              if (value === 0 && this.unit.isLength()) {
//                  output.add(strValue);
//                  return;
//              }
//
//              // Float values doesn't need a leading zero
//              if (value > 0 && value < 1) {
//                  strValue = (strValue).substr(1);
//              }
//          }
//
//          output.add(strValue);
//          this.unit.genCSS(env, output);
//      },
  }

//      toCSS: tree.toCSS,

//--- OperateNode

  ///
  /// In an operation between two Dimensions,
  /// we default to the first Dimension's unit,
  /// so `1px + 2` will yield `3px`.
  ///
  Dimension operate(Contexts env, String op, Dimension other) {
    num value = Operation.operateExec(env, op, this.value, other.value);
    Unit unit = this.unit.clone();

    if (op == '+' || op == '-') {
      if (unit.numerator.isEmpty && unit.denominator.isEmpty) {
        unit.numerator = other.unit.numerator.sublist(0);
        unit.denominator = other.unit.denominator.sublist(0);
      } else if (other.unit.numerator.isEmpty && unit.denominator.isEmpty) {
        // do nothing
      } else {
        other = other.convertTo(this.unit.usedUnits());

        if (env.strictUnits && other.unit.toString() != unit.toString()) {
          throw new LessExceptionError(new LessError(
              message: "Incompatible units. Change the units or use the unit function. Bad units: '"
                + unit.toString() + "' and '" + other.unit.toString() + "'."));
        }

        value = Operation.operateExec(env, op, this.value, other.value);
      }
    } else if (op == '*') {
      unit.numerator
        ..addAll(other.unit.numerator)
        ..sort();
      unit.denominator
        ..addAll(other.unit.denominator)
        .. sort();
      unit.cancel();
    } else if (op == '/') {
      unit.numerator
        ..addAll(other.unit.denominator)
        ..sort();
      unit.denominator
        ..addAll(other.unit.numerator)
        ..sort();
      unit.cancel();
    }

    return new Dimension(value, unit);

//      operate: function (env, op, other) {
//          /*jshint noempty:false */
//          var value = tree.operate(env, op, this.value, other.value),
//              unit = this.unit.clone();
//
//          if (op === '+' || op === '-') {
//              if (unit.numerator.length === 0 && unit.denominator.length === 0) {
//                  unit.numerator = other.unit.numerator.slice(0);
//                  unit.denominator = other.unit.denominator.slice(0);
//              } else if (other.unit.numerator.length === 0 && unit.denominator.length === 0) {
//                  // do nothing
//              } else {
//                  other = other.convertTo(this.unit.usedUnits());
//
//                  if(env.strictUnits && other.unit.toString() !== unit.toString()) {
//                    throw new Error("Incompatible units. Change the units or use the unit function. Bad units: '" + unit.toString() +
//                      "' and '" + other.unit.toString() + "'.");
//                  }
//
//                  value = tree.operate(env, op, this.value, other.value);
//              }
//          } else if (op === '*') {
//              unit.numerator = unit.numerator.concat(other.unit.numerator).sort();
//              unit.denominator = unit.denominator.concat(other.unit.denominator).sort();
//              unit.cancel();
//          } else if (op === '/') {
//              unit.numerator = unit.numerator.concat(other.unit.denominator).sort();
//              unit.denominator = unit.denominator.concat(other.unit.numerator).sort();
//              unit.cancel();
//          }
//          return new(tree.Dimension)(value, unit);
//      },
  }


//--- CompareNode

  /// Returns -1, 0 or +1
  int compare(Node other) {
    if (other is! Dimension) return -1;

    Dimension otherDim = other as Dimension;
    Dimension a;
    Dimension b;

    if (this.unit.isEmpty() || otherDim.unit.isEmpty()) {
      a = this;
      b = otherDim;
    } else {
      a = this.unify();
      b = otherDim.unify();
      if (a.unit.compare(b.unit) != 0) return -1;
    }

    return a.value.compareTo(b.value);

//      compare: function (other) {
//          if (other instanceof tree.Dimension) {
//              var a, b,
//                  aValue, bValue;
//
//              if (this.unit.isEmpty() || other.unit.isEmpty()) {
//                  a = this;
//                  b = other;
//              } else {
//                  a = this.unify();
//                  b = other.unify();
//                  if (a.unit.compare(b.unit) !== 0) {
//                      return -1;
//                  }
//              }
//              aValue = a.value;
//              bValue = b.value;
//
//              if (bValue > aValue) {
//                  return -1;
//              } else if (bValue < aValue) {
//                  return 1;
//              } else {
//                  return 0;
//              }
//          } else {
//              return -1;
//          }
//      },
  }

  ///
  /// Normalize the units to px, s, or rad
  ///
  Dimension unify() => convertTo({ 'length': 'px', 'duration': 's', 'angle': 'rad' });

  ///
  /// Convert a number from one unit into another
  /// [conversions] ==  'px', 's' , ...
  /// or { length: 'px', duration: 's', angle: 'rad' }
  ///
  Dimension convertTo(conversions) {
    double value = this.value;
    Unit unit = this.unit.clone();
    String i;
    String groupName;
    Map<String, double> group;
    String targetUnit; //new unit
    Map derivedConversions = {};
    Map<String, String> conversionsMap;

    if (conversions is String) {
      for (i in UnitConversions.groups.keys) { //length, duration, angle
        if (UnitConversions.groups[i].containsKey(conversions)) {
          derivedConversions = {};
          derivedConversions[i] = conversions;
        }
      }
      conversionsMap = derivedConversions; // {length: 'px', ..}
    } else {
      conversionsMap = conversions;
    }

    // maths on units
    // [atomicUnit] origina unit
    applyUnit(String atomicUnit, bool denominator) {
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

    for (groupName in conversionsMap.keys) {
      if (conversionsMap.containsKey(groupName)) {
        targetUnit = conversionsMap[groupName];
        group = UnitConversions.groups[groupName];

        unit.map(applyUnit);
      }
    }

    unit.cancel();

    return new Dimension(value, unit);

//      convertTo: function (conversions) {
//          var value = this.value, unit = this.unit.clone(),
//              i, groupName, group, targetUnit, derivedConversions = {}, applyUnit;
//
//          if (typeof conversions === 'string') {
//              for(i in tree.UnitConversions) {
//                  if (tree.UnitConversions[i].hasOwnProperty(conversions)) {
//                      derivedConversions = {};
//                      derivedConversions[i] = conversions;
//                  }
//              }
//              conversions = derivedConversions;
//          }
//          applyUnit = function (atomicUnit, denominator) {
//            /*jshint loopfunc:true */
//              if (group.hasOwnProperty(atomicUnit)) {
//                  if (denominator) {
//                      value = value / (group[atomicUnit] / group[targetUnit]);
//                  } else {
//                      value = value * (group[atomicUnit] / group[targetUnit]);
//                  }
//
//                  return targetUnit;
//              }
//
//              return atomicUnit;
//          };
//
//          for (groupName in conversions) {
//              if (conversions.hasOwnProperty(groupName)) {
//                  targetUnit = conversions[groupName];
//                  group = tree.UnitConversions[groupName];
//
//                  unit.map(applyUnit);
//              }
//          }
//
//          unit.cancel();
//
//          return new(tree.Dimension)(value, unit);
//      }
  }
}
