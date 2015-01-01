//source: less/tree/comment.js 1.7.5

part of tree.less;

class Comment extends Node implements EvalNode, MarkReferencedNode, ToCSSNode {
  String value;
  bool silent;
  int index;
  FileInfo currentFileInfo;

  bool isReferenced = false;

  final String type ="Comment";

  Comment(String this.value, [bool this.silent = false, int this.index, FileInfo this.currentFileInfo]);

  /// Writes the comment in [output]. #
  genCSS(Env env, Output output) {
    if (this.debugInfo != null) {
      output.addFull(debugInfo.toOutput(env), this.currentFileInfo, this.index);
    }
    output.add(this.value.trim()); //TODO (orig) shouldn't need to trim, we shouldn't grab the \n

//        if (this.debugInfo) {
//            output.add(tree.debugInfo(env, this), this.currentFileInfo, this.index);
//        }
//        output.add(this.value.trim()); //TODO shouldn't need to trim, we shouldn't grab the \n
  }

//   toCSS: tree.toCSS

  ///
  bool isSilent(Env env) {
    bool isReference = this.currentFileInfo != null
        && this.currentFileInfo.reference
        && !this.isReferenced;
    RegExp re = new RegExp(r'^\/\*!');
    bool isCompressed = env.compress && !re.hasMatch(this.value);
    return this.silent || isReference || isCompressed;

//        var isReference = (this.currentFileInfo && this.currentFileInfo.reference && !this.isReferenced),
//            isCompressed = env.compress && !this.value.match(/^\/\*!/);
//        return this.silent || isReference || isCompressed;
  }

  Node eval(env) => this;

  //--- MarkReferencedNode

  ///
  void markReferenced() {
    this.isReferenced = true;
  }
}