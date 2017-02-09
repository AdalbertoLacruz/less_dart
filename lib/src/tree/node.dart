//source: less/tree/node.js 2.5.0

part of tree.less;

abstract class Node<T> {

  List<Extend> allExtends; //Ruleset
  DebugInfo debugInfo;
  var elements;
  bool evalFirst = false; //see Ruleset.eval

  /// hashCode own or inherited for object compare
  int id;

  CleanCssContext cleanCss; // Info to optimize the node with cleanCss

  FileInfo currentFileInfo;
  bool isRuleset = false; //true in MixinDefinition & Ruleset
  dynamic get name;
  var operands;
  Node originalRuleset; //see mixin_call
  bool parens = false; //Expression
  bool parensInOp = false; //See parsers.operand & Expression
  var rules; //Ruleset
  var selectors;
  String get type;
  T value;

  ///
  Node() {
    id = hashCode;
  }

  /// Directive overrides it
  bool isCharset() => false;

  ///
  bool isRulesetLike() => false;

  ///
  throwAwayComments() { return null; }

  ///
  /// Returns node transformed to css code
  ///
  String toCSS(Contexts context) {
     Output output = new Output();
     genCSS(context, output);
     //if (context != null) context.avoidDartOptimization = true; //avoid dart context prune
     return output.toString();

//2.3.1
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
  void genCSS(Contexts context, Output output){
    output.add(value);

///2.3.1
//  Node.prototype.genCSS = function (context, output) {
//      output.add(this.value);
//  };
  }

  ///
  accept(VisitorBase visitor) {
    value = visitor.visit(value);

//2.3.1
//  Node.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
    }

  ///
  /// Default eval - returns the node
  ///
  eval(Contexts context) => this;

//2.3.1
//  Node.prototype.eval = function () { return this; };

  ///
  num _operate(Contexts context, String op, num a, num b) {
    switch (op) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;
        case '/': return a / b;
    }
    return null;

//2.3.1
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
  /// [precision] to forze
  ///
  num fround(Contexts context, num value, [int precision]) {
  if (value is int) return value;

  //precision
  //int precision = (context != null) ? getValueOrDefault(context.numPrecision, 8) : null;
  //int precision = (context != null) ? context.numPrecision : null;
  if (precision == null || precision == -1) {
    precision = null;
    precision = (context != null) ? context.numPrecision : null;
  }

  // add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
  double result = value + 2e-16;
  return (precision == null) ? value : double.parse(result.toStringAsFixed(precision));

//2.3.1
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
  static int compareNodes(Node a, Node b) {
    //new Logger().log('${a.type}: ${a.value} - ${b.type}: ${b.value}');

    // for "symmetric results" force toCSS-based comparison
    // of Quoted or Anonymous if either value is one of those
    if ((a is CompareNode) && !(b is Quoted || b is Anonymous)) {
      return (a as CompareNode).compare(b);
    } else if (b is CompareNode) {
      return negate((b as CompareNode).compare(a)); //-null?
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

///2.3.1
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


  //debug print the node tree
  StringBuffer toTree(LessOptions options) {
    Contexts env = new Contexts.eval(options);
     Output output = new Output();
     genTree(env, output);
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

    if (selectors is List) process.addAll(selectors);
    if (rules is List) process.addAll(rules);
    if (elements is List) process.addAll(elements);
    if (name is List) process.addAll(name);
    if (value is List) process.addAll(value as List);
    if (operands is List) process.addAll(operands);

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