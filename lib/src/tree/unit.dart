//source: less/tree/dimension.js 2.5.0

part of tree.less;

class Unit extends Node implements CompareNode {
  List numerator;
  List denominator;
  String backupUnit;

  final String type = 'Unit';

  ///
  Unit([List numerator = const [], List denominator = const [], this.backupUnit = null]) {
   this.numerator = numerator.sublist(0)..sort(); //clone
   this.denominator = denominator.sublist(0)..sort();
   if (this.backupUnit == null && this.numerator.isNotEmpty) {
     this.backupUnit = this.numerator[0];
   }

//2.3.1
// var Unit = function (numerator, denominator, backupUnit) {
//     this.numerator = numerator ? numerator.slice(0).sort() : [];
//     this.denominator = denominator ? denominator.slice(0).sort() : [];
//     if (backupUnit) {
//         this.backupUnit = backupUnit;
//     } else if (numerator && numerator.length) {
//         this.backupUnit = numerator[0];
//     }
// };
  }

  ///
  Unit clone()=> new Unit(numerator.sublist(0), denominator.sublist(0), backupUnit);

//2.3.1
//  Unit.prototype.clone = function () {
//      return new Unit(this.numerator.slice(0), this.denominator.slice(0), this.backupUnit);
//  };

  ///
  void genCSS(Contexts context, Output output) {
    // Dimension checks the unit is singular and throws an error if in strict math mode.
    bool stricUnits = (context != null && context.strictUnits != null) ? context.strictUnits : false;

    if (numerator.length == 1) {
      output.add(numerator[0]); // the ideal situation
    } else if (!stricUnits && backupUnit != null) {
      output.add(backupUnit);
    } else if (!stricUnits && denominator.isNotEmpty) {
      output.add(denominator[0]);
    }

//2.4.0
//  Unit.prototype.genCSS = function (context, output) {
//      // Dimension checks the unit is singular and throws an error if in strict math mode.
//      var strictUnits = context && context.strictUnits;
//      if (this.numerator.length === 1) {
//          output.add(this.numerator[0]); // the ideal situation
//      } else if (!strictUnits && this.backupUnit) {
//          output.add(this.backupUnit);
//      } else if (!strictUnits && this.denominator.length) {
//          output.add(this.denominator[0]);
//      }
//  };
  }

  ///
  String toString() {
    String returnStr = numerator.join('*');
    for (int i = 0; i < denominator.length; i++) {
      returnStr += '/' + denominator[i];
    }
    return returnStr;

//2.3.1
//  Unit.prototype.toString = function () {
//      var i, returnStr = this.numerator.join("*");
//      for (i = 0; i < this.denominator.length; i++) {
//          returnStr += "/" + this.denominator[i];
//      }
//      return returnStr;
//  };
  }

  //--- CompareNode

  /// Returns -1 for different, 0 for equal
  int compare(Node other) => this.isUnit(other.toString()) ? 0 : null;

//2.3.1
//  Unit.prototype.compare = function (other) {
//      return this.is(other.toString()) ? 0 : undefined;
//  };

  ///
  //is in js
  bool isUnit(String unitString)
    => this.toString().toUpperCase() == unitString.toUpperCase();

//2.3.1
//  Unit.prototype.is = function (unitString) {
//      return this.toString().toUpperCase() === unitString.toUpperCase();
//  };

  ///
  bool isLength(Contexts context) {
    RegExp re = new RegExp(r'px|em|%|in|cm|mm|pc|pt|ex'); //i?
    return re.hasMatch(toCSS(context));

//2.3.1
//  Unit.prototype.isLength = function () {
//      return Boolean(this.toCSS().match(/px|em|%|in|cm|mm|pc|pt|ex/));
//  };
  }

  ///
  bool isAngle(Contexts context) {
    RegExp re = new RegExp(r'rad|deg|grad|turn'); //i?
    return re.hasMatch(toCSS(context));
  }

  ///
  /// True if numerator & denominator isEmpty
  ///
  bool isEmpty() => numerator.isEmpty && denominator.isEmpty;

//2.3.1
//  Unit.prototype.isEmpty = function () {
//      return this.numerator.length === 0 && this.denominator.length === 0;
//  };

