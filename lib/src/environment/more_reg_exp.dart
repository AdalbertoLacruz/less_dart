part of environment.less;

class MoreRegExp {
  bool    caseSensitive = true;
  bool    global = false;
  String  pattern;
  RegExp  _thisRE;

  ///
  /// flags:
  ///   g : global (for replace)
  ///   i : case insensible
  ///
  MoreRegExp(String this.pattern, [String flags]) {
    if (flags != null) {
      caseSensitive = !flags.contains('i');
      global = flags.contains('g');
    }
    _thisRE = new RegExp(pattern, caseSensitive: caseSensitive);
  }

  ///
  /// replace [source] with [replacement] attending global flag.
  /// replacemnt could contain $n, notation.
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
    final RegExp  dollar = new RegExp(r'\$\d+');
    String        dollarN;
    Match         match;
    String        _replacement = replacement;

    if (dollar.hasMatch(_replacement)) {
      match = _thisRE.firstMatch(source);
      if (match != null) {
        for (int i = 0; i <= match.groupCount; i++) {
          // ignore: prefer_interpolation_to_compose_strings
          dollarN = '\$' + i.toString();
          _replacement = _replacement.replaceAll(dollarN, match[i]);
        }
      }
    }

    return global
        ? source.replaceAll(_thisRE, _replacement)
        : source.replaceFirst(_thisRE, _replacement);
  }

  ///
  /// String map(Match m) => replacement
  /// Depending on flag g uses replaceFirst or replaceAll
  ///
  String replaceMap(String source, Function map) {
    final Match match = _thisRE.firstMatch(source);
    if (match != null) {
      final String replacement = map(match);
      return global
        ? source.replaceAll(_thisRE, replacement)
        : source.replaceFirst(_thisRE, replacement);
    }
    return source;
  }
}
