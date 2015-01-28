//source: less/tree/anonymous.js 1.7.5

part of tree.less;

class Anonymous extends Node implements CompareNode, EvalNode, ToCSSNode {
  var value; //String, Unit, ...
  int index;
  FileInfo currentFileInfo;
  bool mapLines;
  bool rulesetLike;

  String type = 'Anonymous';

  Anonymous(this.value, [int this.index, FileInfo this.currentFileInfo,
           this.mapLines = false, bool this.rulesetLike = false]);

  ///
  Node eval(env) => new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike);


//--- CompareNode

  ///
  int compare(Node x) {
    if (x is! ToCSSNode) return -1;

    String left = this.toCSS(null);
    String right = x.toCSS(null);

    //if (left == right) return 0;
    //return left < right ? -1 : 1;

    return left.compareTo(right);
  }

  ///
  bool isRulesetLike() => this.rulesetLike;

  ///
  void genCSS(Contexts env, Output output) {
    output.add(this.value, this.currentFileInfo, this.index, this.mapLines);
  }

//    toCSS: tree.toCSS

}