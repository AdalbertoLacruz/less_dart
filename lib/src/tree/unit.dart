//source: less/tree/dimension.js 1.7.5

part of tree.less;

class Unit extends Node implements CompareNode, ToCSSNode {
  List numerator;
  List denominator;
  String backupUnit;

  final String type = 'Unit';

  Unit([List numerator = const [], List denominator = const [], this.backupUnit = null]) {
   this.numerator = numerator.sublist(0)..sort(); //clone
   this.denominator = denominator.sublist(0)..sort();
  }

  ///
  Unit clone()=> new Unit(this.numerator.sublist(0),
                          this.denominator.sublist(0),
                          this.backupUnit);

  ///
  void genCSS(Contexts env, Output output) {
    if (this.numerator.length >= 1) {
      output.add(this.numerator[0]);
    } else if (this.denominator.length >= 1) {
      output.add(this.denominator[0]);
    } else if ((env == null || !isTrue(env.strictUnits)) && this.backupUnit != null) {
      output.add(this.backupUnit);
    }

  //      genCSS: function (env, output) {
  //          if (this.numerator.length >= 1) {
  //              output.add(this.numerator[0]);
  //          } else
  //          if (this.denominator.length >= 1) {
  //              output.add(this.denominator[0]);
  //          } else
  //          if ((!env || !env.strictUnits) && this.backupUnit) {
  //              output.add(this.backupUnit);
  //          }
  //      },
  }

  //      toCSS: tree.toCSS,

  ///
  String toString() {
    String returnStr = this.numerator.join('*');
    for (int i = 0; i < this.denominator.length; i++) {
      returnStr += '/' + this.denominator[i];
    }
    return returnStr;
  }

  //--- CompareNode

  /// return -1 for different, 0 for equal
  int compare(Node other) => this.isUnit(other.toString()) ? 0 : -1;

  //
  //      compare: function (other) {
  //          return this.is(other.toString()) ? 0 : -1;
  //      },

  ///
  // is in js
  bool isUnit(String unitString) => this.toString() == unitString;

  //
  //      is: function (unitString) {
  //          return this.toString() === unitString;
  //      },

  ///
  bool isLength(Contexts env) {
    RegExp re = new RegExp(r'px|em|%|in|cm|mm|pc|pt|ex');
    String result = this.toCSS(env);
    return re.hasMatch(result);

  //      isLength: function () {
  //          return Boolean(this.toCSS().match(/px|em|%|in|cm|mm|pc|pt|ex/));
  //      },
  }

  ///
  /// True if numerator & denominator isEmpty
  ///
  bool isEmpty() => this.numerator.isEmpty && this.denominator.isEmpty;

  ///
  bool isSingular() => (this.numerator.length <= 1 && this.denominator.length == 0);

  ///
  /// Process numerator and denominator according to [calback] function
  /// String callback(String unit, bool isDenominator)
  /// callback returns new unit
  ///
  void map(Function callback) {
    int i;

    for (i = 0; i < this.numerator.length; i++) {
      this.numerator[i] = callback(this.numerator[i], false);
    }

    for (i = 0; i < this.denominator.length; i++) {
      this.denominator[i] = callback(this.denominator[i], true);
    }
  }

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

        this.map(mapUnit);
      }
    }

    return result;

  //      usedUnits: function() {
  //          var group, result = {}, mapUnit;
  //
  //          mapUnit = function (atomicUnit) {
  //          /*jshint loopfunc:true */
  //              if (group.hasOwnProperty(atomicUnit) && !result[groupName]) {
  //                  result[groupName] = atomicUnit;
  //              }
  //
  //              return atomicUnit;
  //          };
  //
  //          for (var groupName in tree.UnitConversions) {
  //              if (tree.UnitConversions.hasOwnProperty(groupName)) {
  //                  group = tree.UnitConversions[groupName];
  //
  //                  this.map(mapUnit);
  //              }
  //          }
  //
  //          return result;
  //      },
  }

  ///
  /// Normalize numerator and denominator after operations
  ///
  void cancel() {
    Map<String, int> counter = {};
    String atomicUnit;
    int i;
    String backup;

    for (i = 0; i < this.numerator.length; i++) {
      atomicUnit = this.numerator[i];
      if (backup == null) backup = atomicUnit;
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] + 1;
    }

    for (i = 0; i < this.denominator.length; i++) {
      atomicUnit = this.denominator[i];
      if (backup == null) backup = atomicUnit;
      if (!counter.containsKey(atomicUnit)) counter[atomicUnit] = 0;
      counter[atomicUnit] = counter[atomicUnit] -1;
    }

    this.numerator = [];
    this.denominator = [];

    for (atomicUnit in counter.keys) {
      if (counter.containsKey(atomicUnit)) {
        int count = counter[atomicUnit];
        if (count > 0) {
          for (i = 0; i < count; i++) this.numerator.add(atomicUnit);
        } else if (count < 0) {
          for (i = 0; i < -count; i++) this.denominator.add(atomicUnit);
        }
      }
    }

    if (this.numerator.isEmpty && this.denominator.isEmpty && backup != null) {
      this.backupUnit = backup;
    }

    this.numerator.sort();
    this.denominator.sort();

  //      cancel: function () {
  //          var counter = {}, atomicUnit, i, backup;
  //
  //          for (i = 0; i < this.numerator.length; i++) {
  //              atomicUnit = this.numerator[i];
  //              if (!backup) {
  //                  backup = atomicUnit;
  //              }
  //              counter[atomicUnit] = (counter[atomicUnit] || 0) + 1;
  //          }
  //
  //          for (i = 0; i < this.denominator.length; i++) {
  //              atomicUnit = this.denominator[i];
  //              if (!backup) {
  //                  backup = atomicUnit;
  //              }
  //              counter[atomicUnit] = (counter[atomicUnit] || 0) - 1;
  //          }
  //
  //          this.numerator = [];
  //          this.denominator = [];
  //
  //          for (atomicUnit in counter) {
  //              if (counter.hasOwnProperty(atomicUnit)) {
  //                  var count = counter[atomicUnit];
  //
  //                  if (count > 0) {
  //                      for (i = 0; i < count; i++) {
  //                          this.numerator.push(atomicUnit);
  //                      }
  //                  } else if (count < 0) {
  //                      for (i = 0; i < -count; i++) {
  //                          this.denominator.push(atomicUnit);
  //                      }
  //                  }
  //              }
  //          }
  //
  //          if (this.numerator.length === 0 && this.denominator.length === 0 && backup) {
  //              this.backupUnit = backup;
  //          }
  //
  //          this.numerator.sort();
  //          this.denominator.sort();
  //      }
  //  };
  }
}