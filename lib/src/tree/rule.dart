//source: less/tree/rule.js 2.8.0 20160702

part of tree.less;

///
/// Backwards compatibility shim for Rule (Declaration)
///
  class Rule extends Declaration {
    @override final String    type = 'Rule';

    ///
    Rule(dynamic name, Node value,
        {String important,
        String merge,
        int index,
        FileInfo currentFileInfo,
        bool inline,
        bool variable})
        : super(name, value,
        important: important,
        merge: merge,
        index: index,
        currentFileInfo: currentFileInfo,
        inline: inline,
        variable: variable);
  }

//2.8.0 20160702
// var Rule = function () {
//     var args = Array.prototype.slice.call(arguments);
//     Declaration.call(this, args);
// };
//
// Rule.prototype = Object.create(Declaration.prototype);
// Rule.prototype.constructor = Rule;
// Rule.prototype.type = "Rule";
