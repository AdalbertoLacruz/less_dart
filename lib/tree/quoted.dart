//source: less/tree/quoted.js 1.7.5

part of tree.less;

class Quoted extends Node implements CompareNode, EvalNode, ToCSSNode {
  bool escaped;
  int index;
  FileInfo currentFileInfo;

  String value = '';
  String quote; // ' or "

  final String type = 'Quoted';

  Quoted(String str, String content, bool this.escaped, [int this.index, FileInfo this.currentFileInfo]){
    if(content != null) value = content;
    quote = str.isNotEmpty ? str[0] : '';
  }

  ///
  void genCSS(Env env, Output output) {
    if (!isTrue(this.escaped)) {
      output.addFull(this.quote, this.currentFileInfo, this.index);
    }
    output.add(this.value);
    if (!isTrue(this.escaped)) {
      output.add(this.quote);
    }
  }

//    toCSS: tree.toCSS

  Node eval(Env env){
    Quoted that = this;
    RegExp rExp = new RegExp(r'`([^`]+)`'); //javascript expresion
    RegExp rName = new RegExp(r'@\{([\w-]+)\}');

    //TODO js evaluation
    //var value = this.value.replace(/`([^`]+)`/g, function (_, exp) {
    //            return new(tree.JavaScript)(exp, that.index, true).eval(env).value;
    //        });

    //@f: 'ables';
    //@import 'vari@{f}.less';
    //result = @import 'variables.less';
    var value = this.value.replaceAllMapped(rName, (Match m){
      String name = m[1];
      Node v = new Variable('@' + name, that.index, that.currentFileInfo).eval(env);
      return (v is Quoted) ? v.value : v.toCSS(null);
    });

    return new Quoted(this.quote + value + this.quote, value, this.escaped, this.index, this.currentFileInfo);

//    eval: function (env) {
//        var that = this;
//        var value = this.value.replace(/`([^`]+)`/g, function (_, exp) {
//            return new(tree.JavaScript)(exp, that.index, true).eval(env).value;
//        }).replace(/@\{([\w-]+)\}/g, function (_, name) {
//            var v = new(tree.Variable)('@' + name, that.index, that.currentFileInfo).eval(env, true);
//            return (v instanceof tree.Quoted) ? v.value : v.toCSS();
//        });
//        return new(tree.Quoted)(this.quote + value + this.quote, value, this.escaped, this.index, this.currentFileInfo);
//    },
  }


//--- CompareNode

  /// Returns -1, 0 or +1
  int compare(Node x) {
    if (x is! ToCSSNode) return -1;

    String left;
    String right;

    // when comparing quoted strings allow the quote to differ
    if (x is Quoted && !this.escaped && !x.escaped) {
      left  = x.value;
      right = this.value;
    } else {
      left = this.toCSS(null);
      right = x.toCSS(null);
    }

    return left.compareTo(right);

//    compare: function (x) {
//        if (!x.toCSS) {
//            return -1;
//        }
//
//        var left, right;
//
//        // when comparing quoted strings allow the quote to differ
//        if (x.type === "Quoted" && !this.escaped && !x.escaped) {
//            left = x.value;
//            right = this.value;
//        } else {
//            left = this.toCSS();
//            right = x.toCSS();
//        }
//
//        if (left === right) {
//            return 0;
//        }
//
//        return left < right ? -1 : 1;
//    }
  }
}