//source: less/tree/javascript.js 1.7.5

part of tree.less;

class JavaScript extends Node implements EvalNode {
  bool escaped;
  int index;
  String expression;

  final String type = 'JavaScript';

  JavaScript(String this.expression, int this.index, bool this.escaped);

  // Not supported javascript
  eval(env) {
    return new Anonymous(this.expression);

//    eval: function (env) {
//        var result,
//            that = this,
//            context = {};
//
//        var expression = this.expression.replace(/@\{([\w-]+)\}/g, function (_, name) {
//            return tree.jsify(new(tree.Variable)('@' + name, that.index).eval(env));
//        });
//
//        try {
//            expression = new(Function)('return (' + expression + ')');
//        } catch (e) {
//            throw { message: "JavaScript evaluation error: " + e.message + " from `" + expression + "`" ,
//                    index: this.index };
//        }
//
//        var variables = env.frames[0].variables();
//        for (var k in variables) {
//            if (variables.hasOwnProperty(k)) {
//                /*jshint loopfunc:true */
//                context[k.slice(1)] = {
//                    value: variables[k].value,
//                    toJS: function () {
//                        return this.value.eval(env).toCSS();
//                    }
//                };
//            }
//        }
//
//        try {
//            result = expression.call(context);
//        } catch (e) {
//            throw { message: "JavaScript evaluation error: '" + e.name + ': ' + e.message.replace(/["]/g, "'") + "'" ,
//                    index: this.index };
//        }
//        if (typeof(result) === 'number') {
//            return new(tree.Dimension)(result);
//        } else if (typeof(result) === 'string') {
//            return new(tree.Quoted)('"' + result + '"', result, this.escaped, this.index);
//        } else if (Array.isArray(result)) {
//            return new(tree.Anonymous)(result.join(', '));
//        } else {
//            return new(tree.Anonymous)(result);
//        }
//    }
  }
}