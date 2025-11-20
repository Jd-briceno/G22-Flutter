// lib/services/session_logger_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/track_model.dart';

/// 🪐 SessionLoggerService
/// Registra las canciones escuchadas dentro de una sesión emocional existente.
/// Estructura final Firestore:
/// /users/{uid}/sessions/{sessionId}/tracks[]
class SessionLoggerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Añade una canción al array "tracks" de la sesión indicada.
  Future<void> addTrackToSession({
    required Track track,
    required String sessionId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print("⚠️ Usuario no autenticado.");
        return;
      }

      final sessionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId);

      final trackData = track.toMap();

      await sessionRef.update({
        'tracks': FieldValue.arrayUnion([trackData]),
      });

      print("🎵 Track agregado a la sesión $sessionId: ${track.title}");
    } catch (e) {
      print("⚠️ Error al agregar track a sesión: $e");
    }
  }

  /// 🔹 Elimina un track de la lista si fuera necesario.
  Future<void> removeTrackFromSession({
    required Track track,
    required String sessionId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final sessionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId);

      await sessionRef.update({
        'tracks': FieldValue.arrayRemove([track.toMap()]),
      });

      print("🗑️ Track eliminado de sesión: ${track.title}");
    } catch (e) {
      print("⚠️ Error al eliminar track: $e");
    }
  }

  /// 🔹 Recupera todos los tracks de una sesión (para mostrar en Longbook)
  Future<List<Track>> getTracksFromSession(String sessionId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final sessionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId);

      final snap = await sessionRef.get();
      final data = snap.data();

      if (data == null || data['tracks'] == null) return [];

      final tracks = (data['tracks'] as List<dynamic>)
          .map((e) => Track.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      return tracks;
    } catch (e) {
      print("⚠️ Error obteniendo tracks: $e");
      return [];
    }
  }
}
