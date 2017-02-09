//Not in original

part of tree.less;

///
/// @apply(--mixin-name); directive
///
class Apply extends Node<Anonymous> {
  int       index;

  final String type = 'Apply';

  ///
  Apply(Anonymous value, this.index,FileInfo currentFileInfo){
    this.value = value;
    this.currentFileInfo = currentFileInfo;
  }

  ///
  void genCSS(Contexts context, Output output) {
    output.add('@apply(', currentFileInfo, index);
    value.genCSS(context, output);
    output.add(');');
  }
  // TODO: implement name
  @override
  String get name => null;
}
