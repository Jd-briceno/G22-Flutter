import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// VinylRecord (ESTÁTICO)
/// • Dibuja el vinilo con surcos, brillos y etiqueta central
/// • SIN animación → rendimiento mucho más suave
/// ─────────────────────────────────────────────────────────
class VinylRecord extends StatelessWidget {
  final double size;
  final ImageProvider image;
  final Color labelColor;
  final List<BoxShadow> shadow;

  const VinylRecord({
    super.key,
    required this.image,
    this.size = 140,
    this.labelColor = const Color(0xFF222222),
    this.shadow = const [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 16,
        spreadRadius: 2,
        offset: Offset(0, 6),
      )
    ],
  });

  @override
  Widget build(BuildContext context) {
    final s = size;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Disco + surcos + brillos
            CustomPaint(painter: _VinylPainter()),
            // Etiqueta con portada
            Center(
              child: _VinylLabel(
                size: s * 0.56,
                image: image,
                background: labelColor,
                borderColor: Colors.white24,
              ),
            ),
            // Agujero central
            Center(
              child: Container(
                width: s * 0.06,
                height: s * 0.06,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      spreadRadius: 0.5,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta del centro con imagen, fondo y aro
class _VinylLabel extends StatelessWidget {
  final double size;
  final ImageProvider image;
  final Color background;
  final Color borderColor;

  const _VinylLabel({
    required this.size,
    required this.image,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: borderColor, width: size * 0.02),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: image, fit: BoxFit.cover),
            // Vignette suave
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.25),
                  ],
                  stops: const [0.65, 0.9, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta el cuerpo del vinilo: base, surcos y brillos
class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Base negra con gradiente radial
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.15),
        radius: 0.95,
        colors: const [Color(0xFF0D0D0D), Color(0xFF000000)],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, r, basePaint);

    // Surcos
    final grooves = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0xFFB4B1B8).withOpacity(0.35);

    final inner = r * 0.36;
    for (double rr = inner; rr <= r * 0.96; rr += 1.6) {
      canvas.drawCircle(center, rr, grooves);
    }

    // Aros más marcados
    final bold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE9E8EE).withOpacity(0.5);
    for (double rr = inner + 8; rr <= r * 0.96; rr += 8) {
      canvas.drawCircle(center, rr, bold);
    }

    // Brillos
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.14),
          Colors.transparent,
          Colors.transparent,
          Colors.white.withOpacity(0.10),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Offset.zero & size)
      ..blendMode = BlendMode.softLight;
    canvas.drawCircle(center, r, highlight);

    // Borde exterior
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFE9E8EE).withOpacity(0.8);
    canvas.drawCircle(center, r - 0.6, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
