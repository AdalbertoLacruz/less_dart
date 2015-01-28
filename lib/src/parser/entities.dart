//source: less/parser.js 2.2.0 lines 280-511

part of parser.less;

///
/// Entities are tokens which can be found inside an Expression
///
class Entities {
  Contexts context;
  ParserInput parserInput;
  Parsers parsers; //To reference parsers.expression() and parsers.entity()
  FileInfo fileInfo;

  Node node;

  Entities(Contexts this.context, ParserInput this.parserInput, Parsers this.parsers) {
    this.fileInfo = this.context.currentFileInfo;
  }

  ///
  /// A string, which supports escaping " and '
  ///
  ///     "milky way" 'he\'s the one!'
  ///
  //2.2.0 ok
  Quoted quoted() {
    List<String> str;
    int index = parserInput.i;

    str = parserInput.$re(r'^(~)?("((?:[^"\\\r\n]|\\.)*)"|' + r"'((?:[^'\\\r\n]|\\.)*)')");
    if (str != null) return new Quoted(str[2], str[3] != null ? str[3] : str[4],
        str[1] != null, index, fileInfo);
    return null;

//2.2.0
//  quoted: function () {
//      var str, index = parserInput.i;
//
//      str = parserInput.$re(/^(~)?("((?:[^"\\\r\n]|\\.)*)"|'((?:[^'\\\r\n]|\\.)*)')/);
//      if (str) {
//          return new(tree.Quoted)(str[2], str[3] || str[4], Boolean(str[1]), index, fileInfo);
//      }
//  }
  }

  ///
  /// A catch-all word, such as:
  ///
  ///     black border-collapse
  //2.2.0 ok
  Node keyword() {
    String k = parserInput.$re(r'^%|^[_A-Za-z-][_A-Za-z0-9-]*');
    if (k != null) {
      Node color = new Color.fromKeyword(k);
      return (color != null) ? color : new Keyword(k);
    }
    return null;

//2.2.0
//  keyword: function () {
//      var k = parserInput.$re(/^%|^[_A-Za-z-][_A-Za-z0-9-]*/);
//      if (k) {
//          return tree.Color.fromKeyword(k) || new(tree.Keyword)(k);
//      }
  }

  ///
  /// A function call
  ///
  ///     rgb(255, 0, 255)
  ///
  /// We also try to catch IE's `alpha()`, but let the `alpha` parser
  /// deal with the details.
  ///
  /// The arguments are parsed with the `entities.arguments` parser.
  ///
  //2.2.0 ok
  Node call() {
    String name;
    String nameLC;
    List args;
    Node alpha;
    int index = parserInput.i;

    if (parserInput.peek(new RegExp(r'^url\(', caseSensitive: false))) return null;

    parserInput.save();

    name = parserInput.$re(r'^([\w-]+|%|progid:[\w\.]+)\(', true, 1);
    if (name == null) {
      parserInput.forget();
      return null;
    }

    nameLC = name.toLowerCase();

    if (nameLC == 'alpha') {
      alpha = this.alpha();
      if (alpha != null) return alpha;
    }

    args = arguments();

    if (parserInput.$char(')') == null) {
      parserInput.restore("Could not parse call arguments or missing ')'");
      return null;
    }

    parserInput.forget();
    return new Call(name, args, index, fileInfo);

//2.2.0
//  call: function () {
//      var name, nameLC, args, alpha, index = parserInput.i;
//
//      if (parserInput.peek(/^url\(/i)) {
//          return;
//      }
//
//      parserInput.save();
//
//      name = parserInput.$re(/^([\w-]+|%|progid:[\w\.]+)\(/);
//      if (!name) { parserInput.forget(); return; }
//
//      name = name[1];
//      nameLC = name.toLowerCase();
//
//      if (nameLC === 'alpha') {
//          alpha = parsers.alpha();
//          if(alpha) {
//              return alpha;
//          }
//      }
//
//      args = this.arguments();
//
//      if (! parserInput.$char(')')) {
//          parserInput.restore("Could not parse call arguments or missing ')'");
//          return;
//      }
//
//      parserInput.forget();
//      return new(tree.Call)(name, args, index, fileInfo);
//  }
  }

  ///
  /// IE's alpha function
  ///
  ///     alpha(opacity=88)
  ///
  //Original in parsers.dart
  //2.2.0 ok
  Alpha alpha() {
    var value;

    if (parserInput.$re(r'^\opacity=', false) == null) return null; // i
    value = parserInput.$re(r'^\d+');
    if (value == null) {
      value = parserInput.expect(this.variable, 'Could not parse alpha');
    }
    parserInput.expectChar(')');
    return new Alpha(value);

//2.2.0
//  alpha: function () {
//      var value;
//
//      if (! parserInput.$re(/^opacity=/i)) { return; }
//      value = parserInput.$re(/^\d+/);
//      if (!value) {
//          value = expect(this.entities.variable, "Could not parse alpha");
//      }
//      expectChar(')');
//      return new(tree.Alpha)(value);
//  }
  }

