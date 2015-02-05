//source: less/tree/node.js 2.2.0

// TODO review properties/methods to eliminate
part of tree.less;

class Node {
  /// hashCode own or inherited for object compare
  int id;

  String type;
  var value;
  var name;

  bool allowImports;
  bool evaldCondition; //See selector
  bool evalFirst = false; //see Ruleset
  bool isRuleset = false;
  bool isRulesetLike(bool root) => false;
  bool parensInOp = false; //See parsers.operand
  bool parens = false; //Expression

  Node originalRuleset; //TODO remove. used in mixin_call

  DebugInfo debugInfo;
  var rules; //Ruleset
  var elements;
  var selectors;
  List<Extend> allExtends; //Ruleset
  var operands;

  /// Directive overrides it
  bool isCharset() => false;

  Node() {
    id = hashCode;
  }


  ///
  /// Returns node transformed to css code
  ///
  //2.2.0 ok
  String toCSS(Contexts context) {
     Output output = new Output();
     this.genCSS(context, output);
     //if (context != null) context.avoidDartOptimization = true; //avoid dart context prune
     return output.toString();

//2.2.0
//   Node.prototype.toCSS = function (context) {
//       var strs = [];
//       this.genCSS(context, {
//           add: function(chunk, fileInfo, index) {
//               strs.push(chunk);
//           },
//           isEmpty: function () {
//               return strs.length === 0;
//           }
//       });
//       return strs.join('');
//   };
   }

  ///
  /// Writes in [output] the node transformed to CSS.
  ///
  //2.2.0 ok
  void genCSS(Contexts context, Output output){
    output.add(this.value);

///2.2.0
//  Node.prototype.genCSS = function (context, output) {
//      output.add(this.value);
//  };
  }

  ///
  //2.2.0 ok
  accept(VisitorBase visitor) {
    this.value = visitor.visit(this.value);

//2.2.0
//  Node.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
    }

  ///
  /// Default eval - returns the node
  ///
  //2.2.0 ok
  eval(Contexts env) => this;

//2.2.0
//  Node.prototype.eval = function () { return this; };

  ///
  //Original out of class (operate) - Operate.operateExec TODO change to this
  //2.2.0 ok
  num _operate(Contexts context, String op, num a, num b) {
    switch (op) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;
        case '/': return a / b;
    }
    return null;

//2.2.0
//  Node.prototype._operate = function (context, op, a, b) {
//      switch (op) {
//          case '+': return a + b;
//          case '-': return a - b;
//          case '*': return a * b;
//          case '/': return a / b;
//      }
//  };
  }


  ///
  /// Adjust the precision of [value] according to [context].numPrecision.
  /// 8 By default.
  ///
  //2.2.0 ok
  num fround(Contexts context, num value) {
  if (value is int) return value;

  //precision
  //int precision = (context != null) ? getValueOrDefault(context.numPrecision, 8) : null;
  int precision = (context != null) ? context.numPrecision : null;

  // add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
  double result = value + 2e-16;
  return (precision == null) ? value : double.parse(result.toStringAsFixed(precision));

//2.2.0
//  Node.prototype.fround = function(context, value) {
//      var precision = context && context.numPrecision;
//      //add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
//      return (precision == null) ? value : Number((value + 2e-16).toFixed(precision));
//  };
}

  ///
  /// Compares two nodes [a] and [b]
  ///
  /// Returns:
  ///   -1: a < b
  ///   0: a = b
  ///   1: a > b
  ///   and null  for other value for a != b
  ///
  // 2.2.0 ok
  static int compareNodes(Node a, Node b) {
    // for "symmetric results" force toCSS-based comparison
    // of Quoted or Anonymous if either value is one of those
    if ((a is CompareNode) && !(b is Quoted || b is Anonymous)) {
      return (a as CompareNode).compare(b);
    } else if (b is CompareNode) {
      return -(b as CompareNode).compare(a);
    } else if (a.runtimeType != b.runtimeType) {
      return null;
    }

    var aValue = a.value;
    var bValue = b.value;

    if (aValue is! List) return (aValue == bValue) ? 0 : null;
    if (aValue is List && bValue is List) {
      if (aValue.length != bValue.length) return null;
      for (int i = 0; i < aValue.length; i++) {
        if (Node.compareNodes(aValue[i], bValue[i]) != 0) return null;
      }
    }
    return 0;

///2.2.0
//  Node.compare = function (a, b) {
//      /* returns:
//       -1: a < b
//       0: a = b
//       1: a > b
//       and *any* other value for a != b (e.g. undefined, NaN, -2 etc.) */
//
//      if ((a.compare) &&
//          // for "symmetric results" force toCSS-based comparison
//          // of Quoted or Anonymous if either value is one of those
//          !(b.type === "Quoted" || b.type === "Anonymous")) {
//          return a.compare(b);
//      } else if (b.compare) {
//          return -b.compare(a);
//      } else if (a.type !== b.type) {
//          return undefined;
//      }
//
//      a = a.value;
//      b = b.value;
//      if (!Array.isArray(a)) {
//          return a === b ? 0 : undefined;
//      }
//      if (a.length !== b.length) {
//          return undefined;
//      }
//      for (var i = 0; i < a.length; i++) {
//          if (Node.compare(a[i], b[i]) !== 0) {
//              return undefined;
//          }
//      }
//      return 0;
//  };
  }

  ///
  //2.2.0 ok
  static int numericCompare(num a, num b) {
    return a.compareTo(b);

//    return (a < b)
//        ? - 1
//        : (a == b
//          ? 0
//          : (a > b ? 1 : null));

//2.2.0 ok
//  Node.numericCompare = function (a, b) {
//      return a  <  b ? -1
//          : a === b ?  0
//          : a  >  b ?  1 : undefined;
//  };
  }

  evalImports(Contexts env){}

  throwAwayComments() { return null; }

  //debug print the node tree
  StringBuffer toTree(LessOptions options) {
    Contexts env = new Contexts.eval(options);
     Output output = new Output();
     this.genTree(env, output);
     return output.value;
  }

  void genTree(Contexts env, Output output) {
    int i;
    Node rule;
    String tabStr = '  ' * env.tabLevel;
    List process = [];


    String nameNode = name is String ? name : null;
    if (nameNode == null) nameNode = value is String ? value : '';
    nameNode = nameNode.replaceAll('\n', '');

    output.add('${tabStr}$type ($nameNode)\n');
    env.tabLevel++;

    if (this.selectors is List) process.addAll(this.selectors);
    if (this.rules is List) process.addAll(this.rules);
    if (this.elements is List) process.addAll(this.elements);
    if (this.name is List) process.addAll(this.name);
    if (this.value is List) process.addAll(this.value);
    if (this.operands is List) process.addAll(this.operands);

    if (process.isNotEmpty) {
      for (i = 0; i < process.length; i++) {
        process[i].genTree(env, output);
      }
    }
    if(value is Node) {
      (value as Node).genTree(env, output);
    }
    env.tabLevel--;
  }
}

