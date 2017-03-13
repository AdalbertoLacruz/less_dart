// source: lib/less/functions/default.js 2.5.0

part of functions.less;

class DefaultFunc extends FunctionBase {
  int value_;
  LessError error_;

  @DefineMethod(name: 'default')
  Node eval() {
    int v = value_;
    LessError e = error_;

    if (e != null) throw new LessExceptionError(e);
    if (v != null) return (v > 0) ? new Keyword.True() : new Keyword.False();
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

  void value(int v) {
    value_ = v;
  }

  void error(LessError e) {
    error_ = e;
  }

  void reset() {
    value_ = error_ = null;
  }
}
