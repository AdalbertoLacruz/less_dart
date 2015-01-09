part of nodejs.less;

class RegExpExtended {
  String pattern;
  bool caseSensitive = true;
  bool global = false;
  RegExp _thisRE;

  ///
  /// flags:
  ///   g : global (for replace)
  ///   i : case insensible
  RegExpExtended(String this.pattern, [String flags]) {
    if (flags != null) {
      caseSensitive = !flags.contains('i');
      global = flags.contains('g');
    }
    _thisRE = new RegExp(pattern, caseSensitive: caseSensitive);
  }

  ///
  /// replace [source] with [replacement] attending global flag.
  /// [replacemnt] could contain $n, notation.
  /// Don't support:
  ///   $& -   the matched substring.
  ///   $` -  the portion of the string that precedes the matched substring.
  ///   $' -  the portion of the string that follows the matched substring.
  /// Example:
  ///   RegExpExtended r = new RegExpExtended(r'(string)\.$');
  ///   String re = r.replace('This is a string.', r'new $1.');
  ///   re == 'This is a new string.'
  ///
  String replace(String source, String replacement) {
    RegExp dollar = new RegExp(r'\$\d+');
    int i;
    Match match;
    String dollarN;

    if (dollar.hasMatch(replacement)) {
      match = _thisRE.firstMatch(source);
      if (match != null) {
        for (i = 0; i <= match.groupCount; i++) {
          dollarN = '\$' + i.toString();
          replacement = replacement.replaceAll(dollarN, match[i]);
        }
      }
    }

    if (global) {
      return source.replaceAll(_thisRE, replacement);
    } else {
      return source.replaceFirst(_thisRE, replacement);
    }
  }

  ///
  /// String map(Match m) => replacement
  /// Depending on flag g uses replaceFirst or replaceAll
  ///
  String replaceMap(String source, Function map){
    Match match = _thisRE.firstMatch(source);
    if (match != null) {
      String replacement = map(match);
      if (global) {
        return source.replaceAll(_thisRE, replacement);
      } else {
        return source.replaceFirst(_thisRE, replacement);
      }
    }
    return source;
  }
}