  ///
  bool isSingular() => (numerator.length <= 1 && denominator.isEmpty);

//2.3.1
//  Unit.prototype.isSingular = function() {
//      return this.numerator.length <= 1 && this.denominator.length === 0;
//  };

  ///
  /// Process numerator and denominator according to [calback] function
  /// String callback(String unit, bool isDenominator)
  /// callback returns new unit
  ///
  void map(Function callback) {
    int i;

    for (i = 0; i < numerator.length; i++) {
      numerator[i] = callback(numerator[i], false);
    }

    for (i = 0; i < denominator.length; i++) {
      denominator[i] = callback(denominator[i], true);
    }

//2.3.1
//  Unit.prototype.map = function(callback) {
//      var i;
//
//      for (i = 0; i < this.numerator.length; i++) {
//          this.numerator[i] = callback(this.numerator[i], false);
//      }
//
//      for (i = 0; i < this.denominator.length; i++) {
//          this.denominator[i] = callback(this.denominator[i], true);
//      }
//  };
  }

  ///
  Map usedUnits() {
    Map<String, double> group;
    Map<String, String> result = {};
    String groupName;

    String mapUnit(String atomicUnit, bool isDenominator) {
      if (group.containsKey(atomicUnit) && !result.containsKey(groupName)) {
        result[groupName] = atomicUnit;
      }
      return atomicUnit;
    }

    for (groupName in UnitConversions.groups.keys) {
      if (UnitConversions.groups.containsKey(groupName)) {//redundant?
        group = UnitConversions.groups[groupName];

        map(mapUnit);
      }
    }

    return result;

//2.3.1
//  Unit.prototype.usedUnits = function() {
//      var group, result = {}, mapUnit;
//
//      mapUnit = function (atomicUnit) {
//          /*jshint loopfunc:true */
//          if (group.hasOwnProperty(atomicUnit) && !result[groupName]) {
//              result[groupName] = atomicUnit;
//          }
//
//          return atomicUnit;
//      };
//
//      for (var groupName in unitConversions) {
//          if (unitConversions.hasOwnProperty(groupName)) {
//              group = unitConversions[groupName];
//
//              this.map(mapUnit);
//          }
//      }
//
//      return result;
//  };
  }

  ///
  /// Normalize numerator and denominator after operations
  ///
  void cancel() {
    Map<String, int> counter = {};
    String atomicUnit;
    int i;

    for (i = 0; i < numerator.length; i++) {
      atomicUnit = numerator[i];
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] + 1;
    }

    for (i = 0; i < denominator.length; i++) {
      atomicUnit = denominator[i];
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] -1;
    }

    numerator = [];
    denominator = [];

    for (atomicUnit in counter.keys) {
      if (counter.containsKey(atomicUnit)) {
        int count = counter[atomicUnit];
        if (count > 0) {
          for (i = 0; i < count; i++) numerator.add(atomicUnit);
        } else if (count < 0) {
          for (i = 0; i < -count; i++) denominator.add(atomicUnit);
        }
      }
    }

    numerator.sort();
    denominator.sort();

//2.3.1
//  Unit.prototype.cancel = function () {
//      var counter = {}, atomicUnit, i;
//
//      for (i = 0; i < this.numerator.length; i++) {
//          atomicUnit = this.numerator[i];
//          counter[atomicUnit] = (counter[atomicUnit] || 0) + 1;
//      }
//
//      for (i = 0; i < this.denominator.length; i++) {
//          atomicUnit = this.denominator[i];
//          counter[atomicUnit] = (counter[atomicUnit] || 0) - 1;
//      }
//
//      this.numerator = [];
//      this.denominator = [];
//
//      for (atomicUnit in counter) {
//          if (counter.hasOwnProperty(atomicUnit)) {
//              var count = counter[atomicUnit];
//
//              if (count > 0) {
//                  for (i = 0; i < count; i++) {
//                      this.numerator.push(atomicUnit);
//                  }
//              } else if (count < 0) {
//                  for (i = 0; i < -count; i++) {
//                      this.denominator.push(atomicUnit);
//                  }
//              }
//          }
//      }
//
//      this.numerator.sort();
//      this.denominator.sort();
//  };
  }
}