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

  // ======================================================
  // 🎧 MÉTODO 1: Playlist basada en gustos del usuario
  // ======================================================
  Future<Playlist?> generatePersonalizedPlaylist({
    required List<String> likedGenres,
    required List<String> likedSongs,
    required List<String> interests,
  }) async {
    try {
      final aiTracks = await _ares.generatePlaylist(
        likedGenres: likedGenres,
        likedSongs: likedSongs,
        interests: interests,
      );

      if (aiTracks.isEmpty) return null;

      final futures = aiTracks.map((song) async {
        final query = "${song['title']} ${song['artist']}";
        final results = await _spotify.searchTracks(query);
        return results.isNotEmpty ? results.first : null;
      }).toList();

      int completed = 0;
      final List<Track> finalTracks = [];

      for (final future in futures) {
        final track = await future;
        completed++;
        _progressController.add(completed / futures.length);
        if (track != null) finalTracks.add(track);
      }

      if (finalTracks.isEmpty) return null;

      return await compute(_buildPlaylistInBackground, {
        'id': _uuid.v4(),
        'tracks': finalTracks,
        'title': "ARES Sound Lab",
        'description': "Playlist creada por Ares según tus gustos 🎧",
      });
    } catch (e) {
      debugPrint("❌ Error generando playlist personalizada: $e");
      return null;
    } finally {
      _progressController.add(1.0);
    }
  }

  // ======================================================
  // 🧠 MÉTODO 2: Playlist generada desde una frase o estado emocional
  // ======================================================
  Future<Playlist?> generateMoodBasedPlaylist(String moodPrompt) async {
    try {
      // 🔹 1. Pedir canciones a Gemini según cómo se siente el usuario
      final aiTracks = await _ares.generatePlaylistFromMood(moodPrompt);

      if (aiTracks.isEmpty) return null;

      // 🔹 2. Buscar canciones reales en Spotify
      final futures = aiTracks.map((song) async {
        final query = "${song['title']} ${song['artist']}";
        final results = await _spotify.searchTracks(query);
        return results.isNotEmpty ? results.first : null;
      }).toList();

      int completed = 0;
      final List<Track> finalTracks = [];

      for (final future in futures) {
        final track = await future;
        completed++;
        _progressController.add(completed / futures.length);
        if (track != null) finalTracks.add(track);
      }

      if (finalTracks.isEmpty) return null;

      // 🔹 3. Crear la playlist final en segundo plano
      return await compute(_buildPlaylistInBackground, {
        'id': _uuid.v4(),
        'tracks': finalTracks,
        'title': "Mood Playlist 🎭",
        'description': "Playlist generada por Ares según tu estado de ánimo o deseo musical",
      });
    } catch (e) {
      debugPrint("❌ Error generando playlist por estado de ánimo: $e");
      return null;
    } finally {
      _progressController.add(1.0);
    }
  }

  // ======================================================
  // ⚙️ Función auxiliar: crea la playlist en un isolate
  // ======================================================
  static Playlist _buildPlaylistInBackground(Map<String, dynamic> data) {
    final tracks = data['tracks'] as List<Track>;
    return Playlist(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      coverUrl: tracks.isNotEmpty ? tracks.first.albumArt : "",
      tracks: tracks,
    );
  }

  void dispose() {
    _progressController.close();
  }
}
