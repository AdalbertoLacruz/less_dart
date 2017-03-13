//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node {
  @override covariant Anonymous value;
  @override String get          name => null;
  @override final String        type = 'Apply';

  int       index;

  ///
  Apply(Anonymous value, this.index,FileInfo currentFileInfo){
    this.value = value;
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
