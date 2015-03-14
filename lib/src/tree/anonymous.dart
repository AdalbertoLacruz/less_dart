//source: less/tree/anonymous.js 2.4.0

part of tree.less;

class Anonymous extends Node implements CompareNode {
  var value; //String, Unit, ...
  int index;
  FileInfo currentFileInfo;
  bool mapLines;
  bool rulesetLike;

  String type = 'Anonymous';

  Anonymous(this.value, [int this.index, FileInfo this.currentFileInfo,
           this.mapLines = false, bool this.rulesetLike = false]);

  ///
  //2.3.1 ok
  Node eval(env) => new Anonymous(this.value, this.index,
      this.currentFileInfo, this.mapLines, this.rulesetLike);

///2.3.1
//  Anonymous.prototype.eval = function () {
//      return new Anonymous(this.value, this.index, this.currentFileInfo, this.mapLines, this.rulesetLike);
//  };

//--- CompareNode

  ///
  //2.3.1 ok
  int compare(Node other) {
    return this.toCSS(null).compareTo(other.toCSS(null));

//2.3.1
//  Anonymous.prototype.compare = function (other) {
//      return other.toCSS && this.toCSS() === other.toCSS() ? 0 : undefined;
//  };
  }

  ///
  //2.3.1 ok
  bool isRulesetLike(bool root) => this.rulesetLike;

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    output.add(this.value, this.currentFileInfo, this.index, this.mapLines);

//2.3.1
//  Anonymous.prototype.genCSS = function (context, output) {
//      output.add(this.value, this.currentFileInfo, this.index, this.mapLines);
//  };
  }
}