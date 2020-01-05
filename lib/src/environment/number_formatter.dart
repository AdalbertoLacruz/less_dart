part of environment.less;

// mostly for color & dimension

///
/// Control how a number (int/double) is converted to string
/// usage: NumberFormatter()..options.format(num)
///
class NumberFormatter {
  /// x.12345678. null do nothing
  /// x.12345000 -> x.12345 remove trailing zeros
  int precision;

  /// 0.x -> .x. false do nothing
  bool removeLeadingZero = false;

  /// try convert as if value is int. false do nothing
  bool tryInt = true;

  ///
  NumberFormatter();

  ///
  /// Return the value adjusted by defined precision
  ///
  num adjustPrecision(num value) {
    if (tryInt && value == value.toInt()) return value;

    // add "epsilon" to ensure numbers like 1.000000005
    // (represented as 1.000000004999....) are properly rounded...
    return precision != null
        ? double.parse((value + 2e-16).toStringAsFixed(precision))
        : value;
  }

  ///
  /// Returns a value as String without decimals if possible. Ex. (1, 1.2, .2)
  ///
  String format(num value, {bool formatted = false}) {
    final _value = formatted ? value : adjustPrecision(value);

    if (tryInt && _value == _value.toInt()) return _value.toInt().toString();

    var result = _value.toString();
    if (removeLeadingZero && result.startsWith('0.')) {
      result = result.replaceFirst('0.', '.');
    }

    return result;
  }
}
