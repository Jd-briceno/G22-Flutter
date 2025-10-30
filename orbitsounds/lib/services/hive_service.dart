import 'package:hive/hive.dart';
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
}