//-----------------------------------------------------------

abstract class CompareNode {
  /// Returns -1, 0 or +1
  int compare(Node x);
}
abstract class EvalNode {
  eval(Contexts context);
}
abstract class GetIsReferencedNode {
  getIsReferenced();
}
abstract class MakeImportantNode {
  Node makeImportant();
}

abstract class MarkReferencedNode {
  void markReferenced();
}

abstract class MatchConditionNode {
  List<Node> rules;
  bool matchCondition(List<MixinArgs> args, Contexts context);
  bool matchArgs(List<MixinArgs> args, Contexts context);
}

abstract class OperateNode {
  Node operate(Contexts context, String op, Node other);
}

abstract class ToCSSNode {
  void genCSS(Contexts context, Output output);
  String toCSS(Contexts context);
}

//---------------------------- OutputRulesetMixin -----------------------

// tree.js lines 65-95 for Directive & Media
// tree/directive.js 2.3.1 lines 92-122

///
//2.3.1 ok
class OutputRulesetMixin {
  void outputRuleset(Contexts context, Output output, List<Node> rules) {
    int ruleCnt = rules.length;

    if (context.tabLevel == null) context.tabLevel = 0;
    context.tabLevel++;

    // Compressed
    if (context.compress) {
      output.add('{');
      for (int i = 0; i < ruleCnt; i++) rules[i].genCSS(context, output);
      output.add('}');
      context.tabLevel--;
      return;
    }

    // Non-compressed
    String tabSetStr  = '\n' +  '  ' * (context.tabLevel - 1);
    String tabRuleStr = tabSetStr + '  ';
    if (ruleCnt == 0) {
      output.add(' {' + tabSetStr + '}');
    } else {
      output.add(' {' + tabRuleStr);
      rules[0].genCSS(context, output);
      for (int i = 1; i < ruleCnt; i++) {
        output.add(tabRuleStr);
        rules[i].genCSS(context, output);
      }
      output.add(tabSetStr + '}');
    }

    context.tabLevel--;

//2.3.1
//  Directive.prototype.outputRuleset = function (context, output, rules) {
//      var ruleCnt = rules.length, i;
//      context.tabLevel = (context.tabLevel | 0) + 1;
//
//      // Compressed
//      if (context.compress) {
//          output.add('{');
//          for (i = 0; i < ruleCnt; i++) {
//              rules[i].genCSS(context, output);
//          }
//          output.add('}');
//          context.tabLevel--;
//          return;
//      }
//
//      // Non-compressed
//      var tabSetStr = '\n' + Array(context.tabLevel).join("  "), tabRuleStr = tabSetStr + "  ";
//      if (!ruleCnt) {
//          output.add(" {" + tabSetStr + '}');
//      } else {
//          output.add(" {" + tabRuleStr);
//          rules[0].genCSS(context, output);
//          for (i = 1; i < ruleCnt; i++) {
//              output.add(tabRuleStr);
//              rules[i].genCSS(context, output);
//          }
//          output.add(tabSetStr + '}');
//      }
//
//      context.tabLevel--;
//  };
  }
}