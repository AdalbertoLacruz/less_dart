//source: less/tree/keyword.js 1.7.5

part of tree.less;

class Keyword extends Node implements CompareNode, EvalNode, ToCSSNode {
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
  Keyword eval(Env env) => this;

  ///
  void genCSS(Env env, Output output) {
    if (this.value == '%') {
      throw new LessExceptionError(new LessError(
          type: 'Syntax',
          message: 'Invalid % without number'));
    }
    output.add(this.value);
  }

//    toCSS: tree.toCSS,


//--- CompareNode

  /// Returns -1, 0 or +1
  int compare(Node other) {
    if (other is Keyword) {
      return (other.value == this.value) ? 0 : 1;
    } else {
      return -1;
    }
  }
}