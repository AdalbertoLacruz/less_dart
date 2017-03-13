part of visitor.less;

///
/// Map<String, bool> used for recursionDetector and onceFileDetectionMap
///
class ImportDetector {
  Map<String, bool> _item = <String, bool>{};

  /// Copy the [source] importDetector
  void addAll(ImportDetector source) => _item.addAll(source._item);

  bool containsKey(String key) => _item.containsKey(key);

  Iterable<String> get keys => _item.keys;

  void operator []=(String key, bool value) {
    _item[key] = value;
  }

  //--- static ----

  ///
  /// Returns a new ImportDector copy of [source]
  ///
  static ImportDetector clone(ImportDetector source) {
    ImportDetector result = new ImportDetector();
    return (source != null) ? (result..addAll(source)) : result;
  }

  ///
  /// Returns a not null [detector]
  ///
  static ImportDetector own(ImportDetector detector) {
    return (detector != null) ? detector : new ImportDetector();
  }
}
