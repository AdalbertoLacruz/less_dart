//source: less/tree/comment.js 2.5.0

part of tree.less;

class Comment extends Node implements MarkReferencedNode {
  @override String get        name => null;
  @override final String      type ="Comment";
  @override covariant String  value;

  int   index;
  bool  isLineComment;
  bool  isReferenced = false;

  ///
  Comment(String value, [bool this.isLineComment = false, int this.index, FileInfo currentFileInfo]){
    this.value = value;
    this.currentFileInfo = currentFileInfo;
  }

  ///
  /// Writes the comment in [output].
  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (debugInfo != null) {
      output.add(debugInfo.toOutput(context), currentFileInfo, index);
    }
    output.add(value);

//2.2.0
//    Comment.prototype.genCSS = function (context, output) {
//        if (this.debugInfo) {
//            output.add(getDebugInfo(context, this), this.currentFileInfo, this.index);
//        }
//        output.add(this.value);
//    };
  }

  ///
  bool get isImportant => (value.length > 2) && (value.startsWith('/*!'));

  ///
  bool isSilent(Contexts context) {
    bool isReference = currentFileInfo != null
        && currentFileInfo.reference
        && !isReferenced;

    bool isCompressed = context.compress && (value.length > 2)&& (value[2] != '!');
    return isLineComment || isReference || isCompressed;

//2.2.0
//    Comment.prototype.isSilent = function(context) {
//        var isReference = (this.currentFileInfo && this.currentFileInfo.reference && !this.isReferenced),
//            isCompressed = context.compress && this.value[2] !== "!";
//        return this.isLineComment || isReference || isCompressed;
//    };

  }

  //--- MarkReferencedNode

  ///
  @override
  void markReferenced() {
    isReferenced = true;
  }
}
