import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/playlist_model.dart';
import '../models/track_model.dart';
import 'ares_service.dart';
import 'spotify_service.dart';
import 'package:hive/hive.dart';

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
      // 1) Pedir canciones "ideales" a Ares (Gemini)
      final aiTracks = await _ares.generatePlaylist(
        likedGenres: likedGenres,
        likedSongs: likedSongs,
        interests: interests,
      );

      if (aiTracks.isEmpty) return null;

      // 2) Enriquecer con Spotify buscando cada canción
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

      // 3) Construir playlist final en un isolate
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
      // 1) Pedir canciones a Ares según el prompt de mood
      final aiTracks = await _ares.generatePlaylistFromMood(moodPrompt);

      if (aiTracks.isEmpty) return null;

      // 2) Buscar canciones reales en Spotify
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

      // 3) Crear la playlist final en segundo plano
      return await compute(_buildPlaylistInBackground, {
        'id': _uuid.v4(),
        'tracks': finalTracks,
        'title': "Mood Playlist 🎭",
        'description':
            "Playlist generada por Ares según tu estado de ánimo o deseo musical",
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

  /// 📦 Guarda la última playlist generada (cache offline)
  Future<void> cachePlaylist(Playlist playlist) async {
    final box = await Hive.openBox('trackCache');
    await box.put('last_ares_playlist', playlist.toMap());
    debugPrint("💾 Playlist cached");
  }

  /// 📦 Cargar playlist cacheada (cuando no hay internet)
  Future<Playlist?> getCachedPlaylist() async {
    final box = await Hive.openBox('trackCache');
    final data = box.get('last_ares_playlist');
    if (data == null) return null;

    try {
      return Playlist.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint("❌ Error reading cached playlist: $e");
      return null;
    }
  }
}
