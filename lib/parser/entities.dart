//source: less/parser.js 1.7.5 lines 782-1025

part of parsers.dart;

///
/// Entities are tokens which can be found inside an Expression
///
class Entities {
  Env env;
  CurrentChunk currentChunk;
  Parsers parsers; //To reference parsers.expression() and parsers.entity()

  Node node;

  Entities(Env this.env, CurrentChunk this.currentChunk, Parsers this.parsers);

  ///
  /// A string, which supports escaping " and '
  ///
  ///     "milky way" 'he\'s the one!'
  ///
  //lines 783-800
  Quoted quoted() {
    List<String> str;
    int j = currentChunk.i;
    bool e = false;
    int index = currentChunk.i;

    // Escaped strings
    if (currentChunk.charAt(j) == '~') {
      j++;
      e = true;
    }
    if ((currentChunk.charAt(j) != '"') && (currentChunk.charAt(j) != "'")) return null;

    if (e) currentChunk.$char('~');

    // ^"((?:[^"\\\r\n]|\\.)*)"|'((?:[^'\\\r\n]|\\.)*)'
    str = currentChunk.$re(r'^"((?:[^"\\\r\n]|\\.)*)"|' + r"'((?:[^'\\\r\n]|\\.)*)'");

    if (str != null) return new Quoted(str[0], str[1] != null ? str[1] : str[2], e, index, env.currentFileInfo);
    return null;
  }

  ///
  /// A catch-all word, such as:
  ///
  ///     black border-collapse
  ///
  Node keyword() {
    String k = currentChunk.$re(r'^%|^[_A-Za-z-][_A-Za-z0-9-]*');
    if (k != null) {
      Node color = new Color.fromKeyword(k);
      if (color != null) return color;
      return new Keyword(k);
    }
    return null;

//    keyword: function () {
//        var k;
 //
//        k = $re(/^%|^[_A-Za-z-][_A-Za-z0-9-]*/);
//        if (k) {
//            var color = tree.Color.fromKeyword(k);
//            if (color) {
//                return color;
//            }
//            return new(tree.Keyword)(k);
//        }
//    },
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
  ///
  Node call() {
    String name;
    String nameLC;
    Match nameMatch;
    List args;
    Node alpha_ret;
    int index = currentChunk.i;

    nameMatch = new RegExp(r'^([\w-]+|%|progid:[\w\.]+)\(').firstMatch(currentChunk.current);
    if (nameMatch == null) return null;

    name = nameMatch[1];
    nameLC = name.toLowerCase();
    if (nameLC == 'url') return null;

    currentChunk.i += name.length;

    if (nameLC == 'alpha') {
      alpha_ret = alpha();
      if (alpha_ret != null) return alpha_ret;
    }

    currentChunk.$char('('); // Parse the '(' and consume whitespace.

    args = arguments();

    if (currentChunk.$char(')') == null) return null;

    //?? name null ??
    if (name != null) return new Call(name, args, index, env.currentFileInfo);

    return null;

//    call: function () {
//        var name, nameLC, args, alpha_ret, index = i;
 //
//        name = /^([\w-]+|%|progid:[\w\.]+)\(/.exec(current);
//        if (!name) { return; }
 //
//        name = name[1];
//        nameLC = name.toLowerCase();
//        if (nameLC === 'url') {
//            return null;
//        }
 //
//        i += name.length;
 //
//        if (nameLC === 'alpha') {
//            alpha_ret = parsers.alpha();
//            if(typeof alpha_ret !== 'undefined') {
//                return alpha_ret;
//            }
//        }
 //
//        $char('('); // Parse the '(' and consume whitespace.
 //
//        args = this.arguments();
 //
//        if (! $char(')')) {
//            return;
//        }
 //
//        if (name) { return new(tree.Call)(name, args, index, env.currentFileInfo); }
//    },
  }

  ///
  /// IE's alpha function
  ///
  ///     alpha(opacity=88)
  ///
  //Original in parsers.dart
  Alpha alpha() {
    var value;

    if (currentChunk.$re(r'^\(opacity=', false) == null) return null; // i
    value = currentChunk.$re(r'^\d+');
    if (value == null) value = variable();
    if (value != null) {
      currentChunk.expectChar(')');
      return new Alpha(value);
    }
    return null;

//alpha: function () {
//    var value;
//
//    if (! $re(/^\(opacity=/i)) { return; }
//    value = $re(/^\d+/) || this.entities.variable();
//    if (value) {
//        expectChar(')');
//        return new(tree.Alpha)(value);
//    }
//},

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
      if (currentChunk.$char(',') == null) break;
    }

    return args;

//    arguments: function () {
//        var args = [], arg;
 //
//        while (true) {
//            arg = this.assignment() || parsers.expression();
//            if (!arg) {
//                break;
//            }
//            args.push(arg);
//            if (! $char(',')) {
//                break;
//            }
//        }
//        return args;
//    },
  }

