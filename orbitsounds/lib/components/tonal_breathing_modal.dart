import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:melodymuse/constants/emotion_constants.dart';

class TonalBreathingModal extends StatefulWidget {
  final double bpm;
  final List<String> emotions;
  final String? zenMessage; // IA opcional

  const TonalBreathingModal({
    super.key,
    required this.bpm,
    required this.emotions,
    this.zenMessage,
  });

  @override
  State<TonalBreathingModal> createState() => _TonalBreathingModalState();
}

class _TonalBreathingModalState extends State<TonalBreathingModal>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  late int inhale;
  late int exhale;

  late String primaryEmotion;
  late String guidedMessage;

  @override
  void initState() {
    super.initState();

    // Normalizar emoción
    primaryEmotion = widget.emotions.isNotEmpty
        ? widget.emotions.first.toUpperCase()
        : "UNKNOWN";

    // Fallback mensaje sumi-e si IA viene null o vacío
    final fallback = sumiZenDefaults[primaryEmotion] ?? sumiZenDefaults["UNKNOWN"]!;
    guidedMessage = (widget.zenMessage == null || widget.zenMessage!.trim().isEmpty)
        ? fallback
        : widget.zenMessage!;

    // Convertir BPM → respiración
    final pattern = breathingPattern(widget.bpm);
    inhale = pattern["inhale"]!;
    exhale = pattern["exhale"]!;

    final total = inhale + exhale;

    controller = AnimationController(
      duration: Duration(seconds: total),
      vsync: this,
    )..repeat();

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // === Patrón de respiración según BPM ===
  Map<String, int> breathingPattern(double bpm) {
    if (bpm >= 110) return {"inhale": 6, "exhale": 6};
    if (bpm >= 90) return {"inhale": 5, "exhale": 5};
    return {"inhale": 4, "exhale": 4};
  }

  // === Color según emoción ===
  Color emotionColor() {
    switch (primaryEmotion) {
      case "ANGER":
        return Colors.redAccent;
      case "FEAR":
        return Color(0xFF944FBC);
      case "SADNESS":
        return  Color(0xFF2390D3);
      case "ANXIETY":
        return Colors.orangeAccent;
      case "ENVY":
        return Colors.greenAccent;
      case "DISGUST":
        return Colors.lightGreenAccent;
      case "LOVE":
        return Colors.pinkAccent;
      case "EMBARRASSMENT":
        return const Color(0xFFB53F5F);
      case "BOREDOM":
        return const Color(0xFFA08888);
      case "JOY": 
        return Color(0xFFFECA39);
      default:
        return Colors.white70;
    }
  }

  // === Texto dinámico inhale/exhale ===
  String breathLabel(double t) {
    final cycle = inhale + exhale;
    final position = (t * cycle).floor();

    if (position < inhale) return "Inhale…";
    return "Exhale…";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xAA000000),
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final double t = animation.value;

            // Movimiento sinusoidal del círculo
            final double radius = 60 + sin(t * pi * 2) * 40;

            return Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                color: const Color(0xFF0A141F),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Tonal Breathing",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontFamily: "RobotoMono",
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ——— CÍRCULO DE RESPIRACIÓN ———
                  Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: emotionColor().withOpacity(0.22 + t * 0.35),
                      boxShadow: [
                        BoxShadow(
                          color: emotionColor().withOpacity(0.45),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // inhale/exhale dinámico
                  Text(
                    breathLabel(t),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: "RobotoMono",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mensaje Sumi-e o IA si existiera
                  Text(
                    guidedMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.35,
                      fontFamily: "RobotoMono",
                    ),
                  ),

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white54,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
