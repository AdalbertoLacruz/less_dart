//source: less/tree/unicode-descriptor.js 2.5.0

part of tree.less;

class UnicodeDescriptor extends Node<String> {

  final String type = 'UnicodeDescriptor';

  UnicodeDescriptor(String value){
    this.value = value;
  }
}