  ///
  Node literal() {
    Node result = dimension();
    if (result == null) result = color();
    if (result == null) result = quoted();
    if (result == null) result = unicodeDescriptor();

    return result;
  }

  ///
  /// Assignments are argument entities for calls.
  /// They are present in ie filter properties as shown below.
  ///
  ///     filter: progid:DXImageTransform.Microsoft.Alpha( *opacity=50* )
  ///
  Assignment assignment() {
    String key;
    Node value;

    key = currentChunk.$re(r'^\w+(?=\s?=)', false);
    if (key == null) return null;

    if (currentChunk.$char('=') == null) return null;

    value = parsers.entity();
    if (value != null) return new Assignment(key, value);

    return null;
//    assignment: function () {
//        var key, value;
//        key = $re(/^\w+(?=\s?=)/i);
//        if (!key) {
//            return;
//        }
//        if (!$char('=')) {
//            return;
//        }
//        value = parsers.entity();
//        if (value) {
//            return new(tree.Assignment)(key, value);
//        }
//    },
  }

  ///
  /// Parse url() tokens
  ///
  /// We use a specific rule for urls, because they don't really behave like
  /// standard function calls. The difference is that the argument doesn't have
  /// to be enclosed within a string, so it can't be parsed as an Expression.
  ///
  URL url() {
    String anonymous;
    int index = currentChunk.i;
    Node value;

    if ((currentChunk.charAtPos() != 'u') || (currentChunk.$re(r'^url\(') == null)) return null;

    value = quoted();
    if (value == null) value = variable();
    if (value == null) {
      anonymous = currentChunk.$re(r'''^(?:(?:\\[\(\)'"])|[^\(\)'"])+''');
      if (anonymous == null) anonymous = '';
      value = new Anonymous(anonymous);
    }

    currentChunk.expectChar(')');
    return new URL(value, index, env.currentFileInfo);

//    url: function () {
//        var value;
//
//        if (input.charAt(i) !== 'u' || !$re(/^url\(/)) {
//            return;
//        }
//
//        value = this.quoted() || this.variable() ||
//                $re(/^(?:(?:\\[\(\)'"])|[^\(\)'"])+/) || "";
//
//        expectChar(')');
 //
//        return new(tree.URL)((value.value != null || value instanceof tree.Variable)
//                            ? value : new(tree.Anonymous)(value), env.currentFileInfo);
//    },
  }

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
    int index = currentChunk.i;

