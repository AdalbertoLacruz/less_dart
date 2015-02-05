//source: less/tree/js-eval-node.dart 2.3.1

part of tree.less;

class JsEvalNodeMixin {
  FileInfo currentFileInfo;
  int index;

  ///
  /// JavaScript evaluation - not supported
  //2.3.1
  String evaluateJavaScript(String expression, Contexts context) {
    String result;
    JsEvalNodeMixin that = this;
    Map evalContext = {};

    if (!isTrue(context.javascriptEnabled)) {
      throw new LessExceptionError(new LessError(
                message: 'You are using JavaScript, which has been disabled.',
                index: this.index,
                filename: this.currentFileInfo.filename));
    }

    expression = expression.replaceAllMapped(new RegExp(r'@\{([\w-]+)\}'), (Match m) {
      return that.jsify(new Variable('@' + m[1], that.index, that.currentFileInfo).eval(context));
    });

    try {
      // expression = new Function('return (' + expression + ')');
    } catch (e) {
        // throw { message: "JavaScript evaluation error: " + e.message + " from `" + expression + "`" ,
             //filename: this.currentFileInfo.filename,
             //index:
    }
//      var variables = context.frames[0].variables();
//      for (var k in variables) {
//          if (variables.hasOwnProperty(k)) {
//              /*jshint loopfunc:true */
//              evalContext[k.slice(1)] = {
//                  value: variables[k].value,
//                  toJS: function () {
//                      return this.value.eval(context).toCSS();
//                  }
//              };
//          }
//      }
//
//      try {
//          result = expression.call(evalContext);
//      } catch (e) {
//          throw { message: "JavaScript evaluation error: '" + e.name + ': ' + e.message.replace(/["]/g, "'") + "'" ,
//              filename: this.currentFileInfo.filename,
//              index: this.index };
//      }

    result = expression;
    return result;


//2.3.1
//  JsEvalNode.prototype.evaluateJavaScript = function (expression, context) {
//      var result,
//          that = this,
//          evalContext = {};
//
//      if (context.javascriptEnabled !== undefined && !context.javascriptEnabled) {
//          throw { message: "You are using JavaScript, which has been disabled.",
//              filename: this.currentFileInfo.filename,
//              index: this.index };
//      }
//
//      expression = expression.replace(/@\{([\w-]+)\}/g, function (_, name) {
//          return that.jsify(new Variable('@' + name, that.index, that.currentFileInfo).eval(context));
//      });
//
//      try {
//          expression = new Function('return (' + expression + ')');
//      } catch (e) {
//          throw { message: "JavaScript evaluation error: " + e.message + " from `" + expression + "`" ,
//              filename: this.currentFileInfo.filename,
//              index: this.index };
//      }
//
//      var variables = context.frames[0].variables();
//      for (var k in variables) {
//          if (variables.hasOwnProperty(k)) {
//              /*jshint loopfunc:true */
//              evalContext[k.slice(1)] = {
//                  value: variables[k].value,
//                  toJS: function () {
//                      return this.value.eval(context).toCSS();
//                  }
//              };
//          }
//      }
//
//      try {
//          result = expression.call(evalContext);
//      } catch (e) {
//          throw { message: "JavaScript evaluation error: '" + e.name + ': ' + e.message.replace(/["]/g, "'") + "'" ,
//              filename: this.currentFileInfo.filename,
//              index: this.index };
//      }
//      return result;
//  };
  }

  ///
  //2.3.1
  String jsify(Node obj) {
    if (obj.value is List && obj.value.length > 1) {
      List result = (obj.value as List).map((Node v) => v.toCSS(null)).toList();
      return '[' + result.join(', ') + ']';
    } else {
      return obj.toCSS(null);
    }

//2.3.1
//  JsEvalNode.prototype.jsify = function (obj) {
//      if (Array.isArray(obj.value) && (obj.value.length > 1)) {
//          return '[' + obj.value.map(function (v) { return v.toCSS(); }).join(', ') + ']';
//      } else {
//          return obj.toCSS();
//      }
//  };
  }
}