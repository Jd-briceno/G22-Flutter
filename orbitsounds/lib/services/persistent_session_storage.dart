// persistent_session_storage.dart

import 'package:hive/hive.dart';

class PersistentSessionStorage {
  static const String _boxName = 'session_cache';

  /// Guarda una sesión serializada (mapa) con una clave
  static Future<void> saveSession(String sessionKey, Map<String, dynamic> sessionMap) async {
    final box = await Hive.openBox(_boxName);
    await box.put(sessionKey, sessionMap);
  }

  /// Carga una sesión previamente guardada, devuelve null si no existe
  static Future<Map<String, dynamic>?> loadSession(String sessionKey) async {
    final box = await Hive.openBox(_boxName);
    final data = box.get(sessionKey);
    if (data != null && data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Elimina una sesión guardada
  static Future<void> deleteSession(String sessionKey) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(sessionKey);
  }

  /// Limpia todas las sesiones guardadas (útil para logout, debug, etc.)
  static Future<void> clearAll() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
