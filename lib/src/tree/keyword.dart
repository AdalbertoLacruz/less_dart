//source: less/tree/keyword.js 2.5.0

part of tree.less;

class Keyword extends Node<String> {

  final String type = 'Keyword';

  Keyword(String value){
    this.value = value;
  }

  Keyword.True() {
    this.value = 'true';
  }

  Keyword.False() {
    this.value = 'false';
  }

  ///
  void genCSS(Contexts context, Output output) {
    if (value == '%') {
      throw new LessExceptionError(new LessError(
          type: 'Syntax',
          message: 'Invalid % without number'));
    }
    output.add(value);

//2.3.1
//  Keyword.prototype.genCSS = function (context, output) {
//      if (this.value === '%') { throw { type: "Syntax", message: "Invalid % without number" }; }
//      output.add(this.value);
//  };
  }
}