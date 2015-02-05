//source: less/tree/unicode-descriptor.js 2.3.1

part of tree.less;

class UnicodeDescriptor extends Node {
  String value;

  final String type = 'UnicodeDescriptor';

  UnicodeDescriptor(String this.value);

  ///
  //2.3.1 TODO remove
  UnicodeDescriptor eval(Contexts env) => this;

  ///
  //2.3.1 TODO remove
  void genCSS(Contexts env, Output output) {
    output.add(this.value);
  }
}