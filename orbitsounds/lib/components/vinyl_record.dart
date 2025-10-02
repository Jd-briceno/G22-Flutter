import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// VinylRecord
/// • size: tamaño total del vinilo (px)
/// • image: portada (Network/Asset)
/// • labelColor: color de fondo de la etiqueta (detrás de la portada)
/// • isSpinning: si true, gira en loop
/// • rotationSpeed: vueltas por segundo
/// • shadow: sombra exterior
/// ─────────────────────────────────────────────────────────
class VinylRecord extends StatefulWidget {
  final double size;
  final ImageProvider image;
  final Color labelColor;
  final bool isSpinning;
  final double rotationSpeed; // vueltas/seg
  final List<BoxShadow> shadow;

  const VinylRecord({
    super.key,
    required this.image,
    this.size = 140,
    this.labelColor = const Color(0xFF222222),
    this.isSpinning = false,
    this.rotationSpeed = 0.6,
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
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this);
    if (widget.isSpinning) _startSpin();
  }

  @override
  void didUpdateWidget(covariant VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning ||
        widget.rotationSpeed != oldWidget.rotationSpeed) {
      widget.isSpinning ? _startSpin() : _ctrl.stop();
    }
  }

  void _startSpin() {
    // 1 vuelta = 2π. Velocidad en vueltas/seg → rad/seg
    final radPerSecond = widget.rotationSpeed * 2 * math.pi;
    _ctrl.animateWith(_ConstantAngularVelocity(radPerSecond));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.rotate(
          angle: _ctrl.value, // va creciendo linealmente
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: widget.shadow),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Disco + surcos + brillos
                  CustomPaint(painter: _VinylPainter()),
                  // Etiqueta con portada
                  Center(
                    child: _VinylLabel(
                      size: s * 0.56,               // diámetro de la etiqueta
                      image: widget.image,
                      background: widget.labelColor,
                      borderColor: Colors.white24,   // aro fino
                    ),
                  ),
                  // Agujero central
                  Center(
                    child: Container(
                      width: s * 0.06,
                      height: s * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        boxShadow: const [
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
          ),
        );
      },
    );
  }
}

/// Simula una velocidad angular constante para el controller unbounded.
class _ConstantAngularVelocity extends Simulation {
  final double radPerSecond;
  _ConstantAngularVelocity(this.radPerSecond);

  @override
  double x(double time) => radPerSecond * time;
  @override
  double dx(double time) => radPerSecond;
  @override
  bool isDone(double time) => false;
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
            Image(
              image: image,
              fit: BoxFit.cover,
            ),
            // Vignette suave para “fundir” bordes de la portada
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

    // 1) Base negra con sutil gradiente radial (efecto plástico)
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.15, -0.15),
        radius: 0.95,
        colors: const [
          Color(0xFF0D0D0D),
          Color(0xFF000000),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, r, basePaint);

    // 2) Surcos (concentric rings)
    final grooves = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0xFFB4B1B8).withOpacity(0.35);

    final inner = r * 0.36; // deja espacio para la etiqueta
    for (double rr = inner; rr <= r * 0.96; rr += 1.6) {
      canvas.drawCircle(center, rr, grooves);
    }

    // 3) Aros más marcados (cada ~10 surcos)
    final bold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFE9E8EE).withOpacity(0.5);
    for (double rr = inner + 8; rr <= r * 0.96; rr += 8) {
      canvas.drawCircle(center, rr, bold);
    }

    // 4) Brillo especular (dos reflejos suaves en diagonal)
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

    // 5) Borde exterior sutil (para “recortar” en fondos negros)
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color(0xFFE9E8EE).withOpacity(0.8);
    canvas.drawCircle(center, r - 0.6, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
