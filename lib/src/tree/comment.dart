//source: less/tree/comment.js 3.0.0 20160714

part of tree.less;

///
class Comment extends Node implements SilentNode {
  @override
  final String name = null;

  @override
  final String type = 'Comment';

  @override
  covariant String value;

  ///
  bool isLineComment;

  ///
  Comment(this.value,
      {this.isLineComment = false, int index, FileInfo currentFileInfo})
      : super.init(currentFileInfo: currentFileInfo, index: index) {
    allowRoot = true;
  }

//3.0.0 20160714
// var Comment = function (value, isLineComment, index, currentFileInfo) {
//     this.value = value;
//     this.isLineComment = isLineComment;
//     this._index = index;
//     this._fileInfo = currentFileInfo;
//     this.allowRoot = true;
// };

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField => <String, dynamic>{'value': value};

  ///
  /// Writes the comment in [output].
  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (debugInfo != null) {
      output.add(debugInfo.toOutput(context),
          fileInfo: currentFileInfo, index: index);
    }
    output.add(value);

//3.0.0 20160714
// Comment.prototype.genCSS = function (context, output) {
//     if (this.debugInfo) {
//         output.add(getDebugInfo(context, this), this.fileInfo(), this.getIndex());
//     }
//     output.add(this.value);
// };
  }

  ///
  bool get isImportant => (value.length > 2) && (value.startsWith('/*!'));

  ///
  @override
  bool isSilent(Contexts context) {
    final isCompressed =
        context.compress && (value.length > 2) && (value[2] != '!');
    return isLineComment || isCompressed;

//2.5.3 20151120
// Comment.prototype.isSilent = function(context) {
//     var isCompressed = context.compress && this.value[2] !== "!";
//     return this.isLineComment || isCompressed;
// };
  }

  @override
  String toString() => value;
}
