import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import 'ares_service.dart';
import 'spotify_service.dart';

class AresPlaylistGeneratorService {
  final AresService _ares = AresService();
  final SpotifyService _spotify = SpotifyService();
  final _uuid = const Uuid();

  /// 🔹 StreamController: emite el progreso (cada canción encontrada)
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  /// ✅ Usa Isolate (compute) para generar la playlist en segundo plano
  Future<Playlist?> generatePersonalizedPlaylist({
    required List<String> likedGenres,
    required List<String> likedSongs,
    required List<String> interests,
  }) async {
    try {
      // 🔸 Paso 1: Pedir a la IA las canciones sugeridas
      final aiTracks = await _ares.generatePlaylist(
        likedGenres: likedGenres,
        likedSongs: likedSongs,
        interests: interests,
      );

      if (aiTracks.isEmpty) return null;

      // 🔸 Paso 2: buscar detalles en paralelo usando Future.wait (más rápido)
      final futures = aiTracks.map((song) async {
        final query = "${song['title']} ${song['artist']}";
        final results = await _spotify.searchTracks(query);
        return results.isNotEmpty ? results.first : null;
      }).toList();

      int completed = 0;
      final List<Track> finalTracks = [];

      // 🔸 Paso 3: Ejecutar todas las búsquedas en paralelo con progreso
      for (final future in futures) {
        final track = await future;
        completed++;
        _progressController.add(completed / futures.length);
        if (track != null) finalTracks.add(track);
      }

      if (finalTracks.isEmpty) return null;

      // 🔸 Paso 4: Generar Playlist en segundo plano (Isolate)
      return await compute(_buildPlaylistInBackground, {
        'id': _uuid.v4(),
        'tracks': finalTracks,
      });
    } catch (e) {
      debugPrint("❌ Error generando playlist: $e");
      return null;
    } finally {
      _progressController.add(1.0);
    }
  }

  /// 🧠 Función que corre en otro hilo (Isolate)
  static Playlist _buildPlaylistInBackground(Map<String, dynamic> data) {
    final tracks = data['tracks'] as List<Track>;
    return Playlist(
      id: data['id'] as String,
      title: "Recomendaciones de Ares",
      description: "Playlist creada por Ares según tus gustos 🎧",
      coverUrl: tracks.first.albumArt,
      tracks: tracks,
    );
  }

  void dispose() {
    _progressController.close();
  }
}
