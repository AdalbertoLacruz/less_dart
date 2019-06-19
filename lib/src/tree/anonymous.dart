//source: less/tree/anonymous.js 3.0.0 20160716

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
  Anonymous(dynamic value, {
      int index,
      FileInfo currentFileInfo,
      this.mapLines = false,
      this.rulesetLike = false,
      VisibilityInfo visibilityInfo
      }) : super.init(currentFileInfo: currentFileInfo, index: index,  value: value) {
        allowRoot = true;
        copyVisibilityInfo(visibilityInfo);
      }

//3.0.0 20160714
// var Anonymous = function (value, index, currentFileInfo, mapLines, rulesetLike, visibilityInfo) {
//     this.value = value;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.mapLines = mapLines;
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
      index: _index,
      currentFileInfo: _fileInfo,
      mapLines: mapLines,
      rulesetLike: rulesetLike,
      visibilityInfo: visibilityInfo());

//3.0.0 20160714
// Anonymous.prototype.eval = function () {
//     return new Anonymous(this.value, this._index, this._fileInfo, this.mapLines, this.rulesetLike, this.visibilityInfo());
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
    nodeVisible = (value != null);
    if (nodeVisible) {
      output.add(value, fileInfo: _fileInfo, index: _index, mapLines: mapLines);
    }

//3.0.0 20160716
// Anonymous.prototype.genCSS = function (context, output) {
//     this.nodeVisible = Boolean(this.value);
//     if (this.nodeVisible) {
//         output.add(this.value, this._fileInfo, this._index, this.mapLines);
//     }
// };
  }

  @override
  String toString() {
    if (value is String) return value as String;

    final Output output = new Output();
    value.genCSS(null, output);
    return output.toString();
  }
}
