//source: tree/combinator.js 2.5.0

part of tree.less;

class Combinator extends Node {
  bool emptyOrWhitespace;

  Map<String, bool> _noSpaceCombinators = {
    '': true,
    ' ': true,
    '|': true
  };

  final String type = 'Combinator';

  ///
  Combinator (String value) {
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

  ///
  /// Writes value in [output]
  ///
  genCSS(Contexts context, Output output) {
    if (context != null && context.cleanCss) return genCleanCSS(context, output);

    String spaceOrEmpty = (isTrue(context.compress) || isTrue(_noSpaceCombinators[value])) ? '' : ' ';
    output.add(spaceOrEmpty + value + spaceOrEmpty);

//2.3.1
//  Combinator.prototype.genCSS = function (context, output) {
//      var spaceOrEmpty = (context.compress || _noSpaceCombinators[this.value]) ? '' : ' ';
//      output.add(spaceOrEmpty + this.value + spaceOrEmpty);
//  };
  }

  /// clean-css output
  genCleanCSS(Contexts context, Output output) {
    output.add(value);
  }

  @override
  get name => null;
}