import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MoodEchoService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  final String model = "gemini-2.5-flash";

  /// 🌙 Genera el análisis Mood Echo (con manejo de vacíos y contexto cultural)
  Future<void> generateMoodEcho() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("⚠️ No user logged in.");

    final firestore = FirebaseFirestore.instance;

    // 1️⃣ Obtener perfil del usuario
    final userDoc = await firestore.collection("users").doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final nickname = (userData["nickname"] ?? userData["fullName"] ?? "User").toString();
    final nationality = userData["nationality"]?["name"] ?? "Unknown";
    final flag = userData["nationality"]?["flag"] ?? "";
    final gender = userData["gender"] ?? "Neutral";
    final interests = (userData["interests"] is List && userData["interests"].isNotEmpty)
        ? (userData["interests"] as List).join(", ")
        : "Music, emotions, and introspection";

    // 2️⃣ Obtener última sesión
    final sessionSnap = await firestore
        .collection("users")
        .doc(user.uid)
        .collection("sessions")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (sessionSnap.docs.isEmpty) {
      print("⚠️ No sessions found, skipping Mood Echo generation.");
      return;
    }

    final sessionDoc = sessionSnap.docs.first;
    final sessionRef = sessionDoc.reference;
    final data = sessionDoc.data();

    final emotions = (data["emotions"] as List?)?.cast<String>() ?? [];
    final notes = (data["notes"] ?? "").toString().trim();
    final tracks = (data["tracks"] as List?)
            ?.map((t) => (t as Map)["title"])
            .whereType<String>()
            .toList() ??
        [];

    // 3️⃣ Obtener constelación (puede estar vacía)
    String desiredEmotion = "Unknown";
    try {
      final constellationSnap = await sessionRef
          .collection("constellation")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (constellationSnap.docs.isNotEmpty) {
        desiredEmotion = constellationSnap.docs.first.data()["emotion"] ?? "Unknown";
      }
    } catch (_) {
      desiredEmotion = "Unknown";
    }

    // 🧩 Si todo está vacío, no generamos nada
    if (emotions.isEmpty && tracks.isEmpty && notes.isEmpty && desiredEmotion == "Unknown") {
      print("⚠️ Insufficient data for Mood Echo.");
      await sessionRef.update({
        "mood_echo": {
          "summary": "Not enough data to analyse mood.",
          "reflection": "No emotions, notes, or songs were registered for this session.",
          "alignment_score": 0.0,
          "musical_tone": "neutral silence",
          "recommendation": "Try logging how you feel or adding songs next time."
        },
        "mood_echo_generated_at": FieldValue.serverTimestamp(),
      });
      return;
    }

    // 4️⃣ Preparar prompt con valores seguros
    final safeEmotions = emotions.isNotEmpty ? emotions.join(", ") : "Unknown";
    final safeNotes = notes.isNotEmpty ? notes : "(No notes provided)";
    final safeTracks = tracks.isNotEmpty ? tracks.join(", ") : "(No tracks)";
    final safeDesired = desiredEmotion.isNotEmpty ? desiredEmotion : "Unknown";

    final prompt = '''
You are MOOD ECHO 🌙, an empathic and culturally-sensitive emotional analyst for the Longbook.

User: "$nickname"
Country: $nationality $flag
Gender: $gender
Interests: $interests

Tone rules:
- Japan → poetic, balanced, tranquil metaphors.
- Latin America → warm, emotive, passionate.
- USA/UK → introspective, concise, reflective.
- Otherwise → neutral and empathetic.

Session data:
Felt emotions: $safeEmotions
Desired emotion (constellation): $safeDesired
User notes: "$safeNotes"
Tracks listened: $safeTracks

If some data is missing, focus on what is available and produce a graceful, minimal analysis.

Return a **VALID JSON ONLY** with this exact structure:

{
  "summary": "short neutral summary (max 1 sentence)",
  "reflection": "3 poetic sentences maximum",
  "alignment_score": 0.0-1.0,
  "musical_tone": "short musical description",
  "recommendation": "concise empathetic suggestion"
}
''';

    // 5️⃣ Petición a Gemini
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey");

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
      print("❌ Gemini error ${response.statusCode}: ${response.body}");
      return;
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
    final jsonText = match != null ? match.group(0)! : rawText;

    Map<String, dynamic> moodEcho = {};
    try {
      moodEcho = jsonDecode(jsonText);
    } catch (e) {
      print("⚠️ Could not parse Mood Echo JSON: $e");
      moodEcho = {
        "summary": "Could not interpret your data.",
        "reflection": "Your emotional data could not be analysed this time.",
        "alignment_score": 0.0,
        "musical_tone": "indeterminate",
        "recommendation": "Try writing a short note next session."
      };
    }

    // 6️⃣ Guardar el resultado
    await sessionRef.update({
      "mood_echo": moodEcho,
      "mood_echo_generated_at": FieldValue.serverTimestamp(),
    });

    print("✅ Mood Echo generado y guardado correctamente: $moodEcho");
  }
}
