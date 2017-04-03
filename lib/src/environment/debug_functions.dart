part of environment.less;

int debugCounter = 0;

///
/// check type
/// Example:  `isType(ctxSelectors, 'Selector', isListList: true);`
///
bool isType(dynamic value, String type, {bool isList = false, bool isListList = false}) {
  final bool  _isList = isList || isListList;
  bool        result = true;

  if (value == null) return true;

  if (!_isList && value.runtimeType.toString() == type) return true;

  if (_isList && value is List) {
    for (int i = 0; i < value.length; i++) {
      if (value[i] == null) continue;
      if (isListList) {
        result = result && isType(value[i], type, isList: true);
      } else {
        if (value[i].runtimeType.toString() != type) {
          result = false;
          print ('No $type: ${value[i].runtimeType} (${debugCounter++})');
        }
      }
    }
  } else {
    result = false;
  }

  return result;
}
