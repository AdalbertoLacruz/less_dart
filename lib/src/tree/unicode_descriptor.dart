//source: less/tree/unicode-descriptor.js 2.5.0

part of tree.less;

class UnicodeDescriptor extends Node {
  String value;

  final String type = 'UnicodeDescriptor';

  UnicodeDescriptor(String this.value);
}