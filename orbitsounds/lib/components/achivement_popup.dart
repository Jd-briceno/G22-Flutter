import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heroicons/heroicons.dart';

class AchievementPopup extends StatefulWidget {
  final String genre;
  final String title;
  final String iconPath;

  const AchievementPopup({
    super.key,
    required this.genre,
    required this.title,
    required this.iconPath,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 3.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SVG de fondo (sin el círculo azul, lo dibujaremos aparte)
          SvgPicture.string(
            '''
<svg width="392" height="170" viewBox="0 0 392 170" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="1" y="23" width="390" height="146" rx="10" fill="#B4B1B8"/>
<path d="M20 92.5C20 97.7467 15.7467 102 10.5 102C5.2533 102 1 106.253 1 111.5V159C1 164.523 5.47715 169 11 169H381C386.523 169 391 164.523 391 159V112C391 106.477 386.523 102 381 102H169C163.477 102 159 97.5228 159 92V11C159 5.47715 154.523 1 149 1H30C24.4772 1 20 5.47715 20 11V92.5Z" fill="#010B19" stroke="#E9E8EE"/>
<rect x="188" y="107" width="164" height="26" fill="#010B19"/>
<rect x="347" y="26" width="40" height="40" fill="#B4B1B8"/>
<rect x="161" y="34" width="167" height="60" fill="#B4B1B8"/>
</svg>
            ''',
            width: 392,
            height: 170,
          ),

          // Imagen circular con borde animado
          Positioned(
            left: 22.5,
            top: 10,
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircleGlowPainter(glowWidth: _glowAnimation.value),
                  child: Padding(
                    padding: EdgeInsets.all(_glowAnimation.value / 2),
                    child: ClipOval(
                      child: Image.asset(
                        widget.iconPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.amber,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Título
          Positioned(
            left: 150,
            top: 34,
            width: 167,
            height: 60,
            child: Center(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0XFF010B19),
                  fontWeight: FontWeight.bold,
                  fontFamily: "EncodeSansExpanded",
                  decoration: TextDecoration.none, // 🔹 Esto evita subrayados
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Texto verde
          const Positioned(
            left: 180,
            top: 107,
            width: 164,
            height: 26,
            child: Center(
              child: Text(
                "Congratulations!",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0095FC),
                  fontWeight: FontWeight.bold,
                  fontFamily: "EncodeSansExpanded",
                  decoration: TextDecoration.none, // 🔹 Esto evita subrayados
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Texto adicional
          const Positioned(
            left: 8,
            top: 135,
            width: 350,
            child: Text(
              "New achievement unlocked on your cosmic journey.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'RobotoMono',
                decoration: TextDecoration.none, // 🔹 Esto evita subrayados
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Botón cerrar
          Positioned(
            left: 318,
            top: 28,
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const HeroIcon(
                HeroIcons.xCircle,
                color: Color(0XFF010B19),
                size: 40,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el borde circular con brillo animado
class CircleGlowPainter extends CustomPainter {
  final double glowWidth;

  CircleGlowPainter({required this.glowWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2 - glowWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Glow exterior (suave)
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF0095FC).withOpacity(0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowWidth);

    canvas.drawCircle(center, radius, glowPaint);

    // Borde principal
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF0095FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CircleGlowPainter oldDelegate) =>
      oldDelegate.glowWidth != glowWidth;
}
