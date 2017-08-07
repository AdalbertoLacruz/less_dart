//source: less/tree/directive.js 2.8.0 20160702

part of tree.less;

///
/// Backwards compatibility shim for Directive (AtRule)
///
class Directive extends AtRule {
    @override final String    type = 'Directive';

    ///
    Directive(String name, Node value, dynamic rules, int index,
        FileInfo currentFileInfo, DebugInfo debugInfo,
        {VisibilityInfo visibilityInfo, bool isRooted})
        : super(name, value,
          rules: rules,
          index: index,
          currentFileInfo: currentFileInfo,
          debugInfo: debugInfo,
          visibilityInfo: visibilityInfo,
          isRooted : isRooted);
}

//2.8.0 20160702
// var Directive = function () {
//     var args = Array.prototype.slice.call(arguments);
//     AtRule.call(this, args);
// };
// Directive.prototype = Object.create(AtRule.prototype);
// Directive.prototype.constructor = Directive;
// Directive.prototype.type = "Directive";
