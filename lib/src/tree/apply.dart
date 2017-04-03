//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node {
  @override String get          name => null;
  @override final String        type = 'Apply';
  @override covariant Anonymous value;

  int       index;

  ///
  Apply(Anonymous this.value, this.index, FileInfo currentFileInfo) {
    this.currentFileInfo = currentFileInfo;
  }

  ///
  @override
  void genCSS(Contexts context, Output output) {
    output.add('@apply(', currentFileInfo, index);
    value.genCSS(context, output);
    output.add(');');
  }
}
