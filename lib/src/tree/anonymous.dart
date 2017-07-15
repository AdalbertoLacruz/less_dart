//source: less/tree/anonymous.js 2.6.1 20160305

part of tree.less;

///
class Anonymous extends Node implements CompareNode {
  @override final String name = null;
  @override String       type = 'Anonymous';

  ///
  bool  mapLines;
  ///
  bool  rulesetLike;

  ///
  Anonymous(dynamic value,
      {int index,
      FileInfo currentFileInfo,
      bool this.mapLines = false,
      bool this.rulesetLike = false,
      VisibilityInfo visibilityInfo})
      : super.init(currentFileInfo: currentFileInfo, index: index,  value: value) {
        allowRoot = true;
        copyVisibilityInfo(visibilityInfo);
      }

//2.6.1 20160305
// var Anonymous = function (value, index, currentFileInfo, mapLines, rulesetLike, visibilityInfo) {
//     this.value = value;
//     this.index = index;
//     this.mapLines = mapLines;
//     this.currentFileInfo = currentFileInfo;
//     this.rulesetLike = (typeof rulesetLike === 'undefined') ? false : rulesetLike;
//     this.allowRoot = true;
//     this.copyVisibilityInfo(visibilityInfo);
// };

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  Node eval(Contexts context) => new Anonymous(value,
      index: index,
      currentFileInfo: currentFileInfo,
      mapLines: mapLines,
      rulesetLike: rulesetLike,
      visibilityInfo: visibilityInfo());

//2.5.3 20151120
// Anonymous.prototype.eval = function () {
//     return new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike, this.visibilityInfo());
// };

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

  @override
  String toString() {
    if (value is String)
        return value;

    final Output output = new Output();
    value.genCSS(null, output);
    return output.toString();
  }
}
