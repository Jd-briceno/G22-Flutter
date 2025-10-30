class LRUCache<K, V> {
  final int capacity;
  final _cache = <K, V>{};
  final _usage = <K>[];

  LRUCache(this.capacity);

  V? get(K key) {
    if (_cache.containsKey(key)) {
      _usage.remove(key);
      _usage.insert(0, key);
      return _cache[key];
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _usage.remove(key);
    } else if (_cache.length >= capacity) {
      final oldestKey = _usage.removeLast();
      _cache.remove(oldestKey);
    }
    _cache[key] = value;
    _usage.insert(0, key);
  }

  void clear() {
    _cache.clear();
    _usage.clear();
  }

  bool contains(K key) => _cache.containsKey(key);
}
