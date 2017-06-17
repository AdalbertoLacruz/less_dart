//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node {
  @override final String        name = null;
  @override final String        type = 'Apply';
  @override covariant Anonymous value;

  int index;

  ///
  Apply(Anonymous this.value, this.index, FileInfo currentFileInfo)
      : super.init(currentFileInfo: currentFileInfo);

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('@apply(', currentFileInfo, index);
    value.genCSS(context, output);
    output.add(');');
  }
}
