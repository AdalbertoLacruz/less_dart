// source: less/constants.js 3.7.1 20180718

///
/// How to process math
///
class MathConstants {
  /// Eagerly try to solve all operations
  static const int always = 0;

  /// Require parens for division "/"
  static const int parensDivision = 1;

  /// Require parens for all operations. Same as strict.
  static const int parens = 2;

  /// Legacy strict behavior (super-strict)
  static const int strictLegacy = 3;
}

///
/// Rewrite URLS to make the relative to the base less file
///
class RewriteUrlsConstants {
  /// Don't rewrite
  static const int off = 0;
  /// Rewrites only the URLS starting with '.'
  static const int local = 1;
  /// Rewrites all URLS
  static const int all = 2;
}
