import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:melodymuse/services/spotify_service.dart';
import 'package:hive/hive.dart';

class AresService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  /// 🎧 Genera playlist basada en gustos del usuario
  Future<List<Map<String, String>>> generatePlaylist({
    required List<String> likedGenres,
    required List<String> likedSongs,
    required List<String> interests,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );

    final prompt = """
Eres Ares, una IA musical que crea playlists personalizadas según los gustos e intereses del usuario.

Devuelve **SOLO** un JSON válido, con **exactamente 15 canciones únicas**, sin texto adicional, sin ```json, ni explicaciones.

Formato:
[
  {"title": "Nombre canción", "artist": "Artista"},
  {"title": "Otra canción", "artist": "Otro artista"}
]

Intereses del usuario: ${interests.join(", ")}
Géneros favoritos: ${likedGenres.join(", ")}
Canciones que le gustan: ${likedSongs.join(", ")}
""";

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      print("❌ Error Gemini: ${response.body}");
      return [];
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.isEmpty) {
      print("⚠️ Gemini devolvió respuesta vacía.");
      return [];
    }

    String cleanedText = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    try {
      final parsed = jsonDecode(cleanedText) as List<dynamic>;
      List<Map<String, String>> songs = parsed
          .map((item) => {
                "title": (item["title"] ?? "").toString(),
                "artist": (item["artist"] ?? "").toString(),
              })
          .toList();

      // Asegura 15 canciones exactas
      if (songs.length < 15 && songs.isNotEmpty) {
        while (songs.length < 15) {
          songs.addAll(songs.take(15 - songs.length));
        }
      } else if (songs.length > 15) {
        songs = songs.take(15).toList();
      }

      print("🎵 Playlist generada con ${songs.length} canciones");
      return songs;
    } catch (e) {
      print("⚠️ No se pudo parsear JSON: $cleanedText");
      return [];
    }
  }

  Future<void> cacheGeneratedPlaylist(List<Map<String, String>> playlist) async {
      final box = await Hive.openBox('trackCache');
      await box.put('last_ares_playlist', playlist);
    }

    Future<List<Map<String, String>>?> getCachedPlaylist() async {
    final box = await Hive.openBox('trackCache');
    final data = box.get('last_ares_playlist');
    if (data != null) {
      return List<Map<String, String>>.from(data);
    }
    return null;
  }

  /// 🧠 Nueva función: genera playlist desde una descripción emocional o conversacional
  Future<List<Map<String, String>>> generatePlaylistFromMood(String moodPrompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
    );

    final prompt = """
Eres Ares, una IA musical empática que genera playlists según cómo el usuario dice sentirse o cómo quiere sentirse.

Usuario dice: "$moodPrompt"

Crea una playlist de **exactamente 15 canciones únicas** que reflejen o transformen su estado emocional.

Devuelve **solo un JSON válido**, sin texto adicional, sin comentarios, ni ```json```.

Formato:
[
  {"title": "Nombre canción", "artist": "Artista"},
  {"title": "Otra canción", "artist": "Otro artista"}
]
""";

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      print("❌ Error Gemini (mood): ${response.body}");
      return [];
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.isEmpty) {
      print("⚠️ Gemini devolvió respuesta vacía (mood).");
      return [];
    }

    String cleanedText = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    try {
      final parsed = jsonDecode(cleanedText) as List<dynamic>;
      List<Map<String, String>> songs = parsed
          .map((item) => {
                "title": (item["title"] ?? "").toString(),
                "artist": (item["artist"] ?? "").toString(),
              })
          .toList();

      if (songs.length < 15 && songs.isNotEmpty) {
        while (songs.length < 15) {
          songs.addAll(songs.take(15 - songs.length));
        }
      } else if (songs.length > 15) {
        songs = songs.take(15).toList();
      }

      print("🎶 Playlist por estado de ánimo generada con ${songs.length} canciones");
      return songs;
    } catch (e) {
      print("⚠️ Error parseando JSON: $cleanedText");
      return [];
    }
  }

    /// 🪐 SMART FEATURE: Genera 3 playlists inteligentes desde las últimas sesiones reales en Firestore
  Future<List<Map<String, dynamic>>> generateSmartMixesFromFirestore({
    int sessionLimit = 3,
  }) async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final spotify = SpotifyService(); // 🧠 nuevo: usamos Spotify para enriquecer resultados

    if (user == null) {
      print("⚠️ No hay usuario autenticado.");
      return [];
    }

    try {
      print("📡 Buscando últimas $sessionLimit sesiones de ${user.uid}...");
      final sessionsSnapshot = await db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .limit(sessionLimit)
          .get();

      if (sessionsSnapshot.docs.isEmpty) {
        print("⚠️ No se encontraron sesiones recientes.");
        return [];
      }

      // 🔹 Extrae canciones y emociones
      final List<String> allSongs = [];
      final List<String> allEmotions = [];

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final tracks = (data['tracks'] as List<dynamic>? ?? []);
        final emotions = (data['emotions'] as List<dynamic>? ?? []).cast<String>();

        for (var t in tracks) {
          final map = Map<String, dynamic>.from(t);
          final title = map['title']?.toString() ?? '';
          final artist = map['artist']?.toString() ?? '';
          if (title.isNotEmpty && artist.isNotEmpty) {
            allSongs.add("$title by $artist");
          }
        }

        allEmotions.addAll(emotions);
      }

      print("🎶 Se encontraron ${allSongs.length} canciones y ${allEmotions.length} emociones.");

      // 🔹 Prompt para Gemini
      final prompt = """
Eres Ares, el curador musical empático de Orbitsounds.
Tu misión es crear tres playlists distintas inspiradas en las emociones y canciones recientes del usuario.

Contexto del usuario:
Emociones recientes: ${allEmotions.join(", ")}
Canciones escuchadas últimamente: ${allSongs.take(20).join(", ")}

Crea tres playlists:
1️⃣ Rebirth Mix — para transformar el estado emocional hacia uno más luminoso.
2️⃣ Reflection Mix — para introspección y autoconexión.
3️⃣ Energy Surge — para revitalizar el ánimo y la motivación.

Cada playlist debe tener:
- title
- description (breve y poética)
- tracks: lista de 10 canciones (title + artist)

Devuelve SOLO un JSON válido con este formato exacto:

{
  "playlists": [
    {
      "title": "Rebirth Mix",
      "description": "Renace de las cenizas con un sonido esperanzador.",
      "tracks": [
        {"title": "Song A", "artist": "Artist A"},
        {"title": "Song B", "artist": "Artist B"}
      ]
    },
    {
      "title": "Reflection Mix",
      "description": "Canciones suaves que invitan a mirar hacia adentro.",
      "tracks": [...]
    },
    {
      "title": "Energy Surge",
      "description": "Un impulso de energía para conquistar el día.",
      "tracks": [...]
    }
  ]
}

No incluyas texto fuera del JSON.
""";

      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        print("❌ Error de Gemini: ${response.body}");
        return [];
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.isEmpty) {
        print("⚠️ Gemini devolvió texto vacío.");
        return [];
      }

      final cleaned = text
          .replaceAll(RegExp(r'```json', caseSensitive: false), '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(cleaned);
      final playlists =
          (parsed['playlists'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      print("🎧 Gemini devolvió ${playlists.length} playlists, enriqueciendo con Spotify...");

      // 🔹 Enriquecemos cada mix con metadatos reales desde Spotify
      final List<Map<String, dynamic>> enriched = [];

      for (final mix in playlists) {
        final title = mix['title'] ?? 'Untitled';
        final desc = mix['description'] ?? '';
        final rawTracks = (mix['tracks'] as List<dynamic>? ?? []);

        final List<Map<String, dynamic>> fullTracks = [];

        for (var t in rawTracks.take(10)) {
          final songTitle = t['title']?.toString() ?? '';
          final artist = t['artist']?.toString() ?? '';
          if (songTitle.isEmpty) continue;

          final results = await spotify.searchTracks("$songTitle $artist");
          if (results.isNotEmpty) {
            final found = results.first;
            fullTracks.add({
              "title": found.title,
              "artist": found.artist,
              "albumArt": found.albumArt,
              "duration": found.duration,
              "durationMs": found.durationMs,
            });
          } else {
            fullTracks.add({
              "title": songTitle,
              "artist": artist,
              "albumArt": "",
              "duration": "3:00",
              "durationMs": 180000,
            });
          }
        }

        enriched.add({
          "title": title,
          "description": desc,
          "tracks": fullTracks,
        });
      }

      print("✅ Ares generó ${enriched.length} Smart Mixes enriquecidos con Spotify.");
      return enriched;
    } catch (e, st) {
      print("❌ Error en generateSmartMixesFromFirestore: $e");
      print(st);
      return [];
    }
  }
}
