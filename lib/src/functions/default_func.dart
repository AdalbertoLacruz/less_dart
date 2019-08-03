// source: lib/less/functions/default.js 2.5.0

part of functions.less;

///
class DefaultFunc extends FunctionBase {
  LessError _error;

  int _value;

  ///
  @DefineMethod(name: 'default')
  Node eval() {
    final int v = _value;
    final LessError e = _error;

    if (e != null) {
      throw LessExceptionError(e);
    }
    if (v != null) {
      return (v > 0) ? Keyword.True() : Keyword.False();
    }
    return null;

//    eval: function () {
//        var v = this.value_, e = this.error_;
//        if (e) {
//            throw e;
//        }
//        if (v != null) {
//            return v ? Keyword.True : Keyword.False;
//        }
//    }
  }

  ///
  void value(int v) {
    _value = v;
  }

  ///
  void error(LessError e) {
    _error = e;
  }

  ///
  void reset() {
    _value = _error = null;
  }
}
