library nodejs.less;

import 'dart:async';

part 'base64_string.dart';
part 'console.dart';
part 'path.dart';
part 'reg_exp_extended.dart';

/// resolves null as false. #
bool isTrue(bool value) => value != null ? value : false;

/// resolves null as empty. Return false if null.
/// Supports String, List, Map. #
bool isNotEmpty(value){
  if (value is String) return value.isNotEmpty;
  if (value is List) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return false;
}

/// if [value] is null return default
getValueOrDefault(value, defaultValue) {
  if (value == null) {
    return defaultValue;
  } else {
    return value;
  }
}

///
/// Convert n to String, without decimal .0 if possible
/// if n == 0.1 returns '0.1'
/// if n == 0.0 returns '0'
///
String numToString(num n) {
  int i = n.toInt();
  return (n == i) ? i.toString() : n.toString();
}