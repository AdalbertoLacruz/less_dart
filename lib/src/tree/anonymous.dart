//source: less/tree/anonymous.js 2.5.0

part of tree.less;

class Anonymous extends Node implements CompareNode {
  int index;
  bool mapLines;
  bool rulesetLike;

  String type = 'Anonymous';

  Anonymous(value, [int this.index, FileInfo currentFileInfo,
           this.mapLines = false, bool this.rulesetLike = false]){
    this.value = value;
    this.currentFileInfo = currentFileInfo;
  }

  ///
  Node eval(context) => new Anonymous(value, index, currentFileInfo, mapLines, rulesetLike);

//2.3.1
//  Anonymous.prototype.eval = function () {
//      return new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike);
//  };

//--- CompareNode

  ///
  int compare(Node other) {
    return this.toCSS(null).compareTo(other.toCSS(null));

//2.3.1
//  Anonymous.prototype.compare = function (other) {
//      return other.toCSS && this.toCSS() === other.toCSS() ? 0 : undefined;
//  };
  }

  ///
  bool isRulesetLike() => rulesetLike;

  ///
  void genCSS(Contexts context, Output output) {
    output.add(value, currentFileInfo, index, mapLines);

//2.3.1
//  Anonymous.prototype.genCSS = function (context, output) {
//      output.add(this.value, this.currentFileInfo, this.index, this.mapLines);
//  };
  }

  @override
  String get name => null;
}