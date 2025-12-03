hive_service:import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('settings');
    await Hive.openBox('trackCache'); // 🆕 Box para caché de canciones
  }

  static Box get settingsBox => Hive.box('settings');
  static Box get trackCacheBox => Hive.box('trackCache');

  // ⚙️ Preferencias de usuario
  static void setRememberMe(bool value) => settingsBox.put('rememberMe', value);
  static bool getRememberMe() => settingsBox.get('rememberMe', defaultValue: false);

  static void setThemeMode(bool darkMode) => settingsBox.put('darkMode', darkMode);
  static bool isDarkMode() => settingsBox.get('darkMode', defaultValue: false);

  // 💾 Métodos de caché de tracks
  static Future<void> saveTracks(String playlistId, List<Map<String, dynamic>> tracks) async {
    await trackCacheBox.put(playlistId, tracks);
  }

  static List<Map<String, dynamic>>? getTracks(String playlistId) {
    final cached = trackCacheBox.get(playlistId);
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return null;
  }

  static Future<void> clearTrackCache() async {
    await trackCacheBox.clear();
  }

  static Future<void> saveLastMoodPlaylist(List<Map<String, dynamic>> tracks) async {
    await trackCacheBox.put('mood_last', tracks);
  }

  static List<Map<String, dynamic>>? getLastMoodPlaylist() {
    final cached = trackCacheBox.get('mood_last');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return null;
  }

  static Future<void> clearMoodCache() async {
    final keys = trackCacheBox.keys.where((k) => k.toString().startsWith("mood_")).toList();
    for (var key in keys) {
      await trackCacheBox.delete(key);
    }
  }

  static Future<void> saveLastAresMix(String cacheKey, List<Map<String, dynamic>> tracks) async {
    await trackCacheBox.put('ares_mix_$cacheKey', tracks);
  }

  static List<Map<String, dynamic>>? getLastAresMix(String cacheKey) {
    final cached = trackCacheBox.get('ares_mix_$cacheKey');
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }
    return null;
  }

  // (opcional) limpiar cache de mixes Ares
  static Future<void> clearAresMixCache() async {
    final keys = trackCacheBox.keys.where((k) => k.toString().startsWith('ares_mix_')).toList();
    for (var key in keys) {
      await trackCacheBox.delete(key);
    }
  }
}
