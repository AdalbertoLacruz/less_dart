//source: less/tree/anonymous.js 2.5.1 20150725

part of tree.less;

///
class Anonymous
    extends Node
    implements CompareNode, GetIsReferencedNode, MarkReferencedNode {
  @override final String name = null;
  @override String       type = 'Anonymous';

  ///
  int   index;
  ///
  bool  isReferenced;
  ///
  bool  mapLines;
  ///
  bool  rulesetLike;

  ///
  Anonymous(dynamic value,
      {int this.index,
      FileInfo currentFileInfo,
      bool this.mapLines = false,
      bool this.rulesetLike = false,
      bool this.isReferenced = false})
      : super.init(currentFileInfo: currentFileInfo, value: value);

//2.5.1 20150725
//var Anonymous = function (value, index, currentFileInfo, mapLines, rulesetLike, referenced) {
//     this.value = value;
//     this.index = index;
//     this.mapLines = mapLines;
//     this.currentFileInfo = currentFileInfo;
//     this.rulesetLike = (typeof rulesetLike === 'undefined') ? false : rulesetLike;
//     this.isReferenced = referenced || false;
//};

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
      isReferenced: isReferenced);

//2.5.1 20150725
// Anonymous.prototype.eval = function () {
//     return new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike, this.isReferenced);
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

  ///
  @override
  void markReferenced() {
    isReferenced = true;

//2.5.1 20150725
// Anonymous.prototype.markReferenced = function () {
//   this.isReferenced = true;
// };
  }

  ///
  @override
  bool getIsReferenced() => !(currentFileInfo?.reference ?? false) || isReferenced;

//2.5.1 20150725
// Anonymous.prototype.getIsReferenced = function () {
//     return !this.currentFileInfo || !this.currentFileInfo.reference || this.isReferenced;
// };

  @override
  String toString() {
    if (value is String)
        return value;

    final Output output = new Output();
    value.genCSS(null, output);
    return output.toString();
  }
}
