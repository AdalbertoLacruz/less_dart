//source: tree/combinator.js 2.3.1

part of tree.less;

class Combinator extends Node {
  String value = '';
  bool emptyOrWhitespace;

  Map<String, bool> _noSpaceCombinators = {
    '': true,
    ' ': true,
    '|': true
  };

  final String type = 'Combinator';

  ///
  //2.3.1 ok
  Combinator (String value) {
    if (value == ' ') {
      this.value = ' ';
      this.emptyOrWhitespace = true;
    } else if (value != null) {
      this.value = value.trim();
      this.emptyOrWhitespace = this.value.isEmpty;
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
  //2.3.1 ok
  genCSS(Contexts context, Output output) {
    String spaceOrEmpty = (isTrue(context.compress) || isTrue(this._noSpaceCombinators[this.value])) ? '' : ' ';
    output.add(spaceOrEmpty + this.value + spaceOrEmpty);

//2.3.1
//  Combinator.prototype.genCSS = function (context, output) {
//      var spaceOrEmpty = (context.compress || _noSpaceCombinators[this.value]) ? '' : ' ';
//      output.add(spaceOrEmpty + this.value + spaceOrEmpty);
//  };
  }
}