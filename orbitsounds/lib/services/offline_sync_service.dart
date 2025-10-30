import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final _auth = FirebaseAuth.instance;
  final _analytics = FirebaseAnalytics.instance;

  String _getCurrentUserId() => _auth.currentUser?.uid ?? "guest";

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncCachedEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_emotions') ?? [];
    if (cached.isEmpty) return;

    if (await _isOnline()) {
      for (final e in cached) {
        await FirebaseFirestore.instance.collection('emotions').add({
          "emotion": e,
          "timestamp": FieldValue.serverTimestamp(),
          "userId": _getCurrentUserId(),
        });
      }
      await prefs.remove('cached_emotions');
      print("🔄 Emociones offline sincronizadas (${cached.length})");
    }
  }

  Future<void> syncCachedCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('cached_emotion_collections') ?? [];
    if (cached.isEmpty) return;

    if (await _isOnline()) {
      for (final data in cached) {
        final emotions = data.split('|');
        await FirebaseFirestore.instance.collection("emotions_collections").add({
          "emotions": emotions,
          "timestamp": FieldValue.serverTimestamp(),
          "userId": _getCurrentUserId(),
        });
      }
      await prefs.remove('cached_emotion_collections');
      print("🔄 Colecciones sincronizadas (${cached.length})");
    }
  }

  Future<void> syncCachedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSessions = prefs.getStringList('cached_sessions') ?? [];
    if (cachedSessions.isEmpty) return;

    if (await _isOnline()) {
      final userId = _getCurrentUserId();

      for (final sessionId in cachedSessions) {
        final emotions =
            prefs.getStringList('cached_session_emotions_$sessionId') ?? [];
        if (emotions.isEmpty) continue;

        final sessionRef = FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("sessions")
            .doc(sessionId);

        await sessionRef.set({
          "sessionId": sessionId,
          "userId": userId,
          "timestamp": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        for (final emotion in emotions) {
          await sessionRef.collection("constellation").add({
            "emotion": emotion,
            "source": "Constellation",
            "timestamp": FieldValue.serverTimestamp(),
          });
        }

        await prefs.remove('cached_session_emotions_$sessionId');
        print("✅ Sesión sincronizada con ${emotions.length} emociones: $sessionId");
      }

      await prefs.remove('cached_sessions');
      print("🔄 Todas las sesiones sincronizadas con subcolección 'constellation'");
    }
  }


  void startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        print("🌐 Conectado: sincronizando datos pendientes...");
        syncCachedEmotions();
        syncCachedCollections();
        syncCachedSessions();
      }
    });
  }
}
