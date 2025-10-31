import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import 'ares_service.dart';
import 'spotify_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AresPlaylistGeneratorService {
  final AresService _ares = AresService();
  final SpotifyService _spotify = SpotifyService();
  final _uuid = const Uuid();
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

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
        'description':
            "Because you've been listening to \${likedGenres.isNotEmpty ? likedGenres.first : 'your favorite genres'} and songs like \${likedSongs.isNotEmpty ? likedSongs.first : 'your recent favorites'} 🎧",
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
      // ✅ Ensure API key is available
      if (_apiKey.isEmpty) {
        debugPrint("❌ Gemini API key not found. Please check your .env file.");
        return null;
      }

      // ✅ Example call to Gemini API (replace if your _ares service already does this)
      final uri = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are a music recommendation assistant.
Generate a playlist of 10 songs that match the following mood or emotion: "$moodPrompt".
Return the result strictly in valid JSON format as a list of objects, each containing "title" and "artist".
Example:
[
  {"title": "Fix You", "artist": "Coldplay"},
  {"title": "Someone Like You", "artist": "Adele"}
]
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Error Gemini API: ${response.body}");
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final rawText = (data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '') as String;
      if (rawText.isEmpty) return null;

      // 🧩 Convert Gemini response to usable list
      dynamic parsed;
      try {
        parsed = jsonDecode(rawText);
      } catch (_) {
        parsed = rawText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) {
              final parts = line.split('-');
              return {
                'title': parts.first.trim(),
                'artist': parts.length > 1 ? parts.last.trim() : ''
              };
            })
            .toList();
      }

      final List<dynamic> aiTracks = parsed;
      debugPrint("✅ Gemini response parsed: ${aiTracks.length} tracks");

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
