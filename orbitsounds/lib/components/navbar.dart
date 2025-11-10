import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:feather_icons/feather_icons.dart';
import 'dart:io';

import 'package:orbitsounds/models/weather_model.dart';


class Navbar extends StatelessWidget {
  final String username;
  final String title;
  final String? profileImage; // 👈 opcional ahora
  final Widget? profileWidget; // 👈 nuevo
  final String? subtitle;
  final WeatherModel? weather;

  const Navbar({
    super.key,
    required this.username,
    required this.title,
    this.profileImage,
    this.profileWidget,
    this.subtitle,
    this.weather,
  });

  ImageProvider _imageProviderFor(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/images/Jay.jpg');
    } else if (path.startsWith('http')) {
      // 🔹 Imagen remota (Firebase Storage, etc.)
      return NetworkImage(path);
    } else if (path.startsWith('/data/')) {
      // 🔹 Imagen local guardada en el dispositivo (FileImage)
      return FileImage(File(path));
    } else {
      // 🔹 Imagen desde assets
      return AssetImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        children: [
          // ═════════════ Rectángulo exterior ═════════════
          Positioned(
            left: 28,
            top: 14,
            child: Container(
              width: 325,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF010B19),
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),

          // ═════════════ Rectángulo central (Hello username o Subtitle) ═════════════
          Positioned(
            left: 21,
            top: 36,
            child: Container(
              width: 225,
              height: 57,
              decoration: BoxDecoration(
                color: const Color(0xFF010B19),
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _MarqueeText(
                text: subtitle ?? "Hello, $username",
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Color(0xFFE9E8EE),
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Color(0xFFE9E8EE).withOpacity(0.8),
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 16,
                      color: Colors.blueGrey.shade200,
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 32,
                      color: Color(0xFFE9E8EE).withOpacity(0.6),
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),


          // ═════════════ Rectángulo superior (barra título) ═════════════
          Positioned(
            left: 21,
            top: 1,
            child: Container(
              width: 300,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF010B19),
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          // ═════════════ Rectángulo título ═════════════
          Positioned(
            left: 38,
            top: 4.5,
            child: Container(
              width: 123,
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerLeft,
              child: _SmartMarqueeText(
                text: title,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Color(0xFFE9E8EE),
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Color(0xFFE9E8EE).withOpacity(0.8),
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 14,
                      color: Colors.blueGrey.shade200,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ═════════════ Botón HOME ═════════════
          Positioned(
            left: 1,
            top: 42,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF010B19),
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HeroIcon(
                HeroIcons.home,
                style: HeroIconStyle.outline,
                color: Color(0xFFE9E8EE),
                size: 28,
              ),
            ),
          ),

          // ═════════════ Botón Notificaciones ═════════════
          Positioned(
            left: 252,
            top: 42,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF010B19),
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HeroIcon(
                HeroIcons.bell,
                style: HeroIconStyle.outline,
                color: Color(0xFFE9E8EE),
                size: 28,
              ),
            ),
          ),

          // ═════════════ Foto perfil o ícono custom ═════════════
          Positioned(
            left: 300,
            top: 42,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: profileWidget ??
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image(
                    image: _imageProviderFor(profileImage ?? ''),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Color(0xFFE9E8EE),
                        size: 28,
                      );
                    },
                  ),
                ),
            ),
          ),

          // ═════════════ Icono headphones ═════════════
          Positioned(
              left: 167,
              top: 4.5,
              child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFFB4B1B8), width: 2),
                  ),
                  child: const Icon(
                    FeatherIcons.headphones,
                    color: Color(0xFFB4B1B8),
                    size: 14,
                  ))),

          // ═════════════ Icono nota musical ═════════════
          Positioned(
            left: 192,
            top: 4.5,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
              ),
              child: const HeroIcon(
                HeroIcons.musicalNote,
                style: HeroIconStyle.outline,
                color: Color(0xFFB4B1B8),
                size: 14,
              ),
            ),
          ),

          // ═════════════ Círculo decorativo ═════════════
          Positioned(
            left: 245,
            top: 7,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFFB4B1B8), width: 2),
              ),
            ),
          ),

          // ═════════════ Línea horizontal ═════════════
          Positioned(
            left: 265,
            top: 18,
            child: Container(width: 14, height: 2, color: Color(0xFFB4B1B8)),
          ),

          // ═════════════ X ═════════════
          Positioned(
            left: 280,
            top: 10,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CustomPaint(painter: _XPainter()),
            ),
          ),

          // ═════════════ Clima minimalista (texto + ícono) ═════════════
          Positioned(
            left: 10,
            top: 100,
            child: weather != null
                ? Material(
                    type: MaterialType.transparency,
                    child: Transform.translate(
                      offset: const Offset(-4, 2),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: HeroIcon(
                                    weather!.iconData,
                                    style: HeroIconStyle.solid,
                                    color: weather!.iconColor,
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                (context as Element).markNeedsBuild();
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: value,
                                  child: Text(
                                    '${weather!.description} ${weather!.temperature}°C',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 12,
                                      color: const Color(0xFFE9E8EE),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              Future.delayed(const Duration(milliseconds: 150), () {
                                (context as Element).markNeedsBuild();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// 🔥 Texto siempre con marquee infinito (fluido, sin saltos)
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controller;
  double _scrollWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scrollController.jumpTo(0);
        _controller.forward(from: 0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    setState(() => _scrollWidth = maxScroll);

    _controller.addListener(() {
      if (_scrollController.hasClients && _scrollWidth > 0) {
        final offset = _controller.value * _scrollWidth;
        _scrollController.jumpTo(offset);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(width: 60),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}

/// 🔥 Solo hace marquee infinito si el texto es más largo que el contenedor
class _SmartMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _SmartMarqueeText({required this.text, required this.style});

  @override
  State<_SmartMarqueeText> createState() => _SmartMarqueeTextState();
}

class _SmartMarqueeTextState extends State<_SmartMarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _controller;

  double _textWidth = 0;
  double _boxWidth = 0;
  bool _needsScroll = false;
  double _scrollWidth = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureText());
  }

  void _measureText() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _textWidth = textPainter.width;
        _boxWidth = renderBox.size.width;
        _needsScroll = _textWidth > _boxWidth;
      });

      if (_needsScroll) _startScroll();
    }
  }

  void _startScroll() {
    _scrollWidth = _textWidth;
    _controller.addListener(() {
      if (_scrollController.hasClients && _scrollWidth > 0) {
        final offset = _controller.value * _scrollWidth;
        _scrollController.jumpTo(offset);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scrollController.jumpTo(0);
        _controller.forward(from: 0);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsScroll) {
      return Text(widget.text, style: widget.style);
    }

    return SizedBox(
      height: 22,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(width: 60),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}

/// Dibuja la "X"
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB4B1B8)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
