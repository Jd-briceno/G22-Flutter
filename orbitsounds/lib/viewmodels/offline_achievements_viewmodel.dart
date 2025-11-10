import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfflineAchievementsService {
  static final OfflineAchievementsService _instance = OfflineAchievementsService._internal();
  factory OfflineAchievementsService() => _instance;
  OfflineAchievementsService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _getCurrentUserId() => _auth.currentUser?.uid ?? "guest";

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// 💾 Guardar logro localmente (si no hay conexión)
  Future<void> cacheAchievement(String genreName, Map<String, String> achievement) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_achievements') ?? [];
    final serialized = "$genreName|${achievement['title']}|${achievement['icon']}";
    if (!cached.contains(serialized)) {
      cached.add(serialized);
      await prefs.setStringList('cached_achievements', cached);
      print("📴 Logro cacheado offline: $genreName");
    }
  }

  /// ☁️ Guardar logro online (o cachear si falla)
  Future<void> saveAchievementOnline(String genreName, Map<String, String> achievement) async {
    final uid = _getCurrentUserId();
    final achievementsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements');

    try {
      // 🚀 Intentar guardar directamente (Firestore lo cachea offline si no hay red)
      await achievementsRef.add({
        'target': genreName,
        'title': achievement['title'],
        'icon': achievement['icon'],
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      print("☁️ Logro guardado (online o en caché): $genreName");
    } catch (e) {
      // ❌ Si falla, se guarda localmente
      print("⚠️ Error al guardar logro online ($genreName): $e");
      await cacheAchievement(genreName, achievement);
    }
  }

  /// 🔄 Sincronizar logros cacheados cuando vuelva la conexión
  Future<void> syncCachedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_achievements') ?? [];
    if (cached.isEmpty) return;

    if (await _isOnline()) {
      for (final item in cached) {
        final parts = item.split('|');
        if (parts.length < 3) continue;
        final genreName = parts[0];
        final title = parts[1];
        final icon = parts[2];

        await saveAchievementOnline(genreName, {
          'title': title,
          'icon': icon,
        });
      }
      await prefs.remove('cached_achievements');
      print("🔄 Logros offline sincronizados (${cached.length})");
    }
  }

  /// 🌐 Escucha cuando el usuario se reconecta
  void startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print("🌐 Reconectado: sincronizando logros...");
        syncCachedAchievements();
      }
    });
  }
}
