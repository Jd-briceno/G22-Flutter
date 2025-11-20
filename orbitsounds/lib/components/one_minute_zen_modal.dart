import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// 🌫️ Fallbacks estilo sumi-e, según emoción
const Map<String, String> sumiZenDefaults = {
  "FEAR":
      "Fear is a dark stroke on the canvas, but it does not define the whole painting.\nBreathe in. Let the line soften.",
  "SADNESS":
      "Tears fall like diluted ink, turning sharp lines into soft shades of blue.\nBreathe, and let the paper hold your sorrow.",
  "ANGER":
      "Your anger is a bold brushstroke, strong and undeniable.\nBreathe, and allow its edges to fade into calm.",
  "DISGUST":
      "Like a stain of ink you wish to erase, the feeling will eventually dry and crack.\nBreathe, and let it pass.",
  "ANXIETY":
      "Your thoughts scatter like droplets of ink, restless on the page.\nBreathe in slowly, let them settle into shapes.",
  "ENVY":
      "Envy is a shadow behind a bright stroke, always comparing.\nBreathe, and remember your own canvas is unique.",
  "UNKNOWN":
      "Your feelings are like ink before it meets the paper – full of possibilities.\nBreathe, and let them take a gentle shape.",
};
class OneMinuteZenModal extends StatefulWidget {
  final String zenText;   // Mensaje generado por IA
  final String emotion;   // Emoción difícil principal

  const OneMinuteZenModal({
    super.key,
    required this.zenText,
    required this.emotion,
  });

  @override
  State<OneMinuteZenModal> createState() => _OneMinuteZenModalState();
}

class _OneMinuteZenModalState extends State<OneMinuteZenModal>
    with SingleTickerProviderStateMixin {
  int remaining = 60;
  late Timer _timer;
  late AnimationController _inkController;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining == 0) {
        t.cancel();
        Navigator.pop(context, "completed");
      } else {
        setState(() => remaining--);
      }
    });

    _inkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _inkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotionKey = widget.emotion.toUpperCase();

    // 🔥 Si IA falla → usar fallback sumi-e
    final zenMessage = widget.zenText.isNotEmpty
        ? widget.zenText
        : (sumiZenDefaults[emotionKey] ?? sumiZenDefaults["UNKNOWN"]!);

    return Center(
      child: Material(
        color: const Color(0xAA000000),
        child: AnimatedBuilder(
          animation: _inkController,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(22),
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                color: const Color(0xFF0A141F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "One-Minute Zen",
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: "RobotoMono",
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  CustomPaint(
                    painter: SumiPainter(
                      progress: _inkController.value,
                      emotion: widget.emotion,
                    ),
                    child: const SizedBox(width: 240, height: 120),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    zenMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Breathe…",
                    style: TextStyle(
                      fontFamily: "RobotoMono",
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "$remaining",
                    style: const TextStyle(
                      fontSize: 48,
                      fontFamily: "RobotoMono",
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.pop(context, "skip"),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ===============================================================
/// 🎨 PINTOR SUMI-E — manchas dinámicas según emoción difícil
/// ===============================================================
class SumiPainter extends CustomPainter {
  final double progress;
  final String emotion;

  SumiPainter({
    required this.progress,
    required this.emotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final e = emotion.toUpperCase();

    Color base = Colors.black.withOpacity(0.25 + progress * 0.2);

    switch (e) {
      case "ANGER":
        base = Color(0xFFFF595D).withOpacity(0.32 + progress * 0.12);
        break;
      case "FEAR":
        base = Color(0xFF944FBC).withOpacity(0.30);
        break;
      case "ANXIETY":
        base = Colors.orangeAccent.withOpacity(0.30);
        break;
      case "SADNESS":
        base = Color(0xFF2390D3).withOpacity(0.30);
        break;
      case "ENVY":
        base =  Color(0xFF34C985).withOpacity(0.30);
        break;
      case "DISGUST":
        base =Color(0xFF91C836).withOpacity(0.30);
        break;
    }

    final paint = Paint()
      ..color = base
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    final center = Offset(size.width / 2, size.height / 2);

    double mainSize = 40 + progress * 60;
    if (e == "ANGER") {
      mainSize += sin(progress * pi * 2) * 15;
    }

    canvas.drawCircle(center, mainSize, paint);

    canvas.drawCircle(
      Offset(center.dx - 40, center.dy + 10),
      mainSize * 0.45,
      paint..color = paint.color.withOpacity(0.18),
    );

    canvas.drawCircle(
      Offset(center.dx + 30, center.dy - 20),
      mainSize * 0.33,
      paint..color = paint.color.withOpacity(0.22),
    );
  }

  @override
  bool shouldRepaint(covariant SumiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.emotion != emotion;
}
