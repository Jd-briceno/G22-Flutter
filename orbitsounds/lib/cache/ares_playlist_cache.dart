// ares_playlist_cache.dart
import 'package:hive/hive.dart';
import '../models/playlist_model.dart';

class AresPlaylistCache {
  static const String _boxName = 'aresMixLRU';
  static const int _maxItems = 3;

  ///----------- 🔥 FIX 1: deep cast seguro --------------///
  static Map<String, dynamic> _deepCast(Map<dynamic, dynamic> data) {
    return data.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepCast(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) {
            if (e is Map) return _deepCast(e);
            return e;
          }).toList(),
        );
      } else {
        return MapEntry(key.toString(), value);
      }
    });
  }

  ///----------- SAVE ------------///
  static Future<void> save(Playlist playlist) async {
    final box = await Hive.openBox(_boxName);
    final order = box.get('order', defaultValue: <String>[]) as List<String>;

    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(key, playlist.toMap());

    order.remove(key);
    order.insert(0, key);

    while (order.length > _maxItems) {
      final removed = order.removeLast();
      await box.delete(removed);
    }

    await box.put('order', order);
  }

  ///------------ GET LAST -------------///
  static Future<Playlist?> getLatest() async {
    final box = await Hive.openBox(_boxName);
    final order = List<String>.from(box.get('order', defaultValue: <String>[]));

    if (order.isEmpty) return null;

    final key = order.first;
    final cached = box.get(key);

    if (cached is Map) {
      final fixed = _deepCast(cached);
      return Playlist.fromMap(fixed);
    }

    return null;
  }

  ///------------ GET ALL --------------///
  static Future<List<Playlist>> getAll() async {
    final box = await Hive.openBox(_boxName);
    final order = List<String>.from(box.get('order', defaultValue: <String>[]));

    return order.map((key) {
      final cached = box.get(key);
      if (cached is Map) {
        final fixed = _deepCast(cached);
        return Playlist.fromMap(fixed);
      }
      return null;
    }).whereType<Playlist>().toList();
  }
}
