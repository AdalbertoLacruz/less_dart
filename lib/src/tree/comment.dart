//source: less/tree/comment.js 2.5.0

part of tree.less;

class Comment extends Node implements MarkReferencedNode {
  String value;
  bool isLineComment;
  int index;
  FileInfo currentFileInfo;

  bool isReferenced = false;

  final String type ="Comment";

  Comment(String this.value, [bool this.isLineComment = false, int this.index, FileInfo this.currentFileInfo]);

  ///
  /// Writes the comment in [output].
  ///
  genCSS(Contexts context, Output output) {
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
  void markReferenced() {
    isReferenced = true;
  }
}
