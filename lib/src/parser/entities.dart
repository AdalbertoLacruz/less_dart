//source: less/parser/parser.js 3.9.0 20190711

part of parser.less;

///
/// Entities are tokens which can be found inside an Expression
///
class Entities {
  /// Environment variables
  Contexts context;

  /// Data about the file being parsed
  FileInfo fileInfo;

  /// Input management
  ParserInput parserInput;

  /// For internal use, to reference parsers.expression() and parsers.entity()
  Parsers parsers;

  ///
  /// Constructor. It's an auxiliary class for parsers.
  ///
  Entities(this.context, this.parserInput, this.parsers) {
    fileInfo = context.currentFileInfo;
  }

  ///
  Node mixinLookup() => parsers.mixin.call(inValue: true, getLookup: true);

// 3.5.0.beta.5 20180702
//  mixinLookup: function() {
//      return parsers.mixin.call(true, true);
//  },

  ///
  /// A string, which supports escaping `~`, `"` and `'`
  ///
  ///     "milky way" 'he\'s the one!'
  ///
  Quoted quoted({bool forceEscaped = false}) {
    final int index = parserInput.i;
    bool isEscaped = false;
    String str;

    parserInput.save();
    if (parserInput.$char('~') != null) {
      isEscaped = true;
    } else if (forceEscaped) {
      parserInput.restore();
      return null;
    }

    str = parserInput.$quoted();
    if (str == null) {
      parserInput.restore();
      return null;
    }
    parserInput.forget();
    return Quoted(str[0], str.substring(1, str.length - 1),
        escaped: isEscaped, index: index, currentFileInfo: fileInfo);

// 3.5.0.beta 20180625
//  quoted: function (forceEscaped) {
//    var str, index = parserInput.i, isEscaped = false;
//
//    parserInput.save();
//    if (parserInput.$char('~')) {
//      isEscaped = true;
//    } else if (forceEscaped) {
//      parserInput.restore();
//      return;
//    }
//
//    str = parserInput.$quoted();
//    if (!str) {
//      parserInput.restore();
//      return;
//    }
//    parserInput.forget();
//
//    return new(tree.Quoted)(str.charAt(0), str.substr(1, str.length - 2), isEscaped, index, fileInfo);
//  },
  }

  static final RegExp _keywordRegEx = RegExp(
      r'\[?(?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+\]?',
      caseSensitive: true);

  ///
  /// A catch-all word, such as:
  ///
  ///     black border-collapse
  ///
  /// returns Color | Keyword
  ///
  Node keyword() {
    final String k = parserInput.$char('%') ?? parserInput.$re(_keywordRegEx);

    if (k != null) return Color.fromKeyword(k) ?? Keyword(k);
    return null;

// 3.5.1 20180706
//  keyword: function () {
//      var k = parserInput.$char('%') || parserInput.$re(/^\[?(?:[\w-]|\\(?:[A-Fa-f0-9]{1,6} ?|[^A-Fa-f0-9]))+\]?/);
//      if (k) {
//          return tree.Color.fromKeyword(k) || new(tree.Keyword)(k);
//      }
//  },
  }

  static final RegExp _callRegExp =
      RegExp(r'([\w-]+|%|progid:[\w\.]+)\(', caseSensitive: true);
  static final RegExp _reCallUrl = RegExp(r'url\(', caseSensitive: false);

  ///
  /// A function call
  ///
  ///     rgb(255, 0, 255)
  ///
  /// The arguments are parsed with the `entities.arguments` parser.
  ///
  Node call() {
    List<Node> args = <Node>[];
    bool func;
    final int index = parserInput.i;
    String name;

    if (parserInput.peek(_reCallUrl)) return null;

    parserInput.save();

    name = parserInput.$re(_callRegExp, 1);
    if (name == null) {
      parserInput.forget();
      return null;
    }

    func = customFuncCall(name, args); // Different from js
    if (func != null) {
      // name found
      if (args.isNotEmpty && func) {
        //stop
        parserInput.forget();
        return args.first; //must return Node
      }
    }

    args = arguments(args);

    if (parserInput.$char(')') == null) {
      parserInput.restore("Could not parse call arguments or missing ')'");
      return null;
    }

    parserInput.forget();
    return Call(name, args, index: index, currentFileInfo: fileInfo);

//3.0.0 20170607
// call: function () {
//     var name, args, func, index = parserInput.i;
//
//     // http://jsperf.com/case-insensitive-regex-vs-strtolower-then-regex/18
//     if (parserInput.peek(/^url\(/i)) {
//         return;
//     }
//
//     parserInput.save();
//
//     name = parserInput.$re(/^([\w-]+|%|progid:[\w\.]+)\(/);
//     if (!name) {
//         parserInput.forget();
//         return;
//     }
//
//     name = name[1];
//     func = this.customFuncCall(name);
//     if (func) {
//         args = func.parse();
//         if (args && func.stop) {
//             parserInput.forget();
//             return args;
//         }
//     }
//
//     args = this.arguments(args);
//
//     if (!parserInput.$char(')')) {
//         parserInput.restore("Could not parse call arguments or missing ')'");
//         return;
//     }
//
//     parserInput.forget();
//     return new(tree.Call)(name, args, index, fileInfo);
// },
  }

