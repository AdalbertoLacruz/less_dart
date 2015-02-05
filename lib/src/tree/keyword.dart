//source: less/tree/keyword.js 2.3.1

part of tree.less;

class Keyword extends Node implements CompareNode {
  String value;

  final String type = 'Keyword';

  Keyword(String this.value);

  Keyword.True() {
    this.value = 'true';
  }

  Keyword.False() {
    this.value = 'false';
  }

  ///
  //2.3.1 ok
  void genCSS(Contexts context, Output output) {
    if (this.value == '%') {
      throw new LessExceptionError(new LessError(
          type: 'Syntax',
          message: 'Invalid % without number'));
    }
    output.add(this.value);

//2.3.1
//  Keyword.prototype.genCSS = function (context, output) {
//      if (this.value === '%') { throw { type: "Syntax", message: "Invalid % without number" }; }
//      output.add(this.value);
//  };
  }

//    toCSS: tree.toCSS,


//--- CompareNode

  /// Returns -1, 0 or +1
  //2.3.1 - don't remove used by Node.compareNodes
  int compare(Node other) {
    if (other is Keyword) {
      return (other.value == this.value) ? 0 : 1;
    } else {
      return -1;
    }
  }
}