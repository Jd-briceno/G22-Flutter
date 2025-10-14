import 'package:flutter/material.dart';

/// Widget genérico para dibujar constelaciones
class ConstellationWidget extends StatelessWidget {
  final double size;
  final Color color;
  final List<Offset> points;
  final List<List<int>> connections;

  const ConstellationWidget({
    super.key,
    required this.size,
    required this.color,
    required this.points,
    required this.connections,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ConstellationPainter(
          points: points,
          connections: connections,
          color: color,
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<Offset> points;
  final List<List<int>> connections;
  final Color color;

  _ConstellationPainter({
    required this.points,
    required this.connections,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2;

    final paintPoint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Escalar puntos al tamaño del widget
    final scaledPoints = points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // Dibujar conexiones
    for (var conn in connections) {
      final p1 = scaledPoints[conn[0]];
      final p2 = scaledPoints[conn[1]];
      canvas.drawLine(p1, p2, paintLine);
    }

    // Dibujar puntos
    for (var p in scaledPoints) {
      canvas.drawCircle(p, 5, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🔹 Great Bear (Osa Mayor)
class GreatBearConstellation extends StatelessWidget {
  final double size;
  const GreatBearConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFF9D2053),
      points: [
        Offset(0.1, 0.2),
        Offset(0.3, 0.3),
        Offset(0.5, 0.25),
        Offset(0.7, 0.35),
        Offset(0.8, 0.5),
        Offset(0.6, 0.6),
        Offset(0.4, 0.7),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
        [4, 5],
        [5, 6],
      ],
    );
  }
}

/// 🔹 Southern Cross (Cruz del Sur)
class SouthernCrossConstellation extends StatelessWidget {
  final double size;
  const SouthernCrossConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFFF8CA00),
      points: [
        Offset(0.5, 0.1),
        Offset(0.5, 0.9),
        Offset(0.3, 0.5),
        Offset(0.7, 0.5),
      ],
      connections: [
        [0, 1],
        [2, 3],
      ],
    );
  }
}

/// 🔹 Draco
class DracoConstellation extends StatelessWidget {
  final double size;
  const DracoConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFF23B8A9),
      points: [
        Offset(0.2, 0.2),
        Offset(0.3, 0.4),
        Offset(0.5, 0.5),
        Offset(0.7, 0.4),
        Offset(0.8, 0.6),
        Offset(0.6, 0.8),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
        [4, 5],
      ],
    );
  }
}

/// 🔹 Pegasus
class PegasusConstellation extends StatelessWidget {
  final double size;
  const PegasusConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFF6664FF),
      points: [
        Offset(0.2, 0.2),
        Offset(0.8, 0.2),
        Offset(0.8, 0.8),
        Offset(0.2, 0.8),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 0],
      ],
    );
  }
}

/// 🔹 Phoenix
class PhoenixConstellation extends StatelessWidget {
  final double size;
  const PhoenixConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFFD43F00),
      points: [
        Offset(0.5, 0.1),
        Offset(0.7, 0.3),
        Offset(0.5, 0.5),
        Offset(0.3, 0.3),
        Offset(0.4, 0.7),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 0],
        [2, 4],
      ],
    );
  }
}

/// 🔹 Swan (Cisne)
class SwanConstellation extends StatelessWidget {
  final double size;
  const SwanConstellation({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ConstellationWidget(
      size: size,
      color: const Color(0xFFA1BBD1),
      points: [
        Offset(0.5, 0.1),
        Offset(0.5, 0.4),
        Offset(0.3, 0.6),
        Offset(0.7, 0.6),
        Offset(0.5, 0.9),
      ],
      connections: [
        [0, 1],
        [1, 2],
        [1, 3],
        [1, 4],
      ],
    );
  }
}