  static final RegExp _alphaRegExp1 =
      RegExp(r'\opacity=', caseSensitive: false);
  static final RegExp _alphaRegExp2 = RegExp(r'\d+', caseSensitive: true);

  ///
  /// IE's alpha function
  ///
  ///     alpha(opacity=88)
  ///
  /// Search for String | Variable
  ///
  //Original in parsers.dart
  Quoted ieAlpha() {
    if (parserInput.$re(_alphaRegExp1) == null) return null; // i

    String value = parserInput.$re(_alphaRegExp2);
    if (value == null) {
      final Variable _value =
          parserInput.expect(variable, 'Could not parse alpha');
      value = '@{${_value.name.substring(1)}}';
    }
    parserInput.expectChar(')');

    return Quoted('', 'alpha(opacity=$value)');

//3.0.0 20170607
// ieAlpha: function () {
//     var value;
//
//     // http://jsperf.com/case-insensitive-regex-vs-strtolower-then-regex/18
//     if (!parserInput.$re(/^opacity=/i)) { return; }
//     value = parserInput.$re(/^\d+/);
//     if (!value) {
//         value = expect(parsers.entities.variable, "Could not parse alpha");
//         value = '@{' + value.name.slice(1) + '}';
//     }
//     expectChar(')');
//     return new tree.Quoted('', 'alpha(opacity=' + value + ')');
// },
  }

  ///
  /// Parsing rules for functions with non-standard args, e.g.:
  ///
  ///     boolean(not(2 > 1))
  ///
  /// Receives the custom function [name] and returns the result in [args].
  /// The bool result is null if not custom function is found
  /// or true/false if it is needed to search for more arguments.
  ///
  // This is a quick prototype, to be modified/improved when
  // more custom-parsed funcs come (e.g. `selector(...)`)
  //
  // Differs from js implementation and interface
  bool customFuncCall(String name, List<Node> args) {
    Node result;
    switch (name) {
      case 'alpha':
      case 'Alpha':
        result = ieAlpha();
        if (result != null) args.add(result);
        return true; // stop = true
        break;
      case 'boolean':
      case 'if':
        result = parserInput.expect(parsers.condition, 'expected condition');
        if (result != null) args.add(result);
        return false; //look for more arguments
        break;
    }
    return null; //function not defined

//3.0.0 20170607
// customFuncCall: function (name) {
//     /* Ideally the table is to be moved out of here for faster perf.,
//        but it's quite tricky since it relies on all these `parsers`
//        and `expect` available only here */
//     return {
//         alpha:   f(parsers.ieAlpha, true),
//         boolean: f(condition),
//         'if':    f(condition)
//     }[name.toLowerCase()];
//
//     function f(parse, stop) {
//         return {
//             parse: parse, // parsing function
//             stop:  stop   // when true - stop after parse() and return its result,
//                           // otherwise continue for plain args
//         };
//     }
//
//     function condition() {
//         return [expect(parsers.condition, 'expected condition')];
//     }
// },
  }

