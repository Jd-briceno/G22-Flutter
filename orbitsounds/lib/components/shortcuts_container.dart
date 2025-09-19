import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

class ShortcutItem {
  final HeroIcons icon;
  final String label;
  final VoidCallback onTap; // 🔥 acción al presionar

  const ShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ShortcutsContainer extends StatelessWidget {
  final List<ShortcutItem> shortcuts;

  const ShortcutsContainer({super.key, required this.shortcuts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0XFFB4B1B8), width: 1.5),
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xFF010B19),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: shortcuts.map((item) {
          return ShortcutTile(item: item);
        }).toList(),
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  final ShortcutItem item;

  const ShortcutTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap, // 🔥 ejecuta acción
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 62,
        height: 110,
        child: Column(
          children: [
            // --- Forma SVG + ícono ---
            SizedBox(
              width: 62,
              height: 76,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ShortcutPainter(),
                    ),
                  ),
                  Center(
                    child: HeroIcon(
                      item.icon,
                      style: HeroIconStyle.outline,
                      color: const Color(0XFFE9E8EE),
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // --- Texto debajo ---
            Text(
              item.label,
              style: const TextStyle(
                fontFamily: "RobotoMono",
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Color(0XFFE9E8EE),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Dibujo de la forma SVG
class _ShortcutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = const Color(0xFF010B19)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = const Color(0xFFB4B1B8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(6, 1)
      ..cubicTo(3.23858, 1, 1, 3.23858, 1, 6)
      ..lineTo(1, 78)
      ..cubicTo(1, 80.7614, 3.23858, 83, 6, 83)
      ..lineTo(20.0244, 83)
      ..lineTo(20.0244, 77.5988)
      ..lineTo(22.9512, 77.5988)
      ..lineTo(22.9512, 83)
      ..lineTo(26.3659, 83)
      ..lineTo(26.3659, 77.5988)
      ..lineTo(29.2927, 77.5988)
      ..lineTo(29.2927, 83)
      ..lineTo(33.1951, 83)
      ..lineTo(33.1951, 77.5988)
      ..lineTo(35.6341, 77.5988)
      ..lineTo(35.6341, 83)
      ..lineTo(39.0488, 83)
      ..lineTo(39.0488, 77.5988)
      ..lineTo(41.4878, 77.5988)
      ..lineTo(41.4878, 83)
      ..lineTo(56, 83)
      ..cubicTo(58.7614, 83, 61, 80.7614, 61, 78)
      ..lineTo(61, 30.8655)
      ..cubicTo(61, 29.6551, 60.5609, 28.4858, 59.7643, 27.5746)
      ..lineTo(51.504, 18.126)
      ..cubicTo(50.7073, 17.2148, 50.2683, 16.0455, 50.2683, 14.8351)
      ..lineTo(50.2683, 6)
      ..cubicTo(50.2683, 3.23857, 48.0297, 1, 45.2683, 1)
      ..lineTo(6, 1)
      ..close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}