    if (currentChunk.charAtPos() == '@') {
      name = currentChunk.$re(r'^@@?[\w-]+');
      if (name != null) return new Variable(name, index, env.currentFileInfo);
    }
    return null;

//    variable: function () {
//        var name, index = i;
//
//        if (input.charAt(i) === '@' && (name = $re(/^@@?[\w-]+/))) {
//            return new(tree.Variable)(name, index, env.currentFileInfo);
//        }
//    },
  }


  ///
  /// A variable entity using the protective {} e.g. @{var}
  ///
  Variable variableCurly() {
    String curly;
    int index = currentChunk.i;

    if (currentChunk.charAtPos() == '@' && (curly = currentChunk.$re(r'^@\{([\w-]+)\}', true, 1)) != null) {
      return new Variable('@${curly}', index, env.currentFileInfo);
    }
    return null;

//    variableCurly: function () {
//        var curly, index = i;
//
//        if (input.charAt(i) === '@' && (curly = $re(/^@\{([\w-]+)\}/))) {
//            return new(tree.Variable)("@" + curly[1], index, env.currentFileInfo);
//        }
//    },
   }

  ///
  /// A Hexadecimal color
  ///
  ///     #4F3C2F
  ///
  /// `rgb` and `hsl` colors are parsed through the `entities.call` parser.
  ///
  Color color() {
    Match rgb;

    if (currentChunk.charAtPos() == '#' && (rgb = currentChunk.$reMatch(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})')) != null) {
      // strip colons, brackets, whitespaces and other characters that should not definitely be part of color string
      Match colorCandidateMatch = new RegExp(r'^#([\w]+).*').firstMatch(rgb.input);
      String colorCandidateString = colorCandidateMatch[1];

      // verify if candidate consists only of allowed HEX characters
      if (new RegExp(r'^[A-Fa-f0-9]+$').firstMatch(colorCandidateString) == null) currentChunk.error('Invalid HEX color code');

      return new Color(rgb[1]);
    }
    return null;

//    color: function () {
//        var rgb;
//
//        if (input.charAt(i) === '#' && (rgb = $re(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/))) {
//            var colorCandidateString = rgb.input.match(/^#([\w]+).*/); // strip colons, brackets, whitespaces and other characters that should not definitely be part of color string
//            colorCandidateString = colorCandidateString[1];
//            if (!colorCandidateString.match(/^[A-Fa-f0-9]+$/)) { // verify if candidate consists only of allowed HEX characters
//                error("Invalid HEX color code");
//            }
//            return new(tree.Color)(rgb[1]);
//        }
//    },
  }

  ///
  /// A Dimension, that is, a number and a unit
  ///
  ///     0.5em 95%
  ///
  Dimension dimension() {
    List<String> value;
    int c = currentChunk.charCodeAtPos();
    //Is the first char of the dimension 0-9, '.', '+' or '-'
    if ((c > 57 || c < 43) || c == 47 || c == 44) return null;

    value = currentChunk.$re(r'^([+-]?\d*\.?\d+)(%|[a-z]+)?');
    if (value != null) return new Dimension(value[1], value[2]);
    return null;
  }

  ///
  /// A unicode descriptor, as is used in unicode-range
  ///
  /// U+0??  or U+00A1-00A9
  ///
  UnicodeDescriptor unicodeDescriptor() {
    String ud = currentChunk.$re(r'^U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?', true, 0);
    if (ud != null) return new UnicodeDescriptor(ud);

    return null;
//    unicodeDescriptor: function () {
//        var ud;
//
//        ud = $re(/^U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?/);
//        if (ud) {
//            return new(tree.UnicodeDescriptor)(ud[0]);
//        }
//    },
  }

  ///
  /// JavaScript code to be evaluated
  ///
  ///     `window.location.href`
  ///
  JavaScript javascript() {
    String str;
    int j = currentChunk.i;
    bool e = false;

    if (currentChunk.charAt(j) == '~') { // Escaped strings
      j++;
      e = true;
    }
    if (currentChunk.charAt(j) != '`') return null;

    if (env.javascriptEnabled == null || !env.javascriptEnabled ) {
      currentChunk.error('You are using JavaScript, which has been disabled.');
    }

    if (e) currentChunk.$char('~');

    str = currentChunk.$re(r'^`([^`]*)`');
    if (str != null) return new JavaScript(str, currentChunk.i, e);

    return null;

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