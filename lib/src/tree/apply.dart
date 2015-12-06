//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node {
  Anonymous value;
  int       index;
  FileInfo  currentFileInfo;

  final String type = 'Apply';

  ///
  Apply(this.value, this.index, this.currentFileInfo);

  ///
  void genCSS(Contexts context, Output output) {
    output.add('@apply(', currentFileInfo, index);
    value.genCSS(context, output);
    output.add(');');
  }
}
