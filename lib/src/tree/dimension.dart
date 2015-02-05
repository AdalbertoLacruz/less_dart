//source: less/tree/dimension.js 2.3.1

part of tree.less;

///
/// A number with a unit
///
class Dimension extends Node implements CompareNode, EvalNode, OperateNode, ToCSSNode {
  double value;
  Unit unit;

  final String type = 'Dimension';

  ///
  /// [value] is double or String
  /// [unit] is Unit or String
  ///
  //2.3.1 ok
  Dimension(value, [unit = null]) {
    this.value = (value is String) ? double.parse(value) : value.toDouble();

    if (unit != null) {
      this.unit = (unit is Unit) ? unit : new Unit([unit]);
    } else {
      this.unit = new Unit();
    }

//2.3.1
//  var Dimension = function (value, unit) {
//      this.value = parseFloat(value);
//      this.unit = (unit && unit instanceof Unit) ? unit :
//        new Unit(unit ? [unit] : undefined);
//  };
  }

  ///
  //2.3.1 ok
  void accept(Visitor visitor) {
    this.unit = visitor.visit(this.unit);

//2.3.1
//  Dimension.prototype.accept = function (visitor) {
//      this.unit = visitor.visit(this.unit);
//  };
  }

  ///
  //2.3.1 ok
  Dimension eval(Contexts context) => this;

  ///
  //2.3.1 ok
  Color toColor() => new Color([this.value, this.value, this.value]);

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    if ((context != null && isTrue(context.strictUnits)) && !this.unit.isSingular()) {
      throw new LessExceptionError(new LessError(
          message: 'Multiple units in dimension. Correct the units or use the unit function. Bad unit: ${this.unit.toString()}'));
    }

    double value = fround(context, this.value);
    String strValue = numToString(value); //10.0 -> '10'

    if (value != 0 && value < 0.000001 && value > -0.000001) {
      // would be output 1e-6 etc.
      strValue = value.toStringAsFixed(20).replaceFirst(new RegExp(r'0+$'), '');
    }

    if (context != null && context.compress) {
      // Zero values doesn't need a unit
      if (value == 0 && this.unit.isLength(context)) {
        output.add(strValue);
        return;
      }

      // Float values doesn't need a leading zero
      if (value > 0 && value < 1) {
        strValue = strValue.substring(1);
      }
    }

    output.add(strValue);
    this.unit.genCSS(context, output);

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

//      toCSS: tree.toCSS,

//--- OperateNode

  ///
  /// In an operation between two Dimensions,
  /// we default to the first Dimension's unit,
  /// so `1px + 2` will yield `3px`.
  ///
  //2.3.1 ok
  Dimension operate(Contexts context, String op, Dimension other) {
    num value = _operate(context, op, this.value, other.value);
    Unit unit = this.unit.clone();

    if (op == '+' || op == '-') {
      if (unit.numerator.isEmpty && unit.denominator.isEmpty) {
        unit.numerator = other.unit.numerator.sublist(0);
        unit.denominator = other.unit.denominator.sublist(0);
      } else if (other.unit.numerator.isEmpty && unit.denominator.isEmpty) {
        // do nothing
      } else {
        other = other.convertTo(this.unit.usedUnits());

        if (context.strictUnits && other.unit.toString() != unit.toString()) {
          throw new LessExceptionError(new LessError(
              message: "Incompatible units. Change the units or use the unit function. Bad units: '"
                + unit.toString() + "' and '" + other.unit.toString() + "'."));
        }

        value = _operate(context, op, this.value, other.value);
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

//2.3.1
//  Dimension.prototype.operate = function (context, op, other) {
//      /*jshint noempty:false */
//      var value = this._operate(context, op, this.value, other.value),
//          unit = this.unit.clone();
//
//      if (op === '+' || op === '-') {
//          if (unit.numerator.length === 0 && unit.denominator.length === 0) {
//              unit.numerator = other.unit.numerator.slice(0);
//              unit.denominator = other.unit.denominator.slice(0);
//          } else if (other.unit.numerator.length === 0 && unit.denominator.length === 0) {
//              // do nothing
//          } else {
//              other = other.convertTo(this.unit.usedUnits());
//
//              if(context.strictUnits && other.unit.toString() !== unit.toString()) {
//                throw new Error("Incompatible units. Change the units or use the unit function. Bad units: '" + unit.toString() +
//                  "' and '" + other.unit.toString() + "'.");
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
  //2.3.1 ok
  int compare(Node otherNode) {
    if (otherNode is! Dimension) return null;

    Dimension a;
    Dimension b;
    Dimension other = otherNode as Dimension;

    if (this.unit.isEmpty() || other.unit.isEmpty()) {
      a = this;
      b = other;
    } else {
      a = this.unify();
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
  //2.3.1 ok
  Dimension unify() => convertTo({ 'length': 'px', 'duration': 's', 'angle': 'rad' });

//2.3.1
//  Dimension.prototype.unify = function () {
//      return this.convertTo({ length: 'px', duration: 's', angle: 'rad' });
//  };

  ///
  /// Converts a number from one unit into another
  /// [conversions] ==  'px', 's' , ...
  /// or { length: 'px', duration: 's', angle: 'rad' }
  ///
  //2.3.1 ok
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
}
