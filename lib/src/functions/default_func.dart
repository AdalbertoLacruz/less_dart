// source: lib/less/functions/default.js 2.4.0

part of functions.less;

class DefaultFunc extends FunctionBase {
  var value_;
  var error_;

  @defineMethod(name: 'default')
  Node eval() {
    var v = this.value_;
    LessError e = this.error_;

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

  void value(v) {
    this.value_ = v;
  }

  void error(LessError e) {
    this.error_ = e;
  }

  void reset() {
    this.value_ = this.error_ = null;
  }
}