  ///
  /// The arguments in a call function. Example:
  ///
  ///     color: rgba(255, 238, 170, 0.1);
  ///
  /// Returns a List of `DetachedRuleset | Assignment | Expression`
  /// separated by `,` or `;`
  ///
  List<Node> arguments(List<Node> prevArgs) {
    List<Node> argsComma = prevArgs ?? <Node>[];
    final List<Node> argsSemiColon = <Node>[];
    bool isPrevArgs = prevArgs?.isNotEmpty ?? false;
    bool isSemiColonSeparated = false;
    Node value;

    parserInput.save();

    while (true) {
      if (isPrevArgs) {
        isPrevArgs = false;
      } else {
        value =
            parsers.detachedRuleset() ?? assignment() ?? parsers.expression();
        if (value == null) break;
        if ((value.value is List) && (value.value?.length == 1 ?? false)) {
          value = value.value.first;
        }
        argsComma.add(value);
      }

      if (parserInput.$char(',') != null) continue;

      if (parserInput.$char(';') != null || isSemiColonSeparated) {
        isSemiColonSeparated = true;
        value = (argsComma.length == 1) ? argsComma.first : Value(argsComma);
        argsSemiColon.add(value);
        argsComma = <Node>[];
      }
    }
    parserInput.forget();
    return isSemiColonSeparated ? argsSemiColon : argsComma;

//3.0.0 20170607
// arguments: function (prevArgs) {
//     var argsComma = prevArgs || [],
//         argsSemiColon = [],
//         isSemiColonSeparated, value;
//
//     parserInput.save();
//
//     while (true) {
//         if (prevArgs) {
//             prevArgs = false;
//         } else {
//             value = parsers.detachedRuleset() || this.assignment() || parsers.expression();
//             if (!value) {
//                 break;
//             }
//
//             if (value.value && value.value.length == 1) {
//                 value = value.value[0];
//             }
//
//             argsComma.push(value);
//         }
//
//         if (parserInput.$char(',')) {
//             continue;
//         }
//
//         if (parserInput.$char(';') || isSemiColonSeparated) {
//             isSemiColonSeparated = true;
//             value = (argsComma.length < 1) ? argsComma[0]
//                 : new tree.Value(argsComma);
//             argsSemiColon.push(value);
//             argsComma = [];
//         }
//     }
//
//     parserInput.forget();
//     return isSemiColonSeparated ? argsSemiColon : argsComma;
// },
  }

  ///
  /// Search for
  ///
  ///     Dimension | Color | Quoted | UnicodeDescriptor (U+A5)
  ///
  Node literal() => dimension() ?? color() ?? quoted() ?? unicodeDescriptor();

//2.2.0
//  literal: function () {
//      return this.dimension() ||
//             this.color() ||
//             this.quoted() ||
//             this.unicodeDescriptor();
//  }

  static final RegExp _assignmentRegExp =
      RegExp(r'\w+(?=\s?=)', caseSensitive: false);

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
      return Assignment(key, value);
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

  static final RegExp _urlRegExp =
      RegExp(r'''(?:(?:\\[\(\)'"])|[^\(\)'"])+''', caseSensitive: true);

  ///
  /// Parse url() tokens
  ///
  /// We use a specific rule for urls, because they don't really behave like
  /// standard function calls. The difference is that the argument doesn't have
  /// to be enclosed within a string, so it can't be parsed as an Expression.
  ///
  URL url() {
    final int index = parserInput.i;
    Node value;

    parserInput.autoCommentAbsorb = false;

    if (parserInput.$str('url(') == null) {
      parserInput.autoCommentAbsorb = true;
      return null;
    }

    value = quoted() ??
        variable() ??
        property() ??
        Anonymous(parserInput.$re(_urlRegExp) ?? '');

    parserInput
      ..autoCommentAbsorb = true
      ..expectChar(')');
    return URL(
        (value.value != null) || (value is Variable) || (value is Property)
            ? value
            : Anonymous(value, index: index),
        index: index,
        currentFileInfo: fileInfo);

//3.0.0 20160718
// url: function () {
//     var value, index = parserInput.i;
//
//     parserInput.autoCommentAbsorb = false;
//
//     if (!parserInput.$str("url(")) {
//         parserInput.autoCommentAbsorb = true;
//         return;
//     }
//
//     value = this.quoted() || this.variable() || this.property() ||
//             parserInput.$re(/^(?:(?:\\[\(\)'"])|[^\(\)'"])+/) || "";
//
//     parserInput.autoCommentAbsorb = true;
//
//     expectChar(')');
//
//     return new(tree.URL)((value.value != null ||
//         value instanceof tree.Variable ||
//         value instanceof tree.Property) ?
//         value : new(tree.Anonymous)(value, index), index, fileInfo);
// },
  }

