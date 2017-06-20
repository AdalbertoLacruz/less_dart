//source: less/tree/unicode-descriptor.js 2.5.0

part of tree.less;

///
class UnicodeDescriptor extends Node {
  @override final String      type = 'UnicodeDescriptor';
  @override covariant String  value;

  ///
  UnicodeDescriptor(String this.value);
}
