// mood_echo_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // para compute()
import '../cache/mood_echo_cache.dart';
import '../services/mood_echo_service.dart';

class MoodEchoPage extends StatefulWidget {
  const MoodEchoPage({super.key});

  @override
  State<MoodEchoPage> createState() => _MoodEchoPageState();
}

class _MoodEchoPageState extends State<MoodEchoPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? moodEcho;
  Map<String, dynamic>? userData;
  bool _loading = true;
  bool _generating = false;

  // Stream para emitir cambios en moodEcho
  final StreamController<Map<String, dynamic>?> _echoStreamController =
      StreamController.broadcast();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _loadMoodEcho();
  }

  @override
  void dispose() {
    _echoStreamController.close();
    _fadeController.dispose();
    super.dispose();
  }

  // Función para procesar el Map en un isolate (compute)
  static Map<String, dynamic> _processMoodEcho(Map<String, dynamic> raw) {
    // Aquí puedes realizar validaciones, normalizaciones, filtrados, etc.
    return Map<String, dynamic>.from(raw);
  }

  Future<void> _loadMoodEcho() async {
    setState(() => _loading = true);

    Map<String, dynamic>? loadedEcho;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      final firestore = FirebaseFirestore.instance;

      final userDoc = await firestore.collection("users").doc(uid).get();
      userData = userDoc.data();

      final sessionSnap = await firestore
          .collection("users")
          .doc(uid)
          .collection("sessions")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (sessionSnap.docs.isNotEmpty) {
        final data = sessionSnap.docs.first.data();
        final rawEcho = data["mood_echo"] as Map<String, dynamic>?;
        if (rawEcho != null) {
          // Procesamos en isolate
          final processed = await compute(_processMoodEcho, rawEcho);
          loadedEcho = processed;
          await MoodEchoCache.save(processed); // guardamos en cache LRU
        }
      }

      if (loadedEcho == null) {
        // Si no conseguimos desde red / Firestore, intentamos desde cache
        final cached = await MoodEchoCache.getLatest();
        if (cached != null) {
          loadedEcho = cached;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading MoodEcho: $e");
      // On error, fallback a cache
      final cached = await MoodEchoCache.getLatest();
      if (cached != null) {
        loadedEcho = cached;
      }
    }

    moodEcho = loadedEcho;
    _echoStreamController.add(moodEcho);

    setState(() => _loading = false);
    _fadeController.forward(from: 0);
  }

  Future<void> _regenerate() async {
    setState(() => _generating = true);
    try {
      await MoodEchoService().generateMoodEcho();
      // Espera breve por si hay delay
      await Future.delayed(const Duration(seconds: 1));
      await _loadMoodEcho();
    } catch (e) {
      debugPrint("Error regenerating MoodEcho: $e");
      // Podés mostrar SnackBar de error aquí si quieres
    } finally {
      setState(() => _generating = false);
    }
  }

  // 🎨 Genera un color adaptativo según país y alignment_score
  Color _getThemeColor(double score, String nationality) {
    final nat = nationality.toLowerCase();
    if (nat.contains("japan") || nat.contains("jp")) {
      return score >= 0.7
          ? const Color(0xFFB3E5FC)
          : score >= 0.4
              ? const Color(0xFF81D4FA)
              : const Color(0xFF4FC3F7);
    } else if (nat.contains("mexico") ||
        nat.contains("colombia") ||
        nat.contains("spain") ||
        nat.contains("argentina") ||
        nat.contains("latam")) {
      return score >= 0.7
          ? const Color(0xFFFFB74D)
          : score >= 0.4
              ? const Color(0xFFFFA726)
              : const Color(0xFFFF7043);
    } else if (nat.contains("usa") || nat.contains("uk")) {
      return score >= 0.7
          ? const Color(0xFF90CAF9)
          : score >= 0.4
              ? const Color(0xFF64B5F6)
              : const Color(0xFF42A5F5);
    }
    return score >= 0.7
        ? const Color(0xFFCE93D8)
        : score >= 0.4
            ? const Color(0xFFBA68C8)
            : const Color(0xFFAB47BC);
  }

  // 🎶 Fondo animado según tono o género detectado
  Color _getMoodColor(String tone, double score) {
    final t = tone.toLowerCase();

    if (t.contains("edm") || t.contains("electronic")) {
      return Color.lerp(const Color(0xFF04D9FF), const Color(0xFF8A00C4), score)!;
    } else if (t.contains("rock") || t.contains("j-rock") || t.contains("punk")) {
      return Color.lerp(const Color(0xFF5E0200), const Color(0xFFDE0500), score)!;
    } else if (t.contains("k-pop") || t.contains("pop")) {
      return Color.lerp(const Color(0xFFD60F84), const Color(0xFFD60F84), score)!;
    } else if (t.contains("metal")) {
      return Color.lerp(const Color(0xFF141414), const Color(0xFFA9A9A9), score)!;
    } else if (t.contains("rap") || t.contains("hip") || t.contains("trap")) {
      return Color.lerp(const Color(0xFF000000), const Color(0xFFD4AF37), score)!;
    } else if (t.contains("jazz")) {
      return Color.lerp(const Color(0xFF174D26), const Color(0xFF4D8657), score)!;
    } else if (t.contains("classical") || t.contains("orchestra")) {
      return Color.lerp(const Color(0xFFFFC900), const Color(0xFFEAEAEA), score)!;
    } else if (t.contains("medieval") || t.contains("fantasy")) {
      return Color.lerp(const Color(0xFFBD001B), const Color(0xFFD3A42E), score)!;
    } else if (t.contains("anisong") || t.contains("anime")) {
      return Color.lerp(const Color(0xFF00BFC6), const Color(0xFFFFBF00), score)!;
    } else if (t.contains("musical") || t.contains("theatre")) {
      return Color.lerp(const Color(0xFF011D6B), const Color(0xFFFFBF00), score)!;
    }

    // 🌌 Por defecto: tonos interestelares neutros
    return Color.lerp(Colors.indigo, Colors.cyanAccent, score)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (() {
                final tone = moodEcho?["musical_tone"] ?? "neutral";
                final score = (moodEcho?["alignment_score"] ?? 0.0).toDouble();
                return _getMoodColor(tone, score).withOpacity(0.45);
              })(),
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: _echoStreamController.stream,
            builder: (context, snapshot) {
              if (_loading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final echo = snapshot.data;
              if (echo == null) {
                return _buildEmptyState();
              }

              final nationality = userData?["nationality"]?["name"] ?? "Unknown";
              final flag = userData?["nationality"]?["flag"] ?? "";
              final nickname = userData?["nickname"] ?? "Traveler";
              final score = (echo["alignment_score"] ?? 0.0).toDouble();
              final tone = echo["musical_tone"] ?? "neutral";
              final moodColor = _getMoodColor(tone, score);
              final contentColor = _getThemeColor(score, nationality);

              return FadeTransition(
                opacity: _fadeAnim,
                child: _buildContent(
                  echo,
                  nickname,
                  nationality,
                  flag,
                  moodColor,
                  contentColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> echo, String nickname,
      String nationality, String flag, Color moodColor, Color contentColor) {
    final summary = echo["summary"] ?? "";
    final reflection = echo["reflection"] ?? "";
    final tone = (echo["musical_tone"] ?? "neutral").toString().toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Letter from SOL ☀️",
            style: TextStyle(
              fontFamily: 'EncodeSansExpanded',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: contentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "To $nickname $flag — ${nationality.toUpperCase()}",
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'RobotoMono',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: contentColor, width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: contentColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dear $nickname,",
                  style: TextStyle(
                    color: contentColor,
                    fontFamily: 'EncodeSansExpanded',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reflection,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.string(
                      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none"
                      xmlns="http://www.w3.org/2000/svg">
                      <path d="M9 19V6L21 3V16" stroke="${contentColor.value.toRadixString(16).substring(2)}" stroke-width="2"/>
                      <circle cx="6" cy="19" r="2" fill="${contentColor.value.toRadixString(16).substring(2)}"/>
                      <circle cx="18" cy="16" r="2" fill="${contentColor.value.toRadixString(16).substring(2)}"/>
                      </svg>''',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tone,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: contentColor,
                          fontFamily: 'EncodeSansExpanded',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3,
                        ),  
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "💭 ${echo["recommendation"] ?? ""}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'RobotoMono',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "— SOL",
                    style: TextStyle(
                      color: contentColor,
                      fontFamily: 'EncodeSansExpanded',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],  
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _generating ? null : _regenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: contentColor,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: _generating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _generating ? "Generating..." : "Regenerate Mood Echo",
              style: const TextStyle(
                fontFamily: 'EncodeSansExpanded',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt_rounded,
                color: Colors.white38, size: 60),
            const SizedBox(height: 16),
            const Text(
              "No Mood Echo available yet 🌙",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _regenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text("Generate one now"),
            ),
          ],
        ),
      );
}
