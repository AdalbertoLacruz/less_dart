part of environment.less;

//Only tested [] getValue, getKey
///
class BiMap<K, V> implements Map<K, V> {
  final Map<V, K> _inverse;
  final Map<K, V> _map;

  ///
  BiMap([Map<K, V> other]) : this.from(other ?? <K, V>{});

  ///
  BiMap.from(Map<K, V> other)
      : _map = other,
        _inverse = <V, K>{};

  @override
  V operator [](Object key) => _map[key];

  @override
  void operator []=(K key, V value) {
    _map[key] = value;
    if (_inverse.isNotEmpty) _inverse[value] = key;
  }

  @override
  void addAll(Map<K, V> other) {
    _map.addAll(other);
    if (_inverse.isNotEmpty) {
      other.forEach((K key, V value) {
        _inverse[value] = key;
      });
    }
  }

  ///
  /// Synchronize internal maps
  ///
  void buildInverse() {
    _inverse.clear();
    _map.forEach((K key, V value) {
      _inverse[value] = key;
    });
  }

  @override
  void clear() {
    _map.clear();
    _inverse.clear();
  }

  @override
  bool containsKey(Object key) => _map.containsKey(key);

  @override
  bool containsValue(Object value) => _inverse.isEmpty
      ? _map.containsValue(value)
      : _inverse.containsKey(value);

  @override
  void forEach(void f(K key, V value)) {
    //Potential problems for _inverse
    _inverse.clear();
    _map.forEach(f);
  }

  ///
  /// Given a value, returns the key
  ///
  K getKey(V value) {
    if (_inverse.isEmpty && _map.isNotEmpty) buildInverse(); //synchronize
    return _inverse[value];
  }

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    // Potential problems for _inverse
    _inverse.clear();
    return _map.putIfAbsent(key, ifAbsent);
  }

  @override
  V remove(Object key) {
    if (key == null) return null;
    _inverse.remove(_map[key]);
    return _map.remove(key);
  }

  @override
  Iterable<V> get values => _inverse.isEmpty ? _map.values : _inverse.keys;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