  ///
  //2.2.0 ok
  List<Node> arguments() {
    List<Node> args = [];
    Node arg;

    while (true) {
      arg = assignment();
      if (arg == null) arg = parsers.expression();
      if (arg == null) break;

      args.add(arg);
      if (parserInput.$char(',') == null) break;
    }

    return args;

//2.2.0
//  arguments: function () {
//      var args = [], arg;
//
//      while (true) {
//          arg = this.assignment() || parsers.expression();
//          if (!arg) {
//              break;
//          }
//          args.push(arg);
//          if (! parserInput.$char(',')) {
//              break;
//          }
//      }
//      return args;
//  }
  }

  ///
  //2.2.0 ok
  Node literal() {
    Node result = dimension();
    if (result == null) result = color();
    if (result == null) result = quoted();
    if (result == null) result = unicodeDescriptor();

    return result;

//2.2.0
//  literal: function () {
//      return this.dimension() ||
//             this.color() ||
//             this.quoted() ||
//             this.unicodeDescriptor();
//  }
  }

  ///
  /// Assignments are argument entities for calls.
  /// They are present in ie filter properties as shown below.
  ///
  ///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
  ///
  //2.2.0 ok
  Assignment assignment() {
    String key;
    Node value;

    key = parserInput.$re(r'^\w+(?=\s?=)', false);
    if (key == null) return null;

    if (parserInput.$char('=') == null) return null;

    value = parsers.entity();
    if (value != null) return new Assignment(key, value);

    return null;

//2.2.0
//  assignment: function () {
//      var key, value;
//      key = parserInput.$re(/^\w+(?=\s?=)/i);
//      if (!key) {
//          return;
//      }
//      if (!parserInput.$char('=')) {
//          return;
//      }
//      value = parsers.entity();
//      if (value) {
//          return new(tree.Assignment)(key, value);
//      }
//  }
  }

  ///
  /// Parse url() tokens
  ///
  /// We use a specific rule for urls, because they don't really behave like
  /// standard function calls. The difference is that the argument doesn't have
  /// to be enclosed within a string, so it can't be parsed as an Expression.
  ///
  //2.2.0 ok
  URL url() {
    String anonymous;
    int index = parserInput.i;
    Node value;

    if ((parserInput.currentChar() != 'u') || (parserInput.$re(r'^url\(') == null)) return null;

    parserInput.autoCommentAbsorb = false;
    value = quoted();
    if (value == null) value = variable();
    if (value == null) {
      anonymous = parserInput.$re(r'''^(?:(?:\\[\(\)'"])|[^\(\)'"])+''');
      if (anonymous == null) anonymous = '';
      value = new Anonymous(anonymous);
    }
    parserInput.autoCommentAbsorb = true;

    parserInput.expectChar(')');
    return new URL(value, index, fileInfo);

//2.2.0
//  url: function () {
//      var value, index = parserInput.i;
//
//      parserInput.autoCommentAbsorb = false;
//
//      if (parserInput.currentChar() !== 'u' || !parserInput.$re(/^url\(/)) {
//          parserInput.autoCommentAbsorb = true;
//          return;
//      }
//
//      value = this.quoted() || this.variable() ||
//              parserInput.$re(/^(?:(?:\\[\(\)'"])|[^\(\)'"])+/) || "";
//
//      parserInput.autoCommentAbsorb = true;
//
//      expectChar(')');
//
//      return new(tree.URL)((value.value != null || value instanceof tree.Variable) ?
//                          value : new(tree.Anonymous)(value), index, fileInfo);
//  }
  }

