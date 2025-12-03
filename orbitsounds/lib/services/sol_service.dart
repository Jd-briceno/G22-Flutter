import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/celestial_signal.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

Map<String, dynamic> parseGeminiJson(String rawText) {
  // 🧹 Limpieza
  String clean = rawText.trim();

  final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
  if (match != null) clean = match.group(0)!;

  try {
    return json.decode(clean);
  } catch (_) {
    return {
      "summary": clean.replaceAll(RegExp(r'[\{\}\[\]"]'), '').trim(),
      "reflection": ""
    };
  }
}

class SolService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  final String model = "gemini-2.0-flash";

  Future<Map<String, dynamic>> analyzeWeeklyEmotions({
    required List<String> emotions,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception("🚫 GEMINI_API_KEY no está configurada en el .env");
    }

    // 📘 Generar descripción de constelaciones
    final details = emotions.map((emotion) {
      final entry = constellationInfo.entries.firstWhere(
        (e) => e.value["emotion"] == emotion,
        orElse: () => MapEntry("?", {
          "name": "Unknown",
          "meaning": "No data available.",
          "symbolism": "Unknown meaning."
        }),
      );
      final name = entry.value["name"];
      final meaning = entry.value["meaning"];
      final symbolism = entry.value["symbolism"];
      return "$name → $meaning ($symbolism)";
    }).join("\n");

    // 🌞 Prompt principal
    final prompt = '''
Eres SOL 🌞, el analista emocional del diario Longbook de Orbitsounds.
Analiza las emociones y constelaciones que el usuario ha manifestado recientemente.
Cada constelación representa una emoción y su simbolismo espiritual.

Datos disponibles:
$details

Tu tarea:
- Resume el estado emocional general de la semana.
- Escribe un mensaje introspectivo breve, empático y poético.
- Devuelve SOLO un JSON con este formato exacto, en inglés británico:
{
  "summary": "breve descripción poética de la semana",
  "reflection": "mensaje introspectivo o consejo emocional"
}
''';

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("❌ Error ${response.statusCode}: ${response.body}");
    }

    final decoded = json.decode(response.body);
    final rawText = decoded["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

    // ✅ Usa isolate para parsear
    final result = await compute<String, Map<String, dynamic>>(
      parseGeminiJson,
      rawText,
    );
    return result;
  }

  Future<String> generateZenMessage(List<String> emotions) async {
    if (apiKey == null) {
      throw Exception("GEMINI_API_KEY no está configurada");
    }

    final emotionList = emotions.join(", ");

    final prompt = '''
  Eres SOL ☀️, el guía zen emocional de Orbitsounds.
  Genera un mensaje muy breve (máximo 2 líneas), poético, suave y calmante.

  Debe estar basado en estas emociones:
  $emotionList

  El mensaje debe:
  - sonar meditativo
  - ser empático
  - NO juzgar
  - NO dar órdenes fuertes
  - ser adecuado para una mini meditación de 1 minuto

  Solo devuelve el texto, sin explicación adicional, en inglés británico.
  ''';

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    final decoded = json.decode(response.body);
    final raw = decoded["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
    return raw.trim();
  }

  Future<void> cacheLastSolResponse(Map<String, dynamic> response) async {
    final box = await Hive.openBox('solCache');
    await box.put('last_sol_response', response);
  }

  Future<Map<String, dynamic>?> getLastSolResponse() async {
    final box = await Hive.openBox('solCache');
    final cached = box.get('last_sol_response');
    if (cached != null && cached is Map<String, dynamic>) {
      return Map<String, dynamic>.from(cached);
    }
    return null;
  }

}
