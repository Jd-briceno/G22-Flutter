import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AresService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<List<Map<String, String>>> generatePlaylist({
    required List<String> likedGenres,
    required List<String> likedSongs,
    required List<String> interests,
  }) async {
    final uri = Uri.parse(
      // ✅ Usa el modelo correcto y actualizado
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    // 🧠 Prompt mejorado: pide exactamente 15 canciones únicas
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

    // 🧹 Limpieza del texto (por si viene con ```json)
    String cleanedText = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    List<Map<String, String>> songs = [];

    try {
      final parsed = jsonDecode(cleanedText) as List<dynamic>;
      songs = parsed
          .map((item) => {
                "title": (item["title"] ?? "").toString(),
                "artist": (item["artist"] ?? "").toString(),
              })
          .toList();
    } catch (e) {
      print("⚠️ No se pudo parsear JSON: $cleanedText");
      return [];
    }

    // 🧩 Asegurar que haya mínimo 15 canciones
    if (songs.length < 15 && songs.isNotEmpty) {
      while (songs.length < 15) {
        songs.addAll(songs.take(15 - songs.length)); // duplica hasta llegar a 15
      }
    }

    // 🔹 Si Gemini devuelve más de 15, solo tomamos las primeras 15
    if (songs.length > 15) {
      songs = songs.take(15).toList();
    }

    print("🎵 Playlist generada con ${songs.length} canciones");
    return songs;
  }
}
