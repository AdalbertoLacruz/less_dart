//source: less/tree/keyword.js 2.5.0

part of tree.less;

///
class Keyword extends Node {
  @override final String      type = 'Keyword';
  @override covariant String  value;

  ///
  Keyword(this.value);

  ///
  // ignore: non_constant_identifier_names
  Keyword.True() {
    value = 'true';
  }

  ///
  // ignore: non_constant_identifier_names
  Keyword.False() {
    value = 'false';
  }

  /// Fields to show with genTree
  @override Map<String, dynamic> get treeField => <String, dynamic>{'value': value};

  ///
  @override
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

  @override
  String toString() => value;
}
