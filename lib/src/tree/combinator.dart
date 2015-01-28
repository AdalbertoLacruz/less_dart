//source: less/tree/element.js 1.7.5 lines 71-90

part of tree.less;

class Combinator extends Node implements ToCSSNode {
  String value = '';

  Map<String, bool> _noSpaceCombinators = {
    '': true,
    ' ': true,
    '|': true
  };

  final String type = 'Combinator';

  Combinator (String value) {
    if (value == ' ') {
      this.value = ' ';
    } else if (value != null) {
      this.value = value.trim();
    }
  }

  ///
  /// Writes value in [output]
  /// #
  genCSS(Contexts env, Output output) {
    String spaceOrEmpty = (isTrue(env.compress) || isTrue(this._noSpaceCombinators[this.value])) ? '' : ' ';
    output.add(spaceOrEmpty + this.value + spaceOrEmpty);

//    genCSS: function (env, output) {
//        var spaceOrEmpty = (env.compress || this._noSpaceCombinators[this.value]) ? '' : ' ';
//        output.add(spaceOrEmpty + this.value + spaceOrEmpty);
//    },
  }

  // toCSS => node.toCSS
}