import 'package:hive/hive.dart';
import '../models/session_data.dart';

class SessionCache {
  static const String _boxName = 'sessionLRU';
  static const int _maxItems = 5;

  static Future<void> save(SessionData data) async {
    final box = await Hive.openBox(_boxName);
    final order = box.get('order', defaultValue: <String>[]) as List<String>;

    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, data.toMap());

    order.remove(key);
    order.insert(0, key);

    while (order.length > _maxItems) {
      final removed = order.removeLast();
      await box.delete(removed);
    }

    await box.put('order', order);
  }

  static Future<SessionData?> getLatest() async {
    final box = await Hive.openBox(_boxName);
    final order = box.get('order', defaultValue: <String>[]) as List<String>;
    if (order.isEmpty) return null;
    final key = order.first;
    final cached = box.get(key);
    if (cached is Map) return SessionData.fromMap(Map<String, dynamic>.from(cached));
    return null;
  }
}
