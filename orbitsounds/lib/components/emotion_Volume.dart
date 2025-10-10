import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: EmotionSliderDemo(),
  ));
}

class EmotionSliderDemo extends StatefulWidget {
  const EmotionSliderDemo({Key? key}) : super(key: key);

  @override
  State<EmotionSliderDemo> createState() => _EmotionSliderDemoState();
}

class _EmotionSliderDemoState extends State<EmotionSliderDemo> {
  int _selectedEmotion = 1; // 0 = FEAR, 1 = SADNESS, 2 = JOY

  final List<String> emotions = ["FEAR", "SADNESS", "JOY"];

  void _setEmotion(int index) {
    setState(() {
      _selectedEmotion = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 220,
          height: 600,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Slider con CustomPaint
              Positioned.fill(
                child: CustomPaint(
                  painter: _SliderPainter(
                    selectedEmotion: _selectedEmotion,
                    emotions: emotions,
                  ),
                ),
              ),

              // Thumb (rectángulo deslizante)
              LayoutBuilder(
                builder: (context, constraints) {
                  double railTop = 40;
                  double railBottom = constraints.maxHeight - 40;
                  double sectionHeight = (railBottom - railTop) / 2;

                  // Calcula la posición del thumb según la emoción seleccionada
                  double y = railBottom - _selectedEmotion * sectionHeight;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    bottom: constraints.maxHeight - y - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4B1B8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF010B19), width: 2),
                      ),
                    ),
                  );
                },
              ),

              // Botones de texto para seleccionar emoción
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _setEmotion(2),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("JOY", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _setEmotion(1),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("SADNESS", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _setEmotion(0),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("FEAR", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  final int selectedEmotion;
  final List<String> emotions;

  _SliderPainter({required this.selectedEmotion, required this.emotions});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint railPaint = Paint()
      ..color = const Color(0xFF010B19)
      ..style = PaintingStyle.fill;

    final Paint railActivePaint = Paint()
      ..color = const Color(0xFFE9E8EE)
      ..style = PaintingStyle.fill;

    final double railX = size.width * 0.6;
    final double railWidth = 16;
    final double railTop = 40;
    final double railBottom = size.height - 40;

    // Riel inactivo
    RRect rail = RRect.fromLTRBR(
      railX - railWidth / 2,
      railTop,
      railX + railWidth / 2,
      railBottom,
      const Radius.circular(8),
    );
    canvas.drawRRect(rail, railPaint);

    // Rail activo (hasta la emoción seleccionada)
    double sectionHeight = (railBottom - railTop) / 2;
    double activeBottom = railBottom - selectedEmotion * sectionHeight;

    RRect activeRail = RRect.fromLTRBR(
      railX - railWidth / 2,
      activeBottom,
      railX + railWidth / 2,
      railBottom,
      const Radius.circular(8),
    );
    canvas.drawRRect(activeRail, railActivePaint);

    // Puntos decorativos
    final circlePaint = Paint()..color = const Color(0xFFD9D9D9);

    for (int i = 0; i < 3; i++) {
      for (int j = 1; j <= 6; j++) {
        double y = railTop + (railBottom - railTop) * (i / 2) + (j * (sectionHeight / 7));
        canvas.drawCircle(Offset(railX - 25, y), 4, circlePaint);
      }
    }

    // Líneas horizontales
    final linePaint = Paint()
      ..color = const Color(0xFFE9E8EE)
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      double y = railTop + (railBottom - railTop) * (i / 2);
      canvas.drawLine(
        Offset(railX - 50, y),
        Offset(railX - 15, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      oldDelegate.selectedEmotion != selectedEmotion;
}
