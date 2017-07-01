//source: less/tree/node.js 2.5.0

part of tree.less;

///
abstract class Node {
  ///
  List<Extend>        allExtends; //Ruleset
  ///
  CleanCssContext     cleanCss; // Info to optimize the node with cleanCss
  ///
  FileInfo            currentFileInfo;
  ///
  DebugInfo           debugInfo;
  ///
  List<Element>       elements;
  ///
  bool                evalFirst = false; //see Ruleset.eval
  ///
  bool                evaluated; //result from bool eval, used in condition
  ///
  int                 id; // hashCode own or inherited for object compare
  ///
  bool                isRuleset = false; //true in MixinDefinition & Ruleset
  ///
  List<Node>          operands;
  ///
  Node                originalRuleset; //see mixin_call
  ///
  bool                parens = false; //Expression
  ///
  bool                parensInOp = false; //See parsers.operand & Expression
  ///
  @virtual List<Node> rules; //Ruleset
  ///
  List<Selector>      selectors;

  ///
  @virtual dynamic    value;

  ///
  Node() {
    id = hashCode;
  }

  ///
  Node.init({this.currentFileInfo, this.operands, this.rules, this.value}) {
    id = hashCode;
  }

  /// Fields to show with genTree
  Map<String, dynamic> get treeField => null;
  ///
  dynamic get         name => null; //String | List<Node>
  ///
  String get          type;

  /// Directive overrides it
  bool isCharset() => false;

  ///
  bool isRulesetLike() => false;

  ///
  void throwAwayComments() {}

  ///
  /// Returns node transformed to css code
  ///
  String toCSS(Contexts context) {
    final Output output = new Output();
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
  void genCSS(Contexts context, Output output) {
    output.add(value);

//2.3.1
//  Node.prototype.genCSS = function (context, output) {
//      output.add(this.value);
//  };
  }

  ///
  void accept(VisitorBase visitor) {
    value = visitor.visit(value);

//2.3.1
//  Node.prototype.accept = function (visitor) {
//      this.value = visitor.visit(this.value);
//  };
  }

  ///
  /// Default eval - returns the node
  ///
  @virtual
  Node eval(Contexts context) => this;

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
    if (value is int)
        return value;

    final int _precision = (precision == null || precision == -1)
        ? context?.numPrecision
        : precision;

    // add "epsilon" to ensure numbers like 1.000000005 (represented as 1.000000004999....) are properly rounded...
    final double result = value + 2e-16;
    return (_precision == null)
        ? value
        : double.parse(result.toStringAsFixed(_precision));

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
      return negate((b as CompareNode).compare(a)); //-null => null
    } else if (a.runtimeType != b.runtimeType) {
      return null;
    }

    final dynamic aValue = a.value;
    final dynamic bValue = b.value;

    if (aValue is! List)
        return (aValue == bValue) ? 0 : null;
    if (aValue is List && bValue is List) {
      if (aValue.length != bValue.length)
          return null;
      for (int i = 0; i < aValue.length; i++) {
        if (Node.compareNodes(aValue[i], bValue[i]) != 0)
            return null;
      }
    }
    return 0;

//2.3.1
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
  static int numericCompare(num a, num b) => a.compareTo(b);

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

  //debug print the node tree
  ///
  StringBuffer toTree(LessOptions options) {
    final Contexts  env = new Contexts.eval(options);
    final Output    output = new Output();

    genTree(env, output);
    return output.value;
  }

  ///
  void genTree(Contexts env, Output output, [String prefix = '']) {
      genTreeTitle(env, output, prefix, type, toString());

      final int tabs = prefix.isEmpty ? 1 : 2;
      env.tabLevel = env.tabLevel + tabs ;

      if (treeField == null) {
        output.add('***** FIELDS NOT DEFINED in $type *****');
      } else {
        treeField.forEach((String fieldName, dynamic fieldValue){
          genTreeField(env, output, fieldName, fieldValue);
        });
      }

      env.tabLevel = env.tabLevel - tabs;
  }

  ///
  void genTreeTitle(Contexts env, Output output, String prefix, String type, String value) {
    final String tabStr = '  ' * env.tabLevel;
    output.add('$tabStr$prefix$type ($value)\n');
  }

  ///
  void genTreeField(Contexts env, Output output, String fieldName, dynamic fieldValue) {
    final String tabStr = '  ' * env.tabLevel;

    if (fieldValue == null) {

    } else if (fieldValue is String) {
      if (fieldValue.isNotEmpty)
          output.add('$tabStr.$fieldName: String ($fieldValue)\n');
    } else if (fieldValue is num) {
      output.add('$tabStr.$fieldName: num (${fieldValue.toString()})\n');
    } else if (fieldValue is Node) {
      fieldValue.genTree(env, output, '.$fieldName: ');
    } else if (fieldValue is List && fieldValue.isEmpty) {

    } else if (fieldValue is List && fieldValue.isNotEmpty) {
      output.add('$tabStr.$fieldName: \n');
      env.tabLevel++;
      if (fieldValue.first is Node) {
        fieldValue.forEach((Node e) {
          e.genTree(env, output, '- ');
        });
      } else if (fieldValue.first is MixinArgs) {
        fieldValue.forEach((MixinArgs a) {
          a.genTree(env, output, '- ');
        });
      } else if (fieldValue.first is String) {
        final String tabStr = '  ' * env.tabLevel;
        fieldValue.forEach((String s) {
          output.add('$tabStr- String ($s)\n');
        });
      } else if (fieldValue.first is num) {
        final String tabStr = '  ' * env.tabLevel;
        fieldValue.forEach((num n) {
          output.add('$tabStr- num (${n.toString()})\n');
        });
      } else {
        output.add('*** field type not implemented ***');
      }
      env.tabLevel--;
    } else {
      output.add('$tabStr.$fieldName: ***********\n');
    }
  }
}

//-----------------------------------------------------------

///
abstract class CompareNode {
  /// Returns -1, 0 or +1
  int compare(Node x);
}

///
abstract class GetIsReferencedNode {
  ///
  bool getIsReferenced();
}

///
abstract class MakeImportantNode {
  ///
  Node makeImportant();
}

///
abstract class MarkReferencedNode {
  ///
  void markReferenced();
}

///
abstract class MatchConditionNode {
  ///
  List<Node> rules;
  ///
  bool matchCondition(List<MixinArgs> args, Contexts context);
  ///
  bool matchArgs(List<MixinArgs> args, Contexts context);
}

///
abstract class OperateNode<T> {
  //Node operate(Contexts context, String op, Node other);
  ///
  T operate(Contexts context, String op, T other);
}
