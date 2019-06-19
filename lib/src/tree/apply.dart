//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node {
  @override final String        name = null;
  @override final String        type = 'Apply';
  @override covariant Anonymous value;

  ///
  Apply(this.value, int index, FileInfo currentFileInfo)
      : super.init(currentFileInfo: currentFileInfo, index: index) {
        allowRoot = true;
      }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{
    'value': value
  };

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('@apply(', fileInfo: currentFileInfo, index: index);
    value.genCSS(context, output);
    output.add(');');
  }

  @override
  String toString() {
    final Output output = new Output();
    genCSS(null, output);
    return output.toString();
  }
}