  static final RegExp _variableRegExp =
      RegExp(r'@@?[\w-]+', caseSensitive: true);

  ///
  /// A Variable entity, such as `@fink`, in
  ///
  ///     width: @fink + 2px;
  ///
  /// We use a different parser for variable definitions,
  /// see `parsers.variable`.
  ///
  Node variable() {
    final int index = parserInput.i;
    String name;

    parserInput.save();
    if ((parserInput.currentChar() == '@') &&
        (name = parserInput.$re(_variableRegExp)) != null) {
      final String ch = parserInput.currentChar();
      if (ch == '(' ||
          ch == '[' && !parserInput.prevChar().contains(RegExp(r'\s'))) {
        // this may be a VariableCall lookup
        final Node result = parsers.variableCall(name);
        if (result != null) {
          parserInput.forget();
          return result;
        }
      }
      parserInput.forget();
      return Variable(name, index, fileInfo);
    }
    parserInput.restore();
    return null;

// 3.5.0 20180705
//  variable: function () {
//      var ch, name, index = parserInput.i;
//
//      parserInput.save();
//      if (parserInput.currentChar() === '@' && (name = parserInput.$re(/^@@?[\w-]+/))) {
//          ch = parserInput.currentChar();
//          if (ch === '(' || ch === '[' && !parserInput.prevChar().match(/^\s/)) {
//              // this may be a VariableCall lookup
//              var result = parsers.variableCall(name);
//              if (result) {
//                  parserInput.forget();
//                  return result;
//              }
//          }
//          parserInput.forget();
//          return new(tree.Variable)(name, index, fileInfo);
//      }
//      parserInput.restore();
//  },
  }

  static final RegExp _variableCurlyRegExp =
      RegExp(r'@\{([\w-]+)\}', caseSensitive: true);

