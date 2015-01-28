//source: less/tree/unicode-descriptor.js 1.7.5

part of tree.less;

class UnicodeDescriptor extends Node implements EvalNode, ToCSSNode {
  String value;

  final String type = 'UnicodeDescriptor';

  UnicodeDescriptor(String this.value);

  UnicodeDescriptor eval(Contexts env) => this;

  void genCSS(Contexts env, Output output) {
    output.add(this.value);
  }

//    toCSS: tree.toCSS,
}