// source: lib/less/functions/boolean.js 3.0.0 20170607

part of functions.less;

///
class BooleanFunctions extends FunctionBase {
  ///
  ///  boolean function. Example:
  ///
  ///     a: boolean(not(2 < 1)); => a: true;
  ///
  Keyword boolean(Condition condition) =>
      condition.eval(context).evaluated ? Keyword.True() : Keyword.False();

//3.0.0 20170607
// boolean: function(condition) {
//     return condition ? Keyword.True : Keyword.False;
// },

  ///
  ///  if function. Example:
  ///
  ///     a: if(not(false), 1, 2); => a: 1;
  ///     e: if(not(true), 5);     => e: ;
  ///
  @DefineMethod(name: 'if')
  Node ifFunction(Condition condition, Node trueValue, [Node falseValue]) =>
      condition.eval(context).evaluated
          ? trueValue
          : (falseValue ?? Anonymous(null));

//3.0.0 20170607
// 'if': function(condition, trueValue, falseValue) {
//     return condition ? trueValue
//         : (falseValue || new Anonymous);
// }
}