  ///
  /// A variable entity using the protective `{}`. Example:
  ///
  ///     @{var}
  ///
  Variable variableCurly() {
    String curly;
    final int index = parserInput.i;

    if (parserInput.currentChar() == '@' &&
        (curly = parserInput.$re(_variableCurlyRegExp, 1)) != null) {
      return Variable('@$curly', index, fileInfo);
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

  static final RegExp _propertyRegExp =
      RegExp(r'\$[\w-]+', caseSensitive: true);

  ///
  /// A Property accessor, such as `$color`, in
  ///
  ///     color: black;
  ///     background-color: $color
  ///
  /// That results in:
  ///
  ///     background-color: black;
  ///
  Property property() {
    String name;
    final int index = parserInput.i;

    if (parserInput.currentChar() == r'$' &&
        (name = parserInput.$re(_propertyRegExp, 1)) != null) {
      return Property(name, index, fileInfo);
    }
    return null;

//3.0.0 20160718
// property: function () {
//     var name, index = parserInput.i;
//
//     if (parserInput.currentChar() === '$' && (name = parserInput.$re(/^\$[\w-]+/))) {
//         return new(tree.Property)(name, index, fileInfo);
//     }
// },
  }

  static final RegExp _propertyCurlyRegExp =
      RegExp(r'\$\{([\w-]+)\}', caseSensitive: true);

  ///
  /// A property entity using the protective `{}`. Example:
  ///
  ///     ${prop}
  ///
  Property propertyCurly() {
    String curly;
    final int index = parserInput.i;

    if (parserInput.currentChar() == r'$' &&
        (curly = parserInput.$re(_propertyCurlyRegExp, 1)) != null) {
      return Property('\$$curly', index, fileInfo);
    }
    return null;

//3.0.0 20160718
// propertyCurly: function () {
//     var curly, index = parserInput.i;
//
//     if (parserInput.currentChar() === '$' && (curly = parserInput.$re(/^\$\{([\w-]+)\}/))) {
//         return new(tree.Property)("$" + curly[1], index, fileInfo);
//     }
// },
  }

  static final RegExp _colorRegExp = RegExp(
      r'#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3,4})([\w.#\[])?',
      caseSensitive: true);
  ///
  /// A Hexadecimal color
  ///
  ///     #4F3C2F
  ///
  /// `rgb` and `hsl` colors are parsed through the `entities.call` parser.
  ///
  /// Formats:
  ///
  ///     #rgb, #rgba, #rrggbb, #rrggbbaa,
  ///
  Color color() {
    Match rgb;
    parserInput.save();

    if (parserInput.currentChar() == '#' &&
        (rgb = parserInput.$reMatch(_colorRegExp)) != null) {
      if (rgb[2] == null) {
        parserInput.forget();
        return Color(rgb[1], null, rgb[0]);
      }
    }

    parserInput.restore();
    return null;

// 3.9.0 20190711
//  color: function () {
//      var rgb;
//      parserInput.save();
//
//      if (parserInput.currentChar() === '#' && (rgb = parserInput.$re(/^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3,4})([\w.#\[])?/))) {
//          if (!rgb[2]) {
//              parserInput.forget();
//              return new(tree.Color)(rgb[1], undefined, rgb[0]);
//          }
//      }
//      parserInput.restore();
//  },
  }

  static final RegExp _colorKeywordRegExp =
      RegExp(r'[_A-Za-z-][_A-Za-z0-9-]+', caseSensitive: true);

  ///
  /// Search for a named color, such as `blue`.
  ///
  /// The colors list is in `src/data/colors.dart`
  ///
  Color colorKeyword() {
    parserInput.save();

    final bool autoCommentAbsorb = parserInput.autoCommentAbsorb;
    parserInput.autoCommentAbsorb = false;
    final String k = parserInput.$re(_colorKeywordRegExp);
    parserInput.autoCommentAbsorb = autoCommentAbsorb;

    if (k == null) {
      parserInput.forget();
      return null;
    }

    parserInput.restore();
    final Color color = Color.fromKeyword(k);

    if (color != null) {
      parserInput.$str(k);
      return color;
    }
    return null;

//2.6.1 20160423
// colorKeyword: function () {
//     parserInput.save();
//     var autoCommentAbsorb = parserInput.autoCommentAbsorb;
//     parserInput.autoCommentAbsorb = false;
//     var k = parserInput.$re(/^[_A-Za-z-][_A-Za-z0-9-]+/);
//     parserInput.autoCommentAbsorb = autoCommentAbsorb;
//     if (!k) {
//         parserInput.forget();
//         return;
//     }
//     parserInput.restore();
//     var color = tree.Color.fromKeyword(k);
//     if (color) {
//         parserInput.$str(k);
//         return color;
//     }
// },
  }

  static final RegExp _dimensionRegExp =
      RegExp(r'([+-]?\d*\.?\d+)(%|[a-z_]+)?', caseSensitive: false);

  ///
  /// A Dimension, that is, a number and a unit
  ///
  ///     0.5em
  ///     95%
  ///
  Dimension dimension() {
    if (parserInput.peekNotNumeric()) return null;

    final List<String> value = parserInput.$re(_dimensionRegExp);
    return value != null ? Dimension(value[1], value[2]) : null;

//2.5.3 20151207
//  dimension: function () {
//      if (parserInput.peekNotNumeric()) {
//          return;
//      }
//
//      var value = parserInput.$re(/^([+-]?\d*\.?\d+)(%|[a-z_]+)?/i);
//      if (value) {
//          return new(tree.Dimension)(value[1], value[2]);
//      }
//  }
  }

  static final RegExp _unicodeDescriptorRegExp =
      RegExp(r'U\+[0-9a-fA-F?]+(\-[0-9a-fA-F?]+)?', caseSensitive: true);

  ///
  /// A unicode descriptor, as is used in unicode-range, such as:
  ///
  ///     U+0??  or U+00A1-00A9
  ///
  UnicodeDescriptor unicodeDescriptor() {
    final String ud = parserInput.$re(_unicodeDescriptorRegExp, 0);
    return ud != null ? UnicodeDescriptor(ud) : null;

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

  static final RegExp _javascriptRegExp =
      RegExp(r'[^`]*`', caseSensitive: true);

  ///
  /// JavaScript code to be evaluated
  ///
  ///     window.location.href
  ///
  /// JavaScript evaluation is not supported.
  ///
  JavaScript javascript() {
    final int index = parserInput.i;
    String js;

    parserInput.save();

    final String escape = parserInput.$char('~');
    final String jsQuote = parserInput.$char('`');

    if (jsQuote == null) {
      parserInput.restore();
      return null;
    }

    js = parserInput.$re(_javascriptRegExp);
    if (js != null) {
      parserInput.forget();
      return JavaScript(js.substring(0, js.length - 1),
          escaped: escape != null, index: index, currentFileInfo: fileInfo);
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
