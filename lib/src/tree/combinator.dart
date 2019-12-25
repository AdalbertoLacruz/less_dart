//source: tree/combinator.js 2.5.0

part of tree.less;

///
class Combinator extends Node {
  @override
  final String name = null;

  @override
  final String type = 'Combinator';

  @override
  covariant String value;

  ///
  bool emptyOrWhitespace;

  final Map<String, bool> _noSpaceCombinators = <String, bool>{
    '': true,
    ' ': true,
    '|': true
  };

  ///
  Combinator(String value) {
    this.value = '';
    if (value == ' ') {
      this.value = ' ';
      emptyOrWhitespace = true;
    } else if (value != null) {
      this.value = value.trim();
      emptyOrWhitespace = this.value.isEmpty;
    }

//2.3.1
//  var Combinator = function (value) {
//      if (value === ' ') {
//          this.value = ' ';
//          this.emptyOrWhitespace = true;
//      } else {
//          this.value = value ? value.trim() : "";
//          this.emptyOrWhitespace = this.value === "";
//      }
//  };
  }

  /// Fields to show with genTree
  @override
  Map<String, dynamic> get treeField => <String, dynamic>{'value': value};

  ///
  /// Writes value in [output]
  ///
  @override
  void genCSS(Contexts context, Output output) {
    if (context?.cleanCss ?? false) return genCleanCSS(context, output);

    final spaceOrEmpty =
        ((context?.compress ?? false) || (_noSpaceCombinators[value] ?? false))
            ? ''
            : ' ';
    output.add('$spaceOrEmpty$value$spaceOrEmpty');

//2.3.1
//  Combinator.prototype.genCSS = function (context, output) {
//      var spaceOrEmpty = (context.compress || _noSpaceCombinators[this.value]) ? '' : ' ';
//      output.add(spaceOrEmpty + this.value + spaceOrEmpty);
//  };
  }

  /// clean-css output
  void genCleanCSS(Contexts context, Output output) {
    output.add(value);
  }

  @override
  String toString() => value;
}
