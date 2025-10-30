import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AresService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  /// 🎧 Genera playlist basada en gustos del usuario
  Future<List<Map<String, String>>> generatePlaylist({
    required List<String> likedGenres,
    required List<String> likedSongs,
    required List<String> interests,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
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

  /// 🧠 Nueva función: genera playlist desde una descripción emocional o conversacional
  Future<List<Map<String, String>>> generatePlaylistFromMood(String moodPrompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
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
}
