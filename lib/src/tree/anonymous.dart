//source: less/tree/anonymous.js 2.5.0

part of tree.less;

///
class Anonymous extends Node implements CompareNode {
  @override final String name = null;
  @override String       type = 'Anonymous';

  ///
  int   index;
  ///
  bool  mapLines;
  ///
  bool  rulesetLike;

  ///
  Anonymous(dynamic value,
      {int this.index,
      FileInfo currentFileInfo,
      bool this.mapLines = false,
      bool this.rulesetLike = false})
      : super.init(currentFileInfo: currentFileInfo, value: value);

  ///
  @override
  Node eval(Contexts context) => new Anonymous(value,
      index: index,
      currentFileInfo: currentFileInfo,
      mapLines: mapLines,
      rulesetLike: rulesetLike);

//2.3.1
//  Anonymous.prototype.eval = function () {
//      return new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike);
//  };

//--- CompareNode

  ///
  @override
  int compare(Node other) => toCSS(null).compareTo(other.toCSS(null));

//2.3.1
//  Anonymous.prototype.compare = function (other) {
//      return other.toCSS && this.toCSS() === other.toCSS() ? 0 : undefined;
//  };

  ///
  @override
  bool isRulesetLike() => rulesetLike;

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add(value, fileInfo: currentFileInfo, index: index, mapLines: mapLines);

//2.3.1
//  Anonymous.prototype.genCSS = function (context, output) {
//      output.add(this.value, this.currentFileInfo, this.index, this.mapLines);
//  };
  }
}
