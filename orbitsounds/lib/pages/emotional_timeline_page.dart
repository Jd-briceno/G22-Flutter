import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/navbar.dart';
import '../pages/celestial_signal.dart';
import '../services/sol_service.dart'; // ☀️ Servicio de análisis emocional

class EmotionalTimelinePage extends StatefulWidget {
  const EmotionalTimelinePage({super.key});

  @override
  State<EmotionalTimelinePage> createState() => _EmotionalTimelinePageState();
}

class _EmotionalTimelinePageState extends State<EmotionalTimelinePage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _solLoading = false;
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _solResponse;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fetchRecentSessions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🪐 Carga de las últimas 7 sesiones
  // ==========================================================
  Future<void> _fetchRecentSessions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";

      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("sessions")
          .orderBy("timestamp", descending: true)
          .limit(7)
          .get();

      final sessions = await Future.wait(snapshot.docs.map((doc) async {
        final sub = await doc.reference
            .collection("constellation")
            .orderBy("timestamp", descending: true)
            .limit(1)
            .get();

        final emotion =
            sub.docs.isNotEmpty ? sub.docs.first["emotion"] ?? "Unknown" : "Unknown";

        return {
          "timestamp": (doc["timestamp"] as Timestamp?)?.toDate(),
          "constellationEmotion": emotion,
        };
      }));

      setState(() {
        _sessions = sessions.reversed.toList();
        _loading = false;
      });

      if (_sessions.isNotEmpty) {
        await _analyzeWithSol();
      }
    } catch (e) {
      print("❌ Error cargando sesiones: $e");
      setState(() => _loading = false);
    }
  }

  // ==========================================================
  // ☀️ Llamada a SOL
  // ==========================================================
  Future<void> _analyzeWithSol() async {
    setState(() {
      _solLoading = true;
      _solResponse = null; // 🔥 limpiar mensaje anterior
    });

    try {
      final emotions = _sessions
          .map((s) => s["constellationEmotion"]?.toString() ?? "Unknown")
          .where((e) => e != "Unknown")
          .toList();

      if (emotions.isEmpty) return;

      final sol = SolService();
      final response = await sol.analyzeWeeklyEmotions(emotions: emotions);

      if (!mounted) return;
      setState(() {
        _solResponse = response;
        _solLoading = false;
      });

      _fadeController.forward(from: 0.0);
    } catch (e) {
      print("❌ Error analizando con SOL: $e");
      setState(() => _solLoading = false);
    }
  }

  // ==========================================================
  // 🎨 Determinar color / imagen según emoción
  // ==========================================================
  Map<String, dynamic> _getConstellationVisual(String emotion) {
    for (var entry in constellationInfo.entries) {
      if (entry.value["emotion"] == emotion) {
        final key = entry.key;
        final name = entry.value["name"].toString().split("\n")[0];
        final color = constellationColors[name] ?? Colors.white;

        String? imagePath;
        if (key.contains("_")) {
          imagePath = pairImages[key];
        } else {
          imagePath = individualImages[int.tryParse(key) ?? 0];
        }

        return {"color": color, "image": imagePath, "name": name};
      }
    }
    return {
      "color": Colors.white,
      "image": "assets/images/constellation.png",
      "name": "Unknown"
    };
  }

  // ==========================================================
  // 🧭 UI Principal
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final lastEmotion = _sessions.isNotEmpty
        ? _sessions.last["constellationEmotion"] ?? "Unknown"
        : "Unknown";
    final visual = _getConstellationVisual(lastEmotion);

    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _sessions.isEmpty
                ? const Center(
                    child: Text(
                      "No emotional data found 🌙",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const Navbar(
                          username: "Jay Walker",
                          title: "Longbook Overview",
                          subtitle: "Emotional Timeline",
                          profileImage: "assets/images/Jay.jpg",
                        ),
                        const SizedBox(height: 25),

                        Text(
                          "Your Emotional Journey",
                          style: GoogleFonts.encodeSansExpanded(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🌌 Timeline cósmica
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _sessions.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              final date = session["timestamp"] as DateTime?;
                              final emotion =
                                  session["constellationEmotion"] ?? "Unknown";
                              final v = _getConstellationVisual(emotion);

                              final formatted = date != null
                                  ? DateFormat('EEE').format(date)
                                  : "Day";

                              return Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 1.5,
                                    color: v["color"].withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 75,
                                    height: 75,
                                    decoration: BoxDecoration(
                                      color: v["color"].withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: v["color"],
                                        width: 1.4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: v["color"].withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Image.asset(
                                        v["image"],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatted.toUpperCase(),
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 0),

                        // ☀️ Estado de carga o mensaje final
                        if (_solLoading)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              const CircularProgressIndicator(
                                  color: Colors.white),
                              const SizedBox(height: 14),
                              Text(
                                "Loading your weekly reflection...",
                                style: GoogleFonts.encodeSansExpanded(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        else if (_solResponse != null)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Transform.translate(
                              offset: const Offset(0, 10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: visual["color"].withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: visual["color"],
                                    width: 1.3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: visual["color"].withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Weekly Reflection",
                                      style: GoogleFonts.encodeSansExpanded(
                                        color: visual["color"],
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _solResponse?["summary"] ?? "",
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _solResponse?["reflection"] ?? "",
                                      style: GoogleFonts.robotoMono(
                                        color: visual["color"],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
