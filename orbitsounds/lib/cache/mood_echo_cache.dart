import 'package:hive/hive.dart';

class MoodEchoCache {
  static const String _boxName = 'moodEchoLRU';
  static const int _maxItems = 5;

  static Future<void> save(Map<String, dynamic> moodEcho) async {
    final box = await Hive.openBox(_boxName);
    final order = box.get('order', defaultValue: <String>[]) as List<String>;

    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, moodEcho);

    order.remove(key);
    order.insert(0, key);

    while (order.length > _maxItems) {
      final removed = order.removeLast();
      await box.delete(removed);
    }

    await box.put('order', order);
  }

  static Future<Map<String, dynamic>?> getLatest() async {
    final box = await Hive.openBox(_boxName);
    final order = box.get('order', defaultValue: <String>[]) as List<String>;
    if (order.isEmpty) return null;
    final key = order.first;
    final cached = box.get(key);
    if (cached is Map) return Map<String, dynamic>.from(cached);
    return null;
  }
}
