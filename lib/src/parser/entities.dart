//source: less/parser.js 2.5.0 lines 290-551

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
  Quoted quoted() {
    String str;
    int index = parserInput.i;
    bool isEscaped = false;

    parserInput.save();
    if (parserInput.$char('~') != null) isEscaped = true;
    str = parserInput.$quoted();
    if (str == null) {
      parserInput.restore();
      return null;
    }
    parserInput.forget();
    return new Quoted(str[0], str.substring(1, str.length - 1), isEscaped, index, fileInfo);

//2.4.0 20150315-1345
//  quoted: function () {
//      var str, index = parserInput.i, isEscaped = false;
//
//      parserInput.save();
//      if (parserInput.$char("~")) {
//          isEscaped = true;
//      }
//      str = parserInput.$quoted();
//      if (!str) {
//          parserInput.restore();
//          return;
//      }
//      parserInput.forget();
//
//      return new(tree.Quoted)(str.charAt(0), str.substr(1, str.length - 2), isEscaped, index, fileInfo);
//  },
  }

  static final RegExp  _keywordRegEx = new RegExp(r'^[_A-Za-z-][_A-Za-z0-9-]*', caseSensitive: true);
  ///
  /// A catch-all word, such as:
  ///
  ///     black border-collapse
  ///
  Node keyword() {
    String k = parserInput.$char("%");
    if (k == null) k = parserInput.$re(_keywordRegEx);

    if (k != null) {
      Node color = new Color.fromKeyword(k);
      return (color != null) ? color : new Keyword(k);
    }
    return null;

//2.4.0 20150321 1640
//  keyword: function () {
//      var k = parserInput.$char("%") || parserInput.$re(/^[_A-Za-z-][_A-Za-z0-9-]*/);
//      if (k) {
//          return tree.Color.fromKeyword(k) || new(tree.Keyword)(k);
//      }
//  },
  }

  static final _callRegExp = new RegExp(r'^([\w-]+|%|progid:[\w\.]+)\(', caseSensitive: true);
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
  Node call() {
    String name;
    String nameLC;
    List args;
    Node alpha;
    int index = parserInput.i;

    // http://jsperf.com/case-insensitive-regex-vs-strtolower-then-regex/18
    if (parserInput.peek(new RegExp(r'^url\(', caseSensitive: false))) return null;

    parserInput.save();

    name = parserInput.$re(_callRegExp, 1);
    if (name == null) {
      parserInput.forget();
      return null;
    }

    nameLC = name.toLowerCase();

    if (nameLC == 'alpha') {
      alpha = this.alpha();
      if (alpha != null) {
        parserInput.forget();
        return alpha;
      }
    }

    args = arguments();

    if (parserInput.$char(')') == null) {
      parserInput.restore("Could not parse call arguments or missing ')'");
      return null;
    }

    parserInput.forget();
    return new Call(name, args, index, fileInfo);

//2.4.0 20150315
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
//          if (alpha) {
//              parserInput.forget();
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
//  },
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

  static final _alphaRegExp1 = new RegExp(r'^\opacity=', caseSensitive: false);
  static final _alphaRegExp2 = new RegExp(r'^\d+', caseSensitive: true);
  ///
  /// IE's alpha function
  ///
  ///     alpha(opacity=88)
  ///
  //Original in parsers.dart
  Alpha alpha() {
    var value;

    // http://jsperf.com/case-insensitive-regex-vs-strtolower-then-regex/18
    if (parserInput.$re(_alphaRegExp1) == null) return null; // i
    value = parserInput.$re(_alphaRegExp2);
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

  static final _assignmentRegExp = new RegExp(r'^\w+(?=\s?=)', caseSensitive: false);
  ///
  /// Assignments are argument entities for calls.
  /// They are present in ie filter properties as shown below.
  ///
  ///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
  ///
  Assignment assignment() {
    String key;
    Node value;

    parserInput.save();
    key = parserInput.$re(_assignmentRegExp);
    if (key == null) {
      parserInput.restore();
      return null;
    }

    if (parserInput.$char('=') == null) {
      parserInput.restore();
      return null;
    }

    value = parsers.entity();
    if (value != null) {
      parserInput.forget();
      return new Assignment(key, value);
    } else {
      parserInput.restore();
      return null;
    }

//2.4.0 20150315-1739
//  assignment: function () {
//      var key, value;
//      parserInput.save();
//      key = parserInput.$re(/^\w+(?=\s?=)/i);
//      if (!key) {
//          parserInput.restore();
//          return;
//      }
//      if (!parserInput.$char('=')) {
//          parserInput.restore();
//          return;
//      }
//      value = parsers.entity();
//      if (value) {
//          parserInput.forget();
//          return new(tree.Assignment)(key, value);
//      } else {
//          parserInput.restore();
//      }
//  },
  }

  static final _urlRegExp = new RegExp(r'''^(?:(?:\\[\(\)'"])|[^\(\)'"])+''', caseSensitive: true);
  ///
  /// Parse url() tokens
  ///
  /// We use a specific rule for urls, because they don't really behave like
  /// standard function calls. The difference is that the argument doesn't have
  /// to be enclosed within a string, so it can't be parsed as an Expression.
  ///
  URL url() {
    String anonymous;
    int index = parserInput.i;
    Node value;

    parserInput.autoCommentAbsorb = false;

    if (parserInput.$str('url(') == null) {
      parserInput.autoCommentAbsorb = true;
      return null;
    }

    value = quoted();
    if (value == null) value = variable();
    if (value == null) {
      anonymous = parserInput.$re(_urlRegExp);
      if (anonymous == null) anonymous = '';
      value = new Anonymous(anonymous);
    }
    parserInput.autoCommentAbsorb = true;

    parserInput.expectChar(')');
    return new URL(value, index, fileInfo);

//2.4.0 20150315
//  url: function () {
//      var value, index = parserInput.i;
//
//      parserInput.autoCommentAbsorb = false;
//
//      if (!parserInput.$str("url(")) {
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
//  },
  }

  static final _variableRegExp = new RegExp(r'^@@?[\w-]+', caseSensitive: true);
  ///
  /// A Variable entity, such as `@fink`, in
  ///
  ///     width: @fink + 2px
  ///
  /// We use a different parser for variable definitions,
  /// see `parsers.variable`.
  ///
  Variable variable() {
    String name;
    int index = parserInput.i;

    if (parserInput.currentChar() == '@') {
      name = parserInput.$re(_variableRegExp);
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

  static final _variableCurlyRegExp = new RegExp(r'^@\{([\w-]+)\}', caseSensitive: true);
  ///
  /// A variable entity using the protective {} e.g. @{var}
  ///
  Variable variableCurly() {
    String curly;
    int index = parserInput.i;

    if (parserInput.currentChar() == '@' && (curly = parserInput.$re(_variableCurlyRegExp, 1)) != null) {
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

  static final _colorRegExp1 = new RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})', caseSensitive: true);

  static final _colorRegExp2 = new RegExp(r'^#([\w]+).*');
  static final _colorRegExp3 = new RegExp(r'^[A-Fa-f0-9]+$');

  ///
  /// A Hexadecimal color
  ///
  ///     #4F3C2F
  ///
  /// `rgb` and `hsl` colors are parsed through the `entities.call` parser.
  ///
  Color color() {
    Match rgb;

    if (parserInput.currentChar() == '#'
        && (rgb = parserInput.$reMatchRegExp(_colorRegExp1)) != null) {

      // strip colons, brackets, whitespaces and other characters that should not
      // definitely be part of color string
      Match colorCandidateMatch = _colorRegExp2.firstMatch(rgb.input);
      String colorCandidateString = colorCandidateMatch[1];

      // verify if candidate consists only of allowed HEX characters
      if (_colorRegExp3.firstMatch(colorCandidateString) == null) {
        parserInput.error('Invalid HEX color code');
      }
      return new Color(rgb[1]);
    }
    return null;

//2.4.0
//  color: function () {
//      var rgb;
//
//      if (parserInput.currentChar() === '#' && (rgb = parserInput.$re(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/))) {
//          // strip colons, brackets, whitespaces and other characters that should not
//          // definitely be part of color string
//          var colorCandidateString = rgb.input.match(/^#([\w]+).*/);
//          colorCandidateString = colorCandidateString[1];
//          if (!colorCandidateString.match(/^[A-Fa-f0-9]+$/)) { // verify if candidate consists only of allowed HEX characters
//              error("Invalid HEX color code");
//          }
//          return new(tree.Color)(rgb[1]);
//      }
//  },
  }

  static final _dimensionRegExp = new RegExp(r'^([+-]?\d*\.?\d+)(%|[a-z]+)?', caseSensitive: false);
  ///
  /// A Dimension, that is, a number and a unit
  ///
  ///     0.5em 95%
  ///
  Dimension dimension() {
    if (parserInput.peekNotNumeric()) return null;

    List<String> value = parserInput.$re(_dimensionRegExp);
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

  static final _unicodeDescriptorRegExp = new RegExp(r'^U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?', caseSensitive: true);

  ///
  /// A unicode descriptor, as is used in unicode-range
  ///
  /// U+0??  or U+00A1-00A9
  ///
  UnicodeDescriptor unicodeDescriptor() {
    String ud = parserInput.$re(_unicodeDescriptorRegExp, 0);
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

  static final _javascriptRegExp = new RegExp(r'^[^`]*`', caseSensitive: true);

  ///
  /// JavaScript code to be evaluated
  ///
  ///     `window.location.href`
  ///
  JavaScript javascript() {
    String js;
    int index = parserInput.i;

    parserInput.save();

    String escape = parserInput.$char('~');
    String jsQuote = parserInput.$char('`');

    if (jsQuote == null) {
      parserInput.restore();
      return null;
    }

    js = parserInput.$re(_javascriptRegExp);
    if (js != null) {
      parserInput.forget();
      return new JavaScript(js.substring(0, js.length - 1), escape != null, index, fileInfo);
    }
    parserInput.restore('invalid javascript definition');
    return null;

//2.4.0 20150321 1640
//  javascript: function () {
//      var js, index = parserInput.i;
//
//      parserInput.save();
//
//      var escape = parserInput.$char("~");
//      var jsQuote = parserInput.$char("`");
//
//      if (!jsQuote) {
//          parserInput.restore();
//          return;
//      }
//
//      js = parserInput.$re(/^[^`]*`/);
//      if (js) {
//          parserInput.forget();
//          return new(tree.JavaScript)(js.substr(0, js.length - 1), Boolean(escape), index, fileInfo);
//      }
//      parserInput.restore("invalid javascript definition");
//    }
//},
  }
}