  ///
  /// A Variable entity, such as `@fink`, in
  ///
  ///     width: @fink + 2px
  ///
  /// We use a different parser for variable definitions,
  /// see `parsers.variable`.
  ///
  //2.2.0 ok
  Variable variable() {
    String name;
    int index = parserInput.i;

    if (parserInput.currentChar() == '@') {
      name = parserInput.$re(r'^@@?[\w-]+');
      if (name != null) return new Variable(name, index, fileInfo);
    }
    return null;

//2.2.0
//  variable: function () {
//      var name, index = parserInput.i;
//
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^@@?[\w-]+/))) {
//          return new(tree.Variable)(name, index, fileInfo);
//      }
//  }
  }

  ///
  /// A variable entity using the protective {} e.g. @{var}
  ///
  //2.2.0 ok
  Variable variableCurly() {
    String curly;
    int index = parserInput.i;

    if (parserInput.currentChar() == '@' && (curly = parserInput.$re(r'^@\{([\w-]+)\}', true, 1)) != null) {
      return new Variable('@${curly}', index, fileInfo);
    }
    return null;

//2.2.0
//  variableCurly: function () {
//      var curly, index = parserInput.i;
//
//      if (parserInput.currentChar() === '@' && (curly = parserInput.$re(/^@\{([\w-]+)\}/))) {
//          return new(tree.Variable)("@" + curly[1], index, fileInfo);
//      }
//  }
   }

  ///
  /// A Hexadecimal color
  ///
  ///     #4F3C2F
  ///
  /// `rgb` and `hsl` colors are parsed through the `entities.call` parser.
  ///
  //2.2.0 ok
  Color color() {
    Match rgb;

    if (parserInput.currentChar() == '#' && (rgb = parserInput.$reMatch(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})')) != null) {
      // strip colons, brackets, whitespaces and other characters that should not definitely be part of color string
      Match colorCandidateMatch = new RegExp(r'^#([\w]+).*').firstMatch(rgb.input);
      String colorCandidateString = colorCandidateMatch[1];

      // verify if candidate consists only of allowed HEX characters
      if (new RegExp(r'^[A-Fa-f0-9]+$').firstMatch(colorCandidateString) == null) parserInput.error('Invalid HEX color code');

      return new Color(rgb[1]);
    }
    return null;

//2.2.0
//  color: function () {
//      var rgb;
//
//      if (parserInput.currentChar() === '#' && (rgb = parserInput.$re(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/))) {
//          var colorCandidateString = rgb.input.match(/^#([\w]+).*/); // strip colons, brackets, whitespaces and other characters that should not definitely be part of color string
//          colorCandidateString = colorCandidateString[1];
//          if (!colorCandidateString.match(/^[A-Fa-f0-9]+$/)) { // verify if candidate consists only of allowed HEX characters
//              error("Invalid HEX color code");
//          }
//          return new(tree.Color)(rgb[1]);
//      }
  }

  ///
  /// A Dimension, that is, a number and a unit
  ///
  ///     0.5em 95%
  ///
  //2.2.0 ok
  Dimension dimension() {
    if (parserInput.peekNotNumeric()) return null;

    List<String> value = parserInput.$re(r'^([+-]?\d*\.?\d+)(%|[a-z]+)?', false);
    if (value != null) return new Dimension(value[1], value[2]);
    return null;

//2.2.0
//  dimension: function () {
//      if (parserInput.peekNotNumeric()) {
//          return;
//      }
//
//      var value = parserInput.$re(/^([+-]?\d*\.?\d+)(%|[a-z]+)?/i);
//      if (value) {
//          return new(tree.Dimension)(value[1], value[2]);
//      }
//  }
  }

  ///
  /// A unicode descriptor, as is used in unicode-range
  ///
  /// U+0??  or U+00A1-00A9
  ///
  //2.2.0 ok
  UnicodeDescriptor unicodeDescriptor() {
    String ud = parserInput.$re(r'^U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?', true, 0);
    if (ud != null) return new UnicodeDescriptor(ud);

    return null;

//2.2.0
//  unicodeDescriptor: function () {
//      var ud;
//
//      ud = parserInput.$re(/^U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?/);
//      if (ud) {
//          return new(tree.UnicodeDescriptor)(ud[0]);
//      }
//  }
  }

  ///
  /// JavaScript code to be evaluated
  ///
  ///     `window.location.href`
  ///
  //2.2.0 TODO pending upgrade - requires changes in tree\JavaScript
  JavaScript javascript() {
    String str;
    int j = parserInput.i;
    bool e = false;

    if (parserInput.charAt(j) == '~') { // Escaped strings
      j++;
      e = true;
    }
    if (parserInput.charAt(j) != '`') return null;

    if (context.javascriptEnabled == null || !context.javascriptEnabled ) {
      parserInput.error('You are using JavaScript, which has been disabled.');
    }

    if (e) parserInput.$char('~');

    str = parserInput.$re(r'^`([^`]*)`');
    if (str != null) return new JavaScript(str, parserInput.i, e);

    return null;

//2.2.0
//  javascript: function () {
//      var js, index = parserInput.i;
//
//      js = parserInput.$re(/^(~)?`([^`]*)`/);
//      if (js) {
//          return new(tree.JavaScript)(js[2], Boolean(js[1]), index, fileInfo);
//      }
//  }

//1.7.5
//    javascript: function () {
//        var str, j = i, e;
//
//        if (input.charAt(j) === '~') { j++; e = true; } // Escaped strings
//        if (input.charAt(j) !== '`') { return; }
//        if (env.javascriptEnabled !== undefined && !env.javascriptEnabled) {
//            error("You are using JavaScript, which has been disabled.");
//        }
//
//        if (e) { $char('~'); }
//
//        str = $re(/^`([^`]*)`/);
//        if (str) {
//            return new(tree.JavaScript)(str[1], i, e);
//        }
//    }
  }
}